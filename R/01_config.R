# =========================================================
# 01_config.R
# Purpose:
#   Store all project-wide configuration in one place.
# =========================================================

project_seed <- 1234
set.seed(project_seed)

# Raw input data
dir_raw_fdic <- "data_raw/fdic"
dir_raw_fred <- "data_raw/fred"

# Processed data
dir_panel    <- "data_processed/bank_panel"
dir_modeling <- "data_processed/modeling"
dir_features <- "data_processed/features"

# Outputs
dir_figures    <- "outputs/figures"
dir_tables     <- "outputs/tables"
dir_metrics    <- "outputs/model_metrics"
dir_watchlists <- "outputs/watchlists"

# Saved models
dir_models_logistic <- "models/logistic_regression"
dir_models_rf       <- "models/random_forest"
dir_models_xgb      <- "models/xgboost"

# Optional future settings for a multi-quarter version
train_end_date  <- as.Date("2022-12-31")
test_start_date <- as.Date("2023-01-01")

# Standard column names used across scripts
col_bank_id   <- "bank_id"
col_bank_name <- "bank_name"
col_quarter   <- "quarter_end_date"
col_target    <- "high_risk"

# Risk bucket thresholds used in the watchlist
watchlist_high_cutoff   <- 0.70
watchlist_medium_cutoff <- 0.40

create_project_dirs <- function() {
  dirs <- c(
    dir_raw_fdic, dir_raw_fred, dir_panel, dir_modeling, dir_features,
    dir_figures, dir_tables, dir_metrics, dir_watchlists,
    dir_models_logistic, dir_models_rf, dir_models_xgb
  )

  for (d in dirs) {
    if (!dir.exists(d)) {
      dir.create(d, recursive = TRUE)
    }
  }
}

create_project_dirs()
message("Project configuration loaded successfully.")
