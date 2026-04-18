# FDIC Schema Notes (Beginner-Friendly)

## Why this file exists

FDIC data is complex:
- many columns
- inconsistent naming
- some fields are ratios, some are raw values

This file explains how we simplify it.

---

## Key fields used

| Project Name | FDIC Column |
|-------------|------------|
| bank_id | CERT |
| bank_name | NAME |
| quarter | REPDTE |
| total_assets | ASSET |
| total_loans | LNLSNET |
| deposits | DEP |
| net_income | NETINC |

---

## Risk-related fields

| Project Name | FDIC Column |
|-------------|------------|
| noncurrent_loans | NCLNLSR |
| net_charge_offs | NTLNLSR |
| allowance | LNATRESR |

---

## Important note

Some FDIC columns are:
- already ratios
- not raw dollar values

Example:
- `NCLNLSR` = ratio, not amount

👉 So we **do NOT divide again**

---

## Why this matters

If you treat a ratio as an amount:
- your model becomes wrong
- results become meaningless

---

## Simplification approach

Instead of using hundreds of fields:

We pick:
- a small number of stable variables
- easy-to-understand financial ratios

---

## Future improvement

In a more advanced version:
- map full FFIEC schema
- separate domestic vs consolidated
- build more precise ratios
