# =========================================================
# 06_feature_engineering.R
# Purpose: Create model features for the single-quarter version
# of the credit risk project.
#
# IMPORTANT:
# - This version is designed for your current dataset, which
#   only contains one quarter of data.
# - Because there is no time history yet, we do NOT use:
#     - lag()
#     - lead()
#     - quarter-over-quarter growth
#     - rolling averages
# - Instead, we build a cross-sectional feature set using the
#   current quarter only.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

# ---------------------------------------------------------
# 1. Load input datasets
# ---------------------------------------------------------

# This file is created by 05_build_target.R
df <- readRDS(file.path(dir_modeling, "model_base.rds"))

# FRED macro data is optional for the single-quarter version.
# If it exists, we merge it in. If not, we continue without it.
fred_rds_path <- file.path(dir_raw_fred, "fred_macro_data.rds")

fred_df <- NULL

if (file.exists(fred_rds_path)) {
  fred_df <- readRDS(fred_rds_path)
  message("FRED macro data found and will be merged.")
} else {
  message("FRED macro data not found. Continuing without macro data.")
}

# ---------------------------------------------------------
# 2. Build features
# ---------------------------------------------------------
#
# Based on your FDIC dataset, these fields already appear to
# be ratio-style variables:
# - allowance_for_credit_losses
# - noncurrent_loans
# - net_charge_offs
# - tier1_capital
#
# So we do NOT divide them again.
#
# We also create a few additional ratios from balance-sheet
# style fields that appear to be in dollars:
# - equity_to_assets
# - roa
# - loans_to_assets
# - deposits_to_assets
# ---------------------------------------------------------

feature_panel <- df %>%
  mutate(
    # These already behave like ratios in your file
    reserve_coverage_ratio = allowance_for_credit_losses,
    npa_ratio = noncurrent_loans,
    nco_ratio = net_charge_offs,
    capital_ratio = tier1_capital,
    
    # These are derived from amount-style fields
    equity_to_assets = safe_divide(total_equity_capital, total_assets),
    roa = safe_divide(net_income, total_assets),
    loans_to_assets = safe_divide(total_loans, total_assets),
    deposits_to_assets = safe_divide(deposits, total_assets)
  )

# ---------------------------------------------------------
# 3. Merge macro data if available
# ---------------------------------------------------------
#
# Since you currently have one quarter of data, merging FRED
# is simple: join by quarter_end_date if the macro file exists.
# ---------------------------------------------------------

if (!is.null(fred_df)) {
  feature_panel <- feature_panel %>%
    left_join(fred_df, by = c("quarter_end_date"))
}

# ---------------------------------------------------------
# 4. Keep the most useful columns together
# ---------------------------------------------------------
#
# This step is not strictly required, but it makes the output
# cleaner and easier to inspect.
# ---------------------------------------------------------

feature_panel <- feature_panel %>%
  select(
    bank_id,
    bank_name,
    quarter_end_date,
    
    # target
    any_of(c("high_risk", "high_risk_next_q")),
    
    # original core fields
    total_assets,
    total_loans,
    allowance_for_credit_losses,
    noncurrent_loans,
    net_charge_offs,
    deposits,
    tier1_capital,
    risk_weighted_assets,
    total_equity_capital,
    net_income,
    
    # engineered features
    reserve_coverage_ratio,
    npa_ratio,
    nco_ratio,
    capital_ratio,
    equity_to_assets,
    roa,
    loans_to_assets,
    deposits_to_assets,
    
    # include any FRED columns if present
    everything()
  ) %>%
  distinct()

# ---------------------------------------------------------
# 5. Save outputs
# ---------------------------------------------------------

save_rds_safely(
  feature_panel,
  file.path(dir_features, "feature_panel.rds")
)

save_csv_safely(
  feature_panel,
  file.path(dir_features, "feature_panel.csv")
)

# ---------------------------------------------------------
# 6. Print quick checks
# ---------------------------------------------------------

message("\nFeature engineering complete.\n")

print(glimpse(feature_panel))

message("\nMissing values by column:\n")
missing_summary <- feature_panel %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(
    cols = everything(),
    names_to = "column_name",
    values_to = "missing_count"
  ) %>%
  arrange(desc(missing_count))

print(missing_summary)

message("\nSummary of selected engineered features:\n")
print(
  summary(
    feature_panel %>%
      select(
        any_of(c(
          "reserve_coverage_ratio",
          "npa_ratio",
          "nco_ratio",
          "capital_ratio",
          "equity_to_assets",
          "roa",
          "loans_to_assets",
          "deposits_to_assets"
        ))
      )
  )
)