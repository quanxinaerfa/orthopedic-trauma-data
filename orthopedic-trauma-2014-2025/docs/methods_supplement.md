# Methodological Supplement

This document provides additional methodological details that complement
the Methods section of the manuscript.

## 1. Inclusion criterion definition

The inclusion criterion is **discharge date** between 1 January 2014 and
31 December 2025. We chose discharge date (rather than admission date)
because only discharged episodes have complete length-of-stay, cost, and
discharge-diagnosis data. Admissions still in-hospital on 31 December 2025
were excluded.

## 2. Patient origin classification

Patient origin is derived from the first 6 digits of the national identity
card number (身份证号), which encode the registered residence at birth:

- **江苏本地 (Local Jiangsu)**: First 2 digits = "32" (Jiangsu Province)
- **外省流动人口 (Inter-provincial migrant)**: First 2 digits ∈ other valid
  Chinese province codes (11, 12, 13, 14, 15, 21, 22, 23, 31, 33–37, 41–46,
  50–54, 61–65)
- **其他 (Other)**: Invalid, missing, or non-Chinese ID numbers

Note: This classification reflects **registered household (hukou)** rather
than current residence. A migrant worker who has lived in Jiangsu for
many years still classifies as "inter-provincial migrant" if their hukou
is in another province.

## 3. Multivariable logistic regression specification

The main equity model (Module 04):

```
logit P(surgery = 1) = β₀ + β₁ × migrant + β₂ × male + β₃ × age_group_num
                      + β₄ × site_lower + β₅ × site_upper + β₆ × site_spine
```

Where:
- `migrant`: 1 if inter-provincial migrant, 0 if local Jiangsu resident
- `male`: 1 if male, 0 if female
- `age_group_num`: ordinal (0=0-17, 1=18-45, 2=46-64, 3=≥65)
- `site_lower / upper / spine`: indicator variables (reference =
  polytrauma / unclassified)

The cohort is restricted to fracture admissions excluding hardware-removal
procedures (n = 29,554 in the published manuscript).

## 4. Sensitivity analyses (5 pre-specified)

| # | Subgroup | Rationale |
|---|----------|-----------|
| 1 | Hip fractures (femoral neck + intertrochanteric) | Severity uniform; surgery generally indicated |
| 2 | Long-bone shaft fractures (femoral shaft, tibia/fibula shaft) | Surgery essentially obligatory; minimal clinical discretion |
| 3 | Working-age adults (18-55) | More homogeneous occupational/baseline risk |
| 4 | Extremity fractures only (excludes spine/pelvis) | Removes most discretionary category |
| 5 | Femoral neck fractures only | Most homogeneous severe fracture subgroup |

The pattern across these subgroups (gap persisting in subgroups with some
clinical discretion, but attenuating in subgroups where surgery is
essentially obligatory) supports the interpretation that financial-access
barriers operate preferentially in the zone of clinical discretion.

## 5. ITS model specifications

Model A (without seasonal adjustment):
```
mean_cost_t = β₀ + β₁·t + β₂·D_covid + β₃·t_covid + β₄·D_drg + β₅·t_drg + ε_t
```

Model B (with Fourier seasonal adjustment):
```
mean_cost_t = β₀ + β₁·t + β₂·D_covid + β₃·t_covid + β₄·D_drg + β₅·t_drg
             + γ₁·sin(2πt/12) + γ₂·cos(2πt/12)
             + γ₃·sin(2πt/6) + γ₄·cos(2πt/6) + ε_t
```

Where:
- `t`: month index (0-based)
- `D_covid`: 1 if month ≥ 2020-01, else 0
- `t_covid`: months elapsed since COVID start (0 before)
- `D_drg`: 1 if month ≥ 2023-01, else 0
- `t_drg`: months elapsed since DRG start (0 before)

Standard errors use Newey-West HAC estimation (lag = 3).

## 6. Multiple comparisons

Multiple comparisons were performed across subgroups and outcomes. We did
not formally adjust p-values for multiplicity because:
1. Analyses were pre-specified during study design
2. Most analyses are descriptive rather than confirmatory
3. The primary equity finding (aOR 0.68, p < 0.001) has effect magnitude
   far below what would be affected by multiplicity correction

Findings with marginal p-values (0.01 < p < 0.05) should be interpreted
as exploratory and hypothesis-generating.

## 7. Software environment

All analyses were performed in R (≥ 4.3.0) using packages listed in
`renv.lock`. Computational environment is documented in `sessionInfo.txt`.
