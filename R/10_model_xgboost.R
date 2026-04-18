# =========================================================
# 10_model_xgboost.R
# Purpose:
#   Train and evaluate an optional XGBoost model.
# =========================================================

source("R/00_packages.R")
source("R/01_config.R")
source("R/14_helpers.R")

if (!requireNamespace("xgboost", quietly = TRUE)) {
  stop("Package 'xgboost' is not installed. Run install.packages('xgboost') first.")
}

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

set.seed(project_seed)
train_index <- sample(seq_len(nrow(model_df)), size = floor(0.70 * nrow(model_df)))
train_df <- model_df[train_index, ]
test_df  <- model_df[-train_index, ]

train_x <- as.matrix(train_df %>% select(-high_risk))
test_x  <- as.matrix(test_df %>% select(-high_risk))
train_y <- train_df$high_risk
test_y  <- test_df$high_risk

dtrain <- xgboost::xgb.DMatrix(data = train_x, label = train_y)
dtest  <- xgboost::xgb.DMatrix(data = test_x, label = test_y)

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

test_df$pred_prob <- predict(xgb_model, newdata = dtest)
test_df$pred_class <- ifelse(test_df$pred_prob >= 0.50, 1, 0)

test_eval_df <- test_df %>%
  mutate(
    high_risk = factor(high_risk, levels = c(0, 1)),
    pred_class = factor(pred_class, levels = c(0, 1))
  )

accuracy_value <- mean(test_df$pred_class == test_df$high_risk)
auc_value <- yardstick::roc_auc(test_eval_df, truth = high_risk, pred_prob)

saveRDS(xgb_model, file.path(dir_models_xgb, "xgboost_model.rds"))
save_csv_safely(test_df, file.path(dir_metrics, "xgboost_predictions.csv"))

metrics_df <- tibble(
  metric = c("accuracy", "auc"),
  value = c(accuracy_value, auc_value$.estimate[1])
)

save_csv_safely(metrics_df, file.path(dir_metrics, "xgboost_metrics.csv"))

roc_df <- yardstick::roc_curve(test_eval_df, truth = high_risk, pred_prob)

p_roc <- ggplot(roc_df, aes(x = 1 - specificity, y = sensitivity)) +
  geom_line() +
  geom_abline(linetype = "dashed") +
  labs(title = "ROC Curve - XGBoost", x = "False Positive Rate", y = "True Positive Rate")

ggsave(file.path(dir_figures, "roc_curve_xgboost.png"), p_roc, width = 6, height = 5)

importance_df <- xgboost::xgb.importance(feature_names = colnames(train_x), model = xgb_model) %>%
  as_tibble()

save_csv_safely(importance_df, file.path(dir_tables, "xgboost_variable_importance.csv"))

message("\nSingle-quarter XGBoost complete.")
