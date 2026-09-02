# Codex 跨机恢复套件

把 Codex 的配置、插件、技能打包成可跨机还原的清单。`restore.sh` 会在新机器上：
拷贝配置 → 重装插件 → 重装 registry 技能 → 拷贝本地定制技能 → 打 memory 路径补丁。

## 包含内容

| 文件 | 来源 | 说明 |
|---|---|---|
| config.toml | ~/.codex/config.toml | 已脱敏（无 API key / 无本机路径信任 / 无 hook 哈希） |
| models.json | ~/.codex/models.json | 自定义模型目录（deepseek 等），必须同步 |
| skills-lock.json | ~/.agents/.skill-lock.json | registry 技能参考清单 |
| skills/codex-token-saver/ | ~/.agents/skills/ | 非 registry 技能 |
| skills/layered-test-sop/ | ~/.codex/skills/ | 非 registry 技能 |
| skills/memory-custom/ | 定制版 memory | 覆盖 npx 装的上游版，含按目录拆分规则 |

## 在新机器上恢复

```bash
git clone git@github.com:Shuai-Meng/agent-skills.git
cd agent-skills
bash restore.sh
```

恢复后手动做两件事：
1. 在 `~/.codex/config.toml` 的 `[model_providers.deepseek]` 补回 API key（或用环境变量鉴权）
2. 重启 Codex，首次运行插件 hook 时确认信任

## 更新本套件（把当前机器状态导出）

```bash
cp ~/.codex/config.toml config.toml   # 然后手动删 key / 本机路径
cp ~/.codex/models.json models.json
cp ~/.agents/.skill-lock.json skills-lock.json
cp -r ~/.agents/skills/codex-token-saver skills/
cp -r ~/.codex/skills/layered-test-sop skills/
cp -r ~/.agents/skills/memory skills/memory-custom  # 记得把路径换回 __CODEX_HOME__ 占位符
```

新增 registry 技能后，在 `restore.sh` 的技能段同步加一行。

## 安全注意

- **永不提交** `experimental_bearer_token` / `auth.json` / 任何 `sk-` 密钥
- `[projects.*]` 信任列表与 `[hooks.state]` 哈希是机器相关的，故意不放进套件
- 本仓库是私有的，但泄漏事故常发生在同步时，先跑 `rg 'sk-' .` 再提交
