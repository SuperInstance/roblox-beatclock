# docs/ — BeatClock Documentation

## Documents

### [`user-guide.md`](./user-guide.md)
A 12-section beginner-friendly walkthrough covering installation, first clock, ticks and beats, reading the clock, changing tempo, reacting to beats, server sync, unit conversion, note durations, a full combined example, and troubleshooting. Start here if you're new to musical timing in Roblox.

### [`engineering-manual.md`](./engineering-manual.md)
Internal architecture document for contributors and deep-divers. Covers:

- **The anchor model** — reference-point derivation, why `os.clock()`, why `floor` on ticks
- **Tempo changes** — re-anchoring mechanics, mid-beat edge cases
- **Server synchronization** — drift characteristics, recommended sync intervals, what you need to build
- **Resolution** — why 8 ticks/beat (32nd-note grid), comparison table, overflow analysis (uint32 → 7,456 hours)
- **Thread safety** — single-threaded Luau guarantees, mutation guidelines
- **Design decisions** — no built-in events (poll instead), no Instance dependency, module table as state
- **Testing strategy** — mock `os.clock()` for deterministic verification
- **Extension points** — beat events, swing, pattern sequencing, audio scrubbing, visual sync
- **Limitations** — no networking, singleton clock, no swing, 4/4 implied

## For Contributors

See also [`CONTRIBUTING.md`](../CONTRIBUTING.md) for code style, design principles, and submission guidelines.

**Core principles (don't violate these in PRs):**
1. Stateless queries — compute fresh from `os.clock()`, never accumulate
2. Zero allocations on query — no tables, no closures, no GC
3. No built-in events — consumers poll on Heartbeat

## The Design Philosophy

BeatClock's documentation follows the **excavator lever principle**: a reader builds intuition through metaphor. They don't need the inside of the machine to master the controls. The user guide teaches you what the levers do. The engineering manual shows you the hydraulics. Both are valid ways to understand the same machine.

## Fleet Documentation Connections

- [AI-Writings](https://github.com/SuperInstance/AI-Writings/tree/main/prose) — Fleet stories and essays about the Orchestra and Navigator's Equation
- [fleet-wiki](https://github.com/SuperInstance/fleet-wiki) — D1-backed fleet knowledge base, 700+ pages
- [roblox-bond-system](https://github.com/SuperInstance/roblox-bond-system) docs — The bond system integrates with BeatClock timing
- [roblox-filtergate](https://github.com/SuperInstance/roblox-filtergate) docs — Content filtering for the same fleet
- [cns-bridge](https://github.com/SuperInstance/cns-bridge) — Timing signals flow through the CNS bus
- [tensor-midi](https://github.com/SuperInstance/tensor-midi) — The jazz lattice cousin

---

← Back to [BeatClock](../README.md)
