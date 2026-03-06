# Complexity Rubric

Score each dimension from 0 to 3. Use evidence from the codebase, not guesswork alone.

## Dimensions

### 1. Change Surface
- `0`: One file or one localized function/class
- `1`: One module or one vertical slice
- `2`: Multiple modules in the same app or bounded context
- `3`: Multiple apps, shared libraries, or cross-cutting layers

### 2. Coupling
- `0`: Clear isolated path with minimal dependencies
- `1`: A few direct dependencies
- `2`: Shared abstractions or indirect dependencies likely involved
- `3`: Hidden coupling, fan-out, or unclear ownership

### 3. Data and Contract Impact
- `0`: No schema, payload, or public contract changes
- `1`: Internal DTO or view-model changes only
- `2`: API contract, event payload, or persistence mapping changes
- `3`: Schema migration, backward compatibility, or multi-consumer contract changes

### 4. Domain Uncertainty
- `0`: Existing behavior already matches most of the request
- `1`: Small interpretation gaps
- `2`: Business rules need discovery across several places
- `3`: Requirements or ownership are ambiguous

### 5. Operational Risk
- `0`: No auth, permissions, jobs, cache, payments, or external systems
- `1`: One operational concern exists but is familiar
- `2`: Several operational concerns exist
- `3`: High-risk behavior or third-party integration is central

### 6. Verification Blast Radius
- `0`: One focused test or manual check is enough
- `1`: Several tests in one module
- `2`: Multiple layers or apps need regression coverage
- `3`: End-to-end verification or migration rehearsal is required

## Bands

- `0-4`: Small
- `5-8`: Medium
- `9-12`: Large
- `13-18`: Extra Large

## Interpretation Notes

- Upgrade one band when the code path is still unclear after a reasonable search.
- Upgrade one band when shared abstractions must change.
- Downgrade only when concrete evidence proves the path is narrower than expected.
- Do not average away a `3` in Data and Contract Impact or Operational Risk. Those usually dominate execution cost.
