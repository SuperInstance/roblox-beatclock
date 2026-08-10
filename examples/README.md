# examples/ — BeatClock Working Scripts

> *Drop them in Studio. Watch them run.*

Every example is a complete `LocalScript` you can place in `StarterPlayerScripts` and see results immediately.

## Examples

| File | What It Does |
|------|-------------|
| [`basic-metronome.lua`](basic-metronome.lua) | Clicks on every beat. The simplest possible use of BeatClock. |
| [`synced_lights.lua`](synced_lights.lua) | Ring of 8 light poles that flash on downbeats, dim-pulse on other beats, and shimmer on the 32nd-note grid. Handles tempo changes seamlessly. |
| [`dance-floor.lua`](dance-floor.lua) | Neon dance floor with HSV color cycling, spotlight sweeps, and mid-song tempo shifts (128→140→100 BPM). |
| [`music_sync.lua`](music_sync.lua) | Multi-track music system: switches between exploration, combat, and settlement tracks on measure boundaries. Includes beat-indicator UI. |

## Patterns Demonstrated

- **Beat polling:** `math.floor(BeatClock.getCurrentBeat())` with a `lastBeat` cache
- **Downbeat detection:** `beat % 4 == 0`
- **Tempo changes:** `BeatClock.setBPM()` — seamless mid-song
- **32nd-note scheduling:** `BeatClock.getCurrentTick()` for fine-grained effects
- **Server sync:** `BeatClock.syncFromServer()` integration point
- **Tween timing:** Using `BeatClock.tickDuration()` to set animation durations musically

## How to Use

1. Install BeatClock per the [Quick Start](../README.md#installation) instructions.
2. Copy any example into a `LocalScript` in `StarterPlayerScripts`.
3. Run the game.

---

[← Back to BeatClock](../README.md)
