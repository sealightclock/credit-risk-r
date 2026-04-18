# =========================================================
# 09_model_tree.R
# Purpose:
#   Train and evaluate a random forest model.
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
  mutate(high_risk = factor(high_risk, levels = c(0, 1))) %>%
  drop_na()

set.seed(project_seed)
train_index <- sample(seq_len(nrow(model_df)), size = floor(0.70 * nrow(model_df)))
train_df <- model_df[train_index, ]
test_df  <- model_df[-train_index, ]

rf_model <- ranger::ranger(
  formula = high_risk ~ .,
  data = train_df,
  probability = TRUE,
  num.trees = 300,
  importance = "impurity",
  seed = project_seed
)

rf_pred <- predict(rf_model, data = test_df)
test_df$pred_prob <- rf_pred$predictions[, "1"]
test_df$pred_class <- factor(ifelse(test_df$pred_prob >= 0.50, "1", "0"), levels = c("0", "1"))

accuracy_value <- mean(test_df$pred_class == test_df$high_risk)
conf_matrix <- table(Predicted = test_df$pred_class, Actual = test_df$high_risk)
auc_value <- yardstick::roc_auc(test_df, truth = high_risk, pred_prob)
accuracy_tbl <- yardstick::accuracy(test_df, truth = high_risk, estimate = pred_class)

message("\nConfusion matrix:")
print(conf_matrix)

message("\nAUC:")
print(auc_value)

saveRDS(rf_model, file.path(dir_models_rf, "random_forest_model.rds"))
save_csv_safely(test_df, file.path(dir_metrics, "random_forest_predictions.csv"))

metrics_df <- tibble(
  metric = c("accuracy", "auc"),
  value = c(accuracy_value, auc_value$.estimate[1])
)

save_csv_safely(metrics_df, file.path(dir_metrics, "random_forest_metrics.csv"))

roc_df <- yardstick::roc_curve(test_df, truth = high_risk, pred_prob)

p_roc <- ggplot(roc_df, aes(x = 1 - specificity, y = sensitivity)) +
  geom_line() +
  geom_abline(linetype = "dashed") +
  labs(
    title = "ROC Curve - Random Forest",
    x = "False Positive Rate",
    y = "True Positive Rate"
  )

ggsave(file.path(dir_figures, "roc_curve_random_forest.png"), p_roc, width = 6, height = 5)

importance_df <- tibble(
  feature = names(rf_model$variable.importance),
  importance = as.numeric(rf_model$variable.importance)
) %>%
  arrange(desc(importance))

save_csv_safely(importance_df, file.path(dir_tables, "random_forest_variable_importance.csv"))

p_importance <- ggplot(importance_df, aes(x = reorder(feature, importance), y = importance)) +
  geom_col() +
  coord_flip() +
  labs(title = "Random Forest Variable Importance", x = "Feature", y = "Importance")

ggsave(file.path(dir_figures, "random_forest_variable_importance.png"), p_importance, width = 7, height = 5)

message("\nSingle-quarter random forest complete.")
