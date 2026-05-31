# AGENTS.md

## 仓库定位

- 根项目是 PowerShell 抓取和静态页面生成工具；不要把 `_external/MiroFish/` 当作本项目的一部分，它是带独立 `package.json`、`pyproject.toml`、`docker-compose.yml` 的外部项目目录。
- 真实入口是 `fetch-am.ps1` 和 `build-data.ps1`；`index.html`、`dashboard.html`、`report.html`、`data/*.json`、`pages/*.html` 多数是脚本生成或刷新后的产物。
- 默认脚本参数仍写着旧路径 `C:\codex\test\am`；在当前工作区运行时优先显式传 `-RootDir` / `-OutputDir`，或使用基于 `$PSScriptRoot` 的测试脚本。

## 常用命令

- 本地抓取并刷新页面：`powershell -NoProfile -ExecutionPolicy Bypass -File .\fetch-am.ps1 -OutputDir .`
- 只从现有 `pages/*.html` 重建 JSON 和页面：`powershell -NoProfile -ExecutionPolicy Bypass -File .\build-data.ps1 -RootDir .`
- 测试抓取/链接重写：`powershell -NoProfile -ExecutionPolicy Bypass -File .\test-fetch-am.ps1`
- 测试数据解析、预测、看板生成：`powershell -NoProfile -ExecutionPolicy Bypass -File .\test-build-data.ps1`
- 测试三中三覆盖率输出：`powershell -NoProfile -ExecutionPolicy Bypass -File .\test-sanzhong-coverage.ps1`
- 安装计划任务会写入 `run-hidden.vbs` 并注册 `Fetch-AM-Lottery-Records`：`powershell -NoProfile -ExecutionPolicy Bypass -File .\install-task.ps1 -ScriptPath <绝对路径>\fetch-am.ps1`

## 数据流和产物

- `fetch-am.ps1` 会抓取原站、重写本地资源到 `assets/site/`、保存入口到 `index.html`、发现并保存同站 HTML 到 `pages/`，然后调用 `build-data.ps1`。
- `build-data.ps1` 从 `pages/*.html` 解析开奖记录，写出 `data/records.json`、`data/predictions.json`、`data/game-predictions.json`、`data/prediction-observations.json`、`data/forecast-evaluation.json`，再生成 `dashboard.html` 和 `report.html`。
- `dashboard.html` 内嵌数据，目标是双击本地文件可用；不要改成依赖浏览器本地 `fetch` 读取 JSON。
- JSON/HTML 写入使用 UTF-8 no BOM；PowerShell 中已有 `$Utf8NoBom = [Text.UTF8Encoding]::new($false)`，新增生成写入逻辑应沿用。

## 业务约定

- 来源只有 `am` 和 `hk`；`build-data.ps1` 通过文件名识别香港数据：`hk*` 或 `YYYY1.html` 是 `hk`，其余默认 `am`。
- 每条开奖必须有 7 个球；三中三只看前 6 个号码，特别号只看第 7 个号码。
- 澳门下一期日期按最新开奖日期加 1 天；香港下一期日期用最近开奖间隔推断，不能简单加 1 天。
- 预测和游戏记录需要结算既有 pending/settled 项，再为下一目标期生成新项；不要在打开看板或切换标签时自动新增预测。
- `forecastVersion`、策略池、随机基线、自然周回测、walk-forward 回测等字段由测试覆盖；调整预测结构时先扩展 `test-build-data.ps1`。

## 测试注意

- 优先跑三个根目录 PowerShell 测试脚本；它们会创建并清理 `test-output`、`test-data-output`、`test-sanzhong-output` 等临时目录。
- `optimize-six.py` 需要 `numpy`，会穷举 `49C6`，比常规 PowerShell 测试昂贵；没有明确需要不要把它作为默认验证步骤。
- `fetch-am.ps1` 访问远端站点并会写 `logs/fetch.log`、`snapshots/`；离线或只验证生成逻辑时用 `build-data.ps1 -RootDir .` 或测试脚本。
