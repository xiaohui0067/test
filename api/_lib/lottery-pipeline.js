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

function parseRecordBlocks(html, source, year, fileName) {
  const records = [];
  const issueText = '(?:期|&#26399;)';
  const openText = '(?:开奖时间|&#24320;&#22870;&#26102;&#38388;)';
  const recordPattern = new RegExp(`<li>\\s*<dt><b>(\\d+)<\\/b>${issueText}\\(${openText}:(\\d{4}-\\d{2}-\\d{2})\\)<\\/dt>\\s*<dl>([\\s\\S]*?)<\\/dl>\\s*<\\/li>`, 'gi');
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
