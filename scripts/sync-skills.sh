#!/usr/bin/env bash
# scripts/sync-skills.sh
# 把 .cursor/skills/ 下的 SKILL.md 同步到 .claude/ 和 .codex/，保持 3 处内容一致
# 维护流程：只改 .cursor/skills/.../SKILL.md → 跑这个脚本 → 提交

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/.cursor/skills/weapp-env-setup/SKILL.md"

if [ ! -f "$SOURCE" ]; then
  echo "❌ 源文件不存在: $SOURCE"
  exit 1
fi

TARGETS=(
  "$ROOT/.claude/skills/weapp-env-setup/SKILL.md"
  "$ROOT/.codex/skills/weapp-env-setup/SKILL.md"
)

echo "🔄 同步 SKILL.md 到所有 Agent 工具..."
for target in "${TARGETS[@]}"; do
  mkdir -p "$(dirname "$target")"
  cp "$SOURCE" "$target"
  echo "  ✅ $target"
done

# 校验一致性
echo "🔍 校验内容一致性..."
SOURCE_HASH=$(shasum "$SOURCE" | awk '{print $1}')
for target in "${TARGETS[@]}"; do
  TARGET_HASH=$(shasum "$target" | awk '{print $1}')
  if [ "$SOURCE_HASH" = "$TARGET_HASH" ]; then
    echo "  ✅ $(basename "$(dirname "$(dirname "$target")")") 一致"
  else
    echo "  ❌ $(basename "$(dirname "$(dirname "$target")")") 不一致！"
    exit 1
  fi
done

echo "✨ 全部同步完成"