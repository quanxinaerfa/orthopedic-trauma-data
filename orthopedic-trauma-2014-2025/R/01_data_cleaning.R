# ============================================================
# 01_data_cleaning.R
# ------------------------------------------------------------
# Purpose:   Extract orthopaedic admissions, apply inclusion
#            criteria (discharge date 2014-01-01 to 2025-12-31),
#            derive demographic variables (sex, age groups,
#            patient origin from ID number), flag cost outliers.
# Input:     data/raw/orthopaedic_raw.xlsx OR
#            data/synthetic_sample_n100.csv
# Output:    data/cleaned_data.rds (R binary, used by other modules)
#            output/tables/T01_cleaning_summary.csv
# Section:   Methods - Data source and inclusion criteria
# ============================================================

# Load setup if not already loaded
if (!exists("PROJECT_ROOT")) source(file.path(getwd(), "R", "00_setup.R"))

log_msg("Module 01: Data cleaning starting...")

# ---- Read input data ----
if (grepl("\\.xlsx$", INPUT_DATA)) {
  raw <- readxl::read_excel(INPUT_DATA)
} else {
  raw <- readr::read_csv(INPUT_DATA, locale = readr::locale(encoding = "UTF-8"),
                         show_col_types = FALSE)
}

n_raw <- nrow(raw)
log_msg(sprintf("  Raw records loaded: %d", n_raw))

# ---- Standardise column names if needed ----
expected_cols <- c("住院号", "身份证号", "性别", "年龄",
                   "入院日期", "出院日期", "住院天数",
                   "住院总费用RMB", "出院主诊断", "是否手术")

# Handle alternative column names (e.g. with parentheses)
name_map <- c(
  "住院总费用（RMB）" = "住院总费用RMB",
  "住院总费用(RMB)" = "住院总费用RMB"
)
for (old_name in names(name_map)) {
  if (old_name %in% names(raw)) {
    names(raw)[names(raw) == old_name] <- name_map[old_name]
  }
}

# ---- Parse dates ----
raw <- raw %>%
  mutate(
    入院日期 = as.Date(入院日期),
    出院日期 = as.Date(出院日期),
    出院年份 = lubridate::year(出院日期),
    出院月份 = lubridate::month(出院日期)
  )

# ---- Apply inclusion criterion: discharge date in study period ----
n_before_filter <- nrow(raw)
df <- raw %>% filter(出院日期 >= STUDY_START & 出院日期 <= STUDY_END)
n_after_filter <- nrow(df)
log_msg(sprintf("  Inclusion filter (discharge %s to %s): %d -> %d records",
                STUDY_START, STUDY_END, n_before_filter, n_after_filter))

# ---- Derive patient origin from ID number ----
if (!"患者来源分类" %in% names(df)) {
  df <- df %>%
    mutate(
      省份代码 = derive_province(身份证号),
      患者来源分类 = classify_origin(省份代码)
    )
  log_msg("  Patient origin derived from ID number")
}

# ---- Derive age groups ----
df <- df %>% mutate(年龄组 = age_group(年龄))

# ---- Flag cost outliers (Tukey method: Q1 - 1.5*IQR or Q3 + 1.5*IQR) ----
if (!"费用异常标记" %in% names(df) && "住院总费用RMB" %in% names(df)) {
  q1 <- quantile(df$住院总费用RMB, 0.25, na.rm = TRUE)
  q3 <- quantile(df$住院总费用RMB, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  lower_bound <- q1 - 1.5 * iqr
  upper_bound <- q3 + 1.5 * iqr
  df <- df %>%
    mutate(费用异常标记 = ifelse(住院总费用RMB < lower_bound | 住院总费用RMB > upper_bound,
                            "异常", "正常"))
  log_msg(sprintf("  Cost outliers flagged: %d (%.1f%%)",
                  sum(df$费用异常标记 == "异常"),
                  100 * mean(df$费用异常标记 == "异常")))
}

# ---- Save cleaned data ----
saveRDS(df, file.path(DATA_DIR, "cleaned_data.rds"))
log_msg(sprintf("  Cleaned data saved: %d records, %d columns", nrow(df), ncol(df)))

# ---- Save cleaning summary table ----
summary_tbl <- data.frame(
  step = c("Raw records loaded",
           "After date inclusion filter",
           "Final cleaned dataset"),
  n = c(n_raw, n_after_filter, nrow(df))
)
save_table(summary_tbl, "T01_cleaning_summary.csv")

log_msg("Module 01 complete.")
