# File: PRODUCT_UPGRADE_SCOPE.md

# RADHA Premium Upgrade Scope

| Upgrade | Problem Solved | Revenue Potential | Phase |
|---|---|---:|---|
| Offline audit mode | Low-connectivity store audits | High | Phase 2 |
| Pharmacy expiry mode | Medicine expiry risk | High | Phase 2+ |
| School canteen mode | Child-preferred product audits | Medium/High | Phase 2+ |
| Vendor near-expiry accountability | Suppliers sending short-shelf-life stock | High | Phase 3 |
| Auto discount suggestion | Reduce waste before expiry | Medium | Phase 3 |
| WhatsApp manager bot | Quick audit questions | Medium | Phase 3 |
| Shelf photo AI audit | Display compliance by photo | High | Later |
| Planogram compliance | Chain shelf layout enforcement | High | Later |
| Product recall alert | EAN/batch recall workflow | High | Later |
---

## 2026-05-15 Upgrade Patch: Reclassified Core vs Premium Scope

### Move Into V1 Core
| Feature | Why It Must Be Core | Notes |
|---|---|---|
| Lightweight inventory | Required for store operations after scanning/expiry | Stock in/out, counts, low stock only. |
| GRN inward | Required to enter supplier invoice stock and expiry at inward stage | Keep simple, no purchase accounting. |
| Subscription/free trial | Required for Play Store SaaS business model | 3-month free trial, ₹49/₹99/₹199. |
| Owner-only dashboard | Required for business visibility | Track visitors, leads, signups, trials, paid users, revenue, usage. |

### Keep Out of V1
| Feature | Reason |
|---|---|
| Full GST billing | Turns RADHA into billing/POS and increases compliance scope. |
| POS checkout | Not aligned with operations/audit focus. |
| Accounting | Full ERP complexity. |
| Printer integration | Only needed when billing/POS exists. |
| Supplier payable ledger | Accounting scope; not needed for lightweight GRN. |

