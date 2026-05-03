# ============================================================
# run_all.R
# ------------------------------------------------------------
# Purpose:   Master script to run the full analysis pipeline.
#            Executes modules 01-09 in sequence.
# Usage:     Rscript run_all.R
#            (or source("run_all.R") in R interactive session)
# ============================================================

cat("\n")
cat("============================================================\n")
cat("  Orthopaedic Trauma Reproducibility Pipeline\n")
cat("  Manuscript: Health inequities and seasonal variation\n")
cat("              in orthopaedic admissions, 2014-2025\n")
cat("============================================================\n\n")

start_time <- Sys.time()

# Setup
source("R/00_setup.R")

# Run modules in sequence
modules <- c(
  "R/01_data_cleaning.R",
  "R/02_diagnosis_classification.R",
  "R/03_descriptive_trends.R",
  "R/04_equity_logistic.R",
  "R/05_seasonal_analysis.R",
  "R/06_its_drg_analysis.R",
  "R/07_stratified_drg.R",
  "R/08_high_frequency_users.R",
  "R/09_figures.R"
)

for (mod in modules) {
  cat("\n", paste(rep("-", 60), collapse = ""), "\n", sep = "")
  cat(" Running:", mod, "\n")
  cat(" ", paste(rep("-", 60), collapse = ""), "\n", sep = "")
  tryCatch(
    source(mod),
    error = function(e) {
      message(sprintf("ERROR in %s: %s", mod, e$message))
      message("Pipeline halted. Fix the error and re-run.")
    }
  )
}

end_time <- Sys.time()
duration <- round(as.numeric(difftime(end_time, start_time, units = "mins")), 1)

cat("\n============================================================\n")
cat(sprintf("  Pipeline complete (%.1f minutes)\n", duration))
cat("  Outputs:\n")
cat("    - Tables:  output/tables/\n")
cat("    - Figures: output/figures/\n")
cat("    - Logs:    output/logs/\n")
cat("============================================================\n\n")

# Save sessionInfo for reproducibility documentation
sink(file.path(getwd(), "sessionInfo.txt"))
cat("Session info captured:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
print(sessionInfo())
sink()
cat("sessionInfo.txt updated.\n")
