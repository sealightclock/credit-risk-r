# Credit Risk Early-Warning System in R

This version includes a **real FFIEC Call Report / FDIC bulk-data schema mapping** for core fields used in the project.

## Core schema mapping used

| Project field | Preferred raw fields |
|---|---|
| `bank_id` | `CERT`, `cert`, `IDRSSD`, `idrssd`, `RSSD9001`, `rssd9001` |
| `bank_name` | `NAME`, `BANK`, `bank`, `INSTNAME`, `inst_name` |
| `quarter_end_date` | `REPDTE`, `repdte`, `RCON9999`, `date`, `report_date` |
| `total_assets` | `RCFD2170`, `RCON2170` |
| `total_loans` | `RCFD2122`, `RCON2122`, `RCFDB528`, `RCONB528` |
| `allowance_for_credit_losses` | `RCFD3123`, `RCON3123`, `RCFN3123` |
| `deposits` | `RCFD2200`, `RCON2200` |
| `tier1_capital` | `RCFA8274`, `RCOA8274`, `RCFD8274`, `RCON8274` |
| `risk_weighted_assets` | `RCFAA223`, `RCOAA223`, `RCFDA223`, `RCONA223` |
| `total_equity_capital` | `RCFD3210`, `RCON3210` |
| `net_income` | `RIAD4340`, `RCON4340`, `RCFD4340` |

## Notes

- `noncurrent_loans` is **not a single universal line item** in raw Call Report bulk files. In this project, the script computes it by summing common RC-N delinquency/nonaccrual fields **if they exist**, and otherwise falls back to any pre-aggregated `noncurrent_loans` or `ncloan` column present in the file.
- `net_charge_offs` is also handled defensively. If the file includes an already-aggregated `net_charge_offs` or `nco` field, the script uses it; otherwise it attempts to derive net charge-offs from charge-off and recovery fields when available.

See `SCHEMA_NOTES.md` for implementation details.
