# BeatClock

> *A ship's chronometer carved from a single block of code.*
>
> **Under 4 KB. Zero dependencies. Zero allocations on query. BPM-accurate musical time for Roblox.**

BeatClock is a musical timing system that derives **ticks, beats, and measures** from `os.clock()` — the highest-resolution monotonic clock in Luau. It doesn't count. It computes. Every query is a fresh sight-line to the current musical position, with no accumulated drift.

```
                  ticksPerBeat = 8
       beat 0     beat 1     beat 2     beat 3
      |---------|---------|---------|---------|
      0 1 2 3 4 5 6 7 8 9 ...

      ^tick    ^tick     ^beat     ^measure
      (32nd)   (quarter)  boundary   boundary
```

---

## Why BeatClock?

Roblox gives you [`os.clock()`](https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#osclock) and [`RunService.Heartbeat`](https://create.roblox.com/docs/reference/engine/classes/RunService#Heartbeat). Those tell you *wall-clock time*. They don't tell you *musical time*.

BeatClock bridges that gap. It's the brass sextant you keep in the captain's locker — simple, ancient, and brutally precise. You hold it up, sight the horizon, and it whispers: *"You are exactly 8 ticks past the third beat of the 14th measure."*

With it, you can:

- **Schedule events on a musical grid** — "fire this effect on beat 17" instead of "fire this effect in 1.33 seconds"
- **Sync visuals to audio** — pulse lights, animate UI, and trigger particles exactly on the beat
- **Change tempo smoothly** — ramp from 90 to 128 BPM mid-song; the clock [re-anchors](docs/engineering-manual.md#3-tempo-changes) so there are no jumps or stutters
- **Coordinate server and client** — sync multiple clients to a shared authoritative clock via your own transport
- **Build rhythm mechanics** — detect if a player pressed a button on-beat or off-beat

---

## Quick Start

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BeatClock = require(ReplicatedStorage.BeatClock)

BeatClock.init(120)                       -- start at 120 BPM
print(BeatClock.getCurrentBeat())         -- e.g. 42.5
print(BeatClock.get32ndNoteDuration())    -- 0.0625 seconds
```

That's it. You have a musical clock.

---

## Installation

### Option A — Rojo (recommended)

1. Copy [`src/BeatClock.lua`](src/BeatClock.lua) into your project's `ReplicatedStorage`.
2. Or clone this repo and symlink it:

```bash
git clone https://github.com/SuperInstance/roblox-beatclock.git
```

Add to your `default.project.json`:

```json
{
  "ReplicatedStorage": {
    "BeatClock": {
      "$path": "../roblox-beatclock/src/BeatClock.lua"
    }
  }
}
```

### Option B — Manual copy

1. Open [`src/BeatClock.lua`](src/BeatClock.lua).
2. Copy the entire contents.
3. In Roblox Studio, create a `ModuleScript` named `BeatClock` inside `ReplicatedStorage`.
4. Paste the code in.

---

## How It Works

BeatClock uses a **reference-point anchor model**. At any moment, the clock is defined by three values:

| State | Description |
|-------|-------------|
| `startTick` | The tick value at the reference moment |
| `startTime` | The `os.clock()` reading at the reference moment |
| `bpm` | The current tempo |

The current tick is derived on demand:

```
elapsed = os.clock() - startTime
tickDuration = 60 / (bpm × ticksPerBeat)
currentTick = floor(startTick + elapsed / tickDuration)
```

This means queries are **O(1)** — two subtractions, one division, one floor. No timer drift. No background work. The clock only computes when asked.

When you call `setBPM()`, it captures the current tick, re-anchors to that exact moment, and switches to the new tempo. The tick position is continuous. The hook never moves; only the current does.

For the full architecture, see the [Engineering Manual](docs/engineering-manual.md).

---

## Full API Reference

### Lifecycle

#### `BeatClock.init(bpm: number?)`

Initialize the clock at a given tempo. Sets the reference point (tick 0, now).

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `bpm` | `number?` | `72` | Starting tempo in beats-per-minute. |

#### `BeatClock.setBPM(bpm: number)`

Change tempo while preserving the current tick position. Re-anchors internally — no jumps.

#### `BeatClock.syncFromServer(serverTick: number, bpm: number?)`

Synchronize from an authoritative server clock. Re-anchors the local clock to match the server's tick value at the current moment. Use this with [RemoteEvents](https://create.roblox.com/docs/reference/engine/classes/RemoteEvent), WebSockets, or any transport you build.

#### `BeatClock.reset()`

Reset to tick 0 at the current tempo. Equivalent to `init()` with the current BPM.

### Queries

#### `BeatClock.getCurrentTick(): number`

The core computation. Derives the current tick from elapsed wall-clock time. Always increases monotonically. Integer.

#### `BeatClock.getCurrentBeat(): number`

Current beat position as a float. Whole numbers are downbeats; fractional parts are positions within the beat.

#### `BeatClock.getCurrentMeasure(): number`

Current measure position (1 measure = 4 beats). Float.

#### `BeatClock.isOnBeat(): boolean`

True if the current tick falls exactly on a beat boundary.

#### `BeatClock.getBPM(): number`

Current tempo in beats-per-minute.

#### `BeatClock.elapsed(): number`

Wall-clock seconds since the clock was initialized, last sync'd, or last had a tempo change.

#### `BeatClock.tickDuration(): number`

Duration of a single tick at the current tempo. At 120 BPM: 0.0625 seconds.

#### `BeatClock.get32ndNoteDuration(): number`

Duration of a 32nd note at the current tempo. Equivalent to `tickDuration()` since tick resolution is 8 per beat.

### Conversion

#### `BeatClock.tickToBeat(tick: number): number`

Convert a tick to its beat equivalent. `tickToBeat(20)` → `2.5`.

#### `BeatClock.beatToTick(beat: number): number`

Convert a beat to its nearest tick (floored). `beatToTick(2.5)` → `20`.

---

## Examples

| Example | What It Does |
|---------|-------------|
| [`basic-metronome.lua`](examples/basic-metronome.lua) | Clicks on every beat. The simplest possible use. |
| [`synced_lights.lua`](examples/synced_lights.lua) | Ring of light poles that flash on downbeats, shimmer on 32nd-notes, and handle tempo changes. |
| [`dance-floor.lua`](examples/dance-floor.lua) | Neon dance floor with color cycling, spotlight sweeps, and mid-song tempo shifts. |
| [`music_sync.lua`](examples/music_sync.lua) | Multi-track music system that switches tracks on measure boundaries with beat-aligned starts. |

---

## Performance

BeatClock is **deliberately lightweight**:

- **No allocations on query.** `getCurrentTick()` does arithmetic and a `math.floor`. No tables, no closures.
- **No RunService loops built-in.** You decide when to poll. BeatClock never runs background work.
- **No instances created.** Pure data — no Roblox objects, no signals, no GC pressure.
- **Memory footprint:** ~4 fields on the module table. Under 200 bytes of state.
- **Resolution:** 8 ticks per beat (32nd-note grid). At 120 BPM, that's 7.5ms per tick — well within frame budget.

At 120 BPM with 8 ticks/beat: **576,000 ticks per hour**. A `uint32` holds 4,294,967,295 → ~7,456 hours of continuous operation.

---

## Testing

BeatClock is testable without Roblox by mocking `os.clock()`. The test suite covers module structure, init, tick computation, BPM changes, sync, conversions, note durations, long-session drift, and edge cases.

```bash
LUA_PATH="?.lua;testkit/?.lua;?/init.lua" lua5.1 tests/beatclock_test.lua
```

| Test File | What It Covers |
|-----------|---------------|
| [`tests/beatclock_test.lua`](tests/beatclock_test.lua) | Module structure, init, tick computation, BPM changes, beat detection, reset, measure tracking |
| [`tests/beatclock_extended_test.lua`](tests/beatclock_extended_test.lua) | Conversion round-trips, note durations, setBPM tick preservation, server sync, elapsed, isOnBeat, edge cases, API completeness |
| [`spec/BeatClock_spec.lua`](spec/BeatClock_spec.lua) | TestEZ-format spec with mock clock — long-session drift, all exported functions, invalid-input guards |

Tests run on the [TestKit](testkit/init.lua) framework — a minimal Lua test harness that strips Luau type annotations and runs Roblox Luau code outside Studio.

---

## Design Principles

BeatClock follows three core principles, documented in the [CONTRIBUTING.md](CONTRIBUTING.md):

1. **Stateless queries** — every call to `getCurrentTick()` computes from `os.clock()` fresh; no accumulation, no drift
2. **Zero allocations on query** — no tables, no closures, no GC pressure
3. **No built-in events** — consumers poll on Heartbeat and do their own change detection

If you need beat events, server sync, or pattern scheduling, build it as a **wrapper module** that requires BeatClock. Wrap, don't embed.

---

## Compatibility

- **Roblox Studio** — Luau (Roblox's Lua 5.1 + extensions)
- **Runtime:** Client, Server, and Plugin contexts
- **No external dependencies** — single file, zero requires
- **Luau type annotations** included — works with type checking enabled or disabled

---

## In the Fleet

BeatClock is the chronometer for the [SuperInstance](https://github.com/SuperInstance) musical toolchain. It connects to:

- [**tensor-midi**](https://github.com/SuperInstance/tensor-midi) — Timing IS music. The tensor MIDI system operates on the same pulse grid, but in the fleet's cognitive layer. BeatClock is the Roblox-side heartbeat; tensor-midi is the fleet-side brain.
- [**roblox-bond-system**](https://github.com/SuperInstance/roblox-bond-system) — Bonds have rhythm. NPC relationships pulse and shift on temporal patterns that need a clock to coordinate.
- [**roblox-filtergate**](https://github.com/SuperInstance/roblox-filtergate) — Content filtering timed to musical events, safe zones on downbeats.
- [**vibe-protocol**](https://github.com/SuperInstance/vibe-protocol) — Vibes become signals. When vibes need temporal coordination, BeatClock provides the grid.
- [**cns-bridge**](https://github.com/SuperInstance/cns-bridge) — The central nervous system bus. BeatClock can serve as the clock domain for CNS-packet scheduling in real-time experiences.
- [**fleet-envelope**](https://github.com/SuperInstance/fleet-envelope) — Event grammar. BeatClock timestamps align with envelope timing for synchronized fleet-wide events.

### The Orchestra

In the SuperInstance fleet, multi-model jazz is the operating mode. BeatClock is the click track that keeps every instrument — every model, every agent, every visual system — locked to the same pulse. See:
- [**AI-Writings: Night Watch**](https://github.com/SuperInstance/AI-Writings/tree/main/night-watch) — Overnight creative sessions where BeatClock kept the rhythm.
- [**wesley-journal**](https://github.com/SuperInstance/wesley-journal) — Wesley's experiments with musical timing in the holodeck.

---

## Documentation

| Document | Description |
|----------|-------------|
| [User Guide](docs/user-guide.md) | Beginner-friendly walkthrough — install, first clock, beats, tempo, sync, conversions, troubleshooting |
| [Engineering Manual](docs/engineering-manual.md) | Architecture, anchor model, drift characteristics, design decisions, extension points, limitations |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute, code style, design principles |
| [Examples](examples/) | Working scripts: metronome, synced lights, dance floor, music sync |

---

## License

[MIT](LICENSE) — free for personal and commercial use.

---

## Where to Next

- [**roblox-bond-system**](https://github.com/SuperInstance/roblox-bond-system) — NPC relationships that pulse on BeatClock's grid
- [**roblox-filtergate**](https://github.com/SuperInstance/roblox-filtergate) — Content filtering for safe musical experiences
- [**tensor-midi**](https://github.com/SuperInstance/tensor-midi) — The fleet-side MIDI system. Same pulse, bigger brain.
- [**vibe-protocol**](https://github.com/SuperInstance/vibe-protocol) — When vibes need a clock to coordinate
- [**vessel-agent-system**](https://github.com/SuperInstance/vessel-agent-system) — The boat itself, where timing meets the water
