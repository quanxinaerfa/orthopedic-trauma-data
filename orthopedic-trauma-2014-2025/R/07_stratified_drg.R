# ============================================================
# 07_stratified_drg.R
# ------------------------------------------------------------
# Purpose:   Stratified analysis of DRG-associated cost changes
#            by admission acuity. Pre-specified strata:
#            (1) Emergency trauma (n = 28,958): fractures excl.
#                hardware-removal procedures
#            (2) Elective (n = 10,753): hardware-removal and
#                degenerative-disease admissions
#            Compares pre-DRG (2020-2022) vs post-DRG (2023-2025)
#            within each stratum.
# Input:     data/cleaned_data.rds
# Output:    output/tables/T07_stratified_pre_post.csv
# Section:   Methods - Stratified analysis by acuity
# Key result: Emergency cost -25.6% vs Elective -3.8%
# ============================================================

if (!exists("PROJECT_ROOT")) source(file.path(getwd(), "R", "00_setup.R"))

log_msg("Module 07: Stratified DRG analysis starting...")

df <- readRDS(file.path(DATA_DIR, "cleaned_data.rds"))

# ---- Define acuity strata ----
df <- df %>%
  mutate(
    acuity_stratum = case_when(
      是否骨折 == "是" & 诊断大类 != "内固定相关手术" ~ "Emergency trauma",
      诊断大类 %in% c("内固定相关手术", "退变性疾病") ~ "Elective",
      TRUE ~ "Other"
    ),
    drg_period = case_when(
      出院年份 %in% 2020:2022 ~ "Pre-DRG",
      出院年份 %in% 2023:2025 ~ "Post-DRG",
      TRUE ~ NA_character_
    )
  )

# ---- Filter to analysis subset ----
analysis_df <- df %>%
  filter(acuity_stratum %in% c("Emergency trauma", "Elective"),
         !is.na(drg_period),
         费用异常标记 == "正常",
         !is.na(住院总费用RMB))

log_msg(sprintf("  Stratified analysis n = %d", nrow(analysis_df)))

# ---- Pre/post comparison within each stratum ----
strat_summary <- analysis_df %>%
  group_by(acuity_stratum, drg_period) %>%
  summarise(
    n = n(),
    mean_cost = round(mean(住院总费用RMB), 0),
    median_cost = round(median(住院总费用RMB), 0),
    sd_cost = round(sd(住院总费用RMB), 0),
    mean_los = round(mean(住院天数, na.rm = TRUE), 1),
    .groups = "drop"
  )

log_msg("  Stratified summary:")
print(strat_summary)

# ---- Statistical tests within each stratum ----
results_list <- list()
for (s in c("Emergency trauma", "Elective")) {
  sub <- analysis_df %>% filter(acuity_stratum == s)
  pre <- sub$住院总费用RMB[sub$drg_period == "Pre-DRG"]
  post <- sub$住院总费用RMB[sub$drg_period == "Post-DRG"]
  if (length(pre) < 30 || length(post) < 30) {
    log_msg(sprintf("  WARNING: %s stratum has too few observations - skipping test", s))
    next
  }
  t_res <- t.test(pre, post, var.equal = FALSE)
  pct_change <- round(100 * (mean(post) - mean(pre)) / mean(pre), 1)
  log_msg(sprintf("  %s: pre = ¥%.0f, post = ¥%.0f (%+.1f%%), %s",
                  s, mean(pre), mean(post), pct_change,
                  format_pvalue(t_res$p.value)))
  results_list[[s]] <- data.frame(
    stratum = s,
    pre_mean_cost = round(mean(pre), 0),
    post_mean_cost = round(mean(post), 0),
    pct_change = pct_change,
    t_statistic = round(t_res$statistic, 2),
    p_value = round(t_res$p.value, 4),
    pre_n = length(pre),
    post_n = length(post)
  )
}

if (length(results_list) > 0) {
  results_df <- do.call(rbind, results_list)
  save_table(results_df, "T07_stratified_pre_post.csv")
}

save_table(strat_summary, "T07_stratified_summary.csv")

log_msg("Module 07 complete.")
