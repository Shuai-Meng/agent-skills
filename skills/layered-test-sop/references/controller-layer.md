# Controller 层端点守卫

两层守卫：**清单守卫**（API 面契约）+ **探测守卫**（端点存活扫描）。

## 第一层：端点清单守卫

运行时枚举全部端点映射，与黄金清单精确对比，防止 API 面无声漂移。

```java
@SpringBootTest(properties = "spring.main.lazy-initialization=true")
class EndpointInventoryTest {
    @Autowired @Qualifier("requestMappingHandlerMapping")   // 排除 Actuator 的 controllerEndpointHandlerMapping
    RequestMappingHandlerMapping handlerMapping;
    // 枚举 getHandlerMethods() → path/method/handler，排序序列化
    // 与 src/test/resources/endpoints/endpoints.json 精确对比
    // 首次/有意变更：-DupdateGolden=true 重新生成
}
```

要点：
- 枚举用 `RequestMappingInfo.getPatternValues()`（Spring 6.0.14 可用；`getPathsCondition()` 已移除）
- 黄金清单按 path+method+handler 排序存 JSON，diff 直接显示变更
- 顺带断言无重复映射

## 第二层：端点探测守卫

对每个端点发空 body/空参数请求，断言不 5xx 且 BaseResponse 可解析出 code（任意业务码都算活着）。

```java
@SpringBootTest(properties = "spring.main.lazy-initialization=true")
@AutoConfigureMockMvc
class EndpointProbeTest { /* MockMvc + 认证注入 + 必填参数注入 */ }
```

### 关键坑（都是实测）

- **全量上下文**用 `spring.main.lazy-initialization=true`：不预连外部组件、定时任务不触发
- **认证注入**：Spring Security 6 的 `SecurityContextHolderFilter` 会覆盖手动设置的上下文；
  改用 `RequestAttributeSecurityContextRepository.DEFAULT_REQUEST_ATTR_NAME` 请求属性注入
  （在 HIGHEST_PRECEDENCE 过滤器中 `request.setAttribute(key, context)`）
- **必填 @RequestParam**：缺参在参数解析阶段就 500（全局异常处理器对逃逸异常返回 500）；
  自动从 HandlerMethod 提取必填参数并注入默认值
- **参数名解析**：`MethodParameter.getParameterName()` 运行时可能返回 null，
  用 `DefaultParameterNameDiscoverer.getParameterNames(method)` 兜底
- **路径变量**：`{id}` 替换为 `1`；不适合探测的端点（下载/流式/强状态）维护显式排除清单并注明原因
- **@Decrypt 类 body 解密**：解密失败会回退原文，空 body 探测不炸

### 断言原则

- HTTP 5xx = 失败；200/4xx 都算存活
- 响应是 JSON 且含 `code` 字段即可，不校验业务值
- 探测的目的是"端点没坏"，业务正确性由 service/DAO 测试负责

## 验收

清单对比零漂移；全量探测无 5xx；新增端点自动纳入（清单需更新）。
