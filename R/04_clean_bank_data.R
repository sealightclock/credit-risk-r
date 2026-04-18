# =========================================================
# 04_clean_bank_data.R
# Purpose:
#   Read the FDIC file and create a cleaned bank-level dataset.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

fdic_files <- list.files(
  path = dir_raw_fdic,
  pattern = "\\.(csv|txt)$",
  full.names = TRUE
)

if (length(fdic_files) == 0) {
  stop("No FDIC files available in data_raw/fdic/.")
}

read_one_fdic_file <- function(path) {
  readr::read_csv(path, show_col_types = FALSE) %>%
    janitor::clean_names()
}

raw_list <- lapply(fdic_files, read_one_fdic_file)
fdic_raw <- dplyr::bind_rows(raw_list)

bank_panel_clean <- fdic_raw %>%
  mutate(
    bank_id = as.character(cert),
    bank_name = as.character(name),
    quarter_end_date = lubridate::ymd(as.character(repdte)),
    total_assets = as.numeric(asset),
    total_loans = as.numeric(lnlsnet),
    deposits = as.numeric(dep),
    net_income = as.numeric(netinc),
    total_equity_capital = as.numeric(eqtot),
    allowance_for_credit_losses = as.numeric(lnatresr),
    noncurrent_loans = as.numeric(nclnlsr),
    net_charge_offs = as.numeric(ntlnlsr),
    tier1_capital = as.numeric(idt1cer),
    risk_weighted_assets = as.numeric(idt1rwajr)
  ) %>%
  select(
    bank_id, bank_name, quarter_end_date, total_assets, total_loans,
    allowance_for_credit_losses, noncurrent_loans, net_charge_offs,
    deposits, tier1_capital, risk_weighted_assets,
    total_equity_capital, net_income
  ) %>%
  distinct()

save_rds_safely(bank_panel_clean, file.path(dir_panel, "bank_panel_clean.rds"))
save_csv_safely(bank_panel_clean, file.path(dir_panel, "bank_panel_clean.csv"))

message("\nCleaned data preview:")
print(dplyr::glimpse(bank_panel_clean))
