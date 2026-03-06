# BeautySale price regression context

Open these first:
- `docs/context/PRICE_COMPARISON_STRATEGY.md`
- `docs/context/PRICE_CALCULATION.md`
- `docs/context/DB_SCHEMA.md`
- `docs/context/BEAUTYSALE_STRATEGY_V1.md` (only if rule intent is still unclear)

Primary backend files:
- `backend/src/main/kotlin/com/beautysale/service/TypicalDecisionService.kt`
- `backend/src/main/kotlin/com/beautysale/service/DealSummaryService.kt`
- `backend/src/main/kotlin/com/beautysale/service/ProductMarketPointService.kt`
- `backend/src/main/kotlin/com/beautysale/service/LowestPriceService.kt`
- `backend/src/main/kotlin/com/beautysale/service/SaleEventService.kt`
- `backend/src/main/kotlin/com/beautysale/dto/DealSummaryDto.kt`
- `backend/src/main/kotlin/com/beautysale/dto/CuratedDealDto.kt`
- `backend/src/main/kotlin/com/beautysale/dto/CrawlResultDto.kt`
- `backend/src/main/kotlin/com/beautysale/dto/ProductDto.kt`

Primary frontend files:
- `frontend/lib/deal-composition.ts`
- `frontend/lib/price-signal.ts`
- `frontend/lib/platform.ts`
- `frontend/lib/platform-presentation.ts`
- `frontend/components/price-progress-bar.tsx`
- `frontend/components/platform-card.tsx`
- `frontend/components/product-list-item.tsx`
- `frontend/components/price-history-chart.tsx`
- `frontend/components/price-inline.tsx`
- `frontend/components/price-decision-overview.tsx`
- `frontend/components/sale-event-badge.tsx`
- `frontend/components/curation-product-detail.tsx`
- `frontend/app/products/[id]/page.tsx`
- `frontend/app/curations/[id]/page.tsx`

Focused tests:
- `backend/src/test/kotlin/com/beautysale/service/DealSummaryServiceTest.kt`
- `backend/src/test/kotlin/com/beautysale/service/TypicalDecisionServiceTest.kt`
- `frontend/lib/__tests__/deal-composition.test.ts`
- `frontend/lib/__tests__/price-signal.test.ts`
- `frontend/lib/__tests__/platform-presentation.test.ts`
- `frontend/components/__tests__/price-progress-bar.test.tsx`
- `frontend/components/__tests__/platform-card.test.tsx`
- `frontend/components/__tests__/price-history-chart.test.tsx`
- `frontend/components/__tests__/product-list-item.test.tsx`
- `frontend/components/__tests__/sale-event-badge.test.tsx`
- `frontend/components/__tests__/curation-product-detail-ui.test.tsx`
- `frontend/app/__tests__/metadata-title.test.ts`

Hot keywords:
- `effectivePrice`
- `typicalEffectivePrice`
- `recentWindowMinEffectivePrice`
- `isRecentWindowLow`
- `isStableSku`
- `historical lowest`
- `typicalReady`
- `deltaFromTypical`
- `bundleQty`
- `canApplyCoupon`
- `hasPreAppliedCouponPrice`
- `discountPercent`
- `maxDiscountAmount`
- `평소 가격`
- `평소 최저가 수준`
- `recent low`
