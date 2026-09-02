# DAO 层测试模式

## 适用判定

- **JPA 仓库接口**（`JpaRepository` 派生）：样板，单独测价值低，跳过；有自定义 JPQL 的可用轻量切片集成测试
- **JdbcTemplate 实现**（动态 SQL、批量、原生查询）：重点，尤其是手写 SQL 多分支的类

## 第一层：SQL 组装单测（mock，性价比最高）

DAO 把 SQL 构建做成包级私有方法时直接断言；public 方法用 mock 捕获执行的 SQL 与参数：

```java
@ExtendWith(MockitoExtension.class)
abstract class XxxDaoTestSupport {
    @InjectMocks protected XxxDao dao;
    @Mock protected JdbcTemplate jdbcTemplate;
    @Mock protected NamedParameterJdbcTemplate namedJdbcTemplate;
}
```

- 捕获 SQL：`ArgumentCaptor<String>` + `verify(template).query(captor.capture(), ...)`
- 捕获参数：`ArgumentCaptor<Object[]>`；NamedParameter 用 `SqlParameterSource`（`getValues()`）
- 断言用 `contains`/`endsWith` 片段而非整串等值，避免脆
- 窗口函数/CTE/LIKE 转义等复杂片段单独建用例

### 关键坑

- `NamedParameterJdbcTemplate.query(String, SqlParameterSource, RowMapper)` 内部调用的是
  `JdbcOperations.query(PreparedStatementCreator, RowMapper)` 重载，mock 要打对方法
- 参数名解析：`MethodParameter.getParameterName()` 可能返回 null，用
  `DefaultParameterNameDiscoverer` 兜底（controller 守卫同款问题）
- 动态 SQL 里的字符串拼接（如 `LIKE '%' + escaped + '%'`）断言时要按真实转义结果写

## 第二层：真实引擎冒烟（Testcontainers，可选但推荐）

验证 mock 测不到的执行层：语法、表列存在性、参数绑定、行映射（BeanPropertyRowMapper 的 snake_case→camelCase）。

- **MySQL**：官方模块 `org.testcontainers:mysql`，`AbstractMySqlContainerTest` 基座（singleton 容器 + 真实 DDL 初始化）
- **ClickHouse**：无官方模块，用 `GenericContainer` + `clickhouse/clickhouse-server`
  - 必须设 `CLICKHOUSE_USER/CLICKHOUSE_PASSWORD`，否则镜像禁用 default 用户网络认证
  - "Ready for connections" 写入容器内日志文件而非 stdout，日志等待会超时 → 用 HTTP `/ping` 探活
  - JDBC URL `jdbc:clickhouse://host:8123/<db>`
- **DDL 依据**：优先用测试环境导出的真实 `SHOW CREATE TABLE` 文件建表（`classpath:sql/ddl/...`），而不是 Hibernate `ddl-auto=create`（实体反推的表结构会掩盖真实约束，如 NOT NULL 列）
- **脚本执行**：`ScriptUtils.executeSqlScript` 无分号时会按行拆分，多行 CREATE TABLE 被拆坏 → 用 `EOF_STATEMENT_SEPARATOR` 让整个文件作为一条语句

### 基座骨架

```java
abstract class AbstractXxxContainerTest {
    static final GenericContainer<?> CONTAINER;   // singleton，Ryuk 自动回收
    static { CONTAINER.start(); initSchema(); }   // 每个 JVM 一次
    static JdbcTemplate jdbcTemplate() { ... }
}
```

## 验收

SQL 组装单测 + Pitest ≥90%；冒烟测试全绿（真实 SQL 可执行 + 关键结果映射正确）。
