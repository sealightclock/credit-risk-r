# =========================================================
# 11_backtest.R
# Purpose: Perform repeated holdout validation for the
# single-quarter version of the credit risk project.
#
# IMPORTANT:
# - This is NOT a true time-series backtest.
# - Because the project currently has only one quarter of data,
#   we use repeated random train/test splits instead.
# - This gives a more stable view of model performance than
#   relying on one single split.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

# ---------------------------------------------------------
# 1. Load feature dataset
# ---------------------------------------------------------

df <- readRDS(file.path(dir_features, "feature_panel.rds"))

if (!"high_risk" %in% names(df)) {
  stop("Column 'high_risk' not found. Please run the single-quarter version of R/05_build_target.R first.")
}

# ---------------------------------------------------------
# 2. Prepare modeling dataset
# ---------------------------------------------------------
#
# IMPORTANT:
# We exclude nco_ratio to avoid target leakage because
# high_risk was defined from net_charge_offs.
# ---------------------------------------------------------

model_df <- df %>%
  select(
    high_risk,
    reserve_coverage_ratio,
    npa_ratio,
    capital_ratio,
    equity_to_assets,
    roa,
    loans_to_assets,
    deposits_to_assets
  ) %>%
  mutate(
    high_risk = as.integer(high_risk)
  ) %>%
  drop_na()

cat("\nRows available for backtest:", nrow(model_df), "\n")

if (nrow(model_df) == 0) {
  stop("No rows available after drop_na(). Check missing values in feature_panel.rds.")
}

if (length(unique(model_df$high_risk)) < 2) {
  stop("The target column 'high_risk' has only one class. Backtesting cannot proceed.")
}

cat("\nClass distribution:\n")
print(model_df %>% count(high_risk))

# ---------------------------------------------------------
# 3. Set repeated holdout parameters
# ---------------------------------------------------------

n_iterations <- 30
train_fraction <- 0.70

# ---------------------------------------------------------
# 4. Helper function to calculate metrics
# ---------------------------------------------------------

calculate_metrics <- function(actual, pred_prob, threshold = 0.50) {
  pred_class <- ifelse(pred_prob >= threshold, 1, 0)
  
  eval_df <- tibble(
    actual = factor(actual, levels = c(0, 1)),
    pred_prob = pred_prob,
    pred_class = factor(pred_class, levels = c(0, 1))
  )
  
  accuracy_value <- mean(pred_class == actual)
  
  auc_tbl <- yardstick::roc_auc(
    eval_df,
    truth = actual,
    pred_prob
  )
  
  precision_tbl <- yardstick::precision(
    eval_df,
    truth = actual,
    estimate = pred_class
  )
  
  recall_tbl <- yardstick::recall(
    eval_df,
    truth = actual,
    estimate = pred_class
  )
  
  f1_tbl <- yardstick::f_meas(
    eval_df,
    truth = actual,
    estimate = pred_class
  )
  
  tibble(
    accuracy = accuracy_value,
    auc = auc_tbl$.estimate[1],
    precision = precision_tbl$.estimate[1],
    recall = recall_tbl$.estimate[1],
    f1 = f1_tbl$.estimate[1]
  )
}

# ---------------------------------------------------------
# 5. Repeated holdout validation - Logistic Regression
# ---------------------------------------------------------

logistic_results <- vector("list", n_iterations)

set.seed(project_seed)

for (i in seq_len(n_iterations)) {
  sample_index <- sample(
    seq_len(nrow(model_df)),
    size = floor(train_fraction * nrow(model_df))
  )
  
  train_df <- model_df[sample_index, ]
  test_df  <- model_df[-sample_index, ]
  
  # Skip bad splits where one class disappears
  if (length(unique(train_df$high_risk)) < 2 || length(unique(test_df$high_risk)) < 2) {
    logistic_results[[i]] <- tibble(
      iteration = i,
      accuracy = NA_real_,
      auc = NA_real_,
      precision = NA_real_,
      recall = NA_real_,
      f1 = NA_real_
    )
    next
  }
  
  model <- glm(
    high_risk ~ reserve_coverage_ratio +
      npa_ratio +
      capital_ratio +
      equity_to_assets +
      roa +
      loans_to_assets +
      deposits_to_assets,
    data = train_df,
    family = binomial()
  )
  
  pred_prob <- predict(
    model,
    newdata = test_df,
    type = "response"
  )
  
  metrics_tbl <- calculate_metrics(
    actual = test_df$high_risk,
    pred_prob = pred_prob
  ) %>%
    mutate(iteration = i, model = "Logistic Regression")
  
  logistic_results[[i]] <- metrics_tbl
}

logistic_backtest <- bind_rows(logistic_results)

# ---------------------------------------------------------
# 6. Repeated holdout validation - Random Forest
# ---------------------------------------------------------

rf_results <- vector("list", n_iterations)

set.seed(project_seed)

for (i in seq_len(n_iterations)) {
  sample_index <- sample(
    seq_len(nrow(model_df)),
    size = floor(train_fraction * nrow(model_df))
  )
  
  train_df <- model_df[sample_index, ] %>%
    mutate(high_risk = factor(high_risk, levels = c(0, 1)))
  
  test_df <- model_df[-sample_index, ] %>%
    mutate(high_risk = factor(high_risk, levels = c(0, 1)))
  
  if (length(unique(train_df$high_risk)) < 2 || length(unique(test_df$high_risk)) < 2) {
    rf_results[[i]] <- tibble(
      iteration = i,
      accuracy = NA_real_,
      auc = NA_real_,
      precision = NA_real_,
      recall = NA_real_,
      f1 = NA_real_
    )
    next
  }
  
  rf_model <- ranger::ranger(
    formula = high_risk ~ .,
    data = train_df,
    probability = TRUE,
    num.trees = 300,
    importance = "impurity",
    seed = project_seed + i
  )
  
  rf_pred <- predict(rf_model, data = test_df)
  pred_prob <- rf_pred$predictions[, "1"]
  
  metrics_tbl <- calculate_metrics(
    actual = as.integer(as.character(test_df$high_risk)),
    pred_prob = pred_prob
  ) %>%
    mutate(iteration = i, model = "Random Forest")
  
  rf_results[[i]] <- metrics_tbl
}

rf_backtest <- bind_rows(rf_results)

# ---------------------------------------------------------
# 7. Combine results
# ---------------------------------------------------------

backtest_results <- bind_rows(
  logistic_backtest,
  rf_backtest
) %>%
  select(model, iteration, accuracy, auc, precision, recall, f1)

save_csv_safely(
  backtest_results,
  file.path(dir_metrics, "backtest_results.csv")
)

cat("\nBacktest results preview:\n")
print(head(backtest_results, 10))

# ---------------------------------------------------------
# 8. Summary table
# ---------------------------------------------------------

backtest_summary <- backtest_results %>%
  group_by(model) %>%
  summarise(
    n_valid_runs = sum(!is.na(auc)),
    mean_accuracy = mean(accuracy, na.rm = TRUE),
    sd_accuracy = sd(accuracy, na.rm = TRUE),
    mean_auc = mean(auc, na.rm = TRUE),
    sd_auc = sd(auc, na.rm = TRUE),
    mean_precision = mean(precision, na.rm = TRUE),
    mean_recall = mean(recall, na.rm = TRUE),
    mean_f1 = mean(f1, na.rm = TRUE),
    .groups = "drop"
  )

save_csv_safely(
  backtest_summary,
  file.path(dir_metrics, "backtest_summary.csv")
)

cat("\nBacktest summary:\n")
print(backtest_summary)

# ---------------------------------------------------------
# 9. Charts
# ---------------------------------------------------------

# AUC distribution by model
p_auc <- ggplot(
  backtest_results,
  aes(x = model, y = auc)
) +
  geom_boxplot() +
  labs(
    title = "Repeated Holdout AUC by Model",
    x = "Model",
    y = "AUC"
  )

ggsave(
  filename = file.path(dir_figures, "backtest_auc_by_model.png"),
  plot = p_auc,
  width = 7,
  height = 5
)

print(p_auc)

# Accuracy distribution by model
p_accuracy <- ggplot(
  backtest_results,
  aes(x = model, y = accuracy)
) +
  geom_boxplot() +
  labs(
    title = "Repeated Holdout Accuracy by Model",
    x = "Model",
    y = "Accuracy"
  )

ggsave(
  filename = file.path(dir_figures, "backtest_accuracy_by_model.png"),
  plot = p_accuracy,
  width = 7,
  height = 5
)

print(p_accuracy)

# Iteration-by-iteration AUC
p_auc_trend <- ggplot(
  backtest_results,
  aes(x = iteration, y = auc, group = model)
) +
  geom_line(aes(linetype = model)) +
  geom_point() +
  labs(
    title = "AUC Across Repeated Holdout Iterations",
    x = "Iteration",
    y = "AUC"
  )

ggsave(
  filename = file.path(dir_figures, "backtest_auc_trend.png"),
  plot = p_auc_trend,
  width = 8,
  height = 5
)

print(p_auc_trend)

message("\nRepeated holdout validation complete.\n")