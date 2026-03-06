---
name: kotest-behaviorspec
description: Kotest BehaviorSpec 기반 테스트 작성 가이드. Spring Boot 통합 테스트, E2E 테스트, Repository 테스트 패턴. 테스트 작성/수정 시 자동 활성화. Kotest, BehaviorSpec, 테스트, test 언급 시 트리거.
allowed-tools: Read, Write, Grep, Edit
---

# Kotest BehaviorSpec Test Skill

Kotest BehaviorSpec을 사용한 Spring Boot 테스트 작성 가이드.

## When I Activate

- 테스트 코드 작성 요청 시
- 기존 테스트 수정/추가 시
- Kotest, BehaviorSpec 관련 질문
- 통합 테스트, E2E 테스트 작성 시
- Repository, Service 테스트 작성 시

## Test File Structure

```
src/test/kotlin/com/ifamilysc/romandcx/
├── e2e/              # E2E 테스트 (MockMvc + Testcontainers)
├── service/          # Service 통합 테스트
├── repository/
│   └── internal/     # Repository 테스트
└── unit/             # 유닛 테스트
```

---

## Base Classes

### 1. SpringBehaviorSpec (기본 Spring 테스트)

```kotlin
abstract class SpringBehaviorSpec(
    body: SpringBehaviorSpec.() -> Unit = {}
) : BehaviorSpec(), SpringListener {
    override fun listeners() = listOf(SpringExtension)
}
```

### 2. SpringIntegrationBehaviorSpec (통합 테스트)

```kotlin
@SpringBootTest
@Import(TestcontainersConfiguration::class)
@Transactional
abstract class SpringIntegrationBehaviorSpec(
    body: SpringIntegrationBehaviorSpec.() -> Unit = {}
) : BehaviorSpec(), SpringListener {
    override fun listeners() = listOf(SpringExtension)
}
```

### 3. SpringE2EBehaviorSpec (E2E 테스트)

```kotlin
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestcontainersConfiguration::class)
@AutoConfigureMockMvc
abstract class SpringE2EBehaviorSpec(
    body: SpringE2EBehaviorSpec.() -> Unit = {}
) : BehaviorSpec(), SpringListener {
    override fun listeners() = listOf(SpringExtension)
}
```

---

## Pattern 1: Repository Test

```kotlin
@DataJpaTest
@Import(TestcontainersConfiguration::class, QueryDslConfig::class)
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Transactional(propagation = Propagation.NOT_SUPPORTED)
class CustomerRepositoryTest(
    private val customerRepository: CustomerRepository,
) : SpringBehaviorSpec({

    beforeTest {
        customerRepository.deleteAll()
    }

    given("고객 데이터가 존재할 때") {
        beforeTest {
            customerRepository.saveAll(listOf(
                Customer(name = "홍길동", phone = "010-1234-5678"),
                Customer(name = "김철수", phone = "010-8765-4321"),
            ))
        }

        `when`("이름으로 검색하면") {
            then("해당 고객이 조회된다") {
                val command = PageCustomerCommand(
                    pageRequest = PageRequest(page = 1, size = 10, keyword = "홍길동"),
                )

                val result = customerRepository.findAllByPage(command)

                result.content.shouldHaveSize(1)
                result.content[0].name shouldBe "홍길동"
            }
        }

        `when`("전화번호로 검색하면") {
            then("해당 고객이 조회된다") {
                val result = customerRepository.findByPhone("010-1234-5678")

                result shouldNotBe null
                result!!.name shouldBe "홍길동"
            }
        }
    }

    given("고객이 없을 때") {
        then("빈 결과가 반환된다") {
            val command = PageCustomerCommand(
                pageRequest = PageRequest(page = 1, size = 10),
            )

            val result = customerRepository.findAllByPage(command)

            result.content.shouldBeEmpty()
        }
    }
})
```

---

## Pattern 2: Service Integration Test

```kotlin
class ConsultationCategoryServiceCacheTest(
    private val consultationCategoryService: ConsultationCategoryService,
    private val consultationCategoryRepository: ConsultationCategoryRepository,
    private val cacheManager: CacheManager,
    private val redisTemplate: StringRedisTemplate,
    private val environment: Environment,
) : SpringIntegrationBehaviorSpec({

    val cacheName = "consultation-categories"
    val activeProfile = environment.activeProfiles.firstOrNull() ?: "default"
    val cacheKeyPrefix = "cx:$activeProfile:"

    beforeTest {
        cacheManager.getCache(cacheName)?.clear()
        consultationCategoryRepository.deleteAll()
    }

    given("getAllCategories() 호출") {
        `when`("처음 호출하면") {
            then("캐시에 저장된다") {
                // given
                consultationCategoryService.create(
                    CreateCategoryCommand(name = "테스트 카테고리", color = "#FF0000"),
                )

                // when
                val firstResult = consultationCategoryService.getAllCategories()

                // then
                val keys = redisTemplate.keys("$cacheKeyPrefix$cacheName*")
                keys shouldNotBe null
                keys!!.size shouldBe 1
                firstResult.shouldHaveSize(1)
                firstResult[0].name shouldBe "테스트 카테고리"
            }
        }
    }

    given("create 호출") {
        then("캐시가 클리어된다") {
            // given
            consultationCategoryService.create(
                CreateCategoryCommand(name = "카테고리1", color = "#FF0000"),
            )
            consultationCategoryService.getAllCategories()  // 캐시 생성

            // when
            consultationCategoryService.create(
                CreateCategoryCommand(name = "카테고리2", color = "#00FF00"),
            )

            // then
            val result = consultationCategoryService.getAllCategories()
            result.shouldHaveSize(2)
        }
    }
})
```

---

## Pattern 3: E2E Test (MockMvc)

```kotlin
class AuthControllerE2ETest(
    private val mockMvc: MockMvc,
    private val objectMapper: ObjectMapper,
    private val adminUserRepository: AdminUserRepository,
    private val passwordEncoder: PasswordEncoder,
) : SpringE2EBehaviorSpec({

    beforeTest {
        adminUserRepository.deleteAll()
        adminUserRepository.save(
            AdminUser(
                username = "testuser",
                password = passwordEncoder.encode("password123"),
                name = "테스트 사용자",
                role = Role.ADMIN,
            )
        )
    }

    given("로그인 API") {
        `when`("올바른 자격 증명으로 요청하면") {
            then("200 OK와 사용자 정보를 반환한다") {
                val request = LoginRequest(
                    username = "testuser",
                    password = "password123",
                )

                mockMvc.post("/api/v1/auth/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.username") { value("testuser") }
                    jsonPath("$.name") { value("테스트 사용자") }
                }
            }
        }

        `when`("잘못된 비밀번호로 요청하면") {
            then("401 Unauthorized를 반환한다") {
                val request = LoginRequest(
                    username = "testuser",
                    password = "wrongpassword",
                )

                mockMvc.post("/api/v1/auth/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(request)
                }.andExpect {
                    status { isUnauthorized() }
                }
            }
        }
    }

    given("인증된 사용자") {
        `when`("me API를 호출하면") {
            then("현재 사용자 정보를 반환한다") {
                // 로그인
                val loginRequest = LoginRequest("testuser", "password123")
                val loginResult = mockMvc.post("/api/v1/auth/login") {
                    contentType = MediaType.APPLICATION_JSON
                    content = objectMapper.writeValueAsString(loginRequest)
                }.andReturn()

                val sessionCookie = loginResult.response.getCookie("SESSION")

                // me 호출
                mockMvc.get("/api/v1/auth/me") {
                    cookie(sessionCookie!!)
                }.andExpect {
                    status { isOk() }
                    jsonPath("$.username") { value("testuser") }
                }
            }
        }
    }
})
```

---

## Pattern 4: Unit Test

```kotlin
@Execution(ExecutionMode.CONCURRENT)  // 병렬 실행 가능
class PhoneNumberFormatterTest : BehaviorSpec({

    given("전화번호 포맷터") {
        `when`("11자리 숫자가 주어지면") {
            then("하이픈이 포함된 형식으로 변환한다") {
                val result = "01012345678".toPhoneNumber()
                result shouldBe "010-1234-5678"
            }
        }

        `when`("이미 하이픈이 포함되어 있으면") {
            then("그대로 반환한다") {
                val result = "010-1234-5678".toPhoneNumber()
                result shouldBe "010-1234-5678"
            }
        }

        `when`("숫자가 아닌 문자가 포함되면") {
            then("숫자만 추출하여 변환한다") {
                val result = "010 1234 5678".toPhoneNumber()
                result shouldBe "010-1234-5678"
            }
        }
    }
})
```

---

## Kotest Matchers Cheatsheet

```kotlin
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldStartWith
import io.kotest.matchers.longs.shouldBeBetween
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.assertions.throwables.shouldThrow

// 기본 비교
result shouldBe "expected"
result shouldNotBe null

// 컬렉션
list.shouldHaveSize(3)
list.shouldBeEmpty()
list shouldContain "item"
list.shouldContainAll("a", "b", "c")

// 문자열
str shouldContain "substring"
str shouldStartWith "prefix"

// 숫자 범위
number.shouldBeBetween(1L, 100L)

// Null 체크
value.shouldBeNull()
value.shouldNotBeNull()

// 예외
shouldThrow<IllegalArgumentException> {
    doSomething()
}
```

---

## BDD Style Guide

```kotlin
given("테스트 컨텍스트/시나리오 설명") {
    // 테스트 데이터 설정 (beforeTest)

    `when`("특정 조건/액션") {  // 선택사항
        then("예상 결과") {
            // given - 추가 설정
            // when - 실행
            // then - 검증
        }
    }

    then("직접 결과 검증") {  // when 없이도 사용 가능
        // 테스트 로직
    }
}
```

---

## Test Isolation

### E2E/통합 테스트 (순차 실행)

```kotlin
@SpringBootTest
@Transactional  // DB 자동 롤백
@Execution(ExecutionMode.SAME_THREAD)  // 순차 실행
class MyIntegrationTest : SpringIntegrationBehaviorSpec({

    beforeTest {
        // Redis 등 공유 자원 정리
        redisTemplate.delete(redisTemplate.keys("*") ?: emptySet())
    }
})
```

### 유닛 테스트 (병렬 실행)

```kotlin
@Execution(ExecutionMode.CONCURRENT)  // 병렬 실행
class MyUnitTest : BehaviorSpec({
    // 외부 자원 없이 순수 로직만 테스트
})
```

---

## Common Imports

```kotlin
// Kotest
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.collections.shouldHaveSize

// Spring Test
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post

// JUnit (병렬 실행)
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
```

---

## References

- [Kotest BehaviorSpec](https://kotest.io/docs/framework/testing-styles.html#behavior-spec)
- [Kotest Matchers](https://kotest.io/docs/assertions/core-matchers.html)
- [Spring Boot Testing](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.testing)
