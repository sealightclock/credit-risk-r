# =========================================================
# 10_model_xgboost.R
# Purpose: Train and evaluate an XGBoost model
# for the single-quarter version of the credit risk project.
#
# IMPORTANT:
# - This version is for a dataset with only one quarter.
# - So we use a random train/test split.
# - We exclude nco_ratio to avoid target leakage because
#   high_risk was derived from net_charge_offs.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

# ---------------------------------------------------------
# 1. Load packages needed specifically for this script
# ---------------------------------------------------------

if (!requireNamespace("xgboost", quietly = TRUE)) {
  stop("Package 'xgboost' is not installed. Run install.packages('xgboost') first.")
}

library(xgboost)

# ---------------------------------------------------------
# 2. Load feature dataset
# ---------------------------------------------------------

df <- readRDS(file.path(dir_features, "feature_panel.rds"))

if (!"high_risk" %in% names(df)) {
  stop("Column 'high_risk' not found. Please run the single-quarter version of R/05_build_target.R first.")
}

# ---------------------------------------------------------
# 3. Select modeling columns
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
# 4. Random train/test split
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
# 5. Convert to XGBoost matrices
# ---------------------------------------------------------
#
# XGBoost needs numeric matrix inputs.
# The target column is removed from the feature matrix.
# ---------------------------------------------------------

train_x <- as.matrix(train_df %>% select(-high_risk))
test_x  <- as.matrix(test_df %>% select(-high_risk))

train_y <- train_df$high_risk
test_y  <- test_df$high_risk

dtrain <- xgboost::xgb.DMatrix(data = train_x, label = train_y)
dtest  <- xgboost::xgb.DMatrix(data = test_x, label = test_y)

# ---------------------------------------------------------
# 6. Train XGBoost model
# ---------------------------------------------------------
#
# These settings are intentionally simple and conservative
# for a beginner-friendly first version.
# ---------------------------------------------------------

params <- list(
  objective = "binary:logistic",
  eval_metric = "auc",
  max_depth = 3,
  eta = 0.05,
  subsample = 0.8,
  colsample_bytree = 0.8
)

xgb_model <- xgboost::xgb.train(
  params = params,
  data = dtrain,
  nrounds = 150,
  watchlist = list(train = dtrain, test = dtest),
  verbose = 0
)

print(xgb_model)

# ---------------------------------------------------------
# 7. Predict on test set
# ---------------------------------------------------------

test_df$pred_prob <- predict(xgb_model, newdata = dtest)
test_df$pred_class <- ifelse(test_df$pred_prob >= 0.50, 1, 0)

# ---------------------------------------------------------
# 8. Evaluate model
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

test_eval_df <- test_df %>%
  mutate(
    high_risk = factor(high_risk, levels = c(0, 1)),
    pred_class = factor(pred_class, levels = c(0, 1))
  )

auc_value <- yardstick::roc_auc(
  test_eval_df,
  truth = high_risk,
  pred_prob
)

cat("\nAUC:\n")
print(auc_value)

accuracy_tbl <- yardstick::accuracy(
  test_eval_df,
  truth = high_risk,
  estimate = pred_class
)

cat("\nAccuracy table:\n")
print(accuracy_tbl)

# ---------------------------------------------------------
# 9. Save model and predictions
# ---------------------------------------------------------

saveRDS(
  xgb_model,
  file.path("models", "xgboost_model.rds")
)

save_csv_safely(
  test_df,
  file.path(dir_metrics, "xgboost_predictions.csv")
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
  file.path(dir_metrics, "xgboost_metrics.csv")
)

# ---------------------------------------------------------
# 10. ROC curve
# ---------------------------------------------------------

roc_df <- yardstick::roc_curve(
  test_eval_df,
  truth = high_risk,
  pred_prob
)

p_roc <- ggplot(roc_df, aes(x = 1 - specificity, y = sensitivity)) +
  geom_line() +
  geom_abline(linetype = "dashed") +
  labs(
    title = "ROC Curve - XGBoost",
    x = "False Positive Rate",
    y = "True Positive Rate"
  )

ggsave(
  filename = file.path(dir_figures, "roc_curve_xgboost.png"),
  plot = p_roc,
  width = 6,
  height = 5
)

print(p_roc)

# ---------------------------------------------------------
# 11. Feature importance
# ---------------------------------------------------------

importance_df <- xgboost::xgb.importance(
  feature_names = colnames(train_x),
  model = xgb_model
) %>%
  as_tibble()

save_csv_safely(
  importance_df,
  file.path(dir_tables, "xgboost_variable_importance.csv")
)

p_importance <- ggplot(
  importance_df,
  aes(x = reorder(Feature, Gain), y = Gain)
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "XGBoost Variable Importance",
    x = "Feature",
    y = "Gain"
  )

ggsave(
  filename = file.path(dir_figures, "xgboost_variable_importance.png"),
  plot = p_importance,
  width = 7,
  height = 5
)

print(p_importance)

# ---------------------------------------------------------
# 12. Inspect top predicted high-risk rows
# ---------------------------------------------------------

top_predictions <- test_df %>%
  arrange(desc(pred_prob)) %>%
  slice_head(n = 20)

cat("\nTop predicted high-risk rows from test set:\n")
print(top_predictions)

message("\nSingle-quarter XGBoost complete.\n")
