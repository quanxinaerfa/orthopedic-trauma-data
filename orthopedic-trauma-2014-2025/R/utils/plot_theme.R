# ============================================================
# plot_theme.R
# ------------------------------------------------------------
# Purpose:   Unified ggplot2 theme and colour palette for all
#            figures. Ensures consistent visual style across
#            Figures 1-6 in the manuscript.
# ============================================================

#' Custom ggplot2 theme matching manuscript figure style
theme_manuscript <- function(base_size = 11) {
  theme_minimal(base_size = base_size, base_family = "serif") %+replace%
    theme(
      panel.grid.minor   = element_blank(),
      panel.grid.major   = element_line(colour = "grey90", linewidth = 0.3),
      panel.background   = element_rect(fill = "white", colour = NA),
      plot.background    = element_rect(fill = "white", colour = NA),
      axis.line          = element_line(colour = "black", linewidth = 0.4),
      axis.ticks         = element_line(colour = "black", linewidth = 0.3),
      axis.text          = element_text(colour = "black"),
      strip.background   = element_rect(fill = "grey90", colour = NA),
      legend.background  = element_blank(),
      legend.key         = element_blank(),
      plot.title         = element_text(face = "bold", hjust = 0, size = base_size + 1),
      plot.subtitle      = element_text(hjust = 0, size = base_size - 1, colour = "grey30"),
      plot.caption       = element_text(hjust = 0, size = base_size - 2, colour = "grey50")
    )
}

#' Manuscript colour palette
PALETTE <- list(
  blue   = "#2c6e9b",
  orange = "#e07b39",
  green  = "#5b9e6b",
  red    = "#c0392b",
  rose   = "#c0666a",
  grey   = "#8a8a92",
  sky    = "#7eb8c4"
)

#' Sex-based fill scale
scale_fill_sex <- function() {
  scale_fill_manual(values = c("男性" = PALETTE$blue, "女性" = PALETTE$rose),
                    labels = c("男性" = "Male", "女性" = "Female"),
                    name = "Sex")
}

#' Origin-based fill scale
scale_fill_origin <- function() {
  scale_fill_manual(values = c("江苏本地" = PALETTE$blue,
                               "外省流动人口" = PALETTE$orange,
                               "其他" = PALETTE$grey),
                    labels = c("江苏本地" = "Local Jiangsu",
                               "外省流动人口" = "Inter-provincial migrant",
                               "其他" = "Other"),
                    name = "Patient origin")
}
