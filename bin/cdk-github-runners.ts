#!/usr/bin/env node
import {
	Architecture,
	Ec2RunnerProvider,
	GitHubRunners,
	Os,
	RunnerImageComponent,
} from "@cloudsnorkel/cdk-github-runners";
import { App, aws_ec2 as ec2, Size, Stack } from "aws-cdk-lib";

const app = new App();
const stack = new Stack(app, "github-runners", {
	env: { region: "ap-south-1" },
});
const vpc = new ec2.Vpc(stack, "VPC", {
	subnetConfiguration: [
		{
			name: "Public",
			subnetType: ec2.SubnetType.PUBLIC,
		},
	],
});
const imageCommands = [
	"apt update",
	"apt install make -y",
	"apt upgrade -y",
	"apt autoremove -y",
	"apt clean -y",
	"apt autoclean -y",
];

// small helper to DRY image builders
function makeImageBuilder(opts: {
	id: string;
	arch: Architecture;
	os?: Os;
	instanceType: ec2.InstanceType;
}) {
	const builder = Ec2RunnerProvider.imageBuilder(stack, opts.id, {
		architecture: opts.arch,
		os: opts.os ?? Os.LINUX_UBUNTU_2404,
		awsImageBuilderOptions: { instanceType: opts.instanceType },
		vpc,
	});
	builder.addComponent(
		RunnerImageComponent.custom({ commands: imageCommands }),
	);
	return builder;
}

// small helper to DRY providers
function makeProvider(opts: {
	id: string;
	archLabel: "arm64" | "amd64";
	instanceType: ec2.InstanceType;
	imageBuilder: ReturnType<typeof makeImageBuilder>;
	storageGiB?: number;
}) {
	return new Ec2RunnerProvider(stack, opts.id, {
		instanceType: opts.instanceType,
		storageSize: Size.gibibytes(opts.storageGiB ?? 20),
		labels: [
			opts.archLabel,
			"ec2",
			opts.instanceType.toString(), // e.g. "t4g.small" or "t3.medium"
		],
		imageBuilder: opts.imageBuilder,
		spot: true,
		vpc,
	});
}

// ---------- Instance types ----------
const t4gSmall = ec2.InstanceType.of(
	ec2.InstanceClass.T4G,
	ec2.InstanceSize.SMALL,
);
const t4gMedium = ec2.InstanceType.of(
	ec2.InstanceClass.T4G,
	ec2.InstanceSize.MEDIUM,
);
const t3Small = ec2.InstanceType.of(
	ec2.InstanceClass.T3,
	ec2.InstanceSize.SMALL,
);
const t3Medium = ec2.InstanceType.of(
	ec2.InstanceClass.T3,
	ec2.InstanceSize.MEDIUM,
);

// ---------- Image builders ----------
const imgArmSmall = makeImageBuilder({
	id: "LinuxArm64SmallBuilder",
	arch: Architecture.ARM64,
	instanceType: t4gSmall,
});
const imgArmMedium = makeImageBuilder({
	id: "LinuxArm64MediumBuilder",
	arch: Architecture.ARM64,
	instanceType: t4gMedium,
});
const imgX86Small = makeImageBuilder({
	id: "LinuxAmd64SmallBuilder",
	arch: Architecture.X86_64,
	instanceType: t3Small,
});
const imgX86Medium = makeImageBuilder({
	id: "LinuxAmd64MediumBuilder",
	arch: Architecture.X86_64,
	instanceType: t3Medium,
});

// ---------- Providers ----------
const armSmallProvider = makeProvider({
	id: "EC2-arm64-small",
	archLabel: "arm64",
	instanceType: t4gSmall,
	imageBuilder: imgArmSmall,
});
const armMediumProvider = makeProvider({
	id: "EC2-arm64-medium",
	archLabel: "arm64",
	instanceType: t4gMedium,
	imageBuilder: imgArmMedium,
});
const x86SmallProvider = makeProvider({
	id: "EC2-amd64-small",
	archLabel: "amd64",
	instanceType: t3Small,
	imageBuilder: imgX86Small,
});
const x86MediumProvider = makeProvider({
	id: "EC2-amd64-medium",
	archLabel: "amd64",
	instanceType: t3Medium,
	imageBuilder: imgX86Medium,
});

// ---------- GitHub Runners ----------
const runners = new GitHubRunners(stack, "runners", {
	providers: [
		armSmallProvider,
		armMediumProvider,
		x86SmallProvider,
		x86MediumProvider,
	],
});

// optional operational goodies
runners.createLogsInsightsQueries();
runners.metricJobCompleted();
runners.failedImageBuildsTopic();

app.synth();
