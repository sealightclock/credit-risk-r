# =========================================================
# 09_model_tree.R
# Purpose: Train and evaluate a tree-based model
# for the single-quarter version of the credit risk project.
#
# Model used:
# - Random Forest via ranger
#
# IMPORTANT:
# - This version is for a dataset with only one quarter.
# - So we use a random train/test split, not a time-based split.
# - We use the same target as the logistic model: high_risk
# - We exclude nco_ratio to avoid target leakage, because
#   high_risk was defined from net_charge_offs.
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
# 2. Select modeling columns
# ---------------------------------------------------------
#
# IMPORTANT:
# We intentionally exclude nco_ratio because the target
# high_risk was derived from net_charge_offs.
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
    high_risk = factor(high_risk, levels = c(0, 1))
  ) %>%
  drop_na()

cat("\nRows available for modeling:", nrow(model_df), "\n")

if (nrow(model_df) == 0) {
  stop("No rows available after drop_na(). Check missing values in feature_panel.rds.")
}

cat("\nClass distribution:\n")
print(model_df %>% count(high_risk))

if (length(unique(model_df$high_risk)) < 2) {
  stop("The target column 'high_risk' has only one class. The model cannot be trained.")
}

# ---------------------------------------------------------
# 3. Random train/test split
# ---------------------------------------------------------

set.seed(project_seed)

train_index <- sample(seq_len(nrow(model_df)), size = floor(0.70 * nrow(model_df)))

train_df <- model_df[train_index, ]
test_df  <- model_df[-train_index, ]

cat("\nTrain rows:", nrow(train_df), "\n")
cat("Test rows:", nrow(test_df), "\n")

if (nrow(train_df) == 0 || nrow(test_df) == 0) {
  stop("Train or test set is empty. Check the split logic.")
}

# ---------------------------------------------------------
# 4. Train random forest model
# ---------------------------------------------------------
#
# Beginner-friendly settings:
# - trees = 300 gives a reasonably stable model
# - importance = "impurity" lets us inspect feature importance
# ---------------------------------------------------------

rf_model <- ranger::ranger(
  formula = high_risk ~ .,
  data = train_df,
  probability = TRUE,
  num.trees = 300,
  importance = "impurity",
  seed = project_seed
)

print(rf_model)

# ---------------------------------------------------------
# 5. Predict on test set
# ---------------------------------------------------------

rf_pred <- predict(rf_model, data = test_df)

# ranger returns one probability per class.
# We want the probability for class "1".
test_df$pred_prob <- rf_pred$predictions[, "1"]

test_df$pred_class <- ifelse(test_df$pred_prob >= 0.50, "1", "0")
test_df$pred_class <- factor(test_df$pred_class, levels = c("0", "1"))

# ---------------------------------------------------------
# 6. Evaluate model
# ---------------------------------------------------------

accuracy_value <- mean(test_df$pred_class == test_df$high_risk)

cat("\nAccuracy:\n")
print(accuracy_value)

conf_matrix <- table(
  Predicted = test_df$pred_class,
  Actual = test_df$high_risk
)

cat("\nConfusion matrix:\n")
print(conf_matrix)

auc_value <- yardstick::roc_auc(
  test_df,
  truth = high_risk,
  pred_prob
)

cat("\nAUC:\n")
print(auc_value)

accuracy_tbl <- yardstick::accuracy(
  test_df,
  truth = high_risk,
  estimate = pred_class
)

cat("\nAccuracy table:\n")
print(accuracy_tbl)

# ---------------------------------------------------------
# 7. Save model and predictions
# ---------------------------------------------------------

saveRDS(
  rf_model,
  file.path(dir_models_rf, "random_forest_model.rds")
)

save_csv_safely(
  test_df,
  file.path(dir_metrics, "random_forest_predictions.csv")
)

metrics_df <- tibble(
  metric = c("accuracy", "auc"),
  value = c(
    accuracy_value,
    auc_value$.estimate[1]
  )
)

save_csv_safely(
  metrics_df,
  file.path(dir_metrics, "random_forest_metrics.csv")
)

# ---------------------------------------------------------
# 8. ROC curve
# ---------------------------------------------------------

roc_df <- yardstick::roc_curve(
  test_df,
  truth = high_risk,
  pred_prob
)

p_roc <- ggplot(roc_df, aes(x = 1 - specificity, y = sensitivity)) +
  geom_line() +
  geom_abline(linetype = "dashed") +
  labs(
    title = "ROC Curve - Random Forest",
    x = "False Positive Rate",
    y = "True Positive Rate"
  )

ggsave(
  filename = file.path(dir_figures, "roc_curve_random_forest.png"),
  plot = p_roc,
  width = 6,
  height = 5
)

print(p_roc)

# ---------------------------------------------------------
# 9. Variable importance
# ---------------------------------------------------------

importance_df <- tibble(
  feature = names(rf_model$variable.importance),
  importance = as.numeric(rf_model$variable.importance)
) %>%
  arrange(desc(importance))

save_csv_safely(
  importance_df,
  file.path(dir_tables, "random_forest_variable_importance.csv")
)

p_importance <- ggplot(
  importance_df,
  aes(x = reorder(feature, importance), y = importance)
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Random Forest Variable Importance",
    x = "Feature",
    y = "Importance"
  )

ggsave(
  filename = file.path(dir_figures, "random_forest_variable_importance.png"),
  plot = p_importance,
  width = 7,
  height = 5
)

print(p_importance)

# ---------------------------------------------------------
# 10. Inspect top predicted high-risk rows
# ---------------------------------------------------------

top_predictions <- test_df %>%
  arrange(desc(pred_prob)) %>%
  slice_head(n = 20)

cat("\nTop predicted high-risk rows from test set:\n")
print(top_predictions)

message("\nSingle-quarter random forest complete.\n")