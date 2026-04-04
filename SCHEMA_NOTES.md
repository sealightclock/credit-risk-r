# Real FFIEC Call Report schema notes

This project is mapped to **FFIEC Call Report / FDIC bulk-data style fields**.

## Why the mapping uses `coalesce(...)`
Call Report bulk files commonly expose the same line item with different mnemonic prefixes:

- `RCFD` = consolidated / all offices
- `RCON` = domestic offices
- other prefixes may appear for certain schedules and forms

Because raw files differ by form version and quarter, the project uses a helper that picks the **first existing non-missing** field from a list of candidate columns.

## Stable line items used

- Total assets: item **2170**
- Total loans and leases, net of unearned income: item **2122**
- Allowance for loan and lease losses / ACL: item **3123**
- Total deposits: item **2200**
- Total equity capital: item **3210**
- Net income (loss): item **4340**
- Tier 1 capital allowable under the risk-based capital guidelines: item **8274**
- Risk-weighted assets (net of allowances and other deductions): item **A223**

## Practical caution

Two fields are the hardest to make fully universal directly from raw bulk Call Report files:

1. `noncurrent_loans`
2. `net_charge_offs`

That is because they are often represented by multiple schedule-specific columns rather than a single balance-sheet line item.

The scripts therefore:
- try obvious pre-aggregated columns first
- then derive them from common schedule fields where available
- otherwise leave them as `NA` so the project still runs and you can map the exact columns in your chosen quarter files
