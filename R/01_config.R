# =========================================================
# 01_config.R
# Purpose:
#   Store all project-wide configuration in one place.
#
# Why this file is important:
#   - Avoids hardcoding values throughout scripts
#   - Makes the project easier to modify and debug
#   - Helps beginners understand what controls the workflow
# =========================================================

# ---------------------------------------------------------
# 1. Global random seed
# ---------------------------------------------------------
#
# This ensures that results are reproducible.
# For example:
# - train/test split
# - random forest behavior
#
# If you rerun the project, you will get the same results.
project_seed <- 1234

set.seed(project_seed)

# ---------------------------------------------------------
# 2. Directory structure
# ---------------------------------------------------------
#
# These variables define where data and outputs are stored.
# Keeping them here avoids repeating file paths everywhere.
# ---------------------------------------------------------

# Raw data (input files)
dir_raw_fdic <- "data_raw/fdic"   # FDIC bank data
dir_raw_fred <- "data_raw/fred"   # macroeconomic data (optional)

# Processed data (cleaned and engineered datasets)
dir_panel    <- "data_processed/bank_panel"  # cleaned bank data
dir_modeling <- "data_processed/modeling"    # dataset with target variable
dir_features <- "data_processed/features"    # final feature dataset

# Outputs (results of the project)
dir_figures    <- "outputs/figures"        # charts
dir_tables     <- "outputs/tables"         # summary tables
dir_metrics    <- "outputs/model_metrics"  # model performance
dir_watchlists <- "outputs/watchlists"     # ranked risk outputs

# Models (saved trained models)
dir_models_logistic <- "models/logistic_regression"
dir_models_rf       <- "models/random_forest"

# ---------------------------------------------------------
# 3. Target definition (IMPORTANT)
# ---------------------------------------------------------
#
# In this project, we define "high risk" using net charge-offs.
#
# Since we only have one quarter of data, we do NOT use
# future values (no lead/lag).
#
# Instead, we classify:
#   high_risk = top X% of banks by net charge-offs
#
# This threshold can be adjusted if needed.
# ---------------------------------------------------------

# NOTE:
# This variable is not used directly in your current version
# (which uses quantiles), but we keep it here for flexibility.
target_threshold_nco <- 0.01

# ---------------------------------------------------------
# 4. Train/test split (legacy / optional)
# ---------------------------------------------------------
#
# These are used in multi-quarter projects.
# In your current single-quarter project, we use
# random splitting instead.
#
# We keep them here for future expansion.
# ---------------------------------------------------------

train_end_date  <- as.Date("2022-12-31")
test_start_date <- as.Date("2023-01-01")

# ---------------------------------------------------------
# 5. Column name definitions
# ---------------------------------------------------------
#
# These make the code easier to maintain.
# If column names change, you only update them here.
# ---------------------------------------------------------

col_bank_id   <- "bank_id"
col_bank_name <- "bank_name"
col_quarter   <- "quarter_end_date"

# NOTE:
# Your current project uses "high_risk" instead of
# "high_risk_next_q", but we keep this for future extension.
col_target <- "high_risk_next_q"

# ---------------------------------------------------------
# 6. Watchlist thresholds
# ---------------------------------------------------------
#
# These define how we categorize predicted risk into:
# - High
# - Medium
# - Low
#
# Example:
#   pred_prob >= 0.70 → High risk
#   pred_prob >= 0.40 → Medium risk
#   otherwise → Low risk
# ---------------------------------------------------------

watchlist_high_cutoff   <- 0.70
watchlist_medium_cutoff <- 0.40

# ---------------------------------------------------------
# 7. Create project directories
# ---------------------------------------------------------
#
# This function ensures that all required folders exist.
# If a folder is missing, it will be created automatically.
#
# This is useful when:
# - running the project on a new computer
# - cloning the repo from GitHub
# ---------------------------------------------------------

create_project_dirs <- function() {
  dirs <- c(
    dir_raw_fdic,
    dir_raw_fred,
    dir_panel,
    dir_modeling,
    dir_features,
    dir_figures,
    dir_tables,
    dir_metrics,
    dir_watchlists,
    dir_models_logistic,
    dir_models_rf
  )
  
  for (d in dirs) {
    if (!dir.exists(d)) {
      dir.create(d, recursive = TRUE)
    }
  }
}

# Run directory setup
create_project_dirs()

# ---------------------------------------------------------
# 8. Final message (optional, beginner-friendly)
# ---------------------------------------------------------

message("Project configuration loaded successfully.")
