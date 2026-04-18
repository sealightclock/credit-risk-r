# =========================================================
# 07_eda.R
# Purpose:
#   Perform exploratory data analysis (EDA).
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

feature_panel <- readRDS(file.path(dir_features, "feature_panel.rds"))

message("Rows: ", nrow(feature_panel))
message("Columns: ", ncol(feature_panel))

message("\nColumn names:")
print(names(feature_panel))

message("\nGlimpse:")
print(dplyr::glimpse(feature_panel))

missing_summary <- feature_panel %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(
    cols = everything(),
    names_to = "column_name",
    values_to = "missing_count"
  ) %>%
  arrange(desc(missing_count))

save_csv_safely(missing_summary, file.path(dir_tables, "eda_missing_summary.csv"))

target_distribution <- feature_panel %>%
  count(high_risk) %>%
  mutate(pct = n / sum(n))

save_csv_safely(target_distribution, file.path(dir_tables, "eda_target_distribution.csv"))

p_target <- ggplot(feature_panel, aes(x = factor(high_risk))) +
  geom_bar() +
  labs(title = "Target Distribution", x = "Risk Class", y = "Count")

ggsave(file.path(dir_figures, "eda_target_distribution.png"), p_target, width = 6, height = 4)

p_npa_hist <- ggplot(feature_panel, aes(x = npa_ratio)) +
  geom_histogram(bins = 40) +
  labs(title = "Distribution of Noncurrent Loan Ratio", x = "NPA Ratio", y = "Count")

ggsave(file.path(dir_figures, "eda_npa_ratio_histogram.png"), p_npa_hist, width = 7, height = 5)

p_roa_hist <- ggplot(feature_panel, aes(x = roa)) +
  geom_histogram(bins = 40) +
  labs(title = "Distribution of Return on Assets", x = "ROA", y = "Count")

ggsave(file.path(dir_figures, "eda_roa_histogram.png"), p_roa_hist, width = 7, height = 5)

p_roa_target <- ggplot(feature_panel, aes(x = factor(high_risk), y = roa)) +
  geom_boxplot() +
  labs(title = "ROA by Risk Class", x = "Risk Class", y = "ROA")

ggsave(file.path(dir_figures, "eda_roa_by_target.png"), p_roa_target, width = 7, height = 5)

p_npa_target <- ggplot(feature_panel, aes(x = factor(high_risk), y = npa_ratio)) +
  geom_boxplot() +
  labs(title = "Noncurrent Loan Ratio by Risk Class", x = "Risk Class", y = "NPA Ratio")

ggsave(file.path(dir_figures, "eda_npa_ratio_by_target.png"), p_npa_target, width = 7, height = 5)

message("\nEDA complete.")
