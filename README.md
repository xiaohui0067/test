# 开奖记录数据看板

这是一个静态数据看板项目，用于采集澳门 / 香港开奖记录，生成结构化数据、游戏推荐记录、五期窗口观察和日报页面。项目可以本地运行，也可以部署到 Vercel，并通过 GitHub Actions 执行定时或手动采集。

## 页面入口

- `index.html`：主看板，包含看板、游戏、5期窗口、三中三5期窗口、规律观察、手动采集、日报。
- `kjjl.html`：原始开奖记录页面副本。
- `report.html`：独立日报页面。

## 采集与生成

统一采集入口是 `fetch-all.ps1`：

1. 采集澳门来源页面，保存到 `pages/am*.html`。
2. 采集香港来源页面，保存到 `pages/hk*.html`。
3. 执行 `build-data.ps1`，从 `pages/*.html` 解析开奖记录并生成 `data/*.json`、`index.html` 和 `report.html`。

本地、GitHub Actions、Vercel 页面手动采集都应保持同一套流程，避免线上线下结果不一致。

## 本地命令

重新构建数据和页面：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-data.ps1
```

采集澳门和香港并重新构建：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\fetch-all.ps1
```

安装本地 Windows 定时任务：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-task.ps1
```

本地定时任务默认每天北京时间 `21:45` 执行 `fetch-all.ps1`，超时限制为 15 分钟。

## GitHub Actions

- `.github/workflows/daily-fetch.yml`：自动采集 workflow。
- `.github/workflows/manual-fetch.yml`：页面手动采集触发的 workflow。

自动采集执行 `fetch-all.ps1 -SkipSnapshot`，如果生成文件有变化，会自动提交到 `main`。Vercel 绑定该仓库后会自动重新部署。

需要确认仓库权限：

```text
Settings -> Actions -> General -> Workflow permissions -> Read and write permissions
```

GitHub `schedule` 不是严格准点任务，可能延迟或偶发漏触发；页面里的“手动采集”用于补采。

## Vercel 手动采集

`index.html` 的“手动采集”菜单会调用 `api/manual-fetch.js`，由 Vercel API 触发 GitHub Actions。

必须配置环境变量：

```text
GITHUB_TOKEN=GitHub Personal Access Token
```

可选环境变量：

```text
GITHUB_OWNER=tt88737
GITHUB_REPO=Abc
GITHUB_REF=main
```

配置或修改 Vercel 环境变量后，需要重新部署，线上函数才能读取到新变量。

## 关键文件

- `fetch-all.ps1`：统一采集入口，一次采集澳门和香港，然后构建数据。
- `fetch-am.ps1`：单来源采集脚本，可通过参数指定来源 URL 和输出文件名。
- `build-data.ps1`：解析 `pages/*.html`，生成结构化数据和静态页面。
- `build-three-compound.py`：生成三中三五期窗口复式池状态。
- `api/manual-fetch.js`：Vercel API，用于从页面触发 GitHub Actions。
- `data/records.json`：主结构化开奖记录和看板嵌入数据。
- `data/game-predictions.json`：游戏推荐记录和结算状态。
- `data/window5-state.json`：特别号 5 期窗口覆盖池状态。
- `data/three-compound-state.json`：三中三 5 期窗口复式池状态。

## 测试

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-build-data.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-fetch-am.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\test-sanzhong-coverage.ps1
```

## 已移除模块

旧的“预测观察”模块已经删除，不再生成：

- `data/prediction-observations.json`
- `data/forecast-evaluation.json`
- `records.json` / `index.html` 内嵌的 `forecasts` 字段

当前保留的是游戏推荐记录、5期窗口、三中三5期窗口和规律观察。

## 不提交的运行产物

以下目录用于本地运行、抓取快照或测试输出，已在 `.gitignore` 中忽略：

- `logs/`
- `snapshots/`
- `test-output/`
- `test-data-output/`
- `test-sanzhong-output/`
