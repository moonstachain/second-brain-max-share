#!/usr/bin/env bash
# ============================================================
# 本地专家大脑 · 部署包 · Step 3 接检索器官 + 全量索引
# 作用：把 QMD 接到你的真相源(vault)，切中文 Qwen3 模型，全量向量化。
# 预修三大坑(A7)：①装错目标(显式传 vault 路径) ②HF下载卡(step1已配镜像)
#                ③config优先级(先把 Qwen3 写进 config 再 embed，不踩"环境变量被无视")
# 用法：bash step3-接检索并索引.sh /你的/vault/绝对路径 [collection名]
#   例：bash step3-接检索并索引.sh ~/Documents/MyBrain brain
# 幂等：可重复跑（已索引的不重复嵌入）
# ============================================================
set -euo pipefail

green(){ printf "\033[32m✓ %s\033[0m\n" "$1"; }
info(){ printf "\033[36m→ %s\033[0m\n" "$1"; }
red(){ printf "\033[31m✗ %s\033[0m\n" "$1"; }

VAULT="${1:-}"
NAME="${2:-brain}"
QWEN="hf:Qwen/Qwen3-Embedding-0.6B-GGUF/Qwen3-Embedding-0.6B-Q8_0.gguf"

if [ -z "$VAULT" ]; then
  red "用法: bash step3-接检索并索引.sh /你的/vault/绝对路径 [collection名]"
  exit 1
fi
# 展开 ~ 与相对路径为绝对路径（防"装错目标"）
VAULT="$(cd "$(eval echo "$VAULT")" 2>/dev/null && pwd)" || { red "找不到目录: $1（这就是'装错目标'坑——必须传真相源 vault 的真实路径）"; exit 1; }

# 国内镜像（若 step1 没配，这里兜底）
export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"

echo "=========================================="
echo " Step 3 · 接检索 + 索引"
echo " 真相源 vault : $VAULT"
echo " collection   : $NAME"
echo " embedding    : Qwen3-Embedding-0.6B (中文)"
echo "=========================================="

# 1. 把 vault 加为 collection（指向真大脑，不是工作目录）
info "把 vault 配为 collection '$NAME'…"
qmd collection add "$VAULT" --name "$NAME" --mask "**/*.md"

# 2. 关键：把 embedding 模型切成 Qwen3，写进 config（不只设环境变量！）
#    这一步预修"config 优先级"坑：QMD 首次运行会把默认英文模型写进 ~/.config/qmd/index.yml，
#    config 优先级高于环境变量，且 MCP 子进程不读 shell env —— 必须改 config 文件本身。
CFG="$HOME/.config/qmd/index.yml"
info "把 embedding 模型切到 Qwen3（改 config，预修'环境变量被无视'坑）…"
python3 - "$CFG" "$QWEN" <<'PY'
import sys, io, os
cfg, qwen = sys.argv[1], sys.argv[2]
try:
    import yaml
    use_yaml = True
except Exception:
    use_yaml = False
if not os.path.exists(cfg):
    print("  config 还不存在，qmd 会在下一步创建；先跳过，embed 后复查"); sys.exit(0)
text = open(cfg, encoding="utf-8").read()
if use_yaml:
    d = yaml.safe_load(text) or {}
    d.setdefault("models", {})
    d["models"]["embed"] = qwen
    with open(cfg, "w", encoding="utf-8") as f:
        yaml.safe_dump(d, f, allow_unicode=True, sort_keys=False)
    print("  已用 yaml 写入 models.embed = Qwen3")
else:
    # 无 pyyaml 时的文本兜底：替换或追加 embed 行
    lines = text.splitlines()
    out, in_models, done = [], False, False
    for ln in lines:
        if ln.strip().startswith("models:"):
            in_models = True; out.append(ln); continue
        if in_models and ln.strip().startswith("embed:"):
            out.append("  embed: " + qwen); done = True; in_models = False; continue
        out.append(ln)
    if not done:
        out.append("models:"); out.append("  embed: " + qwen)
    open(cfg, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("  已用文本兜底写入 models.embed = Qwen3")
PY

# 3. 拉本地模型（首次约 2.4GB，走镜像）
info "拉本地模型（首次约 2.4GB，走 $HF_ENDPOINT）…"
qmd pull

# 4. 全量向量化（首次较慢；中文 Qwen3）
info "全量向量化（首次按规模几十分钟，后台耐心等）…"
qmd embed -f

green "Step 3 完成。建议接着跑 step4-验真冒烟.sh '$VAULT' '$NAME' 做冒烟验真。"
echo "提示：换过模型后若用 Claude Code 内的 qmd MCP，重启一次 Claude Code 让它重载新模型（预修'维度不匹配'坑）。"
