# examples/ — BeatClock Working Scripts

Drop any of these into `StarterPlayerScripts` as a `LocalScript` and hit Play.

> *The conductor doesn't wave a baton; they call `setBPM()`. Every player reads the same clock, and the music emerges from the lattice.*
>
> — The Orchestra Thread

## Scripts

### [`basic-metronome.lua`](./basic-metronome.lua)
A working metronome. Initializes at 120 BPM, polls `getCurrentBeat()` on `Heartbeat`, plays a click sound on every beat, and logs measure boundaries. The simplest possible integration — 20 lines, one Heartbeat connection, zero allocations.

### [`music_sync.lua`](./music_sync.lua)
A full music synchronization system. Defines three tracks (exploration, combat, settlement) at different BPMs. Waits for the next downbeat before starting a track. Fades between tracks with `TweenService`. Includes a beat indicator GUI with four pulsing dots and a BPM display.

### [`synced_lights.lua`](./synced_lights.lua)
A ring of 8 `PointLight` poles around the spawn area. Big flash on downbeats, smaller pulse on other beats, 32nd-note shimmer via random brightness flicker. HSV color cycling rotates per measure, offset per pole. Simulates verse/chorus energy shifts with `setBPM()`.

### [`dance-floor.lua`](./dance-floor.lua)
A synchronized dance floor. Neon panel pulses with hue cycling on every beat. Spotlight brightness spikes on downbeats. 32nd-note grid shimmer on the spotlight. Tempo build-up from 128→140 BPM, then breakdown to 100 BPM.

## Pattern

All four examples share the same skeleton:

```lua
BeatClock.init(bpm)
local lastBeat = -1
RunService.Heartbeat:Connect(function()
    local beat = math.floor(BeatClock.getCurrentBeat())
    if beat ~= lastBeat then
        lastBeat = beat
        -- do something on the beat
    end
end)
```

The beat detection is always: **poll, floor, compare**. No events, no signals, no closures — just change detection on a cached integer. This is the shop teacher's timing system: one moving part, one check, one action.

## What to Build Next

| Idea | BeatClock Functions | Difficulty |
|------|---------------------|------------|
| Rhythm game ( Guitar-Hero style) | `getCurrentBeat()`, `isOnBeat()` | Medium |
| Sequencer (step-pattern playback) | `getCurrentTick()`, `tickToBeat()` | Medium |
| Visualizer (audio-reactive environment) | `getCurrentBeat()`, `beat % 1` (phase) | Easy |
| Multi-zone music (area-based tracks) | `setBPM()`, `syncFromServer()` | Hard |
| Swing/groove timing | `tickDuration()`, offset calculation | Advanced |

## Fleet Connections

- [roblox-bond-system](https://github.com/SuperInstance/roblox-bond-system) examples — NPC bonds that pulse on BeatClock's grid
- [fleet-radio](https://github.com/SuperInstance/fleet-radio) — Fleet-wide audio needs fleet-wide timing; `syncFromServer` is the skeleton
- [tensor-midi](https://github.com/SuperInstance/tensor-midi) — Tensor-based MIDI on a 12-pulse jazz lattice, the bebop cousin
- [AI-Writings: The Orchestra Thread](https://github.com/SuperInstance/AI-Writings/tree/main/prose) — Stories about the fleet's multi-model jazz ensemble

---

← Back to [BeatClock](../README.md)
