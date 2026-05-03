# ============================================================
# 08_high_frequency_users.R
# ------------------------------------------------------------
# Purpose:   Identify high-frequency users (≥3 admissions during
#            the study period) by national ID number. Profile their
#            demographics, diagnostic spectrum, and resource use.
# Input:     data/cleaned_data.rds
# Output:    output/tables/T08_high_frequency_summary.csv
#            output/tables/T08_high_frequency_diagnoses.csv
# Section:   Methods - High-frequency users analysis
# Key result: 3.0% of patients account for 12.7% of admissions
# ============================================================

if (!exists("PROJECT_ROOT")) source(file.path(getwd(), "R", "00_setup.R"))

log_msg("Module 08: High-frequency users analysis starting...")

df <- readRDS(file.path(DATA_DIR, "cleaned_data.rds"))

# ---- Filter to records with valid ID numbers ----
df_id <- df %>%
  mutate(身份证号 = as.character(身份证号)) %>%
  filter(!is.na(身份证号), nchar(身份证号) >= 15)

log_msg(sprintf("  Records with valid ID: %d", nrow(df_id)))

# ---- Count admissions per patient ----
admit_count <- df_id %>%
  count(身份证号, name = "n_admissions")

n_unique_patients <- nrow(admit_count)
log_msg(sprintf("  Unique patients: %d", n_unique_patients))

# ---- Identify high-frequency users ----
high_freq_ids <- admit_count$身份证号[admit_count$n_admissions >= 3]
n_hf_patients <- length(high_freq_ids)

hf_records <- df_id %>% filter(身份证号 %in% high_freq_ids)
n_hf_records <- nrow(hf_records)

# ---- Summary statistics ----
hf_summary <- data.frame(
  metric = c("Unique patients (total)",
             "High-frequency patients (≥3 admissions)",
             "% of unique patients who are high-frequency",
             "Admissions by high-frequency users",
             "% of total admissions by high-frequency users",
             "Mean age of high-frequency users (years)",
             "% female among high-frequency users",
             "% hardware-removal among high-frequency admissions"),
  value = c(
    n_unique_patients,
    n_hf_patients,
    round(100 * n_hf_patients / n_unique_patients, 1),
    n_hf_records,
    round(100 * n_hf_records / nrow(df_id), 1),
    round(mean(hf_records$年龄, na.rm = TRUE), 0),
    round(100 * mean(hf_records$性别 == "女性", na.rm = TRUE), 1),
    round(100 * mean(hf_records$诊断大类 == "内固定相关手术", na.rm = TRUE), 1)
  )
)

log_msg("  High-frequency users summary:")
print(hf_summary)

save_table(hf_summary, "T08_high_frequency_summary.csv")

# ---- Top diagnoses among high-frequency users ----
if (n_hf_records > 0) {
  hf_diag <- hf_records %>%
    count(出院主诊断, sort = TRUE, name = "n") %>%
    head(10) %>%
    mutate(percent = round(100 * n / sum(.$n), 1))
  save_table(hf_diag, "T08_high_frequency_diagnoses.csv")
}

# ---- Resource utilisation comparison ----
if ("住院总费用RMB" %in% names(df_id)) {
  total_cost_all <- sum(df_id$住院总费用RMB, na.rm = TRUE)
  total_cost_hf <- sum(hf_records$住院总费用RMB, na.rm = TRUE)
  log_msg(sprintf("  Cost share by high-frequency users: %.1f%%",
                  100 * total_cost_hf / total_cost_all))
}

log_msg("Module 08 complete.")
