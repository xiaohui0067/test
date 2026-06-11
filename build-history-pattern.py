import json
import sys
from pathlib import Path


NUMS_ALL = [f"{i:02d}" for i in range(1, 50)]
POOL_SIZE = 8
EXACT_WINDOW_LIMIT = 45
EXACT_POOL_CACHE = {}
BEST_POOL_CACHE = {}


def display_year(row):
    date = str(row.get("date") or "")
    return date[:4] if len(date) >= 4 else str(row.get("year") or "")


def special_num(row):
    balls = row.get("balls") or []
    if len(balls) < 7:
        return ""
    return str(balls[6].get("numberText") or balls[6].get("number") or "").zfill(2)


def latest_draw_state(row):
    if not row:
        return None
    balls = []
    for ball in row.get("balls") or []:
        balls.append({
            "index": int(ball.get("index") or 0),
            "numberText": str(ball.get("numberText") or ball.get("number") or "").zfill(2),
            "zodiac": str(ball.get("zodiac") or ""),
            "color": str(ball.get("color") or ""),
            "colorName": str(ball.get("colorName") or ""),
        })
    balls = sorted(balls, key=lambda item: item["index"])
    special = balls[6] if len(balls) >= 7 else None
    return {
        "issue": int(row.get("issue") or 0),
        "date": str(row.get("date") or ""),
        "year": display_year(row),
        "balls": balls,
        "regular": balls[:6],
        "special": special,
    }


def fixed_five_windows(rows):
    by_year = {}
    for row in rows:
        year = display_year(row)
        if year:
            by_year.setdefault(year, []).append(row)
    out = []
    for year, year_rows in sorted(by_year.items()):
        sorted_rows = sorted(year_rows, key=lambda row: int(row.get("issue") or 0))
        max_issue = max((int(row.get("issue") or 0) for row in sorted_rows), default=0)
        for start in range(1, max_issue + 1, 5):
            end = start + 4
            chunk = [row for row in sorted_rows if start <= int(row.get("issue") or 0) <= end]
            if len(chunk) < 5:
                continue
            nums = sorted({special_num(row) for row in chunk if special_num(row)}, key=int)
            out.append({"year": year, "start": start, "end": end, "count": len(chunk), "nums": nums})
    return out


def num_window_masks(windows):
    masks = {num: 0 for num in NUMS_ALL}
    for idx, win in enumerate(windows):
        bit = 1 << idx
        for num in win["nums"]:
            if num in masks:
                masks[num] |= bit
    return masks


def exact_best_pool(windows):
    if not windows:
        return NUMS_ALL[:POOL_SIZE], 0

    masks_by_num = num_window_masks(windows)
    candidates = sorted(NUMS_ALL, key=lambda num: (-masks_by_num[num].bit_count(), int(num)))
    masks = [masks_by_num[num] for num in candidates]
    suffix_union = [0] * (len(candidates) + 1)
    for idx in range(len(candidates) - 1, -1, -1):
        suffix_union[idx] = suffix_union[idx + 1] | masks[idx]

    best_count = -1
    best_nums = []

    def coverage_upper_bound(start, covered, slots):
        gains = sorted(((mask & ~covered).bit_count() for mask in masks[start:]), reverse=True)
        return min(len(windows), covered.bit_count() + sum(gains[:slots]))

    def better(nums, count):
        nonlocal best_count, best_nums
        sorted_nums = sorted(nums, key=int)
        if count > best_count:
            return True
        if count == best_count and (not best_nums or [int(n) for n in sorted_nums] < [int(n) for n in best_nums]):
            return True
        return False

    def dfs(start, chosen, covered):
        nonlocal best_count, best_nums
        slots = POOL_SIZE - len(chosen)
        if slots == 0:
            count = covered.bit_count()
            if better(chosen, count):
                best_count = count
                best_nums = sorted(chosen, key=int)
            return
        if len(candidates) - start < slots:
            return
        if (covered | suffix_union[start]).bit_count() < best_count:
            return
        if coverage_upper_bound(start, covered, slots) < best_count:
            return

        best_next = []
        for idx in range(start, len(candidates)):
            gain = (masks[idx] & ~covered).bit_count()
            best_next.append((gain, -int(candidates[idx]), idx))
        best_next.sort(reverse=True)

        used_first = set()
        for _, _, idx in best_next:
            if idx < start or idx in used_first:
                continue
            used_first.add(idx)
            dfs(idx + 1, chosen + [candidates[idx]], covered | masks[idx])
            if (covered | suffix_union[start]).bit_count() <= best_count:
                break

    dfs(0, [], 0)
    if len(best_nums) < POOL_SIZE:
        for num in NUMS_ALL:
            if num not in best_nums:
                best_nums.append(num)
            if len(best_nums) >= POOL_SIZE:
                break
    return best_nums[:POOL_SIZE], max(best_count, 0)


def exact_best_pool_cached(windows):
    key = tuple((win.get("year"), win.get("start"), tuple(win.get("nums") or [])) for win in windows)
    if key not in EXACT_POOL_CACHE:
        EXACT_POOL_CACHE[key] = exact_best_pool(windows)
    return EXACT_POOL_CACHE[key]


def greedy_best_pool(windows):
    if not windows:
        return NUMS_ALL[:POOL_SIZE], 0
    masks_by_num = num_window_masks(windows)
    covered = 0
    chosen = []
    while len(chosen) < POOL_SIZE:
        best_num = None
        best_gain = -1
        best_total = -1
        for num in NUMS_ALL:
            if num in chosen:
                continue
            mask = masks_by_num[num]
            gain = (mask & ~covered).bit_count()
            total = mask.bit_count()
            if gain > best_gain or (gain == best_gain and (total > best_total or (total == best_total and (best_num is None or int(num) < int(best_num))))):
                best_num = num
                best_gain = gain
                best_total = total
        if best_num is None:
            break
        chosen.append(best_num)
        covered |= masks_by_num[best_num]
    return complete_pool(chosen), covered.bit_count()


def best_pool_cached(windows):
    key = tuple((win.get("year"), win.get("start"), tuple(win.get("nums") or [])) for win in windows)
    if key not in BEST_POOL_CACHE:
        if len(windows) <= EXACT_WINDOW_LIMIT:
            BEST_POOL_CACHE[key] = (*exact_best_pool_cached(windows), True)
        else:
            BEST_POOL_CACHE[key] = (*greedy_best_pool(windows), False)
    return BEST_POOL_CACHE[key]


def coverage_stats(windows, pool):
    pool_set = set(pool)
    evaluated = []
    for win in windows:
        covered = any(num in pool_set for num in win["nums"])
        evaluated.append({**win, "covered": covered})
    covered_count = sum(1 for win in evaluated if win["covered"])
    misses = [win for win in evaluated if not win["covered"]]
    max_miss = 0
    current_miss = 0
    run = 0
    for win in evaluated:
        if win["covered"]:
            max_miss = max(max_miss, run)
            run = 0
        else:
            run += 1
    max_miss = max(max_miss, run)
    for win in reversed(evaluated):
        if win["covered"]:
            break
        current_miss += 1
    total = len(evaluated)
    hit_rate = round(covered_count / total * 100, 2) if total else 0
    return {
        "windows": evaluated,
        "covered": covered_count,
        "misses": misses,
        "total": total,
        "hitRate": hit_rate,
        "currentMiss": current_miss,
        "maxMiss": max_miss,
    }


def complete_pool(pool):
    out = list(pool)
    for num in NUMS_ALL:
        if num not in out:
            out.append(num)
        if len(out) >= POOL_SIZE:
            break
    return out[:POOL_SIZE]


def rolling_window_stats(windows):
    evaluated = []
    pool_cache = {}
    for idx, win in enumerate(windows):
        if idx not in pool_cache:
            pool_cache[idx] = best_pool_cached(windows[:idx])[0]
        pool = pool_cache[idx]
        pool = complete_pool(pool)
        pool_set = set(pool)
        hits = [num for num in win["nums"] if num in pool_set]
        evaluated.append({
            **win,
            "pool": pool,
            "poolBasis": "before-window",
            "covered": len(hits) > 0,
            "hits": hits,
        })
    covered_count = sum(1 for win in evaluated if win["covered"])
    misses = [win for win in evaluated if not win["covered"]]
    max_miss = 0
    current_miss = 0
    run = 0
    for win in evaluated:
        if win["covered"]:
            max_miss = max(max_miss, run)
            run = 0
        else:
            run += 1
    max_miss = max(max_miss, run)
    for win in reversed(evaluated):
        if win["covered"]:
            break
        current_miss += 1
    total = len(evaluated)
    hit_rate = round(covered_count / total * 100, 2) if total else 0
    return {
        "windows": evaluated,
        "covered": covered_count,
        "misses": misses,
        "total": total,
        "hitRate": hit_rate,
        "currentMiss": current_miss,
        "maxMiss": max_miss,
    }


def current_window_state(source_rows, current_year, scoped_rows, range_name, post_window_pool):
    year_rows = [row for row in source_rows if display_year(row) == current_year]
    if not year_rows:
        return {
            "year": current_year,
            "start": 0,
            "end": 0,
            "count": 0,
            "expected": 5,
            "covered": False,
            "pool": NUMS_ALL[:POOL_SIZE],
            "poolBasis": "before-current-window",
            "displayMode": "active-window",
            "reviewWindow": None,
            "postWindowOptimal": {
                "pool": complete_pool(post_window_pool),
                "covered": False,
                "hits": [],
            },
            "hits": [],
            "draws": [],
        }
    latest_issue = max((int(row.get("issue") or 0) for row in year_rows), default=0)
    natural_start = ((latest_issue - 1) // 5) * 5 + 1 if latest_issue else 0
    natural_end = natural_start + 4 if natural_start else 0
    natural_rows = sorted(
        [row for row in year_rows if natural_start <= int(row.get("issue") or 0) <= natural_end],
        key=lambda row: int(row.get("issue") or 0),
    )
    natural_complete = len(natural_rows) >= 5
    start = natural_start + 5 if natural_complete else natural_start
    end = start + 4 if start else 0
    window_rows = sorted(
        [row for row in year_rows if start <= int(row.get("issue") or 0) <= end],
        key=lambda row: int(row.get("issue") or 0),
    )
    pre_window_rows = [
        row for row in scoped_rows
        if display_year(row) != current_year or int(row.get("issue") or 0) < start
    ]
    pre_window_pool, _, _ = best_pool_cached(fixed_five_windows(pre_window_rows))
    pool_set = set(pre_window_pool)
    post_pool = complete_pool(post_window_pool)
    post_pool_set = set(post_pool)
    draws = []
    hits = []
    post_hits = []
    for row in window_rows:
        num = special_num(row)
        item = {
            "issue": int(row.get("issue") or 0),
            "date": str(row.get("date") or ""),
            "num": num,
        }
        draws.append(item)
        if num in pool_set:
            hits.append(item)
        if num in post_pool_set:
            post_hits.append(item)
    review_window = None
    if natural_complete:
        review_pre_rows = [
            row for row in scoped_rows
            if display_year(row) != current_year or int(row.get("issue") or 0) < natural_start
        ]
        review_pre_pool, _, _ = best_pool_cached(fixed_five_windows(review_pre_rows))
        review_pre_pool = complete_pool(review_pre_pool)
        review_pool_set = set(review_pre_pool)
        review_nums = sorted({special_num(row) for row in natural_rows if special_num(row)}, key=int)
        review_hits = []
        review_post_hits = []
        review_draws = []
        for row in natural_rows:
            num = special_num(row)
            item = {
                "issue": int(row.get("issue") or 0),
                "date": str(row.get("date") or ""),
                "num": num,
            }
            review_draws.append(item)
            if num in review_pool_set:
                review_hits.append(item)
            if num in post_pool_set:
                review_post_hits.append(item)
        review_window = {
            "year": current_year,
            "start": natural_start,
            "end": natural_end,
            "count": len(natural_rows),
            "expected": 5,
            "nums": review_nums,
            "covered": len(review_hits) > 0,
            "pool": review_pre_pool,
            "poolBasis": "before-review-window",
            "hits": review_hits,
            "draws": review_draws,
            "postWindowOptimal": {
                "covered": len(review_post_hits) > 0,
                "hits": review_post_hits,
            },
        }
    return {
        "year": current_year,
        "start": start,
        "end": end,
        "count": len(window_rows),
        "expected": 5,
        "covered": len(hits) > 0,
        "pool": pre_window_pool,
        "poolBasis": "before-current-window",
        "displayMode": "next-window" if natural_complete else "active-window",
        "reviewWindow": review_window,
        "postWindowOptimal": {
            "pool": post_pool,
            "covered": len(post_hits) > 0,
            "hits": post_hits,
        },
        "hits": hits,
        "draws": draws,
    }


def build_item(source, rows, range_name, generated_at):
    source_rows = [row for row in rows if row.get("source") == source]
    latest = max(source_rows, key=lambda row: (str(row.get("date") or ""), int(row.get("issue") or 0)), default=None)
    current_year = display_year(latest) if latest else ""
    scoped_rows = source_rows if range_name == "all" else [row for row in source_rows if display_year(row) == current_year]
    windows = fixed_five_windows(scoped_rows)
    post_pool, _, post_exact = best_pool_cached(windows)
    post_pool = complete_pool(post_pool)
    post_stats = coverage_stats(windows, post_pool)
    stats = rolling_window_stats(windows)
    years = sorted({display_year(row) for row in scoped_rows if display_year(row)}, reverse=True)
    year_pools = []
    for year in years:
        year_windows = [win for win in stats["windows"] if win["year"] == year]
        completed_year_windows = [win for win in windows if win["year"] == year]
        year_pool, _, year_exact = best_pool_cached(completed_year_windows)
        year_stats = rolling_window_stats(completed_year_windows)
        year_pools.append({
            "year": year,
            "pool": complete_pool(year_pool),
            "exact": year_exact,
            "covered": year_stats["covered"],
            "total": year_stats["total"],
            "hitRate": year_stats["hitRate"],
            "currentMiss": year_stats["currentMiss"],
            "maxMiss": year_stats["maxMiss"],
        })
    return {
        "source": source,
        "range": range_name,
        "currentYear": current_year,
        "pool": stats["windows"][-1]["pool"] if stats["windows"] else complete_pool(post_pool),
        "postWindowOptimalPool": post_pool,
        "postWindowStats": post_stats,
        "exact": post_exact,
        "method": "rolling-before-window-exact-or-greedy-49c8",
        "validationMode": "rolling-before-window",
        "computedAt": generated_at,
        "latestDraw": latest_draw_state(latest),
        "yearPools": year_pools,
        "currentWindow": current_window_state(source_rows, current_year, scoped_rows, range_name, post_pool),
        "rollingWindows": stats["windows"],
        **stats,
    }


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    generated_at = sys.argv[2] if len(sys.argv) > 2 else ""
    records_path = root / "data" / "records.json"
    state_path = root / "data" / "history-pattern-state.json"
    payload = json.loads(records_path.read_text(encoding="utf-8"))
    rows = payload.get("records", [])
    items = []
    for source in ("am", "hk"):
        for range_name in ("year", "all"):
            items.append(build_item(source, rows, range_name, generated_at))
    state_path.write_text(json.dumps({"generatedAt": generated_at, "items": items}, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
