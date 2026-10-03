#!/usr/bin/env bash
# scripts/sync-skills.sh
# 自动发现 .cursor/skills/ 下的所有 Skill，同步到 .claude/ 和 .codex/
# 维护流程：只改 .cursor/skills/<任意>/SKILL.md → 跑这个脚本 → 提交
# 兼容：bash 3 (macOS) / bash 4 / zsh / sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -d "$ROOT/.cursor/skills" ]; then
  echo "❌ .cursor/skills/ 目录不存在: $ROOT/.cursor/skills"
  exit 1
fi

# 发现所有 Skill（bash 3 兼容写法，无 mapfile）
SKILLS=""
for d in "$ROOT/.cursor/skills"/*; do
  if [ -d "$d" ]; then
    skill="$(basename "$d")"
    SKILLS="$SKILLS$skill"$'\n'
  fi
done
SKILLS="$(echo "$SKILLS" | grep -v '^$' | sort)"

COUNT="$(echo "$SKILLS" | wc -l | tr -d ' ')"
if [ "$COUNT" -eq 0 ] || [ "$COUNT" -eq 1 ] && [ -z "$(echo "$SKILLS")" ]; then
  echo "⚠️  未发现任何 Skill（.cursor/skills/ 下没有子目录）"
  exit 0
fi

echo "🔍 发现 $COUNT 个 Skill："
echo "$SKILLS" | sed 's/^/   /'
echo ""

FAILED=0

echo "$SKILLS" | while IFS= read -r skill; do
  [ -z "$skill" ] && continue

  SOURCE="$ROOT/.cursor/skills/$skill/SKILL.md"

  if [ ! -f "$SOURCE" ]; then
    echo "⚠️  $skill: SKILL.md 不存在，跳过"
    continue
  fi

  SOURCE_HASH="$(shasum "$SOURCE" | awk '{print $1}')"

  for tool in claude codex; do
    TARGET="$ROOT/.$tool/skills/$skill/SKILL.md"
    mkdir -p "$(dirname "$TARGET")"
    cp "$SOURCE" "$TARGET"

    TARGET_HASH="$(shasum "$TARGET" | awk '{print $1}')"
    if [ "$SOURCE_HASH" = "$TARGET_HASH" ]; then
      echo "  ✅ .$tool/skills/$skill/SKILL.md"
    else
      echo "  ❌ .$tool/skills/$skill/SKILL.md 同步失败！"
      FAILED=1
    fi
  done

  echo ""
done

if [ "$FAILED" -eq 1 ]; then
  echo "❌ 有同步失败，请检查"
  exit 1
fi

echo "✨ 全部 $COUNT 个 Skill 同步完成"