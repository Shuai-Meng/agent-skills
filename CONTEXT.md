# Context

## 仓库来历
- 2026-09-02 创建：原为一次性跨机恢复套件，后按 mattpocock/skills 的组织方式整理为技能库
- 使用场景：个人在 Codex（DeepSeek 模型）上的配置 + 技能管理

## 技能来源
| 技能 | 来源 | 安装方式 |
|---|---|---|
| caveman / anysearch / find-skills / karpathy / understand-* / memory / code-review / diagnosing-bugs / domain-modeling / handoff / planning-with-files | 各 GitHub 仓库 | npx skills（记录于 skills-lock.json） |
| codex-token-saver | Myking1983/codex-token-saver | 手动拷贝 + 补 frontmatter |
| layered-test-sop | 本地自建 | 手动拷贝 |
| memory（定制版） | lokikill123/codex-token-skills 上游 + 本地补丁 | npx 装上游后覆盖定制 |

## 维护约定
- 本机新增 registry 技能 → `cp ~/.agents/.skill-lock.json skills-lock.json` 同步
- 本机新增本地技能 → 拷入 `skills/` 并在 restore.sh [4/6] 段加拷贝行
- 记忆文件 ~/.codex/MEMORY.md 只放跨项目事实，项目级事实进各项目 AGENTS.md
