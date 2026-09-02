# 变异测试门禁（Pitest）

变异测试是验证"断言质量"的手段：对生产代码注入等价小改动（变异），测试应能击杀；
杀不掉的叫存活变异，需要人工分级。

## pom 配置

```xml
<properties>
  <pitest.targetClasses>com.example.service.XxxService</pitest.targetClasses>
  <pitest.targetTests>com.example.service.Xxx*Test</pitest.targetTests>
</properties>
<plugin>
  <groupId>org.pitest</groupId><artifactId>pitest-maven</artifactId><version>1.15.1</version>
  <configuration>
    <targetClasses><param>${pitest.targetClasses}</param></targetClasses>
    <targetTests><param>${pitest.targetTests}</param></targetTests>
    <argLine>-javaagent:${settings.localRepository}/net/bytebuddy/byte-buddy-agent/1.14.12/byte-buddy-agent-1.14.12.jar</argLine>
  </configuration>
  <dependencies>
    <dependency><groupId>org.pitest</groupId><artifactId>pitest-junit5-plugin</artifactId><version>1.2.1</version></dependency>
  </dependencies>
</plugin>
```

- targetClasses/targetTests 属性化，可用 `-D` 覆盖任意类（变更裁剪、CI 按 diff 跑）
- argLine 内置 byte-buddy-agent，兼容沙箱/无自附加环境

## 运行

```bash
mvn -o pitest:mutationCoverage -Dpitest.targetClasses='com.example.Xxx' -Dpitest.targetTests='com.example.Xxx*Test'
# 沙箱内通常需要升级权限（JVM 自附加被禁）
```

关注输出：`Generated N mutations Killed M (x%)`、`Line Coverage`、`Test strength`。

## 存活变异分级

| 类型 | 示例 | 处理 |
|---|---|---|
| 等价变异 | 早退 `new ArrayList<>()` ↔ `Collections.emptyList()` | 接受，注明 |
| 日志分支 | `if (e instanceof X) log.info else log.error` | 接受，注明 |
| 业务分支 | 条件取反、`setStarRocks(false)` 调用被移除 | **必须补测** |

## 门禁建议

- 目标类行覆盖 ≥90%、变异 ≥90% 收工
- 补测技巧：
  - 负向断言（`assertFalse` 特定片段不存在）能击杀"多加条件"类变异
  - spy + `verify(obj).method()` 击杀"调用被移除"类变异
  - 组合条件（mobile+channel）单独用例，击杀"后置 if 覆盖前置"类变异
