# =========================================================
# 03_download_fred_data.R
# Purpose:
#   Download optional macroeconomic data from FRED.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

quantmod::getSymbols(
  Symbols = c("CORALACBN"),
  src = "FRED",
  auto.assign = TRUE
)

fred_df <- tibble(
  date = zoo::index(CORALACBN),
  coralacbn = as.numeric(CORALACBN[, 1])
) %>%
  mutate(
    quarter_end_date = lubridate::ceiling_date(as.Date(date), unit = "quarter") - lubridate::days(1)
  ) %>%
  group_by(quarter_end_date) %>%
  summarise(
    coralacbn = mean(coralacbn, na.rm = TRUE),
    .groups = "drop"
  )

save_csv_safely(fred_df, file.path(dir_raw_fred, "fred_macro_data.csv"))
save_rds_safely(fred_df, file.path(dir_raw_fred, "fred_macro_data.rds"))
