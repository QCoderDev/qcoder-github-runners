# Welcome to your CDK TypeScript project

This is a blank project for CDK development with TypeScript.

The `cdk.json` file tells the CDK Toolkit how to execute your app.

## Useful commands

* `npm run build`   compile typescript to js
* `npm run watch`   watch for changes and compile
* `npm run test`    perform the jest unit tests
* `npx cdk deploy`  deploy this stack to your default AWS account/region
* `npx cdk diff`    compare deployed stack with current state
* `npx cdk synth`   emits the synthesized CloudFormation template


## EC2 Spot Price by Region
Run script/compare_ec2_price_by_region.sh

Cheapest 10 regions as of 2025/9/20 7:32 pm JST:
### t4g.small

| region | avg_usd | min_usd | az_samples | avg_sps | sps_az_n |
|:--|--:|--:|--:|--:|--:|
| ap-southeast-3 | 0.00217 | 0.00210 | 3 | NA | 0 |
| me-south-1 | 0.00311 | 0.00250 | 3 | NA | 0 |
| eu-south-1 | 0.00330 | 0.00190 | 3 | NA | 0 |
| ap-east-1 | 0.00332 | 0.00300 | 3 | NA | 0 |
| af-south-1 | 0.00347 | 0.00220 | 3 | NA | 0 |
| ap-south-1 | 0.00379 | 0.00280 | 3 | 3.00000 | 3 |
| eu-west-3 | 0.00403 | 0.00300 | 3 | 3.00000 | 3 |
| ap-south-2 | 0.00461 | 0.00420 | 3 | NA | 0 |
| us-east-2 | 0.00520 | 0.00510 | 3 | 3.00000 | 3 |
| us-west-1 | 0.00583 | 0.00530 | 2 | 3.00000 | 2 |
| me-central-1 | 0.00625 | 0.00600 | 3 | NA | 0 |

### t4g.medium

| region | avg_usd | min_usd | az_samples | avg_sps | sps_az_n |
|:--|--:|--:|--:|--:|--:|
| me-south-1 | 0.00799 | 0.00530 | 3 | NA | 0 |
| ap-south-1 | 0.00844 | 0.00800 | 3 | 3.00000 | 3 |
| af-south-1 | 0.00917 | 0.00690 | 3 | NA | 0 |
| ap-south-2 | 0.00975 | 0.00930 | 3 | NA | 0 |
| ap-southeast-3 | 0.00991 | 0.00540 | 3 | NA | 0 |
| eu-west-3 | 0.01009 | 0.00910 | 3 | 3.00000 | 3 |
| eu-south-1 | 0.01012 | 0.00900 | 3 | NA | 0 |
| me-central-1 | 0.01231 | 0.01160 | 3 | NA | 0 |
| ap-southeast-4 | 0.01248 | 0.01210 | 3 | NA | 0 |
| eu-north-1 | 0.01279 | 0.01170 | 3 | 3.00000 | 3 |
| us-east-1 | 0.01339 | 0.01120 | 5 | 3.00000 | 5 |

### t3.small

| region | avg_usd | min_usd | az_samples | avg_sps | sps_az_n |
|:--|--:|--:|--:|--:|--:|
| eu-south-1 | 0.00242 | 0.00240 | 3 | NA | 0 |
| af-south-1 | 0.00271 | 0.00270 | 3 | NA | 0 |
| me-south-1 | 0.00376 | 0.00300 | 3 | NA | 0 |
| ap-east-1 | 0.00378 | 0.00340 | 3 | NA | 0 |
| ap-southeast-3 | 0.00452 | 0.00260 | 3 | NA | 0 |
| ap-southeast-4 | 0.00639 | 0.00590 | 3 | NA | 0 |
| eu-west-3 | 0.00702 | 0.00660 | 3 | 3.00000 | 3 |
| us-east-1 | 0.00770 | 0.00690 | 5 | 3.00000 | 5 |
| us-west-1 | 0.00770 | 0.00740 | 2 | 3.00000 | 2 |
| us-west-2 | 0.00771 | 0.00740 | 4 | 3.00000 | 4 |
| eu-north-1 | 0.00827 | 0.00760 | 3 | 3.00000 | 3 |

### t3.medium

| region | avg_usd | min_usd | az_samples | avg_sps | sps_az_n |
|:--|--:|--:|--:|--:|--:|
| me-south-1 | 0.00767 | 0.00610 | 3 | NA | 0 |
| ap-southeast-3 | 0.00984 | 0.00530 | 3 | NA | 0 |
| af-south-1 | 0.01217 | 0.00830 | 3 | NA | 0 |
| eu-south-1 | 0.01347 | 0.01240 | 3 | NA | 0 |
| ap-southeast-4 | 0.01554 | 0.01520 | 3 | NA | 0 |
| eu-north-1 | 0.01586 | 0.01490 | 3 | 3.00000 | 3 |
| us-west-2 | 0.01670 | 0.01540 | 4 | 3.00000 | 4 |
| us-west-1 | 0.01690 | 0.01640 | 2 | 3.00000 | 2 |
| ap-east-1 | 0.01719 | 0.01550 | 3 | NA | 0 |
| il-central-1 | 0.01730 | 0.01680 | 3 | NA | 0 |
| eu-south-2 | 0.01752 | 0.01670 | 3 | NA | 0 |
