# BeautySale price regression context

Open these first:
- `docs/context/PRICE_CALCULATION.md`
- `docs/context/DB_SCHEMA.md`

Primary backend files:
- `backend/src/main/kotlin/com/beautysale/service/DealSummaryService.kt`
- `backend/src/main/kotlin/com/beautysale/service/TypicalDecisionService.kt`
- `backend/src/main/kotlin/com/beautysale/service/ProductMarketPointService.kt`
- `backend/src/main/kotlin/com/beautysale/service/LowestPriceService.kt`
- `backend/src/main/kotlin/com/beautysale/service/SaleEventService.kt`
- `backend/src/main/kotlin/com/beautysale/dto/ProductDto.kt`
- `backend/src/main/kotlin/com/beautysale/dto/CuratedDealDto.kt`

Primary frontend files:
- `frontend/lib/deal-composition.ts`
- `frontend/lib/price-signal.ts`
- `frontend/lib/platform.ts`
- `frontend/lib/platform-presentation.ts`
- `frontend/components/sale-event-badge.tsx`
- `frontend/components/platform-card.tsx`

Focused tests:
- `backend/src/test/kotlin/com/beautysale/service/DealSummaryServiceTest.kt`
- `frontend/lib/__tests__/deal-composition.test.ts`
- `frontend/lib/__tests__/price-signal.test.ts`
- `frontend/lib/__tests__/platform-presentation.test.ts`
- `frontend/components/__tests__/sale-event-badge.test.tsx`
- `frontend/components/__tests__/platform-card.test.tsx`

Hot keywords:
- `effectivePrice`
- `typicalReady`
- `deltaFromTypical`
- `bundleQty`
- `canApplyCoupon`
- `hasPreAppliedCouponPrice`
- `discountPercent`
- `maxDiscountAmount`
