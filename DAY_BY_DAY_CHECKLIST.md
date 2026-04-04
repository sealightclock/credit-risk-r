# 10-Day Implementation Checklist

## Day 1 — Project setup
- Create GitHub repo: `credit-risk-r`
- Open in RStudio and create `credit-risk-r.Rproj`
- Create project folders
- Initialize `renv`
- Create `.gitignore`
- Add empty script files

## Day 2 — Raw data ingestion
- Decide how to ingest FDIC data
- Pull 1–3 FRED series using `quantmod::getSymbols()` or `fredr`
- Save raw or lightly cleaned macro data

## Day 3 — Clean bank data
- Read one or more raw FDIC files
- Standardize column names with `janitor::clean_names()`
- Keep only needed fields
- Parse reporting quarter/date
- Create consistent bank ID
- Remove duplicates
- Save cleaned panel

## Day 4 — Define target
- Group by bank ID
- Sort by quarter
- Create lead variables such as `nco_ratio_next_q`
- Define binary target `high_risk_next_q`
- Save modeling base table

## Day 5 — Feature engineering
- Engineer reserve coverage, NPA ratio, NCO ratio, loan/deposit growth, capital ratio, ROA
- Add lagged variables
- Merge FRED macro data
- Save feature dataset

## Day 6 — EDA and business charts
- Plot class balance
- Plot target rate over time
- Plot key feature distributions
- Plot macro series over time
- Create missingness summary

## Day 7 — Baseline model
- Time split data
- Create recipe
- Fit logistic regression
- Evaluate AUC, precision/recall, confusion matrix
- Save model and metrics

## Day 8 — Tree model
- Fit random forest
- Evaluate metrics
- Extract variable importance
- Compare against logistic regression

## Day 9 — Backtest and watchlist
- Implement rolling quarter backtest or one out-of-time test
- Score latest quarter
- Create ranked watchlist CSV

## Day 10 — Report and polish
- Build `credit_risk_report.qmd`
- Update `README.md`
- Add screenshots
- Optional: stub Shiny app
