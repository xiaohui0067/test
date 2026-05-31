# Vercel 手动采集实施计划

> **对于代理工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 来逐任务实施此计划。步骤使用复选框（`- [ ]`）语法进行跟踪。

**目标：** 在 Vercel 部署上提供线上采集接口和看板“手动采集”按钮，点击后抓取原站开奖记录、生成最新数据并刷新看板。

**架构：** 保留现有 PowerShell 本地生成流程作为离线工具；新增 Node.js 线上数据管线用于 Vercel Serverless。线上只抓取开奖 HTML 和生成数据 JSON，不镜像 CSS/JS/图片资源，数据通过 Vercel Blob 持久化。

**技术栈：** Node.js 20、Vercel Serverless Functions、Vercel Blob、原生 `fetch`、PowerShell 现有测试脚本。

---

## 文件结构

- 创建：`package.json`，声明 Vercel/Blob 依赖和基础脚本。
- 创建：`api/_lib/lottery-pipeline.js`，线上抓取、解析、统计和简化预测数据生成逻辑。
- 创建：`api/collect.js`，Vercel API：执行采集并写入 Blob。
- 创建：`api/data.js`，Vercel API：读取 Blob 中最新数据。
- 创建：`vercel.json`，配置每天定时调用 `/api/collect`。
- 修改：`build-data.ps1`，生成的 `dashboard.html` 在 Vercel 环境下支持 `/api/data` 和 `/api/collect`。
- 修改：`test-build-data.ps1`，断言看板包含手动采集按钮、API 调用和状态提示。
- 修改：`README.md`，补充 Vercel 部署环境变量和线上采集说明。

## 任务 1：添加 Node/Vercel 项目基础

**文件：**
- 创建：`package.json`
- 创建：`vercel.json`

- [ ] **步骤 1：创建 `package.json`**

```json
{
  "name": "am-lottery-dashboard",
  "private": true,
  "type": "module",
  "engines": {
    "node": ">=20"
  },
  "scripts": {
    "test:ps": "powershell -NoProfile -ExecutionPolicy Bypass -File ./test-build-data.ps1"
  },
  "dependencies": {
    "@vercel/blob": "latest"
  },
  "devDependencies": {}
}
```

- [ ] **步骤 2：创建 `vercel.json`**

```json
{
  "crons": [
    {
      "path": "/api/collect",
      "schedule": "45 13 * * *"
    }
  ]
}
```

说明：Vercel Cron 使用 UTC，`13:45 UTC` 对应北京时间 `21:45`。

- [ ] **步骤 3：安装依赖**

运行：`npm install`

预期：生成 `package-lock.json`，安装 `@vercel/blob` 成功。

## 任务 2：实现线上采集和解析管线

**文件：**
- 创建：`api/_lib/lottery-pipeline.js`

- [ ] **步骤 1：创建解析辅助函数**

在 `api/_lib/lottery-pipeline.js` 中添加：

```js
const DEFAULT_SOURCE_URL = 'https://2025kj.zkclhb.com:2025/am.html';

const SOURCE_NAMES = {
  am: '澳门',
  hk: '香港',
};

function htmlDecode(value) {
  return String(value || '')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)));
}

function colorName(color) {
  if (color === 'red') return '红';
  if (color === 'green') return '绿';
  if (color === 'blue') return '蓝';
  return color;
}

function normalizeZodiac(value) {
  const decoded = htmlDecode(String(value || '').trim());
  const zodiacs = ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪'];
  return zodiacs.find((item) => decoded.startsWith(item)) || decoded;
}

function getSourceKind(fileName) {
  return /^hk/i.test(fileName) || /^\d{4}1\.html$/i.test(fileName) ? 'hk' : 'am';
}

function getYearFromFile(fileName, html) {
  const nameMatch = String(fileName).match(/^(\d{4})1?\.html$/i);
  if (nameMatch) return Number(nameMatch[1]);
  const htmlMatch = String(html).match(/(\d{4})(?:&#24180;|[\u4e00-\u9fff])/);
  return htmlMatch ? Number(htmlMatch[1]) : null;
}
```

- [ ] **步骤 2：实现 HTML 页面发现和抓取**

继续添加：

```js
async function fetchText(url) {
  const response = await fetch(url, {
    headers: {
      'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36',
      accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'accept-language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'cache-control': 'no-cache',
    },
  });
  if (!response.ok) throw new Error(`Fetch failed ${response.status}: ${url}`);
  return response.text();
}

function linkedHtmlUrls(html, baseUrl) {
  const urls = new Map();
  const base = new URL(baseUrl);
  const pattern = /\bhref\s*=\s*["'](?!data:|javascript:|mailto:|tel:|#)([^"']+\.html(?:\?[^"']*)?)["']/gi;
  for (const match of html.matchAll(pattern)) {
    const url = new URL(match[1], baseUrl);
    if (url.protocol === base.protocol && url.hostname === base.hostname && url.port === base.port) {
      urls.set(url.href, url);
    }
  }
  return [...urls.values()];
}

async function collectPages(sourceUrl = DEFAULT_SOURCE_URL, maxPages = 80) {
  const rootHtml = await fetchText(sourceUrl);
  const rootUrl = new URL(sourceUrl);
  const pages = new Map();
  const queue = [];
  pages.set(rootUrl.href, {url: rootUrl.href, fileName: 'am.html', html: rootHtml});
  for (const url of linkedHtmlUrls(rootHtml, sourceUrl)) {
    if (!pages.has(url.href)) {
      pages.set(url.href, {url: url.href, fileName: url.pathname.split('/').pop(), html: null});
      queue.push(url.href);
    }
  }
  while (queue.length && pages.size < maxPages) {
    const nextUrl = queue.shift();
    const page = pages.get(nextUrl);
    try {
      page.html = await fetchText(nextUrl);
      for (const url of linkedHtmlUrls(page.html, nextUrl)) {
        if (pages.size >= maxPages) break;
        if (!pages.has(url.href)) {
          pages.set(url.href, {url: url.href, fileName: url.pathname.split('/').pop(), html: null});
          queue.push(url.href);
        }
      }
    } catch (error) {
      page.error = error.message;
    }
  }
  return [...pages.values()].filter((page) => page.html);
}
```

- [ ] **步骤 3：实现开奖记录解析和统计**

继续添加：

```js
function parseRecordBlocks(html, source, year, fileName) {
  const records = [];
  const recordPattern = /<li>\s*<dt><b>(\d+)<\/b>期\(开奖时间:(\d{4}-\d{2}-\d{2})\)<\/dt>\s*<dl>([\s\S]*?)<\/dl>\s*<\/li>/gi;
  for (const recordMatch of html.matchAll(recordPattern)) {
    const balls = [];
    const ballPattern = /<div\s+class="ball"[^>]*data-name="([^"]+)"[^>]*data-index="(\d+)"[^>]*>\s*<p>\s*<span\s+class="([^"]+)">(\d+)<\/span>\s*<b>([^<]+)<\/b>\s*<\/p>\s*<\/div>/gi;
    for (const ballMatch of recordMatch[3].matchAll(ballPattern)) {
      balls.push({
        index: Number(ballMatch[2]),
        number: Number(ballMatch[4]),
        numberText: ballMatch[4].padStart(2, '0'),
        color: ballMatch[3],
        colorName: colorName(ballMatch[3]),
        zodiac: normalizeZodiac(ballMatch[5]),
      });
    }
    if (balls.length === 7) {
      records.push({
        id: `${source}-${recordMatch[2]}-${recordMatch[1]}`,
        source,
        sourceName: SOURCE_NAMES[source],
        year,
        issue: Number(recordMatch[1]),
        date: recordMatch[2],
        file: fileName,
        balls: balls.sort((a, b) => a.index - b.index),
      });
    }
  }
  return records;
}

function counts(items, selector) {
  const map = new Map();
  for (const item of items) {
    const key = selector(item);
    if (!key) continue;
    map.set(String(key), (map.get(String(key)) || 0) + 1);
  }
  return [...map.entries()]
    .map(([name, count]) => ({name, count}))
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name));
}

function summaryFor(records) {
  const allBalls = records.flatMap((record) => record.balls);
  const latest = records.slice().sort((a, b) => b.date.localeCompare(a.date) || b.issue - a.issue)[0] || null;
  const bySource = {};
  for (const source of ['am', 'hk']) {
    const sourceRecords = records.filter((record) => record.source === source);
    const sourceBalls = sourceRecords.flatMap((record) => record.balls);
    bySource[source] = {
      source,
      sourceName: SOURCE_NAMES[source],
      totalRecords: sourceRecords.length,
      totalBalls: sourceBalls.length,
      years: counts(sourceRecords, (record) => record.year),
      numbers: counts(sourceBalls, (ball) => ball.numberText),
      zodiacs: counts(sourceBalls, (ball) => ball.zodiac),
      colors: counts(sourceBalls, (ball) => ball.colorName),
      latest: sourceRecords.slice().sort((a, b) => b.date.localeCompare(a.date) || b.issue - a.issue)[0] || null,
    };
  }
  return {
    generatedAt: new Date().toISOString().replace('T', ' ').slice(0, 19),
    totalRecords: records.length,
    totalBalls: allBalls.length,
    bySource,
    sources: counts(records, (record) => record.sourceName),
    years: counts(records, (record) => record.year),
    numbers: counts(allBalls, (ball) => ball.numberText),
    zodiacs: counts(allBalls, (ball) => ball.zodiac),
    colors: counts(allBalls, (ball) => ball.colorName),
    latest,
  };
}
```

- [ ] **步骤 4：导出采集函数**

继续添加：

```js
export async function collectLotteryData(options = {}) {
  const sourceUrl = options.sourceUrl || process.env.SOURCE_URL || DEFAULT_SOURCE_URL;
  const pages = await collectPages(sourceUrl, Number(process.env.MAX_COLLECT_PAGES || 80));
  const unique = new Map();
  for (const page of pages) {
    const source = getSourceKind(page.fileName);
    const year = getYearFromFile(page.fileName, page.html);
    for (const record of parseRecordBlocks(page.html, source, year, page.fileName)) {
      unique.set(record.id, record);
    }
  }
  const records = [...unique.values()].sort((a, b) => b.date.localeCompare(a.date) || a.source.localeCompare(b.source) || b.issue - a.issue);
  const summary = summaryFor(records);
  return {
    summary,
    records,
    predictions: {next: [], sanzhong: []},
    games: {generatedAt: summary.generatedAt, items: []},
    forecasts: {generatedAt: summary.generatedAt, items: []},
    collect: {
      sourceUrl,
      pageCount: pages.length,
      generatedAt: summary.generatedAt,
    },
  };
}
```

## 任务 3：实现 Vercel API

**文件：**
- 创建：`api/collect.js`
- 创建：`api/data.js`

- [ ] **步骤 1：创建采集接口 `api/collect.js`**

```js
import {put} from '@vercel/blob';
import {collectLotteryData} from './_lib/lottery-pipeline.js';

const BLOB_KEY = 'latest-records.json';

function allowed(req) {
  const secret = process.env.COLLECT_SECRET;
  if (!secret) return true;
  return req.headers['x-collect-secret'] === secret || req.query?.secret === secret;
}

export default async function handler(req, res) {
  if (req.method !== 'POST' && req.method !== 'GET') {
    res.status(405).json({ok: false, error: 'Method not allowed'});
    return;
  }
  if (!allowed(req)) {
    res.status(401).json({ok: false, error: 'Unauthorized'});
    return;
  }
  try {
    const payload = await collectLotteryData();
    const blob = await put(BLOB_KEY, JSON.stringify(payload), {
      access: 'public',
      contentType: 'application/json; charset=utf-8',
      allowOverwrite: true,
    });
    res.status(200).json({ok: true, url: blob.url, summary: payload.summary, collect: payload.collect});
  } catch (error) {
    res.status(500).json({ok: false, error: error.message});
  }
}
```

- [ ] **步骤 2：创建数据接口 `api/data.js`**

```js
import {list} from '@vercel/blob';

const BLOB_KEY = 'latest-records.json';

export default async function handler(req, res) {
  try {
    const blobs = await list({prefix: BLOB_KEY, limit: 1});
    const blob = blobs.blobs.find((item) => item.pathname === BLOB_KEY) || blobs.blobs[0];
    if (!blob) {
      res.status(404).json({ok: false, error: 'No collected data'});
      return;
    }
    const response = await fetch(blob.url, {cache: 'no-store'});
    if (!response.ok) throw new Error(`Blob read failed: ${response.status}`);
    const payload = await response.json();
    res.setHeader('Cache-Control', 'no-store');
    res.status(200).json(payload);
  } catch (error) {
    res.status(500).json({ok: false, error: error.message});
  }
}
```

## 任务 4：修改看板支持线上数据和手动采集

**文件：**
- 修改：`build-data.ps1`
- 修改：`test-build-data.ps1`

- [ ] **步骤 1：先添加失败测试**

在 `test-build-data.ps1` 读取 `$dashboard` 后加入断言：

```powershell
    if (-not $dashboard.Contains('id="manual-collect"')) {
        throw 'dashboard should render manual collect button'
    }
    if (-not $dashboard.Contains("fetch('/api/collect'")) {
        throw 'dashboard should call collect API'
    }
    if (-not $dashboard.Contains("fetch('/api/data'")) {
        throw 'dashboard should load online data API when hosted'
    }
```

- [ ] **步骤 2：运行测试确认失败**

运行：`powershell -NoProfile -ExecutionPolicy Bypass -File .\test-build-data.ps1`

预期：失败，提示 `dashboard should render manual collect button`。

- [ ] **步骤 3：修改 `build-data.ps1` 的 header 和 JS**

在生成的 `<header>` 中把返回链接旁边加按钮：

```html
    <div class="actions">
      <button id="manual-collect" class="primary" type="button">&#25163;&#21160;&#37319;&#38598;</button>
      <span id="collect-status" class="muted"></span>
      <a href="index.html">&#36820;&#22238;&#24320;&#22870;&#35760;&#24405;</a>
    </div>
```

在脚本中新增：

```javascript
    function isHostedDashboard() {
      return location.protocol === 'http:' || location.protocol === 'https:';
    }
    async function loadOnlineDataIfHosted() {
      if (!isHostedDashboard()) return false;
      try {
        const response = await fetch('/api/data', {cache: 'no-store'});
        if (!response.ok) return false;
        const data = await response.json();
        records = data.records || [];
        summary = data.summary || {};
        generatedPredictions = data.predictions || {next: [], sanzhong: []};
        gamePredictions = data.games || {items: []};
        forecastPredictions = data.forecasts || {items: []};
        sourceRecordCache.am = null;
        sourceRecordCache.hk = null;
        return true;
      } catch (err) {
        return false;
      }
    }
    async function manualCollect() {
      const button = document.getElementById('manual-collect');
      const status = document.getElementById('collect-status');
      if (!isHostedDashboard()) {
        status.textContent = '本地文件不能直接调用 Vercel 采集接口';
        return;
      }
      button.disabled = true;
      status.textContent = '采集中...';
      try {
        const response = await fetch('/api/collect', {method: 'POST'});
        const result = await response.json();
        if (!response.ok || !result.ok) throw new Error(result.error || '采集失败');
        await loadOnlineDataIfHosted();
        status.textContent = `采集完成：${result.summary?.generatedAt || ''}`;
        renderOverview();
      } catch (err) {
        status.textContent = `采集失败：${err.message}`;
      } finally {
        button.disabled = false;
      }
    }
```

把初始化逻辑改为异步：

```javascript
    async function initDashboard() {
      try {
        const embedded = JSON.parse(document.getElementById('embedded-records').textContent);
        records = embedded.records || [];
        summary = embedded.summary || {};
        generatedPredictions = embedded.predictions || {next: [], sanzhong: []};
        gamePredictions = embedded.games || {items: []};
        forecastPredictions = embedded.forecasts || {items: []};
        await loadOnlineDataIfHosted();
        document.getElementById('manual-collect').addEventListener('click', manualCollect);
        renderOverview();
      } catch (err) {
        app.innerHTML = `<section class="panel"><h2>&#25968;&#25454;&#21152;&#36733;&#22833;&#36133;</h2><p>${esc(err.message)}</p></section>`;
      }
    }
    initDashboard();
```

- [ ] **步骤 4：运行测试确认通过**

运行：`powershell -NoProfile -ExecutionPolicy Bypass -File .\test-build-data.ps1`

预期：输出 `PASS`。

## 任务 5：补充部署说明

**文件：**
- 修改：`README.md`

- [ ] **步骤 1：追加 Vercel 部署说明**

追加中文章节：

```markdown
## Vercel 线上采集

线上采集使用 Node.js API，不直接执行 `fetch-am.ps1`。

需要在 Vercel 项目中配置：

- `BLOB_READ_WRITE_TOKEN`：Vercel Blob 读写令牌。
- `COLLECT_SECRET`：可选；配置后手动调用 `/api/collect` 需要带 `?secret=...` 或 `x-collect-secret`。
- `SOURCE_URL`：可选；默认 `https://2025kj.zkclhb.com:2025/am.html`。
- `MAX_COLLECT_PAGES`：可选；默认 `80`。

接口：

- `GET /api/data`：读取最近一次采集数据。
- `POST /api/collect`：执行采集并写入 Blob。

定时任务在 `vercel.json` 中配置为 UTC `13:45`，对应北京时间 `21:45`。
```

## 任务 6：最终验证

**文件：**
- 验证：`package.json`
- 验证：`api/**/*.js`
- 验证：`build-data.ps1`
- 验证：`test-build-data.ps1`

- [ ] **步骤 1：安装 Node 依赖**

运行：`npm install`

预期：退出码 `0`。

- [ ] **步骤 2：运行 PowerShell 看板生成测试**

运行：`powershell -NoProfile -ExecutionPolicy Bypass -File .\test-build-data.ps1`

预期：输出 `PASS`。

- [ ] **步骤 3：运行抓取链接重写测试**

运行：`powershell -NoProfile -ExecutionPolicy Bypass -File .\test-fetch-am.ps1`

预期：输出 `PASS`。

- [ ] **步骤 4：本地重建静态页面**

运行：`powershell -NoProfile -ExecutionPolicy Bypass -File .\build-data.ps1 -RootDir .`

预期：输出 `Records:`、`Saved: .\data\records.json`、`Saved: .\dashboard.html`、`Saved: .\report.html`。

## 自查结果

- 规范覆盖：计划覆盖 Vercel API、Blob 存储、Cron、看板按钮、线上数据加载、部署说明和验证。
- 占位符扫描：没有 `TBD`、`TODO` 或未定义的测试步骤。
- 类型一致性：线上 payload 沿用看板已有 `summary`、`records`、`predictions`、`games`、`forecasts` 字段，前端回退到内嵌 JSON。
