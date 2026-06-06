# Project Optimization Plan

Goal: Continue optimizing the lottery dashboard project with verified, low-risk changes until no clear worthwhile optimization remains in this pass.

## Phase 1: Build Pipeline Evidence
Status: complete

- Measure current build profile and identify whether `parse-pages` slowness is real or caused by stale cache metadata.
- Inspect page parse cache invalidation logic.
- Add targeted tests before changing build behavior.

## Phase 2: Implement Highest-Value Optimization
Status: complete

## Phase 2b: Game Prediction Settlement Index
Status: complete

- Prefer changes that reduce build time, page load work, data size, or operational risk.
- Keep each change narrow and independently verified.
- Rebuild generated files after modifying generators.

## Phase 3: Verification And Push
Status: complete

## Phase 4: Remaining Optimization Scan
Status: complete

- Run relevant regression tests.
- Run `build-data.ps1 -Profile`.
- Commit and push each completed optimization.

## Done Criteria

- Working tree clean: complete.
- Latest optimization pushed: complete.
- No obvious high-value, low-risk optimization remains from current evidence: complete.
