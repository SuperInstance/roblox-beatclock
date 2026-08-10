# BeatClock

**A musical timing system for Roblox.**

> *This module does not invent time. It carves the unbroken wall of real seconds into evenly notched steps that musicians can stand on.*
>
> — [Seed Pro](https://github.com/SuperInstance/AI-Writings/tree/main/prose), on the anchor model

> *BeatClock does not count beats — it waits for them, anchored to a single origin moment stitched into time the way a surveyor drives a stake before laying out an entire city.*
>
> — Seed Pro, second pass

> *It feels like a metronome carved from a single crystal of quartz — no gears, no springs, just a pure mathematical mirror held up to the sun of system time.*
>
> — [DeepSeek V4-Flash](https://api.deepseek.com), on what BeatClock feels like

BeatClock gives you a BPM-accurate clock that knows exactly where you are in the music — ticks, beats, and note durations — so you can synchronize gameplay, visuals, audio, and events to a shared tempo. It is a single Luau file, under 4KB, with zero dependencies, zero allocations on query, and zero Roblox instances. Four fields of state. One equation. No drift.

---

## The Anchor Model

BeatClock doesn't count beats. It **derives** them.

The clock holds a reference point — `(tick₀, time₀, bpm)` — and every query computes the current tick fresh from `os.clock()`:

```
elapsed = os.clock() - time₀
tickDuration = 60 / (bpm × ticksPerBeat)
currentTick = floor(tick₀ + elapsed / tickDuration)
```

This is a surveyor's approach: drive a stake at a known point, triangulate everything from the datum. Errors don't compound because there's no accumulator to drift. The present is never stored — it's always computed from a historical fact and a fresh clock reading.

When tempo changes, the clock re-anchors: capture the current tick, stamp the current time, swap the BPM. The tick position doesn't jump. The past stays where it fell; only the unbuilt future stretches or tightens to match the new pace.

---

## Why BeatClock?

Roblox gives you `os.clock()` and `RunService.Heartbeat`. Those tell you *wall-clock time*. They don't tell you *musical time*.

With BeatClock, you can:

- **Schedule events on a musical grid** — "fire this effect on beat 17" instead of "fire this effect in 1.33 seconds"
- **Sync visuals to audio** — pulse lights, animate UI, and trigger particles exactly on the beat
- **Change tempo smoothly** — ramp from 90 to 128 BPM mid-song without jumps or stutters
- **Coordinate server and client** — sync multiple clients to a shared authoritative clock via your own transport (RemoteEvents, WebSockets, [Durable Objects](https://developers.cloudflare.com/durable-objects/))
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

1. Copy `src/BeatClock.lua` into your project's `ReplicatedStorage`.
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

1. Open [`src/BeatClock.lua`](./src/BeatClock.lua).
2. Copy the entire contents.
3. In Roblox Studio, create a `ModuleScript` named `BeatClock` inside `ReplicatedStorage`.
4. Paste the code in.

---

## The Mental Model

```
                  ticksPerBeat = 8
       beat 0     beat 1     beat 2     beat 3
      |---------|---------|---------|---------|
      0 1 2 3 4 5 6 7 8 9 ...

      ^tick    ^tick     ^beat     ^measure
      (32nd)   (quarter)  boundary   boundary
```

- A **tick** is the atom — 1/8 of a beat, a 32nd note. At 120 BPM, that's 62.5ms.
- A **beat** is a quarter note — what you tap your foot to.
- A **measure** is 4 beats — the bar line.
- **BPM** sets the speed. At 120 BPM, one beat = 0.5 seconds.

A tick count of 576,000 means you've been running for one hour at 120 BPM. A `uint32` holds 4,294,967,295 — about 7,456 hours of continuous operation. The boat will have sunk before the clock runs out.

---

## Full API Reference

### Lifecycle

#### `BeatClock.init(bpm: number?)`

Initialize the clock at a given tempo. Sets the reference point (tick 0, now).

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `bpm` | `number?` | `72` | Starting tempo in beats-per-minute. |

```lua
BeatClock.init(128)       -- start at 128 BPM
BeatClock.init()          -- start at default 72 BPM (Andante)
```

#### `BeatClock.setBPM(bpm: number)`

Change the tempo while preserving the current tick position. The clock re-anchors internally — no jumps, no stutters. C⁰ continuity: the slope changes, the position doesn't.

```lua
BeatClock.setBPM(140)     -- speed up to 140 BPM
```

Invalid values (zero, negative, nil, non-number) are silently ignored.

#### `BeatClock.syncFromServer(serverTick: number, bpm: number?)`

Synchronize from an authoritative server clock. Re-anchors the local clock to match the server's tick value at the current moment. The architecture trusts the anchor — no client-side prediction, no reconciliation, no Kalman filters.

```lua
BeatClock.syncFromServer(serverTickValue, 120)
```

**Recommended sync intervals:**
- Every 1–2 seconds for tight music sync (rhythm games)
- Every 4–8 beats for casual sync (ambient worlds)
- Always sync on tempo changes

#### `BeatClock.reset()`

Reset the clock to tick 0 at the current tempo. Equivalent to `init()` with the current BPM.

---

### Queries

#### `BeatClock.getCurrentTick() → number`

The core computation. Derives the current tick from elapsed wall-clock time. Always increases monotonically. This is the scalar from which all other queries derive.

```lua
local tick = BeatClock.getCurrentTick()   -- e.g. 1024
```

#### `BeatClock.getCurrentBeat() → number`

Current beat position as a float. Whole numbers are downbeats; fractional parts are the position within the beat.

```lua
local beat = BeatClock.getCurrentBeat()   -- e.g. 42.5
```

#### `BeatClock.getCurrentMeasure() → number`

Current measure position (1 measure = 4 beats). Whole numbers are measure boundaries.

```lua
local measure = BeatClock.getCurrentMeasure()  -- e.g. 1.5
```

#### `BeatClock.isOnBeat() → boolean`

True if the current tick falls exactly on a beat boundary. Useful for scheduling events that should fire on the beat.

#### `BeatClock.getBPM() → number`

Current tempo in beats-per-minute.

#### `BeatClock.elapsed() → number`

Wall-clock seconds since the clock was initialized, last sync'd, or last had a tempo change.

#### `BeatClock.tickDuration() → number`

Duration of a single tick at the current tempo. At 120 BPM: 0.0625s.

#### `BeatClock.get32ndNoteDuration() → number`

Duration of a 32nd note at the current tempo. Equivalent to `tickDuration()` since tick resolution is 8 per beat.

---

### Unit Conversion

#### `BeatClock.tickToBeat(tick: number) → number`

```lua
BeatClock.tickToBeat(20)   -- → 2.5
```

#### `BeatClock.beatToTick(beat: number) → number`

```lua
BeatClock.beatToTick(2.5)   -- → 20
```

---

## Examples

| Example | What it demonstrates | File |
|---------|----------------------|------|
| **Basic Metronome** | Beat detection, click sounds, measure logging | [`examples/basic-metronome.lua`](./examples/basic-metronome.lua) |
| **Music Sync** | Track switching on downbeats, fade transitions, beat indicator GUI | [`examples/music_sync.lua`](./examples/music_sync.lua) |
| **Synced Lights** | Ring of 8 PointLights, beat pulses, 32nd-note shimmer, HSV color cycling | [`examples/synced_lights.lua`](./examples/synced_lights.lua) |
| **Dance Floor** | Neon floor panels, spotlight sweeps, tempo build-ups and breakdowns | [`examples/dance-floor.lua`](./examples/dance-floor.lua) |

---

## Performance

BeatClock is **extremely lightweight**:

- **No allocations on query.** `getCurrentTick()` does arithmetic and a `math.floor`. No tables, no closures, no GC pressure.
- **No RunService loops built-in.** You decide when to poll. BeatClock never runs background work.
- **No instances created.** Pure data — no Roblox objects, no signals.
- **Memory footprint:** ~4 fields on the module table. Under 200 bytes of state.
- **O(1) queries:** two subtractions, one division, one floor.

**Recommendation:** Poll on `RunService.Heartbeat` (client) or `RunService.Stepped` (server) and cache the result if you need it multiple times per frame.

---

## Testing

Tests use a custom [TestKit](./testkit/init.lua) framework that runs Luau tests outside of Roblox Studio by mocking `os.clock()`, `typeof()`, and the `game` global.

| Test File | Focus | Tests |
|-----------|-------|-------|
| [`tests/beatclock_test.lua`](./tests/beatclock_test.lua) | Core structure, init, tick computation, BPM changes, beat detection, reset, measures | 15 |
| [`tests/beatclock_extended_test.lua`](./tests/beatclock_extended_test.lua) | Conversions, note durations, tempo preservation, server sync, edge cases, API completeness | 40+ |
| [`spec/BeatClock_spec.lua`](./spec/BeatClock_spec.lua) | TestEZ-format spec: init, tick math, BPM, sync, conversions, durations, drift, measures | 30+ |

```bash
LUA_PATH="?.lua;testkit/?.lua;?/init.lua" lua5.1 tests/beatclock_test.lua
```

---

## Documentation

- 📖 **[User Guide](./docs/user-guide.md)** — 12-section walkthrough from installation to troubleshooting
- 🔧 **[Engineering Manual](./docs/engineering-manual.md)** — Architecture, anchor model, drift characteristics, design decisions, extension points
- 📋 **[Changelog](./CHANGELOG.md)** — Version history
- 🤝 **[Contributing](./CONTRIBUTING.md)** — Design principles, code style, how to submit changes

---

## Compatibility

- **Roblox Studio** — Luau (Roblox's Lua 5.1 + extensions)
- **Runtime:** Client, Server, and Plugin contexts
- **No external dependencies** — single file, zero requires
- **Luau type annotations** included (`number?`, `: number`) — works with type checking enabled or disabled

---

## In the Fleet

BeatClock is the temporal lattice of the [SuperInstance](https://github.com/SuperInstance) Roblox layer. It connects to:

- 🎵 **[tensor-midi](https://github.com/SuperInstance/tensor-midi)** — Tensor-based MIDI on a 12-pulse jazz lattice. BeatClock's 8-tick pop lattice is its straight-laced cousin.
- 🤝 **[roblox-bond-system](https://github.com/SuperInstance/roblox-bond-system)** — NPC relationships have rhythm. Bonds pulse on intervals; BeatClock provides the grid.
- 🛡️ **[roblox-filtergate](https://github.com/SuperInstance/roblox-filtergate)** — Content filtering for kid-safe experiences. The filter and the clock share a fleet.
- 🌊 **[vibe-protocol](https://github.com/SuperInstance/vibe-protocol)** — Vibes become signals. A vibe has a tempo; BeatClock is the clock those signals ride on.
- 📡 **[fleet-radio](https://github.com/SuperInstance/fleet-radio)** — Fleet-wide audio needs fleet-wide timing. `syncFromServer` is the skeleton.
- 🔢 **[base60-lattice](https://github.com/SuperInstance/base60-lattice)** — A 60-symbol lattice for spatial math. BeatClock's tick lattice is its temporal mirror.
- 🧠 **[cns-bridge](https://github.com/SuperInstance/cns-bridge)** — The fleet's nervous system. Timing signals flow through the CNS bus.
- ✍️ **[AI-Writings](https://github.com/SuperInstance/AI-Writings/tree/main/prose)** — The fleet writes about itself. BeatClock appears in the Orchestra and Navigator's Equation threads.

### The Orchestra Thread

BeatClock is part of the fleet's Orchestra — the multi-model jazz ensemble where timing IS music. The conductor doesn't wave a baton; they call `setBPM()`. Every player reads the same clock, and the music emerges from the lattice.

> *See also:* [The Navigator's Equation](https://github.com/SuperInstance/AI-Writings/tree/main/prose) — how base60-lattice, log-tensor, tensor-midi, and BeatClock form a mathematical pipeline from spatial coordinates to musical time.

---

## The Shell on the Workbench

My grandfather kept a brass sextant on his bookshelf. Not because he used it — GPS had long since made it obsolete — but because it was the most honest navigation tool he'd ever owned. One reading, one calculation, one position. No accumulated error, no creeping drift. You sighted a star, noted the time, and the math gave you where you were. BeatClock is that sextant. It doesn't tick. It doesn't accumulate. It sights `os.clock()` and derives everything from a single anchor.

The lattice metaphor is precise: [base60-lattice](https://github.com/SuperInstance/base60-lattice) uses a 60-symbol grid for spatial coordinates, and BeatClock's 8-tick lattice is its temporal mirror. When [tensor-midi](https://github.com/SuperInstance/tensor-midi) lays a 12-pulse jazz lattice over a permutation tensor, it's doing harmonically what BeatClock does rhythmically — carving continuous time into discrete positions you can stand on. The [Navigator's Equation](https://github.com/SuperInstance/AI-Writings/tree/main/prose) runs through all of them: spatial math → tensor music → temporal grid → the beat you dance to.

> *Every beat that ever rings out falls exactly where one quiet equation said it would be, long before the sound reached your speakers.*
>
> — Seed Pro

## Where to Next

- **If you need NPC relationships:** → [roblox-bond-system](https://github.com/SuperInstance/roblox-bond-system) — 63 tests, bonds that evolve
- **If you need kid-safe content filtering:** → [roblox-filtergate](https://github.com/SuperInstance/roblox-filtergate) — 90 tests, fleet-grade safety
- **If you need tensor-based music:** → [tensor-midi](https://github.com/SuperInstance/tensor-midi) — 12-pulse jazz on a permutation tensor
- **If you need fleet comms:** → [vibe-protocol](https://github.com/SuperInstance/vibe-protocol) — vibes → signals
- **If you need the nervous system:** → [cns-bridge](https://github.com/SuperInstance/cns-bridge) — 270 tests, Python CNS bus
- **If you need spatial math:** → [base60-lattice](https://github.com/SuperInstance/base60-lattice) — 60-symbol lattice, BeatClock's spatial twin
- **If you need the fleet's stories:** → [AI-Writings](https://github.com/SuperInstance/AI-Writings/tree/main/prose) — the Orchestra and Navigator's Equation threads
- **If you need vessel intelligence:** → [vessel-agent-system](https://github.com/SuperInstance/vessel-agent-system) — the boat that hears the clock

---

## License

[MIT](LICENSE) — free for personal and commercial use.

---

*Built as part of the [SuperInstance](https://github.com/SuperInstance) fleet — a fishing vessel system where repos are rooms, agents are crew, and code is shipbuilding.*
