#!/usr/bin/env bash
# ============================================================
# 本地专家大脑 · 部署包 · 真·一键部署编排器
# 作用：把 step0(自检) → step1(装QMD) → step2(建脑·交互暂停) → step3(接检索索引) → step4(验真)
#       串成一条线跑完。step2 是 AI 干的活，脚本会打印提示词并暂停，等你粘进 Claude Code 建好后回车继续。
# 用法：bash 一键部署.sh [vault绝对路径] [collection名]
#   例：bash 一键部署.sh ~/Documents/MyBrain brain
#   不传参数会交互式询问。
# 安全：每步失败即停；step1/step3 幂等可重跑；不碰你已有的别的 vault。
# ============================================================
set -uo pipefail

# 颜色
g(){ printf "\033[32m%s\033[0m\n" "$1"; }
b(){ printf "\033[1;36m%s\033[0m\n" "$1"; }
r(){ printf "\033[31m%s\033[0m\n" "$1"; }
y(){ printf "\033[33m%s\033[0m\n" "$1"; }
hr(){ printf "\033[90m%s\033[0m\n" "────────────────────────────────────────────"; }

# 定位脚本所在目录（保证能找到 step*.sh 兄弟脚本）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VAULT="${1:-}"
NAME="${2:-brain}"

clear 2>/dev/null || true
b "╔══════════════════════════════════════════╗"
b "║   本地专家大脑 · 真·一键部署               ║"
b "║   step0自检 → step1装QMD → step2建脑       ║"
b "║   → step3接检索 → step4验真               ║"
b "╚══════════════════════════════════════════╝"
echo
y "说明：这套是「脚本做确定性 + 提示词做 AI 部分 + 验真兜底」。"
y "中途 step2 需要你把提示词粘进 Claude Code 建大脑本体，脚本会暂停等你。"
echo
read -r -p "准备好开始了吗？(回车继续 / Ctrl-C 退出) " _

# ---------- 询问 vault 路径（step3/4 需要） ----------
if [ -z "$VAULT" ]; then
  echo
  b "【先确定你的大脑本体(vault)放哪】"
  y "可以是还不存在的新目录，step2 会让 Claude Code 在里面建结构。"
  read -r -p "输入 vault 路径(如 ~/Documents/MyBrain)： " VAULT
fi
VAULT_EXPANDED="$(eval echo "$VAULT")"
echo "  → vault: $VAULT_EXPANDED   collection: $NAME"

# ========== STEP 0 ==========
echo; hr; b "STEP 0 · 环境自检"; hr
if bash "$SCRIPT_DIR/step0-环境自检.sh"; then
  g "✓ step0 通过"
else
  r "✗ step0 发现缺失依赖。请按上面提示装好后，重跑本脚本。"; exit 1
fi
echo; read -r -p "继续 step1 装 QMD？(回车) " _

# ========== STEP 1 ==========
echo; hr; b "STEP 1 · 装检索器官 QMD"; hr
if bash "$SCRIPT_DIR/step1-装QMD检索器官.sh"; then
  g "✓ step1 完成"
else
  r "✗ step1 失败。检查 npm/claude 网络后重跑。"; exit 1
fi

# ========== STEP 2 (交互暂停 · AI 干的活) ==========
echo; hr; b "STEP 2 · 建大脑本体（AI 干的活，脚本暂停等你）"; hr
echo
y "① 先把宪法模板复制进你的 vault（脚本帮你建目录+复制）："
mkdir -p "$VAULT_EXPANDED"
if [ -f "$VAULT_EXPANDED/CLAUDE.md" ]; then
  y "   （$VAULT_EXPANDED/CLAUDE.md 已存在，跳过复制，不覆盖你的）"
else
  cp "$SCRIPT_DIR/CLAUDE.md.模板" "$VAULT_EXPANDED/CLAUDE.md"
  g "   已复制 CLAUDE.md → $VAULT_EXPANDED/CLAUDE.md（记得把 <你的大脑名> 改成你的）"
fi
echo
y "② 在 $VAULT_EXPANDED 下启动 Claude Code，把下面这段【整段粘给它】："
echo
hr
# 内联打印主提示词（也可见 step2-建脑主提示词.md）
cat <<'PROMPT'
我在用「本地专家大脑绿皮书」搭建我的第二大脑。这个文件夹是我的真相源。
请严格按本目录 CLAUDE.md 的三层架构，帮我建知识库骨架：
1. 建目录：sources/(及 articles/ transcripts/ notes/ 子目录) / concepts/ / syntheses/ / entities/ / insights/ / facts/(可选)
2. 建文件：index.md(知识地图空骨架) / log.md(append-only 日志)
3. 确认 CLAUDE.md 在根目录作为你每次操作前必读的宪法
4. 建好后报告目录结构，并告诉我"可以开始投喂了"
注意：只建结构，不造示例内容；Layer1 你只读、Layer3 你永不碰。
PROMPT
hr
echo
y "③ 建好后，喂一篇测试材料进 sources/articles/，对 Claude Code 说\"帮我录入\"，"
y "   确认 concepts/ 长出了概念页（= B1 立脑成功）。"
echo
b "完成上面三步后回到这里 →"
read -r -p "已建好大脑本体并验证长出概念页？(回车继续 step3 / Ctrl-C 暂停) " _

# ========== STEP 3 ==========
echo; hr; b "STEP 3 · 接检索 + 全量索引（切中文 Qwen3）"; hr
if bash "$SCRIPT_DIR/step3-接检索并索引.sh" "$VAULT_EXPANDED" "$NAME"; then
  g "✓ step3 完成"
else
  r "✗ step3 失败。对照绿皮书 A7 教训档案排查（装错目标/HF镜像/config）。"; exit 1
fi

# ========== STEP 4 ==========
echo; hr; b "STEP 4 · 验真冒烟"; hr
read -r -p "输入一个你库里大概率有的中文测试词(回车用默认'知识 想法')： " Q
Q="${Q:-知识 想法}"
if bash "$SCRIPT_DIR/step4-验真冒烟.sh" "$NAME" "$Q"; then
  echo
  b "╔══════════════════════════════════════════╗"
  g  "  🎉 部署成功！你的本地专家大脑 B1+B2 就绪"
  b "╚══════════════════════════════════════════╝"
  echo
  g "日常用：  qmd query \"你的问题\" -c $NAME"
  g "新增笔记：qmd update   （增量索引，秒级）"
  y "之后按需：脊柱(GitHub备份)→B3深研/运营→B4代谢自动化，见绿皮书卷六。"
else
  r "✗ step4 冒烟未全过。若是库还空，先投喂几篇再重跑 step4；否则对照 A7 排查。"
  exit 1
fi
