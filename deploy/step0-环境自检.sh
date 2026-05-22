#!/usr/bin/env bash
# ============================================================
# 本地专家大脑 · 部署包 · Step 0 环境自检
# 作用：检查部署所需的依赖是否就位，缺什么给出安装命令。只读，不改任何东西。
# 用法：bash step0-环境自检.sh
# ============================================================
set -uo pipefail

green() { printf "\033[32m✓ %s\033[0m\n" "$1"; }
red()   { printf "\033[31m✗ %s\033[0m\n" "$1"; }
yellow(){ printf "\033[33m! %s\033[0m\n" "$1"; }

MISSING=0

echo "=========================================="
echo " 本地专家大脑 · 环境自检"
echo "=========================================="

# 1. Node.js (qmd CLI 需要，建议 ≥18)
if command -v node >/dev/null 2>&1; then
  V=$(node --version)
  green "Node.js 已装：$V"
else
  red "Node.js 未装 → 装：brew install node   (或 https://nodejs.org)"
  MISSING=1
fi

# 2. npm
if command -v npm >/dev/null 2>&1; then
  green "npm 已装：$(npm --version)"
else
  red "npm 未装（随 Node.js 一起装）"
  MISSING=1
fi

# 3. Claude Code CLI (装 qmd plugin 需要)
if command -v claude >/dev/null 2>&1; then
  green "Claude Code CLI 已装"
else
  red "Claude Code CLI 未装 → 见 https://claude.com/claude-code"
  MISSING=1
fi

# 4. git (脊柱/备份需要)
if command -v git >/dev/null 2>&1; then
  green "git 已装：$(git --version | awk '{print $3}')"
  # 检查 git 身份(改名挂 git 的坑，A7)
  if git config --global user.email >/dev/null 2>&1 && git config --global user.name >/dev/null 2>&1; then
    green "git 身份已配：$(git config --global user.name) <$(git config --global user.email)>"
  else
    yellow "git 全局身份未配 → 配：git config --global user.email 'you@x.com' && git config --global user.name 'You'"
    yellow "  (不配会导致自动提交全挂，见 A7 教训档案)"
  fi
else
  red "git 未装 → 装：brew install git"
  MISSING=1
fi

# 5. Obsidian (大脑本体载体，GUI，无法脚本装，提示即可)
if [ -d "/Applications/Obsidian.app" ] || command -v obsidian >/dev/null 2>&1; then
  green "Obsidian 已装"
else
  yellow "Obsidian 未检测到 → 装：brew install --cask obsidian   (或 https://obsidian.md)"
fi

# 6. python3 (脚本里用来安全改 yaml 配置)
if command -v python3 >/dev/null 2>&1; then
  green "python3 已装：$(python3 --version 2>&1 | awk '{print $2}')"
else
  yellow "python3 未装（step3 改配置会用到）→ 装：brew install python3"
fi

# 7. 网络/镜像提示（国内必看）
echo "------------------------------------------"
if curl -sI --connect-timeout 6 https://hf-mirror.com >/dev/null 2>&1; then
  green "HuggingFace 镜像 hf-mirror.com 可达（国内下模型走它，step1 会自动配）"
else
  yellow "hf-mirror.com 暂不可达，国内网络请检查代理"
fi

echo "=========================================="
if [ "$MISSING" -eq 0 ]; then
  green "核心依赖齐全，可以跑 step1-装QMD检索器官.sh"
  exit 0
else
  red "有核心依赖缺失，按上面提示装好后重跑本脚本"
  exit 1
fi
