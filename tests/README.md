# tests/ — BeatClock Test Suite

Tests run outside of Roblox Studio using the custom [TestKit](../testkit/init.lua) framework, which mocks `os.clock()`, `typeof()`, and the Roblox `game` global.

## Files

| File | Focus | Key Tests |
|------|-------|-----------|
| [`beatclock_test.lua`](./beatclock_test.lua) | Module structure, init, tick computation, BPM changes, beat detection, reset, measures | Default BPM fallback, tick advancement at different tempos, `isOnBeat()` booleans, `getCurrentMeasure()` |
| [`beatclock_extended_test.lua`](./beatclock_extended_test.lua) | Conversions, note durations, tempo preservation, server sync, edge cases, API completeness | Round-trip `tick↔beat` conversion, `setBPM` tick continuity, NaN/zero/negative/string rejection, full API surface audit |

## Running

```bash
LUA_PATH="?.lua;testkit/?.lua;?/init.lua" lua5.1 tests/beatclock_test.lua
```

## Strategy

Tests mock `os.clock()` for deterministic timing — set the clock, advance it, assert the tick. No real-time delays, no flaky tests. The mock is a simple closure:

```lua
local mockTime = 0
os.clock = function() return mockTime end
```

The spec file ([`spec/BeatClock_spec.lua`](../spec/BeatClock_spec.lua)) uses TestEZ-format assertions for Roblox-native test runners.

---

← Back to [BeatClock](../README.md)
