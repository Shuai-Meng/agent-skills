#!/usr/bin/env bash
# Codex 跨机恢复：config + models + 插件 + 技能（来源：本仓库 README）
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
AGENTS_DIR="$HOME/.agents"

echo "[1/6] 写入 config.toml / models.json"
mkdir -p "$CODEX_DIR"
[ -f "$CODEX_DIR/config.toml" ] && cp "$CODEX_DIR/config.toml" "$CODEX_DIR/config.toml.bak.pre-restore"
cp "$KIT/config.toml" "$CODEX_DIR/config.toml"
cp "$KIT/models.json" "$CODEX_DIR/models.json"

echo "[1b] 写入全局 AGENTS.md（质疑优先/需求变更护栏）"
[ -f "$CODEX_DIR/AGENTS.md" ] && cp "$CODEX_DIR/AGENTS.md" "$CODEX_DIR/AGENTS.md.bak.pre-restore"
cp "$KIT/codex-AGENTS.md" "$CODEX_DIR/AGENTS.md"

echo "[2/6] 插件重装（清单来自 config.toml 的 [plugins.*]，哈希换机后自动重建）"
command -v codex >/dev/null || { echo "缺少 codex CLI"; exit 1; }
codex plugin add ponytail@ponytail || echo "  ! ponytail 失败：稍后手动 codex plugin add ponytail@ponytail"
codex plugin add tokmizer@tokmizer || echo "  ! tokmizer 失败：稍后手动 codex plugin add tokmizer@tokmizer"

echo "[3/6] registry 技能重装（与 skills-lock.json 对齐）"
command -v npx >/dev/null || { echo "缺少 node/npx"; exit 1; }
mkdir -p "$AGENTS_DIR"
cp "$KIT/skills-lock.json" "$AGENTS_DIR/.skill-lock.json"
node -e '
const lock = require(process.env.HOME + "/.agents/.skill-lock.json");
const bySource = {};
for (const [name, s] of Object.entries(lock.skills)) {
  const url = s.sourceUrl || `https://github.com/${s.source}`;
  (bySource[url] ||= []).push(name);
}
for (const [url, names] of Object.entries(bySource)) {
  console.log(`npx -y skills add ${url} --skill ${names.join(" --skill ")} -g -a codex -y`);
}
' > /tmp/codex-restore-skills.sh
bash /tmp/codex-restore-skills.sh
rm -f /tmp/codex-restore-skills.sh

echo "[4/6] 拷贝非 registry 技能"
mkdir -p "$AGENTS_DIR/skills" "$CODEX_DIR/skills"
cp -R "$KIT/skills/codex-token-saver/." "$AGENTS_DIR/skills/codex-token-saver/"
cp -R "$KIT/skills/layered-test-sop/." "$CODEX_DIR/skills/layered-test-sop/"

echo "[5/6] memory 定制覆盖（路径占位符替换为本机）"
mkdir -p "$AGENTS_DIR/skills/memory"
cp -R "$KIT/skills/memory/." "$AGENTS_DIR/skills/memory/"
sed -i "s|__CODEX_HOME__|$CODEX_DIR|g" "$AGENTS_DIR/skills/memory/SKILL.md"

echo "[6/6] 完成。剩余手动步骤："
echo "  1) 在 $CODEX_DIR/config.toml 的 [model_providers.deepseek] 补回 API key"
echo "  2) 重启 Codex，首次运行插件 hook 时确认信任"
