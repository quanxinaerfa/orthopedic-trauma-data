# Reproduction Guide

This document walks you through reproducing the analysis from scratch.

## For users with access to the real dataset

### Step 1: Place the raw data file

Put the raw HIS export Excel file at:

```
data/raw/orthopaedic_raw.xlsx
```

The file should contain (at minimum) these columns:
- 住院号 (medical record number)
- 身份证号 (national ID number, encrypted/de-identified)
- 性别 (sex)
- 年龄 (age)
- 入院日期 (admission date)
- 出院日期 (discharge date)
- 住院天数 (length of stay)
- 住院总费用RMB or 住院总费用（RMB） (total cost)
- 出院主诊断 (primary discharge diagnosis)
- 是否手术 (whether surgery)

### Step 2: Restore the package environment

```r
install.packages("renv")
renv::restore()
```

This installs the exact package versions used in the original analysis.

If you don't want to use renv, just install the packages manually:

```r
install.packages(c("dplyr", "tidyr", "readr", "readxl", "lubridate",
                   "stringr", "ggplot2", "scales", "patchwork",
                   "RColorBrewer", "sandwich", "lmtest", "broom", "knitr"))
```

### Step 3: Run the full pipeline

From the project root directory:

```bash
Rscript run_all.R
```

Or in an R interactive session:

```r
setwd("/path/to/orthopedic-trauma-2014-2025")
source("run_all.R")
```

### Step 4: Inspect outputs

```
output/
├── tables/      # CSV tables matching the manuscript
├── figures/     # PNG figures (200 dpi)
└── logs/        # Run logs
```

## For users without real-data access (verify pipeline only)

The repository ships with a synthetic 100-row sample at:

```
data/synthetic_sample_n100.csv
```

If you don't place real data in `data/raw/`, the setup script (`R/00_setup.R`)
will automatically detect the synthetic sample and use it.

**Important caveats**:
- Numerical results will NOT match the published manuscript
- Some statistical tests will be skipped due to insufficient sample size
- Figures will appear sparse but the code structure can be verified

## Running individual modules

Each module can be run independently after `00_setup.R`:

```r
source("R/00_setup.R")
source("R/04_equity_logistic.R")  # just the equity analysis
```

## Common issues

### "Package not found" error
Run `renv::restore()` or `install.packages("package_name")`.

### Chinese characters appear as garbled text
Set R locale to UTF-8:
```r
Sys.setlocale("LC_ALL", "en_US.UTF-8")  # or your local UTF-8 locale
```

On Windows, use `chcp 65001` in the terminal before launching R.

### "Path not found" error
Ensure your working directory is the project root (where `run_all.R` lives):
```r
setwd("/path/to/orthopedic-trauma-2014-2025")
```

## Citation

If you use this code, please cite both the manuscript and the Zenodo DOI
listed in `CITATION.cff`.

## Questions

For methodological questions or data access requests:
**Jianhua Lu** — `hmrysci@163.com`

For technical bugs in the code, open an issue on GitHub.
