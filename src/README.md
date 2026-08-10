# src/ — BeatClock Source

> *One file. One plank. One hull.*

This directory contains the entire BeatClock module — a single Luau file with zero dependencies.

## Files

| File | Description |
|------|-------------|
| [`BeatClock.lua`](BeatClock.lua) | The complete module — ~130 lines, under 4 KB |

## Architecture

The module is a **singleton table** that doubles as its own state record:

```
BeatClock.bpm           — current tempo
BeatClock.ticksPerBeat  — constant: 8 (32nd-note resolution)
BeatClock.startTick     — reference tick at anchor point
BeatClock.startTime     — os.clock() reading at anchor point
```

All queries derive from these four values. There are no closures, no metatables, no instances. The module table IS the ship.

See the [Engineering Manual](../docs/engineering-manual.md) for the full architecture discussion.

---

[← Back to BeatClock](../README.md)
