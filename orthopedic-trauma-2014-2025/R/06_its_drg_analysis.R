# ============================================================
# 06_its_drg_analysis.R
# ------------------------------------------------------------
# Purpose:   Interrupted time series analysis of mean hospitalisation
#            cost with two break-points (COVID Jan 2020, DRG Jan 2023).
#            Uses Newey-West HAC standard errors and adds Fourier
#            seasonal terms (sin/cos at 12-mo and 6-mo periods).
#            Reports Durbin-Watson statistic and ACF diagnostics.
# Input:     data/cleaned_data.rds
# Output:    output/tables/T06_its_unadjusted.csv
#            output/tables/T06_its_seasonally_adjusted.csv
#            output/tables/T06_its_diagnostics.csv
# Section:   Methods - Interrupted time series analysis
# ============================================================

if (!exists("PROJECT_ROOT")) source(file.path(getwd(), "R", "00_setup.R"))

log_msg("Module 06: ITS analysis (DRG cost) starting...")

df <- readRDS(file.path(DATA_DIR, "cleaned_data.rds"))

# ---- Build monthly emergency-trauma cost series ----
# Restrict to fracture (excluding hardware removal) - emergency trauma stratum
monthly <- df %>%
  filter(是否骨折 == "是",
         诊断大类 != "内固定相关手术",
         费用异常标记 == "正常",
         !is.na(住院总费用RMB)) %>%
  mutate(年月 = format(出院日期, "%Y-%m")) %>%
  group_by(年月) %>%
  summarise(mean_cost = mean(住院总费用RMB, na.rm = TRUE),
            n = n(),
            .groups = "drop") %>%
  arrange(年月) %>%
  mutate(
    年月_dt = as.Date(paste0(年月, "-01")),
    t = row_number() - 1,
    month_num = lubridate::month(年月_dt),
    covid_D = as.integer(年月_dt >= COVID_START),
    t_covid = pmax(0, t - which(年月_dt >= COVID_START)[1] + 1),
    drg_D = as.integer(年月_dt >= DRG_START),
    t_drg = pmax(0, t - which(年月_dt >= DRG_START)[1] + 1),
    sin12 = sin(2 * pi * t / 12),
    cos12 = cos(2 * pi * t / 12),
    sin6  = sin(2 * pi * t / 6),
    cos6  = cos(2 * pi * t / 6)
  )

log_msg(sprintf("  Monthly time series: %d observations from %s to %s",
                nrow(monthly), min(monthly$年月), max(monthly$年月)))

# ---- Fit ITS WITHOUT seasonal adjustment ----
fit_unadj <- lm(mean_cost ~ t + covid_D + t_covid + drg_D + t_drg, data = monthly)

# Newey-West HAC standard errors
nw_unadj <- lmtest::coeftest(fit_unadj, vcov. = sandwich::NeweyWest(fit_unadj, lag = 3))
log_msg("  Unadjusted ITS coefficients (Newey-West HAC SE):")
print(nw_unadj)

# Diagnostics
dw_unadj <- lmtest::dwtest(fit_unadj)$statistic
acf1_unadj <- as.numeric(acf(residuals(fit_unadj), lag.max = 1, plot = FALSE)$acf[2])
r2_unadj <- summary(fit_unadj)$r.squared
log_msg(sprintf("  Unadjusted: R² = %.3f, Durbin-Watson = %.3f, ACF(1) = %.3f",
                r2_unadj, dw_unadj, acf1_unadj))

# ---- Fit ITS WITH Fourier seasonal adjustment ----
fit_adj <- lm(mean_cost ~ t + covid_D + t_covid + drg_D + t_drg +
                sin12 + cos12 + sin6 + cos6, data = monthly)

nw_adj <- lmtest::coeftest(fit_adj, vcov. = sandwich::NeweyWest(fit_adj, lag = 3))
log_msg("  Seasonally-adjusted ITS coefficients (Newey-West HAC SE):")
print(nw_adj)

dw_adj <- lmtest::dwtest(fit_adj)$statistic
acf1_adj <- as.numeric(acf(residuals(fit_adj), lag.max = 1, plot = FALSE)$acf[2])
r2_adj <- summary(fit_adj)$r.squared
log_msg(sprintf("  Seasonally adjusted: R² = %.3f, Durbin-Watson = %.3f, ACF(1) = %.3f",
                r2_adj, dw_adj, acf1_adj))

# ---- Save outputs ----
unadj_df <- as.data.frame(nw_unadj[, ])
unadj_df$term <- rownames(unadj_df)
adj_df <- as.data.frame(nw_adj[, ])
adj_df$term <- rownames(adj_df)
save_table(unadj_df, "T06_its_unadjusted.csv")
save_table(adj_df, "T06_its_seasonally_adjusted.csv")

diag_df <- data.frame(
  model = c("Unadjusted", "Seasonally-adjusted"),
  r_squared = round(c(r2_unadj, r2_adj), 3),
  durbin_watson = round(c(dw_unadj, dw_adj), 3),
  acf_lag1 = round(c(acf1_unadj, acf1_adj), 3),
  drg_level_shift_RMB = round(c(coef(fit_unadj)["drg_D"], coef(fit_adj)["drg_D"]), 0)
)
save_table(diag_df, "T06_its_diagnostics.csv")

log_msg("Module 06 complete.")
