source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

model_base <- readRDS(file.path(dir_modeling, "model_base.rds"))
fred_df <- readRDS(file.path(dir_raw_fred, "fred_macro_data.rds"))

feature_panel <- model_base %>%
  arrange(.data[[col_bank_id]], .data[[col_quarter]]) %>%
  group_by(.data[[col_bank_id]]) %>%
  mutate(
    reserve_coverage_ratio = safe_divide(allowance_for_credit_losses, noncurrent_loans),
    npa_ratio = safe_divide(noncurrent_loans, total_assets),
    nco_ratio = safe_divide(net_charge_offs, total_loans),
    capital_ratio = safe_divide(tier1_capital, risk_weighted_assets),
    equity_to_assets = safe_divide(total_equity_capital, total_assets),
    roa = safe_divide(net_income, total_assets),

    total_loans_lag1 = lag(total_loans, 1),
    deposits_lag1 = lag(deposits, 1),
    nco_ratio_lag1 = lag(nco_ratio, 1),
    npa_ratio_lag1 = lag(npa_ratio, 1),

    loan_growth_qoq = calc_growth_rate(total_loans, total_loans_lag1),
    deposit_growth_qoq = calc_growth_rate(deposits, deposits_lag1)
  ) %>%
  ungroup() %>%
  left_join(fred_df, by = c("quarter_end_date"))

save_rds_safely(feature_panel, file.path(dir_features, "feature_panel.rds"))
save_csv_safely(feature_panel, file.path(dir_features, "feature_panel.csv"))
