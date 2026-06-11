import assert from "node:assert/strict";
import fs from "node:fs";

const data = JSON.parse(fs.readFileSync("worldcup2026-live-data.json", "utf8"));
assert.equal(data.status.analysisVersion, "sporttery-open-combo-v9-independent");
assert.ok(Array.isArray(data.jcMatches), "jcMatches should be an array");
assert.ok(data.jcMatches.length >= 4, "expected at least four open betting matches");
assert.ok(data.jcMatches.every(item => item.league === "世界杯"), "jcMatches should only include World Cup matches");
assert.ok(
  data.status.sources.some(source => /竞彩|500/.test(source.name)),
  "data should include betting list source diagnostics"
);
assert.ok(
  !data.status.sources.some(source => /中国竞彩网|FourFourTwo/.test(source.name)),
  "data should not include repeatedly blocked collection sources"
);
assert.ok(
  data.status.sources.some(source => /历史世界杯比分/.test(source.name)),
  "data should include historical World Cup score distribution source"
);
assert.ok(
  data.status.sources.some(source => /FIFA排名|Elo|近期状态|新闻/.test(source.name)),
  "data should include team strength or recent form analysis source"
);
assert.ok(
  data.status.sources.some(source => /近期国家队赛果/.test(source.name)),
  "data should include recent national team results source"
);
assert.ok(
  data.status.sources.some(source => /FIFA官方排名/.test(source.name)),
  "data should include official FIFA ranking source diagnostics"
);
assert.ok(
  data.status.sources.some(source => /预计首发/.test(source.name)),
  "data should include projected lineup source diagnostics"
);
assert.ok(
  data.status.sources.some(source => /阵容新闻|lineup news|Sports Mole|FotMob|Rotowire/i.test(source.name)),
  "data should include alternate lineup news source diagnostics"
);
assert.ok(
  data.status.sources.some(source => /Footballdata|football-data|赛果API/.test(source.name)),
  "data should include API-style football results source diagnostics"
);
assert.ok(
  data.status.sources.some(source => /小组积分/.test(source.name)),
  "data should include group standings source diagnostics"
);
assert.ok(
  data.status.sources.some(source => source.url === "https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/standings"),
  "data should include FIFA official standings source diagnostics"
);
assert.ok(
  data.status.sources.some(source => /盘口变化|SP变化/.test(source.name)),
  "data should include odds movement diagnostics"
);
assert.ok(
  data.status.sources.some(source => /天气|weather|Open-Meteo/i.test(source.name)),
  "data should include venue weather source diagnostics"
);

const modelRows = data.jcMatches.filter(item => item.model);
assert.equal(modelRows.length, data.jcMatches.length, "every open betting match should include model output");

assert.ok(data.reliabilitySummary, "data should include reliability summary");
assert.ok(data.analysisInputs?.recentInternationalResults, "data should include recent international result analysis inputs");
assert.ok(Object.keys(data.analysisInputs.recentInternationalResults).length > 0, "recent international result inputs should not be empty");
const currentTeams = [...new Set(data.jcMatches.flatMap(item => [item.home, item.away]))];
const teamsWithRecentResults = currentTeams.filter(team => data.analysisInputs.recentInternationalResults[team]?.played > 0);
assert.ok(
  teamsWithRecentResults.length >= Math.ceil(currentTeams.length * 0.5),
  "at least half of current betting teams should match recent international results"
);
const recentRows = currentTeams.map(team => data.analysisInputs.recentInternationalResults[team]).filter(Boolean);
assert.ok(recentRows.some(row => Number(row.weightedPlayed || 0) > 0), "recent result inputs should include weighted match volume");
assert.ok(recentRows.some(row => Number(row.sampleQuality || 0) > 0), "recent result inputs should include sample quality");
assert.ok(recentRows.every(row => typeof row.matchTypeMix === "object"), "recent result inputs should include match type mix");
assert.ok(recentRows.some(row => Number(row.competitiveShare || 0) > 0), "recent result inputs should include competitive match share");
assert.ok(recentRows.every(row => typeof row.lastMatchDate === "string"), "recent result inputs should include last match date");
assert.ok(recentRows.some(row => typeof row.strongOpponentShare === "number"), "recent result inputs should include strong opponent share");
assert.ok(recentRows.some(row => Array.isArray(row.recentMatches) && row.recentMatches.length > 0), "recent result inputs should retain recent match samples");
const mexicoRecent = data.analysisInputs.recentInternationalResults["墨西哥"]?.recentMatches || [];
const mexicoEliteFriendlies = mexicoRecent.filter(row => ["葡萄牙", "比利时"].includes(row.opponent));
assert.ok(
  mexicoEliteFriendlies.every(row => Number(row.opponentStrength || 0) >= 80),
  "recent result opponent names should be canonicalized before strength weighting"
);
assert.ok(
  mexicoEliteFriendlies.every(row => row.opponentMapped === true),
  "recent result samples should mark canonicalized elite opponents as mapped"
);
assert.ok(data.analysisInputs?.fifaRankings, "data should include official FIFA ranking analysis inputs");
assert.ok(Object.keys(data.analysisInputs.fifaRankings).length > 0, "official FIFA ranking inputs should not be empty");
const currentRankingRows = currentTeams.map(team => data.analysisInputs.fifaRankings[team]).filter(Boolean);
assert.ok(
  currentRankingRows.filter(row => row.source === "fifa-official-api").length >= Math.ceil(currentTeams.length * 0.5),
  "at least half of current betting teams should be backed by the official FIFA ranking API"
);
assert.ok(data.analysisInputs?.projectedLineups, "data should include projected lineup analysis inputs");
assert.ok(data.analysisInputs?.projectedLineupSources, "data should include structured projected lineup source diagnostics");
assert.ok(
  data.analysisInputs.projectedLineupSources.some(source => source.structured === true && source.parsedTeams >= 12),
  "at least one projected lineup source should expose structured team-level lineups"
);
assert.ok(
  data.analysisInputs.projectedLineupSources.every(source => Array.isArray(source.missingTeams)),
  "projected lineup source diagnostics should expose missing teams"
);
assert.ok(data.analysisInputs?.lineupNewsSources, "data should include alternate lineup news diagnostics");
assert.ok(Array.isArray(data.analysisInputs.lineupNewsSources.sources), "alternate lineup news diagnostics should list checked sources");
assert.ok(
  data.analysisInputs.lineupNewsSources.sources.some(source => source.sourceTier === "official"),
  "lineup/news diagnostics should include at least one official World Cup news source"
);
assert.ok(
  data.analysisInputs.lineupNewsSources.sources.some(source => source.sourceTier === "major-media"),
  "lineup/news diagnostics should include at least one major-media World Cup news source"
);
assert.ok(
  data.analysisInputs.lineupNewsSources.sources.some(source => source.sourceType === "rss" && source.ok && source.feedItems > 0),
  "lineup/news diagnostics should include at least one parseable football news RSS source"
);
assert.ok(
  data.analysisInputs.lineupNewsSources.sources.some(source => source.sourceType === "lineup-news" && source.ok && /lineup|team news|predicted/i.test(source.name)),
  "lineup/news diagnostics should include at least one static predicted-lineup or team-news source"
);
assert.ok(
  data.analysisInputs.lineupNewsSources.teamSearches && typeof data.analysisInputs.lineupNewsSources.teamSearches === "object",
  "lineup/news diagnostics should include team-level high-trust search coverage"
);
assert.ok(
  data.analysisInputs.lineupNewsSources.queryExecutionLimit > 0 && data.analysisInputs.lineupNewsSources.queryExecutionLimit <= 12,
  "team-level high-trust search execution should be explicitly rate limited"
);
const teamSearchRows = currentTeams.map(team => data.analysisInputs.lineupNewsSources.teamSearches[team]).filter(Boolean);
assert.ok(teamSearchRows.length >= Math.ceil(currentTeams.length * 0.5), "team-level high-trust searches should cover current betting teams");
assert.ok(
  teamSearchRows.every(row => row.sourceCoverageTierSummary && typeof row.sourceCoverageTierSummary === "object"),
  "team-level high-trust searches should summarize source coverage tiers"
);
assert.ok(
  teamSearchRows.every(row => Array.isArray(row.querySources) && row.querySources.some(source => source.sourceTier === "official") && row.querySources.some(source => source.sourceTier === "major-media")),
  "team-level high-trust searches should list official and major-media query source attempts"
);
assert.ok(
  teamSearchRows.every(row => (row.sourceHits || []).every(hit => !(hit.matchedNames || []).some(name => /^[A-Za-z]{1,3}$/.test(String(name))))),
  "team-level source hits should not rely on ambiguous short English aliases"
);
assert.ok(
  teamSearchRows.some(row => row.querySources.some(source => ["hit", "no-hit", "blocked", "searched"].includes(source.status))),
  "team-level high-trust searches should execute a limited batch of real query source checks"
);
assert.ok(data.analysisInputs?.newsSemanticContexts, "data should include news semantic analysis inputs");
assert.ok(Object.keys(data.analysisInputs.newsSemanticContexts).length > 0, "news semantic contexts should not be empty");
assert.ok(
  currentTeams.some(team => Array.isArray(data.analysisInputs.newsSemanticContexts[team]?.tags)),
  "news semantic contexts should cover current betting teams"
);
const semanticRows = currentTeams.map(team => data.analysisInputs.newsSemanticContexts[team]).filter(Boolean);
assert.ok(
  semanticRows.every(row => Array.isArray(row.evidence)),
  "team news semantic contexts should expose traceable evidence"
);
assert.ok(
  semanticRows.every(row => row.sourceTierSummary && typeof row.sourceTierSummary === "object"),
  "team news semantic contexts should summarize source tiers"
);
assert.ok(
  semanticRows.every(row => row.sourceCoverageTierSummary && typeof row.sourceCoverageTierSummary === "object"),
  "team news semantic contexts should summarize team mention source coverage tiers"
);
assert.ok(
  semanticRows.some(row => (row.sourceCoverageTierSummary.official || 0) > 0 || (row.sourceCoverageTierSummary["major-media"] || 0) > 0),
  "news semantic coverage should include official or major-media team mentions when available"
);
assert.ok(
  semanticRows.every(row => typeof row.conflict === "boolean" && typeof row.trustedImpact === "number"),
  "team news semantic contexts should expose conflict and trusted impact gating"
);
assert.ok(
  semanticRows.every(row => Math.abs(Number(row.trustedImpact || 0)) <= Math.abs(Number(row.scoreImpact || 0)) || Number(row.scoreImpact || 0) === 0),
  "trusted semantic impact should not exceed raw semantic impact"
);
assert.ok(
  semanticRows.every(row => (row.evidence || []).every(item => String(item.keyword || "").length <= 80 && String(item.snippet || "").length <= 260)),
  "news semantic evidence should keep compact keyword and snippet excerpts"
);
const rssSemanticEvidence = semanticRows.flatMap(row => row.evidence || []).filter(item => item.sourceType === "rss");
assert.ok(
  rssSemanticEvidence.every(item => item.sourceTier === "major-media" && item.title),
  "RSS semantic evidence should be item-level major-media evidence when present"
);
assert.ok(
  semanticRows.every(row => (row.evidence || []).every(item => item.sourceType !== "rss" || !/referee|fan|fans|ticket|travel by bus/i.test(`${item.title || ""} ${item.snippet || ""}`))),
  "RSS semantic evidence should exclude peripheral referee/fan/travel logistics stories"
);
assert.ok(
  semanticRows.every(row => (row.evidence || []).every(item => !/localStorage|third-party providers|wager responsibly|JSON|removeItem/i.test(`${item.title || ""} ${item.snippet || ""}`))),
  "news semantic evidence should exclude scripts, storage code, and responsible-gambling boilerplate"
);
const projectedLineupTeams = Object.keys(data.analysisInputs.projectedLineups);
assert.ok(projectedLineupTeams.length >= 12, "projected lineup collection should parse structured lineup inputs for at least 12 teams");
assert.ok(
  projectedLineupTeams.some(team => currentTeams.map(normalize => String(normalize).replace(/\s+/g, "").toLowerCase()).includes(team)),
  "projected lineup inputs should cover at least one current betting team"
);
if (Object.keys(data.analysisInputs.projectedLineups).length === 0) {
  assert.equal(data.reliabilitySummary.lineupProjectedCount + data.reliabilitySummary.lineupProjectedConfirmedCount, 0, "lineup status should not be promoted when no reliable projected lineup rows are parsed");
}
assert.ok(data.analysisInputs?.groupStandings, "data should include group standings analysis inputs even before live standings exist");
const unavailableGroupTeams = data.jcMatches.flatMap(item => [
  item.model?.groupSituationContext?.home?.status === "unavailable" ? item.home : null,
  item.model?.groupSituationContext?.away?.status === "unavailable" ? item.away : null
]).filter(Boolean);
assert.deepEqual(unavailableGroupTeams, [], "current betting teams should resolve to group standing rows");
assert.ok(data.analysisInputs?.oddsMovement, "data should include odds movement analysis inputs");
assert.ok(data.analysisInputs?.scheduleDensity, "data should include schedule density and rest-day inputs");
assert.ok(data.analysisInputs?.venueMap, "data should include venue and host environment inputs");
assert.ok(data.analysisInputs?.weatherForecasts, "data should include venue weather forecast inputs");
assert.equal(data.reliabilitySummary.matchCount, data.jcMatches.length, "reliability summary match count should match current betting matches");
assert.ok(data.reliabilitySummary.averageReliability >= 0 && data.reliabilitySummary.averageReliability <= 100, "summary should include average reliability");
assert.ok(["可跟踪", "只观察", "不建议四串一"].includes(data.reliabilitySummary.executionAdvice), "summary should include independent execution advice");
if (data.reliabilitySummary.lineupUnknownCount === data.reliabilitySummary.matchCount) {
  assert.notEqual(data.reliabilitySummary.executionAdvice, "可跟踪", "summary should not recommend tracking when every lineup is unconfirmed");
}
assert.ok(data.reliabilitySummary.lineupProjectedCount >= 0, "summary should track projected lineups separately from unknown lineups");
assert.ok(data.reliabilitySummary.lineupProjectedConfirmedCount >= 0, "summary should track cross-verified projected lineups separately");
assert.ok(Array.isArray(data.reliabilitySummary.bestReliableMatches), "summary should include reliable match list");
assert.ok(data.reliabilitySummary.bestReliableMatches.length > 0, "summary should include at least one reliable match");
assert.ok(data.reliabilitySummary.finalPicks, "summary should include final pick tiers");
assert.ok(Array.isArray(data.reliabilitySummary.finalPicks.main), "final picks should include main tier");
assert.ok(Array.isArray(data.reliabilitySummary.finalPicks.watch), "final picks should include watch tier");
assert.ok(Array.isArray(data.reliabilitySummary.finalPicks.avoid), "final picks should include avoid tier");
assert.ok(data.reliabilitySummary.finalPicks.main.every(item => item.betAction === "可跟踪"), "main final picks should only include trackable matches");
assert.ok(data.reliabilitySummary.finalPicks.main.every(item => item.lineupStatus), "main final picks should expose lineup status");
assert.ok(data.reliabilitySummary.finalPicks.main.every(item => item.confirmationLabel), "main final picks should expose confirmation label");
assert.ok(data.reliabilitySummary.finalPicks.main.every(item => item.lineupStatus === "confirmed" || item.confirmationLabel !== "最终确认"), "unconfirmed lineup picks should not be labelled final confirmed");
const comboEligibleRows = data.jcMatches.filter(item => item.model?.betAction === "可跟踪" && item.model?.marketCheck?.status !== "divergent");
if (comboEligibleRows.length >= 4) {
  assert.ok(data.scoreCombos.length > 0, "score combos should be generated when at least four trackable non-divergent matches exist");
  assert.equal(data.scoreCombos[0].matches.length, 4, "generated score combo should include four matches");
}
for (const item of data.reliabilitySummary.bestReliableMatches) {
  assert.match(item.score, /^\d-\d$/, "reliable match row should include a main score");
  assert.notEqual(item.betAction, "回避", "best reliable match list should not include avoid picks");
  assert.notEqual(item.marketCheckStatus, "divergent", "best reliable match list should not include market-divergent picks");
  assert.ok(Array.isArray(item.dualScores) && item.dualScores.length === 2, "reliable match row should include two score picks");
  assert.deepEqual(item.dualScores.map(row => row.role), ["主推", "备用"], "reliable match row should label score picks as main and backup");
}
assert.ok(!("marketSummary" in data), "data should not include market summary");

const mainScoreCounts = modelRows.reduce((counts, item) => {
  counts[item.model.score] = (counts[item.model.score] || 0) + 1;
  return counts;
}, {});
assert.ok(
  Math.max(...Object.values(mainScoreCounts)) <= Math.ceil(modelRows.length * 0.4),
  "no single main score should dominate more than 40% of recommendations"
);
const scenarioSet = new Set(modelRows.map(item => item.model.expertScenario));
assert.ok(scenarioSet.size >= 5, "expert scenarios should vary by match context");
const bigMismatchRows = modelRows.filter(item => Math.abs(Number(item.model.strength?.diff || 0)) >= 20);
assert.ok(bigMismatchRows.length > 0, "test data should include strong mismatch matches");
assert.ok(
  bigMismatchRows.some(item => item.model.dualScores.some(row => {
    const [home, away] = row.score.split("-").map(Number);
    return Math.abs(home - away) >= 2;
  })),
  "strong mismatch expert picks should include at least one two-goal favorite-win route"
);
const eliteMismatchRows = modelRows.filter(item => Math.abs(Number(item.model.strength?.diff || 0)) >= 24);
assert.ok(
  eliteMismatchRows.every(item => {
    const topFive = item.model.scoreCandidates.slice(0, 5).map(row => row.score);
    return topFive.includes(item.model.dualScores[0].score);
  }),
  "elite mismatch main score should stay aligned with the top five score distribution candidates"
);
const upsetScoreCounts = modelRows.reduce((counts, item) => {
  const upset = item.model.upsetScore;
  if (upset) counts[upset.score] = (counts[upset.score] || 0) + 1;
  return counts;
}, {});
assert.ok(Object.keys(upsetScoreCounts).length >= 4, "upset score picks should include more than repeated 1-1 covers");
assert.ok(
  Math.max(...Object.values(upsetScoreCounts)) <= Math.ceil(modelRows.length * 0.55),
  "no single upset score should dominate more than 55% of recommendations"
);

for (const item of modelRows.slice(0, 8)) {
  assert.match(item.model.score, /^\d-\d$/, `${item.matchId} should include a predicted score`);
  assert.ok(["home", "draw", "away"].includes(item.model.result), `${item.matchId} should include result direction`);
  assert.ok(item.model.confidence >= 0 && item.model.confidence <= 100, `${item.matchId} confidence should be 0-100`);
  assert.ok(["低", "中", "高"].includes(item.model.risk), `${item.matchId} should include risk level`);
  assert.ok(item.model.reason.length > 8, `${item.matchId} should include model reason`);
  assert.ok(!("implied" in item.model), `${item.matchId} should not include official implied probabilities`);
  assert.ok(!("marketOdds" in item.model), `${item.matchId} should not include market odds`);
  assert.ok(!("selectedOdds" in item.model), `${item.matchId} should not include selected odds`);
  assert.ok(!("fairOdds" in item.model), `${item.matchId} should not include fair odds`);
  assert.ok(!("valueIndex" in item.model), `${item.matchId} should not include odds value index`);
  assert.ok(!("marketWatch" in item.model), `${item.matchId} should not include market watch`);
  assert.ok(item.model.scoreProbability > 0 && item.model.scoreProbability < 1, `${item.matchId} should include score probability`);
  assert.ok(item.model.resultProbability > 0 && item.model.resultProbability < 1, `${item.matchId} should include independent result probability`);
  assert.ok(item.model.drawProbability > 0 && item.model.drawProbability < 1, `${item.matchId} should include draw probability`);
  assert.ok(item.model.strategyContext, `${item.matchId} should include tournament strategy context`);
  assert.ok(item.model.strategyContext.score >= 0 && item.model.strategyContext.score <= 100, `${item.matchId} strategy score should be 0-100`);
  assert.ok(Array.isArray(item.model.strategyContext.flags), `${item.matchId} should include strategy flags`);
  assert.ok(item.model.strategyContext.reason.length > 8, `${item.matchId} should include strategy reason`);
  assert.ok(["must-win", "acceptable-draw", "rotation-conserve", "neutral"].includes(item.model.strategyContext.qualificationNeed), `${item.matchId} should include qualification need`);
  assert.ok(item.model.strategyContext.drawUtility >= 0 && item.model.strategyContext.drawUtility <= 1, `${item.matchId} should include draw utility`);
  assert.ok(item.model.groupSituationContext?.status, `${item.matchId} should include group standings situation context`);
  assert.ok(["not-started", "live", "unavailable"].includes(item.model.groupSituationContext.status), `${item.matchId} group situation status should be explicit`);
  assert.ok(["none", "low", "medium", "high"].includes(item.model.groupSituationContext.mustWinLevel), `${item.matchId} must-win level should be explicit`);
  assert.ok(typeof item.model.groupSituationContext.goalDifferenceNeed === "number", `${item.matchId} should include goal difference need`);
  assert.ok(item.model.groupSituationContext.home && item.model.groupSituationContext.away, `${item.matchId} should include both teams' group standing rows`);
  assert.ok(item.model.matchContextScore >= 0 && item.model.matchContextScore <= 100, `${item.matchId} should include overall analyst context score`);
  assert.ok(item.model.lineupContext?.status, `${item.matchId} should include lineup context`);
  assert.ok(item.model.lineupContext.score >= 0 && item.model.lineupContext.score <= 100, `${item.matchId} lineup context score should be 0-100`);
  assert.ok(item.model.lineupContext.sourceCount >= 0, `${item.matchId} lineup context should include source count`);
  assert.ok(item.model.lineupContext.confidence >= 0 && item.model.lineupContext.confidence <= 100, `${item.matchId} lineup confidence should be 0-100`);
  assert.equal(typeof item.model.lineupContext.conflict, "boolean", `${item.matchId} lineup context should flag conflicts`);
  assert.ok(item.model.lineupContext.home && item.model.lineupContext.away, `${item.matchId} lineup context should include both teams`);
  assert.ok(item.model.lineupNewsContext?.home && item.model.lineupNewsContext?.away, `${item.matchId} should include team-level lineup news context`);
  assert.ok(Array.isArray(item.model.lineupNewsContext.home.sourceHits), `${item.matchId} home lineup news should include source hits`);
  assert.ok(Array.isArray(item.model.lineupNewsContext.away.sourceHits), `${item.matchId} away lineup news should include source hits`);
  assert.ok(item.model.lineupNewsContext.sourceCount >= 0, `${item.matchId} lineup news context should include source count`);
  assert.ok(item.model.newsSemanticContext?.home && item.model.newsSemanticContext?.away, `${item.matchId} should include news semantic context`);
  assert.ok(Array.isArray(item.model.newsSemanticContext.tags), `${item.matchId} news semantic context should include merged tags`);
  assert.ok(typeof item.model.newsSemanticContext.scoreImpact === "number", `${item.matchId} news semantic context should include score impact`);
  assert.ok(typeof item.model.newsSemanticContext.goalBias === "number", `${item.matchId} news semantic context should include goal bias`);
  assert.ok(item.model.newsSemanticContext.confidence >= 0 && item.model.newsSemanticContext.confidence <= 100, `${item.matchId} news semantic confidence should be 0-100`);
  assert.ok(Array.isArray(item.model.newsSemanticContext.evidence), `${item.matchId} news semantic context should include evidence`);
  assert.ok(typeof item.model.newsSemanticContext.conflict === "boolean", `${item.matchId} news semantic context should include conflict flag`);
  assert.ok(typeof item.model.newsSemanticContext.trustedImpact === "number", `${item.matchId} news semantic context should include trusted impact`);
  assert.ok(typeof item.model.newsSemanticContext.trustedGoalBias === "number", `${item.matchId} news semantic context should include trusted goal bias`);
  assert.ok(item.model.newsSemanticContext.sourceTierSummary && typeof item.model.newsSemanticContext.sourceTierSummary === "object", `${item.matchId} news semantic context should include source tier summary`);
  assert.ok(
    Math.abs(Number(item.model.newsSemanticContext.trustedImpact || 0)) <= Math.abs(Number(item.model.newsSemanticContext.scoreImpact || 0)) || Number(item.model.newsSemanticContext.scoreImpact || 0) === 0,
    `${item.matchId} trusted semantic impact should not exceed raw impact`
  );
  assert.ok(item.model.rankingContext?.home && item.model.rankingContext?.away, `${item.matchId} should include official ranking context`);
  assert.ok(typeof item.model.rankingContext.rankGap === "number", `${item.matchId} should include official ranking gap`);
  assert.ok(item.model.formContext?.home && item.model.formContext?.away, `${item.matchId} should include opponent-adjusted form context`);
  assert.ok(typeof item.model.formContext.home.adjustedGoalDiff === "number", `${item.matchId} home form should include adjusted goal difference`);
  assert.ok(typeof item.model.formContext.away.adjustedGoalDiff === "number", `${item.matchId} away form should include adjusted goal difference`);
  assert.ok(typeof item.model.formContext.home.weightedGoalDiff === "number", `${item.matchId} home form should include weighted goal difference`);
  assert.ok(typeof item.model.formContext.away.weightedGoalDiff === "number", `${item.matchId} away form should include weighted goal difference`);
  assert.ok(typeof item.model.formContext.home.competitiveShare === "number", `${item.matchId} home form should include competitive share`);
  assert.ok(typeof item.model.formContext.away.competitiveShare === "number", `${item.matchId} away form should include competitive share`);
  assert.ok(Array.isArray(item.model.formContext.home.recentMatches), `${item.matchId} home form should include recent match samples`);
  assert.ok(Array.isArray(item.model.formContext.away.recentMatches), `${item.matchId} away form should include recent match samples`);
  assert.ok(item.model.formContext.weightedConfidence >= 0 && item.model.formContext.weightedConfidence <= 100, `${item.matchId} form should include weighted confidence`);
  assert.ok(item.model.tacticalContext?.scenario, `${item.matchId} should include tactical matchup context`);
  assert.ok(Array.isArray(item.model.tacticalContext.triggers), `${item.matchId} tactical context should include triggers`);
  assert.ok(item.model.scheduleContext?.home && item.model.scheduleContext?.away, `${item.matchId} should include schedule density context`);
  assert.ok(["first-match", "normal-rest", "short-rest", "unknown"].includes(item.model.scheduleContext.home.status), `${item.matchId} home schedule status should be explicit`);
  assert.ok(["first-match", "normal-rest", "short-rest", "unknown"].includes(item.model.scheduleContext.away.status), `${item.matchId} away schedule status should be explicit`);
  assert.ok(item.model.venueContext?.city, `${item.matchId} should include venue city`);
  assert.ok(item.model.venueContext?.country, `${item.matchId} should include venue country`);
  assert.ok(item.model.venueContext.environmentScore >= 0 && item.model.venueContext.environmentScore <= 100, `${item.matchId} venue environment score should be 0-100`);
  assert.ok(["none", "home", "away", "regional"].includes(item.model.venueContext.hostAdvantage), `${item.matchId} host advantage should be explicit`);
  assert.ok(["low", "medium", "high", "unknown"].includes(item.model.venueContext.travelLoad), `${item.matchId} travel load should be explicit`);
  assert.ok(["low", "medium", "high", "unknown"].includes(item.model.venueContext.climateRisk), `${item.matchId} climate risk should be explicit`);
  assert.ok(["low", "medium", "high", "unknown"].includes(item.model.venueContext.timezoneLoad), `${item.matchId} timezone load should be explicit`);
  assert.ok(item.model.venueContext.weather, `${item.matchId} should include venue weather forecast context`);
  assert.ok(["ok", "forecast", "fallback", "unavailable"].includes(item.model.venueContext.weather.status), `${item.matchId} weather status should be explicit`);
  assert.ok(typeof item.model.venueContext.weather.temperatureC === "number", `${item.matchId} weather should include temperature`);
  assert.ok(typeof item.model.venueContext.weather.precipitationMm === "number", `${item.matchId} weather should include precipitation`);
  assert.ok(typeof item.model.venueContext.weather.windKph === "number", `${item.matchId} weather should include wind speed`);
  assert.ok(["low", "medium", "high", "unknown"].includes(item.model.venueContext.weather.weatherRisk), `${item.matchId} weather risk should be explicit`);
  assert.ok(item.model.marketCheck?.status, `${item.matchId} should include market check status`);
  assert.ok(["aligned", "caution", "divergent", "unavailable"].includes(item.model.marketCheck.status), `${item.matchId} market check should be a non-leading validation status`);
  assert.ok(item.model.oddsMovementContext?.status, `${item.matchId} should include odds movement context`);
  assert.ok(typeof item.model.oddsMovementContext.snapshotCount === "number", `${item.matchId} odds movement should include snapshot count`);
  assert.ok(item.model.oddsMovementContext.opening, `${item.matchId} odds movement should include opening snapshot odds`);
  assert.ok(item.model.oddsMovementContext.previous, `${item.matchId} odds movement should include previous snapshot odds`);
  assert.ok(item.model.marketAnomaly?.level, `${item.matchId} should include market anomaly diagnosis`);
  assert.ok(["none", "low", "medium", "high"].includes(item.model.marketAnomaly.level), `${item.matchId} market anomaly level should be explicit`);
  assert.ok(Array.isArray(item.model.marketAnomaly.flags), `${item.matchId} market anomaly should include flags`);
  assert.equal(typeof item.model.marketAnomaly.penalty, "number", `${item.matchId} market anomaly should include score penalty`);
  assert.ok(item.model.marketAnomaly.reason, `${item.matchId} market anomaly should include reason`);
  assert.ok(item.model.analystSubjective?.stance, `${item.matchId} should include subjective analyst stance`);
  assert.ok(
    ["顺势但降权", "反市场保护", "诱盘疑点", "纯模型判断"].includes(item.model.analystSubjective.stance),
    `${item.matchId} subjective analyst stance should be explicit`
  );
  assert.ok(item.model.analystSubjective.reason?.length >= 12, `${item.matchId} subjective analyst stance should include reasoning`);
  assert.equal(typeof item.model.analystSubjective.capitalNoiseRisk, "number", `${item.matchId} subjective stance should score public-data noise risk`);
  assert.ok(item.model.analystSubjective.capitalNoiseRisk >= 0 && item.model.analystSubjective.capitalNoiseRisk <= 100, `${item.matchId} public-data noise risk should be 0-100`);
  if (item.model.marketCheck.status === "divergent") {
    assert.notEqual(item.model.analystSubjective.stance, "顺势但降权", `${item.matchId} divergent market should not be blindly followed`);
  }
  assert.ok(item.model.scoreRationale?.main && item.model.scoreRationale?.upset, `${item.matchId} should include score rationale for main and upset picks`);
  assert.ok(item.model.scoreRationale?.backup, `${item.matchId} should include backup score rationale separately`);
  assert.ok(item.model.expertScenario, `${item.matchId} should include expert scenario`);
  assert.ok(item.model.expertReason.length >= 20, `${item.matchId} should include expert football reasoning`);
  assert.ok(
    !/博冷(?:保留|防)[^。；]*(?:三球|四球|零封|打穿|大胜)/.test(item.model.expertReason),
    `${item.matchId} expert reason should not describe same-direction big-score backup routes as true upset`
  );
  assert.ok(
    /压制|低位|反击|定位球|控场|身体|转换|谨慎|抢分|轮换|保留|强弱|节奏|防守|进攻/.test(item.model.expertReason),
    `${item.matchId} expert reason should describe football match context`
  );
  assert.ok(["稳定", "均衡", "防冷", "回避"].includes(item.model.recommendationType), `${item.matchId} should include recommendation type`);
  assert.ok(Array.isArray(item.model.dualScores) && item.model.dualScores.length === 2, `${item.matchId} should include two score picks`);
  assert.deepEqual(item.model.dualScores.map(row => row.role), ["主推", "备用"], `${item.matchId} should include main and backup score picks`);
  assert.equal(item.model.dualScores[0].score, item.model.score, `${item.matchId} main score should match expert main pick`);
  const topCandidate = item.model.scoreCandidates?.[0];
  const mainCandidate = item.model.scoreCandidates?.find(row => row.score === item.model.score);
  assert.ok(mainCandidate, `${item.matchId} main score should stay inside the top five score distribution candidates`);
  assert.ok(
    Number(topCandidate.probability || 0) - Number(mainCandidate.probability || 0) <= 0.025,
    `${item.matchId} main score should not trail the top score candidate by more than 2.5 percentage points`
  );
  assert.ok(item.model.upsetScore?.score, `${item.matchId} should include a separate true upset score`);
  assert.equal(item.model.upsetScore.role, "博冷", `${item.matchId} true upset score should be labelled separately`);
  assert.notEqual(
    item.model.upsetScore.score,
    item.model.dualScores[1]?.score,
    `${item.matchId} true upset score should add information instead of duplicating the backup score`
  );
  if (item.model.expertReason.includes("概率分布校准")) {
    assert.ok(
      item.model.expertReason.includes(`校准后主推${item.model.score}`),
      `${item.matchId} calibrated expert reason should restate the final main score`
    );
  }
  const [mainHome, mainAway] = item.model.score.split("-").map(Number);
  const [upsetHome, upsetAway] = item.model.upsetScore.score.split("-").map(Number);
  assert.ok(
    upsetHome + upsetAway <= 3,
    `${item.matchId} true upset score should stay in low-score draw, underdog small-win, or narrow underdog-loss territory`
  );
  const mainResult = mainHome > mainAway ? "home" : mainHome < mainAway ? "away" : "draw";
  const upsetResult = upsetHome > upsetAway ? "home" : upsetHome < upsetAway ? "away" : "draw";
  const weakerScored = mainResult === "home" ? upsetAway > 0 : mainResult === "away" ? upsetHome > 0 : true;
  const isUnderdogResult = mainResult !== "draw" && upsetResult !== mainResult;
  const isNarrowUnderdogLoss = mainResult === "home" ? (upsetHome > upsetAway && upsetAway > 0 && upsetHome - upsetAway <= 1) : mainResult === "away" ? (upsetAway > upsetHome && upsetHome > 0 && upsetAway - upsetHome <= 1) : false;
  assert.ok(
    upsetResult === "draw" || isUnderdogResult || weakerScored || isNarrowUnderdogLoss,
    `${item.matchId} true upset score should be draw, underdog result, narrow underdog-loss, or weaker-team scoring`
  );
  assert.ok(item.model.dualScoreCoverage > item.model.scoreProbability, `${item.matchId} dual coverage should be higher than single score probability`);
  assert.ok(item.model.betScore >= 0 && item.model.betScore <= 100, `${item.matchId} should include bet score`);
  assert.ok(["可跟踪", "观察", "回避"].includes(item.model.betAction), `${item.matchId} should include bet action`);
  assert.ok(item.model.analysisQualityScore >= 0 && item.model.analysisQualityScore <= 100, `${item.matchId} should include analysis quality score`);
  assert.ok(item.model.teamNews?.home && item.model.teamNews?.away, `${item.matchId} should include team news for both teams`);
  assert.ok(["confirmed", "reported-clear", "reported-issues", "unknown"].includes(item.model.teamNews.home.injuryStatus), `${item.matchId} should include home injury status`);
  assert.ok(["confirmed", "reported-clear", "reported-issues", "unknown"].includes(item.model.teamNews.away.injuryStatus), `${item.matchId} should include away injury status`);
  assert.ok(["confirmed", "projected-confirmed", "projected", "unconfirmed"].includes(item.model.lineupStatus), `${item.matchId} should include lineup status`);
  assert.ok(Array.isArray(item.model.riskFlags), `${item.matchId} should include risk flags`);
}

assert.ok(Array.isArray(data.scoreCombos), "scoreCombos should be an array");
if (comboEligibleRows.length < 4) {
  assert.equal(data.scoreCombos.length, 0, "score combo should not be generated when fewer than four trackable non-divergent matches exist");
} else {
  assert.ok(data.scoreCombos.length >= 1, "expected at least one score combo when four trackable non-divergent matches exist");
}
for (const combo of data.scoreCombos) {
  assert.equal(combo.matches.length, 4, "each combo should contain four matches");
  assert.equal(combo.selectionMode, "independent-reliability");
  assert.ok(combo.diversificationAudit, "combo should include diversification audit");
  assert.ok(combo.diversificationAudit.score >= 0 && combo.diversificationAudit.score <= 100, "combo diversification score should be 0-100");
  assert.ok(Array.isArray(combo.diversificationAudit.scenarios), "combo should list tactical scenarios");
  assert.ok(Array.isArray(combo.diversificationAudit.warnings), "combo should include diversification warnings");
  assert.ok(combo.diversificationAudit.lineupProjectedCount >= 0, "combo should track projected lineups separately");
  assert.ok(combo.diversificationAudit.lineupProjectedConfirmedCount >= 0, "combo should track cross-verified projected lineups separately");
  assert.ok(["可小注跟踪", "只做比分参考", "等首发后再看", "四串一不建议纳入"].includes(combo.analystVerdict), "combo should include final analyst verdict");
  if (combo.analystVerdict !== "可小注跟踪") {
    assert.notEqual(combo.comboAction, "可跟踪", "combo action should not overstate a cautious analyst verdict");
  }
  assert.ok(!("comboMarketRisk" in combo), "combo should not include market risk score");
  assert.ok(!("comboValueIndex" in combo), "combo should not include odds value index");
  assert.equal(combo.format, "4x2-score");
  assert.equal(combo.coverageCombos.length, 16, "four matches with two scores each should create 16 tickets");
  assert.ok(combo.dualScoreCoverage > 0 && combo.dualScoreCoverage < 1, "combo should include theoretical dual score coverage");
  assert.equal(combo.stakeUnits, 16, "combo should include 16 stake units");
  combo.matches.forEach(item => {
    assert.ok(item.matchId, "combo match should include betting match id");
    assert.match(item.score, /^\d-\d$/, "combo match should include model score");
    assert.ok(item.modelReason, "combo match should include model reason");
    assert.ok(["可跟踪", "观察", "回避"].includes(item.betAction), "combo match should include bet action");
    assert.ok(item.analysisQualityScore >= 0 && item.analysisQualityScore <= 100, "combo match should include analysis quality");
    assert.ok(item.matchContextScore >= 0 && item.matchContextScore <= 100, "combo match should include analyst context score");
    assert.ok(item.tacticalScenario, "combo match should include tactical scenario");
    assert.ok(item.marketCheckStatus, "combo match should include market check status");
    assert.ok(["可小注跟踪", "只做比分参考", "等首发后再看", "四串一不建议纳入", "大比分只做博冷防线"].includes(item.analystVerdict), "combo match should include analyst verdict");
    if (item.analystVerdict !== "可小注跟踪") {
      assert.notEqual(item.betAction, "可跟踪", "combo match action should not overstate analyst verdict");
    }
    assert.ok(item.scoreRationale?.main && item.scoreRationale?.backup && item.scoreRationale?.upset, "combo match should include main/backup/upset rationale");
    assert.ok(Array.isArray(item.dualScores) && item.dualScores.length === 2, "combo match should include two scores");
    assert.deepEqual(item.dualScores.map(row => row.role), ["主推", "备用"], "combo match dual scores should remain main and backup");
    assert.ok(item.upsetScore?.score, "combo match should include separate true upset score");
    assert.equal(item.upsetScore.role, "博冷", "combo match true upset score should be labelled as upset");
    assert.ok(item.dualScoreCoverage > 0, "combo match should include dual score coverage");
    assert.ok(!("marketWatch" in item), "combo match should not include market watch");
  });
  if (combo.coverageCombos?.length) {
    assert.ok(
      combo.coverageCombos.every(row => row.matches.every(match => match.upsetScore)),
      "combo coverage score rows should carry true upset score next to every score pick"
    );
  }
}

console.log("worldcup model v9 independent shape ok");
