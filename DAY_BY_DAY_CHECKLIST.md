# 10-Day Implementation Checklist (Single-Quarter Credit Risk Project)

## Day 1 — Project setup
- Create GitHub repo: `credit-risk-r`
- Open in RStudio and create `credit-risk-r.Rproj`
- Create project folder structure:
  - `R/`, `data_raw/`, `data_processed/`, `outputs/`, `models/`, `reports/`, `app/`
- Initialize `renv`
- Create `.gitignore`
- Add initial script files

---

## Day 2 — Data acquisition
- Decide data source: FDIC BankFind export (recommended for simplicity)
- Download single-quarter dataset (CSV)
- Place file into:
  - `data_raw/fdic/`
- Pull macro data (optional) using:
  - `quantmod::getSymbols()` or `FRED`
- Save macro data to:
  - `data_raw/fred/`

---

## Day 3 — Clean bank data
- Read FDIC dataset
- Standardize column names with `janitor::clean_names()`
- Map key fields:
  - bank_id, bank_name, quarter_end_date
  - assets, loans, deposits, income
- Handle data types and numeric conversion
- Remove duplicates
- Save cleaned dataset:
  - `data_processed/bank_panel/bank_panel_clean.rds`

---

## Day 4 — Define target (single-quarter version)
- Since only one quarter is available:
  - Define risk using cross-sectional rule
- Create target:
  - `high_risk = top 25% of net_charge_offs`
- Validate class balance
- Save modeling base:
  - `data_processed/modeling/model_base.rds`

---

## Day 5 — Feature engineering (cross-sectional)
- Create financial ratios:
  - reserve coverage
  - NPA ratio
  - capital ratio
  - ROA
  - equity-to-assets
  - loans-to-assets
  - deposits-to-assets
- DO NOT use lag or lead variables (no time dimension)
- Merge macro data if available
- Save feature dataset:
  - `data_processed/features/feature_panel.rds`

---

## Day 6 — Exploratory Data Analysis (EDA)
- Inspect dataset structure (`glimpse`, `summary`)
- Check missing values
- Plot:
  - target distribution
  - feature histograms
- Create relationship charts:
  - ROA vs risk
  - NPA ratio vs risk
- Save charts to:
  - `outputs/figures/`
- Save tables to:
  - `outputs/tables/`

---

## Day 7 — Baseline model (logistic regression)
- Perform random 70/30 train/test split
- Train logistic regression model
- Evaluate:
  - accuracy
  - confusion matrix
  - AUC
- Save outputs:
  - `models/logistic_regression/`
  - `outputs/model_metrics/`

---

## Day 8 — Tree-based model
- Train random forest model (`ranger`)
- Evaluate same metrics:
  - accuracy, AUC
- Extract variable importance
- Compare with logistic regression
- Save outputs and charts

---

## Day 9 — Model validation and watchlist
- Perform repeated holdout validation (30 iterations)
- Compare model stability:
  - AUC distribution
  - accuracy distribution
- Score full dataset using trained model
- Create ranked watchlist:
  - `outputs/watchlists/watchlist.csv`
  - `watchlist_top20.csv`

---

## Day 10 — Charts, report, and app
- Generate charts:
  - top risky banks
  - risk distribution
  - scatter plots
- Build Quarto report:
  - `reports/credit_risk_report.qmd`
  - render to HTML
- Update `README.md`
- Add screenshots for GitHub
- (Optional) Build Shiny dashboard:
  - `app/app.R`

---

# Final Outcome

By Day 10, you will have:

- Cleaned FDIC dataset
- Feature-engineered credit risk dataset
- Logistic regression + random forest models
- Model evaluation metrics
- Ranked credit risk watchlist
- Visualizations and charts
- Final HTML report
- (Optional) Interactive Shiny dashboard

---

# Key Framing (for interviews)

This project demonstrates:

- Practical financial data handling
- Feature engineering for credit risk
- Cross-sectional classification modeling
- Model evaluation and comparison
- Translation of model outputs into business insights

Because the dataset is single-quarter, the project is framed as:

> Cross-sectional credit risk scoring rather than time-series prediction