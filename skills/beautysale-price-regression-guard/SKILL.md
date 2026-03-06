---
name: beautysale-price-regression-guard
description: Use when working in the BeautySale repository on price calculation, deal summary, coupon, bundle, typical price, or platform presentation changes, or when a price-related bug suggests backend and frontend calculations may have diverged.
---

# Beautysale Price Regression Guard

## Overview

Use this only inside the BeautySale repository. It narrows a price-related change to the exact backend and frontend code paths, then forces a small regression sweep before implementation or completion.

If `docs/context/PRICE_CALCULATION.md` or `backend/src/main/kotlin/com/beautysale` is missing, say this skill does not apply.

## When to Use

- User asks about price regression, effective price, typical price, delta from typical, bundle pricing, coupon estimate, or sale-event discount behavior
- Files touched include `DealSummaryService`, `TypicalDecisionService`, `ProductMarketPointService`, `LowestPriceService`, `SaleEventService`, `frontend/lib/platform.ts`, `frontend/lib/deal-composition.ts`, `frontend/lib/price-signal.ts`, or `frontend/lib/platform-presentation.ts`
- Symptoms include "backend value looks right but UI label is wrong", "coupon price changed unexpectedly", "lowest/near lowest badge moved", or "typicalReady and copy do not match"

## Workflow

1. Open `docs/context/PRICE_CALCULATION.md` first, then `docs/context/DB_SCHEMA.md`.
2. State the changed pricing rule in one sentence before touching code.
3. Map the change to one or more layers: raw snapshot parsing, backend summary calculation, market point generation, frontend display logic, notification copy.
4. Open only the nearest relevant files from `references/context.md`. Do not read unrelated services first.
5. Verify existing focused tests around the affected files. If the behavior is not covered, add a test before changing production code.
6. Run an edge-case sweep for the changed rule. Always consider:
   - `bundleQty` 0, 1, and >1
   - `salePrice` null or missing
   - coupon blocked by `canApplyCoupon == false`
   - pre-applied coupon data
   - manual override vs event discount precedence
   - `typicalReady`, `trackingDays`, and `dataPoints` thresholds
   - backend/frontend wording mismatch
7. End with a short note: changed rule, touched layers, focused tests, residual risk.

## Guardrails

- Do not trust a backend-only fix when frontend labels depend on separate thresholds or presentation helpers.
- Do not infer coupon percentages from free-form strings when structured discount fields exist.
- Do not skip the `typicalReady` mismatch check; backend and frontend thresholds can intentionally differ.
- Do not widen the investigation until you identify which layer first became wrong.

## Output Shape

Respond with:
- changed rule
- impacted files
- test gaps or tests to run
- edge cases checked
- smallest safe next change

## References

Open `references/context.md` for the exact file map before deep dives.
