project_seed <- 1234

dir_raw_fdic        <- "data_raw/fdic"
dir_raw_fred        <- "data_raw/fred"
dir_panel           <- "data_processed/bank_panel"
dir_features        <- "data_processed/features"
dir_modeling        <- "data_processed/modeling"
dir_figures         <- "outputs/figures"
dir_tables          <- "outputs/tables"
dir_metrics         <- "outputs/model_metrics"
dir_watchlists      <- "outputs/watchlists"
dir_models_logistic <- "models/logistic_regression"
dir_models_rf       <- "models/random_forest"

target_threshold_nco <- 0.01
train_end_date <- as.Date("2022-12-31")
test_start_date <- as.Date("2023-01-01")

col_bank_id    <- "bank_id"
col_bank_name  <- "bank_name"
col_quarter    <- "quarter_end_date"
col_target     <- "high_risk_next_q"

watchlist_high_cutoff   <- 0.70
watchlist_medium_cutoff <- 0.40

set.seed(project_seed)

create_project_dirs <- function() {
  dirs <- c(
    dir_raw_fdic, dir_raw_fred, dir_panel, dir_features, dir_modeling,
    dir_figures, dir_tables, dir_metrics, dir_watchlists,
    dir_models_logistic, dir_models_rf
  )
  for (d in dirs) if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

create_project_dirs()
