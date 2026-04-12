# Credit Risk Scoring System in R

This project builds a **credit risk scoring model** using publicly available U.S. banking data from the FDIC.

It demonstrates an end-to-end data science workflow:
- data ingestion
- feature engineering
- modeling
- evaluation
- business output (risk watchlist)
- reporting and visualization

---

# Project Overview

The goal is to identify banks with **elevated credit risk** based on financial ratios.

Because the dataset currently contains a **single reporting quarter**, the project is framed as:

> **Cross-sectional credit risk classification**, not time-series forecasting

The final output is a **ranked watchlist of higher-risk banks**, similar to real-world risk monitoring workflows.

---

# Data Sources

- FDIC BankFind / Call Report data (bank-level financials)
- Optional macroeconomic data from FRED

---

# Key Features

The model uses financial indicators such as:

- Noncurrent loan ratio (credit quality)
- Capital ratio (solvency)
- Return on assets (profitability)
- Equity-to-assets ratio (leverage)
- Loans-to-assets and deposits-to-assets (balance sheet structure)

---

# Target Definition

A bank is classified as **high risk** if:

> Its net charge-off ratio falls in the **top 25%** of all banks

---

# Models Implemented

## 1. Logistic Regression (Baseline)
- Interpretable model
- Shows relationship between financial ratios and risk

## 2. Random Forest
- Captures nonlinear relationships
- Provides variable importance

## 3. XGBoost (Optional Advanced Model)
- Gradient boosting model
- Higher predictive power

---

# Model Evaluation

- Accuracy
- AUC (Area Under ROC Curve)
- Confusion matrix
- Repeated holdout validation (30 iterations)

---

# Outputs

## Watchlist

Ranked list of banks by predicted risk: