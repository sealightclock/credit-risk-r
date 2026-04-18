# =========================================================
# 08_model_logistic.R
# Purpose:
#   Train and evaluate a logistic regression model.
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

message("Rows available for modeling: ", nrow(model_df))

if (nrow(model_df) == 0) {
  stop("No rows available after drop_na().")
}

set.seed(project_seed)
train_index <- sample(seq_len(nrow(model_df)), size = floor(0.70 * nrow(model_df)))
train_df <- model_df[train_index, ]
test_df  <- model_df[-train_index, ]

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

message("\nModel summary:")
print(summary(model))

test_df$pred_prob <- predict(model, newdata = test_df, type = "response")
test_df$pred_class <- ifelse(test_df$pred_prob >= 0.50, 1, 0)

accuracy_value <- mean(test_df$pred_class == test_df$high_risk)
conf_matrix <- table(Predicted = test_df$pred_class, Actual = test_df$high_risk)

test_eval_df <- test_df %>%
  mutate(
    high_risk = factor(high_risk, levels = c(0, 1)),
    pred_class = factor(pred_class, levels = c(0, 1))
  )

auc_value <- yardstick::roc_auc(test_eval_df, truth = high_risk, pred_prob)
accuracy_tbl <- yardstick::accuracy(test_eval_df, truth = high_risk, estimate = pred_class)

message("\nConfusion matrix:")
print(conf_matrix)

message("\nAUC:")
print(auc_value)

message("\nAccuracy table:")
print(accuracy_tbl)

saveRDS(model, file.path(dir_models_logistic, "logistic_model.rds"))
save_csv_safely(test_df, file.path(dir_metrics, "logistic_predictions.csv"))

metrics_df <- tibble(
  metric = c("accuracy", "auc"),
  value = c(accuracy_value, auc_value$.estimate[1])
)

save_csv_safely(metrics_df, file.path(dir_metrics, "logistic_metrics.csv"))

roc_df <- yardstick::roc_curve(test_eval_df, truth = high_risk, pred_prob)

p_roc <- ggplot(roc_df, aes(x = 1 - specificity, y = sensitivity)) +
  geom_line() +
  geom_abline(linetype = "dashed") +
  labs(
    title = "ROC Curve - Logistic Regression",
    x = "False Positive Rate",
    y = "True Positive Rate"
  )

ggsave(file.path(dir_figures, "roc_curve_logistic.png"), p_roc, width = 6, height = 5)

message("\nSingle-quarter logistic regression complete.")
