# qcoder-github-runners

This is for self-hosting github actions runners in AWS using https://github.com/CloudSnorkel/cdk-github-runners.

The starndard runners provided by GitHub tends to be quite expensive.

For example, below compares two standard instances

- [Standard linux 2-core runner](https://docs.github.com/en/billing/reference/actions-runner-pricing): 0.96 USD/hour
- [AWS t4g.small Spot Instance](https://aws.amazon.com/ec2/instance-types/t4/): 0.0033 USD/hour

which leads to up to 290x cost efficiency.

## Choosing an Instance Type

Look at the effective cost per job, not just the spot price.

- **Burstable (`t3`/`t4g`) runners are charged for CPU credits.** They launch in `unlimited` mode, and each runner is a fresh instance with no credit balance, so any job that uses more than the baseline CPU (20–30%) pays for surplus credits: $0.05 per vCPU-hour for `t3` and $0.04 for `t4g`. For CPU-heavy jobs this costs more than the instance itself (e.g. a `t3.small` Docker build pays ~$0.0002 for the instance and ~$0.002 in credits).
- Use `t4g.small` only for light or mostly idle jobs (formatters, dispatching and waiting on another workflow).
- Use non-burstable types for CPU-bound jobs:
  - `m5.large` (x86, 2 vCPU, 8 GiB) for `--platform linux/amd64` Docker builds and Playwright.
  - `m8g.medium` (Arm, 1 vCPU, 4 GiB) for linters, code generation, Renovate and tests.
  - `c8g.medium` (Arm, 1 vCPU, 2 GiB) for small Go/Python scripts.
- Leave enough memory headroom. The OS, runner agent and Docker daemon take about 0.5 GiB, so a 2 GiB instance leaves about 1.3 GiB for the job. `golangci-lint` (~1.2–1.4 GiB peak) was OOM-killed on 2 GiB instances, and `next build` peaks at ~2 GiB.
- Credit charges show up as the `APS4-CPUCredits:*` usage types in Cost Explorer.

## EC2 Spot Price by Region
- Run script/compare_ec2_price_by_region.sh
- Benchmark: https://browser.geekbench.com/
- Current Region: ap-southeast-3

Cheapest 20 regions in average for recent 2 years as of 2026/10/03:

### t4g.small

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| ap-south-1 | 0.00461 | 0.00330 | 0.00062 |
| ap-south-2 | 0.00477 | 0.00250 | 0.00074 |
| sa-east-1 | 0.00481 | 0.00320 | 0.00074 |
| ap-southeast-3 | 0.00497 | 0.00210 | 0.00140 |
| us-east-2 | 0.00544 | 0.00330 | 0.00084 |
| ca-west-1 | 0.00549 | 0.00420 | 0.00073 |
| eu-south-2 | 0.00552 | 0.00310 | 0.00108 |
| eu-south-1 | 0.00574 | 0.00430 | 0.00039 |
| af-south-1 | 0.00591 | 0.00350 | 0.00091 |
| ap-east-1 | 0.00596 | 0.00450 | 0.00066 |
| eu-north-1 | 0.00637 | 0.00250 | 0.00211 |
| eu-west-3 | 0.00657 | 0.00550 | 0.00056 |
| ap-southeast-4 | 0.00667 | 0.00450 | 0.00099 |
| il-central-1 | 0.00710 | 0.00610 | 0.00058 |
| us-west-2 | 0.00719 | 0.00520 | 0.00111 |
| ap-southeast-6 | 0.00725 | 0.00630 | 0.00084 |
| ap-northeast-3 | 0.00742 | 0.00610 | 0.00138 |
| us-east-1 | 0.00750 | 0.00520 | 0.00138 |
| mx-central-1 | 0.00776 | 0.00500 | 0.00066 |
| eu-west-2 | 0.00819 | 0.00240 | 0.00269 |

### t3.small

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| ap-southeast-4 | 0.00498 | 0.00410 | 0.00029 |
| ap-southeast-3 | 0.00541 | 0.00260 | 0.00163 |
| us-east-2 | 0.00591 | 0.00430 | 0.00116 |
| ca-west-1 | 0.00620 | 0.00450 | 0.00101 |
| ap-east-1 | 0.00631 | 0.00420 | 0.00143 |
| eu-south-1 | 0.00649 | 0.00420 | 0.00101 |
| sa-east-1 | 0.00659 | 0.00560 | 0.00048 |
| ap-south-2 | 0.00673 | 0.00360 | 0.00159 |
| ap-northeast-2 | 0.00687 | 0.00350 | 0.00134 |
| eu-north-1 | 0.00692 | 0.00240 | 0.00232 |
| eu-south-2 | 0.00721 | 0.00530 | 0.00114 |
| af-south-1 | 0.00728 | 0.00460 | 0.00103 |
| us-west-2 | 0.00746 | 0.00620 | 0.00063 |
| mx-central-1 | 0.00776 | 0.00600 | 0.00097 |
| ap-south-1 | 0.00780 | 0.00520 | 0.00131 |
| il-central-1 | 0.00780 | 0.00560 | 0.00069 |
| ap-east-2 | 0.00788 | 0.00630 | 0.00120 |
| us-east-1 | 0.00798 | 0.00540 | 0.00089 |
| us-west-1 | 0.00899 | 0.00790 | 0.00061 |
| ca-central-1 | 0.00901 | 0.00790 | 0.00048 |

### t4g.medium

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| ap-south-1 | 0.00990 | 0.00770 | 0.00168 |
| ap-southeast-3 | 0.01024 | 0.00420 | 0.00313 |
| ap-south-2 | 0.01031 | 0.00550 | 0.00170 |
| us-east-2 | 0.01126 | 0.00820 | 0.00167 |
| sa-east-1 | 0.01196 | 0.00690 | 0.00373 |
| ca-west-1 | 0.01294 | 0.00990 | 0.00127 |
| il-central-1 | 0.01348 | 0.00980 | 0.00132 |
| ap-northeast-3 | 0.01374 | 0.01220 | 0.00222 |
| af-south-1 | 0.01385 | 0.01140 | 0.00157 |
| ap-southeast-4 | 0.01511 | 0.01300 | 0.00072 |
| mx-central-1 | 0.01531 | 0.01050 | 0.00214 |
| ap-northeast-2 | 0.01587 | 0.00950 | 0.00435 |
| eu-south-2 | 0.01587 | 0.00940 | 0.00317 |
| ap-east-1 | 0.01617 | 0.01150 | 0.00186 |
| ap-southeast-6 | 0.01669 | 0.01270 | 0.00343 |
| ap-southeast-7 | 0.01719 | 0.01230 | 0.00090 |
| us-west-1 | 0.01733 | 0.01370 | 0.00227 |
| ap-east-2 | 0.01741 | 0.01540 | 0.00098 |
| eu-north-1 | 0.01751 | 0.00850 | 0.00593 |
| us-west-2 | 0.01764 | 0.01240 | 0.00227 |

### t3.medium

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| ap-southeast-3 | 0.01258 | 0.00530 | 0.00342 |
| sa-east-1 | 0.01418 | 0.01060 | 0.00165 |
| eu-south-2 | 0.01439 | 0.01040 | 0.00291 |
| us-east-2 | 0.01467 | 0.01050 | 0.00156 |
| eu-north-1 | 0.01531 | 0.00710 | 0.00436 |
| eu-south-1 | 0.01532 | 0.01360 | 0.00093 |
| ap-southeast-4 | 0.01544 | 0.01150 | 0.00135 |
| ap-northeast-2 | 0.01577 | 0.01020 | 0.00227 |
| ca-west-1 | 0.01582 | 0.01380 | 0.00102 |
| il-central-1 | 0.01608 | 0.01440 | 0.00043 |
| ap-south-2 | 0.01618 | 0.00860 | 0.00320 |
| af-south-1 | 0.01639 | 0.01440 | 0.00186 |
| eu-west-2 | 0.01700 | 0.01300 | 0.00116 |
| us-east-1 | 0.01765 | 0.01520 | 0.00135 |
| ap-south-1 | 0.01792 | 0.01330 | 0.00204 |
| us-west-2 | 0.01812 | 0.01380 | 0.00146 |
| ca-central-1 | 0.01869 | 0.01650 | 0.00087 |
| ap-east-1 | 0.01879 | 0.01400 | 0.00237 |
| us-west-1 | 0.01991 | 0.01730 | 0.00167 |
| ap-northeast-1 | 0.02011 | 0.01740 | 0.00141 |

### c8g.medium

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| ap-south-1 | 0.00778 | 0.00540 | 0.00115 |
| ap-east-1 | 0.00895 | 0.00500 | 0.00293 |
| eu-south-2 | 0.00912 | 0.00560 | 0.00252 |
| eu-north-1 | 0.00921 | 0.00440 | 0.00314 |
| ap-south-2 | 0.01085 | 0.00570 | 0.00224 |
| us-east-2 | 0.01130 | 0.00710 | 0.00264 |
| ap-southeast-3 | 0.01133 | 0.00460 | 0.00315 |
| ap-southeast-4 | 0.01186 | 0.00770 | 0.00324 |
| us-west-2 | 0.01231 | 0.00510 | 0.00370 |
| ap-northeast-2 | 0.01254 | 0.00620 | 0.00303 |
| us-east-1 | 0.01282 | 0.00580 | 0.00362 |
| eu-central-2 | 0.01315 | 0.00860 | 0.00371 |
| af-south-1 | 0.01320 | 0.00560 | 0.00567 |
| ca-west-1 | 0.01378 | 0.00840 | 0.00264 |
| eu-south-1 | 0.01405 | 0.00820 | 0.00323 |
| sa-east-1 | 0.01417 | 0.00780 | 0.00347 |
| ap-east-2 | 0.01458 | 0.01220 | 0.00307 |
| eu-west-3 | 0.01561 | 0.00720 | 0.00232 |
| eu-west-1 | 0.01577 | 0.01030 | 0.00334 |
| ap-southeast-5 | 0.01630 | 0.01040 | 0.00300 |

### m8g.medium

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| eu-south-2 | 0.00741 | 0.00500 | 0.00196 |
| ap-south-2 | 0.01014 | 0.00410 | 0.00292 |
| eu-north-1 | 0.01018 | 0.00480 | 0.00279 |
| ap-southeast-3 | 0.01085 | 0.00560 | 0.00403 |
| ap-south-1 | 0.01178 | 0.00740 | 0.00232 |
| sa-east-1 | 0.01282 | 0.00810 | 0.00189 |
| ca-west-1 | 0.01378 | 0.01010 | 0.00194 |
| ap-east-1 | 0.01451 | 0.00950 | 0.00279 |
| us-west-2 | 0.01458 | 0.00760 | 0.00351 |
| us-east-2 | 0.01501 | 0.00880 | 0.00507 |
| ap-northeast-2 | 0.01505 | 0.00550 | 0.00404 |
| af-south-1 | 0.01629 | 0.00830 | 0.00313 |
| ap-southeast-4 | 0.01664 | 0.01120 | 0.00274 |
| eu-south-1 | 0.01668 | 0.01520 | 0.00086 |
| us-east-1 | 0.01693 | 0.00840 | 0.00369 |
| us-west-1 | 0.01696 | 0.01470 | 0.00087 |
| eu-west-3 | 0.01756 | 0.01430 | 0.00140 |
| ca-central-1 | 0.01795 | 0.01460 | 0.00176 |
| ap-east-2 | 0.01817 | 0.01430 | 0.00371 |
| eu-central-2 | 0.01911 | 0.01510 | 0.00085 |

### t4g.large

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| ap-south-1 | 0.01684 | 0.01270 | 0.00187 |
| ap-south-2 | 0.01778 | 0.00930 | 0.00321 |
| us-east-2 | 0.01916 | 0.01340 | 0.00268 |
| eu-south-2 | 0.02137 | 0.01110 | 0.00466 |
| ca-west-1 | 0.02358 | 0.01800 | 0.00245 |
| sa-east-1 | 0.02417 | 0.01700 | 0.00438 |
| ap-southeast-3 | 0.02488 | 0.00850 | 0.00737 |
| us-east-1 | 0.02549 | 0.02040 | 0.00250 |
| eu-north-1 | 0.02556 | 0.00930 | 0.00905 |
| ap-northeast-3 | 0.02593 | 0.02400 | 0.00222 |
| ap-southeast-4 | 0.02625 | 0.01710 | 0.00310 |
| ap-northeast-2 | 0.02676 | 0.01410 | 0.00741 |
| af-south-1 | 0.02689 | 0.02200 | 0.00336 |
| ap-southeast-6 | 0.02776 | 0.02590 | 0.00114 |
| eu-south-1 | 0.02787 | 0.02250 | 0.00229 |
| ap-east-1 | 0.02809 | 0.01960 | 0.00247 |
| us-west-2 | 0.02849 | 0.02190 | 0.00321 |
| il-central-1 | 0.02885 | 0.02320 | 0.00177 |
| mx-central-1 | 0.02917 | 0.02040 | 0.00281 |
| us-west-1 | 0.03214 | 0.02720 | 0.00352 |

### t3.large

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| ca-west-1 | 0.01743 | 0.01090 | 0.00284 |
| ap-southeast-4 | 0.01907 | 0.01480 | 0.00113 |
| ap-southeast-3 | 0.01963 | 0.01060 | 0.00692 |
| ap-south-2 | 0.02229 | 0.00900 | 0.00603 |
| eu-south-2 | 0.02531 | 0.01190 | 0.00719 |
| ap-northeast-2 | 0.02633 | 0.01040 | 0.00799 |
| af-south-1 | 0.02647 | 0.02080 | 0.00352 |
| eu-north-1 | 0.02769 | 0.01580 | 0.00475 |
| us-east-2 | 0.02787 | 0.02270 | 0.00313 |
| ap-east-1 | 0.02815 | 0.01770 | 0.00588 |
| ap-east-2 | 0.02844 | 0.02330 | 0.00334 |
| mx-central-1 | 0.02903 | 0.02350 | 0.00210 |
| il-central-1 | 0.03019 | 0.01880 | 0.00727 |
| us-east-1 | 0.03078 | 0.02580 | 0.00253 |
| ap-south-1 | 0.03142 | 0.01920 | 0.00521 |
| us-west-2 | 0.03207 | 0.02760 | 0.00283 |
| ap-southeast-6 | 0.03225 | 0.03070 | 0.00077 |
| eu-west-2 | 0.03321 | 0.01250 | 0.00662 |
| eu-south-1 | 0.03369 | 0.02810 | 0.00361 |
| ca-central-1 | 0.03378 | 0.02520 | 0.00413 |

### c8g.large

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| eu-south-2 | 0.01450 | 0.00860 | 0.00320 |
| ca-west-1 | 0.02146 | 0.01490 | 0.00526 |
| ap-south-2 | 0.02176 | 0.00960 | 0.00433 |
| ap-south-1 | 0.02198 | 0.01480 | 0.00358 |
| us-east-2 | 0.02321 | 0.01620 | 0.00348 |
| af-south-1 | 0.02395 | 0.01120 | 0.00779 |
| ap-southeast-4 | 0.02418 | 0.01640 | 0.00509 |
| ap-east-1 | 0.02559 | 0.01150 | 0.00632 |
| ap-southeast-3 | 0.02604 | 0.00930 | 0.00856 |
| eu-north-1 | 0.02645 | 0.01450 | 0.00459 |
| ap-east-2 | 0.02885 | 0.02480 | 0.00564 |
| eu-south-1 | 0.02972 | 0.02230 | 0.00203 |
| us-east-1 | 0.02975 | 0.02130 | 0.00430 |
| ap-northeast-2 | 0.02993 | 0.01480 | 0.00809 |
| eu-central-2 | 0.03097 | 0.02010 | 0.00424 |
| us-west-1 | 0.03228 | 0.02710 | 0.00231 |
| us-west-2 | 0.03265 | 0.01530 | 0.00587 |
| ap-southeast-5 | 0.03288 | 0.02220 | 0.00366 |
| sa-east-1 | 0.03343 | 0.02350 | 0.00401 |
| ap-southeast-7 | 0.03439 | 0.02370 | 0.00279 |

### m8g.large

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| eu-south-2 | 0.01718 | 0.01000 | 0.00457 |
| ap-south-2 | 0.02165 | 0.00850 | 0.00539 |
| ca-west-1 | 0.02408 | 0.01710 | 0.00385 |
| ap-southeast-3 | 0.02418 | 0.01120 | 0.00824 |
| ap-southeast-4 | 0.02806 | 0.02170 | 0.00479 |
| af-south-1 | 0.02813 | 0.01500 | 0.00590 |
| ap-east-1 | 0.02937 | 0.01840 | 0.00415 |
| ap-south-1 | 0.02950 | 0.02180 | 0.00350 |
| eu-north-1 | 0.02986 | 0.01410 | 0.00647 |
| eu-south-1 | 0.03289 | 0.01760 | 0.00520 |
| eu-central-2 | 0.03360 | 0.02340 | 0.00416 |
| ap-east-2 | 0.03462 | 0.02750 | 0.00665 |
| ap-northeast-3 | 0.03608 | 0.02890 | 0.00188 |
| ap-northeast-2 | 0.03649 | 0.01630 | 0.00862 |
| us-west-2 | 0.03801 | 0.02230 | 0.00518 |
| mx-central-1 | 0.03809 | 0.02940 | 0.00544 |
| ap-southeast-7 | 0.03904 | 0.03010 | 0.00399 |
| sa-east-1 | 0.04123 | 0.02630 | 0.01194 |
| ap-southeast-5 | 0.04325 | 0.03380 | 0.00394 |
| eu-west-2 | 0.04467 | 0.01420 | 0.01164 |

### t4g.xlarge

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| ca-west-1 | 0.03275 | 0.02310 | 0.00745 |
| ap-south-2 | 0.03406 | 0.01650 | 0.00649 |
| eu-south-2 | 0.03443 | 0.01540 | 0.01225 |
| ap-south-1 | 0.03824 | 0.02890 | 0.00403 |
| eu-north-1 | 0.03905 | 0.01670 | 0.00937 |
| il-central-1 | 0.04075 | 0.02800 | 0.01367 |
| ap-southeast-4 | 0.04172 | 0.02820 | 0.00542 |
| ap-southeast-3 | 0.04450 | 0.01700 | 0.01307 |
| eu-central-2 | 0.04750 | 0.01690 | 0.01654 |
| af-south-1 | 0.04866 | 0.03300 | 0.00457 |
| ap-northeast-3 | 0.05115 | 0.04830 | 0.00172 |
| us-east-2 | 0.05399 | 0.04370 | 0.00606 |
| eu-south-1 | 0.05499 | 0.04660 | 0.00293 |
| ap-southeast-6 | 0.05717 | 0.04920 | 0.00705 |
| sa-east-1 | 0.05903 | 0.04900 | 0.00501 |
| ap-northeast-2 | 0.05904 | 0.01660 | 0.02051 |
| ap-southeast-7 | 0.05913 | 0.04180 | 0.00964 |
| mx-central-1 | 0.05963 | 0.03620 | 0.01042 |
| ap-east-1 | 0.06183 | 0.04510 | 0.00917 |
| us-east-1 | 0.06548 | 0.04860 | 0.00764 |

### t3.xlarge

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| ca-west-1 | 0.03223 | 0.02180 | 0.00500 |
| ap-southeast-4 | 0.03660 | 0.02890 | 0.00205 |
| ap-southeast-3 | 0.03846 | 0.02110 | 0.01407 |
| eu-south-2 | 0.04103 | 0.02030 | 0.01396 |
| eu-north-1 | 0.04796 | 0.02850 | 0.00831 |
| ap-northeast-2 | 0.05053 | 0.02080 | 0.01472 |
| ap-south-2 | 0.05059 | 0.01790 | 0.01251 |
| eu-central-2 | 0.05291 | 0.03700 | 0.01010 |
| ap-south-1 | 0.05401 | 0.03930 | 0.00694 |
| ap-east-2 | 0.05411 | 0.04390 | 0.00510 |
| us-east-2 | 0.05603 | 0.04060 | 0.00539 |
| ap-east-1 | 0.05841 | 0.04170 | 0.00815 |
| af-south-1 | 0.05851 | 0.04510 | 0.00628 |
| us-east-1 | 0.05872 | 0.04350 | 0.00730 |
| sa-east-1 | 0.06032 | 0.04860 | 0.00586 |
| us-west-2 | 0.06084 | 0.05330 | 0.00441 |
| eu-south-1 | 0.06255 | 0.04510 | 0.00681 |
| ap-northeast-1 | 0.06341 | 0.05040 | 0.00712 |
| ap-southeast-5 | 0.06441 | 0.05370 | 0.00422 |
| eu-west-2 | 0.06518 | 0.02690 | 0.01019 |

### c8g.xlarge

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| ap-south-2 | 0.03803 | 0.01400 | 0.00852 |
| ap-southeast-3 | 0.04493 | 0.01830 | 0.01376 |
| ap-east-1 | 0.04933 | 0.02000 | 0.01300 |
| ap-southeast-4 | 0.04951 | 0.02970 | 0.01377 |
| eu-south-2 | 0.05301 | 0.03760 | 0.00867 |
| ap-south-1 | 0.05320 | 0.03800 | 0.00756 |
| ca-west-1 | 0.05604 | 0.03750 | 0.00747 |
| eu-north-1 | 0.05651 | 0.03230 | 0.00961 |
| af-south-1 | 0.05654 | 0.02390 | 0.01658 |
| ap-east-2 | 0.05701 | 0.04940 | 0.01186 |
| eu-central-2 | 0.05839 | 0.03420 | 0.00980 |
| ap-northeast-2 | 0.06164 | 0.03110 | 0.01547 |
| ap-northeast-3 | 0.06192 | 0.05740 | 0.00247 |
| sa-east-1 | 0.06901 | 0.04170 | 0.00969 |
| ap-southeast-7 | 0.06967 | 0.05760 | 0.00282 |
| eu-south-1 | 0.07063 | 0.05160 | 0.00663 |
| us-east-2 | 0.07147 | 0.05460 | 0.01333 |
| us-west-2 | 0.07170 | 0.04710 | 0.01264 |
| ap-southeast-5 | 0.07180 | 0.04440 | 0.00913 |
| us-east-1 | 0.07361 | 0.05050 | 0.01311 |

### m8g.xlarge

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| eu-south-2 | 0.03742 | 0.02000 | 0.01335 |
| ap-south-2 | 0.03931 | 0.01370 | 0.01072 |
| ap-southeast-3 | 0.04962 | 0.02240 | 0.01707 |
| af-south-1 | 0.06106 | 0.02980 | 0.01675 |
| ap-southeast-4 | 0.06116 | 0.04340 | 0.01129 |
| ap-east-1 | 0.06122 | 0.04110 | 0.00789 |
| ap-south-1 | 0.06288 | 0.04500 | 0.00678 |
| eu-north-1 | 0.06434 | 0.04230 | 0.00885 |
| ap-east-2 | 0.06893 | 0.05620 | 0.01300 |
| ap-northeast-3 | 0.06934 | 0.05980 | 0.00269 |
| eu-south-1 | 0.06947 | 0.05340 | 0.00585 |
| ap-southeast-5 | 0.07188 | 0.05680 | 0.01015 |
| eu-central-2 | 0.07196 | 0.05420 | 0.00482 |
| ap-northeast-2 | 0.07244 | 0.02430 | 0.01856 |
| us-west-2 | 0.07411 | 0.05390 | 0.01122 |
| sa-east-1 | 0.07775 | 0.05510 | 0.00937 |
| mx-central-1 | 0.07866 | 0.06180 | 0.00922 |
| us-east-2 | 0.08115 | 0.05940 | 0.01222 |
| ap-southeast-7 | 0.08701 | 0.06820 | 0.00560 |
| us-west-1 | 0.08768 | 0.07310 | 0.00798 |

### m7i.large

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| eu-south-2 | 0.02293 | 0.01130 | 0.00617 |
| eu-north-1 | 0.02839 | 0.01440 | 0.00579 |
| ap-southeast-3 | 0.02946 | 0.01260 | 0.00823 |
| ap-south-2 | 0.03210 | 0.01110 | 0.00824 |
| mx-central-1 | 0.03210 | 0.02690 | 0.00157 |
| ap-east-2 | 0.03356 | 0.02770 | 0.00303 |
| sa-east-1 | 0.03464 | 0.02610 | 0.00389 |
| af-south-1 | 0.03593 | 0.01660 | 0.00634 |
| eu-south-1 | 0.03608 | 0.02350 | 0.00464 |
| us-east-2 | 0.03630 | 0.02960 | 0.00445 |
| ap-northeast-2 | 0.03777 | 0.02270 | 0.00536 |
| ap-south-1 | 0.03811 | 0.02290 | 0.00787 |
| ap-southeast-6 | 0.03856 | 0.03640 | 0.00097 |
| ap-east-1 | 0.03901 | 0.02880 | 0.00451 |
| ap-southeast-4 | 0.03972 | 0.02010 | 0.00501 |
| ca-central-1 | 0.04130 | 0.03430 | 0.00202 |
| eu-west-2 | 0.04130 | 0.01740 | 0.00622 |
| us-west-2 | 0.04216 | 0.03570 | 0.00446 |
| us-east-1 | 0.04218 | 0.03350 | 0.00430 |
| ap-southeast-7 | 0.04381 | 0.03380 | 0.00382 |

### c7i.large

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| eu-south-2 | 0.02121 | 0.01130 | 0.00476 |
| us-east-2 | 0.02448 | 0.01930 | 0.00258 |
| ap-southeast-3 | 0.02581 | 0.01030 | 0.00722 |
| eu-north-1 | 0.02703 | 0.01380 | 0.00566 |
| ap-northeast-2 | 0.02756 | 0.01430 | 0.00503 |
| mx-central-1 | 0.02885 | 0.02370 | 0.00168 |
| ap-south-2 | 0.02976 | 0.01080 | 0.00822 |
| af-south-1 | 0.03108 | 0.01200 | 0.00606 |
| us-east-1 | 0.03206 | 0.02730 | 0.00190 |
| ap-east-1 | 0.03243 | 0.01610 | 0.00410 |
| sa-east-1 | 0.03341 | 0.02330 | 0.00757 |
| ca-west-1 | 0.03375 | 0.02520 | 0.00261 |
| ap-southeast-5 | 0.03387 | 0.02600 | 0.00318 |
| ap-southeast-4 | 0.03396 | 0.01970 | 0.01276 |
| ap-south-1 | 0.03443 | 0.02180 | 0.00682 |
| us-west-2 | 0.03540 | 0.02760 | 0.00442 |
| ap-southeast-6 | 0.03809 | 0.03420 | 0.00229 |
| ap-southeast-7 | 0.03865 | 0.03110 | 0.00335 |
| eu-west-2 | 0.03886 | 0.01610 | 0.00703 |
| eu-south-1 | 0.04038 | 0.02110 | 0.00806 |

### m5.large

| region | avg_usd | min_usd | std_dev |
|:--|--:|--:|--:|
| ap-southeast-3 | 0.02027 | 0.01200 | 0.00605 |
| eu-north-1 | 0.02164 | 0.01020 | 0.00624 |
| eu-south-1 | 0.02263 | 0.01880 | 0.00266 |
| ap-south-2 | 0.02562 | 0.01010 | 0.00874 |
| sa-east-1 | 0.02665 | 0.01880 | 0.00284 |
| af-south-1 | 0.02772 | 0.01800 | 0.00467 |
| ap-southeast-4 | 0.02970 | 0.02270 | 0.00473 |
| ap-east-1 | 0.02996 | 0.01560 | 0.00639 |
| us-east-2 | 0.03106 | 0.01850 | 0.00587 |
| ap-south-1 | 0.03151 | 0.01970 | 0.00517 |
| ap-northeast-2 | 0.03217 | 0.01600 | 0.00722 |
| il-central-1 | 0.03721 | 0.02780 | 0.00241 |
| eu-west-2 | 0.03789 | 0.03320 | 0.00219 |
| ca-central-1 | 0.03842 | 0.03330 | 0.00248 |
| eu-west-3 | 0.03920 | 0.03190 | 0.00263 |
| us-west-2 | 0.03969 | 0.03090 | 0.00343 |
| us-west-1 | 0.03987 | 0.03220 | 0.00404 |
| ap-northeast-3 | 0.04085 | 0.03460 | 0.00263 |
| eu-south-2 | 0.04102 | 0.02560 | 0.00863 |
| ca-west-1 | 0.04139 | 0.03270 | 0.00658 |
