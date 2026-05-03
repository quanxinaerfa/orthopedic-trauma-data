# ============================================================
# 09_figures.R
# ------------------------------------------------------------
# Purpose:   Generate Figures 1-6 for the manuscript at 200 dpi PNG.
# Input:     data/cleaned_data.rds, output/tables/T0*.csv
# Output:    output/figures/Figure_1.png ... Figure_6.png
# Section:   Figures and visualisation
# ============================================================

if (!exists("PROJECT_ROOT")) source(file.path(getwd(), "R", "00_setup.R"))

log_msg("Module 09: Figure generation starting...")

df <- readRDS(file.path(DATA_DIR, "cleaned_data.rds"))

# ============================================================
# FIGURE 1: Annual admission trends by age group
# ============================================================
log_msg("  Generating Figure 1...")

fig1_data <- df %>%
  mutate(age_grp = cut(年龄,
                       breaks = c(-Inf, 17, 64, Inf),
                       labels = c("Paediatric (≤17)", "Adult (18-64)", "Elderly (≥65)"))) %>%
  count(出院年份, age_grp, name = "n")

p1 <- ggplot(fig1_data, aes(x = 出院年份, y = n, fill = age_grp)) +
  geom_area(alpha = 0.85) +
  scale_x_continuous(breaks = 2014:2025) +
  scale_y_continuous(labels = scales::comma) +
  scale_fill_manual(values = c(PALETTE$green, PALETTE$blue, PALETTE$orange),
                    name = "Age group") +
  labs(title = "Figure 1. Annual orthopaedic admissions by age group, 2014-2025",
       x = "Discharge year", y = "Number of admissions") +
  theme_manuscript()

save_figure(p1, "Figure_1.png", width = 10, height = 5)

# ============================================================
# FIGURE 2: Diagnostic category composition over time
# ============================================================
log_msg("  Generating Figure 2...")

fig2_data <- df %>%
  filter(诊断大类 != "其他") %>%
  count(出院年份, 诊断大类, name = "n") %>%
  group_by(出院年份) %>%
  mutate(pct = 100 * n / sum(n)) %>%
  ungroup()

p2 <- ggplot(fig2_data, aes(x = 出院年份, y = pct, fill = 诊断大类)) +
  geom_area(alpha = 0.85, position = "stack") +
  scale_x_continuous(breaks = 2014:2025) +
  scale_fill_brewer(palette = "Set2", name = "Diagnostic category") +
  labs(title = "Figure 2. Annual diagnostic category composition, 2014-2025",
       x = "Discharge year", y = "Percentage of admissions (%)") +
  theme_manuscript()

save_figure(p2, "Figure_2.png", width = 10, height = 5)

# ============================================================
# FIGURE 3: Sex-specific admission trends
# ============================================================
log_msg("  Generating Figure 3...")

fig3_data <- df %>%
  count(出院年份, 性别, name = "n")

p3 <- ggplot(fig3_data, aes(x = 出院年份, y = n, colour = 性别, group = 性别)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_x_continuous(breaks = 2014:2025) +
  scale_y_continuous(labels = scales::comma) +
  scale_colour_manual(values = c("男性" = PALETTE$blue, "女性" = PALETTE$rose),
                      labels = c("男性" = "Male", "女性" = "Female"),
                      name = "Sex") +
  labs(title = "Figure 3. Annual orthopaedic admissions by sex, 2014-2025",
       x = "Discharge year", y = "Number of admissions") +
  theme_manuscript()

save_figure(p3, "Figure_3.png", width = 10, height = 5)

# ============================================================
# FIGURE 4: Stratified hospitalisation cost trends
# ============================================================
log_msg("  Generating Figure 4...")

fig4_data <- df %>%
  filter(费用异常标记 == "正常", !is.na(住院总费用RMB)) %>%
  mutate(stratum = case_when(
    是否骨折 == "是" & 诊断大类 != "内固定相关手术" ~ "Emergency trauma",
    诊断大类 %in% c("内固定相关手术", "退变性疾病") ~ "Elective",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(stratum)) %>%
  group_by(出院年份, stratum) %>%
  summarise(mean_cost = mean(住院总费用RMB), .groups = "drop")

p4 <- ggplot(fig4_data, aes(x = 出院年份, y = mean_cost,
                             colour = stratum, group = stratum)) +
  geom_vline(xintercept = 2023, linetype = "dashed", colour = "grey50") +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  annotate("text", x = 2023, y = max(fig4_data$mean_cost) * 0.95,
           label = "DRG reform", hjust = -0.1, size = 3.5, colour = "grey40") +
  scale_x_continuous(breaks = 2014:2025) +
  scale_y_continuous(labels = scales::comma_format(prefix = "¥")) +
  scale_colour_manual(values = c("Emergency trauma" = PALETTE$red,
                                  "Elective" = PALETTE$blue),
                      name = "Acuity stratum") +
  labs(title = "Figure 4. Hospitalisation costs by admission acuity stratum, 2014-2025",
       x = "Discharge year", y = "Mean hospitalisation cost (RMB)") +
  theme_manuscript()

save_figure(p4, "Figure_4.png", width = 10, height = 5)

# ============================================================
# FIGURE 5: Public health signals (seasonal + equity)
# ============================================================
log_msg("  Generating Figure 5...")

# Panel A: Elderly hip fracture monthly distribution
hip_elderly <- df %>%
  filter(grepl("股骨颈骨折|股骨粗隆间骨折", 出院主诊断), 年龄 >= 65)

monthly_hip <- hip_elderly %>%
  count(出院月份, name = "n") %>%
  tidyr::complete(出院月份 = 1:12, fill = list(n = 0)) %>%
  mutate(season = case_when(
    出院月份 %in% c(10,11,12,1,2) ~ "Autumn-winter (Oct-Feb)",
    出院月份 %in% 5:8 ~ "Summer (May-Aug)",
    TRUE ~ "Spring/early autumn"
  ))

p5a <- ggplot(monthly_hip, aes(x = factor(出院月份), y = n, fill = season)) +
  geom_col(alpha = 0.85, colour = "black", linewidth = 0.3) +
  geom_hline(yintercept = mean(monthly_hip$n), linetype = "dashed", colour = "grey50") +
  scale_x_discrete(labels = month.abb) +
  scale_fill_manual(values = c("Autumn-winter (Oct-Feb)" = PALETTE$red,
                                "Spring/early autumn" = PALETTE$orange,
                                "Summer (May-Aug)" = PALETTE$blue),
                    name = "Season") +
  labs(subtitle = "A. Monthly distribution of elderly (≥65) hip fractures",
       x = "Month", y = "Number of admissions") +
  theme_manuscript() +
  theme(legend.position = "bottom", legend.text = element_text(size = 8))

# Panel B: Equity in surgery rates
cohort_b <- df %>%
  filter(是否骨折 == "是", 诊断大类 != "内固定相关手术",
         患者来源分类 %in% c("江苏本地", "外省流动人口")) %>%
  mutate(surgery = as.integer(是否手术 == "是"))

site_rates <- cohort_b %>%
  group_by(诊断大类, 患者来源分类) %>%
  summarise(rate = 100 * mean(surgery), .groups = "drop") %>%
  mutate(诊断大类 = factor(诊断大类, levels = c("上肢","下肢","脊柱/骨盆")))

p5b <- ggplot(site_rates, aes(x = 诊断大类, y = rate, fill = 患者来源分类)) +
  geom_col(position = "dodge", alpha = 0.85, colour = "black", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.1f%%", rate)),
            position = position_dodge(width = 0.9), vjust = -0.5, size = 3) +
  scale_y_continuous(limits = c(0, 100)) +
  scale_x_discrete(labels = c("上肢" = "Upper limb",
                              "下肢" = "Lower limb",
                              "脊柱/骨盆" = "Spine/pelvis")) +
  scale_fill_manual(values = c("江苏本地" = PALETTE$blue,
                                "外省流动人口" = PALETTE$orange),
                    labels = c("江苏本地" = "Local Jiangsu",
                               "外省流动人口" = "Inter-provincial migrant"),
                    name = "Patient origin") +
  labs(subtitle = "B. Surgical intervention rates by patient origin",
       x = "Fracture site", y = "Surgery rate (%)") +
  theme_manuscript() +
  theme(legend.position = "bottom")

p5 <- p5a + p5b +
  patchwork::plot_annotation(
    title = "Figure 5. Public health signals: seasonal pattern and equity gap",
    theme = theme(plot.title = element_text(face = "bold", size = 12))
  )

save_figure(p5, "Figure_5.png", width = 13, height = 5)

# ============================================================
# FIGURE 6: Elderly women orthopaedic burden trajectory
# ============================================================
log_msg("  Generating Figure 6...")

fig6_data <- df %>%
  filter(年龄 >= 65) %>%
  count(出院年份, 性别, name = "n")

p6 <- ggplot(fig6_data, aes(x = 出院年份, y = n, colour = 性别, group = 性别)) +
  geom_line(linewidth = 1.5) +
  geom_point(size = 3) +
  scale_x_continuous(breaks = 2014:2025) +
  scale_y_continuous(labels = scales::comma) +
  scale_colour_manual(values = c("男性" = PALETTE$blue, "女性" = PALETTE$rose),
                      labels = c("男性" = "Elderly men (≥65)",
                                 "女性" = "Elderly women (≥65)"),
                      name = "") +
  labs(title = "Figure 6. Disproportionate orthopaedic burden in elderly women, 2014-2025",
       x = "Discharge year", y = "Annual orthopaedic admissions") +
  theme_manuscript() +
  theme(legend.position = "top")

save_figure(p6, "Figure_6.png", width = 10, height = 5)

log_msg("Module 09 complete. All 6 figures saved.")
