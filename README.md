# Credit Risk Scoring System in R (Beginner-Friendly)

## What this project does

This project builds a **simple credit risk model** using real U.S. banking data (FDIC).

It shows a complete workflow:
- load data
- clean data
- build features
- train models
- evaluate results
- create a **risk watchlist**

---

## Key idea

We want to answer:

> Which banks look riskier than others **right now**?

Since we only use **one quarter of data**, this is:

- NOT forecasting
- NOT time-series modeling

👉 It is a **cross-sectional classification problem**

---

## Data

Source:
- FDIC Call Report data (bank financials)

Optional:
- FRED macroeconomic data

---

## Target (what we predict)

We define:

- `high_risk = 1` → bank is risky  
- `high_risk = 0` → bank is not risky  

Rule:
- top 25% of banks by **net charge-off ratio**

---

## Models used

1. Logistic Regression (baseline)
2. Random Forest
3. XGBoost (optional)

---

## Outputs

### Watchlist
- outputs/watchlists/watchlist.csv
- ranked by predicted risk

### Charts
- outputs/figures/
- risk distribution, top banks, scatter plots

### Report
- reports/credit_risk_report.html

---

## How to run

Run scripts in order:

source("R/04_clean_bank_data.R")  
source("R/05_build_target.R")  
source("R/06_feature_engineering.R")  
source("R/07_eda.R")  
source("R/08_model_logistic.R")  
source("R/09_model_tree.R")  
source("R/11_backtest.R")  
source("R/12_score_watchlist.R")  
source("R/13_make_charts.R")  

---

## What you learn

- Basic R data analysis
- Financial ratio interpretation
- Simple machine learning
- How to build a real-world analytics project

---

## Limitations

- Only one quarter of data
- No true prediction over time
- Some ratios are simplified

---

## Next steps (future improvements)

- add multiple quarters
- build time-based models
- improve feature engineering
- enhance dashboard
