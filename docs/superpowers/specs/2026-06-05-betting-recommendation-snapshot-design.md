# Betting Recommendation Snapshot Design

## Goal

Upgrade the dashboard from an observation page into a stricter betting recommendation system. The system must keep each recommendation traceable, settle it only against the real draw result, and prevent current pools from rewriting historical outcomes.

## Scope

This design covers the home betting recommendation tab for:

- Special number 8-number pool
- Three-hit-three 8-number pool

Advanced analysis pages can keep their existing observation tables, but the home recommendation result must be driven by recommendation snapshots and strict settlement rules.

## Recommendation Snapshot

Each generated recommendation creates an immutable snapshot object:

- `id`
- `source`
- `date`
- `issue`
- `game`
- `name`
- `pool`
- `poolSize`
- `score`
- `level`
- `reasons`
- `generatedAt`
- `status`
- `draw`
- `matched`
- `hit`

The snapshot `pool` is the effective pool at recommendation time. Review tables must read this snapshot pool first. They may show current-pool hindsight as a separate diagnostic column, but that column cannot affect hit/miss settlement.

## Settlement Rules

Special number:

- Settled when the target issue has a draw record.
- Hit when the special number is in the snapshot pool.

Three-hit-three:

- Settled when the target issue has a draw record.
- Hit when at least 3 of the first 6 draw numbers are in the snapshot pool.

Pending recommendations stay pending. No settled result may be recalculated from the latest pool unless the saved snapshot pool is missing and a legacy fallback is required.

## Risk Gates

The recommendation level is controlled by hard gates before score thresholds:

- Insufficient review sample: pause.
- Current miss greater than historical max miss: pause.
- Recent settled snapshot miss streak at or above 3: pause.
- Snapshot review hit rate below expected baseline by a clear margin: pause.
- A direct bet requires strong score, acceptable current miss, recent strength, and non-weak snapshot review.

The score is still shown, but the level must obey the gates.

## UI

The home page should be simple:

- Current recommendation cards
- Snapshot pool numbers
- Score and level
- Short reasons
- Latest snapshot review table

Observation-heavy wording should stay out of the primary recommendation surface.
