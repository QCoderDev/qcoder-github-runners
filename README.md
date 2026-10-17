# qcoder-github-runners

This is for self-hosting github actions runners in AWS using https://github.com/CloudSnorkel/cdk-github-runners.

The starndard runners provided by GitHub tends to be quite expensive.

For example, below compares two standard instances

- [Standard linux 2-core runner](https://docs.github.com/en/billing/reference/actions-runner-pricing): 0.96 USD/hour
- [AWS c8g.medium Spot Instance](https://aws.amazon.com/ec2/instance-types/c8g/): 0.0066 USD/hour (ap-southeast-3, 30-day average as of 2026/10/11)

which leads to about 145x cost efficiency.

## Choosing an Instance Type

- **Burstable (`t3`/`t4g`) types are not provided.** They launch in `unlimited` mode, and each runner is a fresh instance with no credit balance, so any job that uses more than the baseline CPU (20–30%) pays for surplus credits: $0.05 per vCPU-hour for `t3` and $0.04 for `t4g`. For CPU-heavy jobs this cost more than the instance itself (e.g. a `t3.small` Docker build paid ~$0.0002 for the instance and ~$0.002 in credits).
- Use non-burstable types:
  - `c8g.medium` (Arm, 1 vCPU, 2 GiB) for light jobs and small Go/Python scripts.
  - `m8g.medium` (Arm, 1 vCPU, 4 GiB) for linters, code generation, Renovate and tests.
  - `m5.large` (x86, 2 vCPU, 8 GiB) for `--platform linux/amd64` Docker builds and Playwright.

## EC2 Spot Price by Region
- Run script/compare_ec2_price_by_region.sh
- Benchmark: https://browser.geekbench.com/
- Current Region: ap-southeast-3

Cheapest 20 regions in average for recent 2 years as of 2026/10/03.
`availability` is the Spot interruption frequency over the last month from the [Spot Instance Advisor](https://aws.amazon.com/ec2/spot/instance-advisor/) as of 2026/10/17 (lower is better):

### c8g.medium

| region | avg_usd | min_usd | std_dev | availability |
|:--|--:|--:|--:|--:|
| ap-south-1 | 0.00778 | 0.00540 | 0.00115 | <5% |
| ap-east-1 | 0.00895 | 0.00500 | 0.00293 | 5-10% |
| eu-south-2 | 0.00912 | 0.00560 | 0.00252 | <5% |
| eu-north-1 | 0.00921 | 0.00440 | 0.00314 | 5-10% |
| ap-south-2 | 0.01085 | 0.00570 | 0.00224 | 5-10% |
| us-east-2 | 0.01130 | 0.00710 | 0.00264 | <5% |
| ap-southeast-3 | 0.01133 | 0.00460 | 0.00315 | 5-10% |
| ap-southeast-4 | 0.01186 | 0.00770 | 0.00324 | 5-10% |
| us-west-2 | 0.01231 | 0.00510 | 0.00370 | <5% |
| ap-northeast-2 | 0.01254 | 0.00620 | 0.00303 | <5% |
| us-east-1 | 0.01282 | 0.00580 | 0.00362 | 5-10% |
| eu-central-2 | 0.01315 | 0.00860 | 0.00371 | 5-10% |
| af-south-1 | 0.01320 | 0.00560 | 0.00567 | n/a |
| ca-west-1 | 0.01378 | 0.00840 | 0.00264 | n/a |
| eu-south-1 | 0.01405 | 0.00820 | 0.00323 | 5-10% |
| sa-east-1 | 0.01417 | 0.00780 | 0.00347 | 5-10% |
| ap-east-2 | 0.01458 | 0.01220 | 0.00307 | n/a |
| eu-west-3 | 0.01561 | 0.00720 | 0.00232 | n/a |
| eu-west-1 | 0.01577 | 0.01030 | 0.00334 | <5% |
| ap-southeast-5 | 0.01630 | 0.01040 | 0.00300 | 5-10% |

### m8g.medium

| region | avg_usd | min_usd | std_dev | availability |
|:--|--:|--:|--:|--:|
| eu-south-2 | 0.00741 | 0.00500 | 0.00196 | <5% |
| ap-south-2 | 0.01014 | 0.00410 | 0.00292 | 5-10% |
| eu-north-1 | 0.01018 | 0.00480 | 0.00279 | 5-10% |
| ap-southeast-3 | 0.01085 | 0.00560 | 0.00403 | 5-10% |
| ap-south-1 | 0.01178 | 0.00740 | 0.00232 | <5% |
| sa-east-1 | 0.01282 | 0.00810 | 0.00189 | 5-10% |
| ca-west-1 | 0.01378 | 0.01010 | 0.00194 | 5-10% |
| ap-east-1 | 0.01451 | 0.00950 | 0.00279 | 5-10% |
| us-west-2 | 0.01458 | 0.00760 | 0.00351 | <5% |
| us-east-2 | 0.01501 | 0.00880 | 0.00507 | 5-10% |
| ap-northeast-2 | 0.01505 | 0.00550 | 0.00404 | 5-10% |
| af-south-1 | 0.01629 | 0.00830 | 0.00313 | 5-10% |
| ap-southeast-4 | 0.01664 | 0.01120 | 0.00274 | 5-10% |
| eu-south-1 | 0.01668 | 0.01520 | 0.00086 | 5-10% |
| us-east-1 | 0.01693 | 0.00840 | 0.00369 | 5-10% |
| us-west-1 | 0.01696 | 0.01470 | 0.00087 | <5% |
| eu-west-3 | 0.01756 | 0.01430 | 0.00140 | 5-10% |
| ca-central-1 | 0.01795 | 0.01460 | 0.00176 | <5% |
| ap-east-2 | 0.01817 | 0.01430 | 0.00371 | n/a |
| eu-central-2 | 0.01911 | 0.01510 | 0.00085 | 5-10% |

### c8g.large

| region | avg_usd | min_usd | std_dev | availability |
|:--|--:|--:|--:|--:|
| eu-south-2 | 0.01450 | 0.00860 | 0.00320 | 5-10% |
| ca-west-1 | 0.02146 | 0.01490 | 0.00526 | n/a |
| ap-south-2 | 0.02176 | 0.00960 | 0.00433 | 5-10% |
| ap-south-1 | 0.02198 | 0.01480 | 0.00358 | <5% |
| us-east-2 | 0.02321 | 0.01620 | 0.00348 | 5-10% |
| af-south-1 | 0.02395 | 0.01120 | 0.00779 | n/a |
| ap-southeast-4 | 0.02418 | 0.01640 | 0.00509 | 5-10% |
| ap-east-1 | 0.02559 | 0.01150 | 0.00632 | <5% |
| ap-southeast-3 | 0.02604 | 0.00930 | 0.00856 | <5% |
| eu-north-1 | 0.02645 | 0.01450 | 0.00459 | <5% |
| ap-east-2 | 0.02885 | 0.02480 | 0.00564 | n/a |
| eu-south-1 | 0.02972 | 0.02230 | 0.00203 | 5-10% |
| us-east-1 | 0.02975 | 0.02130 | 0.00430 | >20% |
| ap-northeast-2 | 0.02993 | 0.01480 | 0.00809 | <5% |
| eu-central-2 | 0.03097 | 0.02010 | 0.00424 | <5% |
| us-west-1 | 0.03228 | 0.02710 | 0.00231 | <5% |
| us-west-2 | 0.03265 | 0.01530 | 0.00587 | <5% |
| ap-southeast-5 | 0.03288 | 0.02220 | 0.00366 | 5-10% |
| sa-east-1 | 0.03343 | 0.02350 | 0.00401 | 10-15% |
| ap-southeast-7 | 0.03439 | 0.02370 | 0.00279 | 5-10% |

### m8g.large

| region | avg_usd | min_usd | std_dev | availability |
|:--|--:|--:|--:|--:|
| eu-south-2 | 0.01718 | 0.01000 | 0.00457 | <5% |
| ap-south-2 | 0.02165 | 0.00850 | 0.00539 | 5-10% |
| ca-west-1 | 0.02408 | 0.01710 | 0.00385 | 5-10% |
| ap-southeast-3 | 0.02418 | 0.01120 | 0.00824 | <5% |
| ap-southeast-4 | 0.02806 | 0.02170 | 0.00479 | <5% |
| af-south-1 | 0.02813 | 0.01500 | 0.00590 | 5-10% |
| ap-east-1 | 0.02937 | 0.01840 | 0.00415 | 15-20% |
| ap-south-1 | 0.02950 | 0.02180 | 0.00350 | <5% |
| eu-north-1 | 0.02986 | 0.01410 | 0.00647 | <5% |
| eu-south-1 | 0.03289 | 0.01760 | 0.00520 | <5% |
| eu-central-2 | 0.03360 | 0.02340 | 0.00416 | 5-10% |
| ap-east-2 | 0.03462 | 0.02750 | 0.00665 | n/a |
| ap-northeast-3 | 0.03608 | 0.02890 | 0.00188 | 10-15% |
| ap-northeast-2 | 0.03649 | 0.01630 | 0.00862 | 10-15% |
| us-west-2 | 0.03801 | 0.02230 | 0.00518 | <5% |
| mx-central-1 | 0.03809 | 0.02940 | 0.00544 | n/a |
| ap-southeast-7 | 0.03904 | 0.03010 | 0.00399 | 5-10% |
| sa-east-1 | 0.04123 | 0.02630 | 0.01194 | >20% |
| ap-southeast-5 | 0.04325 | 0.03380 | 0.00394 | 5-10% |
| eu-west-2 | 0.04467 | 0.01420 | 0.01164 | <5% |

### c8g.xlarge

| region | avg_usd | min_usd | std_dev | availability |
|:--|--:|--:|--:|--:|
| ap-south-2 | 0.03803 | 0.01400 | 0.00852 | <5% |
| ap-southeast-3 | 0.04493 | 0.01830 | 0.01376 | <5% |
| ap-east-1 | 0.04933 | 0.02000 | 0.01300 | <5% |
| ap-southeast-4 | 0.04951 | 0.02970 | 0.01377 | <5% |
| eu-south-2 | 0.05301 | 0.03760 | 0.00867 | >20% |
| ap-south-1 | 0.05320 | 0.03800 | 0.00756 | <5% |
| ca-west-1 | 0.05604 | 0.03750 | 0.00747 | n/a |
| eu-north-1 | 0.05651 | 0.03230 | 0.00961 | <5% |
| af-south-1 | 0.05654 | 0.02390 | 0.01658 | n/a |
| ap-east-2 | 0.05701 | 0.04940 | 0.01186 | n/a |
| eu-central-2 | 0.05839 | 0.03420 | 0.00980 | 5-10% |
| ap-northeast-2 | 0.06164 | 0.03110 | 0.01547 | <5% |
| ap-northeast-3 | 0.06192 | 0.05740 | 0.00247 | <5% |
| sa-east-1 | 0.06901 | 0.04170 | 0.00969 | >20% |
| ap-southeast-7 | 0.06967 | 0.05760 | 0.00282 | <5% |
| eu-south-1 | 0.07063 | 0.05160 | 0.00663 | <5% |
| us-east-2 | 0.07147 | 0.05460 | 0.01333 | 15-20% |
| us-west-2 | 0.07170 | 0.04710 | 0.01264 | 5-10% |
| ap-southeast-5 | 0.07180 | 0.04440 | 0.00913 | <5% |
| us-east-1 | 0.07361 | 0.05050 | 0.01311 | >20% |

### m8g.xlarge

| region | avg_usd | min_usd | std_dev | availability |
|:--|--:|--:|--:|--:|
| eu-south-2 | 0.03742 | 0.02000 | 0.01335 | <5% |
| ap-south-2 | 0.03931 | 0.01370 | 0.01072 | 5-10% |
| ap-southeast-3 | 0.04962 | 0.02240 | 0.01707 | <5% |
| af-south-1 | 0.06106 | 0.02980 | 0.01675 | 5-10% |
| ap-southeast-4 | 0.06116 | 0.04340 | 0.01129 | 5-10% |
| ap-east-1 | 0.06122 | 0.04110 | 0.00789 | >20% |
| ap-south-1 | 0.06288 | 0.04500 | 0.00678 | <5% |
| eu-north-1 | 0.06434 | 0.04230 | 0.00885 | 5-10% |
| ap-east-2 | 0.06893 | 0.05620 | 0.01300 | n/a |
| ap-northeast-3 | 0.06934 | 0.05980 | 0.00269 | 10-15% |
| eu-south-1 | 0.06947 | 0.05340 | 0.00585 | <5% |
| ap-southeast-5 | 0.07188 | 0.05680 | 0.01015 | 10-15% |
| eu-central-2 | 0.07196 | 0.05420 | 0.00482 | 5-10% |
| ap-northeast-2 | 0.07244 | 0.02430 | 0.01856 | 15-20% |
| us-west-2 | 0.07411 | 0.05390 | 0.01122 | 5-10% |
| sa-east-1 | 0.07775 | 0.05510 | 0.00937 | >20% |
| mx-central-1 | 0.07866 | 0.06180 | 0.00922 | n/a |
| us-east-2 | 0.08115 | 0.05940 | 0.01222 | 5-10% |
| ap-southeast-7 | 0.08701 | 0.06820 | 0.00560 | 5-10% |
| us-west-1 | 0.08768 | 0.07310 | 0.00798 | 5-10% |

### m7i.large

| region | avg_usd | min_usd | std_dev | availability |
|:--|--:|--:|--:|--:|
| eu-south-2 | 0.02293 | 0.01130 | 0.00617 | <5% |
| eu-north-1 | 0.02839 | 0.01440 | 0.00579 | 5-10% |
| ap-southeast-3 | 0.02946 | 0.01260 | 0.00823 | <5% |
| ap-south-2 | 0.03210 | 0.01110 | 0.00824 | n/a |
| mx-central-1 | 0.03210 | 0.02690 | 0.00157 | <5% |
| ap-east-2 | 0.03356 | 0.02770 | 0.00303 | 5-10% |
| sa-east-1 | 0.03464 | 0.02610 | 0.00389 | >20% |
| af-south-1 | 0.03593 | 0.01660 | 0.00634 | >20% |
| eu-south-1 | 0.03608 | 0.02350 | 0.00464 | >20% |
| us-east-2 | 0.03630 | 0.02960 | 0.00445 | >20% |
| ap-northeast-2 | 0.03777 | 0.02270 | 0.00536 | >20% |
| ap-south-1 | 0.03811 | 0.02290 | 0.00787 | <5% |
| ap-southeast-6 | 0.03856 | 0.03640 | 0.00097 | <5% |
| ap-east-1 | 0.03901 | 0.02880 | 0.00451 | >20% |
| ap-southeast-4 | 0.03972 | 0.02010 | 0.00501 | <5% |
| ca-central-1 | 0.04130 | 0.03430 | 0.00202 | <5% |
| eu-west-2 | 0.04130 | 0.01740 | 0.00622 | 5-10% |
| us-west-2 | 0.04216 | 0.03570 | 0.00446 | 15-20% |
| us-east-1 | 0.04218 | 0.03350 | 0.00430 | 15-20% |
| ap-southeast-7 | 0.04381 | 0.03380 | 0.00382 | <5% |

### c7i.large

| region | avg_usd | min_usd | std_dev | availability |
|:--|--:|--:|--:|--:|
| eu-south-2 | 0.02121 | 0.01130 | 0.00476 | <5% |
| us-east-2 | 0.02448 | 0.01930 | 0.00258 | 15-20% |
| ap-southeast-3 | 0.02581 | 0.01030 | 0.00722 | 10-15% |
| eu-north-1 | 0.02703 | 0.01380 | 0.00566 | 10-15% |
| ap-northeast-2 | 0.02756 | 0.01430 | 0.00503 | 5-10% |
| mx-central-1 | 0.02885 | 0.02370 | 0.00168 | <5% |
| ap-south-2 | 0.02976 | 0.01080 | 0.00822 | <5% |
| af-south-1 | 0.03108 | 0.01200 | 0.00606 | >20% |
| us-east-1 | 0.03206 | 0.02730 | 0.00190 | >20% |
| ap-east-1 | 0.03243 | 0.01610 | 0.00410 | 10-15% |
| sa-east-1 | 0.03341 | 0.02330 | 0.00757 | 10-15% |
| ca-west-1 | 0.03375 | 0.02520 | 0.00261 | n/a |
| ap-southeast-5 | 0.03387 | 0.02600 | 0.00318 | <5% |
| ap-southeast-4 | 0.03396 | 0.01970 | 0.01276 | >20% |
| ap-south-1 | 0.03443 | 0.02180 | 0.00682 | 5-10% |
| us-west-2 | 0.03540 | 0.02760 | 0.00442 | >20% |
| ap-southeast-6 | 0.03809 | 0.03420 | 0.00229 | <5% |
| ap-southeast-7 | 0.03865 | 0.03110 | 0.00335 | <5% |
| eu-west-2 | 0.03886 | 0.01610 | 0.00703 | 15-20% |
| eu-south-1 | 0.04038 | 0.02110 | 0.00806 | n/a |

### m5.large

| region | avg_usd | min_usd | std_dev | availability |
|:--|--:|--:|--:|--:|
| ap-southeast-3 | 0.02027 | 0.01200 | 0.00605 | 10-15% |
| eu-north-1 | 0.02164 | 0.01020 | 0.00624 | 5-10% |
| eu-south-1 | 0.02263 | 0.01880 | 0.00266 | >20% |
| ap-south-2 | 0.02562 | 0.01010 | 0.00874 | >20% |
| sa-east-1 | 0.02665 | 0.01880 | 0.00284 | >20% |
| af-south-1 | 0.02772 | 0.01800 | 0.00467 | >20% |
| ap-southeast-4 | 0.02970 | 0.02270 | 0.00473 | >20% |
| ap-east-1 | 0.02996 | 0.01560 | 0.00639 | >20% |
| us-east-2 | 0.03106 | 0.01850 | 0.00587 | >20% |
| ap-south-1 | 0.03151 | 0.01970 | 0.00517 | >20% |
| ap-northeast-2 | 0.03217 | 0.01600 | 0.00722 | >20% |
| il-central-1 | 0.03721 | 0.02780 | 0.00241 | >20% |
| eu-west-2 | 0.03789 | 0.03320 | 0.00219 | >20% |
| ca-central-1 | 0.03842 | 0.03330 | 0.00248 | >20% |
| eu-west-3 | 0.03920 | 0.03190 | 0.00263 | >20% |
| us-west-2 | 0.03969 | 0.03090 | 0.00343 | 15-20% |
| us-west-1 | 0.03987 | 0.03220 | 0.00404 | >20% |
| ap-northeast-3 | 0.04085 | 0.03460 | 0.00263 | 5-10% |
| eu-south-2 | 0.04102 | 0.02560 | 0.00863 | 15-20% |
| ca-west-1 | 0.04139 | 0.03270 | 0.00658 | >20% |
