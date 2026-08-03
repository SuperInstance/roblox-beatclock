# BeatClock

**A musical timing system for Roblox.**

BeatClock gives you a BPM-accurate clock that knows exactly where you are in the music — ticks, beats, and note durations — so you can synchronize gameplay, visuals, audio, and events to a shared tempo.

---

## Why BeatClock?

Roblox gives you `os.clock()` and `RunService.Heartbeat`. Those tell you *wall-clock time*. They don't tell you *musical time*.

BeatClock bridges that gap. With it, you can:

- **Schedule events on a musical grid** — "fire this effect on beat 17" instead of "fire this effect in 1.33 seconds."
- **Sync visuals to audio** — pulse lights, animate UI, and trigger particles exactly on the beat.
- **Change tempo smoothly** — ramp from 90 to 128 BPM mid-song without jumps or stutters.
- **Coordinate server and client** — sync multiple clients to a shared authoritative clock via your own transport (RemoteEvents, WebSockets, etc.).
- **Build rhythm mechanics** — detect if a player pressed a button on-beat or off-beat.

All in a single, dependency-free Luau module weighing **under 4 KB**.

---

## Installation

### Option A — Rojo (recommended)

1. Copy the `src/BeatClock.lua` file into your project's `ReplicatedStorage`.
2. Or clone this repo and symlink it:

```bash
git clone https://github.com/lucineer/roblox-beatclock.git
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

1. Open `src/BeatClock.lua`.
2. Copy the entire contents.
3. In Roblox Studio, create a `ModuleScript` named `BeatClock` inside `ReplicatedStorage`.
4. Paste the code in.

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

## How It Works

BeatClock is a **tick counter driven by wall-clock time**. Here's the mental model:

```
                  ticksPerBeat = 8
       beat 0     beat 1     beat 2     beat 3
      |---------|---------|---------|---------|
      0 1 2 3 4 5 6 7 8 9 ...

      ^tick    ^tick     ^beat     ^measure
      (32nd)   (quarter)  boundary   boundary
```

- A **tick** is the smallest unit of musical time (1/8 of a beat = a 32nd note).
- A **beat** is a quarter note (what you tap your foot to).
- **BPM** (beats-per-minute) sets the speed. At 120 BPM, one beat = 0.5 seconds.

BeatClock maintains a reference point (tick + timestamp) and derives the current tick from elapsed time on every query. When you change BPM, it re-anchors to preserve position — no jumps.

---

## Full API Reference

### `BeatClock.init(bpm: number?)`

Initialize the clock at a given tempo. Sets the reference point (tick 0, now).

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `bpm` | `number?` | `72` | Starting tempo in beats-per-minute. |

**Returns:** nothing.

```lua
BeatClock.init(128)       -- start at 128 BPM
BeatClock.init()          -- start at default 72 BPM
```

---

### `BeatClock.setBPM(bpm: number)`

Change the tempo while preserving the current tick position. The clock re-anchors internally so there are no jumps.

| Parameter | Type | Description |
|-----------|------|-------------|
| `bpm` | `number` | New tempo. Must be > 0. Invalid values are silently ignored. |

**Returns:** nothing.

```lua
BeatClock.setBPM(140)     -- speed up to 140 BPM
```

---

### `BeatClock.syncFromServer(serverTick: number, bpm: number?)`

Synchronize from an authoritative server clock. Re-anchors the local clock to match the server's tick value at the current moment.

Use this when you have a server-side source of truth (WebSocket relay, RemoteEvent, Durable Object, etc.) and want clients to stay aligned.

| Parameter | Type | Description |
|-----------|------|-------------|
| `serverTick` | `number` | The authoritative tick from the server. |
| `bpm` | `number?` | Optional tempo update alongside the sync. |

**Returns:** nothing.

```lua
-- On receiving a sync message from your server:
BeatClock.syncFromServer(serverTickValue, 120)
```

---

### `BeatClock.getBPM()`

**Returns:** `number` — the current tempo in beats-per-minute.

```lua
local tempo = BeatClock.getBPM()   -- e.g. 128
```

---

### `BeatClock.getCurrentTick()`

The core computation. Derives the current tick from elapsed wall-clock time since the reference point.

**Returns:** `number` — integer tick count. Always increases monotonically.

```lua
local tick = BeatClock.getCurrentTick()   -- e.g. 1024
```

---

### `BeatClock.getCurrentBeat()`

Returns the current beat position as a float. Whole numbers are downbeats; fractional parts are the position within the beat.

**Returns:** `number` — beat position.

```lua
local beat = BeatClock.getCurrentBeat()   -- e.g. 42.5 (halfway through beat 43)
```

---

### `BeatClock.tickToBeat(tick: number)`

Converts a raw tick value to its beat equivalent.

| Parameter | Type | Description |
|-----------|------|-------------|
| `tick` | `number` | Any tick value. |

**Returns:** `number` — beat position.

```lua
local beat = BeatClock.tickToBeat(20)   -- 2.5
```

---

### `BeatClock.beatToTick(beat: number)`

Converts a beat value to its nearest tick (floored to integer).

| Parameter | Type | Description |
|-----------|------|-------------|
| `beat` | `number` | Any beat value. |

**Returns:** `number` — tick position.

```lua
local tick = BeatClock.beatToTick(2.5)   -- 20
```

---

### `BeatClock.elapsed()`

Wall-clock seconds since the clock was initialized, last sync'd, or last had a tempo change.

**Returns:** `number` — seconds.

```lua
local sec = BeatClock.elapsed()   -- e.g. 34.7
```

---

### `BeatClock.tickDuration()`

Duration of a single tick at the current tempo.

**Returns:** `number` — seconds per tick.

```lua
local dur = BeatClock.tickDuration()   -- at 120 BPM: 0.0625s
```

---

### `BeatClock.get32ndNoteDuration()`

Duration of a 32nd note at the current tempo. Equivalent to `tickDuration()` since the tick resolution is 8 per beat.

**Returns:** `number` — seconds per 32nd note.

```lua
local dur = BeatClock.get32ndNoteDuration()   -- at 120 BPM: 0.0625s
```

---

## Examples

### 1. Basic Beat Scheduling

Fire an event on every beat:

```lua
local lastBeat = -1

RunService.Heartbeat:Connect(function()
    local beat = math.floor(BeatClock.getCurrentBeat())
    if beat ~= lastBeat then
        lastBeat = beat
        print("Beat:", beat)
        -- trigger your event here
    end
end)
```

### 2. Synchronizing Audio to a Tempo

Start music and keep visuals locked to it:

```lua
BeatClock.init(128)

local music = Instance.new("Sound")
music.SoundId = "rbxassetid://YOUR_AUDIO_ID"
music.Parent = workspace
music:Play()

-- Pulse a neon part on every beat
local neonPart = workspace.NeonPanel
local lastBeat = -1

RunService.Heartbeat:Connect(function()
    local beat = math.floor(BeatClock.getCurrentBeat())
    if beat ~= lastBeat then
        lastBeat = beat
        neonPart.Material = Enum.Material.Neon
        task.delay(0.05, function()
            neonPart.Material = Enum.Material.Plastic
        end)
    end
end)
```

### 3. Creating a Metronome UI

Display the current beat in a ScreenGui:

```lua
BeatClock.init(120)

local screen = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
local label = Instance.new("TextLabel", screen)
label.Size = UDim2.fromScale(0.2, 0.1)
label.Position = UDim2.fromScale(0.4, 0.05)
label.Font = Enum.Font.GothamBold
label.TextScaled = true

local lastBeat = -1

RunService.Heartbeat:Connect(function()
    local beat = math.floor(BeatClock.getCurrentBeat())
    if beat ~= lastBeat then
        lastBeat = beat
        local beatInMeasure = beat % 4 + 1
        label.Text = tostring(beatInMeasure)

        -- Highlight downbeat
        if beatInMeasure == 1 then
            label.TextColor3 = Color3.fromRGB(255, 80, 80)
        else
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end)
```

### 4. Building a Rhythm Game Mechanic

Detect if the player clicked on-beat:

```lua
BeatClock.init(140)

local HIT_WINDOW = 0.15  -- ±150ms tolerance

local function onPlayerClicked()
    local beatProgress = BeatClock.getCurrentBeat() % 1
    -- Distance to nearest beat boundary
    local offset = math.min(beatProgress, 1 - beatProgress)
    local secondsOff = offset * (60 / BeatClock.getBPM())

    if secondsOff < HIT_WINDOW then
        local rating = "PERFECT"
        if secondsOff > 0.05 then rating = "GOOD" end
        print("Hit! " .. rating .. " (off by " .. string.format("%.0fms", secondsOff * 1000) .. ")")
    else
        print("Miss (off by " .. string.format("%.0fms", secondsOff * 1000) .. ")")
    end
end

-- Wire up your input here
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        onPlayerClicked()
    end
end)
```

### 5. Day/Night Cycle Synced to Musical Time

Drive a lighting cycle from the beat clock:

```lua
BeatClock.init(80)  -- slow tempo for ambient world

local BEATS_PER_CYCLE = 64  -- 16 measures per full cycle
local Lighting = game:GetService("Lighting")

RunService.Heartbeat:Connect(function()
    local beat = BeatClock.getCurrentBeat()
    local cycleProgress = (beat % BEATS_PER_CYCLE) / BEATS_PER_CYCLE

    -- Map progress (0-1) to a full day cycle (0h - 24h)
    local hours = cycleProgress * 24

    -- Set ClockTime (0-24)
    Lighting.ClockTime = hours

    -- Adjust brightness
    local isDay = hours > 6 and hours < 18
    Lighting.Brightness = isDay and 2 + math.sin((hours - 6) / 12 * math.pi) * 1
                         or 0.3
end)
```

---

## Performance Notes

BeatClock is **extremely lightweight**:

- **No allocations on query.** `getCurrentTick()` does arithmetic and a `math.floor`. No tables, no closures.
- **No RunService loops built-in.** You decide when to poll. BeatClock never runs background work.
- **No instances created.** Pure data — no Roblox objects, no signals, no garbage collection pressure.
- **Memory footprint:** ~4 fields on the module table. Under 200 bytes of state.
- **Resolution:** 8 ticks per beat (32nd-note grid). At 120 BPM, that's 7.5ms per tick — well within frame budget.

**Recommendation:** Poll on `RunService.Heartbeat` (client) or `RunService.Stepped` (server) and cache the result if you need it multiple times per frame.

---

## Compatibility

- **Roblox Studio** — Luau (Roblox's Lua 5.1 + extensions)
- **Runtime:** Client, Server, and Plugin contexts
- **No external dependencies** — single file, zero requires
- **Luau type annotations** included (`number?`, `: number`) — works with type checking enabled or disabled

---

## License

[MIT](LICENSE) — free for personal and commercial use.
