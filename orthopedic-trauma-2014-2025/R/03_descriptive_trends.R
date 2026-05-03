# ============================================================
# 03_descriptive_trends.R
# ------------------------------------------------------------
# Purpose:   Describe annual admission trends, demographic shifts
#            (sex, age, origin), and the increase in elderly
#            proportion over time. Linear regression for elderly
#            proportion: β = +1.24 percentage points per year.
# Input:     data/cleaned_data.rds
# Output:    output/tables/T03_annual_trends.csv
#            output/tables/T03_elderly_proportion_trend.csv
# Section:   Methods - Descriptive analysis; Results - Trends
# ============================================================

if (!exists("PROJECT_ROOT")) source(file.path(getwd(), "R", "00_setup.R"))

log_msg("Module 03: Descriptive trends starting...")

df <- readRDS(file.path(DATA_DIR, "cleaned_data.rds"))

# ---- Annual admission counts ----
annual <- df %>%
  group_by(出院年份) %>%
  summarise(
    total_admissions = n(),
    male_n = sum(性别 == "男性", na.rm = TRUE),
    female_n = sum(性别 == "女性", na.rm = TRUE),
    elderly_n = sum(年龄 >= ELDERLY_CUTOFF, na.rm = TRUE),
    elderly_pct = round(100 * mean(年龄 >= ELDERLY_CUTOFF, na.rm = TRUE), 1),
    paediatric_n = sum(年龄 <= PAEDIATRIC_CUTOFF, na.rm = TRUE),
    local_n = sum(患者来源分类 == "江苏本地", na.rm = TRUE),
    migrant_n = sum(患者来源分类 == "外省流动人口", na.rm = TRUE),
    surgery_pct = round(100 * mean(是否手术 == "是", na.rm = TRUE), 1),
    fracture_pct = round(100 * mean(是否骨折 == "是", na.rm = TRUE), 1),
    .groups = "drop"
  )

log_msg("  Annual trends:")
print(annual, n = nrow(annual))

# ---- Linear regression: elderly proportion vs year ----
mod_elderly <- lm(elderly_pct ~ 出院年份, data = annual)
summ_elderly <- summary(mod_elderly)
slope <- coef(mod_elderly)["出院年份"]
slope_se <- summ_elderly$coefficients["出院年份", "Std. Error"]
slope_p <- summ_elderly$coefficients["出院年份", "Pr(>|t|)"]
r2 <- summ_elderly$r.squared

log_msg(sprintf("  Elderly proportion linear trend:"))
log_msg(sprintf("    Slope (β) = %+.3f percentage points per year", slope))
log_msg(sprintf("    SE = %.3f, %s, R² = %.3f",
                slope_se, format_pvalue(slope_p), r2))

# ---- Total admission growth ----
adm_first <- annual$total_admissions[which.min(annual$出院年份)]
adm_peak <- max(annual$total_admissions)
adm_growth <- (adm_peak - adm_first) / adm_first * 100
log_msg(sprintf("  Total admission growth: %d -> %d (%+.1f%%)",
                adm_first, adm_peak, adm_growth))

# ---- Trend regression summary ----
trend_summary <- data.frame(
  metric = c("Elderly proportion (%)", "Total admissions"),
  start_value = c(annual$elderly_pct[1], adm_first),
  end_value = c(annual$elderly_pct[nrow(annual)], adm_peak),
  slope_per_year = c(round(slope, 3), NA),
  p_value = c(round(slope_p, 4), NA),
  r_squared = c(round(r2, 3), NA)
)

# ---- Save ----
save_table(annual, "T03_annual_trends.csv")
save_table(trend_summary, "T03_elderly_proportion_trend.csv")

log_msg("Module 03 complete.")
