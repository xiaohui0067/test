import fs from "node:fs";
import path from "node:path";

const workspace = process.cwd();
const fifaUrl = "https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/match-schedule-fixtures-results-teams-stadiums";
const fifaStandingsUrl = "https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/standings";
const sporttery500Url = "https://trade.500.com/jczq/";
const injuryUrl = "https://www.sportsgambler.com/injuries/football/fifa-world-cup/";
const worldCupGoalSummaryUrl = "https://datahub.io/football/worldcup/_r/-/goal-timing-by-tournament-summary.csv";
const worldCupAppearancesUrl = "https://datahub.io/football/worldcup/_r/-/tournament-appearances.csv";
const footballRatingsUrl = "https://www.footballratings.org/";
const fifaRankingUrl = "https://inside.fifa.com/en/fifa-world-ranking/men";
const fifaRankingApiUrl = "https://api.fifa.com/api/v3/rankings/?gender=1&count=211";
const goalProjectedLineupsUrl = "https://www.goal.com/en/lists/probable-line-ups-world-cup-2026-starters-and-expected-starting-xi-of-the-48-national-teams/blt0d21c342d47a4cc2";
const lineupNewsUrls = [
  {name: "FIFA official World Cup news", url: "https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles"},
  {name: "Reuters soccer World Cup news", url: "https://www.reuters.com/sports/soccer/"},
  {name: "AP World Cup news", url: "https://apnews.com/hub/world-cup"},
  {name: "ESPN FIFA World Cup news", url: "https://www.espn.com/soccer/league/_/name/fifa.world"},
  {name: "BBC Sport Football RSS", url: "https://feeds.bbci.co.uk/sport/football/rss.xml", sourceType: "rss"},
  {name: "ESPN Soccer RSS", url: "https://www.espn.com/espn/rss/soccer/news", sourceType: "rss"},
  {name: "Fantasy Football Scout team news", url: "https://www.fantasyfootballscout.co.uk/team-news/", sourceType: "lineup-news"},
  {name: "Yahoo predicted lineups 48 teams", url: "https://sports.yahoo.com/articles/predicted-lineups-48-teams-world-065000142.html", sourceType: "lineup-news"},
  {name: "SportsGambler football lineups", url: "https://www.sportsgambler.com/lineups/football/", sourceType: "lineup-news"},
  {name: "Sports Mole lineup news", url: "https://www.sportsmole.co.uk/football/world-cup/"},
  {name: "FotMob lineup news", url: "https://www.fotmob.com/"},
  {name: "Rotowire lineup news", url: "https://www.rotowire.com/soccer/lineups.php"}
];
const footballdataWorldCupApiUrl = "https://footballdata.io/football-world-cup-api/";
const recentInternationalUrls = [
  "https://raw.githubusercontent.com/openfootball/internationals/master/friendly/2026_friendly.txt",
  "https://raw.githubusercontent.com/openfootball/internationals/master/fifa_world_cup_qualification/2026_fifa_world_cup_qualification.txt",
  "https://raw.githubusercontent.com/openfootball/internationals/master/fifa_world_cup_qualification/2025_fifa_world_cup_qualification.txt"
];

const worldCup2026Venues = [
  {stadium: "Estadio Azteca", city: "Mexico City", country: "Mexico", climateRisk: "medium", timezone: -6, latitude: 19.3029, longitude: -99.1505},
  {stadium: "Estadio Guadalajara", city: "Guadalajara", country: "Mexico", climateRisk: "medium", timezone: -6, latitude: 20.6819, longitude: -103.4624},
  {stadium: "Estadio Monterrey", city: "Monterrey", country: "Mexico", climateRisk: "high", timezone: -6, latitude: 25.6682, longitude: -100.2446},
  {stadium: "BMO Field", city: "Toronto", country: "Canada", climateRisk: "low", timezone: -4, latitude: 43.6332, longitude: -79.4186},
  {stadium: "BC Place", city: "Vancouver", country: "Canada", climateRisk: "low", timezone: -7, latitude: 49.2768, longitude: -123.1119},
  {stadium: "MetLife Stadium", city: "New York/New Jersey", country: "United States", climateRisk: "medium", timezone: -4, latitude: 40.8135, longitude: -74.0745},
  {stadium: "SoFi Stadium", city: "Los Angeles", country: "United States", climateRisk: "low", timezone: -7, latitude: 33.9535, longitude: -118.3392},
  {stadium: "AT&T Stadium", city: "Dallas", country: "United States", climateRisk: "high", timezone: -5, latitude: 32.7473, longitude: -97.0945},
  {stadium: "Mercedes-Benz Stadium", city: "Atlanta", country: "United States", climateRisk: "medium", timezone: -4, latitude: 33.7554, longitude: -84.4008},
  {stadium: "NRG Stadium", city: "Houston", country: "United States", climateRisk: "high", timezone: -5, latitude: 29.6847, longitude: -95.4107},
  {stadium: "Hard Rock Stadium", city: "Miami", country: "United States", climateRisk: "high", timezone: -4, latitude: 25.9580, longitude: -80.2389},
  {stadium: "Lincoln Financial Field", city: "Philadelphia", country: "United States", climateRisk: "medium", timezone: -4, latitude: 39.9008, longitude: -75.1675},
  {stadium: "Lumen Field", city: "Seattle", country: "United States", climateRisk: "low", timezone: -7, latitude: 47.5952, longitude: -122.3316},
  {stadium: "Levi's Stadium", city: "San Francisco Bay Area", country: "United States", climateRisk: "low", timezone: -7, latitude: 37.4030, longitude: -121.9700},
  {stadium: "GEHA Field at Arrowhead Stadium", city: "Kansas City", country: "United States", climateRisk: "medium", timezone: -5, latitude: 39.0490, longitude: -94.4839},
  {stadium: "Gillette Stadium", city: "Boston", country: "United States", climateRisk: "medium", timezone: -4, latitude: 42.0909, longitude: -71.2643}
];

async function fetchText(url) {
  const response = await fetch(url, {
    headers: {
      accept: "text/html,application/json;q=0.9,*/*;q=0.8",
      "accept-language": "zh-CN,zh;q=0.9,en;q=0.7",
      "cache-control": "no-cache",
      referer: "https://www.fifa.com/",
      "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) WorldCupDashboard/1.0"
    },
    signal: AbortSignal.timeout(30000)
  });
  const text = await response.text();
  return {response, text};
}

async function checkSource(name, url) {
  try {
    const {response, text} = await fetchText(url);
    return {
      name,
      url,
      ok: response.ok,
      statusCode: response.status,
      bytes: text.length,
      note: response.ok ? "页面可访问，已用于状态校验。" : `HTTP ${response.status}`
    };
  } catch (error) {
    return {name, url, ok: false, statusCode: 0, bytes: 0, note: error.message};
  }
}

function fallbackWeatherForVenue(venue) {
  const temperatureC = venue.climateRisk === "high" ? 30 : venue.climateRisk === "medium" ? 25 : 20;
  const precipitationMm = venue.climateRisk === "high" ? 0.8 : venue.climateRisk === "medium" ? 0.4 : 0.2;
  const windKph = venue.climateRisk === "high" ? 18 : 12;
  return {
    status: "fallback",
    source: "venue-climate-profile",
    temperatureC,
    precipitationMm,
    windKph,
    weatherRisk: venue.climateRisk || "unknown",
    reason: "当前日期超出逐小时预报窗口或天气源缺失，使用赛地气候画像兜底"
  };
}

function weatherRiskFor({temperatureC, precipitationMm, windKph}, fallbackRisk = "unknown") {
  if (temperatureC >= 31 || precipitationMm >= 6 || windKph >= 32) return "high";
  if (temperatureC >= 27 || precipitationMm >= 2 || windKph >= 22) return "medium";
  if (Number.isFinite(temperatureC)) return "low";
  return fallbackRisk;
}

async function fetchVenueWeatherForecasts() {
  const uniqueVenues = [...new Map(worldCup2026Venues.map(venue => [venue.city, venue])).values()];
  const forecasts = {};
  const sources = [];
  await Promise.all(uniqueVenues.map(async venue => {
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${venue.latitude}&longitude=${venue.longitude}&hourly=temperature_2m,precipitation,wind_speed_10m&forecast_days=16&timezone=auto`;
    try {
      const {response, text} = await fetchText(url);
      const json = response.ok ? JSON.parse(text) : {};
      const hourly = json.hourly || {};
      forecasts[venue.city] = {
        status: response.ok ? "forecast" : "fallback",
        source: "Open-Meteo",
        latitude: venue.latitude,
        longitude: venue.longitude,
        hourlyTime: hourly.time || [],
        temperature: hourly.temperature_2m || [],
        precipitation: hourly.precipitation || [],
        wind: hourly.wind_speed_10m || [],
        fallback: fallbackWeatherForVenue(venue)
      };
      sources.push({name: `Open-Meteo ${venue.city}`, ok: response.ok, statusCode: response.status, bytes: text.length});
    } catch (error) {
      forecasts[venue.city] = {
        status: "fallback",
        source: "Open-Meteo",
        latitude: venue.latitude,
        longitude: venue.longitude,
        hourlyTime: [],
        temperature: [],
        precipitation: [],
        wind: [],
        fallback: fallbackWeatherForVenue(venue),
        error: error.message
      };
      sources.push({name: `Open-Meteo ${venue.city}`, ok: false, statusCode: 0, bytes: 0});
    }
  }));
  return {
    source: {
      name: "Open-Meteo赛地天气预报",
      url: "https://api.open-meteo.com/",
      ok: Object.values(forecasts).some(item => item.status === "forecast"),
      statusCode: sources.some(item => item.ok) ? 200 : 0,
      bytes: sources.reduce((sum, item) => sum + Number(item.bytes || 0), 0),
      note: `已检查${uniqueVenues.length}个世界杯赛地天气，${sources.filter(item => item.ok).length}个赛地返回逐小时预报；超出窗口使用气候画像兜底。`
    },
    forecasts
  };
}

function weatherForMatch(match, venue, weatherForecasts = {}) {
  const row = weatherForecasts[venue.city];
  const fallback = row?.fallback || fallbackWeatherForVenue(venue);
  if (!row || !Array.isArray(row.hourlyTime) || !row.hourlyTime.length) return fallback;
  const start = parseMatchStartTime(match);
  if (!start) return fallback;
  const targetHour = new Date(start);
  targetHour.setMinutes(0, 0, 0);
  const target = targetHour.toISOString().slice(0, 13);
  const index = row.hourlyTime.findIndex(value => String(value).slice(0, 13) === target);
  if (index < 0) return fallback;
  const temperatureC = Number(row.temperature[index]);
  const precipitationMm = Number(row.precipitation[index] || 0);
  const windKph = Number(row.wind[index] || 0);
  const weatherRisk = weatherRiskFor({temperatureC, precipitationMm, windKph}, venue.climateRisk);
  return {
    status: "forecast",
    source: "Open-Meteo",
    temperatureC: round2(temperatureC),
    precipitationMm: round2(precipitationMm),
    windKph: round2(windKph),
    weatherRisk,
    reason: `天气${round2(temperatureC)}C，降雨${round2(precipitationMm)}mm，风速${round2(windKph)}km/h，风险${weatherRisk}`
  };
}

function normalizeName(value) {
  return String(value || "")
    .replace(/\s+/g, "")
    .replace(/[（）()]/g, "")
    .replace(/队/g, "")
    .toLowerCase();
}

function normalizeStatus(value) {
  const text = String(value ?? "");
  if (/开售|销售|可售|在售|selling|sale/i.test(text)) return "开售";
  if (/停售|截止|结束|已关|closed|stop/i.test(text)) return "停售";
  return text || "-";
}

function pickField(record, keys) {
  for (const key of keys) {
    if (record?.[key] !== undefined && record[key] !== null && String(record[key]).trim() !== "") {
      return String(record[key]).trim();
    }
  }
  return "";
}

function collectObjects(value, out = []) {
  if (!value || typeof value !== "object") return out;
  if (!Array.isArray(value)) out.push(value);
  Object.values(value).forEach(item => collectObjects(item, out));
  return out;
}

function parseCsvRows(text) {
  const lines = String(text || "").trim().split(/\r?\n/).filter(Boolean);
  if (lines.length < 2) return [];
  const headers = lines[0].split(",").map(item => item.trim());
  return lines.slice(1).map(line => {
    const cells = line.split(",").map(item => item.trim());
    return Object.fromEntries(headers.map((header, index) => [header, cells[index] || ""]));
  });
}

function canParlayFromRecord(record) {
  const text = JSON.stringify(record);
  if (/单关|不可串|single/i.test(text)) return false;
  return /串关|过关|parlay|had|hhad|crs|bf/i.test(text) || true;
}

function scoreSupportedFromRecord(record) {
  return /比分|score|crs|bf/i.test(JSON.stringify(record));
}

function isWorldCupMatch(item = {}) {
  const league = String(item.league || "");
  return league === "世界杯" || /world\s*cup|fifa\s*world\s*cup|世界杯/i.test(league);
}

function parseJsonCandidates(text) {
  const candidates = [];
  const trimmed = text.trim();
  if (trimmed.startsWith("{") || trimmed.startsWith("[")) candidates.push(trimmed);
  for (const match of text.matchAll(/<script[^>]*>([\s\S]*?)<\/script>/gi)) {
    const jsonLike = match[1].match(/(\{[\s\S]{200,}\})/);
    if (jsonLike) candidates.push(jsonLike[1]);
  }
  return candidates;
}

function parseSportteryMatches(text) {
  const records = [];
  for (const candidate of parseJsonCandidates(text)) {
    try {
      const data = JSON.parse(candidate);
      collectObjects(data).forEach(record => {
        const home = pickField(record, ["homeTeamName", "homeName", "hostName", "hostTeam", "homeTeam", "h_cn", "home"]);
        const away = pickField(record, ["awayTeamName", "awayName", "guestName", "guestTeam", "awayTeam", "a_cn", "away"]);
        if (!home || !away || home === away) return;
        const status = normalizeStatus(pickField(record, ["saleStatus", "status", "matchStatus", "betStatus", "sellStatus"]));
        records.push({
          matchId: pickField(record, ["matchId", "id", "matchNum", "matchNo", "issueNum"]) || `${home}-${away}`,
          league: pickField(record, ["leagueName", "league", "l_cn", "competitionName"]),
          home,
          away,
          teams: `${home} vs ${away}`,
          startTime: pickField(record, ["matchDate", "matchTime", "startTime", "date"]),
          status,
          canParlay: canParlayFromRecord(record),
          scoreSupported: scoreSupportedFromRecord(record),
          rawStatus: pickField(record, ["saleStatus", "status", "matchStatus", "betStatus", "sellStatus"])
        });
      });
    } catch {
      // Ignore non-JSON script blocks.
    }
  }
  return [...new Map(records.map(item => [`${normalizeName(item.home)}-${normalizeName(item.away)}-${item.startTime}`, item])).values()];
}

function getAttributeMap(row) {
  const attrs = {};
  const tag = row.match(/^<tr\s+([^>]*)>/i)?.[1] || "";
  for (const match of tag.matchAll(/([a-zA-Z0-9_-]+)="([^"]*)"/g)) attrs[match[1]] = match[2];
  return attrs;
}

function decodeHtml(value) {
  return String(value || "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .trim();
}

function parseRssItems(xml, limit = 80) {
  const items = [];
  const itemPattern = /<item\b[\s\S]*?<\/item>/gi;
  const tagValue = (item, tag) => {
    const match = item.match(new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, "i"));
    return decodeHtml(String(match?.[1] || "").replace(/<!\[CDATA\[|\]\]>/g, "").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim());
  };
  for (const match of xml.matchAll(itemPattern)) {
    const item = match[0];
    const title = tagValue(item, "title");
    const description = tagValue(item, "description");
    const link = tagValue(item, "link");
    if (title || description) items.push({title, description, link});
    if (items.length >= limit) break;
  }
  return items;
}

function parseChinaTime(value) {
  if (!value) return null;
  const date = new Date(`${String(value).trim().replace(" ", "T")}+08:00`);
  return Number.isNaN(date.getTime()) ? null : date;
}

function parse500SportteryMatches(text) {
  const rows = text.match(/<tr[^>]*class="[^"]*bet-tb-tr[\s\S]*?<\/tr>/gi) || [];
  const now = new Date();
  return rows.map(row => {
    const attrs = getAttributeMap(row);
    if (!attrs["data-matchnum"]) return null;
    const subactive = attrs["data-subactive"] || "";
    const buyEnd = parseChinaTime(attrs["data-buyendtime"]);
    const canParlay = /bfgg:1/.test(subactive);
    const scoreSupported = /bfdg:1|bfgg:1/.test(subactive);
    const isOpen = attrs["data-isactive"] === "1" && attrs["data-isend"] !== "1" && (!buyEnd || buyEnd > now);
    const odds = {};
    for (const match of row.matchAll(/data-type="([^"]+)"\s+data-value="([^"]+)"\s+data-sp="([^"]+)"/g)) {
      const [, type, value, sp] = match;
      if (!odds[type]) odds[type] = {};
      odds[type][value] = Number(sp);
    }
    const home = decodeHtml(attrs["data-homesxname"]);
    const away = decodeHtml(attrs["data-awaysxname"]);
    return {
      matchId: attrs["data-matchnum"],
      league: decodeHtml(attrs["data-simpleleague"]),
      home,
      away,
      teams: `${home} vs ${away}`,
      startTime: `${attrs["data-matchdate"] || ""} ${attrs["data-matchtime"] || ""}`.trim(),
      buyEndTime: attrs["data-buyendtime"] || "",
      status: isOpen ? "开售" : "已截止",
      canParlay,
      scoreSupported,
      odds,
      rawStatus: `isend=${attrs["data-isend"] || ""}; subactive=${subactive}`,
      source: "500彩票网"
    };
  }).filter(item => item && item.home && item.away && item.canParlay && item.scoreSupported && item.status === "开售");
}

async function fetch500SportteryMatches() {
  try {
    const response = await fetch(sporttery500Url, {
      headers: {
        accept: "text/html,*/*;q=0.8",
        "accept-language": "zh-CN,zh;q=0.9,en;q=0.7",
        "cache-control": "no-cache",
        referer: "https://www.500.com/",
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) WorldCupDashboard/1.0"
      },
      signal: AbortSignal.timeout(30000)
    });
    const buffer = Buffer.from(await response.arrayBuffer());
    const text = new TextDecoder("gb18030").decode(buffer);
    const matches = response.ok ? parse500SportteryMatches(text).filter(isWorldCupMatch) : [];
    return {
      source: {
        name: "500彩票网竞彩开售列表",
        url: sporttery500Url,
        ok: response.ok && matches.length > 0,
        statusCode: response.status,
        bytes: buffer.length,
        note: response.ok ? `解析到 ${matches.length} 场当前可串关比分赛事。` : `HTTP ${response.status}，未使用静态赛事兜底。`
      },
      matches
    };
  } catch (error) {
    return {
      source: {name: "500彩票网竞彩开售列表", url: sporttery500Url, ok: false, statusCode: 0, bytes: 0, note: `${error.message}，未使用静态赛事兜底。`},
      matches: []
    };
  }
}

function loadPreviousOpenMatches() {
  try {
    const file = path.join(workspace, "worldcup2026-live-data.json");
    if (!fs.existsSync(file)) return [];
    const previous = JSON.parse(fs.readFileSync(file, "utf8"));
    const matches = Array.isArray(previous.jcMatches)
      ? previous.jcMatches
        .filter(item => item && item.home && item.away && item.scoreSupported !== false && isWorldCupMatch(item))
        .map(({model, ...item}) => item)
      : [];
    if (matches.length) return matches;
    return [];
    const historyFile = path.join(workspace, "worldcup2026-odds-history.json");
    if (!fs.existsSync(historyFile)) return [];
    const history = JSON.parse(fs.readFileSync(historyFile, "utf8"));
    const snapshot = Array.isArray(history.snapshots) ? history.snapshots.findLast(item => Array.isArray(item.matches) && item.matches.length) : null;
    return snapshot
      ? snapshot.matches.map(item => {
        const [home, away] = String(item.teams || "").split(/\s+vs\s+/i).map(part => part.trim());
        return home && away ? {
          matchId: item.matchId,
          league: "历史开售快照",
          teams: item.teams,
          home,
          away,
          startTime: item.startTime,
          canParlay: true,
          scoreSupported: true,
          status: "历史兜底",
          rawStatus: "history-fallback"
        } : null;
      }).filter(Boolean)
      : [];
  } catch {
    return [];
  }
}

function stripTags(value) {
  return decodeHtml(String(value || "").replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim());
}

function parseInjuryReport(text) {
  const report = {};
  const headings = [...text.matchAll(/<h[23][^>]*>([\s\S]*?)<\/h[23]>/gi)];
  for (let index = 0; index < headings.length; index++) {
    const team = stripTags(headings[index][1]);
    if (!team || team.length > 40) continue;
    const start = headings[index].index + headings[index][0].length;
    const end = index + 1 < headings.length ? headings[index + 1].index : text.length;
    const section = text.slice(start, end);
    const clean = stripTags(section);
    const hasIssue = /injur|suspend|doubt|out|questionable|fitness|hamstring|knee|ankle|muscle/i.test(clean);
    const noIssue = /no injuries|no players are currently reported|full squad|clean bill/i.test(clean);
    report[normalizeName(team)] = {
      team,
      injuryStatus: hasIssue ? "reported-issues" : noIssue ? "reported-clear" : "unknown",
      summary: clean.slice(0, 180) || "暂无公开伤停摘要",
      source: "Sportsgambler injuries"
    };
  }
  return report;
}

async function fetchInjuryReport() {
  try {
    const {response, text} = await fetchText(injuryUrl);
    const report = response.ok ? parseInjuryReport(text) : {};
    return {
      source: {
        name: "Sportsgambler 世界杯伤停",
        url: injuryUrl,
        ok: response.ok,
        statusCode: response.status,
        bytes: text.length,
        note: response.ok ? `已读取公开伤停页，解析 ${Object.keys(report).length} 支球队。` : `HTTP ${response.status}`
      },
      report
    };
  } catch (error) {
    return {
      source: {name: "Sportsgambler 世界杯伤停", url: injuryUrl, ok: false, statusCode: 0, bytes: 0, note: error.message},
      report: {}
    };
  }
}

async function fetchHistoricalWorldCupSummary() {
  try {
    const [{response: goalsResponse, text: goalsText}, {response: appearancesResponse, text: appearancesText}] = await Promise.all([
      fetchText(worldCupGoalSummaryUrl),
      fetchText(worldCupAppearancesUrl)
    ]);
    const goalRows = goalsResponse.ok ? parseCsvRows(goalsText) : [];
    const appearanceRows = appearancesResponse.ok ? parseCsvRows(appearancesText) : [];
    const recentRows = goalRows.slice(-5);
    const averageGoals = recentRows.length
      ? round2(recentRows.reduce((sum, row) => sum + Number(row.goals_per_match || 0), 0) / recentRows.length)
      : 0;
    const teamAppearances = Object.fromEntries(appearanceRows.map(row => [normalizeName(row.team_name), Number(row.appearances || 0)]));
    return {
      source: {
        name: "历史世界杯比分分布",
        url: worldCupGoalSummaryUrl,
        ok: goalsResponse.ok && appearancesResponse.ok,
        statusCode: goalsResponse.status,
        bytes: goalsText.length + appearancesText.length,
        note: `DataHub历史世界杯CSV：近5届均场进球${averageGoals || "未知"}，球队参赛经验${appearanceRows.length}队。`
      },
      summary: {averageGoals, teamAppearances}
    };
  } catch (error) {
    return {
      source: {...historicalWorldCupScoreSource, ok: false, statusCode: 0, bytes: 0, note: `DataHub历史世界杯CSV抓取失败：${error.message}，使用本地先验。`},
      summary: {averageGoals: 0, teamAppearances: {}}
    };
  }
}

function parseFootballRatings(text) {
  const teams = {};
  for (const [team, profile] of Object.entries(teamStyleProfile)) {
    const normalized = normalizeName(team);
    const display = englishTeamNames[team] || team.replace(/[()]/g, "");
    const index = text.toLowerCase().indexOf(display.toLowerCase());
    if (index < 0) continue;
    const rawChunk = text.slice(Math.max(0, index - 900), index + 900);
    const chunk = rawChunk.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ");
    const quality = chunk.match(/\b(Excellent|Great|Good|Average|Poor)\b/)?.[1] || "";
    const formLetters = [...rawChunk.matchAll(/>([WDL])</g)].map(match => match[1]).slice(-5).join("");
    teams[normalized] = {quality, form: formLetters, attack: profile.attack, defense: profile.defense, style: profile.style};
  }
  return teams;
}

async function fetchFootballRatingsProfile() {
  try {
    const {response, text} = await fetchText(footballRatingsUrl);
    const teams = response.ok ? parseFootballRatings(text) : {};
    return {
      source: {
        name: "FIFA排名/Elo/近期状态综合画像",
        url: footballRatingsUrl,
        ok: response.ok && Object.keys(teams).length > 0,
        statusCode: response.status,
        bytes: text.length,
        note: response.ok ? `FootballRatings页面可访问，解析${Object.keys(teams).length}队排名/近况片段，并结合本地风格画像。` : `HTTP ${response.status}，使用本地球队画像。`
      },
      ratings: teams
    };
  } catch (error) {
    return {
      source: {...teamProfileSource, ok: false, statusCode: 0, bytes: 0, note: `FootballRatings抓取失败：${error.message}，使用本地球队画像。`},
      ratings: {}
    };
  }
}

function fallbackFifaRankings() {
  return Object.fromEntries(Object.entries(teamStrength)
    .sort((a, b) => b[1] - a[1])
    .map(([team, strength], index) => [normalizeName(team), {team, rank: index + 1, points: strength * 10, source: "local-strength-fallback"}]));
}

function parseFifaRankings(text) {
  const rankings = {};
  const raw = String(text || "");
  try {
    const data = JSON.parse(raw);
    for (const item of data.Results || []) {
      const english = item.TeamName?.find?.(row => row.Locale === "en-GB")?.Description || item.TeamName?.[0]?.Description || "";
      const local = englishToLocalTeam.get(normalizeName(english)) || english;
      if (!local || !item.Rank) continue;
      rankings[normalizeName(local)] = {
        team: local,
        rank: Number(item.Rank),
        previousRank: Number(item.PrevRank || item.Rank),
        points: Number(item.DecimalTotalPoints || item.TotalPoints || 0),
        countryCode: item.IdCountry || "",
        source: "fifa-official-api"
      };
    }
    if (Object.keys(rankings).length) return rankings;
  } catch {}
  const clean = raw.replace(/\\u002F/g, "/");
  for (const [team, english] of Object.entries(englishTeamNames)) {
    const normalizedEnglish = String(english).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const nearby = clean.match(new RegExp(`(.{0,120})${normalizedEnglish}(.{0,120})`, "i"))?.[0] || "";
    const rank = Number(nearby.match(/rank(?:ing)?["':\\s-]*(\\d{1,3})/i)?.[1] || nearby.match(/#\\s*(\\d{1,3})/)?.[1] || 0);
    if (rank) rankings[normalizeName(team)] = {team, rank, source: "fifa-official"};
  }
  return rankings;
}

async function fetchFifaRankings() {
  try {
    const [page, api] = await Promise.all([
      fetchText(fifaRankingUrl),
      fetchText(fifaRankingApiUrl)
    ]);
    const parsed = api.response.ok ? parseFifaRankings(api.text) : {};
    const rankings = Object.keys(parsed).length >= 8 ? parsed : fallbackFifaRankings();
    return {
      source: {
        name: "FIFA官方排名",
        url: fifaRankingApiUrl,
        ok: api.response.ok && Object.keys(parsed).length >= 8,
        statusCode: api.response.status,
        bytes: api.text.length + page.text.length,
        note: api.response.ok && Object.keys(parsed).length >= 8
          ? `FIFA官方排名API解析${Object.keys(parsed).length}队，官方页面状态${page.response.status}。`
          : `FIFA官方排名API未解析到稳定结构，官方页面状态${page.response.status}，使用本地强度顺序回退${Object.keys(rankings).length}队。`
      },
      rankings
    };
  } catch (error) {
    const rankings = fallbackFifaRankings();
    return {
      source: {name: "FIFA官方排名", url: fifaRankingUrl, ok: false, statusCode: 0, bytes: 0, note: `抓取失败：${error.message}，使用本地强度顺序回退。`},
      rankings
    };
  }
}

function parseProjectedLineups(text) {
  const lineups = {};
  const clean = stripTags(text)
    .replace(/&#x27;/g, "'")
    .replace(/&amp;/g, "&")
    .replace(/\s+/g, " ");
  const blocks = [...clean.matchAll(/PROBABLE\s+([A-Z][A-Z\s().'-]+?)\s+LINEUP\s*\(([^)]+)\)\s*:\s*([\s\S]*?)(?=\s+Coach\s*:|\s+PROBABLE\s+[A-Z][A-Z\s().'-]+?\s+LINEUP\s*\(|$)/gi)];
  const byEnglish = new Map();
  for (const match of blocks) {
    const english = match[1].replace(/\s+/g, " ").trim();
    const formation = match[2].replace(/\s+/g, "").trim();
    const playerText = match[3].replace(/\s+Advertisement\s+/gi, " ").trim();
    const players = playerText
      .split(/[;,]/)
      .map(item => item.replace(/\s+/g, " ").trim())
      .filter(Boolean)
      .slice(0, 11);
    if (!formation || players.length < 8) continue;
    byEnglish.set(normalizeName(english), {formation, players, summary: playerText.slice(0, 260)});
  }
  for (const [team, english] of Object.entries(englishTeamNames)) {
    const parsed = byEnglish.get(normalizeName(english));
    if (!parsed) continue;
    lineups[normalizeName(team)] = {
      team,
      status: "projected",
      formation: parsed.formation,
      source: "Goal probable lineups",
      keyPlayers: parsed.players,
      summary: parsed.summary
    };
  }
  return lineups;
}

async function fetchProjectedLineups() {
  try {
    const {response, text} = await fetchText(goalProjectedLineupsUrl);
    const lineups = response.ok ? parseProjectedLineups(text) : {};
    return {
      source: {
        name: "预计首发 Goal.com",
        url: goalProjectedLineupsUrl,
        ok: response.ok && Object.keys(lineups).length > 0,
        statusCode: response.status,
        bytes: text.length,
        note: response.ok ? `读取预计首发页，解析${Object.keys(lineups).length}队线索。` : `HTTP ${response.status}`
      },
      sources: [{
        name: "Goal.com probable lineups",
        url: goalProjectedLineupsUrl,
        sourceType: "structured-lineup",
        structured: Object.keys(lineups).length > 0,
        parsedTeams: Object.keys(lineups).length,
        ok: response.ok && Object.keys(lineups).length > 0,
        statusCode: response.status
      }],
      lineups
    };
  } catch (error) {
    return {
      source: {name: "预计首发 Goal.com", url: goalProjectedLineupsUrl, ok: false, statusCode: 0, bytes: 0, note: error.message},
      sources: [{
        name: "Goal.com probable lineups",
        url: goalProjectedLineupsUrl,
        sourceType: "structured-lineup",
        structured: false,
        parsedTeams: 0,
        ok: false,
        statusCode: 0,
        note: error.message
      }],
      lineups: {}
    };
  }
}

async function fetchLineupNewsDiagnostics() {
  const sources = await Promise.all(lineupNewsUrls.map(async item => {
    try {
      const {response, text} = await fetchText(item.url);
      const feedItems = item.sourceType === "rss" && response.ok ? parseRssItems(text) : [];
      const clean = item.sourceType === "rss"
        ? feedItems.map(row => `${row.title} ${row.description} ${row.link}`).join(" ").slice(0, 50000)
        : stripTags(text).slice(0, 50000);
      const hasWorldCupSignal = /world cup|fifa|national team|lineups?|injur/i.test(clean);
      const sourceTier = sourceTierFor(item.name, item.url);
      return {
        name: item.name,
        url: item.url,
        sourceType: item.sourceType || "html",
        sourceTier,
        ok: response.ok,
        statusCode: response.status,
        bytes: text.length,
        feedItems: feedItems.length,
        feedSearchItems: feedItems.slice(0, 80),
        hasWorldCupSignal,
        searchText: clean,
        note: response.ok
          ? (hasWorldCupSignal ? "页面可访问，存在阵容/伤停/国家队相关线索；当前仅作诊断，不直接提升首发可信度。" : "页面可访问，但未识别到稳定世界杯阵容结构。")
          : `HTTP ${response.status}`
      };
    } catch (error) {
      return {name: item.name, url: item.url, sourceType: item.sourceType || "html", sourceTier: sourceTierFor(item.name, item.url), ok: false, statusCode: 0, bytes: 0, feedItems: 0, feedSearchItems: [], hasWorldCupSignal: false, note: error.message};
    }
  }));
  return {
    source: {
      name: "阵容新闻替代源诊断",
      url: "multi:SportsMole,FotMob,Rotowire",
      ok: sources.some(item => item.ok),
      statusCode: sources.some(item => item.ok) ? 200 : 0,
      bytes: sources.reduce((sum, item) => sum + Number(item.bytes || 0), 0),
      note: `已检查${sources.length}个阵容新闻替代源，${sources.filter(item => item.ok).length}个可访问；仅作阵容短板诊断。`
    },
    sources: sources.map(({searchText, feedSearchItems, ...source}) => source),
    searchSources: sources
  };
}

async function checkFootballDataApiSource() {
  try {
    const {response, text} = await fetchText(footballdataWorldCupApiUrl);
    return {
      source: {
        name: "Footballdata赛果API",
        url: footballdataWorldCupApiUrl,
        ok: response.ok,
        statusCode: response.status,
        bytes: text.length,
        note: response.ok ? "API说明页可访问；当前仍以OpenFootball公开文本作为无密钥赛果输入。" : `HTTP ${response.status}，保留OpenFootball回退。`
      },
      apiAvailable: response.ok
    };
  } catch (error) {
    return {
      source: {name: "Footballdata赛果API", url: footballdataWorldCupApiUrl, ok: false, statusCode: 0, bytes: 0, note: `${error.message}，保留OpenFootball回退。`},
      apiAvailable: false
    };
  }
}

function parseOpenFootballDate(value) {
  const match = String(value || "").match(/\b([A-Z][a-z]{2})\/(\d{1,2})\b/) || String(value || "").match(/\b(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)\s+([A-Z][a-z]{2})\s+(\d{1,2})\b/);
  if (!match) return null;
  const monthIndex = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"].indexOf(match[1]);
  if (monthIndex < 0) return null;
  const yearMatch = String(value || "").match(/\b(2025|2026)\b/);
  const year = yearMatch ? Number(yearMatch[1]) : 2026;
  return new Date(Date.UTC(year, monthIndex, Number(match[2])));
}

function recentMatchWeight(matchType, dateText) {
  const typeWeight = matchType === "world-cup-qualification" ? 1.18 : 0.72;
  const parsed = parseOpenFootballDate(dateText);
  if (!parsed) return typeWeight;
  const anchor = new Date(Date.UTC(2026, 5, 10));
  const ageDays = Math.max(0, Math.round((anchor - parsed) / 86400000));
  const decay = Math.max(0.55, Math.exp(-ageDays / 420));
  return round2(typeWeight * decay);
}

function parseOpenFootballResults(text, meta = {}) {
  const rows = [];
  let currentDate = "";
  for (const rawLine of String(text || "").split(/\r?\n/)) {
    const line = rawLine.trimEnd();
    if (/^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\s/.test(line.trim())) {
      currentDate = line.trim();
      continue;
    }
    const match = line.match(/^\s{2,}(.+?)\s{2,}(\d+)-(\d+)\s+(.+?)(?:\s{2,}|$)/);
    if (!match) continue;
    rows.push({
      date: currentDate,
      home: match[1].trim(),
      away: match[4].trim(),
      homeGoals: Number(match[2]),
      awayGoals: Number(match[3]),
      matchType: meta.matchType || "friendly",
      sourceUrl: meta.url || "",
      weight: recentMatchWeight(meta.matchType || "friendly", currentDate)
    });
  }
  return rows;
}

function addRecentResult(stats, team, opponent, goalsFor, goalsAgainst, match = {}) {
  const key = normalizeName(canonicalTeamName(team));
  const row = stats[key] || {played: 0, weightedPlayed: 0, goalsFor: 0, goalsAgainst: 0, adjustedFor: 0, adjustedAgainst: 0, weightedFor: 0, weightedAgainst: 0, opponentStrengthSum: 0, weightedOpponentStrengthSum: 0, competitiveCount: 0, strongOpponentCount: 0, matchTypeMix: {}, form: [], recentMatches: []};
  const canonicalOpponent = canonicalTeamName(opponent);
  const opponentMapped = normalizeName(canonicalOpponent) !== normalizeName(opponent) || Boolean(teamStrength[canonicalOpponent]);
  const opponentStrength = strengthOf(opponent);
  const opponentFactor = Math.max(0.72, Math.min(1.35, opponentStrength / 70));
  const weight = Number(match.weight || 1);
  const type = match.matchType || "friendly";
  const parsedDate = parseOpenFootballDate(match.date);
  row.played += 1;
  row.weightedPlayed += weight;
  row.goalsFor += goalsFor;
  row.goalsAgainst += goalsAgainst;
  row.adjustedFor += goalsFor * opponentFactor;
  row.adjustedAgainst += goalsAgainst / opponentFactor;
  row.weightedFor += goalsFor * opponentFactor * weight;
  row.weightedAgainst += (goalsAgainst / opponentFactor) * weight;
  row.opponentStrengthSum += opponentStrength;
  row.weightedOpponentStrengthSum += opponentStrength * weight;
  if (type !== "friendly") row.competitiveCount += 1;
  if (opponentStrength >= 74) row.strongOpponentCount += 1;
  row.matchTypeMix[type] = (row.matchTypeMix[type] || 0) + 1;
  row.form.push(goalsFor > goalsAgainst ? "W" : goalsFor === goalsAgainst ? "D" : "L");
  row.recentMatches.push({
    date: parsedDate ? parsedDate.toISOString().slice(0, 10) : "",
    opponent: canonicalOpponent,
    opponentMapped,
    goalsFor,
    goalsAgainst,
    matchType: type,
    opponentStrength,
    weight
  });
  stats[key] = row;
}

async function fetchRecentInternationalResults() {
  try {
    const responses = await Promise.all(recentInternationalUrls.map(async url => {
      const {response, text} = await fetchText(url);
      return {url, response, text};
    }));
    const matches = responses.flatMap(item => {
      if (!item.response.ok) return [];
      const matchType = item.url.includes("qualification") ? "world-cup-qualification" : "friendly";
      return parseOpenFootballResults(item.text, {url: item.url, matchType});
    });
    const stats = {};
    for (const match of matches) {
      addRecentResult(stats, match.home, match.away, match.homeGoals, match.awayGoals, match);
      addRecentResult(stats, match.away, match.home, match.awayGoals, match.homeGoals, match);
    }
    for (const row of Object.values(stats)) {
      row.avgFor = round2(row.goalsFor / Math.max(1, row.played));
      row.avgAgainst = round2(row.goalsAgainst / Math.max(1, row.played));
      row.adjustedAvgFor = round2(row.adjustedFor / Math.max(1, row.played));
      row.adjustedAvgAgainst = round2(row.adjustedAgainst / Math.max(1, row.played));
      row.adjustedGoalDiff = round2(row.adjustedAvgFor - row.adjustedAvgAgainst);
      row.avgOpponentStrength = round2(row.opponentStrengthSum / Math.max(1, row.played));
      row.weightedPlayed = round2(row.weightedPlayed);
      row.weightedAvgFor = round2(row.weightedFor / Math.max(0.01, row.weightedPlayed));
      row.weightedAvgAgainst = round2(row.weightedAgainst / Math.max(0.01, row.weightedPlayed));
      row.weightedGoalDiff = round2(row.weightedAvgFor - row.weightedAvgAgainst);
      row.weightedAvgOpponentStrength = round2(row.weightedOpponentStrengthSum / Math.max(0.01, row.weightedPlayed));
      row.competitiveShare = round2(row.competitiveCount / Math.max(1, row.played));
      row.strongOpponentShare = round2(row.strongOpponentCount / Math.max(1, row.played));
      row.recentMatches = row.recentMatches
        .sort((a, b) => String(b.date).localeCompare(String(a.date)))
        .slice(0, 6);
      row.lastMatchDate = row.recentMatches[0]?.date || "";
      row.sampleQuality = Math.min(100, Math.round(Math.min(8, row.weightedPlayed) * 9 + Math.min(18, Math.max(0, row.weightedAvgOpponentStrength - 58))));
      row.form = row.form.slice(-5).join("");
    }
    for (const local of new Set([...Object.keys(englishTeamNames), ...Object.keys(teamAliasNames)])) {
      const row = lookupTeamRow(stats, local);
      if (row) stats[local] = row;
    }
    return {
      source: {
        name: "近期国家队赛果",
        url: "https://github.com/openfootball/internationals",
        ok: matches.length > 0,
        statusCode: responses.some(item => item.response.ok) ? 200 : 0,
        bytes: responses.reduce((sum, item) => sum + item.text.length, 0),
        note: `OpenFootball internationals：解析${matches.length}场2025-2026国家队赛果，形成${Object.keys(stats).length}队近期进失球和状态。`
      },
      stats
    };
  } catch (error) {
    return {
      source: {name: "近期国家队赛果", url: "https://github.com/openfootball/internationals", ok: false, statusCode: 0, bytes: 0, note: `OpenFootball抓取失败：${error.message}`},
      stats: {}
    };
  }
}

const groups = [
  ["A", [["墨西哥", "safe"], ["南非", ""], ["韩国", "risk"], ["捷克", "risk"]]],
  ["B", [["加拿大", "risk"], ["瑞士", "safe"], ["卡塔尔", ""], ["波黑", "risk"]]],
  ["C", [["巴西", "hot"], ["摩洛哥", "safe"], ["海地", ""], ["苏格兰", "risk"]]],
  ["D", [["美国", "safe"], ["巴拉圭", "risk"], ["澳大利亚", ""], ["土耳其", "risk"]]],
  ["E", [["德国", "hot"], ["库拉索", ""], ["科特迪瓦", "risk"], ["厄瓜多尔", "safe"]]],
  ["F", [["荷兰", "hot"], ["日本", "risk"], ["突尼斯", ""], ["瑞典", "safe"]]],
  ["G", [["比利时", "safe"], ["埃及", "risk"], ["伊朗", "risk"], ["新西兰", ""]]],
  ["H", [["西班牙", "hot"], ["佛得角", ""], ["沙特", "risk"], ["乌拉圭", "safe"]]],
  ["I", [["法国", "hot"], ["塞内加尔", "risk"], ["挪威", "safe"], ["伊拉克", ""]]],
  ["J", [["阿根廷", "hot"], ["阿尔及利亚", "risk"], ["奥地利", "safe"], ["约旦", ""]]],
  ["K", [["葡萄牙", "hot"], ["乌兹别克斯坦", ""], ["哥伦比亚", "safe"], ["刚果(金)", "risk"]]],
  ["L", [["英格兰", "hot"], ["克罗地亚", "safe"], ["巴拿马", ""], ["加纳", "risk"]]]
];

const leaders = [
  {team: "法国", note: "阵容厚度最完整", pct: 89},
  {team: "西班牙", note: "控球与边路爆点", pct: 88},
  {team: "阿根廷", note: "大赛经验极强", pct: 86},
  {team: "英格兰", note: "中前场人才密度高", pct: 85},
  {team: "巴西", note: "前场上限极高", pct: 84},
  {team: "葡萄牙", note: "阵容均衡且选择多", pct: 83},
  {team: "德国", note: "强弱差明显", pct: 82},
  {team: "荷兰", note: "防线与转换稳定", pct: 78}
];

const teamStrength = {
  法国: 92, 西班牙: 91, 阿根廷: 90, 英格兰: 89, 巴西: 88, 葡萄牙: 87, 德国: 86, 荷兰: 84,
  比利时: 82, 乌拉圭: 81, 克罗地亚: 80, 瑞士: 79, 哥伦比亚: 79, 摩洛哥: 78, 日本: 77, 美国: 76,
  塞内加尔: 76, 挪威: 75, 厄瓜多尔: 75, 瑞典: 74, 奥地利: 74, 科特迪瓦: 73, 韩国: 72, 土耳其: 72,
  澳大利亚: 71, 巴拉圭: 71, 苏格兰: 70, 伊朗: 70, 加拿大: 70, 墨西哥: 70, 捷克: 69, 突尼斯: 68,
  波黑: 67, 南非: 66, 卡塔尔: 65, 沙特: 65, 乌兹别克斯坦: 64, 新西兰: 63, 阿尔及利亚: 63,
  "刚果(金)": 62, 刚果: 62, 巴拿马: 61, 加纳: 61, 伊拉克: 60, 佛得角: 59, 库拉索: 58, 约旦: 58, 海地: 56
};

const groupByTeam = new Map(groups.flatMap(([group, teams]) => teams.map(([team, tier]) => [normalizeName(team), {group, tier: tier || "outsider"}])));

const contenderTiers = {
  法国: "title", 西班牙: "title", 阿根廷: "title", 英格兰: "title", 巴西: "title", 葡萄牙: "title",
  德国: "contender", 荷兰: "contender", 比利时: "contender",
  乌拉圭: "danger", 克罗地亚: "danger", 哥伦比亚: "danger", 摩洛哥: "danger", 瑞士: "danger", 日本: "danger", 美国: "danger",
  塞内加尔: "darkhorse", 挪威: "darkhorse", 瑞典: "darkhorse", 厄瓜多尔: "darkhorse", 奥地利: "darkhorse", 科特迪瓦: "darkhorse", 韩国: "darkhorse"
};

const latestPublicRiskNotes = [
  {team: "伊朗", flag: "公开资讯扰动", weight: 12, note: "公开报道曾出现团队签证/出行不确定性，赛前准备质量需打折。"},
  {team: "刚果(金)", flag: "公开资讯扰动", weight: 10, note: "近期公开热身赛资讯出现非竞技扰动，体能与备战连续性需打折。"}
];

const historicalWorldCupScoreSource = {
  name: "历史世界杯比分分布",
  url: "local:world-cup-score-priors",
  ok: true,
  statusCode: 0,
  bytes: 14,
  note: "使用历届世界杯常见比分结构作专家判断先验，覆盖小胜、两球胜、三球打穿和强队丢球场景。"
};

const teamProfileSource = {
  name: "FIFA排名/Elo/近期状态综合画像",
  url: "local:team-strength-style-profile",
  ok: true,
  statusCode: 0,
  bytes: Object.keys(teamStrength).length,
  note: "使用本地球队强度、争冠档位、风格标签、伤停和公开资讯扰动形成赛前分析画像。"
};

const teamStyleProfile = {
  法国: {attack: 92, defense: 86, style: "速度冲击和阵容厚度", bigWin: true},
  西班牙: {attack: 90, defense: 84, style: "控球压制和边路推进", bigWin: true},
  阿根廷: {attack: 88, defense: 85, style: "控场经验和前场效率", bigWin: true},
  英格兰: {attack: 88, defense: 83, style: "中前场冲击和定位球", bigWin: true},
  巴西: {attack: 91, defense: 80, style: "前场个人能力和转换", bigWin: true},
  葡萄牙: {attack: 89, defense: 82, style: "边路和中前场层次", bigWin: true},
  德国: {attack: 86, defense: 80, style: "压迫和禁区冲击", bigWin: true},
  荷兰: {attack: 82, defense: 82, style: "防线稳定和转换", bigWin: false},
  乌拉圭: {attack: 80, defense: 81, style: "身体对抗和直接冲击", bigWin: false},
  摩洛哥: {attack: 76, defense: 82, style: "低位纪律和快速反击", bigWin: false},
  日本: {attack: 77, defense: 78, style: "节奏纪律和转换速度", bigWin: false},
  塞内加尔: {attack: 77, defense: 77, style: "身体对抗和边路速度", bigWin: false},
  克罗地亚: {attack: 76, defense: 79, style: "控节奏和中场经验", bigWin: false},
  瑞士: {attack: 76, defense: 80, style: "整体防守和定位球", bigWin: false},
  哥伦比亚: {attack: 79, defense: 76, style: "前场创造和对抗", bigWin: false},
  冰岛: {attack: 61, defense: 64, style: "低位防守和定位球", vulnerable: true},
  佛得角: {attack: 60, defense: 62, style: "低位防守", vulnerable: true},
  库拉索: {attack: 59, defense: 61, style: "防守承压", vulnerable: true},
  阿尔及利亚: {attack: 66, defense: 67, style: "反击和对抗", vulnerable: false},
  刚果: {attack: 64, defense: 62, style: "身体对抗但防线波动", vulnerable: true},
  "刚果(金)": {attack: 64, defense: 62, style: "身体对抗但防线波动", vulnerable: true},
  约旦: {attack: 59, defense: 62, style: "低位防守", vulnerable: true},
  海地: {attack: 58, defense: 59, style: "防线承压", vulnerable: true},
  伊拉克: {attack: 61, defense: 62, style: "低位防守和反击", vulnerable: true},
  乌兹别克斯坦: {attack: 64, defense: 66, style: "组织纪律和反击", vulnerable: false}
};

const englishTeamNames = {
  法国: "France", 西班牙: "Spain", 阿根廷: "Argentina", 英格兰: "England", 巴西: "Brazil", 葡萄牙: "Portugal", 德国: "Germany", 荷兰: "Netherlands",
  比利时: "Belgium", 乌拉圭: "Uruguay", 克罗地亚: "Croatia", 瑞士: "Switzerland", 哥伦比亚: "Colombia", 摩洛哥: "Morocco", 日本: "Japan", 美国: "United States",
  塞内加尔: "Senegal", 挪威: "Norway", 厄瓜多尔: "Ecuador", 瑞典: "Sweden", 奥地利: "Austria", 科特迪瓦: "Ivory Coast", 韩国: "South Korea", 土耳其: "Turkey",
  澳大利亚: "Australia", 巴拉圭: "Paraguay", 苏格兰: "Scotland", 伊朗: "Iran", 加拿大: "Canada", 墨西哥: "Mexico", 捷克: "Czech Republic", 突尼斯: "Tunisia",
  波黑: "Bosnia and Herzegovina", 南非: "South Africa", 卡塔尔: "Qatar", 沙特: "Saudi Arabia", 沙特阿拉伯: "Saudi Arabia", 乌兹别克斯坦: "Uzbekistan", 乌兹别克: "Uzbekistan",
  新西兰: "New Zealand", 阿尔及利亚: "Algeria", "刚果(金)": "DR Congo", 刚果: "DR Congo", 巴拿马: "Panama", 加纳: "Ghana", 伊拉克: "Iraq", 佛得角: "Cape Verde",
  库拉索: "Curacao", 约旦: "Jordan", 海地: "Haiti", 冰岛: "Iceland", 匈牙利: "Hungary", 哈萨克: "Kazakhstan", 泰国: "Thailand", 中国: "China"
};

const englishToLocalTeam = new Map(Object.entries(englishTeamNames).flatMap(([local, english]) => [
  [normalizeName(english), local],
  [normalizeName(local), local]
]));

const teamAliasNames = {
  "尼日利亚": ["Nigeria"],
  "埃及": ["Egypt"],
  "哥斯达": ["Costa Rica"],
  "玻利维亚": ["Bolivia"],
  "刚果(金)": ["DR Congo", "Congo DR", "Congo Kinshasa", "Congo"],
  "沙特阿拉伯": ["Saudi Arabia"],
  "乌兹别克": ["Uzbekistan"],
  "美国": ["United States", "USA"],
  "韩国": ["South Korea", "Korea Republic"],
  "捷克": ["Czech Republic", "Czechia"],
  "波黑": ["Bosnia and Herzegovina", "Bosnia-Herzegovina"],
  "库拉索": ["Curacao", "Curaçao"],
  "科特迪瓦": ["Ivory Coast", "Cote d'Ivoire"],
  "佛得角": ["Cape Verde", "Cabo Verde"]
};

for (const [local, aliases] of Object.entries(teamAliasNames)) {
  englishToLocalTeam.set(normalizeName(local), local);
  for (const alias of aliases) englishToLocalTeam.set(normalizeName(alias), local);
}

function canonicalTeamName(team) {
  return englishToLocalTeam.get(normalizeName(team)) || team;
}

function teamLookupKeys(team) {
  const keys = new Set([normalizeName(team)]);
  const canonical = canonicalTeamName(team);
  keys.add(normalizeName(canonical));
  const english = englishTeamNames[canonical];
  if (english) keys.add(normalizeName(english));
  for (const alias of teamAliasNames[canonical] || []) keys.add(normalizeName(alias));
  return [...keys].filter(Boolean);
}

function lookupTeamRow(rows = {}, team) {
  for (const key of teamLookupKeys(team)) {
    if (rows[key]) return rows[key];
  }
  return undefined;
}

function teamSearchNames(team) {
  const canonical = canonicalTeamName(team);
  return [...new Set([
    team,
    canonical,
    englishTeamNames[canonical],
    ...(teamAliasNames[canonical] || [])
  ].filter(Boolean))];
}

function sourceHitsForTeam(team, sources = []) {
  const names = teamSearchNames(team).filter(name => !/^[A-Za-z]{1,3}$/.test(String(name)));
  const sourceHits = [];
  for (const source of sources || []) {
    if (!source.ok || !source.searchText) continue;
    const text = String(source.searchText);
    const matchedNames = names.filter(name => new RegExp(`\\b${String(name).replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b`, "i").test(text));
    if (matchedNames.length) {
      sourceHits.push({
        name: source.name,
        url: source.url,
        sourceTier: source.sourceTier || sourceTierFor(source.name, source.url),
        matchedNames: matchedNames.slice(0, 3),
        signal: source.hasWorldCupSignal ? "lineup-news-signal" : "team-mentioned"
      });
    }
  }
  return sourceHits;
}

function querySourcesForTeam(team) {
  const english = teamSearchNames(team).find(name => /[a-z]/i.test(name)) || team;
  const query = encodeURIComponent(`${english} World Cup 2026 team news`);
  return [
    {
      name: "FIFA official team news search",
      url: `https://www.fifa.com/en/search?query=${query}`,
      sourceTier: "official",
      status: "planned-query"
    },
    {
      name: "AP team news search",
      url: `https://apnews.com/search?q=${query}`,
      sourceTier: "major-media",
      status: "planned-query"
    },
    {
      name: "Reuters team news search",
      url: `https://www.reuters.com/site-search/?query=${query}`,
      sourceTier: "major-media",
      status: "planned-query"
    },
    {
      name: "ESPN team news search",
      url: `https://www.espn.com/search/_/q/${query}`,
      sourceTier: "major-media",
      status: "planned-query"
    }
  ];
}

function queryStatusFromResponse({response, text}, team) {
  if (!response.ok) {
    return response.status === 401 || response.status === 403 || response.status === 429 ? "blocked" : "no-hit";
  }
  const clean = stripTags(text).slice(0, 30000);
  const hit = teamSearchNames(team).some(name => new RegExp(`\\b${String(name).replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b`, "i").test(clean));
  return hit ? "hit" : "no-hit";
}

async function enrichTeamNewsSearches(teamSearches = {}, maxTeams = 12) {
  const selected = Object.values(teamSearches).slice(0, maxTeams);
  for (const row of selected) {
    const executable = (row.querySources || []).filter(source => /FIFA official|AP team/.test(source.name));
    const checked = await Promise.all(executable.map(async source => {
      try {
        const fetched = await fetchText(source.url);
        return {
          ...source,
          status: queryStatusFromResponse(fetched, row.team),
          statusCode: fetched.response.status,
          bytes: fetched.text.length
        };
      } catch (error) {
        return {
          ...source,
          status: "blocked",
          statusCode: 0,
          bytes: 0,
          note: error.message
        };
      }
    }));
    row.querySources = (row.querySources || []).map(source => checked.find(item => item.name === source.name) || source);
    const queryHits = row.querySources
      .filter(source => source.status === "hit")
      .map(source => ({
        name: source.name,
        url: source.url,
        sourceTier: source.sourceTier,
        matchedNames: teamSearchNames(row.team).slice(0, 2),
        signal: "team-query-hit"
      }));
    if (queryHits.length) {
      row.sourceHits = [...(row.sourceHits || []), ...queryHits];
      row.sourceCount = row.sourceHits.length;
      row.sourceCoverageTierSummary = sourceCoverageTierSummaryFor(row.sourceHits);
      row.highTrustSourceCount = Number(row.sourceCoverageTierSummary.official || 0) + Number(row.sourceCoverageTierSummary["major-media"] || 0);
      row.status = "covered";
    }
  }
  return teamSearches;
}

function lineupNewsForTeam(team, lineupNewsSources = {}) {
  const sourceHits = sourceHitsForTeam(team, lineupNewsSources.searchSources || []);
  return {
    team,
    sourceHits,
    sourceCount: sourceHits.length,
    confidence: Math.min(100, sourceHits.length * 18),
    status: sourceHits.length ? "mentioned" : "not-found"
  };
}

function lineupNewsContextFor(match, lineupNewsSources = {}) {
  const home = lineupNewsForTeam(match.home, lineupNewsSources);
  const away = lineupNewsForTeam(match.away, lineupNewsSources);
  return {
    status: home.sourceCount || away.sourceCount ? "partial" : "unavailable",
    sourceCount: home.sourceCount + away.sourceCount,
    confidence: Math.round((home.confidence + away.confidence) / 2),
    home,
    away,
    reason: home.sourceCount || away.sourceCount
      ? `阵容新闻源命中：${match.home} ${home.sourceCount}源，${match.away} ${away.sourceCount}源`
      : "阵容新闻替代源未命中当前两队"
  };
}

function buildTeamNewsSearches(matches, lineupNewsSources = {}) {
  const teams = [...new Set(matches.flatMap(match => [match.home, match.away]))];
  return Object.fromEntries(teams.map(team => {
    const sourceHits = sourceHitsForTeam(team, lineupNewsSources.searchSources || []);
    const sourceCoverageTierSummary = sourceCoverageTierSummaryFor(sourceHits);
    const highTrustSourceCount = Number(sourceCoverageTierSummary.official || 0) + Number(sourceCoverageTierSummary["major-media"] || 0);
    return [team, {
      team,
      querySources: querySourcesForTeam(team),
      sourceHits,
      sourceCount: sourceHits.length,
      highTrustSourceCount,
      sourceCoverageTierSummary,
      status: sourceHits.length ? "covered" : "not-found"
    }];
  }));
}

const newsSemanticRules = [
  {tag: "rotation-risk", pattern: /rotate|rotation|rest|rested|fringe|second-string|bench|changed side|fresh legs/i, scoreImpact: -5, goalBias: -0.05},
  {tag: "key-player-managed", pattern: /managed minutes|fitness test|not risked|protect|precaution|minor knock|doubt|questionable/i, scoreImpact: -5, goalBias: -0.04},
  {tag: "injury-return", pattern: /return|returns|back in training|fit again|available|recovered/i, scoreImpact: 3, goalBias: 0.03},
  {tag: "must-attack", pattern: /must[- ]win|need(?:s|ed)?\s+(?:a\s+)?win|goal difference|attack|front foot|must score|qualification hopes/i, scoreImpact: 4, goalBias: 0.08},
  {tag: "low-block", pattern: /low block|deep defence|deep defense|sit deep|compact|defensive shape|park/i, scoreImpact: -2, goalBias: -0.08},
  {tag: "counter-threat", pattern: /counter-attack|counterattack|transition|pace on the break|breakaway|wide pace/i, scoreImpact: 2, goalBias: 0.04},
  {tag: "travel-fatigue", pattern: /travel|fatigue|jet lag|long trip|recovery time|short turnaround/i, scoreImpact: -3, goalBias: -0.03},
  {tag: "morale-risk", pattern: /dispute|unrest|criticism|pressure|poor morale|off-field|controversy/i, scoreImpact: -4, goalBias: -0.02}
];

const sourceTierWeights = {
  official: 1,
  "major-media": 0.85,
  "football-media": 0.7,
  "fantasy-lineup": 0.45,
  derived: 0.55,
  unknown: 0.35
};

function sourceTierFor(name = "", url = "") {
  const haystack = `${name} ${url}`.toLowerCase();
  if (/official/.test(haystack) || /(^|\.)fifa\.com\//.test(haystack) || /(^|\.)inside\.fifa\.com\//.test(haystack) || /\b(uefa|caf|concacaf|conmebol|afc)\b/.test(haystack)) return "official";
  if (/bbc|reuters|associated press|apnews|guardian|espn|sky sports|cbs|nbc|fox sports|athletic/.test(haystack)) return "major-media";
  if (/goal\.com|sportsmole|fotmob|transfermarkt|worldsoccertalk/.test(haystack)) return "football-media";
  if (/fantasyfootballscout|fantasy football scout|sportsgambler|rotowire|fantasy|lineups/.test(haystack)) return "fantasy-lineup";
  if (/derived|projected|injur/.test(haystack)) return "derived";
  return "unknown";
}

function compactSnippet(text, keyword = "") {
  const clean = String(text || "").replace(/\s+/g, " ").trim();
  if (!clean) return "";
  const hit = keyword ? clean.toLowerCase().indexOf(String(keyword).toLowerCase()) : -1;
  const center = hit >= 0 ? hit : 0;
  return clean.slice(Math.max(0, center - 90), Math.min(clean.length, center + 170));
}

function sourceTierSummaryFor(evidence = []) {
  return evidence.reduce((summary, item) => {
    const tier = item.sourceTier || "unknown";
    summary[tier] = (summary[tier] || 0) + 1;
    return summary;
  }, {});
}

function sourceCoverageTierSummaryFor(sources = []) {
  return sources.reduce((summary, item) => {
    const tier = item.sourceTier || sourceTierFor(item.name, item.url);
    summary[tier] = (summary[tier] || 0) + 1;
    return summary;
  }, {});
}

function detectSemanticConflict(tags = []) {
  const set = new Set(tags);
  return [
    ["injury-return", "key-player-managed"],
    ["rotation-risk", "expected-xi-available"],
    ["must-attack", "low-block"]
  ].filter(([a, b]) => set.has(a) && set.has(b)).map(([a, b]) => `${a}/${b}`);
}

function trustedSemanticMultiplier(evidence = [], conflict = false) {
  if (!evidence.length) return 0;
  const tiers = sourceTierSummaryFor(evidence);
  const tierScore = evidence.reduce((sum, item) => sum + (sourceTierWeights[item.sourceTier] || sourceTierWeights.unknown), 0) / evidence.length;
  const multiSourceBoost = new Set(evidence.map(item => `${item.sourceName || ""}|${item.sourceUrl || ""}`)).size >= 2 ? 0.16 : 0;
  const strongTierBoost = (tiers.official || tiers["major-media"]) ? 0.18 : 0;
  const conflictPenalty = conflict ? 0.45 : 1;
  return Math.max(0, Math.min(1, round4((tierScore + multiSourceBoost + strongTierBoost) * conflictPenalty)));
}

function extractNewsSnippet(text, team) {
  const clean = String(text || "").replace(/\s+/g, " ");
  const canonical = canonicalTeamName(team);
  const english = englishTeamNames[canonical] || team;
  const names = [team, canonical, english, ...(teamAliasNames[canonical] || [])].filter(Boolean);
  const hits = [];
  for (const name of [...new Set(names)]) {
    const index = clean.toLowerCase().indexOf(String(name).toLowerCase());
    if (index >= 0) hits.push(clean.slice(Math.max(0, index - 420), index + 620));
  }
  return hits.join(" ");
}

function textMentionsTeam(text, team) {
  const names = teamSearchNames(team).filter(name => !/^[A-Za-z]{1,3}$/.test(String(name)));
  return names.some(name => new RegExp(`\\b${String(name).replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b`, "i").test(String(text || "")));
}

function rssEvidenceForTeam(team, source, tier) {
  if (source.sourceType !== "rss" || !Array.isArray(source.feedSearchItems)) return [];
  const rows = [];
  for (const item of source.feedSearchItems) {
    const text = `${item.title || ""} ${item.description || ""}`;
    if (!textMentionsTeam(text, team)) continue;
    if (/referee|fan|fans|ticket|tickets|travel by bus|supporters|visa|entry to/i.test(text)) continue;
    if (!/squad|player|players|coach|manager|injur|line-?up|training|fitness|match|game|group|qualif|world cup|team/i.test(text)) continue;
    for (const rule of newsSemanticRules) {
      const match = text.match(rule.pattern);
      if (!match) continue;
      rows.push({
        tag: rule.tag,
        keyword: match[0],
        title: item.title || "",
        snippet: compactSnippet(text, match[0]),
        sourceName: source.name,
        sourceUrl: item.link || source.url,
        sourceTier: tier,
        sourceType: "rss"
      });
    }
  }
  return rows.slice(0, 4);
}

function validNewsEvidenceText(text) {
  if (/localStorage|sessionStorage|removeItem|JSON|third-party providers|wager responsibly|responsible gambling|cookie|privacy policy/i.test(String(text || ""))) return false;
  return true;
}

function semanticNewsForTeam(team, lineupNewsSources = {}, projectedLineups = {}, injuryReport = {}, teamSearch = null) {
  const snippets = [];
  const sourceHits = [];
  const evidence = [];
  for (const source of lineupNewsSources.searchSources || []) {
    if (!source.ok || !source.searchText) continue;
    const snippet = extractNewsSnippet(source.searchText, team);
    if (!snippet) continue;
    snippets.push(snippet);
    const tier = sourceTierFor(source.name, source.url);
    sourceHits.push({name: source.name, url: source.url, sourceTier: tier});
    evidence.push(...rssEvidenceForTeam(team, source, tier));
    for (const rule of newsSemanticRules) {
      const match = snippet.match(rule.pattern);
      if (!match) continue;
      if (!validNewsEvidenceText(snippet)) continue;
      evidence.push({
        tag: rule.tag,
        keyword: match[0],
        snippet: compactSnippet(snippet, match[0]),
        sourceName: source.name,
        sourceUrl: source.url,
        sourceTier: tier
      });
    }
  }
  const projected = projectedLineups[normalizeName(team)] || {};
  const injury = teamNewsFor(team, injuryReport);
  if (projected.summary) snippets.push(projected.summary);
  if (injury.summary) snippets.push(injury.summary);
  const text = snippets.join(" ");
  const tags = newsSemanticRules.filter(rule => rule.pattern.test(text)).map(rule => rule.tag);
  if (injury.injuryStatus === "reported-issues") {
    tags.push("key-player-managed");
    evidence.push({
      tag: "key-player-managed",
      keyword: injury.injuryStatus,
      snippet: compactSnippet(injury.summary || injury.reason || "reported injury issues"),
      sourceName: "injury-report",
      sourceUrl: injuryUrl,
      sourceTier: sourceTierFor("injury-report", injuryUrl)
    });
  }
  if (projected.status === "projected" && Array.isArray(projected.keyPlayers) && projected.keyPlayers.length >= 10) {
    tags.push("expected-xi-available");
    evidence.push({
      tag: "expected-xi-available",
      keyword: projected.formation || "projected-xi",
      snippet: compactSnippet(projected.summary || projected.keyPlayers.join(", ")),
      sourceName: projected.sourceName || "Goal.com probable lineups",
      sourceUrl: projected.sourceUrl || goalProjectedLineupsUrl,
      sourceTier: sourceTierFor(projected.sourceName || "Goal.com probable lineups", projected.sourceUrl || goalProjectedLineupsUrl)
    });
  }
  const uniqueTags = [...new Set(tags)];
  const rules = newsSemanticRules.filter(rule => uniqueTags.includes(rule.tag));
  const scoreImpact = Math.max(-12, Math.min(10, rules.reduce((sum, rule) => sum + rule.scoreImpact, 0)));
  const goalBias = Math.max(-0.18, Math.min(0.18, round4(rules.reduce((sum, rule) => sum + rule.goalBias, 0))));
  const conflictReasons = detectSemanticConflict(uniqueTags);
  const sourceTierSummary = sourceTierSummaryFor(evidence);
  const trustMultiplier = trustedSemanticMultiplier(evidence, conflictReasons.length > 0);
  const confidence = Math.min(100, sourceHits.length * 18 + (projected.summary ? 18 : 0) + (injury.injuryStatus !== "unknown" ? 16 : 0) + uniqueTags.length * 4 + Math.round(trustMultiplier * 12));
  const trustedImpact = round4(scoreImpact * trustMultiplier);
  const trustedGoalBias = round4(goalBias * trustMultiplier);
  const sourceCoverageTierSummary = sourceCoverageTierSummaryFor(sourceHits);
  const mergedCoverage = {
    ...sourceCoverageTierSummary,
    ...Object.fromEntries(Object.entries(teamSearch?.sourceCoverageTierSummary || {}).map(([tier, count]) => [tier, Math.max(Number(sourceCoverageTierSummary[tier] || 0), Number(count || 0))]))
  };
  return {
    team,
    tags: uniqueTags,
    confidence,
    scoreImpact,
    goalBias,
    trustedImpact,
    trustedGoalBias,
    trustMultiplier,
    conflict: conflictReasons.length > 0,
    conflictReasons,
    evidence: evidence.slice(0, 8),
    sourceTierSummary,
    sourceCoverageTierSummary: mergedCoverage,
    teamSearch: teamSearch || null,
    sourceCount: sourceHits.length,
    sources: sourceHits,
    summary: uniqueTags.length ? uniqueTags.join(" / ") : "no-strong-semantic-signal"
  };
}

function buildNewsSemanticContexts(matches, {lineupNewsSources = {}, projectedLineups = {}, injuryReport = {}, teamSearches = {}} = {}) {
  const teams = [...new Set(matches.flatMap(match => [match.home, match.away]))];
  return Object.fromEntries(teams.map(team => [team, semanticNewsForTeam(team, lineupNewsSources, projectedLineups, injuryReport, teamSearches[team])]));
}

function newsSemanticContextFor(match, contexts = {}) {
  const emptyContext = team => ({team, tags: [], confidence: 0, scoreImpact: 0, goalBias: 0, trustedImpact: 0, trustedGoalBias: 0, evidence: [], sourceTierSummary: {}, sourceCoverageTierSummary: {}, conflict: false});
  const home = contexts[match.home] || emptyContext(match.home);
  const away = contexts[match.away] || emptyContext(match.away);
  const tags = [...new Set([...(home.tags || []).map(tag => `home:${tag}`), ...(away.tags || []).map(tag => `away:${tag}`)])].slice(0, 10);
  const scoreImpact = Math.max(-12, Math.min(12, Number(home.scoreImpact || 0) + Number(away.scoreImpact || 0)));
  const goalBias = Math.max(-0.22, Math.min(0.22, round4(Number(home.goalBias || 0) + Number(away.goalBias || 0))));
  const trustedImpact = Math.max(-12, Math.min(12, round4(Number(home.trustedImpact || 0) + Number(away.trustedImpact || 0))));
  const trustedGoalBias = Math.max(-0.22, Math.min(0.22, round4(Number(home.trustedGoalBias || 0) + Number(away.trustedGoalBias || 0))));
  const confidence = Math.round((Number(home.confidence || 0) + Number(away.confidence || 0)) / 2);
  const evidence = [
    ...(home.evidence || []).map(item => ({...item, side: "home", team: match.home})),
    ...(away.evidence || []).map(item => ({...item, side: "away", team: match.away}))
  ].slice(0, 10);
  const sourceTierSummary = sourceTierSummaryFor(evidence);
  const sourceCoverageTierSummary = sourceCoverageTierSummaryFor([...(home.sources || []), ...(away.sources || [])]);
  const conflictReasons = [...(home.conflictReasons || []).map(item => `home:${item}`), ...(away.conflictReasons || []).map(item => `away:${item}`)];
  return {
    home,
    away,
    tags,
    scoreImpact,
    goalBias,
    trustedImpact,
    trustedGoalBias,
    confidence,
    evidence,
    sourceTierSummary,
    sourceCoverageTierSummary,
    conflict: Boolean(home.conflict || away.conflict || conflictReasons.length),
    conflictReasons,
    reason: tags.length ? `新闻语义：${tags.join(" / ")}` : "新闻语义未见强信号"
  };
}

for (const [local, aliases] of Object.entries(teamAliasNames)) {
  const aliasGroup = aliases
    .flatMap(alias => [alias, canonicalTeamName(alias)])
    .map(alias => groupByTeam.get(normalizeName(alias)))
    .find(Boolean);
  if (aliasGroup && !groupByTeam.has(normalizeName(local))) {
    groupByTeam.set(normalizeName(local), aliasGroup);
  }
}

function strengthOf(team) {
  const canonical = canonicalTeamName(team);
  const direct = teamStrength[canonical] ?? teamStrength[team];
  if (direct) return direct;
  const normalized = normalizeName(canonical);
  const found = Object.entries(teamStrength).find(([name]) => normalizeName(name) === normalized);
  return found ? found[1] : 66;
}

function teamGroupInfo(team) {
  for (const key of teamLookupKeys(team)) {
    if (groupByTeam.has(key)) return groupByTeam.get(key);
  }
  return groupByTeam.get(normalizeName(team)) || {group: "未知", tier: "unknown"};
}

function contenderTier(team) {
  const direct = contenderTiers[team];
  if (direct) return direct;
  const normalized = normalizeName(team);
  const found = Object.entries(contenderTiers).find(([name]) => normalizeName(name) === normalized);
  return found ? found[1] : "field";
}

function publicRiskFor(team) {
  const normalized = normalizeName(team);
  return latestPublicRiskNotes.find(item => normalizeName(item.team) === normalized);
}

function styleProfileFor(team, ratings = {}) {
  const rating = ratings[normalizeName(team)];
  const direct = teamStyleProfile[team];
  if (direct) return {...direct, ...(rating || {})};
  const normalized = normalizeName(team);
  const found = Object.entries(teamStyleProfile).find(([name]) => normalizeName(name) === normalized || normalized.includes(normalizeName(name)) || normalizeName(name).includes(normalized));
  return found ? {...found[1], ...(rating || {})} : {...(rating || {}), attack: rating?.attack || strengthOf(team), defense: rating?.defense || strengthOf(team), style: rating?.style || "综合能力中性", bigWin: false, vulnerable: strengthOf(team) < 64};
}

function fixtureStageFor(match) {
  const source = `${match.matchId || ""} ${match.league || ""} ${match.startTime || ""}`;
  const number = Number(String(match.matchId || "").match(/\d+/)?.[0] || 0);
  if (/淘汰|1\/8|半决|决赛|附加/.test(source)) return "knockout";
  if (number && number >= 250) return "late-group";
  if (number && number >= 220) return "mid-group";
  return "early-group";
}

function tournamentStrategyContext(match, strengthDiff) {
  const homeInfo = teamGroupInfo(match.home);
  const awayInfo = teamGroupInfo(match.away);
  const homeTier = contenderTier(match.home);
  const awayTier = contenderTier(match.away);
  const stage = fixtureStageFor(match);
  const sameGroup = homeInfo.group !== "未知" && homeInfo.group === awayInfo.group;
  const eliteTiers = new Set(["title", "contender"]);
  const dangerTiers = new Set(["danger", "darkhorse"]);
  const flags = [];
  let drawUtility = 0.18;
  let rotationRisk = 0.08;
  let bracketIncentive = 0.08;
  let upsetIntentRisk = 0.1;
  let goalSuppression = 0;
  let favoriteGoalPressure = 0;
  let qualificationNeed = "neutral";

  if (sameGroup) {
    flags.push("同组积分博弈");
    drawUtility += 0.05;
  }
  if (stage === "early-group") {
    flags.push("小组早段谨慎");
    drawUtility += 0.04;
    goalSuppression += 0.05;
  } else if (stage === "mid-group") {
    flags.push("小组中段看积分形势");
    drawUtility += 0.04;
    bracketIncentive += 0.05;
  } else if (stage === "late-group") {
    flags.push("小组末轮排名选择");
    drawUtility += 0.1;
    rotationRisk += 0.1;
    bracketIncentive += 0.14;
    goalSuppression += 0.08;
  } else {
    flags.push("淘汰赛容错低");
    goalSuppression += 0.06;
  }

  if (Math.abs(strengthDiff) >= 18) {
    const favorite = strengthDiff > 0 ? match.home : match.away;
    const favoriteTier = strengthDiff > 0 ? homeTier : awayTier;
    const underdogTier = strengthDiff > 0 ? awayTier : homeTier;
    if (eliteTiers.has(favoriteTier)) {
      flags.push(`${favorite}争冠队保留实力`);
      rotationRisk += 0.18;
      goalSuppression += 0.07;
      favoriteGoalPressure += stage === "late-group" ? 0.1 : 0.02;
      qualificationNeed = stage === "late-group" ? "rotation-conserve" : "acceptable-draw";
    }
    if (underdogTier === "field" || underdogTier === "outsider") {
      flags.push("弱队抢分防守优先");
      upsetIntentRisk += 0.14;
      drawUtility += 0.08;
    }
  } else if (Math.abs(strengthDiff) <= 6) {
    flags.push("强弱接近防平");
    drawUtility += 0.12;
    upsetIntentRisk += 0.1;
    qualificationNeed = "acceptable-draw";
  } else if (dangerTiers.has(homeTier) || dangerTiers.has(awayTier)) {
    flags.push("强队遇潜在黑马");
    upsetIntentRisk += 0.12;
  }

  if (eliteTiers.has(homeTier) && eliteTiers.has(awayTier)) {
    flags.push("争冠队直接对话降节奏");
    drawUtility += 0.1;
    rotationRisk += 0.08;
    goalSuppression += 0.12;
  }

  for (const risk of [publicRiskFor(match.home), publicRiskFor(match.away)].filter(Boolean)) {
    flags.push(risk.flag);
    upsetIntentRisk += risk.weight / 100;
    goalSuppression += risk.weight / 180;
  }

  if (qualificationNeed === "neutral" && (stage === "late-group" || drawUtility >= 0.34)) qualificationNeed = "acceptable-draw";
  if (stage === "late-group" && Math.abs(strengthDiff) < 10 && drawUtility < 0.32) {
    qualificationNeed = "must-win";
    favoriteGoalPressure += 0.08;
  }

  drawUtility = Math.max(0, Math.min(1, drawUtility));
  rotationRisk = Math.max(0, Math.min(1, rotationRisk));
  bracketIncentive = Math.max(0, Math.min(1, bracketIncentive));
  upsetIntentRisk = Math.max(0, Math.min(1, upsetIntentRisk));
  goalSuppression = Math.max(0, Math.min(0.32, goalSuppression));
  favoriteGoalPressure = Math.max(-0.12, Math.min(0.18, favoriteGoalPressure));
  const score = Math.round(Math.max(0, Math.min(100, drawUtility * 28 + rotationRisk * 24 + bracketIncentive * 22 + upsetIntentRisk * 26)));

  return {
    stage,
    group: sameGroup ? homeInfo.group : "跨组/未知",
    qualificationNeed,
    drawUtility: round4(drawUtility),
    rotationRisk: round4(rotationRisk),
    bracketIncentive: round4(bracketIncentive),
    upsetIntentRisk: round4(upsetIntentRisk),
    goalSuppression: round4(goalSuppression),
    favoriteGoalPressure: round4(favoriteGoalPressure),
    flags: [...new Set(flags)].slice(0, 6),
    score,
    reason: `${stage === "early-group" ? "小组早段" : stage === "mid-group" ? "小组中段" : stage === "late-group" ? "小组末轮" : "淘汰赛"}策略分${score}，平局收益${Math.round(drawUtility * 100)}%，轮换保留${Math.round(rotationRisk * 100)}%，避强/半区动机${Math.round(bracketIncentive * 100)}%`
  };
}

function poisson(lambda, goals) {
  let factorial = 1;
  for (let index = 2; index <= goals; index++) factorial *= index;
  return Math.exp(-lambda) * Math.pow(lambda, goals) / factorial;
}

const worldCupScorePrior = new Map([
  ["1-0", 1.02],
  ["0-1", 1.02],
  ["2-1", 1.34],
  ["1-2", 1.34],
  ["2-0", 1.26],
  ["0-2", 1.26],
  ["1-1", 0.98],
  ["3-1", 1.12],
  ["1-3", 1.12],
  ["3-0", 1.1],
  ["0-3", 1.1],
  ["0-0", 0.72]
]);

function scoreDistribution(homeLambda, awayLambda, strategyContext = {}, strengthDiff = 0) {
  const rows = [];
  for (let home = 0; home <= 4; home++) {
    for (let away = 0; away <= 4; away++) {
      const rawProbability = poisson(homeLambda, home) * poisson(awayLambda, away);
      const prior = worldCupScorePrior.get(`${home}-${away}`) || 1;
      const totalGoals = home + away;
      const isDraw = home === away;
      const isNarrow = Math.abs(home - away) <= 1;
      const isFavoriteBigWin = Math.abs(home - away) >= 3;
      const isFavoriteTwoGoalWin = (strengthDiff >= 10 && home - away === 2) || (strengthDiff <= -10 && away - home === 2);
      const isFavoriteTwoOne = (strengthDiff >= 7 && home === 2 && away === 1) || (strengthDiff <= -7 && away === 2 && home === 1);
      const strategyPrior =
        (isDraw ? 1 + Number(strategyContext.drawUtility || 0) * 0.18 : 1) *
        (totalGoals <= 2 ? 1 + Number(strategyContext.goalSuppression || 0) * 0.28 : 1 - Number(strategyContext.goalSuppression || 0) * 0.18) *
        (isNarrow ? 1 + Number(strategyContext.upsetIntentRisk || 0) * 0.12 : 1) *
        (isFavoriteTwoGoalWin ? 1 + Math.min(0.28, Math.abs(strengthDiff) / 100) : 1) *
        (isFavoriteTwoOne ? 1 + Math.min(0.22, Math.abs(strengthDiff) / 120) : 1) *
        (isFavoriteBigWin ? 1 + Number(strategyContext.favoriteGoalPressure || 0) - Number(strategyContext.rotationRisk || 0) * 0.3 : 1);
      rows.push({home, away, probability: rawProbability * prior * Math.max(0.35, strategyPrior), rawProbability});
    }
  }
  const total = rows.reduce((sum, row) => sum + row.probability, 0) || 1;
  rows.forEach(row => { row.probability = row.probability / total; });
  return rows.sort((a, b) => b.probability - a.probability || (b.home + b.away) - (a.home + a.away));
}

function resultFromScore(score) {
  if (score.home > score.away) return "home";
  if (score.home < score.away) return "away";
  return "draw";
}

function pickText(result, home, away) {
  if (result === "home") return `${home}胜`;
  if (result === "away") return `${away}胜`;
  return "平局";
}

function round2(value) {
  return Math.round(Number(value || 0) * 100) / 100;
}

function round4(value) {
  return Math.round(Number(value || 0) * 10000) / 10000;
}

function resultProbabilityFromScores(scores, result) {
  return round4(scores.filter(score => resultFromScore(score) === result).reduce((sum, score) => sum + score.probability, 0));
}

function selectMainScore(scores, {strengthDiff, homeLambda, awayLambda, strategyContext}) {
  const top = scores[0];
  if (!top) return top;
  const viableThreshold = Math.abs(strengthDiff) >= 12 ? 0.25 : 0.4;
  const viable = scores.filter(score => score.probability >= top.probability * viableThreshold);
  const lambdaDiff = homeLambda - awayLambda;
  const favoriteResult = strengthDiff >= 7 || lambdaDiff >= 0.12
    ? "home"
    : strengthDiff <= -7 || lambdaDiff <= -0.12
      ? "away"
      : "draw";
  const dominantFavorite = Math.abs(strengthDiff) >= 22;
  const clearFavorite = Math.abs(strengthDiff) >= 12;
  const favoriteLambda = strengthDiff >= 0 ? homeLambda : awayLambda;
  const suppressed = Number(strategyContext.rotationRisk || 0) >= 0.34 || Number(strategyContext.goalSuppression || 0) >= 0.2;
  const scoreValue = score => {
    const result = resultFromScore(score);
    const total = score.home + score.away;
    const margin = Math.abs(score.home - score.away);
    let value = score.probability * 100;
    if (result === favoriteResult) value += clearFavorite ? 7 : 2;
    if (dominantFavorite && result === favoriteResult && margin >= 3 && favoriteLambda >= 1.85 && !suppressed) value += 26;
    if (strengthDiff <= -16 && result === "away" && score.home === 0 && score.away === 3 && awayLambda >= 1.78 && !suppressed) value += 18;
    if (strengthDiff <= -12 && result === "away" && score.home === 1 && score.away === 3 && awayLambda >= 1.7) value += 10;
    if (dominantFavorite && result === favoriteResult && total === 4 && margin === 2 && favoriteLambda >= 1.8) value += 6;
    if (clearFavorite && result === favoriteResult && total === 4 && margin === 2 && favoriteLambda >= 1.55) value += 5;
    if (dominantFavorite && result === favoriteResult && margin === 2) value += suppressed ? 9 : 7;
    if (clearFavorite && result === favoriteResult && total === 3 && margin === 1) value += 5;
    if (favoriteResult === "draw" && result === "draw") value += 3;
    if (favoriteResult === "draw" && total >= 4) value += 3;
    if (total === 0) value -= 5;
    if (clearFavorite && result === "draw") value -= 4;
    return value;
  };
  return viable.sort((a, b) => scoreValue(b) - scoreValue(a) || b.probability - a.probability)[0];
}

function scoreObject(scoreText, scores) {
  const [home, away] = scoreText.split("-").map(Number);
  const found = scores.find(score => score.home === home && score.away === away);
  return found || {home, away, probability: 0.01};
}

function trueUpsetScoreFor({main, backup, scores, strengthDiff}) {
  const mainScore = scoreObject(main, scores);
  const mainResult = resultFromScore(mainScore);
  const homeFavorite = strengthDiff >= 0;
  const sameScore = (score, text) => `${score.home}-${score.away}` === text;
  const available = predicate => scores
    .filter(score => !sameScore(score, main) && !sameScore(score, backup) && predicate(score))
    .sort((a, b) => (a.home + a.away) - (b.home + b.away) || b.probability - a.probability)[0];
  const drawValue = score => {
    if (score.home === 1 && score.away === 1) return 0;
    if (score.home === 0 && score.away === 0) return 1;
    if (score.home === 2 && score.away === 2) return 3;
    return 2;
  };
  const drawCover = () => scores
    .filter(score => !sameScore(score, main) && !sameScore(score, backup) && resultFromScore(score) === "draw" && score.home + score.away <= 2)
    .sort((a, b) => drawValue(a) - drawValue(b) || b.probability - a.probability)[0] ||
    available(score => resultFromScore(score) === "draw");
  if (mainResult === "draw") {
    return available(score => resultFromScore(score) !== "draw" && Math.abs(score.home - score.away) === 1) ||
      available(score => resultFromScore(score) !== "draw") ||
      drawCover() ||
      scoreObject(homeFavorite ? "1-0" : "0-1", scores);
  }
  const underdogResult = mainResult === "home" ? "away" : "home";
  const absDiff = Math.abs(strengthDiff);
  const draw = drawCover();
  const narrowFavoriteWinWithUnderdogGoal = available(score =>
    resultFromScore(score) === mainResult &&
    Math.abs(score.home - score.away) === 1 &&
    (mainResult === "home" ? score.away > 0 : score.home > 0) &&
    score.home + score.away <= 3
  );
  const underdogSmallWin = available(score =>
    resultFromScore(score) === underdogResult &&
    Math.abs(score.home - score.away) === 1 &&
    score.home + score.away <= 3
  );
  const fallback = mainResult === "home" ? scoreObject("1-1", scores) : scoreObject("1-1", scores);
  if (absDiff >= 12) return narrowFavoriteWinWithUnderdogGoal || draw || underdogSmallWin || fallback;
  if (absDiff <= 6) return draw || underdogSmallWin || narrowFavoriteWinWithUnderdogGoal || fallback;
  return draw || narrowFavoriteWinWithUnderdogGoal || underdogSmallWin || fallback;
}

function calibrateMainScore({main, backup, scores, reason}) {
  const top = scores[0];
  const mainScore = scoreObject(main, scores);
  const mainInTopFive = scores.slice(0, 5).some(score => score.home === mainScore.home && score.away === mainScore.away);
  const trailsTopTooMuch = Number(top?.probability || 0) - Number(mainScore.probability || 0) > 0.025;
  if (!top || (mainInTopFive && !trailsTopTooMuch)) {
    return {main, backup, reason};
  }
  const calibratedMain = `${top.home}-${top.away}`;
  return {
    main: calibratedMain,
    backup: main === calibratedMain ? backup : main,
    reason: `${reason} 概率分布校准：模型最高候选为${calibratedMain}，校准后主推${calibratedMain}，原专家比分${main}作为备用保留。`
  };
}

function expertScorePick(match, {scores, strengthDiff, homeLambda, awayLambda, strategyContext, teamNews, ratings = {}, historicalSummary = {}, recentResults = {}}) {
  const homeTier = contenderTier(match.home);
  const awayTier = contenderTier(match.away);
  const eliteTiers = new Set(["title", "contender"]);
  const dangerTiers = new Set(["danger", "darkhorse"]);
  const homeIssues = teamNews.home.injuryStatus === "reported-issues";
  const awayIssues = teamNews.away.injuryStatus === "reported-issues";
  const publicRiskHome = publicRiskFor(match.home);
  const publicRiskAway = publicRiskFor(match.away);
  const homeProfile = styleProfileFor(match.home, ratings);
  const awayProfile = styleProfileFor(match.away, ratings);
  const absDiff = Math.abs(strengthDiff);
  const stronger = strengthDiff >= 0 ? match.home : match.away;
  const weaker = strengthDiff >= 0 ? match.away : match.home;
  const strongerProfile = strengthDiff >= 0 ? homeProfile : awayProfile;
  const weakerProfile = strengthDiff >= 0 ? awayProfile : homeProfile;
  const strongerRecent = recentResults[normalizeName(stronger)] || {};
  const weakerRecent = recentResults[normalizeName(weaker)] || {};
  const strongerElite = strengthDiff >= 0 ? eliteTiers.has(homeTier) : eliteTiers.has(awayTier);
  const weakerDanger = strengthDiff >= 0 ? dangerTiers.has(awayTier) : dangerTiers.has(homeTier);
  const strongerHasIssues = strengthDiff >= 0 ? homeIssues || publicRiskHome : awayIssues || publicRiskAway;
  const weakerAttack = Number(weakerProfile.attack || 0);
  const weakerExpectedGoals = strengthDiff >= 0 ? awayLambda : homeLambda;
  const weakerCanScore = weakerDanger || weakerExpectedGoals >= 0.95 || weakerAttack >= 66 || Number(weakerRecent.avgFor || 0) >= 1.2 || (Number(strategyContext.upsetIntentRisk || 0) >= 0.24 && weakerAttack >= 63);
  const strongerAttackHigh = Number(strongerProfile.attack || 0) >= 86 || strongerProfile.bigWin || Number(strongerRecent.avgFor || 0) >= 1.8;
  const weakerDefenseFragile = Number(weakerProfile.defense || 0) <= 64 || weakerProfile.vulnerable || Number(weakerRecent.avgAgainst || 0) >= 1.6;
  const strongerExperience = Number(historicalSummary.teamAppearances?.[normalizeName(stronger)] || 0);
  const weakerExperience = Number(historicalSummary.teamAppearances?.[normalizeName(weaker)] || 0);
  const historicalGoalEnvironment = Number(historicalSummary.averageGoals || 0);
  const experienceGap = strongerExperience - weakerExperience;
  const needsBigWin = strategyContext.qualificationNeed === "must-win" || fixtureStageFor(match) === "late-group";
  const lowTempo = Number(strategyContext.drawUtility || 0) >= 0.34 || Number(strategyContext.goalSuppression || 0) >= 0.12;
  let main;
  let upset;
  let scenario;
  let reason;

  if (absDiff <= 2) {
    main = homeLambda >= awayLambda ? "1-1" : "1-1";
    upset = homeLambda >= awayLambda ? "1-0" : "0-1";
    scenario = "均势谨慎";
    reason = "两队强弱接近，比赛更像中场争夺和防守细节决定走势，主推平局；博冷保留一方通过定位球或反击小胜。";
  } else if (absDiff <= 6) {
    const homeLean = strengthDiff > 0 || homeLambda > awayLambda + 0.12;
    main = lowTempo ? (homeLean ? "1-0" : "0-1") : (homeLean ? "2-1" : "1-2");
    upset = "1-1";
    scenario = "轻微优势防平";
    reason = `${homeLean ? match.home : match.away}有轻微强弱和节奏优势，但差距不足以支撑大胜，主推小胜；博冷防双方谨慎试探后打成平局。`;
  } else if (absDiff <= 11) {
    const homeFav = strengthDiff > 0;
    main = weakerCanScore ? (homeFav ? "2-1" : "1-2") : (homeFav ? "1-0" : "0-1");
    upset = homeFav ? "1-1" : "1-1";
    scenario = "优势方小胜";
    reason = `${stronger}整体更稳，但${weaker}具备反击或身体对抗威胁，比赛不宜按单边压制处理，主推优势方一球小胜，博冷防平。`;
  } else if (absDiff <= 18) {
    const homeFav = strengthDiff > 0;
    if (weakerCanScore || strongerHasIssues) {
      main = homeFav ? "2-1" : "1-2";
      upset = homeFav ? "2-0" : "0-2";
      scenario = "强队占优但有失球风险";
      reason = `${stronger}实力占优，但${weaker}有转换、定位球或备战变量制造进球的空间，主推强队赢球但丢一球；备用保留强队控场零封，博冷另防弱队进球后小负或逼平。`;
    } else {
      main = homeFav ? "2-0" : "0-2";
      upset = homeFav ? "2-1" : "1-2";
      scenario = "强队控场";
      reason = `${stronger}强度和控场能力高一档，${weaker}主要靠低位防守拖节奏，主推强队两球胜；博冷防弱队反击打进一球。`;
    }
  } else {
    const homeFav = strengthDiff > 0;
    if (absDiff >= 26 && strongerAttackHigh && weakerDefenseFragile && needsBigWin) {
      main = homeFav ? "4-0" : "0-4";
      upset = homeFav ? "3-0" : "0-3";
      scenario = "强队冲净胜球";
      reason = `${stronger}进攻层级和阵容厚度明显高出一档，${weaker}防线抗压偏弱；若比赛目标需要净胜球，强队不会只满足小胜，主推四球打穿，备用保留三球零封，博冷另防强队降节奏或弱队偷到进球。`;
    } else if (absDiff >= 24 && strongerAttackHigh && weakerDefenseFragile && strongerElite) {
      if (weakerCanScore || strongerHasIssues) {
        main = homeFav ? "3-1" : "1-3";
        upset = homeFav ? "4-1" : "1-4";
        scenario = "强队大胜但留失球口";
        reason = `${stronger}进攻层级和替补深度明显高于${weaker}，弱队防线长时间承压容易被打穿；但${weaker}仍有反击或定位球进球点，主推三球级别优势，备用保留比赛打开后的四球路线，博冷另防弱队进球小负。`;
      } else {
        main = homeFav ? "3-0" : "0-3";
        upset = homeFav ? "4-0" : "0-4";
        scenario = "强队大胜零封";
        reason = `${stronger}进攻火力和控场能力明显高于${weaker}，且${weaker}防线抗压偏弱；结合历史世界杯均场进球${historicalGoalEnvironment || "参考"}和参赛经验差${experienceGap}，若早进球仍可能打到三球以上，主推三球零封，备用防四球打穿，博冷另防强队领先后降节奏。`;
      }
    } else if (absDiff >= 24 && strongerAttackHigh && weakerDefenseFragile && !lowTempo) {
      main = homeFav ? "4-1" : "1-4";
      upset = homeFav ? "3-0" : "0-3";
      scenario = "强队火力打穿但留失球口";
      reason = `${stronger}攻击线具备连续制造机会的能力，${weaker}防线脆弱但仍可能通过反击或定位球偷到一球，主推大比分赢球；备用防强队控场零封，博冷另防弱队进球后小负。`;
    } else if (strongerElite && lowTempo) {
      main = homeFav ? "2-0" : "0-2";
      upset = homeFav ? "3-0" : "0-3";
      scenario = "争冠队控场保留";
      reason = `${stronger}属于争冠级别球队，面对${weaker}预计控场优势明显，但小组阶段存在轮换和保留实力，主推稳健两球胜；若早进球或弱队防线崩盘，备用防三球打穿，博冷另防优势方只赢一球或弱队进球。`;
    } else if (weakerCanScore || strongerHasIssues) {
      main = strongerAttackHigh && weakerDefenseFragile ? (homeFav ? "4-1" : "1-4") : (homeFav ? "3-1" : "1-3");
      upset = homeFav ? "2-1" : "1-2";
      scenario = "强弱分明但弱队有进球点";
      reason = `${stronger}进攻层级明显更高，${weaker}防守承压时容易被连续打穿；但${weaker}并非完全没有反击和定位球机会，主推强队拉开比分同时丢一球；博冷防强队节奏控制成一球小胜。`;
    } else {
      main = strongerAttackHigh && weakerDefenseFragile ? (homeFav ? "4-0" : "0-4") : (homeFav ? "3-0" : "0-3");
      upset = homeFav ? "2-0" : "0-2";
      scenario = "强队打穿";
      reason = `${stronger}强弱优势非常清晰，${weaker}若长时间低位防守会承受持续压力；结合强队进攻层级和弱队防线质量，主推强队打穿零封；备用防强队领先后降节奏，博冷另防优势方一球小胜或弱队进球。`;
    }
  }

  if (strategyContext.qualificationNeed === "rotation-conserve" && /3/.test(main) && strongerElite) {
    upset = main;
    main = strengthDiff >= 0 ? "2-0" : "0-2";
    scenario = `${scenario} / 轮换修正`;
    reason += " 同时考虑争冠队赛程规划，若领先较早可能降节奏，因此主推从大胜修正为更稳健的两球胜。";
  }
  const calibrated = calibrateMainScore({main, backup: upset, scores, reason});
  main = calibrated.main;
  upset = calibrated.backup;
  reason = calibrated.reason;

  const mainScore = scoreObject(main, scores);
  const backupScore = scoreObject(upset, scores);
  const upsetScore = trueUpsetScoreFor({main, backup: upset, scores, strengthDiff});
  const upsetText = `${upsetScore.home}-${upsetScore.away}`;
  return {
    score: main,
    result: resultFromScore(mainScore),
    scenario,
    reason,
    upsetScore: {score: upsetText, probability: round4(upsetScore.probability), result: resultFromScore(upsetScore), role: "博冷"},
    picks: [
      {score: main, probability: round4(mainScore.probability), result: resultFromScore(mainScore), role: "主推"},
      {score: upset, probability: round4(backupScore.probability), result: resultFromScore(backupScore), role: "备用"}
    ]
  };
}

function dualScorePicks(scores, preferredResult, selectedFirst = scores[0]) {
  const first = selectedFirst;
  const firstTotal = first ? first.home + first.away : 0;
  const upsetResults = preferredResult === "draw"
    ? ["home", "away"]
    : ["draw", preferredResult === "home" ? "away" : "home"];
  const second =
    scores.find(score =>
      score !== first &&
      resultFromScore(score) === preferredResult &&
      Math.abs((score.home + score.away) - firstTotal) >= 1 &&
      score.probability >= Number(first?.probability || 0) * 0.58
    ) ||
    scores.find(score =>
      score !== first &&
      upsetResults.includes(resultFromScore(score)) &&
      score.probability >= Number(first?.probability || 0) * 0.62
    ) ||
    scores.find(score =>
      score !== first &&
      resultFromScore(score) === preferredResult &&
      `${score.home}-${score.away}` !== `${first?.home}-${first?.away}`
    ) ||
    scores.find(score => score !== first && upsetResults.includes(resultFromScore(score))) ||
    scores.find(score => score !== first && resultFromScore(score) === preferredResult) ||
    scores.find(score => score !== first) ||
    scores[1];
  return [first, second].filter(Boolean).map((score, index) => ({
    score: `${score.home}-${score.away}`,
    probability: round4(score.probability),
    result: resultFromScore(score),
    role: index === 0 ? "主推" : "备用"
  }));
}

function recommendationType(confidence, risk, drawProbability) {
  if (risk === "高" && confidence < 58) return "回避";
  if (risk === "低" && confidence >= 64) return "稳定";
  if (drawProbability >= 0.3) return "防冷";
  return "均衡";
}

function betScore({confidence, risk, scoreProbability, resultProbability, analysisQualityScore}) {
  const riskPenalty = risk === "高" ? 18 : risk === "中" ? 9 : 0;
  const scoreBoost = Math.max(0, Math.min(18, scoreProbability * 100));
  const resultBoost = Math.max(0, Math.min(18, resultProbability * 24));
  const qualityPenalty = analysisQualityScore < 80 ? 5 : 0;
  return Math.round(Math.max(0, Math.min(100, confidence * 0.64 + scoreBoost + resultBoost - riskPenalty - qualityPenalty)));
}

function betAction(score, risk) {
  if (score < 55 || risk === "高") return "回避";
  if (score >= 68) return "可跟踪";
  return "观察";
}

function teamNewsFor(team, injuryReport) {
  const found = injuryReport[normalizeName(team)];
  return found || {
    team,
    injuryStatus: "unknown",
    summary: "未采集到可靠公开伤停信息",
    source: "unavailable"
  };
}

function injuryStrengthPenalty(news) {
  if (news.injuryStatus === "reported-issues") return 2;
  return 0;
}

function riskFlagsFor({risk, drawProbability, strengthDiff, scoreProbability, teamNews, lineupStatus}) {
  const flags = [];
  if (scoreProbability < 0.12) flags.push("比分概率低");
  if (risk === "高") flags.push("风险高");
  if (drawProbability >= 0.3) flags.push("平局概率高");
  if (Math.abs(strengthDiff) < 5) flags.push("强弱差不足");
  if (teamNews.home.injuryStatus === "reported-issues" || teamNews.away.injuryStatus === "reported-issues") flags.push("存在伤停");
  if (lineupStatus !== "confirmed") flags.push("首发未确认");
  return flags;
}

function analysisQualityScore({injurySourceOk, teamNews, lineupStatus, riskFlags}) {
  let score = 84;
  if (injurySourceOk) score += 6;
  if (teamNews.home.injuryStatus === "unknown") score -= 5;
  if (teamNews.away.injuryStatus === "unknown") score -= 5;
  if (lineupStatus === "unconfirmed") score -= 8;
  if (riskFlags.includes("首发未确认")) score -= 3;
  return Math.max(0, Math.min(100, score));
}

function lineupProfileFor(team, {projectedLineups = {}, teamNews = {}, ratings = {}}) {
  const projected = projectedLineups[normalizeName(team)] || null;
  const news = teamNewsFor(team, teamNews);
  const style = styleProfileFor(team, ratings);
  const sources = [];
  if (projected) sources.push(projected.source || "projected-lineup");
  if (news.injuryStatus !== "unknown") sources.push(news.source || "injury-report");
  if (style.style) sources.push("team-style-profile");
  const formations = [...new Set([projected?.formation].filter(Boolean))];
  const conflict = formations.length > 1;
  const confidence = Math.max(0, Math.min(100,
    (projected ? 44 : 0) +
    (news.injuryStatus !== "unknown" ? 24 : 0) +
    (style.style ? 16 : 0) -
    (conflict ? 18 : 0)
  ));
  return {
    team,
    status: projected ? "projected" : "unconfirmed",
    formation: projected?.formation || "",
    sourceCount: sources.length,
    sources: [...new Set(sources)],
    confidence,
    conflict,
    keyPlayers: projected?.keyPlayers || [],
    missingPlayers: news.injuryStatus === "reported-issues" ? [news.summary].filter(Boolean).slice(0, 1) : [],
    summary: projected?.summary || news.summary || ""
  };
}

function mergedLineupStatus(homeLineup, awayLineup) {
  if (homeLineup.status === "confirmed" && awayLineup.status === "confirmed") return "confirmed";
  if (homeLineup.status === "projected" && awayLineup.status === "projected" && homeLineup.sourceCount >= 2 && awayLineup.sourceCount >= 2 && !homeLineup.conflict && !awayLineup.conflict) return "projected-confirmed";
  if (homeLineup.status === "projected" || awayLineup.status === "projected") return "projected";
  return "unconfirmed";
}

function lineupContextFor({lineupStatus, teamNews, homeLineup, awayLineup}) {
  let score = lineupStatus === "confirmed" ? 92 : lineupStatus === "projected-confirmed" ? 84 : lineupStatus === "projected" ? 76 : 58;
  const flags = [];
  if (lineupStatus === "unconfirmed") flags.push("首发未确认");
  if (lineupStatus === "projected-confirmed") flags.push("多源预计首发");
  if (homeLineup?.conflict || awayLineup?.conflict) {
    score -= 12;
    flags.push("阵容源冲突");
  }
  if (teamNews.home.injuryStatus === "reported-issues") {
    score -= 8;
    flags.push("主队有伤停");
  }
  if (teamNews.away.injuryStatus === "reported-issues") {
    score -= 8;
    flags.push("客队有伤停");
  }
  if (teamNews.home.injuryStatus === "unknown" || teamNews.away.injuryStatus === "unknown") {
    score -= 6;
    flags.push("伤停信息不完整");
  }
  return {
    status: lineupStatus,
    score: Math.max(0, Math.min(100, score)),
    sourceCount: Number(homeLineup?.sourceCount || 0) + Number(awayLineup?.sourceCount || 0),
    confidence: Math.round((Number(homeLineup?.confidence || 0) + Number(awayLineup?.confidence || 0)) / 2),
    conflict: Boolean(homeLineup?.conflict || awayLineup?.conflict),
    home: homeLineup || {},
    away: awayLineup || {},
    flags,
    reason: flags.length ? flags.join("，") : "阵容和伤停公开信息相对稳定"
  };
}

function formContextFor(match, recentResults = {}) {
  const build = team => {
    const row = lookupTeamRow(recentResults, team) || {};
    const played = Number(row.played || 0);
    const adjustedGoalDiff = Number(row.adjustedGoalDiff ?? round2(Number(row.avgFor || 0) - Number(row.avgAgainst || 0)));
    return {
      team,
      played,
      weightedPlayed: Number(row.weightedPlayed || 0),
      form: row.form || "",
      avgFor: Number(row.avgFor || 0),
      avgAgainst: Number(row.avgAgainst || 0),
      adjustedAvgFor: Number(row.adjustedAvgFor || row.avgFor || 0),
      adjustedAvgAgainst: Number(row.adjustedAvgAgainst || row.avgAgainst || 0),
      adjustedGoalDiff,
      weightedAvgFor: Number(row.weightedAvgFor || row.adjustedAvgFor || row.avgFor || 0),
      weightedAvgAgainst: Number(row.weightedAvgAgainst || row.adjustedAvgAgainst || row.avgAgainst || 0),
      weightedGoalDiff: Number(row.weightedGoalDiff ?? adjustedGoalDiff),
      avgOpponentStrength: Number(row.avgOpponentStrength || 0),
      weightedAvgOpponentStrength: Number(row.weightedAvgOpponentStrength || row.avgOpponentStrength || 0),
      sampleQuality: Number(row.sampleQuality || 0),
      competitiveShare: Number(row.competitiveShare || 0),
      strongOpponentShare: Number(row.strongOpponentShare || 0),
      lastMatchDate: row.lastMatchDate || "",
      matchTypeMix: row.matchTypeMix || {},
      recentMatches: Array.isArray(row.recentMatches) ? row.recentMatches : []
    };
  };
  const home = build(match.home);
  const away = build(match.away);
  const diff = round2(home.weightedGoalDiff - away.weightedGoalDiff);
  const confidence = Math.min(100, Math.round((Math.min(home.played, 5) + Math.min(away.played, 5)) * 10));
  const weightedConfidence = Math.min(100, Math.round((Math.min(home.weightedPlayed, 5) + Math.min(away.weightedPlayed, 5)) * 8 + (home.sampleQuality + away.sampleQuality) * 0.1));
  return {
    home,
    away,
    edge: diff > 0.35 ? "home-form" : diff < -0.35 ? "away-form" : "balanced-form",
    diff,
    confidence,
    weightedConfidence,
    reason: `近期对手强弱折算后净胜差：${match.home} ${home.adjustedGoalDiff}，${match.away} ${away.adjustedGoalDiff}`
  };
}

function tacticalContextFor(match, {strengthDiff, ratings = {}, recentResults = {}, strategyContext}) {
  const homeProfile = styleProfileFor(match.home, ratings);
  const awayProfile = styleProfileFor(match.away, ratings);
  const homeRecent = lookupTeamRow(recentResults, match.home) || {};
  const awayRecent = lookupTeamRow(recentResults, match.away) || {};
  const triggers = [];
  if (Math.abs(strengthDiff) >= 18) triggers.push("强弱差明显");
  if (Number(homeProfile.attack || 0) - Number(awayProfile.defense || 0) >= 20) triggers.push("主队进攻压制客队防线");
  if (Number(awayProfile.attack || 0) - Number(homeProfile.defense || 0) >= 20) triggers.push("客队进攻压制主队防线");
  if (awayProfile.vulnerable && strengthDiff > 12) triggers.push("客队防线脆弱");
  if (homeProfile.vulnerable && strengthDiff < -12) triggers.push("主队防线脆弱");
  if (Number(awayProfile.attack || 0) >= 64 || Number(awayRecent.avgFor || 0) >= 1.2) triggers.push("客队有反击进球点");
  if (Number(homeProfile.attack || 0) >= 64 || Number(homeRecent.avgFor || 0) >= 1.2) triggers.push("主队有反击进球点");
  if (Number(strategyContext.goalSuppression || 0) >= 0.12) triggers.push("赛程策略压低总进球");
  if (Number(strategyContext.favoriteGoalPressure || 0) > 0.06) triggers.push("净胜球/排名压力抬高大比分");
  const favorite = strengthDiff >= 0 ? match.home : match.away;
  const underdog = strengthDiff >= 0 ? match.away : match.home;
  const scenario = Math.abs(strengthDiff) >= 24 && triggers.some(item => item.includes("防线脆弱"))
    ? "强队大胜路径"
    : Math.abs(strengthDiff) >= 12
      ? "强队控场路径"
      : Number(strategyContext.drawUtility || 0) >= 0.3
        ? "防平胶着路径"
        : "均势细节路径";
  return {
    scenario,
    favorite,
    underdog,
    triggers: [...new Set(triggers)].slice(0, 8),
    reason: `${favorite}相对占优，${underdog}的主要变量是低位防守、转换反击和定位球；${scenario}`
  };
}

function marketCheckFor(match, modelResult) {
  const spf = match.odds?.spf || match.odds?.nspf || null;
  if (!spf || !Object.keys(spf).length) {
    return {status: "unavailable", favorite: "", modelResult, reason: "没有可用胜平负SP，仅使用模型判断"};
  }
  const map = {3: "home", 1: "draw", 0: "away"};
  const ranked = Object.entries(spf)
    .filter(([, value]) => Number(value) > 0)
    .sort((a, b) => Number(a[1]) - Number(b[1]));
  const favorite = map[ranked[0]?.[0]] || "";
  const favoriteSp = Number(ranked[0]?.[1] || 0);
  const modelSp = Number(Object.entries(map).find(([, result]) => result === modelResult)?.[0] ? spf[Object.entries(map).find(([, result]) => result === modelResult)[0]] : 0);
  const status = !favorite
    ? "unavailable"
    : favorite === modelResult
      ? "aligned"
      : modelSp && modelSp <= favoriteSp * 1.45
        ? "caution"
        : "divergent";
  return {
    status,
    favorite,
    modelResult,
    favoriteSp,
    modelSp,
    reason: status === "aligned"
      ? "市场方向与模型方向一致，仅作校验"
      : status === "caution"
        ? "市场方向与模型略有分歧，降低追踪强度"
        : status === "divergent"
          ? "市场低SP方向与模型明显不同，标记为风险"
          : "没有可用胜平负SP，仅使用模型判断"
  };
}

function groupStandingsPlaceholder() {
  const standings = Object.fromEntries(groups.map(([group, teams]) => [group, teams.map(([team]) => ({
    team,
    played: 0,
    points: 0,
    goalDifference: 0,
    status: "not-started"
  }))]));
  return {
    source: {name: "小组积分/净胜球", url: "local:pre-tournament-groups", ok: true, statusCode: 0, bytes: groups.length, note: "世界杯未开赛，输出小组积分占位；开赛后需替换为实时积分源。"},
    standings,
    live: false
  };
}

async function fetchFifaGroupStandings() {
  const placeholder = groupStandingsPlaceholder();
  try {
    const {response, text} = await fetchText(fifaStandingsUrl);
    return {
      source: {
        name: "FIFA官方小组积分/净胜球",
        url: fifaStandingsUrl,
        ok: response.ok,
        statusCode: response.status,
        bytes: text.length,
        note: response.ok
          ? "FIFA standings 页面可访问；当前赛事未开赛或页面未提供可解析实时表，使用赛前小组占位。"
          : `HTTP ${response.status}，使用赛前小组占位。`
      },
      standings: placeholder.standings,
      live: false
    };
  } catch (error) {
    return {
      source: {name: "FIFA官方小组积分/净胜球", url: fifaStandingsUrl, ok: false, statusCode: 0, bytes: 0, note: `${error.message}，使用赛前小组占位。`},
      standings: placeholder.standings,
      live: false
    };
  }
}

function standingRowFor(team, standings = {}) {
  const info = teamGroupInfo(team);
  const rows = standings[info.group] || [];
  const keys = new Set(teamLookupKeys(team));
  return rows.find(row => keys.has(normalizeName(row.team))) || {
    team,
    played: 0,
    points: 0,
    goalDifference: 0,
    status: "not-started",
    source: "inferred-placeholder"
  };
}

function groupSituationContextFor(match, standings = {}) {
  const home = standingRowFor(match.home, standings);
  const away = standingRowFor(match.away, standings);
  const sameGroup = teamGroupInfo(match.home).group === teamGroupInfo(match.away).group && teamGroupInfo(match.home).group !== "未知";
  const hasStarted = Number(home.played || 0) > 0 || Number(away.played || 0) > 0;
  const pointGap = Number(home.points || 0) - Number(away.points || 0);
  const goalDifferenceGap = Number(home.goalDifference || 0) - Number(away.goalDifference || 0);
  const mustWinLevel = !hasStarted
    ? "none"
    : Math.abs(pointGap) >= 4
      ? "high"
      : Math.abs(pointGap) >= 2
        ? "medium"
        : "low";
  return {
    status: hasStarted ? "live" : "not-started",
    group: sameGroup ? teamGroupInfo(match.home).group : "cross-group-or-unknown",
    sameGroup,
    home,
    away,
    pointGap,
    goalDifferenceGap,
    mustWinLevel,
    goalDifferenceNeed: hasStarted ? Math.max(0, 2 - Math.abs(goalDifferenceGap)) : 0,
    drawUtility: !hasStarted ? 0.22 : Math.abs(pointGap) <= 1 ? 0.34 : 0.18,
    reason: hasStarted
      ? `积分差${pointGap}，净胜球差${goalDifferenceGap}，抢分等级${mustWinLevel}`
      : "小组未开赛，积分和净胜球暂不构成真实动机"
  };
}

function loadOddsHistory() {
  try {
    const file = path.join(workspace, "worldcup2026-odds-history.json");
    if (!fs.existsSync(file)) return {snapshots: []};
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return {snapshots: []};
  }
}

function spfOddsToMarketOdds(odds = {}) {
  const spf = odds.spf || odds.nspf || {};
  return {
    home: Number(spf[3] || 0),
    draw: Number(spf[1] || 0),
    away: Number(spf[0] || 0),
    source: odds.spf ? "spf" : odds.nspf ? "nspf" : "unavailable"
  };
}

function oddsMovementForMatches(matches, nowIso) {
  const history = loadOddsHistory();
  const previousSnapshots = Array.isArray(history.snapshots) ? history.snapshots : [];
  const previous = previousSnapshots.findLast(item => Array.isArray(item.matches) && item.matches.length);
  const previousMap = new Map((previous?.matches || []).map(item => [item.matchId, item]));
  const openingMap = new Map();
  const snapshotCounts = new Map();
  for (const item of previousSnapshots) {
    if (!Array.isArray(item.matches)) continue;
    for (const row of item.matches) {
      if (!row.matchId) continue;
      snapshotCounts.set(row.matchId, (snapshotCounts.get(row.matchId) || 0) + 1);
      if (!openingMap.has(row.matchId)) openingMap.set(row.matchId, row);
    }
  }
  const movements = {};
  const snapshot = {
    capturedAt: nowIso,
    matches: matches.map(match => {
      const marketOdds = spfOddsToMarketOdds(match.odds || {});
      const previousOdds = previousMap.get(match.matchId)?.marketOdds || {};
      const deltas = {
        home: round2(Number(marketOdds.home || 0) - Number(previousOdds.home || 0)),
        draw: round2(Number(marketOdds.draw || 0) - Number(previousOdds.draw || 0)),
        away: round2(Number(marketOdds.away || 0) - Number(previousOdds.away || 0))
      };
      const maxAbsDelta = Math.max(...Object.values(deltas).map(value => Math.abs(Number(value || 0))));
      const status = !previous ? "baseline" : maxAbsDelta >= 0.35 ? "volatile" : maxAbsDelta >= 0.15 ? "watch" : "stable";
      const openingOdds = openingMap.get(match.matchId)?.marketOdds || marketOdds;
      const openingDeltas = {
        home: round2(Number(marketOdds.home || 0) - Number(openingOdds.home || 0)),
        draw: round2(Number(marketOdds.draw || 0) - Number(openingOdds.draw || 0)),
        away: round2(Number(marketOdds.away || 0) - Number(openingOdds.away || 0))
      };
      const strongestMove = Object.entries(openingDeltas)
        .filter(([, value]) => Math.abs(Number(value || 0)) > 0)
        .sort((a, b) => Math.abs(Number(b[1])) - Math.abs(Number(a[1])))[0];
      const direction = strongestMove ? `${strongestMove[0]} ${Number(strongestMove[1]) > 0 ? "drifting" : "shortening"}` : "unchanged";
      movements[match.matchId] = {
        status,
        deltas,
        openingDeltas,
        direction,
        snapshotCount: (snapshotCounts.get(match.matchId) || 0) + 1,
        previousCapturedAt: previous?.capturedAt || "",
        openingCapturedAt: openingMap.get(match.matchId)?.capturedAt || nowIso,
        opening: openingOdds,
        previous: previousMap.get(match.matchId)?.marketOdds || marketOdds,
        current: marketOdds
      };
      return {matchId: match.matchId, teams: match.teams, startTime: match.startTime, capturedAt: nowIso, marketOdds};
    })
  };
  const nextHistory = {snapshots: [...previousSnapshots.slice(-19), snapshot]};
  return {
    source: {name: "盘口变化/SP变化", url: "worldcup2026-odds-history.json", ok: true, statusCode: 0, bytes: snapshot.matches.length, note: previous ? `已对比上一轮${previous.matches?.length || 0}场SP快照。` : "已建立首轮SP变化基线。"},
    movements,
    history: nextHistory
  };
}

function rankingContextFor(match, rankings = {}) {
  const home = lookupTeamRow(rankings, match.home) || {team: match.home, rank: 99, source: "fallback-missing"};
  const away = lookupTeamRow(rankings, match.away) || {team: match.away, rank: 99, source: "fallback-missing"};
  return {
    home,
    away,
    rankGap: Number(away.rank || 99) - Number(home.rank || 99),
    source: home.source === "fifa-official" || away.source === "fifa-official" ? "fifa-official" : "fallback"
  };
}

function oddsMovementContextFor(match, movements = {}) {
  const current = spfOddsToMarketOdds(match.odds || {});
  return movements[match.matchId] || {
    status: "baseline",
    deltas: {home: 0, draw: 0, away: 0},
    openingDeltas: {home: 0, draw: 0, away: 0},
    direction: "unchanged",
    snapshotCount: 1,
    previousCapturedAt: "",
    openingCapturedAt: "",
    opening: current,
    previous: current,
    current
  };
}

function marketAnomalyFor({marketCheck, oddsMovementContext, modelResult}) {
  const flags = [];
  const current = oddsMovementContext.current || {};
  const opening = oddsMovementContext.opening || current;
  const previous = oddsMovementContext.previous || current;
  const openingDeltas = oddsMovementContext.openingDeltas || {};
  const deltas = oddsMovementContext.deltas || {};
  const sideMap = {home: "主胜", draw: "平局", away: "客胜"};
  const maxOpeningMove = Math.max(...Object.values(openingDeltas).map(value => Math.abs(Number(value || 0))));
  const maxRecentMove = Math.max(...Object.values(deltas).map(value => Math.abs(Number(value || 0))));
  if (oddsMovementContext.snapshotCount >= 3 && maxOpeningMove >= 0.45) flags.push("相对首盘大幅波动");
  if (maxRecentMove >= 0.22) flags.push("近轮SP突然变化");
  const modelOpeningDelta = Number(openingDeltas[modelResult] || 0);
  const modelRecentDelta = Number(deltas[modelResult] || 0);
  if (modelOpeningDelta >= 0.25 && modelRecentDelta >= 0.08) flags.push(`模型方向${sideMap[modelResult] || modelResult}持续升赔`);
  if (modelOpeningDelta <= -0.28 && marketCheck.status === "divergent") flags.push("市场降赔方向与模型不一致");
  const favoriteSide = ["home", "draw", "away"]
    .filter(side => Number(current[side] || 0) > 0)
    .sort((a, b) => Number(current[a]) - Number(current[b]))[0] || "";
  const favoriteShortening = favoriteSide && Number(openingDeltas[favoriteSide] || 0) <= -0.25;
  if (favoriteShortening && favoriteSide !== modelResult) flags.push(`市场强化${sideMap[favoriteSide] || favoriteSide}但模型不支持`);
  if (oddsMovementContext.status === "volatile") flags.push("盘口快照波动剧烈");
  const level = flags.some(flag => /不一致|突然|剧烈/.test(flag))
    ? "high"
    : flags.length >= 2
      ? "medium"
      : flags.length === 1
        ? "low"
        : "none";
  const penalty = level === "high" ? 8 : level === "medium" ? 5 : level === "low" ? 2 : 0;
  return {
    level,
    penalty,
    flags: [...new Set(flags)].slice(0, 6),
    direction: oddsMovementContext.direction || "unchanged",
    snapshotCount: oddsMovementContext.snapshotCount || 1,
    reason: flags.length ? flags.join(" / ") : "盘口快照未见临场异常，仅作校验"
  };
}

function parseMatchStartTime(match) {
  const value = String(match.startTime || "").trim();
  const parsed = new Date(`${value.replace(" ", "T")}+08:00`);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function scheduleDensityForMatches(matches) {
  const byTeam = new Map();
  for (const match of matches) {
    const start = parseMatchStartTime(match);
    for (const team of [match.home, match.away]) {
      const key = normalizeName(team);
      if (!byTeam.has(key)) byTeam.set(key, []);
      byTeam.get(key).push({matchId: match.matchId, teams: match.teams, start});
    }
  }
  for (const rows of byTeam.values()) rows.sort((a, b) => Number(a.start || 0) - Number(b.start || 0));
  const context = {};
  for (const match of matches) {
    const build = team => {
      const key = normalizeName(team);
      const rows = byTeam.get(key) || [];
      const index = rows.findIndex(row => row.matchId === match.matchId);
      const current = rows[index] || {};
      const previous = index > 0 ? rows[index - 1] : null;
      const next = index >= 0 && index < rows.length - 1 ? rows[index + 1] : null;
      const restHours = previous?.start && current.start ? Math.round((current.start - previous.start) / 36e5) : null;
      const nextHours = next?.start && current.start ? Math.round((next.start - current.start) / 36e5) : null;
      const status = restHours === null ? "first-match" : restHours < 96 ? "short-rest" : "normal-rest";
      return {team, status, restHours, nextHours, previousMatchId: previous?.matchId || "", nextMatchId: next?.matchId || ""};
    };
    context[match.matchId] = {home: build(match.home), away: build(match.away)};
  }
  return context;
}

function scheduleContextFor(match, scheduleDensity = {}) {
  return scheduleDensity[match.matchId] || {
    home: {team: match.home, status: "unknown", restHours: null, nextHours: null},
    away: {team: match.away, status: "unknown", restHours: null, nextHours: null}
  };
}

function hostCountryForTeam(team) {
  const normalized = normalizeName(team);
  if (normalized === normalizeName("美国")) return "United States";
  if (normalized === normalizeName("墨西哥")) return "Mexico";
  if (normalized === normalizeName("加拿大")) return "Canada";
  return "";
}

function regionForTeam(team) {
  const northAmerica = ["美国", "墨西哥", "加拿大", "哥斯达", "哥斯达黎加", "巴拿马"];
  const southAmerica = ["巴西", "阿根廷", "乌拉圭", "哥伦比亚", "厄瓜多尔", "巴拉圭"];
  const europe = ["法国", "西班牙", "英格兰", "德国", "葡萄牙", "荷兰", "比利时", "克罗地亚", "瑞士", "瑞典", "挪威", "奥地利", "捷克", "苏格兰", "土耳其", "波黑"];
  const africa = ["南非", "摩洛哥", "塞内加尔", "尼日利亚", "阿尔及利亚", "埃及", "加纳", "科特迪瓦", "突尼斯", "刚果(金)", "佛得角"];
  const asia = ["日本", "韩国", "伊朗", "沙特", "沙特阿拉伯", "卡塔尔", "澳大利亚", "伊拉克", "乌兹别克", "乌兹别克斯坦", "约旦"];
  const normalized = normalizeName(team);
  if (northAmerica.some(item => normalizeName(item) === normalized)) return "north-america";
  if (southAmerica.some(item => normalizeName(item) === normalized)) return "south-america";
  if (europe.some(item => normalizeName(item) === normalized)) return "europe";
  if (africa.some(item => normalizeName(item) === normalized)) return "africa";
  if (asia.some(item => normalizeName(item) === normalized)) return "asia";
  return "unknown";
}

function venueForMatch(match, index = 0) {
  const number = Number(String(match.matchId || "").match(/\d+/)?.[0] || index);
  return worldCup2026Venues[Math.abs(number || index) % worldCup2026Venues.length];
}

function venueContextFor(match, venue, weatherForecasts = {}) {
  const homeHost = hostCountryForTeam(match.home);
  const awayHost = hostCountryForTeam(match.away);
  const homeRegion = regionForTeam(match.home);
  const awayRegion = regionForTeam(match.away);
  const venueRegion = venue.country === "Mexico" || venue.country === "Canada" || venue.country === "United States" ? "north-america" : "unknown";
  const hostAdvantage = homeHost === venue.country ? "home" : awayHost === venue.country ? "away" : homeRegion === venueRegion || awayRegion === venueRegion ? "regional" : "none";
  const outsideRegionCount = [homeRegion, awayRegion].filter(region => region !== "north-america" && region !== "unknown").length;
  const travelLoad = outsideRegionCount >= 2 ? "high" : outsideRegionCount === 1 ? "medium" : "low";
  const timezoneLoad = venue.timezone <= -7 && (homeRegion === "europe" || awayRegion === "europe" || homeRegion === "africa" || awayRegion === "africa") ? "high" : travelLoad === "high" ? "medium" : "low";
  const weather = weatherForMatch(match, venue, weatherForecasts);
  const environmentScore = Math.max(0, Math.min(100,
    78 -
    (venue.climateRisk === "high" ? 12 : venue.climateRisk === "medium" ? 6 : 0) -
    (weather.weatherRisk === "high" ? 10 : weather.weatherRisk === "medium" ? 5 : 0) -
    (travelLoad === "high" ? 10 : travelLoad === "medium" ? 5 : 0) -
    (timezoneLoad === "high" ? 8 : timezoneLoad === "medium" ? 4 : 0) +
    (hostAdvantage === "home" || hostAdvantage === "away" ? 8 : hostAdvantage === "regional" ? 3 : 0)
  ));
  return {
    stadium: venue.stadium,
    city: venue.city,
    country: venue.country,
    hostAdvantage,
    travelLoad,
    climateRisk: venue.climateRisk || "unknown",
    timezoneLoad,
    weather,
    environmentScore,
    reason: `${venue.city}/${venue.country}，气候${venue.climateRisk}，旅行${travelLoad}，时区${timezoneLoad}，主办方优势${hostAdvantage}`
  };
}

function venueMapForMatches(matches, weatherForecasts = {}) {
  const map = {};
  matches.forEach((match, index) => {
    map[match.matchId] = venueContextFor(match, venueForMatch(match, index), weatherForecasts);
  });
  return map;
}

function scoreRationaleFor({expertPick, tacticalContext, strategyContext, formContext, marketCheck}) {
  const main = expertPick.picks?.[0] || {};
  const backup = expertPick.picks?.[1] || {};
  const upset = expertPick.upsetScore || {};
  return {
    main: `主推${main.score || expertPick.score}：${tacticalContext.scenario}，${formContext.reason}，${strategyContext.reason}`,
    backup: `备用${backup.score || "-"}：保留同方向比分变化、强队控场或弱队进球的常规防线。`,
    upset: `博冷${upset.score || "-"}：优先防平局、弱队进球、爆冷小胜或优势方一球小胜；${marketCheck.reason}`
  };
}

function analystContextScore({quality, resultProbability, lineupContext, formContext, tacticalContext, marketCheck, strategyContext}) {
  let score = quality * 0.34 + resultProbability * 100 * 0.28 + lineupContext.score * 0.16 + formContext.confidence * 0.08;
  if (tacticalContext.triggers.length >= 3) score += 5;
  if (marketCheck.status === "aligned") score += 4;
  if (marketCheck.status === "caution") score -= 4;
  if (marketCheck.status === "divergent") score -= 10;
  score -= Number(strategyContext.score || 0) * 0.06;
  return Math.round(Math.max(0, Math.min(100, score)));
}

function subjectiveAnalystLayer({match, strengthDiff, resultProbability, drawProbability, scoreProbability, marketCheck, marketAnomaly, strategyContext, tacticalContext, lineupStatus, newsSemanticContext}) {
  const favoriteBias = Math.abs(strengthDiff) >= 18 && resultProbability >= 0.62;
  const publicDataNoise = Math.round(Math.max(0, Math.min(100,
    (marketCheck.status === "divergent" ? 36 : marketCheck.status === "caution" ? 22 : 10) +
    (marketAnomaly.level === "high" ? 24 : marketAnomaly.level === "medium" ? 14 : marketAnomaly.level === "low" ? 7 : 0) +
    (favoriteBias ? 12 : 0) +
    (lineupStatus !== "confirmed" ? 10 : 0) +
    (Number(strategyContext.rotationRisk || 0) * 45) +
    (scoreProbability < 0.13 ? 8 : 0)
  )));
  let stance = "纯模型判断";
  let reason = "公开数据只作为背景输入，最终按强弱结构、比赛节奏和冷门路径做人工过滤。";
  let adjustment = 0;
  if (marketCheck.status === "aligned" && favoriteBias) {
    stance = "顺势但降权";
    adjustment = -4;
    reason = "市场与模型同向但强队热度集中，主观上不追大热，只保留控场比分并提高博冷权重。";
  } else if (marketCheck.status === "divergent" && drawProbability >= 0.28) {
    stance = "诱盘疑点";
    adjustment = -8;
    reason = "公开方向与模型冲突且平局权重不低，视为可能诱导单边判断，主观上转为防平和弱队进球。";
  } else if (marketCheck.status === "divergent") {
    stance = "反市场保护";
    adjustment = -5;
    reason = "市场方向与模型冲突，但足球逻辑仍支持原判断，主观上不盲从公开方向，只降低执行强度。";
  } else if (marketCheck.status === "caution") {
    stance = "诱盘疑点";
    adjustment = -3;
    reason = "公开方向与模型略有错位，主观上保留比分判断，但不把公开数据当作加分项。";
  }
  return {
    stance,
    capitalNoiseRisk: publicDataNoise,
    adjustment,
    reason,
    protectedAngles: [
      drawProbability >= 0.28 ? "防平" : "",
      favoriteBias ? "防强队热度" : "",
      tacticalContext.triggers?.some(item => /反击|定位球|低位/.test(item)) ? "防弱队进球" : "",
      newsSemanticContext.tags?.some(item => /rotation|managed/.test(item)) ? "防轮换降速" : ""
    ].filter(Boolean)
  };
}

function buildMatchModel(match, context = {}) {
  const teamNews = {
    home: teamNewsFor(match.home, context.injuryReport || {}),
    away: teamNewsFor(match.away, context.injuryReport || {})
  };
  const projectedLineups = context.projectedLineups || {};
  const homeLineup = lineupProfileFor(match.home, {projectedLineups, teamNews: context.injuryReport || {}, ratings: context.ratings || {}});
  const awayLineup = lineupProfileFor(match.away, {projectedLineups, teamNews: context.injuryReport || {}, ratings: context.ratings || {}});
  const lineupStatus = mergedLineupStatus(homeLineup, awayLineup);
  const lineupNewsContext = lineupNewsContextFor(match, context.lineupNewsSources || {});
  const newsSemanticContext = newsSemanticContextFor(match, context.newsSemanticContexts || {});
  const rankingContext = rankingContextFor(match, context.fifaRankings || {});
  const oddsMovementContext = oddsMovementContextFor(match, context.oddsMovement || {});
  const scheduleContext = scheduleContextFor(match, context.scheduleDensity || {});
  const venueContext = (context.venueMap || {})[match.matchId] || venueContextFor(match, venueForMatch(match, 0), context.weatherForecasts || {});
  const groupSituationContext = groupSituationContextFor(match, context.groupStandings || {});
  const homeStrength = strengthOf(match.home) - injuryStrengthPenalty(teamNews.home);
  const awayStrength = strengthOf(match.away) - injuryStrengthPenalty(teamNews.away);
  const strengthDiff = homeStrength - awayStrength;
  const formContext = formContextFor(match, context.recentResults || {});
  const formGoalOffset = Math.max(-0.16, Math.min(0.16, Number(formContext.diff || 0) * 0.045));
  const expectedDiff = Math.max(-1.35, Math.min(1.35, strengthDiff / 14));
  const balancePenalty = Math.abs(strengthDiff) < 5 ? -0.12 : 0.08;
  const strategyContext = tournamentStrategyContext(match, strengthDiff);
  const strategyGoalOffset = -Number(strategyContext.goalSuppression || 0) * 0.45 + Number(strategyContext.favoriteGoalPressure || 0) + Number(newsSemanticContext.trustedGoalBias || 0);
  const totalGoals = Math.max(1.55, Math.min(3.35, 2.28 + Math.abs(expectedDiff) * 0.24 + balancePenalty + strategyGoalOffset));
  const strategyDiffTrim = Number(strategyContext.rotationRisk || 0) * 0.08 + Number(strategyContext.drawUtility || 0) * 0.04;
  const semanticDiffOffset = Math.max(-0.08, Math.min(0.08, Number(newsSemanticContext.trustedImpact || 0) * 0.01));
  const formAdjustedExpectedDiff = expectedDiff + formGoalOffset + semanticDiffOffset;
  const adjustedExpectedDiff = formAdjustedExpectedDiff > 0
    ? Math.max(0, formAdjustedExpectedDiff - strategyDiffTrim)
    : Math.min(0, formAdjustedExpectedDiff + strategyDiffTrim);
  const homeLambda = Math.max(0.35, Math.min(3.3, totalGoals / 2 + adjustedExpectedDiff / 2));
  const awayLambda = Math.max(0.25, Math.min(3.1, totalGoals - homeLambda));
  const scores = scoreDistribution(homeLambda, awayLambda, strategyContext, strengthDiff);
  const expertPick = expertScorePick(match, {
    scores,
    strengthDiff,
    homeLambda,
    awayLambda,
    strategyContext,
    teamNews,
    ratings: context.ratings || {},
    historicalSummary: context.historicalSummary || {},
    recentResults: context.recentResults || {}
  });
  const topScore = scoreObject(expertPick.score, scores);
  const result = expertPick.result;
  const resultProbability = resultProbabilityFromScores(scores, result);
  const drawProbability = resultProbabilityFromScores(scores, "draw");
  const confidence = Math.round(Math.max(42, Math.min(86, resultProbability * 100 * 0.78 + Math.abs(strengthDiff) * 0.44 + topScore.probability * 100 * 0.8)));
  const riskScore = (1 - resultProbability) * 68 + drawProbability * 30 - Math.abs(strengthDiff) * 0.18 + Number(strategyContext.score || 0) * 0.18;
  const risk = riskScore >= 54 ? "高" : riskScore >= 42 ? "中" : "低";
  const scoreCandidates = scores.slice(0, 5).map(score => ({score: `${score.home}-${score.away}`, probability: round4(score.probability), result: resultFromScore(score)}));
  const scoreProbability = round4(topScore.probability);
  const dualScores = expertPick.picks;
  const upsetScore = expertPick.upsetScore;
  const dualScoreCoverage = round4(dualScores.reduce((sum, item) => sum + item.probability, 0));
  const type = recommendationType(confidence, risk, drawProbability);
  const marketCheck = marketCheckFor(match, result);
  const marketAnomaly = marketAnomalyFor({marketCheck, oddsMovementContext, modelResult: result});
  const provisionalFlags = [
    ...riskFlagsFor({risk, drawProbability, strengthDiff, scoreProbability, teamNews, lineupStatus}),
    ...strategyContext.flags,
    ...(newsSemanticContext.tags.includes("home:rotation-risk") || newsSemanticContext.tags.includes("away:rotation-risk") ? ["新闻提示轮换"] : []),
    ...(newsSemanticContext.tags.includes("home:key-player-managed") || newsSemanticContext.tags.includes("away:key-player-managed") ? ["新闻提示核心保护"] : []),
    ...(newsSemanticContext.tags.includes("home:must-attack") || newsSemanticContext.tags.includes("away:must-attack") ? ["新闻提示抢攻"] : []),
    ...(oddsMovementContext.status === "volatile" ? ["SP变化剧烈"] : oddsMovementContext.status === "watch" ? ["SP变化需观察"] : []),
    ...(marketAnomaly.level === "high" ? ["盘口临场异常"] : marketAnomaly.level === "medium" ? ["盘口变化需复核"] : []),
    ...(scheduleContext.home.status === "short-rest" || scheduleContext.away.status === "short-rest" ? ["赛程短休"] : []),
    ...(venueContext.climateRisk === "high" ? ["气候风险高"] : []),
    ...(venueContext.hostAdvantage !== "none" ? ["主办地/区域优势"] : []),
    ...(groupSituationContext.mustWinLevel === "high" ? ["积分形势必须抢分"] : [])
  ].filter((flag, index, list) => list.indexOf(flag) === index).slice(0, 10);
  const quality = Math.min(100, analysisQualityScore({injurySourceOk: Boolean(context.injurySourceOk), teamNews, lineupStatus, riskFlags: provisionalFlags}) + Math.min(4, Math.round(Number(lineupNewsContext.sourceCount || 0) * 0.75)) + Math.min(5, Math.round(Number(newsSemanticContext.confidence || 0) * 0.05)));
  const lineupContext = lineupContextFor({lineupStatus, teamNews, homeLineup, awayLineup});
  const tacticalContext = tacticalContextFor(match, {strengthDiff, ratings: context.ratings || {}, recentResults: context.recentResults || {}, strategyContext});
  const scoreRationale = scoreRationaleFor({expertPick, tacticalContext, strategyContext, formContext, marketCheck});
  const matchContextScore = analystContextScore({quality, resultProbability, lineupContext, formContext, tacticalContext, marketCheck, strategyContext});
  const analystSubjective = subjectiveAnalystLayer({
    match,
    strengthDiff,
    resultProbability,
    drawProbability,
    scoreProbability,
    marketCheck,
    marketAnomaly,
    strategyContext,
    tacticalContext,
    lineupStatus,
    newsSemanticContext
  });
  const baseBetScore = betScore({confidence, risk, scoreProbability, resultProbability, analysisQualityScore: quality});
  const marketPenalty = marketCheck.status === "divergent" ? 8 : marketCheck.status === "caution" ? 4 : 0;
  const contextBoost = matchContextScore >= 72 ? 3 : matchContextScore < 55 ? -5 : 0;
  const scoreForBet = Math.max(0, Math.min(100, Math.round(baseBetScore - Number(strategyContext.score || 0) * 0.08 - marketPenalty - marketAnomaly.penalty + contextBoost + analystSubjective.adjustment)));
  const rawAction = betAction(scoreForBet, risk);
  const analystVerdict = analystVerdictForModel({
    betAction: rawAction,
    lineupStatus,
    matchContextScore,
    marketCheck,
    tacticalContext,
    scoreProbability,
    dualScores
  });
  const action = analystVerdict === "可小注跟踪"
    ? rawAction
    : analystVerdict === "四串一不建议纳入"
      ? "回避"
      : "观察";
  return {
    score: expertPick.score,
    result,
    pick: pickText(result, match.home, match.away),
    confidence,
    risk,
    recommendationType: type,
    betScore: scoreForBet,
    betAction: action,
    analystVerdict,
    analysisQualityScore: quality,
    matchContextScore,
    lineupContext,
    lineupNewsContext,
    newsSemanticContext,
    rankingContext,
    formContext,
    tacticalContext,
    scheduleContext,
    venueContext,
    marketCheck,
    oddsMovementContext,
    marketAnomaly,
    analystSubjective,
    scoreRationale,
    teamNews,
    lineupStatus,
    upsetScore,
    strategyContext,
    groupSituationContext,
    expertScenario: expertPick.scenario,
    expertReason: expertPick.reason,
    riskFlags: provisionalFlags,
    scoreProbability,
    resultProbability,
    drawProbability,
    dualScores,
    dualScoreCoverage,
    scoreCandidates,
    expectedGoals: {home: round2(homeLambda), away: round2(awayLambda)},
    strength: {home: homeStrength, away: awayStrength, diff: strengthDiff},
    reason: `${expertPick.reason} 强度差${strengthDiff}，FIFA排名差${rankingContext.rankGap}，近期状态折算${formContext.diff}，${groupSituationContext.reason}，赛程${scheduleContext.home.status}/${scheduleContext.away.status}，场地${venueContext.reason}，参考期望进球${round2(homeLambda)}-${round2(awayLambda)}，胜平负可靠性${Math.round(resultProbability * 100)}%，平局概率${Math.round(drawProbability * 100)}%，${strategyContext.reason}，${newsSemanticContext.reason}，${marketCheck.reason}，SP变化${oddsMovementContext.status}，盘口异常${marketAnomaly.level}，${marketAnomaly.reason}，主观判断${analystSubjective.stance}，${analystSubjective.reason}，公开噪声${analystSubjective.capitalNoiseRisk}，分析上下文${matchContextScore}，下注评分${scoreForBet}，建议${action}，情报质量${quality}`
  };
}

const alerts = [
  {title: "法国 vs 挪威", text: "法国整体实力占优，但挪威前场单点爆破强，平局和小冷风险需要保留。"},
  {title: "荷兰 vs 日本", text: "日本转换速度和纪律性强，不适合简单判断荷兰稳胜。"},
  {title: "英格兰 vs 克罗地亚", text: "英格兰纸面更强，但克罗地亚大赛节奏控制能力仍在。"},
  {title: "西班牙 vs 乌拉圭", text: "西班牙控球强，乌拉圭对抗强，容易进入低比分胶着局。"}
];

const matches = [
  {teams: "墨西哥 vs 南非", note: "揭幕战，主场优势明显；但首战节奏通常偏谨慎。", score: "2-1", pick: "墨西哥胜", probability: "胜 58% / 平 25% / 负 17%", confidence: 67, type: "hot"},
  {teams: "巴西 vs 摩洛哥", note: "C组强强对话，巴西上限更高，摩洛哥反击和防守纪律强。", score: "2-1", pick: "巴西胜", probability: "胜 55% / 平 27% / 负 18%", confidence: 62, type: "hot"},
  {teams: "韩国 vs 捷克", note: "两队强度接近，捷克身体对抗和定位球更直接，平局权重不低。", score: "1-1", pick: "平局", probability: "胜 34% / 平 32% / 负 34%", confidence: 50, type: "upset"},
  {teams: "加拿大 vs 波黑", note: "加拿大速度优势明显，波黑阵地战经验更足，倾向小比分分胜负。", score: "1-0", pick: "加拿大胜", probability: "胜 44% / 平 29% / 负 27%", confidence: 55, type: "hot"},
  {teams: "美国 vs 巴拉圭", note: "东道主有节奏优势，巴拉圭对抗和定位球有威胁。", score: "1-1", pick: "平局", probability: "胜 38% / 平 33% / 负 29%", confidence: 54, type: "upset"},
  {teams: "德国 vs 库拉索", note: "强弱差清晰，德国控球压制面大。", score: "2-0", pick: "德国胜", probability: "胜 76% / 平 17% / 负 7%", confidence: 78, type: "combo"},
  {teams: "荷兰 vs 日本", note: "节奏和反击质量接近，日本具备拖入平局的能力。", score: "1-1", pick: "平局", probability: "胜 42% / 平 31% / 负 27%", confidence: 52, type: "upset"},
  {teams: "西班牙 vs 佛得角", note: "控球压制面大，西班牙边路和肋部创造力占优。", score: "3-0", pick: "西班牙胜", probability: "胜 80% / 平 14% / 负 6%", confidence: 82, type: "combo"},
  {teams: "法国 vs 塞内加尔", note: "身体对抗强度高，法国速度和阵容厚度更好。", score: "2-1", pick: "法国胜", probability: "胜 59% / 平 25% / 负 16%", confidence: 64, type: "hot"},
  {teams: "阿根廷 vs 阿尔及利亚", note: "阿根廷经验与控制力占优，适合不败方向。", score: "2-0", pick: "阿根廷胜", probability: "胜 68% / 平 22% / 负 10%", confidence: 74, type: "combo"},
  {teams: "葡萄牙 vs 刚果(金)", note: "葡萄牙阵容厚度更强，边路与中场创造力占优。", score: "2-0", pick: "葡萄牙胜", probability: "胜 77% / 平 16% / 负 7%", confidence: 79, type: "combo"},
  {teams: "英格兰 vs 克罗地亚", note: "淘汰赛级别强度，英格兰强但克罗地亚控节奏能力强。", score: "2-1", pick: "英格兰胜", probability: "胜 53% / 平 29% / 负 18%", confidence: 61, type: "upset"},
  {teams: "西班牙 vs 乌拉圭", note: "H组头名关键战，风格冲突明显，低比分概率高。", score: "1-1", pick: "平局", probability: "胜 43% / 平 32% / 负 25%", confidence: 55, type: "upset"},
  {teams: "法国 vs 挪威", note: "I组最强进攻对撞，法国整体更强，挪威单点爆破强。", score: "2-2", pick: "平局", probability: "胜 47% / 平 29% / 负 24%", confidence: 51, type: "upset"},
  {teams: "德国 vs 科特迪瓦", note: "德国控球，科特迪瓦反击；德国胜面高但丢球风险存在。", score: "2-1", pick: "德国胜", probability: "胜 57% / 平 25% / 负 18%", confidence: 63, type: "hot"},
  {teams: "荷兰 vs 瑞典", note: "F组排名分水岭，荷兰防守和转换质量略占优。", score: "2-1", pick: "荷兰胜", probability: "胜 54% / 平 27% / 负 19%", confidence: 60, type: "hot"}
];

function findAnalysisForJcMatch(jcMatch) {
  const home = normalizeName(jcMatch.home);
  const away = normalizeName(jcMatch.away);
  return matches.find(item => {
    const text = normalizeName(item.teams);
    return text.includes(home) && text.includes(away);
  });
}

function analystVerdictForModel(model) {
  const marketStatus = model.marketCheck?.status || "unavailable";
  const scenario = model.tacticalContext?.scenario || "";
  const hasBigScore = (model.dualScores || []).some(item => {
    const [home, away] = String(item.score || "").split("-").map(Number);
    return Math.max(home || 0, away || 0) >= 3;
  });
  if (model.betAction === "回避" || marketStatus === "divergent") return "四串一不建议纳入";
  if (model.lineupStatus !== "confirmed" && Number(model.matchContextScore || 0) < 56) return "等首发后再看";
  if (hasBigScore && scenario === "强队大胜路径" && Number(model.scoreProbability || 0) < 0.12) return "大比分只做博冷防线";
  if (model.betAction === "可跟踪" && Number(model.matchContextScore || 0) >= 55 && marketStatus !== "caution") return "可小注跟踪";
  return "只做比分参考";
}

function scenarioPenalty(selected, candidate) {
  const scenario = candidate.jcMatch.model.tacticalContext?.scenario || "";
  const sameScenarioCount = selected.filter(item => (item.jcMatch.model.tacticalContext?.scenario || "") === scenario).length;
  return sameScenarioCount >= 2 ? 10 : sameScenarioCount === 1 ? 3 : 0;
}

function comboCandidateScore(selected, candidate) {
  const model = candidate.jcMatch.model;
  let score = Number(model.betScore || 0) + Number(model.matchContextScore || 0) * 0.22 + Number(model.resultProbability || 0) * 18;
  score -= scenarioPenalty(selected, candidate);
  if ((model.marketCheck?.status || "") === "caution") score -= 6;
  if ((model.marketCheck?.status || "") === "divergent") score -= 18;
  if (model.lineupStatus !== "confirmed") {
    const unknownCount = selected.filter(item => item.jcMatch.model.lineupStatus !== "confirmed").length;
    if (unknownCount >= 3) score -= 8;
  }
  if (analystVerdictForModel(model) === "四串一不建议纳入") score -= 30;
  return score;
}

function selectDiversifiedCombo(candidates) {
  const selected = [];
  const pool = candidates.slice();
  while (selected.length < 4 && pool.length) {
    pool.sort((a, b) => comboCandidateScore(selected, b) - comboCandidateScore(selected, a));
    selected.push(pool.shift());
  }
  return selected;
}

function diversificationAuditFor(selected) {
  const scenarios = selected.map(item => item.jcMatch.model.tacticalContext?.scenario || "未知");
  const scenarioCounts = scenarios.reduce((map, scenario) => {
    map[scenario] = (map[scenario] || 0) + 1;
    return map;
  }, {});
  const marketStatuses = selected.map(item => item.jcMatch.model.marketCheck?.status || "unavailable");
  const lineupUnconfirmedCount = selected.filter(item => item.jcMatch.model.lineupStatus === "unconfirmed").length;
  const lineupProjectedCount = selected.filter(item => item.jcMatch.model.lineupStatus === "projected").length;
  const lineupProjectedConfirmedCount = selected.filter(item => item.jcMatch.model.lineupStatus === "projected-confirmed").length;
  const warnings = [];
  if (Object.values(scenarioCounts).some(count => count >= 3)) warnings.push("战术路径集中");
  if (marketStatuses.includes("divergent")) warnings.push("存在市场校验明显分歧");
  if (marketStatuses.filter(status => status === "caution").length >= 2) warnings.push("市场校验谨慎场次偏多");
  if (lineupUnconfirmedCount >= 4) warnings.push("全部首发未确认");
  else if (lineupProjectedCount >= 4) warnings.push("全部仅预计首发");
  const score = Math.max(0, Math.min(100,
    86 -
    (Object.values(scenarioCounts).some(count => count >= 3) ? 12 : 0) -
    (marketStatuses.includes("divergent") ? 18 : 0) -
    (marketStatuses.filter(status => status === "caution").length * 5) -
    (lineupUnconfirmedCount >= 4 ? 8 : lineupUnconfirmedCount * 2) -
    (lineupProjectedCount >= 4 ? 4 : lineupProjectedCount)
  ));
  return {
    score,
    scenarios,
    scenarioCounts,
    marketStatuses,
    lineupUnknownCount: lineupUnconfirmedCount,
    lineupProjectedCount,
    lineupProjectedConfirmedCount,
    warnings
  };
}

function comboAnalystVerdict({comboAction, comboBetScore, comboReliability, diversificationAudit}) {
  if (comboAction === "回避" || diversificationAudit.score < 55 || diversificationAudit.warnings.includes("存在市场校验明显分歧")) return "四串一不建议纳入";
  if (diversificationAudit.lineupUnknownCount >= 4 && comboBetScore < 74) return "等首发后再看";
  if (diversificationAudit.lineupProjectedCount >= 4 && comboBetScore < 72) return "等首发后再看";
  if (comboAction === "可跟踪" && comboBetScore >= 68 && comboReliability >= 48 && diversificationAudit.score >= 64) return "可小注跟踪";
  return "只做比分参考";
}

function buildScoreCombos(jcMatches, finalMainPicks = null) {
  const finalMainIds = Array.isArray(finalMainPicks) ? new Set(finalMainPicks.map(item => item.matchId)) : null;
  const candidates = jcMatches
    .filter(jcMatch => jcMatch.model)
    .filter(jcMatch => !finalMainIds || finalMainIds.has(jcMatch.matchId))
    .filter(jcMatch => jcMatch.model.betAction === "可跟踪" && jcMatch.model.marketCheck?.status !== "divergent")
    .map(jcMatch => ({jcMatch, analysis: findAnalysisForJcMatch(jcMatch)}))
    .sort((a, b) =>
      Number(a.jcMatch.model.betAction === "回避") - Number(b.jcMatch.model.betAction === "回避") ||
      Number(b.jcMatch.model.risk === "低") - Number(a.jcMatch.model.risk === "低") ||
      Number(b.jcMatch.model.recommendationType === "稳定") - Number(a.jcMatch.model.recommendationType === "稳定") ||
      Number(b.jcMatch.model.betScore || 0) - Number(a.jcMatch.model.betScore || 0) ||
      Number(b.jcMatch.model.matchContextScore || 0) - Number(a.jcMatch.model.matchContextScore || 0) ||
      Number(b.jcMatch.model.resultProbability || 0) - Number(a.jcMatch.model.resultProbability || 0) ||
      Number(b.jcMatch.model.analysisQualityScore || 0) - Number(a.jcMatch.model.analysisQualityScore || 0) ||
      Number(b.jcMatch.model.confidence || 0) - Number(a.jcMatch.model.confidence || 0)
    );
  if (candidates.length < 4) return [];
  const selected = selectDiversifiedCombo(candidates);
  const comboConfidence = Math.round(selected.reduce((sum, item) => sum + Number(item.jcMatch.model.confidence || 0), 0) / selected.length);
  const comboBetScore = Math.round(selected.reduce((sum, item) => sum + Number(item.jcMatch.model.betScore || 0), 0) / selected.length);
  const comboReliability = Math.round(selected.reduce((sum, item) => sum + Number(item.jcMatch.model.resultProbability || 0) * 100, 0) / selected.length);
  const diversificationAudit = diversificationAuditFor(selected);
  const dualScoreCoverage = round4(selected.reduce((product, item) => product * Number(item.jcMatch.model.dualScoreCoverage || 0), 1));
  const rawComboAction = selected.some(item => item.jcMatch.model.betAction === "回避") || comboBetScore < 60 || comboReliability < 42 || diversificationAudit.score < 52
    ? "回避"
    : comboBetScore >= 70 && comboReliability >= 48
      ? "可跟踪"
      : "观察";
  const analystVerdict = comboAnalystVerdict({comboAction: rawComboAction, comboBetScore, comboReliability, diversificationAudit});
  const comboAction = analystVerdict === "可小注跟踪"
    ? rawComboAction
    : analystVerdict === "四串一不建议纳入"
      ? "回避"
      : "观察";
  const coverageCombos = selected.reduce((rows, item) => {
    const scores = item.jcMatch.model.dualScores || [];
    const upsetScore = item.jcMatch.model.upsetScore?.score || "";
    return rows.flatMap(row => scores.map(score => ({
      matches: [...row.matches, {matchId: item.jcMatch.matchId, teams: item.jcMatch.teams, score: score.score, role: score.role, upsetScore}],
      probability: round4(row.probability * Number(score.probability || 0))
    })));
  }, [{matches: [], probability: 1}]);
  return [{
    name: "模型四串一比分",
    selectionMode: "independent-reliability",
    format: "4x2-score",
    risk: "每场双比分生成16注四串一，竞彩/500只提供场次编号和开售状态，不参与比分与胜平负判断。",
    comboConfidence,
    comboBetScore,
    comboReliability,
    comboAction,
    analystVerdict,
    diversificationAudit,
    dualScoreCoverage,
    stakeUnits: coverageCombos.length,
    coverageCombos,
    matches: selected.map(item => ({
      matchId: item.jcMatch.matchId,
      league: item.jcMatch.league,
      teams: item.jcMatch.teams,
      startTime: item.jcMatch.startTime,
      score: item.jcMatch.model.score,
      dualScores: item.jcMatch.model.dualScores,
      dualScoreCoverage: item.jcMatch.model.dualScoreCoverage,
      upsetScore: item.jcMatch.model.upsetScore,
      pick: item.jcMatch.model.pick,
      confidence: item.jcMatch.model.confidence,
      risk: item.jcMatch.model.risk,
      recommendationType: item.jcMatch.model.recommendationType,
      betScore: item.jcMatch.model.betScore,
      betAction: item.jcMatch.model.betAction,
      analystVerdict: analystVerdictForModel(item.jcMatch.model),
      analysisQualityScore: item.jcMatch.model.analysisQualityScore,
      matchContextScore: item.jcMatch.model.matchContextScore,
      tacticalScenario: item.jcMatch.model.tacticalContext?.scenario || "",
      marketCheckStatus: item.jcMatch.model.marketCheck?.status || "unavailable",
      marketAnomaly: item.jcMatch.model.marketAnomaly,
      scoreRationale: item.jcMatch.model.scoreRationale,
      riskFlags: item.jcMatch.model.riskFlags,
      scoreProbability: item.jcMatch.model.scoreProbability,
      resultProbability: item.jcMatch.model.resultProbability,
      drawProbability: item.jcMatch.model.drawProbability,
      modelReason: item.jcMatch.model.reason,
      note: item.analysis?.note || item.jcMatch.model.reason
    }))
  }];
}

function buildReliabilitySummary(jcMatches) {
  const rows = jcMatches.filter(item => item.model);
  const matchCount = rows.length;
  const countBy = predicate => rows.filter(predicate).length;
  const trackedCount = countBy(item => item.model.betAction === "可跟踪");
  const watchCount = countBy(item => item.model.betAction === "观察");
  const avoidCount = countBy(item => item.model.betAction === "回避");
  const highDrawCount = countBy(item => Number(item.model.drawProbability || 0) >= 0.3);
  const lineupUnknownCount = countBy(item => item.model.lineupStatus === "unconfirmed");
  const lineupProjectedCount = countBy(item => item.model.lineupStatus === "projected");
  const lineupProjectedConfirmedCount = countBy(item => item.model.lineupStatus === "projected-confirmed");
  const averageReliability = matchCount
    ? Math.round(rows.reduce((sum, item) => sum + Number(item.model.resultProbability || 0) * 100, 0) / matchCount)
    : 0;
  const executionAdvice = matchCount < 4 || avoidCount > matchCount * 0.6 || averageReliability < 42
    ? "不建议四串一"
    : trackedCount >= 4 && averageReliability >= 48
      ? "可跟踪"
      : "只观察";
  const pickRows = rows.map(item => ({
      matchId: item.matchId,
      teams: item.teams,
      startTime: item.startTime,
      reliability: Math.round(Number(item.model.resultProbability || 0) * 100),
      drawProbability: Math.round(Number(item.model.drawProbability || 0) * 100),
      score: item.model.score,
      dualScores: item.model.dualScores,
      dualScoreCoverage: item.model.dualScoreCoverage,
      upsetScore: item.model.upsetScore,
      betScore: item.model.betScore,
      betAction: item.model.betAction,
      lineupStatus: item.model.lineupStatus,
      lineupConfidence: item.model.lineupContext?.confidence ?? 0,
      confirmationLabel: item.model.lineupStatus === "confirmed"
        ? "最终确认"
        : item.model.lineupStatus === "projected-confirmed"
          ? "多源预计"
          : item.model.lineupStatus === "projected"
            ? "预计首发"
            : "等首发确认",
      matchContextScore: item.model.matchContextScore,
      tacticalScenario: item.model.tacticalContext?.scenario || "",
      marketCheckStatus: item.model.marketCheck?.status || "unavailable",
      marketAnomalyLevel: item.model.marketAnomaly?.level || "none",
      marketAnomalyPenalty: item.model.marketAnomaly?.penalty || 0,
      marketAnomalyFlags: item.model.marketAnomaly?.flags || [],
      riskFlags: item.model.riskFlags
    }));
  const sortFinalPicks = (a, b) =>
    Number(b.betAction === "可跟踪") - Number(a.betAction === "可跟踪") ||
    Number(a.marketAnomalyPenalty || 0) - Number(b.marketAnomalyPenalty || 0) ||
    Number(b.betScore || 0) - Number(a.betScore || 0) ||
    Number(b.reliability || 0) - Number(a.reliability || 0) ||
    Number(b.matchContextScore || 0) - Number(a.matchContextScore || 0);
  const bestReliableMatches = pickRows
    .filter(item => item.betAction !== "回避" && item.marketCheckStatus !== "divergent")
    .sort(sortFinalPicks)
    .slice(0, 6);
  const finalPicks = {
    main: pickRows.filter(item => item.betAction === "可跟踪" && item.marketCheckStatus !== "divergent").sort(sortFinalPicks).slice(0, 3),
    watch: pickRows.filter(item => item.betAction === "观察" && item.marketCheckStatus !== "divergent").sort(sortFinalPicks).slice(0, 6),
    avoid: pickRows.filter(item => item.betAction === "回避" || item.marketCheckStatus === "divergent").sort((a, b) =>
      Number(b.marketCheckStatus === "divergent") - Number(a.marketCheckStatus === "divergent") ||
      Number(b.reliability || 0) - Number(a.reliability || 0)
    )
  };
  const summaryText = `平均可靠性 ${averageReliability}%，可跟踪 ${trackedCount} 场，观察 ${watchCount} 场，回避 ${avoidCount} 场，平局概率偏高 ${highDrawCount} 场；当前建议：${executionAdvice}。`;
  return {
    matchCount,
    trackedCount,
    watchCount,
    avoidCount,
    highDrawCount,
    lineupUnknownCount,
    lineupProjectedCount,
    lineupProjectedConfirmedCount,
    averageReliability,
    bestReliableMatches,
    finalPicks,
    executionAdvice,
    summaryText
  };
}

const [fifaSource, fifaGroupStandings, sporttery500, injuries, historicalWorldCup, footballRatings, fifaRankings, projectedLineups, lineupNewsSources, weatherForecasts, footballDataApi, recentInternationalResults] = await Promise.all([
  checkSource("FIFA 官方赛程", fifaUrl),
  fetchFifaGroupStandings(),
  fetch500SportteryMatches(),
  fetchInjuryReport(),
  fetchHistoricalWorldCupSummary(),
  fetchFootballRatingsProfile(),
  fetchFifaRankings(),
  fetchProjectedLineups(),
  fetchLineupNewsDiagnostics(),
  fetchVenueWeatherForecasts(),
  checkFootballDataApiSource(),
  fetchRecentInternationalResults()
]);

const now = new Date();
const previousOpenMatches = loadPreviousOpenMatches();
const openMatchSource = sporttery500.matches.length
  ? {matches: sporttery500.matches, source: sporttery500.source}
  : {matches: previousOpenMatches, source: {
      name: "本地上一轮竞彩开售列表",
      url: "worldcup2026-live-data.json",
      ok: previousOpenMatches.length > 0,
      statusCode: 0,
      bytes: previousOpenMatches.length,
      note: previousOpenMatches.length > 0 ? `外部开售列表失败，沿用上一轮 ${previousOpenMatches.length} 场并重新计算模型。` : "外部开售列表失败，且本地无上一轮数据。"
    }};
const groupStandings = fifaGroupStandings;
const oddsMovement = oddsMovementForMatches(openMatchSource.matches, now.toISOString());
const scheduleDensity = scheduleDensityForMatches(openMatchSource.matches);
const venueMap = venueMapForMatches(openMatchSource.matches, weatherForecasts.forecasts);
const currentOpenTeams = [...new Set(openMatchSource.matches.flatMap(match => [match.home, match.away]))];
const projectedLineupSources = (projectedLineups.sources || []).map(source => {
  const missingTeams = currentOpenTeams.filter(team => !projectedLineups.lineups[normalizeName(team)]);
  return {
    ...source,
    checkedTeams: currentOpenTeams.length,
    missingTeams,
    coveragePercent: currentOpenTeams.length ? Math.round((currentOpenTeams.length - missingTeams.length) * 100 / currentOpenTeams.length) : 0
  };
});
lineupNewsSources.queryExecutionLimit = 6;
lineupNewsSources.teamSearches = await enrichTeamNewsSearches(buildTeamNewsSearches(openMatchSource.matches, lineupNewsSources), lineupNewsSources.queryExecutionLimit);
const publicLineupNewsSources = (({searchSources, ...rest}) => rest)(lineupNewsSources);
const newsSemanticContexts = buildNewsSemanticContexts(openMatchSource.matches, {
  lineupNewsSources,
  projectedLineups: projectedLineups.lineups,
  injuryReport: injuries.report,
  teamSearches: lineupNewsSources.teamSearches
});
const jcMatches = openMatchSource.matches.map(item => ({
  ...item,
  model: buildMatchModel(item, {
    injuryReport: injuries.report,
    injurySourceOk: injuries.source.ok,
    ratings: footballRatings.ratings,
    fifaRankings: fifaRankings.rankings,
    projectedLineups: projectedLineups.lineups,
    projectedLineupSources,
    lineupNewsSources: publicLineupNewsSources,
    newsSemanticContexts,
    historicalSummary: historicalWorldCup.summary,
    recentResults: recentInternationalResults.stats,
    oddsMovement: oddsMovement.movements,
    scheduleDensity,
    venueMap,
    weatherForecasts: weatherForecasts.forecasts,
    groupStandings: groupStandings.standings
  })
}));
const jcSource = openMatchSource.source;
const reliabilitySummary = buildReliabilitySummary(jcMatches);
const scoreCombos = buildScoreCombos(jcMatches);
scoreCombos.forEach(combo => {
  combo.comboAnalysisQuality = Math.round(combo.matches.reduce((sum, item) => sum + Number(item.analysisQualityScore || 0), 0) / combo.matches.length);
});
const sources = [
  fifaSource,
  sporttery500.source,
  ...(jcSource.name === sporttery500.source.name && jcSource.url === sporttery500.source.url ? [] : [jcSource]),
  injuries.source,
  historicalWorldCup.source,
  footballRatings.source,
  fifaRankings.source,
  projectedLineups.source,
  lineupNewsSources.source,
  weatherForecasts.source,
  footballDataApi.source,
  recentInternationalResults.source,
  groupStandings.source,
  oddsMovement.source
];
sources.push({
  name: "新闻语义分析",
  url: "derived:lineup-news-sources",
  ok: Object.keys(newsSemanticContexts).length > 0,
  statusCode: 0,
  bytes: Object.keys(newsSemanticContexts).length,
  note: `基于阵容新闻、预计首发和伤停文本提取${Object.keys(newsSemanticContexts).length}队语义标签，用于轮换、抢攻、低位、防反等赛前情报校验。`
});
const publicSourceOk = fifaSource.ok;
const jcSummary = jcSource.ok ? `竞彩开售赛事 ${jcMatches.length} 场，四串一组合 ${scoreCombos.length} 组。` : `竞彩开售列表获取失败：${jcSource.note}`;

const data = {
  status: {
    updatedAtLocal: now.toLocaleString("zh-CN", {hour12: false}),
    updatedAtIso: now.toISOString(),
    summary: `${publicSourceOk ? "已刷新公开赛程状态" : "公开赛程状态刷新失败"}；${jcSummary}`,
    analysisVersion: "sporttery-open-combo-v9-independent",
    refreshMinutes: 30,
    sources
  },
  groups,
  leaders,
  alerts,
  matches,
  jcMatches,
  scoreCombos,
  reliabilitySummary,
  analysisInputs: {
    historicalWorldCup: historicalWorldCup.summary,
    footballRatings: footballRatings.ratings,
    fifaRankings: fifaRankings.rankings,
    projectedLineups: projectedLineups.lineups,
    projectedLineupSources,
    lineupNewsSources: publicLineupNewsSources,
    newsSemanticContexts,
    recentInternationalResults: recentInternationalResults.stats,
    footballDataApi: {available: footballDataApi.apiAvailable},
    groupStandings: groupStandings.standings,
    oddsMovement: oddsMovement.movements,
    scheduleDensity,
    venueMap,
    weatherForecasts: weatherForecasts.forecasts
  }
};

fs.writeFileSync(path.join(workspace, "worldcup2026-live-data.json"), JSON.stringify(data, null, 2), "utf8");
fs.writeFileSync(path.join(workspace, "worldcup2026-live-data.js"), `window.WORLDCUP2026_LIVE_DATA = ${JSON.stringify(data, null, 2)};\n`, "utf8");
fs.writeFileSync(path.join(workspace, "worldcup2026-odds-history.json"), JSON.stringify(oddsMovement.history, null, 2), "utf8");
fs.appendFileSync(path.join(workspace, "worldcup2026-update.log"), `${data.status.updatedAtLocal} ${data.status.summary}\n`, "utf8");

console.log(`${data.status.updatedAtLocal} ${data.status.summary}`);
