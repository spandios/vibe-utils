---
name: kotlin-dto-patterns
description: Kotlin DTO 변환 패턴 가이드. Request/Response DTO 규칙, OpenAPI Schema 어노테이션, data class 패턴. DTO, Request, Response 작성 시 자동 활성화.
allowed-tools: Read, Write, Grep, Edit
---

# Kotlin DTO Patterns Skill

Kotlin에서 REST API DTO 작성 규칙과 변환 패턴.

## When I Activate

- Request/Response DTO 작성 시
- API 엔드포인트 생성 시
- DTO 변환 로직 관련 질문
- OpenAPI/Swagger 문서화 작업 시

---

## Core Rules

### 1. Request DTO → Service 직접 전달

```kotlin
// Controller
@PostMapping
fun create(@Valid @RequestBody request: CreateCustomerRequest): CustomerResponse {
    val customer = service.create(request)  // Request 직접 전달
    return CustomerResponse.from(customer)
}

// Service
@Transactional
fun create(request: CreateCustomerRequest): Customer {
    return repository.save(
        Customer(
            name = request.name,
            phone = request.phone,
        )
    )
}
```

### 2. Response DTO → `from()` 팩토리 메서드

```kotlin
data class CustomerResponse(
    val id: Long,
    val name: String,
    val phone: String,
    val createdAt: LocalDateTime,
) {
    companion object {
        fun from(entity: Customer): CustomerResponse {
            return CustomerResponse(
                id = entity.id!!,
                name = entity.name,
                phone = entity.phone,
                createdAt = entity.createdAt,
            )
        }
    }
}
```

---

## OpenAPI Schema Annotations

### `@field:Schema` 사용 (필수)

생성자 파라미터에 Schema 적용 시 반드시 `@field:` 사용

```kotlin
// ✅ 올바른 방법
data class CreateCustomerRequest(
    @field:NotBlank(message = "이름은 필수입니다")
    @field:Schema(description = "고객 이름", example = "홍길동")
    val name: String,

    @field:Pattern(regexp = "^010-\\d{4}-\\d{4}$", message = "올바른 전화번호 형식이 아닙니다")
    @field:Schema(description = "전화번호", example = "010-1234-5678")
    val phone: String,
)

// ❌ 잘못된 방법 (Swagger에서 인식 안됨)
data class CreateCustomerRequest(
    @Schema(description = "고객 이름")  // field: 누락
    val name: String,
)
```

### 컬렉션 필드

```kotlin
data class ConsultationResponse(
    @field:Schema(description = "상담 ID")
    val id: Long,

    @field:Schema(description = "카테고리 목록")
    val categories: List<CategoryDto>,

    @field:Schema(description = "상담 이력")
    val histories: List<HistoryDto>,
) {
    companion object {
        fun from(entity: Consultation): ConsultationResponse {
            return ConsultationResponse(
                id = entity.id!!,
                categories = entity.categories.map { CategoryDto.from(it) },
                histories = entity.histories.map { HistoryDto.from(it) },
            )
        }
    }
}
```

---

## Request DTO Patterns

### Create Request

```kotlin
data class Create{Entity}Request(
    @field:NotBlank(message = "이름은 필수입니다")
    @field:Size(max = 100, message = "이름은 100자 이하여야 합니다")
    @field:Schema(description = "이름", example = "샘플 이름", required = true)
    val name: String,

    @field:Size(max = 500, message = "설명은 500자 이하여야 합니다")
    @field:Schema(description = "설명", example = "샘플 설명")
    val description: String? = null,

    @field:Schema(description = "카테고리 ID 목록", example = "[1, 2, 3]")
    val categoryIds: List<Long> = emptyList(),
)
```

### Update Request

```kotlin
data class Update{Entity}Request(
    @field:NotBlank(message = "이름은 필수입니다")
    @field:Size(max = 100, message = "이름은 100자 이하여야 합니다")
    @field:Schema(description = "이름", example = "수정된 이름", required = true)
    val name: String,

    @field:Size(max = 500, message = "설명은 500자 이하여야 합니다")
    @field:Schema(description = "설명", example = "수정된 설명")
    val description: String? = null,
)
```

### Search/Filter Request

```kotlin
data class Search{Entity}Request(
    @field:Schema(description = "검색 키워드")
    val keyword: String? = null,

    @field:Schema(description = "상태 필터", example = "ACTIVE")
    val status: {Entity}Status? = null,

    @field:Schema(description = "시작일", example = "2024-01-01")
    val startDate: LocalDate? = null,

    @field:Schema(description = "종료일", example = "2024-12-31")
    val endDate: LocalDate? = null,

    @field:Schema(description = "페이지 번호", example = "1", defaultValue = "1")
    val page: Int = 1,

    @field:Schema(description = "페이지 크기", example = "20", defaultValue = "20")
    val size: Int = 20,
)
```

---

## Response DTO Patterns

### Basic Response

```kotlin
data class {Entity}Response(
    @field:Schema(description = "ID")
    val id: Long,

    @field:Schema(description = "이름")
    val name: String,

    @field:Schema(description = "상태")
    val status: {Entity}Status,

    @field:Schema(description = "생성일시")
    val createdAt: LocalDateTime,

    @field:Schema(description = "수정일시")
    val updatedAt: LocalDateTime,
) {
    companion object {
        fun from(entity: {Entity}): {Entity}Response {
            return {Entity}Response(
                id = entity.id!!,
                name = entity.name,
                status = entity.status,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt,
            )
        }
    }
}
```

### List Item Response (목록용 간략 DTO)

```kotlin
data class {Entity}ListItem(
    @field:Schema(description = "ID")
    val id: Long,

    @field:Schema(description = "이름")
    val name: String,

    @field:Schema(description = "상태")
    val status: {Entity}Status,
) {
    companion object {
        fun from(entity: {Entity}): {Entity}ListItem {
            return {Entity}ListItem(
                id = entity.id!!,
                name = entity.name,
                status = entity.status,
            )
        }
    }
}
```

### Detail Response (상세 조회용)

```kotlin
data class {Entity}DetailResponse(
    @field:Schema(description = "ID")
    val id: Long,

    @field:Schema(description = "이름")
    val name: String,

    @field:Schema(description = "설명")
    val description: String?,

    @field:Schema(description = "관련 항목 목록")
    val items: List<ItemDto>,

    @field:Schema(description = "담당자 정보")
    val assignee: AdminUserDto?,

    @field:Schema(description = "생성일시")
    val createdAt: LocalDateTime,

    @field:Schema(description = "수정일시")
    val updatedAt: LocalDateTime,
) {
    companion object {
        fun from(entity: {Entity}): {Entity}DetailResponse {
            return {Entity}DetailResponse(
                id = entity.id!!,
                name = entity.name,
                description = entity.description,
                items = entity.items.map { ItemDto.from(it) },
                assignee = entity.adminUser?.let { AdminUserDto.from(it) },
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt,
            )
        }
    }
}
```

---

## Pagination Response

```kotlin
data class PageResponse<T>(
    @field:Schema(description = "데이터 목록")
    val content: List<T>,

    @field:Schema(description = "현재 페이지 (1-based)")
    val page: Int,

    @field:Schema(description = "페이지 크기")
    val size: Int,

    @field:Schema(description = "전체 항목 수")
    val totalElements: Long,

    @field:Schema(description = "전체 페이지 수")
    val totalPages: Int,

    @field:Schema(description = "첫 페이지 여부")
    val first: Boolean,

    @field:Schema(description = "마지막 페이지 여부")
    val last: Boolean,
) {
    companion object {
        fun <T, E> from(
            page: Page<E>,
            transform: (E) -> T,
        ): PageResponse<T> {
            return PageResponse(
                content = page.content.map(transform),
                page = page.number + 1,  // 0-based → 1-based
                size = page.size,
                totalElements = page.totalElements,
                totalPages = page.totalPages,
                first = page.isFirst,
                last = page.isLast,
            )
        }
    }
}

// 사용
@GetMapping
fun getAll(request: SearchRequest): PageResponse<{Entity}ListItem> {
    val page = service.findAll(request)
    return PageResponse.from(page) { {Entity}ListItem.from(it) }
}
```

---

## Nested DTO

연관 엔티티용 간략 DTO

```kotlin
// 담당자 정보 (AdminUser의 간략 버전)
data class AdminUserDto(
    @field:Schema(description = "ID")
    val id: Long,

    @field:Schema(description = "이름")
    val name: String,

    @field:Schema(description = "사용자명")
    val username: String,
) {
    companion object {
        fun from(entity: AdminUser): AdminUserDto {
            return AdminUserDto(
                id = entity.id!!,
                name = entity.name,
                username = entity.username,
            )
        }
    }
}

// 카테고리 정보
data class CategoryDto(
    @field:Schema(description = "ID")
    val id: Long,

    @field:Schema(description = "이름")
    val name: String,

    @field:Schema(description = "색상")
    val color: String,
) {
    companion object {
        fun from(entity: ConsultationCategory): CategoryDto {
            return CategoryDto(
                id = entity.id!!,
                name = entity.name,
                color = entity.color,
            )
        }
    }
}
```

---

## Validation Annotations Cheatsheet

```kotlin
// 필수값
@field:NotBlank(message = "필수 입력입니다")
@field:NotNull(message = "필수 입력입니다")
@field:NotEmpty(message = "하나 이상 선택해야 합니다")

// 길이/크기
@field:Size(min = 2, max = 100, message = "2~100자 사이여야 합니다")
@field:Min(value = 1, message = "1 이상이어야 합니다")
@field:Max(value = 100, message = "100 이하여야 합니다")

// 형식
@field:Email(message = "올바른 이메일 형식이 아닙니다")
@field:Pattern(regexp = "^010-\\d{4}-\\d{4}$", message = "올바른 전화번호 형식이 아닙니다")

// 양수
@field:Positive(message = "양수여야 합니다")
@field:PositiveOrZero(message = "0 이상이어야 합니다")

// 날짜
@field:Past(message = "과거 날짜여야 합니다")
@field:Future(message = "미래 날짜여야 합니다")
```

---

## Anti-Patterns

```kotlin
// ❌ Entity 직접 반환
@GetMapping("/{id}")
fun get(@PathVariable id: Long): Customer {  // Entity 노출
    return service.getById(id)
}

// ✅ Response DTO 반환
@GetMapping("/{id}")
fun get(@PathVariable id: Long): CustomerResponse {
    return CustomerResponse.from(service.getById(id))
}

// ❌ 생성자에서 변환
data class CustomerResponse(entity: Customer) {  // 생성자 파라미터로 Entity
    val id = entity.id!!
    val name = entity.name
}

// ✅ companion object의 from() 사용
data class CustomerResponse(
    val id: Long,
    val name: String,
) {
    companion object {
        fun from(entity: Customer): CustomerResponse { ... }
    }
}

// ❌ @Schema 누락
data class CustomerResponse(
    val id: Long,  // description 없음
    val name: String,
)

// ✅ @field:Schema 적용
data class CustomerResponse(
    @field:Schema(description = "고객 ID")
    val id: Long,

    @field:Schema(description = "고객 이름")
    val name: String,
)
```

---

## Quick Reference

| 상황 | 패턴 |
|------|------|
| Request → Service | 직접 전달 |
| Entity → Response | `Response.from(entity)` |
| 컬렉션 변환 | `.map { Dto.from(it) }` |
| nullable 변환 | `entity?.let { Dto.from(it) }` |
| Schema 적용 | `@field:Schema(description = "...")` |
| Validation | `@field:NotBlank`, `@field:Size`, etc. |
