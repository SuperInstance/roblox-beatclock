# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-08-04

### Added
- `BeatClock.init(bpm?)` — initialize with optional BPM (default 72 Andante)
- `BeatClock.setBPM(bpm)` — change tempo mid-session, preserving tick position via re-anchoring
- `BeatClock.syncFromServer(serverTick, bpm?)` — synchronize from an authoritative server clock
- `BeatClock.getBPM()` — current tempo
- `BeatClock.getCurrentTick()` — integer tick count derived from wall-clock time
- `BeatClock.getCurrentBeat()` — float beat position
- `BeatClock.tickToBeat(tick)` / `BeatClock.beatToTick(beat)` — unit conversion
- `BeatClock.elapsed()` — wall-clock seconds since anchor
- `BeatClock.tickDuration()` — seconds per tick at current tempo
- `BeatClock.get32ndNoteDuration()` — seconds per 32nd note (alias of tickDuration)
- Engineering manual documenting the anchor model, drift characteristics, and extension points
- User guide with 12 sections covering installation through troubleshooting
- Two example scripts: basic metronome, dance floor with tempo changes
- MIT license
