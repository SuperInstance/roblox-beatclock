# tests/ — BeatClock Test Suite

Tests run outside of Roblox Studio using the custom [TestKit](../testkit/init.lua) framework, which mocks `os.clock()`, `typeof()`, and the Roblox `game` global.

> *Every beat that ever rings out falls exactly where one quiet equation said it would be, long before the sound reached your speakers.*
>
> — Seed Pro

## Files

| File | Focus | Tests |
|------|-------|-------|
| [`beatclock_test.lua`](./beatclock_test.lua) | Module structure, init, tick computation, BPM changes, beat detection, reset, measures | 15 |
| [`beatclock_extended_test.lua`](./beatclock_extended_test.lua) | Conversions, note durations, tempo preservation, server sync, edge cases, API completeness | 40+ |
| [`spec/BeatClock_spec.lua`](../spec/BeatClock_spec.lua) | TestEZ-format spec for Roblox-native runners | 30+ |

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

This is the shop teacher's approach: you don't test a level by checking if the bubble moved. You check if the surface is flat. Mock the clock, advance it to known positions, verify the tick lands where the equation says it should. Every test is a surveyor's stake — a known point where the math must hold.

### What the Tests Prove

| Property | How |
|----------|-----|
| **Tick derivation** | Set mock time, assert exact tick values |
| **Tempo continuity** | Change BPM mid-run, verify tick doesn't jump |
| **Server sync** | Inject server tick, verify anchor resets |
| **Edge case robustness** | Feed zero, negative, nil, NaN, string — all silently rejected |
| **Round-trip conversion** | tick→beat→tick is identity for multiples of 8 |
| **API completeness** | All 14 exported functions exist and are callable |

## Fleet Testing Connections

- [roblox-bond-system](https://github.com/SuperInstance/roblox-bond-system) tests — 63 Lua tests using the same TestKit philosophy
- [roblox-filtergate](https://github.com/SuperInstance/roblox-filtergate) tests — 90 Lua tests, the fleet's most thoroughly tested Roblox module
- [cns-bridge](https://github.com/SuperInstance/cns-bridge) — 270 Python tests, the fleet's most rigorous test suite
- [voxel-logic](https://github.com/SuperInstance/voxel-logic) — 99.7% test coverage, the gold standard

---

← Back to [BeatClock](../README.md)
