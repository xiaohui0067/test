---
name: merge-coworker-package
description: Use when the user says 合并压缩包, 合并同事代码, 叠加代码, or provides a coworker zip/archive/folder path to merge into this repository while keeping GitHub Pages/main working.
---

# 合并同事代码包

## 目标

在不破坏当前 `main` 和 GitHub Pages 可用状态的前提下，把同事给的压缩包或目录安全叠加到当前仓库。

## 触发条件

- 用户提供同事代码压缩包路径，例如 `C:\Users\Administrator\Desktop\coworker.zip`
- 用户提供同事解压后的目录路径
- 用户说“合并同事代码”“叠加同事代码”“把这个包合进来”“保证线上还能用”
- 用户直接说“合并压缩包 `C:\Users\Administrator\Desktop\xxx.zip`”
- 用户直接粘贴一个 `.zip`、`.7z`、`.rar` 或目录路径并要求合并

## 自动触发语

用户以后可以直接发送：

```text
合并压缩包 C:\Users\Administrator\Desktop\xxx.zip
```

收到这种消息后，不要再解释通用 Git 流程，直接按本技能流程执行。只有在路径不存在、当前工作区有未提交改动会被覆盖、或功能冲突无法自动整合时才停下来问用户。

## 硬性规则

- 不要直接把压缩包解到项目根目录。
- 不要先覆盖文件再观察结果。
- 不要把未确认的同事代码直接提交到 `main`。
- 不要提交无关的本地未跟踪文件，例如用户自己的笔记。
- 遇到同文件冲突时，保留双方意图，不能粗暴选择一边。
- 冲突解决的底线是“双方功能都保留”：同事新增功能要能用，当前项目已有功能也要能用。
- 如果两边实现互相排斥，必须做整合设计并向用户说明取舍点，不能静默删除任何一方功能。
- 测试没过不能合入 `main`。

## 流程

1. 确认输入路径存在。
2. 检查当前仓库状态：`git status --short`。
3. 如果当前有未提交改动，区分用户已有改动和本次任务改动；不要覆盖用户改动。必要时先请用户确认是否提交或暂存。
4. 确认当前分支是 `main`，并同步远程：`git pull github2 main`。
5. 新建隔离分支：`git checkout -b merge-coworker-YYYYMMDD-HHMM`。
6. 把压缩包解压到临时目录：`C:\Users\ADMINI~1\AppData\Local\Temp\2\opencode\coworker-<timestamp>`。
7. 检查解压目录结构，识别真正项目根。不要把外层包装目录误合并。
8. 对比文件清单，特别检查 `.git`、`.github`、`data`、`pages`、`assets`、脚本和入口 HTML。
9. 复制同事代码到工作区时跳过：`.git`、`node_modules`、临时输出、缓存、系统文件。
10. 查看差异：`git status --short` 和 `git diff --stat`。
11. 对关键同文件改动读取 diff，判断是否需要手动合并。
12. 运行项目验证命令。
13. 验证通过后提交到隔离分支并推送该分支。
14. 向用户报告变更、测试结果和分支名，等待用户确认后才合入 `main`。
15. 用户确认后，切回 `main`，拉取远程，合并隔离分支，推送 `github2 main`。

## 默认验证命令

按顺序运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-fetch-am.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-build-data.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-sanzhong-coverage.ps1
```

如果只改文档或纯静态文本，可以说明为什么跳过部分测试，但仍要至少运行与影响范围匹配的验证。

## 复制规则

允许覆盖或新增这些项目文件，但必须看 diff：

- `fetch-am.ps1`
- `build-data.ps1`
- `test-*.ps1`
- `.github/workflows/*.yml`
- `index.html`
- `dashboard.html`
- `report.html`
- `data/*.json`
- `pages/*.html`
- `assets/**`

默认跳过：

- `.git/**`
- `.github/workflows` 中明显无关或危险的发布配置，除非用户明确需要
- `node_modules/**`
- `_external/**`，除非用户明确说同事改的是外部项目
- `logs/**`
- `snapshots/**`
- `test-output/**`
- `test-data-output/**`
- `test-sanzhong-output/**`
- `.DS_Store`、`Thumbs.db`

## 冲突处理

如果同事和当前仓库改了同一个文件：

1. 读取当前文件和同事版本。
2. 确定双方改动目的。
3. 列出双方功能点：当前项目已有功能、同事新增或修改的功能。
4. 手工整合到当前文件，目标是让两边功能同时存在。
5. 如果同一入口、同一数据字段或同一 UI 区域冲突，优先做兼容整合，例如合并判断条件、保留两个数据分支、把 UI 操作合并到同一区域。
6. 为双方功能分别运行或补充验证；不能只验证其中一边。
7. 在报告里列出冲突文件、保留的当前功能、保留的同事功能和处理方式。

不要使用 `git checkout --theirs` 或 `git checkout --ours` 粗暴选择整文件，除非用户明确要求。

如果无法同时保留双方功能，停止并向用户说明：

```text
这个冲突不是简单代码冲突，而是功能设计冲突。当前功能是 X，同事功能是 Y，两者在 Z 位置互相排斥。
方案 A：...
方案 B：...
推荐：...
```

获得用户确认后再继续。

## 提交策略

隔离分支提交信息：

```text
merge: integrate coworker package
```

合入 `main` 前必须让用户确认。确认前最多推送隔离分支，不推送 `main`。

## 用户交互模板

开始时：

```text
我会按隔离分支流程合并这个同事代码包：先备份当前远程状态，新建 merge 分支，解压到临时目录，对比后合并，跑测试，通过后只推送 merge 分支。等你确认后才合入 main。
```

需要确认合入 `main` 时：

```text
同事代码已在分支 `<branch>` 合并并验证。是否现在合入 `main` 并推送到 GitHub Pages 使用的主分支？
```

## 完成报告

报告必须包含：

- 输入包路径
- 临时解压目录
- 合并分支名
- 改动文件摘要
- 冲突文件和处理方式
- 验证命令和结果
- 是否已合入 `main`
- 如果未合入，下一步命令
