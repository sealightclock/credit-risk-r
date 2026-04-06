# =========================================================
# 06_feature_engineering.R
# Purpose: Create model features and merge macro data.
# This version assumes several FDIC fields are already ratios.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

model_base <- readRDS(file.path(dir_modeling, "model_base.rds"))
fred_df <- readRDS(file.path(dir_raw_fred, "fred_macro_data.rds"))

feature_panel <- model_base %>%
  arrange(.data[[col_bank_id]], .data[[col_quarter]]) %>%
  group_by(.data[[col_bank_id]]) %>%
  mutate(
    # These already appear to be ratios in your dataset
    reserve_coverage_ratio = allowance_for_credit_losses,
    npa_ratio = noncurrent_loans,
    nco_ratio = net_charge_offs,
    capital_ratio = tier1_capital,
    
    # These are still useful because the numerators/denominators look like dollars
    equity_to_assets = safe_divide(total_equity_capital, total_assets),
    roa = safe_divide(net_income, total_assets),
    
    total_loans_lag1 = dplyr::lag(total_loans, 1),
    deposits_lag1 = dplyr::lag(deposits, 1),
    nco_ratio_lag1 = dplyr::lag(nco_ratio, 1),
    npa_ratio_lag1 = dplyr::lag(npa_ratio, 1),
    
    loan_growth_qoq = calc_growth_rate(total_loans, total_loans_lag1),
    deposit_growth_qoq = calc_growth_rate(deposits, deposits_lag1)
  ) %>%
  ungroup() %>%
  left_join(fred_df, by = c("quarter_end_date"))

save_rds_safely(
  feature_panel,
  file.path(dir_features, "feature_panel.rds")
)

save_csv_safely(
  feature_panel,
  file.path(dir_features, "feature_panel.csv")
)

print(glimpse(feature_panel))
print(summary(feature_panel))