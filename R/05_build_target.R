# =========================================================
# 05_build_target.R
# Purpose:
#   Create the target variable for the single-quarter project.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

df <- readRDS(file.path(dir_panel, "bank_panel_clean.rds"))

threshold <- quantile(df$net_charge_offs, 0.75, na.rm = TRUE)

df <- df %>%
  mutate(
    high_risk = if_else(net_charge_offs > threshold, 1, 0)
  )

save_rds_safely(df, file.path(dir_modeling, "model_base.rds"))

target_summary <- df %>%
  count(high_risk) %>%
  mutate(pct = n / sum(n))

save_csv_safely(target_summary, file.path(dir_tables, "target_summary.csv"))

message("\nTarget summary:")
print(target_summary)
