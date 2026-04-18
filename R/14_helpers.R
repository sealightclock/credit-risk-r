# =========================================================
# 14_helpers.R
# Purpose:
#   Store small helper functions used across the project.
# =========================================================

save_csv_safely <- function(df, path) {
  readr::write_csv(df, path)
  message("Saved: ", path)
}

save_rds_safely <- function(object, path) {
  saveRDS(object, path)
  message("Saved: ", path)
}

add_risk_bucket <- function(prob) {
  dplyr::case_when(
    prob >= watchlist_high_cutoff   ~ "High",
    prob >= watchlist_medium_cutoff ~ "Medium",
    TRUE                            ~ "Low"
  )
}

safe_divide <- function(num, denom) {
  ifelse(is.na(denom) | denom == 0, NA_real_, num / denom)
}
