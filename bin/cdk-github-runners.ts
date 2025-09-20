#!/usr/bin/env node
import {
	Architecture,
	Ec2RunnerProvider,
	GitHubRunners,
	Os,
	RunnerImageComponent,
} from "@cloudsnorkel/cdk-github-runners";
import { App, aws_ec2 as ec2, Size, Stack } from "aws-cdk-lib";

// ---- Edit here: explicit InstanceType objects ----
const instanceTypes: ec2.InstanceType[] = [
	ec2.InstanceType.of(ec2.InstanceClass.T4G, ec2.InstanceSize.SMALL),
	ec2.InstanceType.of(ec2.InstanceClass.T4G, ec2.InstanceSize.MEDIUM),
	ec2.InstanceType.of(ec2.InstanceClass.T4G, ec2.InstanceSize.LARGE),
	ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.SMALL),
	ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MEDIUM),
	ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.LARGE),
	ec2.InstanceType.of(ec2.InstanceClass.C8G, ec2.InstanceSize.MEDIUM),
	ec2.InstanceType.of(ec2.InstanceClass.C8G, ec2.InstanceSize.LARGE),
];

const app = new App();
const stack = new Stack(app, "github-runners", {
	env: { region: "ap-southeast-3" },
});

const vpc = new ec2.Vpc(stack, "VPC", {
	subnetConfiguration: [{ name: "Public", subnetType: ec2.SubnetType.PUBLIC }],
	natGateways: 0,
});

const IMAGE_OS = Os.LINUX_UBUNTU_2404;
const IMAGE_CMDS = [
	"apt update",
	"apt install -y make",
	"apt upgrade -y",
	"apt autoremove -y",
	"apt clean -y",
	"apt autoclean -y",
];

// ARM/x86 detection from the instance-type string ("t4g.small", "t3.small", etc.)
const isArmFamily = (s: string) => /\dg\./.test(s) || /^a1\./.test(s);
const archOf = (itype: ec2.InstanceType) =>
	isArmFamily(itype.toString()) ? Architecture.ARM64 : Architecture.X86_64;

const makeImageBuilder = (id: string, itype: ec2.InstanceType) => {
	const builder = Ec2RunnerProvider.imageBuilder(stack, `${id}Image`, {
		architecture: archOf(itype),
		os: IMAGE_OS,
		awsImageBuilderOptions: { instanceType: itype },
		vpc,
	});
	builder.addComponent(RunnerImageComponent.custom({ commands: IMAGE_CMDS }));
	return builder;
};

const makeProvider = (id: string, itype: ec2.InstanceType) =>
	new Ec2RunnerProvider(stack, id, {
		instanceType: itype,
		storageSize: Size.gibibytes(20),
		labels: ["ec2", itype.toString()],
		imageBuilder: makeImageBuilder(id, itype),
		spot: true,
		vpc,
	});

const providers = instanceTypes.map((itype) =>
	makeProvider(`runner-${itype.toString().replace(/\./g, "-")}`, itype),
);

const runners = new GitHubRunners(stack, "runners", { providers });

// Optional, keep if useful
runners.createLogsInsightsQueries();
runners.metricJobCompleted();
runners.failedImageBuildsTopic();

app.synth();
