# tests/ — BeatClock Test Suite

> *Sea trials. Every plank stressed, every joint tested.*

## Test Files

| File | Framework | What It Covers |
|------|-----------|----------------|
| [`beatclock_test.lua`](beatclock_test.lua) | [TestKit](../testkit/init.lua) | Module structure, init, tick computation, BPM changes, beat detection, reset, measure tracking |
| [`beatclock_extended_test.lua`](beatclock_extended_test.lua) | [TestKit](../testkit/init.lua) | Conversion round-trips, note durations, setBPM tick preservation, server sync, elapsed, isOnBeat, edge cases, API completeness |

## Running Tests

```bash
LUA_PATH="?.lua;testkit/?.lua;?/init.lua" lua5.1 tests/beatclock_test.lua
LUA_PATH="?.lua;testkit/?.lua;?/init.lua" lua5.1 tests/beatclock_extended_test.lua
```

## Testing Strategy

Tests mock `os.clock()` to control time deterministically:

```lua
local mockTime = 0
os.clock = function() return mockTime end

BeatClock.init(120)
mockTime = 0.5  -- advance 500ms
-- At 120 BPM: tickDuration = 0.0625s → 8 ticks elapsed → beat 1.0
```

This means we can test any tempo, any duration, any drift scenario — without waiting in real time.

See also: [`spec/BeatClock_spec.lua`](../spec/BeatClock_spec.lua) for TestEZ-format tests.

---

[← Back to BeatClock](../README.md)
