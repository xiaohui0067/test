# Betting Recommendation Snapshot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add immutable betting recommendation snapshots, independent settlement, and strict risk gates for the home recommendation tab.

**Architecture:** Keep the implementation inside `build-data.ps1` because the current app is generated as a static `index.html` with embedded JavaScript. Add focused test assertions in `test-dashboard-three-window-ui.ps1` so the generated dashboard must expose the snapshot and settlement functions.

**Tech Stack:** PowerShell build script, embedded browser JavaScript, generated static HTML.

---

### Task 1: Add Snapshot Contract Tests

**Files:**
- Modify: `test-dashboard-three-window-ui.ps1`

- [ ] **Step 1: Write failing assertions**

Add assertions requiring:

- `function bettingRecommendationSnapshot`
- `function settleBettingSnapshot`
- Snapshot review using `snapshot.pool`
- Three-hit-three settlement requiring `matched.length >= 3`
- UI labels for snapshot result and current-pool hindsight separation

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File .\test-dashboard-three-window-ui.ps1`

Expected: FAIL because snapshot functions do not exist yet.

### Task 2: Implement Snapshot And Settlement

**Files:**
- Modify: `build-data.ps1`

- [ ] **Step 1: Add helpers**

Implement:

- `bettingTargetIssue(latest)`
- `bettingRecommendationSnapshot(...)`
- `settleBettingSnapshot(snapshot, rows)`
- `bettingSnapshotReviewGroups(rows, item, limit)`

- [ ] **Step 2: Use snapshots in analysis**

Update `bettingRecommendationAnalysis(source)` so each item contains:

- `snapshot`
- `review` based on settled snapshots
- strict level calculated from snapshot review

- [ ] **Step 3: Keep current-pool hindsight separate**

Review rows may include `currentHit`, but the official `hit` field must come from the snapshot pool.

### Task 3: Tighten Risk Gates And UI

**Files:**
- Modify: `build-data.ps1`

- [ ] **Step 1: Add strict risk gate function**

Implement a hard-gated recommendation level. Pause must override score when snapshot review is weak, sample is insufficient, or miss risk is too high.

- [ ] **Step 2: Simplify recommendation card copy**

Show:

- score
- level
- snapshot pool
- short reason list
- latest issue target

- [ ] **Step 3: Rename review columns**

Use explicit columns:

- `推荐快照结果`
- `当前池回看`

### Task 4: Build And Verify

**Files:**
- Generated: `index.html`

- [ ] **Step 1: Run targeted test**

Run: `powershell -ExecutionPolicy Bypass -File .\test-dashboard-three-window-ui.ps1`

Expected: PASS.

- [ ] **Step 2: Rebuild dashboard**

Run: `powershell -ExecutionPolicy Bypass -File .\build-data.ps1`

Expected: completed without error.

- [ ] **Step 3: Run build regression test**

Run: `powershell -ExecutionPolicy Bypass -File .\test-build-data.ps1`

Expected: PASS.

### Task 5: Commit And Push

**Files:**
- Commit only intentional source, test, docs, and generated HTML changes.

- [ ] **Step 1: Inspect diff**

Run: `git status --short` and `git diff --stat`.

- [ ] **Step 2: Commit**

Run: `git add ...` then `git commit -m "feat: add betting recommendation snapshots"`.

- [ ] **Step 3: Push**

Run: `git push`.
