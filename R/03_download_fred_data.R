source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

fred_symbols <- c("CORALACBN")

quantmod::getSymbols(Symbols = fred_symbols, src = "FRED", auto.assign = TRUE)

fred_df <- tibble(
  date = zoo::index(CORALACBN),
  coralacbn = as.numeric(CORALACBN[, 1])
) %>%
  mutate(quarter_end_date = ceiling_date(as.Date(date), unit = "quarter") - days(1)) %>%
  group_by(quarter_end_date) %>%
  summarise(coralacbn = mean(coralacbn, na.rm = TRUE), .groups = "drop")

save_csv_safely(fred_df, file.path(dir_raw_fred, "fred_macro_data.csv"))
save_rds_safely(fred_df, file.path(dir_raw_fred, "fred_macro_data.rds"))
