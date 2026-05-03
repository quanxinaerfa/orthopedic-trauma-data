# ============================================================
# 05_seasonal_analysis.R
# ------------------------------------------------------------
# Purpose:   Test for seasonal variation in elderly hip fractures
#            (October-February peak) and paediatric fractures
#            (July summer surge) using chi-square goodness-of-fit
#            against a uniform monthly distribution.
# Input:     data/cleaned_data.rds
# Output:    output/tables/T05_seasonal_elderly_hip.csv
#            output/tables/T05_seasonal_paediatric.csv
# Section:   Methods - Seasonal pattern analysis
# Key result: Elderly hip χ² = 23.5, p < 0.001
# ============================================================

if (!exists("PROJECT_ROOT")) source(file.path(getwd(), "R", "00_setup.R"))

log_msg("Module 05: Seasonal analysis starting...")

df <- readRDS(file.path(DATA_DIR, "cleaned_data.rds"))

# ---- Elderly hip fractures (femoral neck + intertrochanteric) ----
hip_elderly <- df %>%
  filter(grepl("股骨颈骨折|股骨粗隆间骨折", 出院主诊断),
         年龄 >= ELDERLY_CUTOFF)

n_hip <- nrow(hip_elderly)
log_msg(sprintf("  Elderly hip fracture admissions: n = %d", n_hip))

# Monthly count
monthly_hip <- hip_elderly %>%
  count(出院月份, name = "n") %>%
  tidyr::complete(出院月份 = 1:12, fill = list(n = 0)) %>%
  arrange(出院月份) %>%
  mutate(
    month_name = month.abb[出院月份],
    expected = n_hip / 12,
    deviation_pct = round(100 * (n - expected) / expected, 1)
  )

# Chi-square goodness-of-fit (against uniform)
if (n_hip >= 60) {
  chisq_hip <- chisq.test(monthly_hip$n,
                          p = rep(1/12, 12), rescale.p = FALSE)
  log_msg(sprintf("  Elderly hip seasonality: χ² = %.2f, df = %d, %s",
                  chisq_hip$statistic, chisq_hip$parameter,
                  format_pvalue(chisq_hip$p.value)))

  # Autumn-winter (Oct-Feb) vs summer (May-Aug)
  aw_n <- sum(monthly_hip$n[monthly_hip$出院月份 %in% c(10,11,12,1,2)])
  summer_n <- sum(monthly_hip$n[monthly_hip$出院月份 %in% 5:8])
  aw_pct <- round(100 * aw_n / n_hip, 1)
  log_msg(sprintf("  Autumn-winter (Oct-Feb): %d (%.1f%%)", aw_n, aw_pct))
  log_msg(sprintf("  Summer (May-Aug): %d", summer_n))
} else {
  log_msg("  WARNING: n < 60, chi-square skipped (likely synthetic sample)")
}

save_table(monthly_hip, "T05_seasonal_elderly_hip.csv")

# ---- Paediatric fractures (≤17 years) ----
paediatric <- df %>%
  filter(年龄 <= PAEDIATRIC_CUTOFF, 是否骨折 == "是")

n_ped <- nrow(paediatric)
log_msg(sprintf("  Paediatric fracture admissions: n = %d", n_ped))

monthly_ped <- paediatric %>%
  count(出院月份, name = "n") %>%
  tidyr::complete(出院月份 = 1:12, fill = list(n = 0)) %>%
  arrange(出院月份) %>%
  mutate(
    month_name = month.abb[出院月份],
    expected = n_ped / 12,
    deviation_pct = round(100 * (n - expected) / expected, 1)
  )

if (n_ped >= 60) {
  chisq_ped <- chisq.test(monthly_ped$n,
                          p = rep(1/12, 12), rescale.p = FALSE)
  log_msg(sprintf("  Paediatric seasonality: χ² = %.2f, df = %d, %s",
                  chisq_ped$statistic, chisq_ped$parameter,
                  format_pvalue(chisq_ped$p.value)))

  # Summer (Jul-Aug) vs other months
  summer_ped <- sum(monthly_ped$n[monthly_ped$出院月份 %in% 7:8])
  non_summer_ped <- sum(monthly_ped$n[!monthly_ped$出院月份 %in% 7:8])
  summer_mean_per_month <- summer_ped / 2
  non_summer_mean_per_month <- non_summer_ped / 10
  pct_increase <- round(100 * (summer_mean_per_month - non_summer_mean_per_month) /
                        non_summer_mean_per_month, 1)
  log_msg(sprintf("  Paediatric July-August surge: %+.1f%% vs non-summer mean", pct_increase))
}

save_table(monthly_ped, "T05_seasonal_paediatric.csv")

log_msg("Module 05 complete.")
