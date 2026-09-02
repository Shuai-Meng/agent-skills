# agent-skills

Codex 私人技能库与跨机恢复套件：把本机的 Codex 配置、插件、技能整理成可跨机还原的清单。

## 结构

```
agent-skills/
├── README.md          # 本文件
├── AGENTS.md          # 仓库维护规则（给 agent 读）
├── CONTEXT.md         # 背景与决策
├── config.toml        # Codex 脱敏配置（模型/插件清单/features）
├── models.json        # 自定义模型目录
├── skills-lock.json   # registry 技能清单（19 个）
├── restore.sh         # 新机器一键恢复
└── skills/
    ├── codex-token-saver/    # 非 registry：Codex 省钱策略
    ├── layered-test-sop/     # 非 registry：Java/Spring 测试 SOP
    └── memory/               # 定制 memory（覆盖上游，含按目录拆分规则）
```

## 快速恢复（新机器）

```bash
git clone git@github.com:Shuai-Meng/agent-skills.git
cd agent-skills
bash restore.sh
```

`restore.sh` 会自动：写配置 → 重装插件 → 按 skills-lock.json 动态重装 registry 技能 → 拷贝本地技能 → 替换 memory 路径。

恢复后手动两件事：
1. 在 `~/.codex/config.toml` 的 `[model_providers.deepseek]` 补回 API key
2. 重启 Codex，首次运行插件 hook 时确认信任

## 更新本仓库（导出本机最新状态）

```bash
cp ~/.codex/config.toml config.toml          # 然后删 key / 本机路径（见 AGENTS.md 红线）
cp ~/.codex/models.json models.json
cp ~/.agents/.skill-lock.json skills-lock.json
cp -r ~/.agents/skills/codex-token-saver skills/
cp -r ~/.codex/skills/layered-test-sop skills/
cp -r ~/.agents/skills/memory skills/memory   # 路径换回 __CODEX_HOME__ 占位符
git add -A && git commit -m "sync" && git push
```

registry 技能的新增/删除只需同步 `skills-lock.json`，restore.sh 无需改动（动态生成）。

## 安全

- 永不提交 API key、auth.json、`[projects.*]` 信任列表、`[hooks.state]` 哈希
- 提交前跑 `rg 'sk-[A-Za-z0-9]{8,}|/home/' .`
- 本仓库是私有的，但同步工具可能外泄，先扫描再提交

## License

私有仓库，暂未授权分发。
