---
name: beautysale-price-regression-guard
description: Use when working in the BeautySale repository on typical price, backend-owned recent or historical low tiers, fallback price copy, or coupon and bundle calculations where backend rules, DTOs, and frontend labels may diverge.
---

# Beautysale Price Regression Guard

## Overview

Use this only inside the BeautySale repository. Start from the pricing docs, identify the first wrong layer, then run a focused regression sweep across numeric rules, DTO transport, and UI copy.

If `docs/context/PRICE_CALCULATION.md` or `backend/src/main/kotlin/com/beautysale` is missing, say this skill does not apply.

Current assumptions to verify before changing code:
- `typicalEffectivePrice` is the 30-day market-best median, not a raw observed minimum
- user-facing numeric labels and axis labels should use `평소 최저가`, not `평소 가격`
- `BUY` means cheaper than the `typical` baseline; `최근 최저가 수준` means near the real recent 30-day minimum with a meaningful gap from `typical`
- tier precedence is `historical lowest > recent window low > BUY > NORMAL > WATCH`
- `isRecentWindowLow` and `isHistoricalLowest` are backend-owned; frontend should render them, not re-derive them
- stable-SKU clamping is backend-owned; fallback copy or axis labels can still drift even when DTO values are correct

## When to Use

- User asks about effective price, deal summary, typical price, delta from typical, recent-low or historical-low tiers, coupon estimate, bundle pricing, or price-related copy
- Files touched include `DealPolicy`, `DealSummaryService`, `TypicalDecisionService`, `ProductMarketPointService`, `LowestPriceService`, `SaleEventService`, `frontend/lib/platform.ts`, `frontend/lib/deal-composition.ts`, `frontend/lib/platform-presentation.ts`, `frontend/components/price-progress-bar.tsx`, `frontend/components/price-progress-bar-model.ts`, `frontend/components/price-progress-bar-card.tsx`, or `frontend/components/price-decision-overview.tsx`
- Symptoms include "backend value looks right but UI label is wrong", "recent low and BUY should be merged", "fallback copy disagrees with the main tier", "historical high label is misleading", "coupon price changed unexpectedly", or "typicalReady and copy do not match"

## Quick Checks

| Symptom | Start here |
|---------|------------|
| 숫자 라벨과 헤드라인 의미가 다름 | `TypicalDecisionService.kt`, `price-progress-bar-model.ts`, `price-progress-bar-card.tsx` |
| fallback 카드 문구가 backend tier와 다름 | `price-progress-bar.tsx`, `price-decision-overview.tsx`, `platform-presentation.ts` |
| recent-low / historical-low 우선순위가 이상함 | `DealPolicy.kt`, `TypicalDecisionService.kt`, DTO files, `price-progress-bar-model.ts` |
| recent-low 와 BUY 의미가 섞임 | `DealPolicy.kt`, `TypicalDecisionService.kt`, `PRICE_COMPARISON_STRATEGY.md` |
| 최고가 라벨이 값 의미와 다름 | `BrandProductService.kt`, `price-progress-bar-card.tsx` |
| 리스트/상세/메타데이터 카피가 서로 다름 | `product-list-item.tsx`, `platform-card.tsx`, `app/products/[id]/page.tsx`, `app/curations/[id]/page.tsx` |
| 쿠폰 예상가가 바뀜 | `frontend/lib/platform.ts`, `platform-presentation.ts`, `sale-event-badge.tsx`, `SaleEventService.kt` |

## Workflow

1. Open `docs/context/PRICE_COMPARISON_STRATEGY.md`, `docs/context/PRICE_CALCULATION.md`, then `docs/context/DB_SCHEMA.md`.
2. State the changed pricing rule in one sentence using this form: `X is computed from Y and rendered as Z.`
3. Map the change to one or more layers: raw snapshot parsing, market point generation, backend decision state, DTO/API transport, list/detail/metadata presentation.
4. Open only the nearest relevant files from `references/context.md`. For presentation bugs, open the exact renderer of the copy before widening to backend services.
5. Verify existing focused tests around the affected files. If the behavior is not covered, add a test before changing production code.
6. Run an edge-case sweep for the changed rule. Always consider:
   - `bundleQty` 0, 1, and >1
   - `salePrice` null or missing
   - coupon blocked by `canApplyCoupon == false`
   - pre-applied coupon data
   - manual override vs event discount precedence
   - `typicalReady`, `trackingDays`, and `dataPoints` thresholds
   - median-based `typicalEffectivePrice` vs label wording (`평소 최저가` numeric label, `평소 최저가 수준` headline)
   - `BUY` vs `recent low` separation: cheaper-than-typical is not the same as near-recent-min
   - tier precedence: `historical lowest > recent window low > BUY > NORMAL > WATCH`
   - `current == recentWindowMin == typical` should not auto-promote into a stronger recommendation
   - stable-SKU clamp vs frontend badge or title
   - fallback UI when the main card is not renderable
   - `maxObservedUnitPrice` semantics when `trackingDays >= 30`
   - per-unit vs total-price labels
   - list/detail/metadata copy consistency
7. Before claiming completion, run only the nearest regression tests for the touched pricing rule, then widen only if they fail.
8. End with a short note: changed rule, first wrong layer, impacted files, focused tests, residual risk.

## Guardrails

- Do not call a median-based `typical` value a raw observed minimum in numeric labels.
- Do not label user-facing numeric baselines as `평소 가격`; use `평소 최저가`.
- Do not trust a backend-only fix when frontend labels depend on separate helpers or components.
- Do not collapse `recent low` and `BUY` into one meaning unless the UX explicitly compresses display while backend states remain separate.
- Do not implement `recent low` or `historical low` in frontend only if backend owns `isStableSku` or decision-state clamping.
- Do not let fallback UI reintroduce frontend-only `priceDecision` heuristics after backend tiers are available.
- Do not call `maxObservedUnitPrice` an all-time maximum unless the source really is all-time; with long tracking it may be recent-window max.
- Do not infer coupon percentages from free-form strings when structured discount fields exist.
- Do not assume docs marked as strategy are already live behavior; verify whether each rule is target-only or implemented.
- Do not skip the `typicalReady` mismatch check; backend and frontend thresholds can intentionally differ.
- Do not widen the investigation until you identify which layer first became wrong.

## Output Shape

Respond with:
- changed rule
- first wrong layer
- impacted files
- tests run or test gaps
- edge cases checked
- tier separation rationale if `recent` and `BUY` are both involved
- smallest safe next change

## References

Open `references/context.md` for the exact file map before deep dives.
