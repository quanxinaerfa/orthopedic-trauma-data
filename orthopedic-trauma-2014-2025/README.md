# Orthopaedic Trauma in a Chinese District Hospital, 2014–2025

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.XXXXXXX.svg)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R Version](https://img.shields.io/badge/R-%E2%89%A54.3.0-blue.svg)](https://cran.r-project.org/)

Reproducibility package for the manuscript:

> **[YOUR_LASTNAME] J, [COAUTHOR_NAMES], et al.** Health inequities and seasonal variation in orthopaedic admissions: a 12-year retrospective study of 55,787 admissions in a Chinese district hospital. *BMC Public Health.* 2026;XX(X):XXX. doi:[TO_BE_ASSIGNED]

---

## 📋 Overview

This repository contains all R analysis scripts, supporting documentation, and a synthetic data sample to reproduce the results, tables, and figures reported in the above manuscript.

The analysis covers **55,787 orthopaedic admissions** discharged from Haimen District People's Hospital (Jiangsu Province, China) between 1 January 2014 and 31 December 2025, examining:

1. Long-term admission trends and demographic shifts
2. Inequities in surgical care between local residents and inter-provincial migrant patients
3. Seasonal patterns of elderly hip fractures and paediatric injuries
4. Hospitalisation cost changes following Diagnosis-Related Group (DRG) payment reform

---

## 🚀 Quick Start

### Prerequisites
- **R** ≥ 4.3.0
- **RStudio** (recommended) or any R IDE
- ~500 MB free disk space
- The packages listed in `renv.lock` (auto-installed via `renv::restore()`)

### Reproduce the analysis in 3 steps

```bash
# 1. Clone or download this repository
git clone https://github.com/[YOUR_USERNAME]/orthopedic-trauma-industry-2014-2025.git
cd orthopedic-trauma-industry-2014-2025

# 2. Restore the exact R package environment
Rscript -e 'install.packages("renv"); renv::restore()'

# 3. Run the full analysis pipeline using the synthetic sample
Rscript run_all.R
```

Outputs will be written to `output/tables/` and `output/figures/`.

> **Note:** Real patient data are not publicly available due to ethics restrictions (see Data Availability below). The pipeline runs end-to-end on the synthetic sample (`data/synthetic_sample_n100.csv`) included in this package, allowing readers to verify code functionality without access to identifiable data.

---

## 📁 Repository Structure

```
orthopedic-trauma-industry-2014-2025/
│
├── README.md                              # This file
├── LICENSE                                # MIT License (code)
├── CITATION.cff                           # Machine-readable citation
├── sessionInfo.txt                        # R environment snapshot
├── renv.lock                              # Locked package versions
├── .gitignore                             # Files excluded from version control
├── run_all.R                              # Master script — runs full pipeline
│
├── data/
│   ├── README_data.md                     # Data source, fields, access policy
│   ├── data_dictionary.csv                # Variable definitions
│   ├── synthetic_sample_n100.csv          # 100-row synthetic sample (no PHI)
│   └── raw/                               # Real data location (gitignored)
│       └── .gitkeep
│
├── R/
│   ├── 00_setup.R                         # Load packages, set global parameters
│   ├── 01_data_cleaning.R                 # Module 1: Extraction & cleaning
│   ├── 02_diagnosis_classification.R      # Module 2: Keyword-matching algorithm
│   ├── 03_descriptive_trends.R            # Module 3: Long-term trends
│   ├── 04_equity_logistic.R               # Module 4: Health equity analysis
│   ├── 05_seasonal_analysis.R             # Module 5: Seasonal chi-square tests
│   ├── 06_its_drg_analysis.R              # Module 6: ITS with Newey-West & Fourier
│   ├── 07_stratified_drg.R                # Module 7: Acuity-stratified analysis
│   ├── 08_high_frequency_users.R          # Module 8: High-frequency users
│   ├── 09_figures.R                       # Module 9: Figures 1–6
│   └── utils/
│       ├── helper_functions.R             # Common helper functions
│       └── plot_theme.R                   # Unified ggplot2 theme
│
├── output/
│   ├── tables/                            # Auto-generated tables (CSV)
│   ├── figures/                           # Auto-generated figures (PNG, 200 dpi)
│   └── logs/                              # Run logs
│
└── docs/
    ├── keyword_dictionary.md              # Diagnosis keyword merging rules (transparency)
    ├── methods_supplement.md              # Extended methodological notes
    └── reproduction_guide.md              # Step-by-step reproduction instructions
```

---

## 🔬 Analysis Modules

Each script is self-contained and corresponds to a Methods subsection in the manuscript:

| Script | Methods Section | Key Output |
|--------|----------------|-----------|
| `01_data_cleaning.R` | Data source & inclusion criteria | `data/cleaned_data.rds` |
| `02_diagnosis_classification.R` | Diagnosis classification | Adds `诊断大类` (diagnosis category) |
| `03_descriptive_trends.R` | Descriptive trends | Table 1, Figure 1 inputs |
| `04_equity_logistic.R` | Health equity analysis | aOR estimates, sensitivity analyses |
| `05_seasonal_analysis.R` | Seasonal pattern analysis | χ² tests, monthly distributions |
| `06_its_drg_analysis.R` | Interrupted time series | DRG-associated cost change |
| `07_stratified_drg.R` | Stratified analysis by acuity | Emergency vs elective stratum |
| `08_high_frequency_users.R` | High-frequency users | Patient-level aggregation |
| `09_figures.R` | All figures | Figures 1–6 (200 dpi PNG) |

Run any module independently:
```bash
Rscript R/04_equity_logistic.R
```

---

## 📊 Data Availability

### Real Data
The de-identified patient-level dataset analysed in this study contains protected health information and **cannot be shared publicly** under the terms of the ethics approval (ref: 2026-KY015-01, Haimen District People's Hospital Ethics Committee).

Researchers seeking access for legitimate scientific purposes may contact the corresponding author (`hmrysci@163.com`). Access requires:
- A formal data access request with a study protocol
- IRB approval from the requester's home institution
- A signed data use agreement

### Synthetic Sample
A 100-row synthetic sample (`data/synthetic_sample_n100.csv`) with identical structure but no real patient identifiers is included to verify that the analysis pipeline runs correctly. This sample is randomised and **must not be used for substantive analysis**.

---

## 🔑 Diagnosis Classification Transparency

A core methodological feature of this study is the keyword-matching algorithm used to classify Chinese free-text diagnoses. The complete mapping from raw diagnostic text to analytic categories is documented in [`docs/keyword_dictionary.md`](docs/keyword_dictionary.md).

Key rules include:
- **Tibial plateau fractures** were merged with general tibial fracture variants (`胫骨骨折`, `胫腓骨骨折`, `闭合性胫骨骨折`) due to documented terminology shifts during 2017–2018.
- **Distal radius fractures** were merged with related radial variants (`桡骨骨折`, `桡骨下段骨折`, `尺桡骨骨折`) due to a coding-system update around 2021.
- All synonyms were aggregated to the parent anatomical-site level for time-series analyses; condition-specific trend reporting was avoided for the two subgroups most affected by terminology shifts.

This documentation is provided as **transparency-in-lieu-of-validation** — the keyword algorithm has not been formally validated against gold-standard manual coding, which is acknowledged as a study limitation in the manuscript.

---

## 🧪 Software Environment

This analysis was conducted using:

- **R version:** 4.3.x
- **Operating system:** [YOUR_OS, e.g., Ubuntu 22.04 LTS / Windows 11 / macOS 14]
- **Key packages:** `dplyr`, `tidyr`, `ggplot2`, `readxl`, `lubridate`, `sandwich`, `lmtest`, `forecast`, `scales`, `patchwork`

A complete environment snapshot is provided in [`sessionInfo.txt`](sessionInfo.txt).
The exact package versions can be restored using [`renv`](https://rstudio.github.io/renv/):
```r
renv::restore()
```

---

## 📜 Citation

If you use this code in your research, please cite **both** the manuscript and this software package:

### Manuscript
```bibtex
@article{[YOUR_LASTNAME]2026orthopaedic,
  author  = {[YOUR_LASTNAME], [Initial] and [Coauthors]},
  title   = {Health inequities and seasonal variation in orthopaedic admissions: 
             a 12-year retrospective study of 55,787 admissions in a Chinese district hospital},
  journal = {BMC Public Health},
  year    = {2026},
  volume  = {XX},
  pages   = {XXX},
  doi     = {[TO_BE_ASSIGNED]}
}
```

### Software (this repository)
```bibtex
@software{[YOUR_LASTNAME]2026orthopaedic_code,
  author  = {[YOUR_LASTNAME], [Initial]},
  title   = {Orthopaedic Trauma Analysis Code 2014--2025},
  year    = {2026},
  version = {1.0.0},
  doi     = {10.5281/zenodo.XXXXXXX},
  url     = {https://github.com/[YOUR_USERNAME]/orthopedic-trauma-industry-2014-2025}
}
```

A `CITATION.cff` file is included for automatic citation generation by GitHub and Zenodo.

---

## ⚖️ License

- **Code (R scripts):** [MIT License](LICENSE) — free to use, modify, and redistribute with attribution.
- **Documentation:** [Creative Commons Attribution 4.0 International (CC-BY-4.0)](https://creativecommons.org/licenses/by/4.0/).
- **Data:** Not licensed for redistribution. Synthetic sample is released under CC0 (public domain).

---

## 🤝 Contributing & Issues

This repository is a static archive of the analysis published in the above manuscript. For:

- **Bug reports** in the analysis code: open an issue on [GitHub](https://github.com/[YOUR_USERNAME]/orthopedic-trauma-industry-2014-2025/issues)
- **Methodological questions** or **data access requests**: contact the corresponding author at `hmrysci@163.com`
- **Reuse for other projects**: you are welcome — please cite both the manuscript and the Zenodo DOI

---

## 🙏 Acknowledgements

This analysis was supported by [YOUR_FUNDING, or "no external funding"]. We thank the staff of the Information Technology Department at Haimen District People's Hospital for assistance with data extraction.

---

## 📞 Corresponding Author

**[YOUR_NAME]**
Department of Orthopaedic Surgery
Haimen District People's Hospital
Nantong, Jiangsu Province, China
Email: hmrysci@163.com

---

*Last updated: [YYYY-MM-DD]*
*Repository version: 1.0.0*
*Zenodo DOI: 10.5281/zenodo.XXXXXXX*
