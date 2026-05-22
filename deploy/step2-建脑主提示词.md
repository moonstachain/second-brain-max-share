# Step 2 · 建脑主提示词（粘给 Claude Code）

> 这一步建你的**大脑本体（真相源）**——目录结构 + 宪法文件。
> AI 驱动，无法纯脚本完成，所以用一段"主提示词"让 Claude Code 替你建。

## 操作

1. 新建一个空文件夹做你的 vault，例如 `~/Documents/MyBrain`
2. 把本目录的 `CLAUDE.md.模板` 复制进去，改名为 `CLAUDE.md`，把 `<你的大脑名>` 换成你的名字
3. 在该文件夹下启动 Claude Code，把下面这段**整段粘给它**：

---

```
我在用「本地专家大脑绿皮书」搭建我的第二大脑。这个文件夹是我的真相源（Single Source of Truth）。

请你严格按照本目录下 CLAUDE.md 的三层架构，帮我把知识库骨架建好：

1. 建三层目录：
   - sources/        （Layer1 原料，你只读不可变）
   - sources/articles/  sources/transcripts/  sources/notes/  （原料子类）
   - concepts/       （Layer2 概念页）
   - syntheses/      （Layer2 综述页）
   - entities/       （Layer2 实体页：人/公司/项目）
   - insights/       （Layer3 人类洞察，你永不触碰）
   - facts/          （人工校正的高信任事实，可选）

2. 建两个关键文件：
   - index.md  ：手写入口页/知识地图（先放一个空骨架，含各领域导航占位）
   - log.md    ：append-only 操作日志（格式 ## [YYYY-MM-DD] 操作 | 标题）

3. 确认 CLAUDE.md 在根目录，作为你每次操作前必读的宪法。

4. 建好后，向我报告目录结构，并告诉我："现在可以开始投喂了——把任何材料扔进 sources/ 对应子目录，说'帮我录入'即可。"

注意：不要创建任何示例知识内容，只建结构。Layer1 我只读、Layer3 你永不碰，这两条是硬约束。
```

---

## 验证这一步成功

Claude Code 跑完后，确认：
- [ ] `sources/` `concepts/` `syntheses/` `entities/` `insights/` 五个目录都在
- [ ] `index.md`、`log.md`、`CLAUDE.md` 三个文件在根目录
- [ ] 喂一篇测试材料进 `sources/articles/`，说"帮我录入"，看 `concepts/` 是否长出概念页

✅ 长出了概念页 = 你的大脑本体（B1 立脑）成功，去跑 `step3-接检索并索引.sh`。
