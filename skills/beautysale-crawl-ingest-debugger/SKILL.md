---
name: beautysale-crawl-ingest-debugger
description: Use when working in the BeautySale repository on crawl ingestion, crawl result processing, price snapshot creation, price change detection, or notification side effects, or when crawled data looks missing, duplicated, stale, or incorrect.
---

# Beautysale Crawl Ingest Debugger

## Overview

Use this only inside the BeautySale repository. It traces a crawl issue from API input to persistence and downstream side effects so fixes land on the first broken stage instead of the loudest symptom.

If `backend/src/main/kotlin/com/beautysale/service/CrawlResultService.kt` is missing, say this skill does not apply.

## When to Use

- User asks about crawl-result bugs, missing products, stale prices, duplicate notifications, affiliate URL issues, or bad sold-out/discontinued transitions
- Files touched include `InternalCrawlController`, `CrawlResultDto`, `CrawlResultService`, `PriceChangeDetector`, `NotificationService`, `PlatformProductRepository`, or `PriceSnapshotRepository`
- Symptoms start from incoming crawl data but surface later in lists, deal summaries, alerts, or admin tooling

## Workflow

1. Start with the failing symptom and one concrete platform product or product id if available.
2. Open the input contract first: `InternalCrawlController` and `CrawlResultDto`.
3. Trace the ingest path in order: crawl input -> normalization/persistence -> snapshot creation -> price-change detection -> notification or market-point side effects.
4. At each stage, write down the expected side effect before reading more code.
5. Check the nearest existing service tests before proposing a fix. Add or tighten a test at the first broken stage.
6. If the data symptom reaches UI or admin pages, stop and confirm whether the root cause is ingest, summary rebuild, or presentation.
7. Finish with the earliest broken stage, evidence, smallest safe fix, and downstream entities that must be revalidated.

## Guardrails

- Do not jump to controller or UI fixes when the ingest chain is unverified.
- Do not inspect every repository first; follow the chain in order.
- Do not assume a missing notification means notification code is broken. Upstream snapshot or price-change logic may be wrong.
- Do not stop at the first visible mismatch; note all downstream consumers that may now hold stale data.

## Output Shape

Respond with:
- symptom
- earliest confirmed broken stage
- evidence files
- focused tests to add or run
- downstream recheck list

## References

Open `references/context.md` for the ingest chain and hotspot file list.
