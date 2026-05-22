#!/usr/bin/env bash
# ============================================================
# 本地专家大脑 · 部署包 · Step 1 装检索器官 QMD
# 作用：装 qmd CLI + plugin + 配国内 HF 镜像。幂等，可重复跑。
# 把"HF 下载卡死"的坑(A7)预修好。
# 用法：bash step1-装QMD检索器官.sh
# ============================================================
set -euo pipefail

green() { printf "\033[32m✓ %s\033[0m\n" "$1"; }
info()  { printf "\033[36m→ %s\033[0m\n" "$1"; }

echo "=========================================="
echo " Step 1 · 装检索器官 QMD"
echo "=========================================="

# 1. 装 qmd CLI 本体（已装则 npm 自动跳过/升级）
if qmd --version >/dev/null 2>&1; then
  green "qmd CLI 已装：$(qmd --version | head -1)"
else
  info "装 qmd CLI（npm 全局）…"
  npm install -g @tobilu/qmd
  green "qmd CLI 装好：$(qmd --version | head -1)"
fi

# 2. 装 Claude Code plugin（自动注册 MCP server + skill）
info "装/确认 qmd plugin…"
claude plugin marketplace add tobi/qmd 2>/dev/null || true
claude plugin install qmd@qmd 2>/dev/null || true
green "qmd plugin 已装（自动注册 MCP + skill）"

# 3. 配国内 HF 镜像，持久化到 shell rc（预修"HF 下载卡死"坑 A7）
RC="$HOME/.zshrc"; [ -n "${ZSH_VERSION:-}" ] || { [ "$(basename "${SHELL:-}")" = "zsh" ] && RC="$HOME/.zshrc" || RC="$HOME/.bashrc"; }
if grep -q "HF_ENDPOINT" "$RC" 2>/dev/null; then
  green "HF 镜像已配置在 $RC"
else
  {
    echo ""
    echo "# qmd: 国内 HuggingFace 镜像，加速本地模型下载 — 部署包自动添加"
    echo 'export HF_ENDPOINT="https://hf-mirror.com"'
  } >> "$RC"
  green "HF 镜像已写入 $RC（export HF_ENDPOINT=https://hf-mirror.com）"
fi

echo "------------------------------------------"
green "Step 1 完成。下一步："
info "  1) 用 step2-建脑主提示词.md 让 Claude Code 建好你的大脑本体（真相源）"
info "  2) 然后跑 step3-接检索并索引.sh <你的vault路径>"
