# ============================================================
# helper_functions.R
# ------------------------------------------------------------
# Purpose:   Common utility functions used across modules
# ============================================================

#' Format p-value for reporting
#' @param p numeric p-value
#' @return formatted string
format_pvalue <- function(p) {
  if (is.na(p)) return("NA")
  if (p < 0.001) return("p < 0.001")
  return(sprintf("p = %.3f", p))
}

#' Format odds ratio with 95% CI
#' @param or odds ratio
#' @param lo lower CI
#' @param hi upper CI
format_or_ci <- function(or, lo, hi) {
  sprintf("%.2f (95%% CI %.2f-%.2f)", or, lo, hi)
}

#' Derive province code from Chinese national ID number
#' First 2 digits = province; first 6 digits = county
#' @param id_vec character vector of ID numbers
#' @return character vector of 2-digit province codes
derive_province <- function(id_vec) {
  ids <- as.character(id_vec)
  ids <- ifelse(nchar(ids) >= 6, substr(ids, 1, 2), NA_character_)
  return(ids)
}

#' Classify patient origin (local Jiangsu / migrant / other)
#' @param province_code 2-digit province code from ID
classify_origin <- function(province_code) {
  case_when(
    is.na(province_code) ~ "其他",
    province_code == JIANGSU_PROVINCE_CODE ~ "江苏本地",
    province_code %in% c("11","12","13","14","15","21","22","23","31","33","34","35",
                         "36","37","41","42","43","44","45","46","50","51","52","53",
                         "54","61","62","63","64","65") ~ "外省流动人口",
    TRUE ~ "其他"
  )
}

#' Categorise age into groups
#' @param age numeric age vector
age_group <- function(age) {
  cut(age,
      breaks = c(-Inf, PAEDIATRIC_CUTOFF, 45, 64, Inf),
      labels = c("0-17", "18-45", "46-64", "65+"),
      right = TRUE)
}

#' Save table to CSV with timestamp
save_table <- function(df, filename) {
  out_path <- file.path(TABLES_DIR, filename)
  write.csv(df, out_path, row.names = FALSE, fileEncoding = "UTF-8")
  message("  Saved: ", out_path)
}

#' Save plot to PNG at 200 dpi
save_figure <- function(plot, filename, width = 10, height = 6) {
  out_path <- file.path(FIGURES_DIR, filename)
  ggsave(out_path, plot = plot, width = width, height = height, dpi = 200)
  message("  Saved: ", out_path)
}

#' Log message with timestamp
log_msg <- function(...) {
  msg <- paste0("[", format(Sys.time(), "%H:%M:%S"), "] ", ...)
  message(msg)
}
