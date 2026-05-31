import argparse
import itertools
import json
from pathlib import Path

import numpy as np


VERIFY_COUNT = 13_983_816
BATCH_SIZE = 250_000


def first_six_mask(record):
    mask = 0
    for ball in record["balls"][:6]:
        mask |= 1 << (int(ball["number"]) - 1)
    return np.uint64(mask)


def combo_mask(combo):
    mask = 0
    for num in combo:
        mask |= 1 << (num - 1)
    return np.uint64(mask)


def metric_rates(hit_orders, total):
    if hit_orders:
        current_miss = hit_orders[0]
        max_miss = current_miss
        for prev, cur in zip(hit_orders, hit_orders[1:]):
            max_miss = max(max_miss, cur - prev - 1)
    else:
        current_miss = total
        max_miss = total

    def rate(limit):
        take = min(limit, total)
        if take <= 0:
            return 0.0
        return round(sum(1 for order in hit_orders if order < take) / take * 100, 1)

    return {
        "hits": len(hit_orders),
        "currentMiss": int(current_miss),
        "maxMiss": int(max_miss),
        "match3Rate": round(len(hit_orders) / total * 100, 1) if total else 0.0,
        "recent60": rate(60),
        "recent120": rate(120),
        "recent240": rate(240),
    }


def score_metrics(metrics):
    return round(
        metrics["recent60"] * 900
        + metrics["recent120"] * 650
        + metrics["recent240"] * 260
        + metrics["match3Rate"] * 120
        - metrics["currentMiss"] * 80
        - metrics["maxMiss"] * 20,
        1,
    )


def evaluate_top(records, top=10):
    total = len(records)
    record_masks = np.array([first_six_mask(record) for record in records], dtype=np.uint64)
    best = []
    batch_masks = []
    batch_combos = []
    verified = 0

    def flush():
        nonlocal best, batch_masks, batch_combos
        if not batch_masks:
            return
        masks = np.array(batch_masks, dtype=np.uint64)
        hit_count = np.zeros(masks.shape[0], dtype=np.uint16)
        current_miss = np.full(masks.shape[0], total, dtype=np.uint16)
        max_miss = np.zeros(masks.shape[0], dtype=np.uint16)
        last_hit = np.full(masks.shape[0], -1, dtype=np.int32)
        recent60 = np.zeros(masks.shape[0], dtype=np.uint16)
        recent120 = np.zeros(masks.shape[0], dtype=np.uint16)
        recent240 = np.zeros(masks.shape[0], dtype=np.uint16)

        for order, record_mask in enumerate(record_masks):
            hits = np.bitwise_count(np.bitwise_and(masks, record_mask)) >= 3
            if not bool(np.any(hits)):
                continue
            hit_count[hits] += 1
            current_miss[np.logical_and(hits, current_miss == total)] = order
            seen_before = np.logical_and(hits, last_hit >= 0)
            if bool(np.any(seen_before)):
                gap = order - last_hit[seen_before] - 1
                max_miss[seen_before] = np.maximum(max_miss[seen_before], gap.astype(np.uint16))
            last_hit[hits] = order
            if order < 60:
                recent60[hits] += 1
            if order < 120:
                recent120[hits] += 1
            if order < 240:
                recent240[hits] += 1

        max_miss = np.maximum(max_miss, current_miss)
        denom60 = max(min(total, 60), 1)
        denom120 = max(min(total, 120), 1)
        denom240 = max(min(total, 240), 1)
        denom_all = max(total, 1)
        match3_rate = hit_count.astype(np.float64) / denom_all * 100
        r60 = recent60.astype(np.float64) / denom60 * 100
        r120 = recent120.astype(np.float64) / denom120 * 100
        r240 = recent240.astype(np.float64) / denom240 * 100
        scores = r60 * 900 + r120 * 650 + r240 * 260 + match3_rate * 120 - current_miss * 80 - max_miss * 20
        keep = min(top * 4, scores.shape[0])
        idxs = np.argpartition(scores, -keep)[-keep:]
        for idx in idxs:
            metrics = {
                "hits": int(hit_count[idx]),
                "currentMiss": int(current_miss[idx]),
                "maxMiss": int(max_miss[idx]),
                "match3Rate": round(float(match3_rate[idx]), 1),
                "recent60": round(float(r60[idx]), 1),
                "recent120": round(float(r120[idx]), 1),
                "recent240": round(float(r240[idx]), 1),
            }
            best.append((float(scores[idx]), batch_combos[idx], metrics))
        best.sort(key=lambda item: (-item[0], item[2]["currentMiss"], item[2]["maxMiss"]))
        best = best[: top * 4]
        batch_masks = []
        batch_combos = []

    for combo in itertools.combinations(range(1, 50), 6):
        verified += 1
        batch_combos.append(combo)
        batch_masks.append(combo_mask(combo))
        if len(batch_masks) >= BATCH_SIZE:
            flush()
    flush()

    rows = []
    for _, combo, _ in best[:top]:
        selected_mask = combo_mask(combo)
        hit_orders = [
            order
            for order, record_mask in enumerate(record_masks)
            if int(np.bitwise_count(np.bitwise_and(selected_mask, record_mask))) >= 3
        ]
        metrics = metric_rates(hit_orders, total)
        rows.append(
            {
                "numbers": [f"{num:02d}" for num in combo],
                "metrics": metrics,
                "score": score_metrics(metrics),
                "verifiedCandidates": VERIFY_COUNT,
                "verification": "exhaustive-49c6",
            }
        )
    rows.sort(key=lambda row: (-row["score"], row["metrics"]["currentMiss"], row["metrics"]["maxMiss"]))
    return {"verifiedCandidates": verified, "method": "exhaustive-49c6", "rows": rows[:top]}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    payload = json.loads(Path(args.input).read_text(encoding="utf-8"))
    records = payload["records"]
    result = {
        "sanzhong": {
            "sixBest": {
                "am": evaluate_top([record for record in records if record["source"] == "am"]),
                "hk": evaluate_top([record for record in records if record["source"] == "hk"]),
            }
        }
    }
    Path(args.output).write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


if __name__ == "__main__":
    main()
