# Spring annotations — what each one does

> Key idea: **an annotation is a passive label. It does nothing by itself.**
> Someone reads it and reacts. `@Override` → the compiler reads it.
> `@Repository` → the container reads it at startup. `@Transactional` → a proxy
> reads it at runtime.
>
> ✅ = appears in the talk / slides. ➕ = extra, popular, good to know.

---

## 1. Make a bean out of a class

**✅ `@Component`** — the base label. You put it on a class. At startup the container
scans the package, sees the label, and creates one bean from this class. All the labels
below are special cases of `@Component`.

**✅ `@Repository`** — same as `@Component` + means "data layer". You put it on a DAO.
**Bonus they ask about:** it translates low-level `SQLException` and Hibernate/JPA
exceptions into one common Spring hierarchy — `DataAccessException`. So your service
catches one type and does not depend on MySQL or Postgres.

**➕ `@Service`** — same as `@Component` + means "business logic layer". Technically no
difference from `@Component`, only meaning: you read the code and see the layer at once.

**➕ `@Controller`** — the web layer, handles HTTP requests (Spring MVC routes to it).

**➕ `@Bean`** — you put it on a **method** inside a `@Configuration` class: "what this
method returns is a bean". Why you need it if `@Component` exists: you can only put
`@Component` on **your own** class. If the bean must come from a **third-party** class
from a library (`DataSource`, `ObjectMapper`, `RestTemplate`), you have no access to the
source. Then you write a method and mark it `@Bean`.

---

## 2. Inject dependencies

**✅ `@Autowired`** — "inject a matching bean here". The search is **by type**. You can
put it on a constructor, a setter, or a field. Note: with **one** constructor you can
skip it — Spring understands (since 4.3).

**✅ `@Qualifier("h2DataSource")`** — when there are several beans of the same type, it
says which one you need. Choice **by bean name**. This is the choice of the consumer.

**✅ `@Primary`** — "if nobody says anything, take me". A default from the supplier. You
put it once on a bean; `@Qualifier` you put at every injection point. If both are
present, `@Qualifier` wins (it is more specific).

**✅ `@Profile("test")`** — the bean does **not** enter the container if the profile is
not active. You turn a profile on with `spring.profiles.active=test`. This is how the
prod database and the test database are switched.

**➕ `@Value("${db.url}")`** — inject one value from `application.properties`.

**➕ `@ConfigurationProperties(prefix = "app")`** — bind a **whole block** of settings to
an object, type-safe. Better than many `@Value` for a group of related properties.

---

## 3. Configuration

**✅ `@ComponentScan`** — "where to look for labelled classes". By default it scans the
package of the class itself and all sub-packages — that is why the main class goes into
the root package.

**➕ `@Configuration`** — a class that holds bean definitions (`@Bean` methods). Detail:
Spring wraps such a class in a proxy, so calling one `@Bean` method from another returns
the **same** singleton, not a new object.

---

## 4. Lifecycle

**✅ `@PostConstruct`** — the method runs **after** all dependencies are injected. Use it
to warm up a cache or open a connection. Why not in the constructor: with field or setter
injection the dependencies are still `null` while the constructor runs.

**➕ `@PreDestroy`** — runs before the bean is destroyed; release resources. Not called
for prototype beans or on a hard process kill.

**✅ `@Scope("prototype")`** — how many instances to keep. `singleton` (default, one per
container), `prototype` (a new one every time), `request` / `session` (web).

**➕ `@Lazy`** — create the bean not at startup, but on the first use.

---

## 5. Behaviour through a proxy

**✅ `@Transactional`** — Spring wraps the bean in a proxy: open a transaction before the
method, commit after it, roll back on an exception. Three traps they love to ask:
1. **self-invocation** — you call the method from inside the same class through `this`
   → the call goes around the proxy → no transaction;
2. by default rollback only on `RuntimeException` (unchecked); on checked exceptions it
   commits, unless you set `rollbackFor`;
3. the method must be `public`.
The same proxy mechanism (and the same self-invocation trap) drives `@Async` and
`@Cacheable`.

---

## 6. Spring Boot

**✅ `@SpringBootApplication`** — three in one:
`@Configuration` + `@ComponentScan` + `@EnableAutoConfiguration`.

**✅ `@EnableAutoConfiguration`** — the auto part: it looks at the classpath and
configures beans. Sees a database driver → configures a `DataSource`. Sees a web starter
→ starts an embedded Tomcat.

---

## 7. Not Spring, but present in the talk

**✅ `@Override`** — read by the **compiler**, not by Spring. In the talk it is the
analogy: a label does nothing by itself, someone reads it.

**✅ `@RequiredArgsConstructor`** — this is **Lombok**, not Spring. It generates a
constructor for all `final` fields, so you do not write it by hand. `private final` +
this annotation = constructor injection in production.

---

## 8. Extra popular ones (web / test / async)

**Web / REST**
- **`@RestController`** = `@Controller` + `@ResponseBody` (returns data, not a page name).
- **`@GetMapping` / `@PostMapping` / `@PutMapping` / `@DeleteMapping`** — bind a method to
  an HTTP method and a URL.
- **`@PathVariable`** — a part of the URL into a parameter (`/users/{id}`).
- **`@RequestParam`** — a query parameter (`?page=2`).
- **`@RequestBody`** — the request body (JSON) into an object.
- **`@Valid`** — turn on validation of the incoming object.

**Tests**
- **`@SpringBootTest`** — start the whole context (integration test).
- **`@DataJpaTest` / `@WebMvcTest`** — start only the data layer / only the web layer. Faster.
- **`@MockitoBean`** — replace a bean in the context with a mock (was `@MockBean`, deprecated in Boot 3.4).

**Async / schedule / cache** (all work through a proxy → same self-invocation trap)
- **`@Async`** (+ `@EnableAsync`) — run the method in a separate thread.
- **`@Scheduled`** (+ `@EnableScheduling`) — run on a schedule (cron).
- **`@Cacheable`** (+ `@EnableCaching`) — cache the result of the method.

---

## One sentence for the interview

An annotation is always a **passive label** — it does nothing. The work is done by
whoever reads it: `@Override` → the compiler, `@Repository` → the container at startup,
`@Transactional` → the proxy at runtime. And `@Transactional`, `@Async`, `@Cacheable`
all work through proxies, so they share the same `this.method()` trap — understand the
mechanism once, and you answer four questions at once.
