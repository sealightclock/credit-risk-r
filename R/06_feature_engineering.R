# =========================================================
# 06_feature_engineering.R
# Purpose:
#   Build the feature set used by the models.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

df <- readRDS(file.path(dir_modeling, "model_base.rds"))

fred_rds_path <- file.path(dir_raw_fred, "fred_macro_data.rds")
fred_df <- NULL

if (file.exists(fred_rds_path)) {
  fred_df <- readRDS(fred_rds_path)
  message("FRED macro data found and will be merged.")
} else {
  message("FRED macro data not found. Continuing without macro data.")
}

feature_panel <- df %>%
  mutate(
    reserve_coverage_ratio = allowance_for_credit_losses,
    npa_ratio = noncurrent_loans,
    nco_ratio = net_charge_offs,
    capital_ratio = tier1_capital,
    equity_to_assets = safe_divide(total_equity_capital, total_assets),
    roa = safe_divide(net_income, total_assets),
    loans_to_assets = safe_divide(total_loans, total_assets),
    deposits_to_assets = safe_divide(deposits, total_assets)
  )

if (!is.null(fred_df)) {
  feature_panel <- feature_panel %>%
    left_join(fred_df, by = "quarter_end_date")
}

feature_panel <- feature_panel %>%
  select(
    bank_id, bank_name, quarter_end_date, high_risk,
    total_assets, total_loans, deposits, total_equity_capital, net_income,
    allowance_for_credit_losses, noncurrent_loans, net_charge_offs,
    tier1_capital, risk_weighted_assets,
    reserve_coverage_ratio, npa_ratio, nco_ratio, capital_ratio,
    equity_to_assets, roa, loans_to_assets, deposits_to_assets,
    everything()
  ) %>%
  distinct()

save_rds_safely(feature_panel, file.path(dir_features, "feature_panel.rds"))
save_csv_safely(feature_panel, file.path(dir_features, "feature_panel.csv"))

message("\nFeature engineering complete.")
print(dplyr::glimpse(feature_panel))
