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
- Run script/compare_ec2_price_by_region.sh
- Benchmark: https://browser.geekbench.com/

Cheapest 10 regions as of 2025/9/20 7:32 pm JST:
### t4g.small

| region | avg_usd | min_usd |
|:--|--:|--:|
| ap-southeast-3 | 0.00217 | 0.00210 |
| me-south-1 | 0.00312 | 0.00250 |
| ap-east-1 | 0.00330 | 0.00300 |
| eu-south-1 | 0.00330 | 0.00190 |
| af-south-1 | 0.00342 | 0.00220 |
| ap-south-1 | 0.00379 | 0.00280 |
| eu-west-3 | 0.00408 | 0.00300 |
| ap-south-2 | 0.00461 | 0.00420 |
| us-east-2 | 0.00520 | 0.00510 |
| us-west-1 | 0.00583 | 0.00530 |
| me-central-1 | 0.00625 | 0.00600 |

### t3.small

| region | avg_usd | min_usd |
|:--|--:|--:|
| eu-south-1 | 0.00242 | 0.00240 |
| af-south-1 | 0.00271 | 0.00270 |
| me-south-1 | 0.00377 | 0.00300 |
| ap-east-1 | 0.00378 | 0.00340 |
| ap-southeast-3 | 0.00441 | 0.00260 |
| ap-southeast-4 | 0.00639 | 0.00590 |
| eu-west-3 | 0.00702 | 0.00660 |
| us-east-1 | 0.00767 | 0.00690 |
| us-west-1 | 0.00770 | 0.00740 |
| us-west-2 | 0.00771 | 0.00740 |
| eu-north-1 | 0.00828 | 0.00760 |

### t4g.medium

| region | avg_usd | min_usd |
|:--|--:|--:|
| me-south-1 | 0.00798 | 0.00530 |
| ap-south-1 | 0.00845 | 0.00800 |
| af-south-1 | 0.00914 | 0.00690 |
| ap-south-2 | 0.00972 | 0.00930 |
| ap-southeast-3 | 0.00990 | 0.00540 |
| eu-west-3 | 0.01009 | 0.00910 |
| eu-south-1 | 0.01014 | 0.00900 |
| me-central-1 | 0.01231 | 0.01160 |
| ap-southeast-4 | 0.01249 | 0.01210 |
| eu-north-1 | 0.01275 | 0.01170 |
| us-east-1 | 0.01339 | 0.01120 |

### t3.medium

| region | avg_usd | min_usd |
|:--|--:|--:|
| me-south-1 | 0.00770 | 0.00610 |
| ap-southeast-3 | 0.00979 | 0.00530 |
| af-south-1 | 0.01219 | 0.00830 |
| eu-south-1 | 0.01345 | 0.01240 |
| ap-southeast-4 | 0.01556 | 0.01520 |
| eu-north-1 | 0.01586 | 0.01490 |
| us-west-2 | 0.01668 | 0.01540 |
| us-west-1 | 0.01690 | 0.01640 |
| ap-east-1 | 0.01723 | 0.01580 |
| il-central-1 | 0.01730 | 0.01680 |
| eu-south-2 | 0.01752 | 0.01670 |

### c8g.medium

| region | avg_usd | min_usd |
|:--|--:|--:|
| ap-southeast-3 | 0.00475 | 0.00460 |
| sa-east-1 | 0.00610 | 0.00610 |
| ap-south-1 | 0.00702 | 0.00650 |
| ap-south-2 | 0.00888 | 0.00830 |
| us-west-1 | 0.01198 | 0.01040 |
| eu-south-2 | 0.01239 | 0.01080 |
| ap-northeast-2 | 0.01334 | 0.01270 |
| eu-north-1 | 0.01337 | 0.01310 |
| us-east-2 | 0.01358 | 0.01040 |
| eu-central-1 | 0.01424 | 0.01310 |
| us-west-2 | 0.01438 | 0.01340 |

### t4g.large

| region | avg_usd | min_usd |
|:--|--:|--:|
| ap-southeast-3 | 0.01024 | 0.00850 |
| me-south-1 | 0.01311 | 0.01040 |
| eu-south-1 | 0.01418 | 0.00770 |
| af-south-1 | 0.01441 | 0.00870 |
| ap-south-1 | 0.01692 | 0.01550 |
| ap-south-2 | 0.01795 | 0.01720 |
| ap-east-1 | 0.01958 | 0.01340 |
| eu-west-3 | 0.02128 | 0.02030 |
| ap-southeast-4 | 0.02375 | 0.02280 |
| us-east-1 | 0.02463 | 0.02020 |
| eu-south-2 | 0.02608 | 0.02210 |

### t3.large

| region | avg_usd | min_usd |
|:--|--:|--:|
| af-south-1 | 0.01093 | 0.01090 |
| me-south-1 | 0.01528 | 0.01220 |
| ap-southeast-3 | 0.01855 | 0.01060 |
| eu-south-1 | 0.02025 | 0.00960 |
| ap-southeast-4 | 0.02474 | 0.02340 |
| eu-south-2 | 0.02851 | 0.02480 |
| ap-east-1 | 0.03063 | 0.02800 |
| us-west-1 | 0.03103 | 0.03030 |
| eu-north-1 | 0.03129 | 0.03040 |
| eu-west-3 | 0.03351 | 0.02920 |
| us-west-2 | 0.03453 | 0.03240 |

### c8g.large

| region | avg_usd | min_usd |
|:--|--:|--:|
| ap-southeast-3 | 0.00977 | 0.00920 |
| ap-south-2 | 0.01698 | 0.01540 |
| us-west-1 | 0.02420 | 0.02100 |
| eu-south-2 | 0.02522 | 0.02330 |
| ap-south-1 | 0.02679 | 0.02520 |
| sa-east-1 | 0.02893 | 0.01220 |
| ap-southeast-7 | 0.02926 | 0.02750 |
| us-east-2 | 0.03004 | 0.02600 |
| eu-north-1 | 0.03009 | 0.02900 |
| ap-southeast-5 | 0.03052 | 0.02780 |
| us-west-2 | 0.03196 | 0.02940 |
