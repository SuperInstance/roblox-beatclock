--[[
    BeatClock — A musical timing system for Roblox.
    ──────────────────────────────────────────────────
    BeatClock provides BPM-accurate tick, beat, and note-duration
    queries for synchronizing gameplay, audio, visuals, and events
    to a shared musical clock.

    Features:
      ✓ Pure Luau, zero dependencies
      ✓ Sub-beat resolution (8 ticks per beat = 32nd-note grid)
      ✓ Smooth tempo changes that preserve tick position
      ✓ Optional server synchronization (bring your own transport)
      ✓ Tiny footprint — no RunService loops unless you want them

    Quick start:
        local BeatClock = require(ReplicatedStorage.BeatClock)
        BeatClock.init(120)
        print(BeatClock.getCurrentBeat())

    @author  Lucineer Project
    @license MIT
    @version 1.0.0
]]

local BeatClock = {}

-- ============================================================
--  Constants
-- ============================================================

local DEFAULT_BPM = 72
local TICKS_PER_BEAT = 8 -- 32nd-note resolution (8 ticks per quarter note)

-- ============================================================
--  Internal state
-- ============================================================

BeatClock.bpm = DEFAULT_BPM
BeatClock.ticksPerBeat = TICKS_PER_BEAT
BeatClock.startTick = 0
BeatClock.startTime = 0

-- ============================================================
--  Lifecycle
-- ============================================================

--[[
    Initialize the BeatClock at a given BPM.
    Sets the reference point for all tick computations.

    Call this once when your experience starts (e.g. in a client
    bootstrap script or when a scene loads).

    @param bpm number? — starting tempo in beats-per-minute.
                         Defaults to 72 (Andante).
]]
function BeatClock.init(bpm: number?)
    BeatClock.bpm = bpm or DEFAULT_BPM
    BeatClock.startTick = 0
    BeatClock.startTime = os.clock()
end

--[[
    Change the tempo while preserving the current tick position.
    The clock re-anchors so that tempo changes are seamless —
    no jumps, no skipped beats.

    @param bpm number — new tempo in beats-per-minute (must be > 0).
]]
function BeatClock.setBPM(bpm: number)
    if typeof(bpm) ~= "number" or bpm <= 0 then return end

    -- Capture current tick before changing tempo
    local currentTick = BeatClock.getCurrentTick()

    -- Re-anchor: the new reference point is (currentTick, now)
    BeatClock.startTick = currentTick
    BeatClock.startTime = os.clock()
    BeatClock.bpm = bpm
end

--[[
    Synchronize from an authoritative server tick.
    Useful when you have a server-side clock (e.g. a Durable Object,
    WebSocket relay, or RemoteEvent) and want clients to stay in sync.

    Call this whenever you receive a sync message from your server.

    @param serverTick number — the authoritative tick value from the server.
    @param bpm number? — optional BPM update alongside the sync.
]]
function BeatClock.syncFromServer(serverTick: number, bpm: number?)
    if typeof(serverTick) ~= "number" then return end

    BeatClock.startTick = serverTick
    BeatClock.startTime = os.clock()

    if bpm and typeof(bpm) == "number" and bpm > 0 then
        BeatClock.bpm = bpm
    end
end

-- ============================================================
--  Queries
-- ============================================================

--[[
    Returns the current tempo.

    @return number — beats-per-minute.
]]
function BeatClock.getBPM(): number
    return BeatClock.bpm
end

--[[
    Wall-clock seconds since the clock was initialized or last sync'd.
    This is raw elapsed time, not musical time.

    @return number — seconds since init / setBPM / syncFromServer.
]]
function BeatClock.elapsed(): number
    return os.clock() - BeatClock.startTime
end

--[[
    Duration of a single tick at the current tempo.

    @return number — seconds per tick.
]]
function BeatClock.tickDuration(): number
    return 60.0 / (BeatClock.bpm * BeatClock.ticksPerBeat)
end

--[[
    The current tick count, derived from elapsed wall-clock time
    since the reference point. Always increases monotonically.

    This is the core computation from which all other queries derive.

    @return number — integer tick count (floor of continuous value).
]]
function BeatClock.getCurrentTick(): number
    local elapsedSec = BeatClock.elapsed()
    local ticksElapsed = elapsedSec / BeatClock.tickDuration()
    return math.floor(BeatClock.startTick + ticksElapsed)
end

--[[
    The current beat position as a float.
    Whole numbers are downbeats; fractional parts are positions
    within the beat.

    Example: at 8 ticks/beat, tick 20 → beat 2.5 (middle of beat 3).

    @return number — beat position (float).
]]
function BeatClock.getCurrentBeat(): number
    return BeatClock.getCurrentTick() / BeatClock.ticksPerBeat
end

--[[
    Convert a tick value to its beat equivalent.

    @param tick number — tick position.
    @return number — beat position.
]]
function BeatClock.tickToBeat(tick: number): number
    return tick / BeatClock.ticksPerBeat
end

--[[
    Convert a beat value to its nearest tick.

    @param beat number — beat position.
    @return number — tick position (floored to integer).
]]
function BeatClock.beatToTick(beat: number): number
    return math.floor(beat * BeatClock.ticksPerBeat)
end

--[[
    Duration of a 32nd note at the current tempo.

    At 120 BPM → 0.0625 s
    At  90 BPM → 0.0833 s
    At  72 BPM → 0.1042 s

    Useful for scheduling fine-grained visual or audio events
    on a musical grid.

    @return number — seconds per 32nd note.
]]
function BeatClock.get32ndNoteDuration(): number
    return 60.0 / (BeatClock.bpm * 8)
end

return BeatClock
