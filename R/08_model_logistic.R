# =========================================================
# 08_model_logistic.R
# Purpose: Train and evaluate a logistic regression model
# for the single-quarter version of the credit risk project.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

# ---------------------------------------------------------
# 1. Load feature dataset
# ---------------------------------------------------------

df <- readRDS(file.path(dir_features, "feature_panel.rds"))

# ---------------------------------------------------------
# 2. Check that the target column exists
# ---------------------------------------------------------

if (!"high_risk" %in% names(df)) {
  stop("Column 'high_risk' not found. Please run the single-quarter version of R/05_build_target.R first.")
}

# ---------------------------------------------------------
# 3. Select modeling columns
# ---------------------------------------------------------
#
# IMPORTANT:
# We intentionally exclude nco_ratio because high_risk was
# defined from net_charge_offs. Including it would cause
# target leakage and can make glm unstable.
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

# ---------------------------------------------------------
# 4. Check class balance
# ---------------------------------------------------------

cat("\nClass distribution:\n")
print(model_df %>% count(high_risk))

if (length(unique(model_df$high_risk)) < 2) {
  stop("The target column 'high_risk' has only one class. The model cannot be trained.")
}

# ---------------------------------------------------------
# 5. Random train/test split
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
# 6. Train logistic regression model
# ---------------------------------------------------------

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

cat("\nModel summary:\n")
print(summary(model))

# ---------------------------------------------------------
# 7. Predict on test set
# ---------------------------------------------------------

test_df$pred_prob <- predict(
  model,
  newdata = test_df,
  type = "response"
)

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
  model,
  file.path(dir_models_logistic, "logistic_model.rds")
)

save_csv_safely(
  test_df,
  file.path(dir_metrics, "logistic_predictions.csv")
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
  file.path(dir_metrics, "logistic_metrics.csv")
)

# ---------------------------------------------------------
# 10. Create ROC curve
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
    title = "ROC Curve - Logistic Regression",
    x = "False Positive Rate",
    y = "True Positive Rate"
  )

ggsave(
  filename = file.path(dir_figures, "roc_curve_logistic.png"),
  plot = p_roc,
  width = 6,
  height = 5
)

print(p_roc)

# ---------------------------------------------------------
# 11. Optional: inspect top predicted high-risk rows
# ---------------------------------------------------------

top_predictions <- test_df %>%
  arrange(desc(pred_prob)) %>%
  slice_head(n = 20)

cat("\nTop predicted high-risk rows from test set:\n")
print(top_predictions)

message("\nSingle-quarter logistic regression complete.\n")