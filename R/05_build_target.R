source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

bank_panel_clean <- readRDS(file.path(dir_panel, "bank_panel_clean.rds"))

model_base <- bank_panel_clean %>%
  arrange(.data[[col_bank_id]], .data[[col_quarter]]) %>%
  group_by(.data[[col_bank_id]]) %>%
  mutate(
    nco_ratio = safe_divide(net_charge_offs, total_loans),
    nco_ratio_next_q = lead(nco_ratio, 1),
    high_risk_next_q = if_else(
      !is.na(nco_ratio_next_q) & nco_ratio_next_q > target_threshold_nco,
      1,
      0,
      missing = 0
    )
  ) %>%
  ungroup()

save_rds_safely(model_base, file.path(dir_modeling, "model_base.rds"))

target_summary <- model_base %>%
  count(high_risk_next_q) %>%
  mutate(pct = n / sum(n))

save_csv_safely(target_summary, file.path(dir_tables, "target_summary.csv"))
print(target_summary)
