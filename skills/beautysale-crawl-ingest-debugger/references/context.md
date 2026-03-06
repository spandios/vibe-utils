# BeautySale crawl ingest context

Read the contract and schema first:
- `backend/src/main/kotlin/com/beautysale/controller/InternalCrawlController.kt`
- `backend/src/main/kotlin/com/beautysale/dto/CrawlResultDto.kt`
- `docs/context/DB_SCHEMA.md`
- `docs/context/API_SPEC.md`

Core ingest chain:
- `backend/src/main/kotlin/com/beautysale/service/CrawlResultService.kt`
- `backend/src/main/kotlin/com/beautysale/repository/PlatformProductRepository.kt`
- `backend/src/main/kotlin/com/beautysale/repository/PriceSnapshotRepository.kt`
- `backend/src/main/kotlin/com/beautysale/service/PriceChangeDetector.kt`
- `backend/src/main/kotlin/com/beautysale/service/NotificationService.kt`
- `backend/src/main/kotlin/com/beautysale/service/ProductMarketPointService.kt`

Focused tests:
- `backend/src/test/kotlin/com/beautysale/service/CrawlResultServiceCoupangAffiliateTest.kt`
- `backend/src/test/kotlin/com/beautysale/service/PriceChangeDetectorTest.kt`
- `backend/src/test/kotlin/com/beautysale/service/NotificationServiceTest.kt`

Downstream symptoms often appear in:
- `backend/src/main/kotlin/com/beautysale/service/LowestPriceService.kt`
- `backend/src/main/kotlin/com/beautysale/service/BrandProductService.kt`
- `backend/src/main/kotlin/com/beautysale/service/CuratedDealService.kt`

Hot keywords:
- `crawl-results`
- `missingStreak`
- `discontinuedAt`
- `soldOut`
- `affiliateUrl`
- `price change`
- `notification`
