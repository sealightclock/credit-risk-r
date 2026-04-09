# =========================================================
# 12_score_watchlist.R
# Purpose: Score all banks and create a ranked watchlist
# for the single-quarter version of the credit risk project.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

# ---------------------------------------------------------
# 1. Load data and trained model
# ---------------------------------------------------------

df <- readRDS(file.path(dir_features, "feature_panel.rds"))
model <- readRDS(file.path(dir_models_logistic, "logistic_model.rds"))

# ---------------------------------------------------------
# 2. Keep only the columns needed by the model
# ---------------------------------------------------------
#
# These must match the predictors used in 08_model_logistic.R
# ---------------------------------------------------------

score_df <- df %>%
  select(
    bank_id,
    bank_name,
    quarter_end_date,
    reserve_coverage_ratio,
    npa_ratio,
    capital_ratio,
    equity_to_assets,
    roa,
    loans_to_assets,
    deposits_to_assets,
    net_charge_offs,
    noncurrent_loans,
    total_assets,
    total_loans,
    deposits,
    total_equity_capital,
    net_income
  ) %>%
  drop_na(
    reserve_coverage_ratio,
    npa_ratio,
    capital_ratio,
    equity_to_assets,
    roa,
    loans_to_assets,
    deposits_to_assets
  )

cat("\nRows available for scoring:", nrow(score_df), "\n")

if (nrow(score_df) == 0) {
  stop("No rows available for scoring after drop_na().")
}

# ---------------------------------------------------------
# 3. Score all rows
# ---------------------------------------------------------

score_df$pred_prob <- predict(
  model,
  newdata = score_df,
  type = "response"
)

score_df <- score_df %>%
  mutate(
    risk_bucket = case_when(
      pred_prob >= 0.70 ~ "High",
      pred_prob >= 0.40 ~ "Medium",
      TRUE ~ "Low"
    )
  )

# ---------------------------------------------------------
# 4. Rank the watchlist
# ---------------------------------------------------------

watchlist <- score_df %>%
  arrange(desc(pred_prob)) %>%
  select(
    bank_id,
    bank_name,
    quarter_end_date,
    pred_prob,
    risk_bucket,
    npa_ratio,
    capital_ratio,
    reserve_coverage_ratio,
    roa,
    loans_to_assets,
    deposits_to_assets,
    net_charge_offs,
    noncurrent_loans,
    total_assets,
    total_loans,
    deposits
  )

# ---------------------------------------------------------
# 5. Save outputs
# ---------------------------------------------------------

save_csv_safely(
  watchlist,
  file.path(dir_watchlists, "watchlist.csv")
)

save_csv_safely(
  watchlist %>% slice_head(n = 20),
  file.path(dir_watchlists, "watchlist_top20.csv")
)

cat("\nTop 20 watchlist rows:\n")
print(watchlist %>% slice_head(n = 20))

message("\nWatchlist generation complete.\n")