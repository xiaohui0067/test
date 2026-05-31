# Lottery Games Design

## Goal

Add a game module to the local lottery dashboard for Macau and Hong Kong sources. The module tracks two recommendation games after each scheduled data collection: three-hit-three on the first six draw numbers, and special-number hit on the seventh draw number.

## Scope

The dashboard keeps the current overview and daily report modules, and adds a focused game module. The game module supports source switching between Macau and Hong Kong. Each source has independent recommendation records, target issue/date calculation, settlement, miss statistics, and history.

## Game Rules

Game 1 is three-hit-three. Each recommendation contains three unique numbers from 01 to 49. A recommendation is settled against the target draw when that issue is available. It hits only when all three recommended numbers appear in the first six regular numbers.

Game 2 is special number. Each recommendation contains one number from 01 to 49. A recommendation is settled against the target draw when that issue is available. It hits only when the recommended number equals the seventh special number.

For both games, the system records source, target year, display year, issue, target date, algorithm id/name, numbers, creation time, settled draw details, hit status, current miss, and historical max miss. Pending recommendations remain pending until the matching draw is parsed.

## Algorithms

Each source and game generates twelve rows per target issue: eleven algorithm-specific recommendations and one ensemble recommendation.

The eleven algorithm families are:

- greedy
- backtracking
- dynamic programming
- simulated annealing
- genetic algorithm
- particle swarm
- Monte Carlo
- ant colony
- Markov chain
- Bayesian inference
- association rules

These are implemented as deterministic, explainable heuristic/statistical models over local historical records. The ensemble recommendation aggregates the eleven algorithm outputs using voting and recent historical performance weights.

## Data Flow

The existing 21:45 scheduled fetch remains the trigger. After pages are fetched and records are parsed, build-data generates game recommendations. It first loads existing game records, settles pending records against newly parsed draws, then creates recommendations for each source's next target issue if they do not already exist.

Macau target dates are calculated as latest draw date plus one day. Hong Kong target dates use the existing historical interval approach so non-daily opening is respected.

Game records are saved in `data/game-predictions.json`. The dashboard embeds the game payload alongside records and summary data so it can open directly as a local file.

## UI

`dashboard.html` has three tabs: overview, games, and daily report. The games tab has a source selector and two sections:

- Three-hit-three: ensemble recommendation, algorithm recommendation table, and history with hit/miss/miss metrics.
- Special number: ensemble recommendation, algorithm recommendation table, and history with hit/miss/miss metrics.

The interface uses dense tables and compact number chips consistent with the existing dashboard style.

## Testing

`test-build-data.ps1` will verify:

- dashboard emits overview, games, and daily tabs only
- game-predictions.json is created
- both games are generated for Macau and Hong Kong
- each game/source/target issue has eleven algorithms plus one ensemble row
- three-hit-three settlement uses only the first six numbers and requires all three numbers
- special-number settlement uses only the seventh number
- pending records stay pending when the target draw is absent
- Hong Kong next target date is not generated as latest date plus one day

