# =========================================================
# 12_score_watchlist.R
# Purpose:
#   Score all banks using the trained logistic regression model
#   and create a ranked watchlist.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

df <- readRDS(file.path(dir_features, "feature_panel.rds"))
model <- readRDS(file.path(dir_models_logistic, "logistic_model.rds"))

score_df <- df %>%
  select(
    bank_id, bank_name, quarter_end_date,
    reserve_coverage_ratio, npa_ratio, capital_ratio,
    equity_to_assets, roa, loans_to_assets, deposits_to_assets,
    net_charge_offs, noncurrent_loans, total_assets, total_loans,
    deposits, total_equity_capital, net_income
  ) %>%
  drop_na(
    reserve_coverage_ratio, npa_ratio, capital_ratio,
    equity_to_assets, roa, loans_to_assets, deposits_to_assets
  )

if (nrow(score_df) == 0) {
  stop("No rows available for scoring after drop_na().")
}

score_df$pred_prob <- predict(model, newdata = score_df, type = "response")

score_df <- score_df %>%
  mutate(risk_bucket = add_risk_bucket(pred_prob))

watchlist <- score_df %>%
  arrange(desc(pred_prob)) %>%
  select(
    bank_id, bank_name, quarter_end_date, pred_prob, risk_bucket,
    npa_ratio, capital_ratio, reserve_coverage_ratio, roa,
    loans_to_assets, deposits_to_assets, net_charge_offs,
    noncurrent_loans, total_assets, total_loans, deposits
  )

save_csv_safely(watchlist, file.path(dir_watchlists, "watchlist.csv"))
save_csv_safely(watchlist %>% slice_head(n = 20), file.path(dir_watchlists, "watchlist_top20.csv"))

message("\nWatchlist generation complete.")
print(watchlist %>% slice_head(n = 20))
