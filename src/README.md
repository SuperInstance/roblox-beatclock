# src/ — BeatClock Source

The entire module is a single file: [`BeatClock.lua`](./BeatClock.lua).

Under 4KB. Four fields of state. Fourteen functions. Zero dependencies.

## The Equation

```
tick(now) = floor(tick₀ + (now - time₀) / (60 / (bpm × ticksPerBeat)))
```

Everything else — beats, measures, note durations, beat detection — is a lens over that single scalar.

## Architecture

BeatClock is a **Mathematical Projection System**: one pure function `f(anchor, now) → tick` wrapped in a minimal mutable cell. The anchor `(tick₀, time₀, bpm)` only updates on authority events (`init`, `setBPM`, `syncFromServer`). Time progression never mutates state.

### Key Invariants

1. **Referential transparency** — `getCurrentTick()` at the same `os.clock()` always returns the same value
2. **Anchor continuity** — `setBPM()` preserves the instantaneous tick (C⁰ continuity)
3. **Monotonicity** — `tick₀` and `time₀` only increase
4. **Authority isolation** — `syncFromServer()` overwrites the anchor atomically; no smoothing

## Why `os.clock()`?

Highest-resolution monotonic clock in Luau. Process-local. Not affected by NTP adjustments. ~microsecond precision. No network round-trip like `workspace:GetServerTimeNow()`.

---

← Back to [BeatClock](../README.md)
