# =========================================================
# 04_clean_bank_data.R
# Purpose: Read raw FDIC files and create a cleaned bank-quarter panel.
# This version is mapped to your actual FDIC preview columns.
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

# ---------------------------------------------------------
# Column mapping based on your actual file:
#
# CERT     -> bank certificate number
# NAME     -> bank name
# REPDTE   -> report date
# ASSET    -> total assets
# LNLSNET  -> net loans and leases
# LNATRESR -> allowance / reserve ratio or reserve-related field
# DEP      -> total deposits
# NETINC   -> net income
# NCLNLSR  -> noncurrent loan ratio
# NTLNLSR  -> net charge-off ratio
# EQ / EQTOT -> equity
# IDT1CER  -> tier 1 capital ratio or related capital field
# IDT1RWAJR / RBCRWAJ -> risk-based capital / RWA-related field
#
# IMPORTANT:
# Some of these are ratios, not raw dollar amounts.
# That is okay for now because your goal is to get a beginner-friendly,
# working project pipeline first.
# ---------------------------------------------------------

bank_panel_clean <- fdic_raw %>%
  mutate(
    bank_id = as.character(cert),
    bank_name = as.character(name),
    
    # REPDTE is typically YYYYMMDD, so ymd() is safer than as.Date()
    quarter_end_date = lubridate::ymd(as.character(repdte)),
    
    # Core size / balance-sheet fields
    total_assets = as.numeric(asset),
    total_loans = as.numeric(lnlsnet),
    deposits = as.numeric(dep),
    net_income = as.numeric(netinc),
    
    # Capital
    total_equity_capital = as.numeric(eqtot),
    
    # These may not be perfect "raw dollars", but they are the best
    # beginner-friendly placeholders from your current file.
    tier1_capital = as.numeric(idt1cer),
    risk_weighted_assets = as.numeric(idt1rwajr),
    
    # Credit-risk related fields
    # These appear to be ratio-style fields in your dataset.
    allowance_for_credit_losses = as.numeric(lnatresr),
    noncurrent_loans = as.numeric(nclnlsr),
    net_charge_offs = as.numeric(ntlnlsr)
  ) %>%
  select(
    bank_id,
    bank_name,
    quarter_end_date,
    total_assets,
    total_loans,
    allowance_for_credit_losses,
    noncurrent_loans,
    net_charge_offs,
    deposits,
    tier1_capital,
    risk_weighted_assets,
    total_equity_capital,
    net_income
  ) %>%
  distinct()

save_rds_safely(
  bank_panel_clean,
  file.path(dir_panel, "bank_panel_clean.rds")
)

save_csv_safely(
  bank_panel_clean,
  file.path(dir_panel, "bank_panel_clean.csv")
)

print(dplyr::glimpse(bank_panel_clean))
print(summary(bank_panel_clean))