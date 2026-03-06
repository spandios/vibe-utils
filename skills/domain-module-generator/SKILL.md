---
name: domain-module-generator
description: Spring Boot + Kotlin 도메인 모듈 생성 가이드. Domain-Centric Layered Architecture 패턴. 새 도메인/기능 추가 시 자동 활성화. 모듈, 도메인, 엔티티 생성 언급 시 트리거.
allowed-tools: Read, Write, Grep, Edit
---

# Domain Module Generator Skill

Spring Boot + Kotlin 프로젝트의 Domain-Centric Layered Architecture에 맞는 도메인 모듈 생성 가이드.

## When I Activate

- 새로운 도메인/엔티티 추가 요청 시
- 새로운 API 엔드포인트 생성 시
- 모듈 구조 관련 질문
- "~를 만들어줘", "~ 기능 추가해줘" 요청 시

## Recommended Package Structure

```
com.example.app/
├── {domain}/                  # 도메인 모듈
│   ├── {Entity}.kt           # Entity
│   ├── {Entity}Repository.kt # Repository
│   ├── {Entity}Service.kt    # Service
│   ├── api/                  # REST API 레이어
│   │   ├── {Entity}Controller.kt
│   │   └── dto/
│   │       ├── {Entity}Request.kt
│   │       └── {Entity}Response.kt
│   ├── event/                # 도메인 이벤트 (선택)
│   ├── query/                # QueryDSL Projection (선택)
│   └── repository/           # QueryDSL 커스텀 구현 (선택)
│       ├── {Entity}RepositoryCustom.kt
│       └── {Entity}RepositoryImpl.kt
│
├── common/                   # 공통 모듈
│   ├── entity/              # Base Entity 클래스
│   ├── exception/           # 예외 처리
│   └── dto/                 # 공통 DTO
└── infrastructure/           # 인프라 레이어
    └── config/              # 설정 클래스
```

---

## Step 1: Entity 생성

```kotlin
// src/main/kotlin/com/example/app/{domain}/{Entity}.kt

package com.example.app.{domain}

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "{table_name}")
class {Entity}(

    @Column(nullable = false)
    var name: String,

    @Column(length = 500)
    var description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: {Entity}Status = {Entity}Status.ACTIVE,

    // N:1 관계
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    var user: User? = null,

    // 1:N 관계
    @OneToMany(mappedBy = "{entity}", cascade = [CascadeType.ALL], orphanRemoval = true)
    val items: MutableList<{Entity}Item> = mutableListOf(),

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @Column(nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),

) {

    // 비즈니스 메서드
    fun update(name: String, description: String?) {
        this.name = name
        this.description = description
        this.updatedAt = LocalDateTime.now()
    }

    fun addItem(item: {Entity}Item) {
        items.add(item)
        item.{entity} = this
    }

    @PreUpdate
    fun preUpdate() {
        updatedAt = LocalDateTime.now()
    }
}

enum class {Entity}Status {
    ACTIVE, INACTIVE
}
```

### Base Entity 패턴 (선택)

```kotlin
// common/entity/TimestampEntity.kt
@MappedSuperclass
abstract class TimestampEntity {
    @Column(nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now()

    @Column(nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now()
        protected set

    @PreUpdate
    fun preUpdate() {
        updatedAt = LocalDateTime.now()
    }
}

// 사용
@Entity
class {Entity}(...) : TimestampEntity()
```

---

## Step 2: Repository 생성

### 기본 Repository

```kotlin
// src/main/kotlin/com/example/app/{domain}/{Entity}Repository.kt

package com.example.app.{domain}

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.EntityGraph
import java.util.Optional

interface {Entity}Repository : JpaRepository<{Entity}, Long> {

    // N:1 관계 즉시 로딩
    @EntityGraph(attributePaths = ["user"])
    override fun findById(id: Long): Optional<{Entity}>

    @EntityGraph(attributePaths = ["user"])
    fun findAllByStatusOrderByCreatedAtDesc(status: {Entity}Status): List<{Entity}>

    fun existsByName(name: String): Boolean
}
```

### QueryDSL 커스텀 Repository (복잡한 쿼리)

```kotlin
// repository/{Entity}RepositoryCustom.kt
interface {Entity}RepositoryCustom {
    fun findAllByPage(command: Page{Entity}Command): Page<{Entity}>
}

// repository/{Entity}RepositoryImpl.kt
@Repository
class {Entity}RepositoryImpl(
    private val queryFactory: JPAQueryFactory,
) : {Entity}RepositoryCustom {

    override fun findAllByPage(command: Page{Entity}Command): Page<{Entity}> {
        val {entity} = Q{Entity}.{entity}

        val query = queryFactory
            .selectFrom({entity})
            .where(
                command.keyword?.let {
                    {entity}.name.containsIgnoreCase(it)
                }
            )
            .orderBy({entity}.createdAt.desc())

        val total = query.fetch().size.toLong()
        val content = query
            .offset(command.offset)
            .limit(command.limit)
            .fetch()

        return PageImpl(content, command.pageable, total)
    }
}

// Repository에 커스텀 인터페이스 상속 추가
interface {Entity}Repository : JpaRepository<{Entity}, Long>, {Entity}RepositoryCustom
```

---

## Step 3: Service 생성

```kotlin
// src/main/kotlin/com/example/app/{domain}/{Entity}Service.kt

package com.example.app.{domain}

import com.example.app.{domain}.api.dto.Create{Entity}Request
import com.example.app.{domain}.api.dto.Update{Entity}Request
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class {Entity}Service(
    private val repository: {Entity}Repository,
) {

    fun getById(id: Long): {Entity} {
        return repository.findById(id)
            .orElseThrow { IllegalArgumentException("{Entity} not found: $id") }
    }

    fun getAll(): List<{Entity}> {
        return repository.findAllByStatusOrderByCreatedAtDesc({Entity}Status.ACTIVE)
    }

    @Transactional
    fun create(request: Create{Entity}Request): {Entity} {
        validateDuplicate(request.name)

        val entity = {Entity}(
            name = request.name,
            description = request.description,
        )

        return repository.save(entity)
    }

    @Transactional
    fun update(id: Long, request: Update{Entity}Request): {Entity} {
        val entity = getById(id)

        if (entity.name != request.name) {
            validateDuplicate(request.name)
        }

        entity.update(
            name = request.name,
            description = request.description,
        )

        return entity
    }

    @Transactional
    fun delete(id: Long) {
        val entity = getById(id)
        entity.status = {Entity}Status.INACTIVE
    }

    private fun validateDuplicate(name: String) {
        if (repository.existsByName(name)) {
            throw IllegalArgumentException("이미 존재하는 이름입니다: $name")
        }
    }
}
```

---

## Step 4: Controller + DTO 생성

### Controller

```kotlin
// src/main/kotlin/com/example/app/{domain}/api/{Entity}Controller.kt

package com.example.app.{domain}.api

import com.example.app.{domain}.{Entity}Service
import com.example.app.{domain}.api.dto.*
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/v1/{entities}")
@Tag(name = "{Entity} 관리", description = "{Entity} CRUD API")
class {Entity}Controller(
    private val service: {Entity}Service,
) {

    @GetMapping
    @Operation(summary = "{Entity} 목록 조회")
    fun getAll(): List<{Entity}Response> {
        return service.getAll().map { {Entity}Response.from(it) }
    }

    @GetMapping("/{id}")
    @Operation(summary = "{Entity} 상세 조회")
    fun getById(@PathVariable id: Long): {Entity}Response {
        return {Entity}Response.from(service.getById(id))
    }

    @PostMapping
    @Operation(summary = "{Entity} 생성")
    fun create(@Valid @RequestBody request: Create{Entity}Request): {Entity}Response {
        return {Entity}Response.from(service.create(request))
    }

    @PutMapping("/{id}")
    @Operation(summary = "{Entity} 수정")
    fun update(
        @PathVariable id: Long,
        @Valid @RequestBody request: Update{Entity}Request,
    ): {Entity}Response {
        return {Entity}Response.from(service.update(id, request))
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "{Entity} 삭제")
    fun delete(@PathVariable id: Long) {
        service.delete(id)
    }
}
```

### Request DTO

```kotlin
// api/dto/Create{Entity}Request.kt
data class Create{Entity}Request(
    @field:NotBlank(message = "이름은 필수입니다")
    @field:Size(max = 100, message = "이름은 100자 이하여야 합니다")
    @field:Schema(description = "이름", example = "샘플 이름")
    val name: String,

    @field:Size(max = 500, message = "설명은 500자 이하여야 합니다")
    @field:Schema(description = "설명", example = "샘플 설명")
    val description: String? = null,
)

// api/dto/Update{Entity}Request.kt
data class Update{Entity}Request(
    @field:NotBlank(message = "이름은 필수입니다")
    @field:Size(max = 100, message = "이름은 100자 이하여야 합니다")
    @field:Schema(description = "이름", example = "수정된 이름")
    val name: String,

    @field:Size(max = 500, message = "설명은 500자 이하여야 합니다")
    @field:Schema(description = "설명", example = "수정된 설명")
    val description: String? = null,
)
```

### Response DTO

```kotlin
// api/dto/{Entity}Response.kt
data class {Entity}Response(
    @field:Schema(description = "ID")
    val id: Long,

    @field:Schema(description = "이름")
    val name: String,

    @field:Schema(description = "설명")
    val description: String?,

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
                description = entity.description,
                status = entity.status,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt,
            )
        }
    }
}
```

---

## Layer Responsibilities

| Layer | 책임 | 어노테이션 |
|-------|------|-----------|
| **Entity** | 비즈니스 개념, 데이터 + 간단한 검증 | `@Entity` |
| **Repository** | 데이터 접근, 쿼리 | `JpaRepository`, `@EntityGraph` |
| **Service** | 비즈니스 로직, 트랜잭션 | `@Service`, `@Transactional` |
| **Controller** | HTTP 요청/응답, DTO 변환 | `@RestController` |

---

## Checklist

새 도메인 모듈 생성 시:

- [ ] Entity 생성 (timestamp 필드 포함)
- [ ] Repository 생성 (@EntityGraph 적용)
- [ ] Service 생성 (@Transactional 적용)
- [ ] Controller 생성 (REST API)
- [ ] Request/Response DTO 생성
- [ ] (선택) QueryDSL 커스텀 Repository 추가
- [ ] (선택) 도메인 이벤트 추가
- [ ] 테스트 코드 작성

---

## Package Naming Rules

- 패키지명에 **대시(-) 사용 불가** (Java 식별자 규칙)
- 복합 단어는 **언더스코어(_)** 로 구분
- 예: `representative_number`, `extension_number`
- 또는 소문자로 연결: `representativenumber`
