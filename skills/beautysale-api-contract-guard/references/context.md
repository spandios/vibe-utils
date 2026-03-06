# BeautySale API contract context

Read these first:
- `docs/context/API_SPEC.md`
- `backend/src/main/kotlin/com/beautysale/config/SecurityConfig.kt`

Controller roots:
- `backend/src/main/kotlin/com/beautysale/controller/`
- `backend/src/main/kotlin/com/beautysale/dto/`

Common route groups:
- Public: `/api/v1/*`
- Admin: `/api/admin/*`
- Internal: `/api/internal/*`

Public/controller anchors:
- `backend/src/main/kotlin/com/beautysale/controller/ProductController.kt`
- `backend/src/main/kotlin/com/beautysale/controller/DealController.kt`
- `backend/src/main/kotlin/com/beautysale/controller/SaleEventController.kt`
- `backend/src/main/kotlin/com/beautysale/controller/TrackingController.kt`
- `backend/src/main/kotlin/com/beautysale/controller/BrandRequestController.kt`
- `backend/src/main/kotlin/com/beautysale/controller/SubscriptionController.kt`

Admin/internal anchors:
- `backend/src/main/kotlin/com/beautysale/controller/AdminProductController.kt`
- `backend/src/main/kotlin/com/beautysale/controller/AdminNotificationController.kt`
- `backend/src/main/kotlin/com/beautysale/controller/AdminCacheController.kt`
- `backend/src/main/kotlin/com/beautysale/controller/InternalCrawlController.kt`
- `backend/src/main/kotlin/com/beautysale/controller/InternalCoupangController.kt`

Focused tests:
- `backend/src/test/kotlin/com/beautysale/controller/ProductControllerTest.kt`
- `backend/src/test/kotlin/com/beautysale/controller/DealControllerTest.kt`
- `backend/src/test/kotlin/com/beautysale/controller/TrackingControllerTest.kt`
- `backend/src/test/kotlin/com/beautysale/controller/BrandRequestControllerTest.kt`
- `backend/src/test/kotlin/com/beautysale/controller/SubscriptionControllerTest.kt`
- `backend/src/test/kotlin/com/beautysale/controller/AdminPriceSnapshotControllerTest.kt`
- `backend/src/test/kotlin/com/beautysale/controller/AdminCuratedDealControllerTest.kt`
- `backend/src/test/kotlin/com/beautysale/controller/AdminBrandControllerTest.kt`

Notes:
- Do not assume `springdoc-openapi` or Swagger endpoints exist.
- Keep repo docs and controller tests aligned with any contract change.
