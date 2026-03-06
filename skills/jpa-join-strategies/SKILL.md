---
name: jpa-join-strategies
description: Spring Data JPA/Hibernate 조인 전략 가이드. N+1 문제 방지, EntityGraph, Batch Fetch, 페이지네이션 조인 패턴. Repository/Service 코드 작성 시 자동 활성화. JPA, Hibernate, 연관관계, fetch join 언급 시 트리거.
allowed-tools: Read, Write, Grep, Edit
---

# JPA Join Strategies Skill

Spring Data JPA/Hibernate에서 연관관계 로딩 최적화를 위한 조인 전략 가이드.

## When I Activate

- Repository 또는 Service에서 연관 엔티티 조회 로직 작성 시
- N+1 문제 언급 또는 발견 시
- @EntityGraph, fetch join, batch fetch 관련 질문
- 페이지네이션 + 조인 쿼리 작성 시
- LAZY 로딩 관련 에러 발생 시 (LazyInitializationException)

## Core Configuration

```yaml
spring.jpa:
  open-in-view: false  # OSIV 비활성화 (필수)
  properties.hibernate:
    default_batch_fetch_size: 100  # Batch fetch 크기
    enable_lazy_load_no_trans: false  # 트랜잭션 밖 LAZY 로딩 금지
```

---

## 조인 전략 선택 가이드

### 관계 유형별 전략

| 관계 | 페이지네이션 | 권장 전략 | 이유 |
|------|-------------|-----------|------|
| N:1, 1:1 | 무관 | `@EntityGraph` 또는 `JOIN FETCH` | row 증가 없음 |
| 1:N | 없음 | `@EntityGraph` 또는 `JOIN FETCH` | 안전 |
| 1:N | 있음 | Batch Fetch (별도 IN 쿼리) | row 폭발 방지 |
| 다중 컬렉션 | 무관 | Batch Fetch | Cartesian Product 방지 |

---

## Pattern 1: @EntityGraph (N:1, 1:1 관계)

**사용 시점**: 항상 함께 로딩해야 하는 N:1, 1:1 관계

```kotlin
// Repository
interface ExtensionNumberRepository : JpaRepository<ExtensionNumber, Long> {

    // N:1 관계 (ExtensionNumber → AdminUser)
    @EntityGraph(attributePaths = ["adminUser"])
    fun findAllByOrderByExtensionNumberAsc(): List<ExtensionNumber>
}

interface AdminUserRepository : JpaRepository<AdminUser, Long> {

    // 1:1 관계 (AdminUser ↔ ExtensionNumber)
    @EntityGraph(attributePaths = ["extensionNumber"])
    override fun findAll(): List<AdminUser>
}
```

**실행 SQL**: LEFT JOIN으로 1개 쿼리
```sql
SELECT e.*, a.* FROM extension_number e
LEFT JOIN admin_user a ON e.admin_user_id = a.id
```

---

## Pattern 2: @Query + JOIN FETCH (복합 조건)

**사용 시점**: 복잡한 조건과 함께 연관 엔티티 로딩

```kotlin
interface ConsultationRepository : JpaRepository<Consultation, Long> {

    @Query("""
        SELECT c FROM Consultation c
        JOIN FETCH c.counselor
        LEFT JOIN FETCH c.customer
        WHERE c.id = :id
    """)
    fun findDetailById(id: Long): Optional<Consultation>
}
```

**주의**: 1:N 컬렉션은 JOIN FETCH 하지 않음 (Batch Fetch 활용)

---

## Pattern 3: Batch Fetch (1:N, 다중 컬렉션)

**사용 시점**: 상세 조회에서 여러 컬렉션 로딩

```kotlin
// Entity - 컬렉션은 LAZY 유지
@Entity
class Consultation(
    @OneToMany(mappedBy = "consultation", fetch = FetchType.LAZY)
    val categories: MutableSet<ConsultationCategory> = mutableSetOf(),

    @OneToMany(mappedBy = "consultation", fetch = FetchType.LAZY)
    val histories: MutableList<ConsultationHistory> = mutableListOf()
)

// Service - 트랜잭션 내에서 접근 시 batch fetch 발동
@Service
@Transactional(readOnly = true)
class ConsultationService(
    private val repository: ConsultationRepository
) {
    fun getDetail(id: Long): Consultation {
        val consultation = repository.findDetailById(id).orElseThrow()

        // Batch fetch 발동 (IN 절로 로딩)
        consultation.categories.size
        consultation.histories.size

        return consultation
    }
}
```

**실행 SQL**: 총 3-4개 쿼리 (Cartesian Product 방지)
```sql
-- 1. 메인 + N:1
SELECT c.*, counselor.*, customer.* FROM consultation c ...

-- 2. categories (batch)
SELECT * FROM consultation_categories WHERE consultation_id IN (1)

-- 3. histories (batch)
SELECT * FROM consultation_history WHERE consultation_id IN (1)
```

---

## Pattern 4: 페이지네이션 + 1:N 관계

**핵심 원칙**: 1:N 관계는 절대 JOIN FETCH 하지 않음

```kotlin
// Repository - Projection + N:1만 JOIN
class ConsultationRepositoryImpl(
    private val queryFactory: JPAQueryFactory
) : ConsultationRepositoryCustom {

    override fun findAllByPage(command: PageCommand): Page<ConsultationListDto> {
        val consultation = QConsultation.consultation
        val counselor = QAdminUser.adminUser
        val customer = QCustomer.customer

        val content = queryFactory
            .select(QConsultationListDto(
                consultation.id,
                consultation.type,
                counselor.name,
                customer.name
            ))
            .from(consultation)
            .innerJoin(consultation.counselor, counselor)  // N:1 (NOT NULL)
            .leftJoin(consultation.customer, customer)      // N:1 (nullable)
            // categories는 JOIN 하지 않음 (1:N)
            .offset(command.offset)
            .limit(command.limit)
            .fetch()

        return PageImpl(content, command.pageable, total)
    }
}

// 컬렉션은 별도 IN 쿼리로 로딩
fun findCategoriesByConsultationIds(ids: List<Long>): Map<Long, List<Category>> {
    return queryFactory
        .select(consultation.id, category)
        .from(consultation)
        .join(consultation.categories, category)
        .where(consultation.id.`in`(ids))
        .fetch()
        .groupBy({ it.get(consultation.id)!! }, { it.get(category)!! })
}
```

---

## Pattern 5: LAZY Collection 초기화

**핵심 원칙**: 엔티티를 반환하는 모든 `@Transactional` 메서드는 반환 전에 LAZY 컬렉션 초기화

### Extension Function 활용 (권장)

```kotlin
// common/util/JpaExtensions.kt
fun initializeLazyCollections(vararg collections: Collection<*>) {
    collections.forEach { it.size }  // batch fetch 발동
}

// Entity별 extension 함수
fun Consultation.initializeLazyCollections() {
    initializeLazyCollections(categories, histories)
}

fun Customer.initializeLazyCollections() {
    initializeLazyCollections(consultations, addresses)
}
```

### Service에서 사용

```kotlin
@Service
@Transactional
class ConsultationService(
    private val repository: ConsultationRepository
) {
    fun getDetailById(id: Long): Consultation {
        val consultation = repository.findDetailById(id).orElseThrow()
        consultation.initializeLazyCollections()  // 트랜잭션 내에서 초기화
        return consultation
    }

    fun create(request: CreateRequest): Consultation {
        val saved = repository.save(Consultation(...))
        saved.initializeLazyCollections()  // 새로 생성한 엔티티도 초기화
        return saved
    }

    fun update(id: Long, request: UpdateRequest): Consultation {
        val consultation = getById(id)
        consultation.initializeLazyCollections()
        consultation.update(...)
        return consultation
    }
}
```

### 초기화 체크리스트

- [ ] 엔티티를 반환하는 모든 Service 메서드 확인
- [ ] Controller에서 DTO 변환 시 컬렉션 접근 여부 확인
- [ ] 트랜잭션 내에서 `.initializeLazyCollections()` 호출
- [ ] Entity의 비즈니스 메서드에서 컬렉션 접근 시 초기화 필요

---

## Anti-Patterns (금지 패턴)

### 1. 페이지네이션 + 1:N JOIN FETCH

```kotlin
// ❌ 금지: row 폭발로 페이지네이션 오작동
@Query("""
    SELECT c FROM Consultation c
    JOIN FETCH c.categories  -- 1:N 컬렉션!
""")
fun findAllWithCategories(pageable: Pageable): Page<Consultation>

// ✅ 해결: 별도 쿼리로 분리
fun findAll(pageable: Pageable): Page<Consultation>
fun findCategoriesByConsultationIds(ids: List<Long>): Map<Long, List<Category>>
```

### 2. 다중 컬렉션 JOIN FETCH

```kotlin
// ❌ 금지: Cartesian Product 발생
@Query("""
    SELECT c FROM Consultation c
    JOIN FETCH c.categories
    JOIN FETCH c.histories
""")
fun findWithAllCollections(id: Long): Consultation

// ✅ 해결: Batch Fetch 활용
@Query("""
    SELECT c FROM Consultation c
    JOIN FETCH c.counselor
    WHERE c.id = :id
""")
fun findDetailById(id: Long): Consultation
// categories, histories는 batch fetch로 자동 로딩
```

### 3. 트랜잭션 밖에서 LAZY 접근

```kotlin
// ❌ 금지: LazyInitializationException 발생
@GetMapping("/{id}")
fun get(@PathVariable id: Long): ConsultationDto {
    val consultation = service.getById(id)  // 트랜잭션 종료
    return ConsultationDto(
        categories = consultation.categories.map { ... }  // 에러!
    )
}

// ✅ 해결: Service에서 초기화 후 반환
@Service
@Transactional(readOnly = true)
class ConsultationService {
    fun getById(id: Long): Consultation {
        val c = repository.findById(id).orElseThrow()
        c.initializeLazyCollections()  // 트랜잭션 내에서 초기화
        return c
    }
}
```

---

## Quick Reference

```kotlin
// N:1 관계 → @EntityGraph
@EntityGraph(attributePaths = ["counselor", "customer"])
fun findById(id: Long): Optional<Consultation>

// 복합 조건 → @Query + JOIN FETCH
@Query("SELECT c FROM Consultation c JOIN FETCH c.counselor WHERE c.type = :type")
fun findByType(type: ConsultationType): List<Consultation>

// 1:N + 페이지네이션 → QueryDSL + 별도 IN 쿼리
// 메인 쿼리에서 N:1만 조인, 컬렉션은 ID로 별도 조회

// 상세 조회 → N:1 FETCH + 컬렉션 Batch
// JOIN FETCH로 N:1 로딩, 컬렉션은 접근 시 자동 batch
```

---

## References

- [Hibernate Batch Fetching](https://docs.jboss.org/hibernate/orm/current/userguide/html_single/Hibernate_User_Guide.html#fetching-batch)
- [Spring Data JPA EntityGraph](https://docs.spring.io/spring-data/jpa/reference/jpa/entity-graph.html)
