# =========================================================
# 13_make_charts.R
# Purpose: Create presentation-ready charts for the
# single-quarter credit risk project.
#
# This script creates:
# 1. Top 20 risky banks bar chart
# 2. Risk bucket distribution chart
# 3. ROA vs predicted risk scatter plot
# 4. NPA ratio vs predicted risk scatter plot
# 5. Assets vs predicted risk scatter plot
#
# Input:
# - outputs/watchlists/watchlist.csv
#
# Output:
# - PNG files saved to outputs/figures/
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

# ---------------------------------------------------------
# 1. Load watchlist
# ---------------------------------------------------------

watchlist_path <- file.path(dir_watchlists, "watchlist.csv")

if (!file.exists(watchlist_path)) {
  stop("watchlist.csv not found. Please run R/12_score_watchlist.R first.")
}

watchlist <- readr::read_csv(watchlist_path, show_col_types = FALSE)

cat("\nRows in watchlist:", nrow(watchlist), "\n")
cat("Columns in watchlist:\n")
print(names(watchlist))

# ---------------------------------------------------------
# 2. Basic cleanup
# ---------------------------------------------------------

watchlist <- watchlist %>%
  mutate(
    bank_name = as.character(bank_name),
    risk_bucket = factor(risk_bucket, levels = c("Low", "Medium", "High"))
  )

# ---------------------------------------------------------
# 3. Top 20 risky banks bar chart
# ---------------------------------------------------------

top20 <- watchlist %>%
  slice_head(n = 20) %>%
  mutate(
    bank_name_short = stringr::str_trunc(bank_name, width = 35)
  )

p_top20 <- ggplot(
  top20,
  aes(
    x = reorder(bank_name_short, pred_prob),
    y = pred_prob
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Top 20 Banks by Predicted Credit Risk",
    x = "Bank",
    y = "Predicted Risk Probability"
  )

ggsave(
  filename = file.path(dir_figures, "top_20_risky_banks.png"),
  plot = p_top20,
  width = 10,
  height = 7
)

print(p_top20)

# ---------------------------------------------------------
# 4. Risk bucket distribution
# ---------------------------------------------------------

bucket_summary <- watchlist %>%
  count(risk_bucket) %>%
  mutate(
    pct = n / sum(n)
  )

save_csv_safely(
  bucket_summary,
  file.path(dir_tables, "risk_bucket_distribution.csv")
)

p_bucket <- ggplot(bucket_summary, aes(x = risk_bucket, y = n)) +
  geom_col() +
  labs(
    title = "Distribution of Risk Buckets",
    x = "Risk Bucket",
    y = "Number of Banks"
  )

ggsave(
  filename = file.path(dir_figures, "risk_bucket_distribution.png"),
  plot = p_bucket,
  width = 7,
  height = 5
)

print(p_bucket)

# ---------------------------------------------------------
# 5. ROA vs predicted risk
# ---------------------------------------------------------

if ("roa" %in% names(watchlist)) {
  p_roa <- ggplot(
    watchlist,
    aes(x = roa, y = pred_prob)
  ) +
    geom_point(alpha = 0.6) +
    labs(
      title = "ROA vs Predicted Credit Risk",
      x = "Return on Assets (ROA)",
      y = "Predicted Risk Probability"
    )
  
  ggsave(
    filename = file.path(dir_figures, "roa_vs_predicted_risk.png"),
    plot = p_roa,
    width = 7,
    height = 5
  )
  
  print(p_roa)
}

# ---------------------------------------------------------
# 6. NPA ratio vs predicted risk
# ---------------------------------------------------------

if ("npa_ratio" %in% names(watchlist)) {
  p_npa <- ggplot(
    watchlist,
    aes(x = npa_ratio, y = pred_prob)
  ) +
    geom_point(alpha = 0.6) +
    labs(
      title = "Noncurrent Loan Ratio vs Predicted Credit Risk",
      x = "Noncurrent Loan Ratio",
      y = "Predicted Risk Probability"
    )
  
  ggsave(
    filename = file.path(dir_figures, "npa_ratio_vs_predicted_risk.png"),
    plot = p_npa,
    width = 7,
    height = 5
  )
  
  print(p_npa)
}

# ---------------------------------------------------------
# 7. Total assets vs predicted risk
# ---------------------------------------------------------

if ("total_assets" %in% names(watchlist)) {
  p_assets <- ggplot(
    watchlist,
    aes(x = total_assets, y = pred_prob)
  ) +
    geom_point(alpha = 0.6) +
    scale_x_log10() +
    labs(
      title = "Total Assets vs Predicted Credit Risk",
      x = "Total Assets (log scale)",
      y = "Predicted Risk Probability"
    )
  
  ggsave(
    filename = file.path(dir_figures, "assets_vs_predicted_risk.png"),
    plot = p_assets,
    width = 7,
    height = 5
  )
  
  print(p_assets)
}

# ---------------------------------------------------------
# 8. Capital ratio vs predicted risk
# ---------------------------------------------------------

if ("capital_ratio" %in% names(watchlist)) {
  p_capital <- ggplot(
    watchlist,
    aes(x = capital_ratio, y = pred_prob)
  ) +
    geom_point(alpha = 0.6) +
    labs(
      title = "Capital Ratio vs Predicted Credit Risk",
      x = "Capital Ratio",
      y = "Predicted Risk Probability"
    )
  
  ggsave(
    filename = file.path(dir_figures, "capital_ratio_vs_predicted_risk.png"),
    plot = p_capital,
    width = 7,
    height = 5
  )
  
  print(p_capital)
}

# ---------------------------------------------------------
# 9. Summary table for recruiter-friendly reporting
# ---------------------------------------------------------

summary_tbl <- tibble(
  metric = c(
    "number_of_banks_scored",
    "average_predicted_risk",
    "median_predicted_risk",
    "max_predicted_risk",
    "min_predicted_risk"
  ),
  value = c(
    nrow(watchlist),
    mean(watchlist$pred_prob, na.rm = TRUE),
    median(watchlist$pred_prob, na.rm = TRUE),
    max(watchlist$pred_prob, na.rm = TRUE),
    min(watchlist$pred_prob, na.rm = TRUE)
  )
)

save_csv_safely(
  summary_tbl,
  file.path(dir_tables, "watchlist_summary_metrics.csv")
)

cat("\nSummary metrics:\n")
print(summary_tbl)

message("\nChart generation complete.\n")