---
name: beautysale-api-contract-guard
description: Use when working in the BeautySale repository on controller, DTO, security, or API contract changes, or when public, admin, or internal endpoints may need test, auth, or docs updates.
---

# Beautysale Api Contract Guard

## Overview

Use this only inside the BeautySale repository. It keeps API changes honest by forcing route-group checks, auth checks, DTO checks, focused controller tests, and docs sync for BeautySale's public, admin, and internal surfaces.

If `docs/context/API_SPEC.md` or `backend/src/main/kotlin/com/beautysale/controller` is missing, say this skill does not apply.

## When to Use

- User asks to add or change a controller endpoint, request DTO, response DTO, auth rule, or error response
- Files touched include `controller/`, `dto/`, `SecurityConfig.kt`, or controller integration tests
- The change could affect `/api/v1`, `/api/admin`, or `/api/internal`

## Workflow

1. Identify the route group first: public, admin, or internal.
2. Open `docs/context/API_SPEC.md` and `backend/src/main/kotlin/com/beautysale/config/SecurityConfig.kt` before changing code.
3. Map the contract surface: controller method, request DTO, response DTO, validation, auth header rules, cache impact.
4. Find the nearest controller integration test and adjust or add coverage before implementation when behavior changes.
5. After the code change, sync the contract summary in `docs/context/API_SPEC.md` if the endpoint shape, path, query parameters, or response type changed.
6. Explicitly check whether the change requires cache invalidation, admin UI adjustments, or frontend caller updates.
7. End with a short contract diff: route, auth, request, response, tests, docs.

## Guardrails

- Do not assume Swagger or springdoc exists; this repository currently documents API changes in repo docs and tests.
- Do not change DTO shape without checking both controller tests and API docs.
- Do not forget `X-API-Key` coverage for admin and internal routes.
- Do not treat a cache-affecting endpoint as controller-only work.

## Output Shape

Respond with:
- route group
- contract diff
- auth impact
- focused tests
- docs that changed
- caller or cache follow-ups

## References

Open `references/context.md` for route-group anchors, DTO locations, and controller test entry points.
