---
name: layered-test-sop
description: >-
  Generate a three-layer test suite for Java/Spring Boot projects: service-layer unit tests
  (Mockito fixtures + domain-split test classes), DAO-layer tests (SQL-assembly unit tests plus
  real-engine smoke tests via Testcontainers for JdbcTemplate-heavy code), and controller-layer
  endpoint guards (golden endpoint manifest + live probe sweep), validated by mutation-testing
  gates (Pitest). Use when the user asks to add or complete tests for a Java/Spring project,
  build a layered testing体系 (unit/integration/E2E/DAO/endpoint tests), generate test suites
  with AI, set up mutation-testing coverage gates, or create an AI-driven testing SOP for CI.
---

# Layered Test SOP

为 Java/Spring Boot 项目生成三层测试体系，并用变异测试做验收门禁。
本技能是"流程 + 决策规则"，不是死脚本：先分析目标项目，再按层生成，最后验证迭代。

## 主流程

1. **分析项目**
   - 技术栈：Spring Boot 版本、Java 版本、ORM（JPA / JdbcTemplate / MyBatis）
   - 测试现状：已有测试、依赖（Mockito / Testcontainers / Pitest）、运行环境（沙箱 / CI、Docker 可用性）
   - 代码规模：controller / DAO / service 数量与业务复杂度，判断哪些层值得做
2. **按层生成**（顺序：service → DAO → controller；每层跑通后再进下一层）
   - service 层：见 `references/service-layer.md`
   - DAO 层：见 `references/dao-layer.md`
   - controller 层：见 `references/controller-layer.md`
3. **验证门禁**：见 `references/mutation-gating.md`
   - 每层：编译 + 测试全绿
   - 有业务逻辑的类：Pitest 变异分数 ≥ 90%，存活变异分级（等价/日志类可接受并注明，业务类必须补测）
4. **迭代**：失败 → 修复生产缺陷或补测试 → 重跑 → 直到门禁通过

## 决策规则

- 优先做有真实业务逻辑的类：分支多、动态 SQL、外部调用；样板类（纯 CRUD 接口、无逻辑 DAO）跳过并说明原因
- 测试与被测类**同包、目录扁平**，便于访问包级私有方法
- 一个被测类 = 一套 `XxxFixtures`（构造测试数据）+ `XxxTestSupport`（Mockito 基座）+ 多个按业务域拆分的 `Xxx*Test` 类
- 环境受限（沙箱禁网络/Docker/端口）时：明确说明所需权限；mock 单测不依赖外部环境，集成/冒烟需要容器
- 不硬凑覆盖率：只调用不断言的测试比没有更糟

## References（按需加载）

- `references/service-layer.md` — service 单测模式、组织约定与坑
- `references/dao-layer.md` — DAO SQL 组装单测 + Testcontainers 真实引擎冒烟
- `references/controller-layer.md` — 端点清单守卫 + 存活探测守卫
- `references/mutation-gating.md` — Pitest 配置、运行命令、存活变异分级

## Templates（assets/templates/）

`.skeleton` 文件为模式骨架（带 TODO），复制到目标项目后按需适配，不要原样照搬本项目专属内容。
