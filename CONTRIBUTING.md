# Contributing to BeatClock

Thanks for your interest in improving BeatClock!

## Getting Started

1. **Fork & clone** the repo
2. Install [Rojo](https://rojo.space) for Studio sync
3. Run `rojo serve` to test changes in Studio

## Development Workflow

```bash
rojo serve  # live sync to Studio
```

### Running Tests

Tests live in `spec/` and use the [TestEZ](https://github.com/Roblox/testez) format. Tests mock `os.clock()` to verify tick computation deterministically.

### Code Style

- **Luau type annotations** on all public functions
- **Doc comments** (`--[[ ... ]]`) on every exported method
- **camelCase** for function names
- Keep the module **zero-dependency, zero-Instance** — pure data
- Never add background threads or RunService loops — polling is the consumer's job

## Design Principles

BeatClock follows three core principles:

1. **Stateless queries** — every call to `getCurrentTick()` computes from `os.clock()` fresh; no accumulation, no drift
2. **Zero allocations on query** — no tables, no closures, no GC pressure
3. **No built-in events** — consumers poll on Heartbeat and do their own change detection

If your contribution adds background work, event signals, or Instance creation, it will likely be rejected. Wrap, don't embed.

## Adding Functionality

If you need beat events, server sync, or pattern scheduling, build it as a **wrapper module** that requires BeatClock:

```lua
local BeatClock = require(ReplicatedStorage.BeatClock)
local BeatScheduler = {}
-- Your wrapper code here, using BeatClock.getCurrentBeat()
```

## Submitting Changes

1. Feature branch: `git checkout -b feat/your-feature`
2. Test with `spec/BeatClock_spec.lua`
3. Clear commit messages
4. Open a PR

## Reporting Bugs

Include:
- BPM at time of issue
- Whether `setBPM()` or `syncFromServer()` was called
- Time since `init()`
- Expected vs. actual tick/beat value

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
