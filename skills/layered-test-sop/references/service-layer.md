# Service 层单测模式

## 适用判定

Service 有分支/编排/外部依赖（Redis、HTTP、其他 Service）时做；纯转发样板可跳过。

## 组织约定

- 测试与被测类同包、目录扁平（子包会导致 IDE 推断包名不一致，且无法访问包级私有方法）
- 每套：`XxxFixtures`（构造测试数据）+ `XxxTestSupport`（Mockito 基座，无测试方法）+ 多个 `Xxx*Test`（按业务域拆分，如 `XxxAccountTest` / `XxxQueryTest` / `XxxStatusTest`）

## 基座骨架

```java
@ExtendWith(MockitoExtension.class)
abstract class XxxServiceTestSupport {
    @Spy @InjectMocks
    protected XxxService xxxService;   // 需要测私有方法/doReturn 时用 Spy
    @Mock protected DepA depA;          // mock 名与生产字段名一致，避免同类型注入歧义
    @Mock protected DepB depB;
}
```

## 关键实践

- **严格模式**（MockitoExtension 默认）：每个 stub 必须被用到；`doReturn().when()` 用于 spy 的非 void/void 方法
- **副作用验证**：对 mock 返回的对象用 `spy(...)` 包裹，`verify(spyObj).setter(value)` 验证调用，能击杀"移除调用"类变异
- **负向用例**：异常路径、空值守卫、边界条件各补一条；变异测试会告诉你哪里没覆盖
- **数据构造**放 Fixtures，用 `Map.of`/`List.of`/builder 方法，避免每个用例手写长参数

## 常见坑

- JDK 21 + Mockito：需要 byte-buddy-agent（沙箱禁 JVM 自附加时 `-DargLine` 加 javaagent，见 mutation-gating.md）
- mockito-junit-jupiter 显式声明，版本与 mockito-core 一致
- `@MockBean` 只用于集成测试上下文，不要混进纯单测
- 同类型多个依赖：mock 字段命名与生产字段一致，否则 @InjectMocks 可能注错

## 验收

`mvn test -Dtest='Xxx*Test'` 全绿；对目标类跑 Pitest，变异 ≥90% 收工。
