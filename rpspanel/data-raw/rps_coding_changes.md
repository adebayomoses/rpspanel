# RPS rule coding: verification and extension (October 2026)

This file records how `inst/extdata/rps_rules.csv` and `rps_targets.csv` were
checked and extended. `source("data-raw/check_rps_rules.R")` reports 51 of 51
states coded, no missing coverage shares, and final targets that match the
target schedules. `testthat::test_local()` passes (113 tests).

## Coding conventions

- **Coverage share** is the share of statewide retail sales that is subject
  to the RPS. It is taken from LBNL's "RPS-Applicable Sales" and "Statewide
  Sales" sheets for 2023. Exceptions: MT uses 2020, its last year in force.
  KS and WV come from EIA State Electricity Profiles 2024, Tables 3 and 9,
  because LBNL reports no applicable sales for them.
- **Tier choice.** The coding uses the main new-renewables tier including
  its carve-outs. Existing-resource tiers and non-renewable tiers are left
  out: MA Class II, MD Tier 2, NJ Class II, PA Tier II, CT Class II/III,
  DC Tier 2, ME Class II, NH Classes III/IV and RI existing. Each row's
  `notes` says which tiers were left out.
- **Utility-specific schedules.** States with different targets by utility
  type use the schedule of the largest obligated group: CO IOUs, MN non-Xcel,
  NC IOUs, OR large IOUs, NM IOUs and VA Dominion. `notes` gives the gap
  between that schedule and LBNL's sales-weighted average.
- **Interim targets.** Where the statute has an annual schedule, the target
  rows are the fewest breakpoints that reproduce the annual values within
  0.25 percentage points under linear interpolation. Hold points are added so
  that step schedules stay flat. This applies to CT DC ME MI MD MO MT NH NJ
  NM NV OH PA RI VT WI. The annual values come from LBNL calendar-year data,
  except MD, which comes from the statute.
- **repeal_year** is the first year in which the requirement no longer
  applies, so a state is in force for years `< repeal_year`.
- **acp_usd_mwh** is filled only where the statute or DSIRE gives a single
  base non-solar ACP. It is left `NA` where the level varies by year or is
  set by the regulator: MD, IL, NH and OR.

## Changes to the 14 starter states (all now `verified = TRUE`)

| State | Change |
|---|---|
| AZ | coverage 0.589; added 2009 and 2010 targets; **repeal_year 2026** (the ACC voted 5-0 on 4 March 2026 to repeal REST) |
| CA | coverage 1.00 -> 0.985; added 2003 starting target 0.1185 (LBNL large-IOU level) |
| CO | coverage 0.990 |
| IL | coverage 0.929; added 2009, 2010 and 2015 targets (statutory 4%, 5%, 10%) |
| MA | **final target 0.35 -> 0.40 in 2030** (2021 Climate Act); added 2024 and 2029 points; coverage 0.887; ACP $50 |
| MD | coverage 1.00 -> 0.980; full Tier 1 schedule from Pub. Util. 7-703(b), replacing the 2006 -> 2020 straight line, which overstated 2010-2018; added the geothermal carve-out |
| MN | coverage 1.00 -> 0.999; added 2034 = 0.25 (25% holds until 55% in 2035) |
| NC | coverage 1.00 -> 0.998 |
| NJ | first compliance 2001 -> 2002 (LBNL first energy year); full Class I schedule replacing the 1999 -> 2021 straight line; coverage 0.990; ACP $50 |
| NV | first compliance 2005 -> 2003 (5% from 2003 under SB 372 of 2001); full biennial schedule; coverage 0.929 |
| NY | added 2006 = 0.193 (2004 baseline) and 2021 = 0.32 (LBNL); coverage 0.983 |
| OR | carve-out 0 -> 1 (IOU solar requirement, HB 3039); coverage 0.808 |
| TX | **repeal_year 2025** (HB 1500 of 2023 ended the mandate; solar-only transition to 1 Sept 2025); added SB 7 / SB 20 interim MW targets; coverage 0.757; ACP $50 |
| WA | coverage 0.874; no other change |

## The 25 newly coded states

- **RPS (has_rps = 1):** CT DE DC HI IA KS ME MI MO MT NH NM OH PA RI VT VA
  WI WV.
  - Repeals: KS 2015 (SB 91), MT 2021 (HB 576), OH 2027 (HB 6 ends the
    requirement after 2026), WV 2015 (HB 2001).
  - IA is coded as `capacity_mw` (105 MW).
  - KS uses LBNL's sales-equivalent shares of its peak-capacity standard.
  - WV is coded as an RPS because the task asked for it. It was an
    alternative-energy standard with no renewable minimum, it never reached a
    compliance year, and LBNL does not count it. Set `has_rps = 0` if you
    prefer LBNL's convention.
- **No mandatory RPS (has_rps = 0), voluntary goals named:** IN (2011 CPS),
  ND (2007), OK (2010), SC (2014 DER program), SD (2008), UT (2008).

## Judgement calls worth a second look

- **AZ**: enactment is 2006 (REST). The 2001 Environmental Portfolio
  Standard is not coded.
- **HI**: enactment is 2004 (Act 95). The 2001 Act 272 set a goal only.
- **WI**: first compliance is 2006 (Act 141 levels). The 1999 Act 9
  incremental schedule is not coded.
- **ME**: nominal is 0 in 2000-2007 because the 30% existing-resource class is
  excluded.
- **IA**: first compliance year is set to the enactment year (1983) because
  the law has no dated schedule.
- **DE**: the 2008-2009 targets are interpolated between 1% in 2007 (PSC
  Order 7933) and 5% in 2010 (SB 119).
- **One coverage value per state**: NY covered about 0.73 of sales before
  2017. VA percentages apply to sales net of nuclear.
- **The 12 original no-RPS rows** were not re-checked and stay
  `verified = FALSE`.

## Other files changed

- `tests/testthat/test-panel.R` read CA coverage as a hard-coded 1. It now
  reads the bundled value.
- The status text in `README.Rmd`/`README.md`, `vignettes/rps-stringency.Rmd`,
  `NEWS.md`, and the roxygen in `R/rps_rules.R` with its `man/rps_rules.Rd`
  now describe the verified coding.

## Sources

- LBNL, *State Electricity Resource Standards*, data files updated June 2026,
  from https://emp.lbl.gov/projects/renewables-portfolio:
  - "RPS & CES Targets and Demand" (target schedules and RPS-applicable and
    statewide sales)
  - "Historical RPS & CES Target Achievement and Compliance Costs" (checked,
    not used directly)
- DSIRE program pages, https://programs.dsireusa.org/system/program/detail/ID,
  read October 2026: AZ 268, CA 840, CO 133, CT 195, DC 303, DE 1231, HI 606,
  IA 265, IL 584, IN 4832, KS 3401, MA 479, MD 1085, ME 452, MI 3094,
  MN 2401, MO 2622, MT 384, NC 2660, ND 2697, NH 2523, NJ 564, NM 720,
  NV 373, NY 5883, OH 2934, OK 4178, OR 2594, PA 262, RI 1095, SC 5505,
  SD 2898, UT 2901, VA 22133, VT 5786, WA 2350, WI 190.
- Statute texts:
  - Md. Code, Public Utilities 7-703 (mgaleg.maryland.gov)
  - 26 Del. C. 354 (delcode.delaware.gov)
  - Delaware SB 119, Chapter 451 (depsc.delaware.gov)
  - Va. Code 56-585.5 (law.lis.virginia.gov)
- West Virginia HB 2001 (2015) bill text and history (wvlegislature.gov),
  plus news coverage of the repeal (Power Magazine, World Coal).
- Texas HB 1500 (2023): 16 TAC 25.173 and ERCOT NPRR 1250, with the PUCT
  report.
- Arizona REST repeal: KJZZ, 5 March 2026, and ACC news releases of 5 March
  2026 and 15 August 2025.
- EIA State Electricity Profiles 2024 for Kansas and West Virginia, Tables 3
  and 9 (EIA-861).
