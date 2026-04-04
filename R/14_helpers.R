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

calc_growth_rate <- function(x, lag_x) {
  ifelse(is.na(lag_x) | lag_x == 0, NA_real_, (x - lag_x) / lag_x)
}

safe_divide <- function(num, denom) {
  ifelse(is.na(denom) | denom == 0, NA_real_, num / denom)
}

pick_first_existing <- function(df, candidates) {
  present <- intersect(candidates, names(df))
  if (length(present) == 0) return(rep(NA_real_, nrow(df)))
  out <- df[[present[1]]]
  if (length(present) > 1) {
    for (nm in present[-1]) {
      out <- dplyr::coalesce(out, df[[nm]])
    }
  }
  out
}

pick_date_field <- function(df, candidates) {
  present <- intersect(candidates, names(df))
  if (length(present) == 0) return(as.Date(rep(NA, nrow(df))))
  out <- df[[present[1]]]
  if (length(present) > 1) {
    for (nm in present[-1]) {
      out <- dplyr::coalesce(out, df[[nm]])
    }
  }
  out_chr <- as.character(out)
  out_chr <- stringr::str_replace_all(out_chr, "[^0-9-]", "")
  parsed <- suppressWarnings(lubridate::ymd(out_chr))
  parsed
}
