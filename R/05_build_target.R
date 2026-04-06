# =========================================================
# 05_build_target.R
# Purpose: Create next-quarter target variable.
# This version assumes net_charge_offs is already a ratio.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

bank_panel_clean <- readRDS(file.path(dir_panel, "bank_panel_clean.rds"))

model_base <- bank_panel_clean %>%
  arrange(.data[[col_bank_id]], .data[[col_quarter]]) %>%
  group_by(.data[[col_bank_id]]) %>%
  mutate(
    # net_charge_offs already appears to be a ratio in your FDIC dataset
    nco_ratio = net_charge_offs,
    nco_ratio_next_q = lead(nco_ratio, 1),
    high_risk_next_q = if_else(
      !is.na(nco_ratio_next_q) & nco_ratio_next_q > target_threshold_nco,
      1,
      0,
      missing = 0
    )
  ) %>%
  ungroup()

save_rds_safely(
  model_base,
  file.path(dir_modeling, "model_base.rds")
)

target_summary <- model_base %>%
  count(high_risk_next_q) %>%
  mutate(pct = n / sum(n))

save_csv_safely(
  target_summary,
  file.path(dir_tables, "target_summary.csv")
)

print(target_summary)