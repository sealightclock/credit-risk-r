# =========================================================
# 05_build_target.R (Single-quarter version)
# Purpose: Create risk label using current data
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

df <- readRDS(file.path(dir_panel, "bank_panel_clean.rds"))

# Since net_charge_offs is already a ratio,
# define high risk as top 25%

threshold <- quantile(df$net_charge_offs, 0.75, na.rm = TRUE)

df <- df %>%
  mutate(
    high_risk = if_else(net_charge_offs > threshold, 1, 0)
  )

save_rds_safely(df, file.path(dir_modeling, "model_base.rds"))

df %>% count(high_risk)