# Findings

## Current State

- Branch `main` is clean at `3b131ff chore: remove unused cron fetch endpoint`.
- Data files are compacted; largest files are `records.json/js` 2.36 MB each. `page-parse-cache.json` is now a small index, with page records split under `data/page-parse-cache/`.
- Dashboard now loads heavy data by tab instead of loading all full data at once.

## Candidate Optimizations

- Build profile sometimes shows `parse-pages` around 50-63 seconds after conflict/cache churn, but normal cache-hit builds were around a few seconds earlier. Need evidence before changing parser/cache.
- `api/cron-fetch.js` exists but Vercel deployment did not include it; cron has been routed through `manual-fetch.js` as a workaround. This is operational, not a code optimization target for now.

## Build Cache Evidence

- Reading `data/page-parse-cache.json` as raw text took about 0.08s.
- Converting that 2.5 MB JSON with PowerShell `ConvertFrom-Json` timed out after 60s.
- Listing 26 page HTML files took about 0.05s.
- Root cause for slow `parse-pages` is large-object `ConvertFrom-Json`, not file IO or regex parsing alone.
- Candidate fix: split page parse cache into a small index plus one compact records JSON file per page.
- After implementing split cache, second cache-hit build measured `parse-pages` at about 1.5s.
- Added `source|issue` record lookup for game settlement. `game-settle-existing` dropped from about 2.0s to about 0.46s, and `game-predictions` from about 2.16s to about 1.28s.
- Tried single-pass PowerShell summary counters. It increased `summary-counts` from about 2.9s to about 4.0s, likely due to function-call and nested hashtable overhead, so it was reverted.
- Removed obsolete `api/cron-fetch.js`; Vercel Cron is intentionally routed through `api/manual-fetch.js?cron=1` because that function is known to deploy.
- Current cache-hit build profile is around 7-8s. Largest remaining item is `summary-counts` around 2.7s; a tested single-pass rewrite was slower, so no further low-risk summary optimization is recommended in this pass.
