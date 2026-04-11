# =========================================================
# 07_eda.R
# Purpose: Exploratory Data Analysis (EDA) for the
# single-quarter credit risk project.
#
# This script helps you:
# - understand the structure of the dataset
# - check missing values
# - inspect the target distribution
# - summarize important variables
# - generate beginner-friendly charts
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

# ---------------------------------------------------------
# 1. Load feature panel
# ---------------------------------------------------------

feature_panel <- readRDS(file.path(dir_features, "feature_panel.rds"))

cat("\nRows:", nrow(feature_panel), "\n")
cat("Columns:", ncol(feature_panel), "\n")

cat("\nColumn names:\n")
print(names(feature_panel))

cat("\nGlimpse of feature_panel:\n")
print(glimpse(feature_panel))

# ---------------------------------------------------------
# 2. Missing value summary
# ---------------------------------------------------------

missing_summary <- feature_panel %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(
    cols = everything(),
    names_to = "column_name",
    values_to = "missing_count"
  ) %>%
  arrange(desc(missing_count))

cat("\nMissing value summary:\n")
print(missing_summary)

save_csv_safely(
  missing_summary,
  file.path(dir_tables, "eda_missing_summary.csv")
)

# ---------------------------------------------------------
# 3. Target distribution
# ---------------------------------------------------------

target_col <- NULL

if ("high_risk" %in% names(feature_panel)) {
  target_col <- "high_risk"
} else if ("high_risk_next_q" %in% names(feature_panel)) {
  target_col <- "high_risk_next_q"
}

if (!is.null(target_col)) {
  target_distribution <- feature_panel %>%
    count(.data[[target_col]]) %>%
    mutate(pct = n / sum(n))
  
  cat("\nTarget distribution:\n")
  print(target_distribution)
  
  save_csv_safely(
    target_distribution,
    file.path(dir_tables, "eda_target_distribution.csv")
  )
  
  p_target <- ggplot(feature_panel, aes(x = factor(.data[[target_col]]))) +
    geom_bar() +
    labs(
      title = "Target Distribution",
      x = "Target Class",
      y = "Count"
    )
  
  ggsave(
    filename = file.path(dir_figures, "eda_target_distribution.png"),
    plot = p_target,
    width = 6,
    height = 4
  )
  
  print(p_target)
}

# ---------------------------------------------------------
# 4. Summary statistics for important numeric features
# ---------------------------------------------------------

numeric_features <- c(
  "reserve_coverage_ratio",
  "npa_ratio",
  "nco_ratio",
  "capital_ratio",
  "equity_to_assets",
  "roa",
  "loans_to_assets",
  "deposits_to_assets",
  "total_assets",
  "total_loans",
  "deposits",
  "net_income"
)

existing_numeric_features <- intersect(numeric_features, names(feature_panel))

if (length(existing_numeric_features) > 0) {
  summary_stats <- summary(feature_panel[, existing_numeric_features])
  
  cat("\nSummary statistics:\n")
  print(summary_stats)
}

# ---------------------------------------------------------
# 5. Histograms of key variables
# ---------------------------------------------------------

if ("npa_ratio" %in% names(feature_panel)) {
  p_npa_hist <- ggplot(feature_panel, aes(x = npa_ratio)) +
    geom_histogram(bins = 40) +
    labs(
      title = "Distribution of Noncurrent Loan Ratio",
      x = "NPA Ratio",
      y = "Count"
    )
  
  ggsave(
    filename = file.path(dir_figures, "eda_npa_ratio_histogram.png"),
    plot = p_npa_hist,
    width = 7,
    height = 5
  )
  
  print(p_npa_hist)
}

if ("roa" %in% names(feature_panel)) {
  p_roa_hist <- ggplot(feature_panel, aes(x = roa)) +
    geom_histogram(bins = 40) +
    labs(
      title = "Distribution of Return on Assets",
      x = "ROA",
      y = "Count"
    )
  
  ggsave(
    filename = file.path(dir_figures, "eda_roa_histogram.png"),
    plot = p_roa_hist,
    width = 7,
    height = 5
  )
  
  print(p_roa_hist)
}

if ("capital_ratio" %in% names(feature_panel)) {
  p_capital_hist <- ggplot(feature_panel, aes(x = capital_ratio)) +
    geom_histogram(bins = 40) +
    labs(
      title = "Distribution of Capital Ratio",
      x = "Capital Ratio",
      y = "Count"
    )
  
  ggsave(
    filename = file.path(dir_figures, "eda_capital_ratio_histogram.png"),
    plot = p_capital_hist,
    width = 7,
    height = 5
  )
  
  print(p_capital_hist)
}

# ---------------------------------------------------------
# 6. Relationship charts vs target
# ---------------------------------------------------------

if (!is.null(target_col) && "roa" %in% names(feature_panel)) {
  p_roa_target <- ggplot(
    feature_panel,
    aes(x = factor(.data[[target_col]]), y = roa)
  ) +
    geom_boxplot() +
    labs(
      title = "ROA by Risk Class",
      x = "Risk Class",
      y = "ROA"
    )
  
  ggsave(
    filename = file.path(dir_figures, "eda_roa_by_target.png"),
    plot = p_roa_target,
    width = 7,
    height = 5
  )
  
  print(p_roa_target)
}

if (!is.null(target_col) && "npa_ratio" %in% names(feature_panel)) {
  p_npa_target <- ggplot(
    feature_panel,
    aes(x = factor(.data[[target_col]]), y = npa_ratio)
  ) +
    geom_boxplot() +
    labs(
      title = "Noncurrent Loan Ratio by Risk Class",
      x = "Risk Class",
      y = "NPA Ratio"
    )
  
  ggsave(
    filename = file.path(dir_figures, "eda_npa_ratio_by_target.png"),
    plot = p_npa_target,
    width = 7,
    height = 5
  )
  
  print(p_npa_target)
}

# ---------------------------------------------------------
# 7. Top banks by assets
# ---------------------------------------------------------

if ("bank_name" %in% names(feature_panel) && "total_assets" %in% names(feature_panel)) {
  top_assets <- feature_panel %>%
    arrange(desc(total_assets)) %>%
    slice_head(n = 20) %>%
    mutate(bank_name_short = stringr::str_trunc(bank_name, width = 35))
  
  p_top_assets <- ggplot(
    top_assets,
    aes(x = reorder(bank_name_short, total_assets), y = total_assets)
  ) +
    geom_col() +
    coord_flip() +
    labs(
      title = "Top 20 Banks by Total Assets",
      x = "Bank",
      y = "Total Assets"
    )
  
  ggsave(
    filename = file.path(dir_figures, "eda_top_20_assets.png"),
    plot = p_top_assets,
    width = 9,
    height = 7
  )
  
  print(p_top_assets)
}

message("\nEDA complete.\n")
