# BeatClock — User Guide

A beginner-friendly walkthrough of every feature. By the end, you'll know how to add musical timing to any Roblox experience.

---

## Table of Contents

1. [What Is BeatClock?](#1-what-is-beatclock)
2. [Installing](#2-installing)
3. [Your First Clock](#3-your-first-clock)
4. [Understanding Ticks and Beats](#4-understanding-ticks-and-beats)
5. [Reading the Clock](#5-reading-the-clock)
6. [Changing Tempo](#6-changing-tempo)
7. [Reacting to Beats](#7-reacting-to-beats)
8. [Syncing with a Server](#8-syncing-with-a-server)
9. [Converting Between Units](#9-converting-between-units)
10. [Note Durations](#10-note-durations)
11. [Putting It All Together](#11-putting-it-all-together)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. What Is BeatClock?

BeatClock is a small Luau module that acts as a **musical stopwatch** for Roblox. Instead of counting seconds, it counts **beats** and **ticks** — the same units musicians use.

Imagine a metronome. It clicks at a steady rate — say, 120 clicks per minute. Each click is a **beat**. Between each click, there are tiny subdivisions called **ticks** (8 of them per beat, matching 32nd notes in music).

BeatClock keeps track of where you are in that stream of clicks and ticks, so you can say things like:

- "Pulse this light on beat 17."
- "Is the player pressing the button on a beat?"
- "How many milliseconds until the next 32nd note?"

All from a single module with zero dependencies.

---

## 2. Installing

### With Rojo

If you use Rojo (and you should!), just point your project file at the module:

```json
{
  "ReplicatedStorage": {
    "BeatClock": {
      "$path": "path/to/roblox-beatclock/src/BeatClock.lua"
    }
  }
}
```

### Without Rojo

1. Open Roblox Studio.
2. In the Explorer, find **ReplicatedStorage**.
3. Right-click → **Insert Object** → **ModuleScript**.
4. Name it `BeatClock`.
5. Open `src/BeatClock.lua` from this repo and copy everything in.
6. Paste it into the ModuleScript.

Done!

---

## 3. Your First Clock

Create a `LocalScript` in **StarterPlayerScripts**:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BeatClock = require(ReplicatedStorage:WaitForChild("BeatClock"))

BeatClock.init(120)

while true do
    print("Beat:", BeatClock.getCurrentBeat())
    task.wait(0.5)
end
```

Run the game. You'll see the beat number climbing: 0, 1, 2, 3, 4...

**Congratulations** — you have a musical clock running.

---

## 4. Understanding Ticks and Beats

BeatClock uses two units of musical time:

| Unit | What it is | Example |
|------|-----------|---------|
| **Beat** | A quarter note — what you tap your foot to | Beat 42 |
| **Tick** | 1/8 of a beat — a 32nd note | Tick 336 (which is beat 42) |

At **120 BPM**:
- One beat = 0.5 seconds
- One tick = 0.0625 seconds (62.5ms)
- Eight ticks fit in one beat

Think of it like a ruler:
```
Beat:  |←── 0 ──→|←── 1 ──→|←── 2 ──→|
Tick:  |0|1|2|3|4|5|6|7|0|1|2|3|4|5|6|7|0|...
```

You can always convert between the two:

```lua
BeatClock.beatToTick(2.5)   -- → 20 (the 20th tick)
BeatClock.tickToBeat(20)    -- → 2.5 (halfway through beat 3)
```

---

## 5. Reading the Clock

BeatClock has four "where am I?" functions:

```lua
-- Where am I in tick space? (integer)
local tick = BeatClock.getCurrentTick()     -- e.g. 336

-- Where am I in beat space? (float)
local beat = BeatClock.getCurrentBeat()     -- e.g. 42.0

-- How long since I started? (seconds)
local sec = BeatClock.elapsed()            -- e.g. 21.0

-- What's my tempo?
local bpm = BeatClock.getBPM()             -- e.g. 120
```

**Tip:** In a `Heartbeat` loop, call `getCurrentBeat()` once and cache it:

```lua
RunService.Heartbeat:Connect(function()
    local beat = BeatClock.getCurrentBeat()
    -- use `beat` for everything this frame
end)
```

---

## 6. Changing Tempo

You can change BPM at any time without jumps or stutters:

```lua
BeatClock.init(100)          -- start slow
task.wait(10)
BeatClock.setBPM(140)        -- speed up — current beat position is preserved
task.wait(10)
BeatClock.setBPM(80)         -- slow down
```

When you call `setBPM()`:
1. BeatClock captures the current tick.
2. It re-anchors the clock to that exact moment.
3. Future ticks are computed at the new speed.

There's no gap, no jump, no accumulated error. The tempo change is seamless.

**Common use cases:**
- **Build-ups:** gradually increase BPM during a music drop.
- **Dynamic music:** match gameplay intensity (slow for calm areas, fast for combat).
- **Transitions:** change tempo between scenes.

---

## 7. Reacting to Beats

BeatClock doesn't fire events on its own. Instead, you poll it in a `Heartbeat` loop and detect changes:

```lua
local RunService = game:GetService("RunService")
local lastBeat = -1

RunService.Heartbeat:Connect(function()
    local beat = math.floor(BeatClock.getCurrentBeat())

    if beat ~= lastBeat then
        lastBeat = beat

        -- This code runs once per beat
        print("Click! Beat", beat)

        -- Detect downbeat (first beat of a 4/4 measure)
        if beat % 4 == 0 then
            print("  ↳ Downbeat! Measure", math.floor(beat / 4) + 1)
        end
    end
end)
```

**Why polling instead of events?**

1. It's simpler — one connection, one cache variable.
2. It's flexible — you decide what "on beat" means for your game.
3. It's zero-allocation — no closures, no signal connections, no GC.

You can wrap this pattern into a helper function:

```lua
local function onBeat(callback)
    local last = -1
    RunService.Heartbeat:Connect(function()
        local beat = math.floor(BeatClock.getCurrentBeat())
        if beat ~= last then
            last = beat
            callback(beat)
        end
    end)
end

-- Usage:
onBeat(function(beat)
    print("Beat:", beat)
end)
```

---

## 8. Syncing with a Server

If you have a server that tracks the authoritative musical position (e.g. a DJ system, a music game server, or a shared experience clock), you can sync clients to it:

```lua
-- Server sends sync data via RemoteEvent
local syncEvent = ReplicatedStorage:WaitForChild("MusicSync")

syncEvent.OnClientEvent:Connect(function(serverTick, bpm)
    BeatClock.syncFromServer(serverTick, bpm)
end)
```

On the server side:

```lua
-- Server tells clients where the clock is
while true do
    syncEvent:FireAllClients(BeatClock.getCurrentTick(), BeatClock.getBPM())
    task.wait(2)  -- sync every 2 seconds
end
```

After calling `syncFromServer()`:
- The client's clock matches the server's tick.
- Any drift is corrected.
- Tempo is updated if a new BPM is provided.

**How often should you sync?**
- **Every 1–2 seconds** for tight music sync (rhythm games, performances).
- **Every 4–8 beats** for casual sync (ambient worlds, shared day/night cycles).
- **On tempo changes** — always sync when the BPM changes.

---

## 9. Converting Between Units

BeatClock provides two conversion helpers:

### Beat → Tick

```lua
local tick = BeatClock.beatToTick(4.5)
-- → 36 (because 4.5 × 8 = 36)
```

### Tick → Beat

```lua
local beat = BeatClock.tickToBeat(36)
-- → 4.5 (because 36 / 8 = 4.5)
```

These are useful for:
- **Pattern scheduling:** "Start this pattern at beat 8" → convert to tick for precise timing.
- **Offset calculations:** "This note is 3 ticks after beat 4" → `BeatClock.beatToTick(4) + 3 = 35`.
- **UI display:** Convert ticks back to beats to show "Beat 4.2" to the player.

---

## 10. Note Durations

BeatClock can tell you the real-time duration of musical note values:

### Tick Duration

```lua
local dur = BeatClock.tickDuration()
-- At 120 BPM: 0.0625 seconds (62.5ms per tick)
```

### 32nd Note Duration

```lua
local dur = BeatClock.get32ndNoteDuration()
-- Same as tickDuration() — 0.0625s at 120 BPM
```

**Why would you use this?**

- **Tween timing:** Make a TweenService animation last exactly one 32nd note:
  ```lua
  local info = TweenInfo.new(BeatClock.get32ndNoteDuration())
  ```
- **Particle effects:** Emit particles on a musical grid:
  ```lua
  particleEmitter.Rate = 1 / BeatClock.get32ndNoteDuration()
  ```
- **Stagger animations:** Cascade UI elements one tick apart:
  ```lua
  for i, frame in ipairs(frames) do
      task.delay(i * BeatClock.tickDuration(), function()
          frame.Visible = true
      end)
  end
  ```

---

## 11. Putting It All Together

Here's a complete example combining tempo changes, beat detection, note durations, and visual effects:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local BeatClock = require(ReplicatedStorage:WaitForChild("BeatClock"))

-- Start the clock
BeatClock.init(100)

-- Create a pulsing part
local part = Instance.new("Part")
part.Anchored = true
part.Size = Vector3.new(4, 4, 4)
part.Position = Vector3.new(0, 5, 0)
part.Material = Enum.Material.Neon
part.Color = Color3.fromRGB(0, 150, 255)
part.Parent = workspace

-- Beat detection
local lastBeat = -1

RunService.Heartbeat:Connect(function()
    local beat = math.floor(BeatClock.getCurrentBeat())

    if beat ~= lastBeat then
        lastBeat = beat

        -- Pulse on every beat
        local pulseTime = BeatClock.tickDuration() * 4
        TweenService:Create(part, TweenInfo.new(0.1), {
            Size = Vector3.new(6, 6, 6),
        }):Play()

        task.delay(0.1, function()
            TweenService:Create(part, TweenInfo.new(pulseTime), {
                Size = Vector3.new(4, 4, 4),
            }):Play()
        end)

        -- Change color every measure (4 beats)
        if beat % 4 == 0 then
            local hue = (beat / 4 % 8) / 8
            part.Color = Color3.fromHSV(hue, 0.7, 1)
        end
    end
end)

-- Tempo change schedule
task.delay(8, function()
    print("Speeding up!")
    BeatClock.setBPM(140)
end)

task.delay(16, function()
    print("Slow down...")
    BeatClock.setBPM(80)
end)
```

---

## 12. Troubleshooting

### "The beat number jumps around / isn't consistent"

Make sure you're calling `math.floor(BeatClock.getCurrentBeat())` — the raw beat is a float. If you compare floats directly, tiny timing differences will cause flicker.

### "setBPM doesn't seem to work"

Check that you're passing a positive number. `setBPM(0)`, `setBPM(-1)`, or `setBPM(nil)` are silently ignored.

### "The clock starts at a weird number"

Did you call `BeatClock.init()`? Without initialization, the clock starts at the default 72 BPM with `startTime = 0`, which means `elapsed()` is huge and the tick count is very large.

### "Multiple clients are out of sync"

BeatClock is local to each client. For multi-client sync, you need a server authoritative clock calling `syncFromServer()` regularly. See [§8](#8-syncing-with-a-server).

### "Ticks are counting too fast / too slow"

Verify your BPM. At 120 BPM with 8 ticks/beat, you should see 960 ticks per minute (16 per second). At 72 BPM, you'll see 576 ticks per minute (9.6 per second).

### "Can I use this on the server?"

Yes! BeatClock works in server scripts too. The `os.clock()` call is available in all Luau contexts. For server-driven experiences, call `init()` on the server and broadcast sync updates to clients.

---

## Further Reading

- [Full API Reference](../README.md#full-api-reference) — every method with examples
- [Engineering Manual](./engineering-manual.md) — architecture, data flow, design decisions
- [Examples](../examples/) — working scripts you can drop into Studio

Happy composing! 🎵
