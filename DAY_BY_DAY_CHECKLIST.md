# Beginner-Friendly Implementation Checklist

## Day 1 — Setup
- Create project folder
- Create R scripts
- Run `00_packages.R`
- Run `01_config.R`

---

## Day 2 — Load data
- Place FDIC file into `data_raw/fdic/`
- Run `02_download_fdic_data.R`
- Check column names

---

## Day 3 — Clean data
- Run `04_clean_bank_data.R`
- Verify:
  - bank_id
  - total_assets
  - loans
- Save cleaned dataset

---

## Day 4 — Build target
- Run `05_build_target.R`
- Understand:
  - what is high risk?
- Check class balance

---

## Day 5 — Feature engineering
- Run `06_feature_engineering.R`
- Learn:
  - NPA ratio
  - ROA
  - capital ratio

---

## Day 6 — EDA
- Run `07_eda.R`
- Look at:
  - distributions
  - missing values
  - charts

---

## Day 7 — Logistic model
- Run `08_model_logistic.R`
- Check:
  - accuracy
  - AUC
- Understand coefficients

---

## Day 8 — Random forest
- Run `09_model_tree.R`
- Compare with logistic
- Check feature importance

---

## Day 9 — Validation
- Run `11_backtest.R`
- Understand:
  - repeated holdout
  - stability of model

---

## Day 10 — Watchlist + charts
- Run `12_score_watchlist.R`
- Run `13_make_charts.R`
- Review:
  - top risky banks
  - charts
