# BeatClock — Engineering Manual

Internal architecture, data flow, and design decisions.

---

## 1. Architecture Overview

BeatClock is a **stateless query engine** over a tiny mutable state record. There are no background threads, no event handlers, and no Roblox instances. The module table *is* the state.

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
│  Queries:                                     │
│    elapsed()       → os.clock() - startTime   │
│    tickDuration()  → 60 / (bpm × ticksPerBeat)│
│    getCurrentTick()→ floor(startTick +        │
│                        elapsed / tickDuration)│
│    getCurrentBeat()→ tick / ticksPerBeat      │
│                                               │
│  Mutations:                                   │
│    init(bpm)         → set anchor to (0, now) │
│    setBPM(bpm)       → re-anchor preserving   │
│                        current tick           │
│    syncFromServer()  → set anchor to          │
│                        (serverTick, now)      │
└──────────────────────────────────────────────┘
```

## 2. The Anchor Model

BeatClock uses a **reference-point anchor** model. At any moment, the clock is defined by:

```
(tick₀, time₀, bpm)
```

Where:
- `tick₀` is the tick value at the reference moment
- `time₀` is the `os.clock()` value at the reference moment
- `bpm` is the current tempo

The current tick is derived on demand:

```
elapsed = os.clock() - time₀
tickDuration = 60 / (bpm × ticksPerBeat)
currentTick = floor(tick₀ + elapsed / tickDuration)
```

This means:
- **Queries are O(1)** — two subtractions, one division, one floor.
- **No timer drift** — we always read `os.clock()` fresh, so accumulated error is impossible.
- **No background work** — the clock only computes when asked.

### Why `os.clock()`?

`os.clock()` is the highest-resolution monotonic clock available in Luau. It's process-local, not affected by system time changes (NTP adjustments), and has ~microsecond precision on most platforms.

`tick()` is lower resolution and based on system uptime. `os.time()` is integer-second granularity. `workspace:GetServerTimeNow()` requires a network round-trip.

### Why `floor` on tick (integer)?

Ticks represent discrete positions on a musical grid. A tick is either "where you are" or "where you were" — there's no value in a fractional tick. The floor ensures consistency: if you poll twice in the same tick interval, you get the same answer.

Beats, by contrast, are returned as floats because fractional beat positions are musically meaningful (e.g., "halfway through beat 3").

## 3. Tempo Changes

When `setBPM(bpm)` is called:

1. Capture `currentTick = getCurrentTick()` (the exact tick at this moment under the old tempo).
2. Set `startTick = currentTick` and `startTime = os.clock()`.
3. Set `bpm = bpm`.

This re-anchors the clock so that:
- The tick position is continuous (no jump).
- Future ticks are computed at the new tempo.
- There's no accumulation error because the anchor is reset.

### Edge case: tempo change mid-beat

If the tempo changes at beat 2.5 (tick 20 at 8 ticks/beat), the new anchor is `(20, now)`. The beat position remains 2.5. The next tick arrives after `60 / (newBPM × 8)` seconds.

## 4. Server Synchronization

BeatClock does not include a networking layer. The `syncFromServer(serverTick, bpm?)` method is a hook for your own transport:

```
Server (authoritative)              Client (mirror)
        │                                 │
        │   WebSocket / RemoteEvent       │
        │──── tick: 12345, bpm: 128 ─────▶│
        │                                 │
        │                          syncFromServer(12345, 128)
        │                          → startTick = 12345
        │                          → startTime = os.clock()
        │                          → bpm = 128
```

**Drift characteristics:**
- After sync, drift is bounded by `os.clock()` precision (~µs) and network latency jitter.
- Between syncs, drift accumulates at the clock skew rate (typically <1 ppm on modern hardware).
- Recommended sync interval: every 1–5 seconds for tight synchronization, or every 8–16 beats for musical synchronization.

**What you need to build:**
- A server-side authoritative tick source (any clock you trust).
- A transport (RemoteEvent, WebSocket, MessagingService, etc.).
- A client-side call to `syncFromServer()` when messages arrive.

## 5. Resolution: Why 8 Ticks Per Beat?

8 ticks per beat = 32nd-note resolution. This is the standard MIDI resolution for fine-grained musical timing.

| Resolution | Ticks/Beat | Grid Unit | At 120 BPM |
|-----------|-----------|-----------|------------|
| Quarter note | 1 | Beat | 500 ms |
| Eighth note | 2 | 1/8 | 250 ms |
| 16th note | 4 | 1/16 | 125 ms |
| **32nd note** | **8** | **1/32** | **62.5 ms** |
| 64th note | 16 | 1/64 | 31.25 ms |

32nd-note resolution (62.5ms at 120 BPM) is finer than human perception of timing accuracy (~30–50ms window for "on the beat" in rhythm games), while keeping tick counts manageable for long sessions:

- At 120 BPM with 8 ticks/beat: **576,000 ticks per hour**
- A `uint32` holds 4,294,967,295 → ~7,456 hours of continuous operation

## 6. Thread Safety

BeatClock is safe for **single-threaded Luau** (the Roblox execution model). All mutations happen synchronously. There are no coroutines, no deferred execution, no shared mutable state beyond the module table.

If multiple `Heartbeat` connections read the clock in the same frame, they all see the same values (no mutation happens between reads in a query-only context).

`setBPM()` and `syncFromServer()` mutate the state table. These should be called from a single authoritative source (your game logic or server sync handler), not from multiple competing callers.

## 7. Design Decisions

### No built-in events/signals

BeatClock deliberately avoids `RBXScriptSignal` or custom signal implementations. Reasons:
- **Polling is simpler** — one `Heartbeat` connection, cache the result.
- **Zero allocation** — signals would create closures, connections, and GC pressure.
- **Flexibility** — consumers decide their own update frequency and scheduling.

If you want beat-triggered events, wrap it:

```lua
local lastBeat = -1
local function onBeat(callback)
    RunService.Heartbeat:Connect(function()
        local beat = math.floor(BeatClock.getCurrentBeat())
        if beat ~= lastBeat then
            lastBeat = beat
            callback(beat)
        end
    end)
end
```

### No Instance dependency

BeatClock never touches the DataModel. It works in any context: client, server, plugin, command bar, headless tests. This makes it trivially testable and portable.

### `os.clock()` over alternatives

| Clock | Resolution | Monotonic | Context | Verdict |
|-------|-----------|-----------|---------|---------|
| `os.clock()` | ~µs | Yes | Process | ✅ Best choice |
| `tick()` | ~ms | Yes-ish | Session | Lower resolution |
| `os.time()` | 1s | No (wall) | Epoch | Too coarse |
| `workspace:GetServerTimeNow()` | ~ms | Yes | Server | Network round-trip |

### Module table as state

The module table doubles as the state record. This avoids creating a separate state object, which would require either a metatable wrapper or returning a constructor. Direct table access (`BeatClock.bpm`) is the simplest possible API for a singleton clock.

## 8. Testing Strategy

BeatClock is testable without Roblox by mocking `os.clock()`:

```lua
-- Pseudo-test
local mockClock = 0
local _osClock = os.clock
os.clock = function() return mockClock end

BeatClock.init(120)
assert(BeatClock.getCurrentTick() == 0)

mockClock = 0.5  -- advance 500ms
-- At 120 BPM, tickDuration = 60/(120*8) = 0.0625s
-- Ticks elapsed = 0.5 / 0.0625 = 8 → beat 1.0
assert(BeatClock.getCurrentTick() == 8)
assert(BeatClock.getCurrentBeat() == 1.0)

os.clock = _osClock
```

For Roblox-native testing, use [roblox-ts](https://roblox-ts.com/) with Jest or [TestEz](https://github.com/Roblox/testez).

## 9. Extension Points

BeatClock is designed to be extended, not modified:

| Extension | How |
|-----------|-----|
| **Beat events** | Wrap `getCurrentBeat()` in a `Heartbeat` loop with change detection. |
| **Server authority** | Call `syncFromServer()` from your transport layer. |
| **Musical bars** | `bar = math.floor(beat / 4) + 1` |
| **Swing/groove** | Offset tick boundaries by a swing factor before scheduling. |
| **Pattern sequencing** | Use `beat % patternLength` to index a pattern table. |
| **Audio scrubbing** | Map `getCurrentBeat()` to a `Sound.TimePosition` for seeking. |
| **Visual sync** | Feed `beat % 1` (phase) into tweens or shader parameters. |

## 10. Limitations

- **No built-in networking** — you provide the transport for multi-client sync.
- **Single clock instance** — the module is a singleton. For multiple independent clocks, instantiate separate module copies.
- **No swing** — straight subdivision only. Add swing in your scheduling layer.
- **No time signature** — always 4/4 implied. Time signatures are a presentation concern; compute them from beats.
- **`os.clock()` resets on process restart** — the clock is session-scoped, not persistent. For persistence, store `getCurrentTick()` and feed it back via `syncFromServer()` on resume.
