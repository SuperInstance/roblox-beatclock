# docs/ — BeatClock Documentation

> *The ship's manual. Everything worth knowing about the chronometer.*

## Documents

| File | Description |
|------|-------------|
| [`user-guide.md`](user-guide.md) | Beginner-friendly walkthrough: install, first clock, understanding ticks and beats, reading the clock, changing tempo, reacting to beats, server sync, unit conversion, note durations, troubleshooting |
| [`engineering-manual.md`](engineering-manual.md) | Architecture overview, the anchor model, tempo changes, server synchronization, resolution rationale, thread safety, design decisions, testing strategy, extension points, limitations |

## When to Read What

- **Just getting started?** Read the [User Guide](user-guide.md). It walks through every feature with copy-paste examples.
- **Need to understand internals?** Read the [Engineering Manual](engineering-manual.md). It covers the anchor model, drift math, and why `os.clock()` over alternatives.
- **Looking for the API?** See the [main README](../README.md#full-api-reference).

---

[← Back to BeatClock](../README.md)
