# agent-skills 仓库规则

## 目的
本仓库是 Codex 的私人技能库 + 跨机恢复套件：配置、插件清单、registry 技能清单、本地定制技能。

## 目录约定
- `config.toml` / `models.json` — Codex 脱敏配置与模型目录，机器无关
- `skills-lock.json` — registry 技能清单（= `~/.agents/.skill-lock.json` 的同步副本）
- `restore.sh` — 新机器一键恢复；registry 技能段由 lock 动态生成，禁止手写硬编码清单
- `skills/<name>/` — 本地定制/非 registry 技能，需含带 frontmatter 的 `SKILL.md`
- `CONTEXT.md` — 仓库背景与决策

## 技能作者规约
- 每个技能目录必须含 `SKILL.md`，frontmatter 要有 `name`（小写连字符）和 `description`
- memory 技能的记忆文件路径用占位符 `__CODEX_HOME__`，restore 时替换为本机路径
- 需要补充材料时放 `references/`（文档）或 `assets/`（模板/资源）

## 安全红线
- 永不提交：API key、`auth.json`、`~/.zshrc` 内容、`[projects.*]` 信任列表、`[hooks.state]` 哈希
- 提交前先跑 `rg 'sk-[A-Za-z0-9]{8,}|/home/' .`
