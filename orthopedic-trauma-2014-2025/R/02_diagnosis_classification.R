# ============================================================
# 02_diagnosis_classification.R
# ------------------------------------------------------------
# Purpose:   Apply Chinese keyword-matching algorithm to classify
#            diagnoses into anatomical categories. Aggregate
#            terminology variants (tibial plateau, distal radius
#            and their synonyms) to mitigate coding-system shifts.
# Input:     data/cleaned_data.rds
# Output:    data/cleaned_data.rds (overwrites with new columns)
#            output/tables/T02_diagnosis_distribution.csv
#            docs/keyword_dictionary.md (rendered)
# Section:   Methods - Diagnosis classification
# ============================================================

if (!exists("PROJECT_ROOT")) source(file.path(getwd(), "R", "00_setup.R"))

log_msg("Module 02: Diagnosis classification starting...")

df <- readRDS(file.path(DATA_DIR, "cleaned_data.rds"))

# ---- Define keyword groups ----
# IMPORTANT: Multiple synonyms map to the same parent category to handle
# terminology shifts during the study period (see docs/keyword_dictionary.md)

upper_limb_keywords <- c(
  "桡骨", "尺骨", "尺桡骨", "肱骨", "肩胛", "锁骨",
  "腕骨", "掌骨", "指骨", "肩关节", "肘关节"
)

lower_limb_keywords <- c(
  "股骨", "胫骨", "腓骨", "胫腓骨", "跟骨", "距骨",
  "髌骨", "踝", "足", "胫骨平台", "髋关节"
)

spine_pelvis_keywords <- c(
  "腰椎", "胸椎", "颈椎", "脊柱", "椎体", "骨盆", "骶骨"
)

hardware_keywords <- c(
  "内固定取出", "钢板取出", "螺钉取出", "髓内钉取出", "克氏针取出"
)

degenerative_keywords <- c(
  "颈椎病", "椎间盘", "膝骨关节炎", "髋关节炎", "骨关节炎",
  "腰椎管狭窄", "椎管狭窄"
)

fracture_keywords <- c(
  "骨折", "骨裂", "粉碎性", "粗隆间", "股骨颈", "椎体压缩"
)

# ---- Classification function ----
classify_diagnosis <- function(diag_text) {
  if (is.na(diag_text) || diag_text == "") return("其他")

  d <- as.character(diag_text)

  # Hardware-related procedures (highest priority - may overlap with anatomy)
  if (any(stringr::str_detect(d, hardware_keywords))) return("内固定相关手术")

  # Degenerative diseases (before fracture check, as may co-occur)
  if (any(stringr::str_detect(d, degenerative_keywords)) &&
      !any(stringr::str_detect(d, fracture_keywords))) {
    return("退变性疾病")
  }

  # Anatomical categorisation for fractures and traumatic conditions
  if (any(stringr::str_detect(d, spine_pelvis_keywords))) return("脊柱/骨盆")
  if (any(stringr::str_detect(d, lower_limb_keywords))) return("下肢")
  if (any(stringr::str_detect(d, upper_limb_keywords))) return("上肢")

  return("其他")
}

# ---- Identify whether diagnosis is a fracture ----
is_fracture <- function(diag_text) {
  if (is.na(diag_text)) return(NA_character_)
  if (any(stringr::str_detect(as.character(diag_text), fracture_keywords))) {
    return("是")
  }
  return("否")
}

# ---- Apply classification (skip if already done) ----
if (!"诊断大类" %in% names(df) ||
    sum(df$诊断大类 == "其他", na.rm = TRUE) > 0.5 * nrow(df)) {
  log_msg("  Applying keyword-matching algorithm...")
  df$诊断大类 <- vapply(df$出院主诊断, classify_diagnosis, character(1))
}

if (!"是否骨折" %in% names(df)) {
  df$是否骨折 <- vapply(df$出院主诊断, is_fracture, character(1))
}

# ---- Summary table ----
diag_dist <- df %>%
  count(诊断大类, name = "n") %>%
  mutate(percent = round(100 * n / sum(n), 1)) %>%
  arrange(desc(n))

log_msg("  Diagnosis category distribution:")
print(diag_dist)

# ---- Save outputs ----
saveRDS(df, file.path(DATA_DIR, "cleaned_data.rds"))
save_table(diag_dist, "T02_diagnosis_distribution.csv")

log_msg("Module 02 complete.")
