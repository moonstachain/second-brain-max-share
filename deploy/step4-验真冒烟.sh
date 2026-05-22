#!/usr/bin/env bash
# ============================================================
# 本地专家大脑 · 部署包 · Step 4 验真冒烟
# 作用：确认检索器官真的接对、Qwen3 真的生效、中文检索真的能召回。
# 体现绿皮书铁律：装好 ≠ 能用，能用要冒烟验（卷三第15章 验真）。
# 用法：bash step4-验真冒烟.sh [collection名] [测试中文query]
#   例：bash step4-验真冒烟.sh brain "我最近的思考"
# ============================================================
set -uo pipefail

green(){ printf "\033[32m✓ %s\033[0m\n" "$1"; }
red(){ printf "\033[31m✗ %s\033[0m\n" "$1"; }
info(){ printf "\033[36m→ %s\033[0m\n" "$1"; }

NAME="${1:-brain}"
Q="${2:-知识 想法}"
export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
PASS=0; FAIL=0

echo "=========================================="
echo " Step 4 · 验真冒烟（collection: $NAME）"
echo "=========================================="

# 1. 索引存在 + 向量数 > 0
info "检查索引状态…"
ST="$(qmd status 2>&1)"
echo "$ST" | sed 's/\x1b\[[0-9;]*[A-Za-z]//g' | grep -E "Vectors|$NAME|Files|Embedding"
if echo "$ST" | grep -qE "Vectors:[[:space:]]*[1-9]"; then
  green "向量已生成（Vectors > 0）"; PASS=$((PASS+1))
else
  red "向量数为 0 —— embed 没成功？回去重跑 step3"; FAIL=$((FAIL+1))
fi

# 2. embedding 模型确实是 Qwen3
if echo "$ST" | grep -qi "Qwen3-Embedding"; then
  green "embedding 模型 = Qwen3（中文已生效）"; PASS=$((PASS+1))
else
  red "embedding 不是 Qwen3 —— config 没切对，回去看 step3 第2步"; FAIL=$((FAIL+1))
fi

# 3. 中文检索真能召回
info "跑中文检索冒烟：query='$Q' -c $NAME"
R="$(qmd query "$Q" -c "$NAME" --files -n 3 2>&1 | sed 's/\x1b\[[0-9;]*[A-Za-z]//g' | grep -E 'qmd://|,0\.' || true)"
if [ -n "$R" ]; then
  green "中文检索有命中："; echo "$R" | head -3
  PASS=$((PASS+1))
else
  red "中文检索 0 命中 —— 库可能还空（先投喂几篇）或索引没建好"; FAIL=$((FAIL+1))
fi

echo "------------------------------------------"
if [ "$FAIL" -eq 0 ]; then
  green "全部冒烟通过（$PASS/3）——检索器官接对了，大脑 B2 通感成功！"
  echo "日常用：qmd query \"你的问题\" -c $NAME"
  exit 0
else
  red "有 $FAIL 项未过——按上面提示修，对照 A7 教训档案"
  exit 1
fi
