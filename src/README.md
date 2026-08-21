# src/ — BeatClock Source

The entire module is a single file: [`BeatClock.lua`](./BeatClock.lua).

Under 4KB. Four fields of state. Fourteen functions. Zero dependencies.

> *A metronome carved from a single crystal of quartz — no gears, no springs, just a pure mathematical mirror held up to the sun of system time.*
>
> — DeepSeek V4-Flash

## The Equation

```
tick(now) = floor(tick₀ + (now - time₀) / (60 / (bpm × ticksPerBeat)))
```

Everything else — beats, measures, note durations, beat detection — is a lens over that single scalar.

## Architecture

BeatClock is a **Mathematical Projection System**: one pure function `f(anchor, now) → tick` wrapped in a minimal mutable cell. The anchor `(tick₀, time₀, bpm)` only updates on authority events (`init`, `setBPM`, `syncFromServer`). Time progression never mutates state.

```
┌──────────────────────────────────────────────┐
│                 BeatClock                     │
│                                               │
│  State:                                       │
│    bpm           number   (e.g. 120)          │
│    ticksPerBeat  number   (constant: 8)       │
│    startTick     number   (reference tick)    │
│    startTime     number   (os.clock at anchor)│
│                                               │
│  Queries (O(1), zero allocations):            │
│    elapsed()       → os.clock() - startTime   │
│    tickDuration()  → 60 / (bpm × ticksPerBeat)│
│    getCurrentTick()→ floor(startTick +        │
│                        elapsed / tickDuration)│
│    getCurrentBeat()→ tick / ticksPerBeat      │
│                                               │
│  Mutations (authority events only):           │
│    init(bpm)         → set anchor to (0, now) │
│    setBPM(bpm)       → re-anchor preserving   │
│                        current tick           │
│    syncFromServer()  → set anchor to          │
│                        (serverTick, now)      │
└──────────────────────────────────────────────┘
```

### Key Invariants

1. **Referential transparency** — `getCurrentTick()` at the same `os.clock()` always returns the same value
2. **Anchor continuity** — `setBPM()` preserves the instantaneous tick (C⁰ continuity)
3. **Monotonicity** — `tick₀` and `time₀` only increase
4. **Authority isolation** — `syncFromServer()` overwrites the anchor atomically; no smoothing

## Why `os.clock()`?

Highest-resolution monotonic clock in Luau. Process-local. Not affected by NTP adjustments. ~microsecond precision. No network round-trip like `workspace:GetServerTimeNow()`.

## File Manifest

| File | Size | Purpose |
|------|------|---------|
| [`BeatClock.lua`](./BeatClock.lua) | ~4KB | The entire module. 14 functions, 4 state fields, zero dependencies. |

## Fleet Connections

- [fleet-jepa-midi](https://github.com/SuperInstance/fleet-jepa-midi) — The 12-pulse jazz lattice. BeatClock's 8-tick grid is its straight-laced cousin.
- [base60-lattice](https://github.com/SuperInstance/base60-lattice) — 60-symbol spatial lattice. BeatClock's tick lattice is its temporal mirror.
- [cns-bridge](https://github.com/SuperInstance/cns-bridge) — The fleet's nervous system. Timing signals flow through the CNS bus.
- [roblox-bond-system](https://github.com/SuperInstance/roblox-bond-system/src) — NPC bonds have rhythm. BeatClock provides the grid they pulse on.

---

← Back to [BeatClock](../README.md)
