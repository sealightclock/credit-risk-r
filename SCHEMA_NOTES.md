# Feature Panel Schema (Actual Implementation)

This document reflects the **exact structure of `feature_panel.rds`** used
throughout modeling and backtesting.

Each row represents:
- one bank (`id_rssd`)
- one reporting date (`report_date`)

---

## 1. Core identifiers

- `id_rssd`  
  Unique bank identifier (FDIC / FFIEC)

- `report_date`  
  Reporting period (quarter-end date)

---

## 2. Raw balance sheet variables (standardized)

These fields are resolved via `coalesce(...)` from raw Call Report columns.

- `total_assets`  
- `total_loans`  
- `allowance`  
- `total_deposits`  
- `total_equity`  
- `net_income`  
- `tier1_capital`  
- `risk_weighted_assets`

---

## 3. Credit risk variables (best-effort fields)

These may be partially missing depending on source files.

- `noncurrent_loans`  
- `net_charge_offs`

These are:
- derived when possible
- otherwise set to `NA`

---

## 4. Derived financial ratios (used in models)

The following features are computed in the pipeline:

- `capital_ratio`  
  = tier1_capital / risk_weighted_assets

- `roa`  
  = net_income / total_assets

- `loan_ratio`  
  = total_loans / total_assets

- `deposit_ratio`  
  = total_deposits / total_assets

- `allowance_ratio`  
  = allowance / total_loans

---

## 5. Modeling target

- `default_flag`  
  Binary indicator used for supervised learning

Definition depends on backtest logic (see `R/11_backtest.R`).

---

## 6. Data characteristics

- Dataset is **panel data**
- Missing values (`NA`) are allowed for:
  - `noncurrent_loans`
  - `net_charge_offs`
- Core balance sheet variables are expected to be mostly populated

---

## 7. Design principles (as implemented)

- Use **stable column names** regardless of raw schema variation
- Avoid breaking the pipeline due to missing raw fields
- Prefer **robustness over perfect regulatory reconstruction**

---

## 8. IMPORTANT: Source of truth

To verify or update this schema, run:

```r
names(feature_panel)