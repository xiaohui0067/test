# 开奖记录本地抓取和线上看板

这个仓库维护一套开奖记录抓取、解析、预测和静态看板生成工具。根项目以 PowerShell 脚本为主，同时提供 Vercel API 用于线上手动采集。

## 核心入口

- `fetch-am.ps1`：抓取原站页面，重写本地资源，保存 `index.html`、`pages/*.html`、`assets/site/*`，然后调用 `build-data.ps1`。
- `build-data.ps1`：从 `pages/*.html` 解析开奖记录，生成 `data/*.json`、`dashboard.html`、`report.html`。
- `dashboard.html`：数据看板，包含看板、游戏、预测、5期窗口、日报标签；本地双击可用，线上部署时会优先读取 `/api/data`。
- `report.html`：独立日报页。
- `api/collect.js`：Vercel 手动采集接口，抓取原站、重新计算基础数据并写入 Vercel Blob。
- `api/data.js`：Vercel 数据读取接口，从 Vercel Blob 读取最近一次线上采集结果。

## 本地运行

当前脚本默认参数里仍保留旧路径 `C:\codex\test\am`。在本仓库目录运行时，优先显式传入当前目录。

抓取原站并刷新所有页面：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\fetch-am.ps1 -OutputDir .
```

只用现有 `pages/*.html` 重建 JSON 和看板：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-data.ps1 -RootDir .
```

打开本地文件：

```text
index.html
dashboard.html
report.html
```

## 生成产物

`build-data.ps1` 会写出：

- `data/records.json`：开奖记录和内嵌看板数据主 payload。
- `data/predictions.json`：下一期和三中三预测。
- `data/game-predictions.json`：游戏推荐记录和结算结果。
- `data/prediction-observations.json`：预测观察记录。
- `data/forecast-evaluation.json`：预测评估摘要。
- `dashboard.html`：内嵌数据的静态看板。
- `report.html`：日报页面。

JSON 和 HTML 写入使用 UTF-8 no BOM。

## 看板功能

- 看板：按澳门 / 香港来源查看记录数量、最新开奖、热门号码、生肖、颜色和最近 20 期。
- 游戏：展示三中三和特别号推荐，包含综合主推、11 算法统计、历史记录、微信扫码复制文本。
- 预测：展示三中三和特别号观察记录、策略回测、随机基线、自然周盈利门槛、walk-forward 回测。
- 5期窗口：只观察特别号，每 5 期一个窗口，按号码池判断覆盖情况；详细规则见 `docs/5期窗口观察规则.md`。
- 日报：展示最新开奖、数据状态、热门号码和遗漏号码。

已移除的旧模块包括趋势、选号、沙盘、开奖记录挑战、特别号防连错旧函数和旧的周期 8 码组合 UI。

## Vercel 线上采集

线上采集使用 Node.js API，不直接执行 `fetch-am.ps1`。按钮在 `dashboard.html` 顶部，线上环境点击后会调用 `POST /api/collect`。

需要在 Vercel 项目中配置或确认：

- `BLOB_READ_WRITE_TOKEN`：Vercel Blob 读写令牌；当前代码按 Private Blob store 写入和读取。
- `COLLECT_SECRET`：可选。如果希望看板按钮直接可用，不要配置此项；配置后手动调用 `/api/collect` 需要带 `?secret=...` 或 `x-collect-secret`。
- `SOURCE_URL`：可选，默认 `https://2025kj.zkclhb.com:2025/am.html`。
- `MAX_COLLECT_PAGES`：可选，默认 `80`。

连接或修改 Vercel Blob 后必须重新部署一次；旧部署不会自动获得新环境变量。正式域名要确认 `BLOB_READ_WRITE_TOKEN` 作用域包含 Production。

接口：

- `GET /api/data`：读取最近一次线上采集数据。
- `POST /api/collect`：执行线上采集并写入 Blob。

`vercel.json` 配置了每天 UTC `13:45` 调用 `/api/collect`，对应北京时间 `21:45`。

当前线上 Node 版会重新计算 `records` 和 `summary` 基础统计；完整的 PowerShell 预测、游戏和回测逻辑仍由本地 `build-data.ps1` 生成。

## GitHub Pages 部署

`.github/workflows/static.yml` 会把仓库静态文件部署到 GitHub Pages。

首次使用需要在 GitHub 仓库设置里开启：

```text
Settings -> Pages -> Build and deployment -> Source -> GitHub Actions
```

如果未开启，`actions/configure-pages` 可能报 `Get Pages site failed` 或 `Resource not accessible by integration`。

## 测试

优先运行这三个脚本：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-fetch-am.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-build-data.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-sanzhong-coverage.ps1
```

`test-fetch-am.ps1` 验证抓取和链接重写。`test-build-data.ps1` 验证数据解析、预测、游戏、看板生成和页面关键结构。`test-sanzhong-coverage.ps1` 验证三中三覆盖率输出。

`optimize-six.py` 需要 `numpy`，会穷举 `49C6`，比常规测试昂贵；没有明确需要不要作为默认验证步骤。

## Windows 计划任务

安装每天晚上 9:45 自动抓取：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-task.ps1 -ScriptPath <绝对路径>\fetch-am.ps1
```

计划任务名称：

```text
Fetch-AM-Lottery-Records
```

手动触发：

```powershell
Start-ScheduledTask -TaskName Fetch-AM-Lottery-Records
```
