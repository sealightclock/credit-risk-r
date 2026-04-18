# =========================================================
# 11_backtest.R
# Purpose:
#   Perform repeated holdout validation.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

df <- readRDS(file.path(dir_features, "feature_panel.rds"))

if (!"high_risk" %in% names(df)) {
  stop("Column 'high_risk' not found. Run R/05_build_target.R first.")
}

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
  mutate(high_risk = as.integer(high_risk)) %>%
  drop_na()

n_iterations <- 30
train_fraction <- 0.70

calculate_metrics <- function(actual, pred_prob, threshold = 0.50) {
  pred_class <- ifelse(pred_prob >= threshold, 1, 0)

  eval_df <- tibble(
    actual = factor(actual, levels = c(0, 1)),
    pred_prob = pred_prob,
    pred_class = factor(pred_class, levels = c(0, 1))
  )

  accuracy_value <- mean(pred_class == actual)
  auc_tbl <- yardstick::roc_auc(eval_df, truth = actual, pred_prob)
  precision_tbl <- yardstick::precision(eval_df, truth = actual, estimate = pred_class)
  recall_tbl <- yardstick::recall(eval_df, truth = actual, estimate = pred_class)
  f1_tbl <- yardstick::f_meas(eval_df, truth = actual, estimate = pred_class)

  tibble(
    accuracy = accuracy_value,
    auc = auc_tbl$.estimate[1],
    precision = precision_tbl$.estimate[1],
    recall = recall_tbl$.estimate[1],
    f1 = f1_tbl$.estimate[1]
  )
}

logistic_results <- vector("list", n_iterations)
set.seed(project_seed)

for (i in seq_len(n_iterations)) {
  sample_index <- sample(seq_len(nrow(model_df)), size = floor(train_fraction * nrow(model_df)))
  train_df <- model_df[sample_index, ]
  test_df  <- model_df[-sample_index, ]

  if (length(unique(train_df$high_risk)) < 2 || length(unique(test_df$high_risk)) < 2) {
    logistic_results[[i]] <- tibble(
      iteration = i, accuracy = NA_real_, auc = NA_real_,
      precision = NA_real_, recall = NA_real_, f1 = NA_real_,
      model = "Logistic Regression"
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

  pred_prob <- predict(model, newdata = test_df, type = "response")

  logistic_results[[i]] <- calculate_metrics(test_df$high_risk, pred_prob) %>%
    mutate(iteration = i, model = "Logistic Regression")
}

rf_results <- vector("list", n_iterations)
set.seed(project_seed)

for (i in seq_len(n_iterations)) {
  sample_index <- sample(seq_len(nrow(model_df)), size = floor(train_fraction * nrow(model_df)))
  train_df <- model_df[sample_index, ] %>%
    mutate(high_risk = factor(high_risk, levels = c(0, 1)))
  test_df <- model_df[-sample_index, ] %>%
    mutate(high_risk = factor(high_risk, levels = c(0, 1)))

  if (length(unique(train_df$high_risk)) < 2 || length(unique(test_df$high_risk)) < 2) {
    rf_results[[i]] <- tibble(
      iteration = i, accuracy = NA_real_, auc = NA_real_,
      precision = NA_real_, recall = NA_real_, f1 = NA_real_,
      model = "Random Forest"
    )
    next
  }

  rf_model <- ranger::ranger(
    formula = high_risk ~ .,
    data = train_df,
    probability = TRUE,
    num.trees = 300,
    seed = project_seed + i
  )

  pred_prob <- predict(rf_model, data = test_df)$predictions[, "1"]

  rf_results[[i]] <- calculate_metrics(
    actual = as.integer(as.character(test_df$high_risk)),
    pred_prob = pred_prob
  ) %>%
    mutate(iteration = i, model = "Random Forest")
}

backtest_results <- bind_rows(bind_rows(logistic_results), bind_rows(rf_results)) %>%
  select(model, iteration, accuracy, auc, precision, recall, f1)

save_csv_safely(backtest_results, file.path(dir_metrics, "backtest_results.csv"))

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

save_csv_safely(backtest_summary, file.path(dir_metrics, "backtest_summary.csv"))

p_auc <- ggplot(backtest_results, aes(x = model, y = auc)) +
  geom_boxplot() +
  labs(title = "Repeated Holdout AUC by Model", x = "Model", y = "AUC")

ggsave(file.path(dir_figures, "backtest_auc_by_model.png"), p_auc, width = 7, height = 5)

p_accuracy <- ggplot(backtest_results, aes(x = model, y = accuracy)) +
  geom_boxplot() +
  labs(title = "Repeated Holdout Accuracy by Model", x = "Model", y = "Accuracy")

ggsave(file.path(dir_figures, "backtest_accuracy_by_model.png"), p_accuracy, width = 7, height = 5)

message("\nRepeated holdout validation complete.")
