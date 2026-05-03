# ============================================================
# 04_equity_logistic.R
# ------------------------------------------------------------
# Purpose:   Multivariable logistic regression for surgical
#            intervention by patient origin (local vs migrant),
#            adjusted for age, sex, and fracture site. Includes
#            5 pre-specified sensitivity analyses by fracture
#            severity subgroups.
# Input:     data/cleaned_data.rds
# Output:    output/tables/T04_equity_main.csv
#            output/tables/T04_equity_sensitivity.csv
#            output/tables/T04_equity_site_stratified.csv
# Section:   Methods - Health equity analysis
#            Results - Health equity (key finding: aOR 0.68)
# ============================================================

if (!exists("PROJECT_ROOT")) source(file.path(getwd(), "R", "00_setup.R"))

log_msg("Module 04: Health equity logistic regression starting...")

df <- readRDS(file.path(DATA_DIR, "cleaned_data.rds"))

# ---- Build analytic cohort: fracture admissions only ----
cohort <- df %>%
  filter(是否骨折 == "是",
         诊断大类 != "内固定相关手术",
         患者来源分类 %in% c("江苏本地", "外省流动人口")) %>%
  mutate(
    migrant = as.integer(患者来源分类 == "外省流动人口"),
    surgery = as.integer(是否手术 == "是"),
    male = as.integer(性别 == "男性"),
    age_group_num = as.integer(cut(年龄, c(-Inf, 17, 45, 64, Inf), labels = 0:3)),
    site_lower = as.integer(诊断大类 == "下肢"),
    site_upper = as.integer(诊断大类 == "上肢"),
    site_spine = as.integer(诊断大类 == "脊柱/骨盆")
  ) %>%
  filter(!is.na(migrant), !is.na(surgery), !is.na(age_group_num))

log_msg(sprintf("  Equity analysis cohort: n = %d", nrow(cohort)))

# ---- Crude rates ----
crude_rates <- cohort %>%
  group_by(患者来源分类) %>%
  summarise(n = n(),
            surgery_rate_pct = round(100 * mean(surgery), 1),
            .groups = "drop")
log_msg("  Crude surgery rates:")
print(crude_rates)

# ---- Main multivariable logistic regression ----
fit_main <- glm(
  surgery ~ migrant + male + age_group_num + site_lower + site_upper + site_spine,
  family = binomial(link = "logit"),
  data = cohort
)

# Extract OR and 95% CI for migrant
extract_or <- function(model, term = "migrant") {
  s <- summary(model)
  if (!term %in% rownames(s$coefficients)) return(NULL)
  beta <- s$coefficients[term, "Estimate"]
  se   <- s$coefficients[term, "Std. Error"]
  pv   <- s$coefficients[term, "Pr(>|z|)"]
  data.frame(
    term = term,
    aOR = exp(beta),
    CI_lower = exp(beta - 1.96 * se),
    CI_upper = exp(beta + 1.96 * se),
    p_value = pv,
    n = nrow(model$data)
  )
}

main_result <- extract_or(fit_main)
main_result$subgroup <- "Main analysis: all fractures"
log_msg(sprintf("  MAIN: aOR = %.2f (95%% CI %.2f-%.2f), %s, n = %d",
                main_result$aOR, main_result$CI_lower, main_result$CI_upper,
                format_pvalue(main_result$p_value), main_result$n))

save_table(main_result, "T04_equity_main.csv")

# ---- Sensitivity analyses: 5 pre-specified subgroups ----
log_msg("  Running 5 sensitivity analyses...")

run_sensitivity <- function(data_subset, label, with_site = TRUE) {
  if (nrow(data_subset) < 100 || length(unique(data_subset$migrant)) < 2) {
    return(data.frame(subgroup = label, aOR = NA, CI_lower = NA,
                      CI_upper = NA, p_value = NA, n = nrow(data_subset)))
  }
  formula_str <- if (with_site) {
    "surgery ~ migrant + male + age_group_num + site_lower + site_upper + site_spine"
  } else {
    "surgery ~ migrant + male + age_group_num"
  }
  fit <- tryCatch(
    glm(as.formula(formula_str), family = binomial(link = "logit"), data = data_subset),
    error = function(e) NULL
  )
  if (is.null(fit)) {
    return(data.frame(subgroup = label, aOR = NA, CI_lower = NA,
                      CI_upper = NA, p_value = NA, n = nrow(data_subset)))
  }
  res <- extract_or(fit)
  res$subgroup <- label
  return(res)
}

# Sensitivity 1: hip fractures (severe, generally surgically indicated)
hip_cohort <- cohort %>%
  filter(grepl("股骨颈|股骨粗隆", 出院主诊断))
sens1 <- run_sensitivity(hip_cohort, "S1: Hip fractures (femoral neck + intertrochanteric)",
                         with_site = FALSE)

# Sensitivity 2: long-bone shaft fractures (surgery essentially obligatory)
long_bone_cohort <- cohort %>%
  filter(grepl("股骨干|胫腓骨|胫骨干", 出院主诊断))
sens2 <- run_sensitivity(long_bone_cohort, "S2: Long-bone shaft fractures",
                         with_site = FALSE)

# Sensitivity 3: working-age adults
working_cohort <- cohort %>% filter(年龄 >= WORKING_AGE_MIN, 年龄 <= WORKING_AGE_MAX)
sens3 <- run_sensitivity(working_cohort, "S3: Working-age adults (18-55)")

# Sensitivity 4: extremity fractures only (excludes spine/pelvis)
extremity_cohort <- cohort %>% filter(诊断大类 %in% c("上肢","下肢"))
sens4 <- run_sensitivity(extremity_cohort, "S4: Extremity fractures only")

# Sensitivity 5: femoral neck fractures only
fneck_cohort <- cohort %>% filter(grepl("股骨颈骨折", 出院主诊断))
sens5 <- run_sensitivity(fneck_cohort, "S5: Femoral neck fractures only",
                         with_site = FALSE)

sens_all <- rbind(sens1, sens2, sens3, sens4, sens5)
log_msg("  Sensitivity results:")
print(sens_all)

save_table(sens_all, "T04_equity_sensitivity.csv")

# ---- Site-stratified crude rates ----
site_strat <- cohort %>%
  group_by(诊断大类, 患者来源分类) %>%
  summarise(n = n(),
            surgery_rate_pct = round(100 * mean(surgery), 1),
            .groups = "drop") %>%
  tidyr::pivot_wider(names_from = 患者来源分类,
                     values_from = c(n, surgery_rate_pct))
save_table(site_strat, "T04_equity_site_stratified.csv")

log_msg("Module 04 complete.")
