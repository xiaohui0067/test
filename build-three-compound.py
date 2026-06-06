import json
import random
import sys
from itertools import combinations
from pathlib import Path


NUMS_ALL = [f"{i:02d}" for i in range(1, 50)]


def regular_nums(row):
    return [
        str((ball.get("numberText") or ball.get("number") or "")).zfill(2)
        for ball in (row.get("balls") or [])[:6]
    ]


def display_year(row):
    date = str(row.get("date") or "")
    return date[:4] if len(date) >= 4 else str(row.get("year") or "")


def windows(rows):
    if not rows:
        return []
    max_issue = max(int(row.get("issue") or 0) for row in rows)
    sorted_rows = sorted(rows, key=lambda row: int(row.get("issue") or 0))
    out = []
    for start in range(1, max_issue + 1, 5):
        end = start + 4
        chunk = [row for row in sorted_rows if start <= int(row.get("issue") or 0) <= end]
        if chunk:
            out.append({"start": start, "end": end, "count": len(chunk), "rows": chunk})
    return out


def num_mask(nums):
    mask = 0
    for num in nums:
        value = int(num)
        if 1 <= value <= 49:
            mask |= 1 << (value - 1)
    return mask


def pool_mask(pool):
    return num_mask(pool)


def window_specs(rows):
    specs = []
    for item in windows(rows):
        row_items = []
        for row in item["rows"]:
            nums = regular_nums(row)
            row_items.append({"row": row, "nums": nums, "mask": num_mask(nums)})
        specs.append({
            "start": item["start"],
            "end": item["end"],
            "count": item["count"],
            "rows": row_items,
        })
    return specs


def draw_hit(row, pool):
    return len(set(regular_nums(row)) & set(pool)) >= 3


def coverage(rows, pool):
    return coverage_from_specs(window_specs(rows), pool)


def coverage_from_specs(specs, pool):
    result = []
    mask = pool_mask(pool)
    for item in specs:
        hits = []
        for row in item["rows"]:
            if (row["mask"] & mask).bit_count() < 3:
                continue
            matched = sorted([num for num in row["nums"] if mask & (1 << (int(num) - 1))], key=int)
            if len(matched) >= 3:
                hits.append({"issue": int(row["row"].get("issue") or 0), "date": row["row"].get("date"), "matched": matched})
        result.append({
            "start": item["start"],
            "end": item["end"],
            "count": item["count"],
            "hits": hits,
            "covered": bool(hits),
        })
    return result


def normalized_pool(nums):
    return sorted([str(num).zfill(2) for num in (nums or []) if str(num).strip()], key=int)


def pool_snapshot_for_window(current_pool, history, window_start):
    snapshot = normalized_pool(current_pool)
    changes = sorted(history or [], key=lambda item: int(item.get("issue") or 0), reverse=True)
    for change in changes:
        if int(window_start or 0) <= int(change.get("issue") or 0) and change.get("beforePool"):
            snapshot = normalized_pool(change.get("beforePool") or [])
    return snapshot


def snapshot_windows(rows, current_pool, history):
    specs = window_specs(rows)
    result = []
    for item in specs:
        pool_snapshot = pool_snapshot_for_window(current_pool, history, item["start"])
        wins = coverage_from_specs([item], pool_snapshot)
        if wins:
            wins[0]["poolSnapshot"] = pool_snapshot
            result.append(wins[0])
    return result


def refresh_pool_with_snapshots(pool_item, rows, history_key="changeHistory"):
    history = list(pool_item.get(history_key, []))
    wins = snapshot_windows(rows, pool_item.get("pool", []), history)
    pool_item["windows"] = wins
    pool_item.update(pool_metrics(wins))
    return pool_item


def score_pool(rows, pool):
    return score_pool_from_specs(window_specs(rows), pool)


def score_pool_from_specs(specs, pool):
    mask = pool_mask(pool)
    completed = [item for item in specs if item["count"] >= 5]
    covered = 0
    hit_draws = 0
    recent_flags = []
    for item in completed:
        item_hit_draws = 0
        for row in item["rows"]:
            if (row["mask"] & mask).bit_count() >= 3:
                item_hit_draws += 1
        if item_hit_draws:
            covered += 1
            recent_flags.append(True)
        else:
            recent_flags.append(False)
        hit_draws += item_hit_draws
    recent = sum(idx for idx, covered_item in enumerate(recent_flags[-10:], 1) if covered_item)
    return covered, hit_draws, recent, -sum(int(num) for num in pool)


def frequency_order(rows):
    counts = {num: 0 for num in NUMS_ALL}
    for row in rows:
        for num in regular_nums(row):
            counts[num] += 1
    return sorted(NUMS_ALL, key=lambda num: (-counts[num], int(num)))


def greedy_seed(rows, size, order, specs=None):
    specs = specs or window_specs(rows)
    selected = []
    while len(selected) < size:
        best_num = None
        best_score = None
        for num in order:
            if num in selected:
                continue
            candidate = sorted(selected + [num], key=int)
            score = score_pool_from_specs(specs, candidate)
            if best_score is None or score > best_score:
                best_score = score
                best_num = num
        selected = sorted(selected + [best_num], key=int)
    return selected


def improve(rows, start_pool, specs=None):
    specs = specs or window_specs(rows)
    selected = sorted(start_pool, key=int)
    best_score = score_pool_from_specs(specs, selected)
    improved = True
    rounds = 0
    while improved and rounds < 80:
        improved = False
        rounds += 1
        for out_num in selected[:]:
            outside = [num for num in NUMS_ALL if num not in selected]
            for in_num in outside:
                candidate = sorted([num for num in selected if num != out_num] + [in_num], key=int)
                score = score_pool_from_specs(specs, candidate)
                if score > best_score:
                    selected = candidate
                    best_score = score
                    improved = True
                    break
            if improved:
                break
    return selected, best_score


def best_pool(rows, size):
    specs = window_specs(rows)
    freq = frequency_order(rows)
    seeds = [
        greedy_seed(rows, size, NUMS_ALL, specs),
        greedy_seed(rows, size, freq, specs),
        sorted(freq[:size], key=int),
    ]
    rng = random.Random(20260602 + size + len(rows))
    for _ in range(60):
        seeds.append(sorted(rng.sample(NUMS_ALL, size), key=int))
    best = None
    best_score = None
    for seed_pool in seeds:
        pool, score = improve(rows, seed_pool, specs)
        if best_score is None or score > best_score:
            best = pool
            best_score = score
    wins = coverage_from_specs(specs, best)
    metrics = pool_metrics(wins)
    return {
        "poolSize": size,
        "pool": best,
        "windows": wins,
        **metrics,
        "computedBy": "python-local-search",
    }


def pool_metrics(wins):
    completed = [item for item in wins if item["count"] >= 5]
    total = len(completed)
    covered = sum(1 for item in completed if item["covered"])
    hit_draws = sum(len(item["hits"]) for item in completed)
    hit_rate = round(covered / total * 100, 2) if total else 0
    recent = completed[-10:]
    recent_covered = sum(1 for item in recent if item["covered"])
    recent_hit_rate = round(recent_covered / len(recent) * 100, 2) if recent else 0
    current_miss = 0
    for item in reversed(completed):
        if item["covered"]:
            break
        current_miss += 1
    max_miss = 0
    run = 0
    for item in completed:
        if item["covered"]:
            max_miss = max(max_miss, run)
            run = 0
        else:
            run += 1
    max_miss = max(max_miss, run)
    health_status = "normal-observe"
    health_reason = "compound-window-stable"
    if total >= 2 and current_miss >= 2:
        health_status = "downrank-observe"
        health_reason = "two-completed-window-misses"
    if total >= 3 and max_miss > 0 and current_miss > max_miss:
        health_status = "trigger-recalc"
        health_reason = "current-miss-exceeds-historical-max"
    if recent and recent_hit_rate + 20 < hit_rate:
        health_status = "downrank-observe"
        health_reason = "recent-coverage-below-year"
    return {
        "covered": covered,
        "total": total,
        "hitDraws": hit_draws,
        "hitRate": hit_rate,
        "recentCovered": recent_covered,
        "recentTotal": len(recent),
        "recentHitRate": recent_hit_rate,
        "currentMiss": current_miss,
        "maxMiss": max_miss,
        "healthStatus": health_status,
        "healthReason": health_reason,
    }


def item_better(new_item, old_item):
    if not old_item:
        return True
    return (
        int(new_item.get("covered", 0)),
        int(new_item.get("hitDraws", 0)),
        float(new_item.get("hitRate", 0)),
    ) > (
        int(old_item.get("covered", 0)),
        int(old_item.get("hitDraws", 0)),
        float(old_item.get("hitRate", 0)),
    )


def pool_diff(before_pool, after_pool):
    before = sorted([str(num).zfill(2) for num in before_pool], key=int)
    after = sorted([str(num).zfill(2) for num in after_pool], key=int)
    before_set = set(before)
    after_set = set(after)
    kept = [num for num in after if num in before_set]
    added = [num for num in after if num not in before_set]
    removed = [num for num in before if num not in after_set]
    change_count = len(added) + len(removed)
    if not before:
        change_level = "initial"
    elif change_count <= 2:
        change_level = "stable"
    elif change_count <= 4:
        change_level = "medium-change"
    else:
        change_level = "rebuild"
    return {
        "kept": kept,
        "added": added,
        "removed": removed,
        "changeCount": change_count,
        "changeLevel": change_level,
    }


def cross_year_pool(source_rows, year_rows, size, year_pool=None):
    candidate = best_pool(source_rows, size)
    pool = candidate.get("pool", [])
    history_windows = candidate.get("windows", [])
    history_metrics = pool_metrics(history_windows)
    year_windows = coverage(year_rows, pool)
    year_metrics = pool_metrics(year_windows)
    year_pool = sorted([str(num).zfill(2) for num in (year_pool or [])], key=int)
    pool_set = set(pool)
    year_pool_set = set(year_pool)
    intersection = [num for num in pool if num in year_pool_set]
    cross_year_only = [num for num in pool if num not in year_pool_set]
    year_only = [num for num in year_pool if num not in pool_set]
    return {
        "poolSize": size,
        "scope": "all-history",
        "pool": pool,
        "windows": year_windows,
        **year_metrics,
        "yearWindows": year_windows,
        "yearCovered": year_metrics["covered"],
        "yearTotal": year_metrics["total"],
        "yearHitRate": year_metrics["hitRate"],
        "yearRecentCovered": year_metrics["recentCovered"],
        "yearRecentTotal": year_metrics["recentTotal"],
        "yearRecentHitRate": year_metrics["recentHitRate"],
        "yearCurrentMiss": year_metrics["currentMiss"],
        "yearMaxMiss": year_metrics["maxMiss"],
        "historyWindows": history_windows,
        "historyCovered": history_metrics["covered"],
        "historyTotal": history_metrics["total"],
        "historyHitRate": history_metrics["hitRate"],
        "historyRecentCovered": history_metrics["recentCovered"],
        "historyRecentTotal": history_metrics["recentTotal"],
        "historyRecentHitRate": history_metrics["recentHitRate"],
        "historyCurrentMiss": history_metrics["currentMiss"],
        "historyMaxMiss": history_metrics["maxMiss"],
        "historyHitDraws": history_metrics["hitDraws"],
        "intersection": intersection,
        "intersectionCount": len(intersection),
        "crossYearOnly": cross_year_only,
        "yearOnly": year_only,
        "computedBy": candidate.get("computedBy", "python-local-search"),
    }


def has_complete_pools(item):
    pools = item.get("pools") or []
    cross_year_pools = item.get("crossYearPools") or []
    pool_sizes = sorted(int(pool.get("poolSize") or 0) for pool in pools)
    cross_year_sizes = sorted(int(pool.get("poolSize") or 0) for pool in cross_year_pools)
    all_pools = list(pools) + list(cross_year_pools)
    has_snapshots = all(
        any(win.get("poolSnapshot") for win in (pool.get("windows") or pool.get("yearWindows") or []))
        for pool in all_pools
    )
    return pool_sizes == [5, 6, 7, 8] and cross_year_sizes == [5, 6, 7, 8] and has_snapshots


def cached_item(old_item, generated_at):
    item = json.loads(json.dumps(old_item))
    item["computedAt"] = generated_at
    item["status"] = "cached"
    for pool in item.get("pools") or []:
        pool["status"] = "cached"
    for pool in item.get("crossYearPools") or []:
        pool["status"] = "cached"
    return item


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
    records_path = root / "data" / "records.json"
    state_path = root / "data" / "three-compound-state.json"
    generated_at = sys.argv[2] if len(sys.argv) > 2 else ""
    payload = json.loads(records_path.read_text(encoding="utf-8"))
    records = payload.get("records", [])
    previous = {}
    if state_path.exists():
        try:
            old_payload = json.loads(state_path.read_text(encoding="utf-8"))
            previous = {(item.get("source"), str(item.get("year"))): item for item in old_payload.get("items", [])}
        except Exception:
            previous = {}
    items = []
    for source in ("am", "hk"):
        source_rows = [row for row in records if row.get("source") == source and row.get("date")]
        if not source_rows:
            continue
        latest = max(source_rows, key=lambda row: (str(row.get("date") or ""), int(row.get("issue") or 0)))
        year = display_year(latest)
        year_rows = sorted([row for row in source_rows if display_year(row) == year], key=lambda row: int(row.get("issue") or 0))
        old_item = previous.get((source, year), {})
        latest_issue = int(latest.get("issue") or 0)
        if (
            old_item
            and int(old_item.get("latestIssue") or 0) == latest_issue
            and has_complete_pools(old_item)
        ):
            items.append(cached_item(old_item, generated_at))
            continue
        old_pools = {int(item.get("poolSize")): item for item in old_item.get("pools", []) if item.get("poolSize")}
        old_cross_year_pools = {int(item.get("poolSize")): item for item in old_item.get("crossYearPools", []) if item.get("poolSize")}
        pools = []
        cross_year_pools = []
        changed = False
        cross_year_changed = False
        for size in (5, 6, 7, 8):
            candidate = best_pool(year_rows, size)
            old_pool = old_pools.get(size)
            if item_better(candidate, old_pool):
                before_pool = old_pool.get("pool", []) if old_pool else []
                before_covered = old_pool.get("covered") if old_pool else None
                before_hit_rate = old_pool.get("hitRate") if old_pool else None
                diff = pool_diff(before_pool, candidate["pool"])
                old_history = list((old_pool or {}).get("changeHistory", []))
                candidate["status"] = "changed" if old_pool else "initial"
                candidate["changeTime"] = generated_at
                candidate["changeHistory"] = [{
                    "changedAt": generated_at,
                    "issue": int(latest.get("issue") or 0),
                    "beforePool": before_pool,
                    "afterPool": candidate["pool"],
                    "beforeCovered": before_covered,
                    "afterCovered": candidate["covered"],
                    "beforeHitRate": before_hit_rate,
                    "afterHitRate": candidate["hitRate"],
                    **diff,
                    "reason": "better-completed-window-coverage-pool" if old_pool else "initial-three-compound-pool",
                }] + old_history[:29]
                candidate = refresh_pool_with_snapshots(candidate, year_rows)
                changed = True
                pools.append(candidate)
            else:
                old_pool["status"] = "no-change"
                refresh_pool_with_snapshots(old_pool, year_rows)
                old_pool["changeHistory"] = list(old_pool.get("changeHistory", []))
                pools.append(old_pool)
        year_pools_by_size = {int(item.get("poolSize")): item for item in pools if item.get("poolSize")}
        for size in (5, 6, 7, 8):
            year_pool = (year_pools_by_size.get(size) or {}).get("pool", [])
            candidate = cross_year_pool(source_rows, year_rows, size, year_pool)
            old_pool = old_cross_year_pools.get(size)
            if item_better(
                {
                    "covered": candidate["historyCovered"],
                    "hitDraws": candidate["historyHitDraws"],
                    "hitRate": candidate["historyHitRate"],
                },
                {
                    "covered": old_pool.get("historyCovered") if old_pool else None,
                    "hitDraws": old_pool.get("historyHitDraws") if old_pool else None,
                    "hitRate": old_pool.get("historyHitRate") if old_pool else None,
                } if old_pool else None,
            ):
                before_pool = old_pool.get("pool", []) if old_pool else []
                before_covered = old_pool.get("historyCovered") if old_pool else None
                before_hit_rate = old_pool.get("historyHitRate") if old_pool else None
                diff = pool_diff(before_pool, candidate["pool"])
                old_history = list((old_pool or {}).get("changeHistory", []))
                candidate["status"] = "changed" if old_pool else "initial"
                candidate["changeTime"] = generated_at
                candidate["changeHistory"] = [{
                    "changedAt": generated_at,
                    "issue": int(latest.get("issue") or 0),
                    "beforePool": before_pool,
                    "afterPool": candidate["pool"],
                    "beforeCovered": before_covered,
                    "afterCovered": candidate["historyCovered"],
                    "beforeHitRate": before_hit_rate,
                    "afterHitRate": candidate["historyHitRate"],
                    **diff,
                    "reason": "better-all-history-compound-pool" if old_pool else "initial-cross-year-compound-pool",
                }] + old_history[:29]
                history_windows = snapshot_windows(source_rows, candidate.get("pool", []), candidate.get("changeHistory", []))
                history_metrics = pool_metrics(history_windows)
                year_windows = snapshot_windows(year_rows, candidate.get("pool", []), candidate.get("changeHistory", []))
                year_metrics = pool_metrics(year_windows)
                candidate.update(year_metrics)
                candidate["windows"] = year_windows
                candidate["yearWindows"] = year_windows
                candidate["yearCovered"] = year_metrics["covered"]
                candidate["yearTotal"] = year_metrics["total"]
                candidate["yearHitRate"] = year_metrics["hitRate"]
                candidate["yearRecentCovered"] = year_metrics["recentCovered"]
                candidate["yearRecentTotal"] = year_metrics["recentTotal"]
                candidate["yearRecentHitRate"] = year_metrics["recentHitRate"]
                candidate["yearCurrentMiss"] = year_metrics["currentMiss"]
                candidate["yearMaxMiss"] = year_metrics["maxMiss"]
                candidate["historyWindows"] = history_windows
                candidate["historyCovered"] = history_metrics["covered"]
                candidate["historyTotal"] = history_metrics["total"]
                candidate["historyHitRate"] = history_metrics["hitRate"]
                candidate["historyRecentCovered"] = history_metrics["recentCovered"]
                candidate["historyRecentTotal"] = history_metrics["recentTotal"]
                candidate["historyRecentHitRate"] = history_metrics["recentHitRate"]
                candidate["historyCurrentMiss"] = history_metrics["currentMiss"]
                candidate["historyMaxMiss"] = history_metrics["maxMiss"]
                candidate["historyHitDraws"] = history_metrics["hitDraws"]
                cross_year_changed = True
                cross_year_pools.append(candidate)
            else:
                old_pool["status"] = "no-change"
                old_pool["scope"] = "all-history"
                pool = old_pool.get("pool", [])
                history_windows = snapshot_windows(source_rows, pool, old_pool.get("changeHistory", []))
                history_metrics = pool_metrics(history_windows)
                year_windows = snapshot_windows(year_rows, pool, old_pool.get("changeHistory", []))
                year_metrics = pool_metrics(year_windows)
                old_pool.update(year_metrics)
                old_pool["windows"] = year_windows
                old_pool["yearWindows"] = year_windows
                old_pool["yearCovered"] = year_metrics["covered"]
                old_pool["yearTotal"] = year_metrics["total"]
                old_pool["yearHitRate"] = year_metrics["hitRate"]
                old_pool["yearRecentCovered"] = year_metrics["recentCovered"]
                old_pool["yearRecentTotal"] = year_metrics["recentTotal"]
                old_pool["yearRecentHitRate"] = year_metrics["recentHitRate"]
                old_pool["yearCurrentMiss"] = year_metrics["currentMiss"]
                old_pool["yearMaxMiss"] = year_metrics["maxMiss"]
                old_pool["historyWindows"] = history_windows
                old_pool["historyCovered"] = history_metrics["covered"]
                old_pool["historyTotal"] = history_metrics["total"]
                old_pool["historyHitRate"] = history_metrics["hitRate"]
                old_pool["historyRecentCovered"] = history_metrics["recentCovered"]
                old_pool["historyRecentTotal"] = history_metrics["recentTotal"]
                old_pool["historyRecentHitRate"] = history_metrics["recentHitRate"]
                old_pool["historyCurrentMiss"] = history_metrics["currentMiss"]
                old_pool["historyMaxMiss"] = history_metrics["maxMiss"]
                old_pool["historyHitDraws"] = history_metrics["hitDraws"]
                year_pool = sorted([str(num).zfill(2) for num in year_pool], key=int)
                pool_set = set(pool)
                year_pool_set = set(year_pool)
                old_pool["intersection"] = [num for num in pool if num in year_pool_set]
                old_pool["intersectionCount"] = len(old_pool["intersection"])
                old_pool["crossYearOnly"] = [num for num in pool if num not in year_pool_set]
                old_pool["yearOnly"] = [num for num in year_pool if num not in pool_set]
                old_pool["changeHistory"] = list(old_pool.get("changeHistory", []))
                cross_year_pools.append(old_pool)
        items.append({
            "source": source,
            "year": year,
            "latestIssue": latest_issue,
            "computedAt": generated_at,
            "status": "changed" if changed or cross_year_changed else "no-change",
            "pools": pools,
            "crossYearPools": cross_year_pools,
        })
    state_path.write_text(json.dumps({"generatedAt": generated_at, "items": items}, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
