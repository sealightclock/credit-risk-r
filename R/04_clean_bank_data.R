source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

fdic_files <- list.files(
  path = dir_raw_fdic,
  pattern = "\\.(csv|txt)$",
  full.names = TRUE
)

if (length(fdic_files) == 0) stop("No FDIC files available.")

read_one_fdic_file <- function(path) {
  readr::read_csv(path, show_col_types = FALSE) %>%
    janitor::clean_names()
}

raw_list <- lapply(fdic_files, read_one_fdic_file)
fdic_raw <- dplyr::bind_rows(raw_list)

# ---- Real FFIEC/FDIC schema mapping ----
bank_panel_clean <- fdic_raw %>%
  mutate(
    bank_id = as.character(pick_first_existing(., c("cert", "idrssd", "rssd9001", "rssdhcr", "fed_rssd"))),
    bank_name = as.character(pick_first_existing(., c("name", "bank", "inst_name", "institution_name"))),
    quarter_end_date = pick_date_field(., c("repdte", "report_date", "date", "as_of_date")),

    total_assets = as.numeric(pick_first_existing(., c("rcfd2170", "rcon2170"))),

    # Total loans and leases, net of unearned income.
    # Some downstream / derived datasets use B528 after 2001, so we include it as a fallback.
    total_loans = as.numeric(pick_first_existing(., c("rcfd2122", "rcon2122", "rcfdb528", "rconb528"))),

    # Allowance / ACL on loans and leases.
    allowance_for_credit_losses = as.numeric(pick_first_existing(., c("rcfd3123", "rcon3123", "rcfn3123"))),

    deposits = as.numeric(pick_first_existing(., c("rcfd2200", "rcon2200"))),

    tier1_capital = as.numeric(pick_first_existing(., c("rcfa8274", "rcoa8274", "rcfd8274", "rcon8274"))),
    risk_weighted_assets = as.numeric(pick_first_existing(., c("rcfaa223", "rcoaa223", "rcfda223", "rcona223"))),

    total_equity_capital = as.numeric(pick_first_existing(., c("rcfd3210", "rcon3210"))),
    net_income = as.numeric(pick_first_existing(., c("riad4340", "rcfd4340", "rcon4340"))),

    # Noncurrent loans:
    # 1) use any already-aggregated field if present
    # 2) otherwise try a practical sum of common RC-N style fields if they exist
    noncurrent_loans_preagg = as.numeric(pick_first_existing(., c("noncurrent_loans", "ncloan", "noncurrent_lnls"))),

    noncurrent_loans_derived = rowSums(
      cbind(
        as.numeric(pick_first_existing(., c("rcfd5525", "rcon5525"))), # common noncurrent / nonaccrual style item when available
        as.numeric(pick_first_existing(., c("rcfd5526", "rcon5526"))),
        as.numeric(pick_first_existing(., c("rcfd5527", "rcon5527")))
      ),
      na.rm = TRUE
    ),

    noncurrent_loans = dplyr::if_else(
      !is.na(noncurrent_loans_preagg),
      noncurrent_loans_preagg,
      dplyr::if_else(noncurrent_loans_derived > 0, noncurrent_loans_derived, NA_real_)
    ),

    # Net charge-offs:
    # Prefer a pre-aggregated field if present, else derive from charge-offs minus recoveries.
    net_charge_offs_preagg = as.numeric(pick_first_existing(., c("net_charge_offs", "nco", "net_loan_lease_chargeoffs"))),

    charge_offs_total = rowSums(
      cbind(
        as.numeric(pick_first_existing(., c("riad4635", "rcfd4635", "rcon4635"))),
        as.numeric(pick_first_existing(., c("riad4605", "rcfd4605", "rcon4605")))
      ),
      na.rm = TRUE
    ),

    recoveries_total = rowSums(
      cbind(
        as.numeric(pick_first_existing(., c("riad4605", "rcfd4605", "rcon4605"))),
        as.numeric(pick_first_existing(., c("riad2419", "rcfd2419", "rcon2419")))
      ),
      na.rm = TRUE
    ),

    net_charge_offs = dplyr::if_else(
      !is.na(net_charge_offs_preagg),
      net_charge_offs_preagg,
      dplyr::if_else((charge_offs_total != 0 | recoveries_total != 0), charge_offs_total - recoveries_total, NA_real_)
    )
  ) %>%
  select(
    bank_id, bank_name, quarter_end_date,
    total_assets, total_loans, allowance_for_credit_losses,
    noncurrent_loans, net_charge_offs, deposits,
    tier1_capital, risk_weighted_assets,
    total_equity_capital, net_income
  ) %>%
  distinct()

save_rds_safely(bank_panel_clean, file.path(dir_panel, "bank_panel_clean.rds"))
save_csv_safely(bank_panel_clean, file.path(dir_panel, "bank_panel_clean.csv"))
