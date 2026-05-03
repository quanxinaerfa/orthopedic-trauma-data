# ============================================================
# 00_setup.R
# ------------------------------------------------------------
# Purpose:   Load all required packages, define global parameters,
#            set up output directories, and check data availability.
# Run order: First (sourced by run_all.R and individual modules)
# Author:    Jianhua Lu
# Project:   Orthopaedic Trauma 2014-2025 Reproducibility Package
# ============================================================

# ---- Required packages ----
required_packages <- c(
  "dplyr",        # Data manipulation
  "tidyr",        # Data reshaping
  "readr",        # CSV I/O
  "readxl",       # Excel I/O
  "lubridate",    # Date handling
  "stringr",      # String manipulation
  "ggplot2",      # Plotting
  "scales",       # Plot scales
  "patchwork",    # Multi-panel figures
  "RColorBrewer", # Colour palettes
  "sandwich",     # Newey-West HAC SE
  "lmtest",       # Linear model tests
  "broom",        # Tidy model output
  "knitr"         # Table formatting
)

# Install any missing packages
missing_packages <- setdiff(required_packages, rownames(installed.packages()))
if (length(missing_packages) > 0) {
  message("Installing missing packages: ", paste(missing_packages, collapse = ", "))
  install.packages(missing_packages, repos = "https://cloud.r-project.org")
}

# Load all packages
invisible(lapply(required_packages, library, character.only = TRUE))

# ---- Global parameters ----
PROJECT_ROOT <- here::here()  # Will fall back to getwd() if 'here' not loaded
if (!exists("PROJECT_ROOT") || is.null(PROJECT_ROOT)) {
  PROJECT_ROOT <- getwd()
}

# Study period (inclusion criterion: discharge date in this range)
STUDY_START <- as.Date("2014-01-01")
STUDY_END   <- as.Date("2025-12-31")

# Policy break-points for Interrupted Time Series
COVID_START <- as.Date("2020-01-01")
DRG_START   <- as.Date("2023-01-01")

# Age cutoffs (years)
ELDERLY_CUTOFF   <- 65
PAEDIATRIC_CUTOFF <- 17
WORKING_AGE_MIN  <- 18
WORKING_AGE_MAX  <- 55

# Province codes (first 2 digits of national ID)
JIANGSU_PROVINCE_CODE <- "32"

# Statistical thresholds
SIG_THRESHOLD <- 0.05

# ---- Set up paths ----
DATA_DIR     <- file.path(PROJECT_ROOT, "data")
OUTPUT_DIR   <- file.path(PROJECT_ROOT, "output")
TABLES_DIR   <- file.path(OUTPUT_DIR, "tables")
FIGURES_DIR  <- file.path(OUTPUT_DIR, "figures")
LOGS_DIR     <- file.path(OUTPUT_DIR, "logs")

# Create output directories if they don't exist
for (d in c(TABLES_DIR, FIGURES_DIR, LOGS_DIR)) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

# ---- Detect input data file ----
# Priority: real data > synthetic sample
RAW_DATA_PATH <- file.path(DATA_DIR, "raw", "orthopaedic_raw.xlsx")
SYNTHETIC_DATA_PATH <- file.path(DATA_DIR, "synthetic_sample_n100.csv")

if (file.exists(RAW_DATA_PATH)) {
  INPUT_DATA <- RAW_DATA_PATH
  IS_SYNTHETIC <- FALSE
  message("Using REAL data: ", INPUT_DATA)
} else if (file.exists(SYNTHETIC_DATA_PATH)) {
  INPUT_DATA <- SYNTHETIC_DATA_PATH
  IS_SYNTHETIC <- TRUE
  message("Using SYNTHETIC sample: ", INPUT_DATA)
  message("NOTE: Results will not match published manuscript values.")
} else {
  stop("No input data found. Place raw data in data/raw/ or synthetic sample in data/")
}

# ---- Source utility functions ----
utils_files <- list.files(file.path(PROJECT_ROOT, "R", "utils"), 
                          pattern = "\\.R$", full.names = TRUE)
invisible(lapply(utils_files, source))

message("Setup complete. Project root: ", PROJECT_ROOT)
