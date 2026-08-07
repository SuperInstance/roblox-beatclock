-- tests/beatclock_extended_test.lua
-- Extended tests for BeatClock: conversion functions, edge cases,
-- server sync, tempo changes preserving tick position.
-- Overnight creative loop — the clock gets a full workout.

local testkit = require("testkit")
local expect = testkit.expect

-- Mock typeof for Luau compatibility
if not typeof then
    _G.typeof = function(v)
        local t = type(v)
        if t == "table" and v._robloxType then return v._robloxType end
        return t
    end
    rawset(_G, "typeof", _G.typeof)
end

-- Mock os.clock for deterministic testing
local mockTime = 0
os.clock = function() return mockTime end

local BeatClock = testkit.loadModule("/home/eileen/projects/roblox-beatclock/src/BeatClock.lua")

-- ============================================================
-- tickToBeat conversion tests
-- ============================================================
describe("tickToBeat", function()
    it("converts tick 0 to beat 0", function()
        expect(BeatClock.tickToBeat(0)):toBe(0)
    end)

    it("converts ticks to beats correctly", function()
        -- With ticksPerBeat = 8: tick 8 = beat 1
        expect(BeatClock.tickToBeat(8)):toBe(1)
        expect(BeatClock.tickToBeat(16)):toBe(2)
        expect(BeatClock.tickToBeat(32)):toBe(4)
    end)

    it("handles fractional tick positions", function()
        -- tick 4 = beat 0.5 (halfway through beat 1)
        expect(BeatClock.tickToBeat(4)):toBe(0.5)
        -- tick 12 = beat 1.5
        expect(BeatClock.tickToBeat(12)):toBe(1.5)
    end)

    it("handles negative ticks", function()
        expect(BeatClock.tickToBeat(-8)):toBe(-1)
        expect(BeatClock.tickToBeat(-4)):toBe(-0.5)
    end)
end)

-- ============================================================
-- beatToTick conversion tests
-- ============================================================
describe("beatToTick", function()
    it("converts beat 0 to tick 0", function()
        expect(BeatClock.beatToTick(0)):toBe(0)
    end)

    it("converts beats to ticks correctly", function()
        -- With ticksPerBeat = 8: beat 1 = tick 8
        expect(BeatClock.beatToTick(1)):toBe(8)
        expect(BeatClock.beatToTick(2)):toBe(16)
        expect(BeatClock.beatToTick(4)):toBe(32)
    end)

    it("floors non-integer tick results", function()
        -- beat 0.5 = tick 4.0 → stays 4
        expect(BeatClock.beatToTick(0.5)):toBe(4)
        -- beat 1.25 = tick 10 → 10
        expect(BeatClock.beatToTick(1.25)):toBe(10)
        -- beat 1.1 = tick 8.8 → floors to 8
        expect(BeatClock.beatToTick(1.1)):toBe(8)
    end)

    it("handles negative beats", function()
        expect(BeatClock.beatToTick(-1)):toBe(-8)
    end)
end)

-- ============================================================
-- Round-trip conversion: tick → beat → tick
-- ============================================================
describe("tick-beat round-trip conversion", function()
    it("tick → beat → tick is identity for multiples of 8", function()
        for _, tick in ipairs({0, 8, 16, 24, 32, 40, 48, 56, 64}) do
            local beat = BeatClock.tickToBeat(tick)
            local backToTick = BeatClock.beatToTick(beat)
            expect(backToTick):toBe(tick)
        end
    end)

    it("tick → beat → tick may lose precision for non-multiples", function()
        -- tick 5 → beat 0.625 → tick 5 (floor(0.625 * 8) = 5) — actually preserves!
        local beat = BeatClock.tickToBeat(5)
        expect(BeatClock.beatToTick(beat)):toBe(5)

        -- tick 3 → beat 0.375 → tick 3 (floor(3.0) = 3)
        beat = BeatClock.tickToBeat(3)
        expect(BeatClock.beatToTick(beat)):toBe(3)
    end)
end)

-- ============================================================
-- get32ndNoteDuration tests
-- ============================================================
describe("get32ndNoteDuration", function()
    it("returns correct duration at 120 BPM", function()
        mockTime = 0
        BeatClock.init(120)
        -- 60 / (120 * 8) = 60 / 960 = 0.0625
        local dur = BeatClock.get32ndNoteDuration()
        expect(dur > 0):toBe(true)
        expect(dur < 0.07):toBe(true)
        expect(dur > 0.06):toBe(true)
    end)

    it("returns longer duration at slower BPM", function()
        mockTime = 0
        BeatClock.init(60)
        local slowDur = BeatClock.get32ndNoteDuration()

        BeatClock.init(240)
        local fastDur = BeatClock.get32ndNoteDuration()

        expect(slowDur > fastDur):toBe(true)
    end)

    it("doubles duration when BPM halves", function()
        mockTime = 0
        BeatClock.init(120)
        local dur120 = BeatClock.get32ndNoteDuration()

        BeatClock.init(60)
        local dur60 = BeatClock.get32ndNoteDuration()

        -- 60 BPM should be exactly 2x the duration of 120 BPM
        local ratio = dur60 / dur120
        expect(ratio > 1.99 and ratio < 2.01):toBe(true)
    end)
end)

-- ============================================================
-- tickDuration tests
-- ============================================================
describe("tickDuration", function()
    it("matches get32ndNoteDuration", function()
        mockTime = 0
        BeatClock.init(128)
        local td = BeatClock.tickDuration()
        local nd = BeatClock.get32ndNoteDuration()
        -- Both should be the same: 60 / (bpm * 8)
        expect(td > 0):toBe(true)
        -- They should be equal (within float precision)
        expect(math.abs(td - nd) < 0.0001):toBe(true)
    end)
end)

-- ============================================================
-- setBPM preserves tick position
-- ============================================================
describe("setBPM preserves tick position", function()
    it("does not jump ticks on tempo change", function()
        mockTime = 0
        BeatClock.init(120)

        -- Advance some time
        mockTime = 2.0
        local tickBefore = BeatClock.getCurrentTick()

        -- Change tempo
        BeatClock.setBPM(60)

        -- Tick immediately after should be same or very close
        local tickAfter = BeatClock.getCurrentTick()
        expect(math.abs(tickAfter - tickBefore) <= 1):toBe(true)
    end)

    it("ignores invalid BPM values", function()
        mockTime = 0
        BeatClock.init(120)
        local bpmBefore = BeatClock.bpm

        BeatClock.setBPM(0)
        expect(BeatClock.bpm):toBe(bpmBefore)

        BeatClock.setBPM(-10)
        expect(BeatClock.bpm):toBe(bpmBefore)

        BeatClock.setBPM(nil)
        expect(BeatClock.bpm):toBe(bpmBefore)

        BeatClock.setBPM("fast")
        expect(BeatClock.bpm):toBe(bpmBefore)
    end)

    it("documents NaN BPM behavior", function()
        -- In Lua, NaN passes typeof == 'number' but NaN <= 0 is false
        -- So setBPM(NaN) would set bpm to NaN. This is a known edge case.
        -- The init function guards with bpm > 0 which catches NaN (NaN > 0 is false).
        mockTime = 0
        BeatClock.init(0/0)  -- NaN should fall to default via init's guard
        expect(BeatClock.bpm):toBe(72) -- default, because NaN > 0 is false
    end)
end)

-- ============================================================
-- syncFromServer tests
-- ============================================================
describe("syncFromServer", function()
    it("sets startTick from server", function()
        mockTime = 0
        BeatClock.init(120)
        BeatClock.syncFromServer(1000)
        -- After sync, at time 0, tick should be 1000
        expect(BeatClock.getCurrentTick()):toBe(1000)
    end)

    it("updates BPM when provided", function()
        mockTime = 0
        BeatClock.init(120)
        BeatClock.syncFromServer(0, 200)
        expect(BeatClock.bpm):toBe(200)
    end)

    it("does not change BPM when not provided", function()
        mockTime = 0
        BeatClock.init(120)
        BeatClock.syncFromServer(0)
        expect(BeatClock.bpm):toBe(120)
    end)

    it("ignores invalid serverTick", function()
        mockTime = 0
        BeatClock.init(120)
        local tickBefore = BeatClock.startTick
        BeatClock.syncFromServer(nil)
        expect(BeatClock.startTick):toBe(tickBefore)

        BeatClock.syncFromServer("hello")
        expect(BeatClock.startTick):toBe(tickBefore)
    end)

    it("ignores invalid BPM in sync", function()
        mockTime = 0
        BeatClock.init(120)
        BeatClock.syncFromServer(0, 0)
        expect(BeatClock.bpm):toBe(120)

        BeatClock.syncFromServer(0, -5)
        expect(BeatClock.bpm):toBe(120)

        BeatClock.syncFromServer(0, "fast")
        expect(BeatClock.bpm):toBe(120)
    end)
end)

-- ============================================================
-- elapsed tests
-- ============================================================
describe("elapsed", function()
    it("returns 0 at initialization", function()
        mockTime = 42
        BeatClock.init(120)
        local el = BeatClock.elapsed()
        expect(el >= 0 and el < 0.001):toBe(true)
    end)

    it("returns elapsed time", function()
        mockTime = 10
        BeatClock.init(120)
        mockTime = 15
        local el = BeatClock.elapsed()
        expect(math.abs(el - 5) < 0.001):toBe(true)
    end)

    it("resets after setBPM", function()
        mockTime = 0
        BeatClock.init(120)
        mockTime = 10
        BeatClock.setBPM(180)
        local el = BeatClock.elapsed()
        expect(el < 0.001):toBe(true)
    end)

    it("resets after syncFromServer", function()
        mockTime = 0
        BeatClock.init(120)
        mockTime = 20
        BeatClock.syncFromServer(0)
        local el = BeatClock.elapsed()
        expect(el < 0.001):toBe(true)
    end)
end)

-- ============================================================
-- isOnBeat tests
-- ============================================================
describe("isOnBeat", function()
    it("returns true at tick 0", function()
        mockTime = 0
        BeatClock.init(120)
        -- At time 0, tick should be 0, which is on beat
        expect(BeatClock.isOnBeat()):toBe(true)
    end)

    it("returns true when tick is multiple of ticksPerBeat", function()
        mockTime = 0
        BeatClock.init(120)
        -- At 120 BPM: 60/(120*8) = 0.0625 sec/tick
        -- tick 8 = at 0.5 seconds (beat boundary)
        mockTime = 0.5
        -- Tick should be 8, which is on beat
        expect(BeatClock.isOnBeat()):toBe(true)
    end)
end)

-- ============================================================
-- getCurrentMeasure tests
-- ============================================================
describe("getCurrentMeasure", function()
    it("returns 0 at start", function()
        mockTime = 0
        BeatClock.init(120)
        expect(BeatClock.getCurrentMeasure()):toBe(0)
    end)

    it("returns 1 after 4 beats", function()
        mockTime = 0
        BeatClock.init(120)
        -- 4 beats at 120 BPM = 4 * 0.5 = 2.0 seconds
        mockTime = 2.0
        local m = BeatClock.getCurrentMeasure()
        expect(m >= 0.99):toBe(true)
    end)

    it("equals getCurrentBeat / 4", function()
        mockTime = 0
        BeatClock.init(128)
        mockTime = 3.7
        local beat = BeatClock.getCurrentBeat()
        local measure = BeatClock.getCurrentMeasure()
        expect(math.abs(measure - beat / 4) < 0.001):toBe(true)
    end)
end)

-- ============================================================
-- reset tests
-- ============================================================
describe("reset", function()
    it("resets tick to 0", function()
        mockTime = 0
        BeatClock.init(120)
        mockTime = 10.0
        BeatClock.reset()
        local tick = BeatClock.getCurrentTick()
        expect(tick):toBe(0)
    end)

    it("preserves BPM", function()
        mockTime = 0
        BeatClock.init(180)
        mockTime = 5.0
        BeatClock.reset()
        expect(BeatClock.bpm):toBe(180)
    end)
end)

-- ============================================================
-- getBPM tests
-- ============================================================
describe("getBPM", function()
    it("returns the current BPM", function()
        mockTime = 0
        BeatClock.init(96)
        expect(BeatClock.getBPM()):toBe(96)
    end)

    it("reflects tempo changes", function()
        mockTime = 0
        BeatClock.init(96)
        BeatClock.setBPM(144)
        expect(BeatClock.getBPM()):toBe(144)
    end)

    it("reflects sync BPM", function()
        mockTime = 0
        BeatClock.init(96)
        BeatClock.syncFromServer(0, 200)
        expect(BeatClock.getBPM()):toBe(200)
    end)
end)

-- ============================================================
-- init edge cases
-- ============================================================
describe("init edge cases", function()
    it("accepts very high BPM", function()
        mockTime = 0
        BeatClock.init(1000)
        expect(BeatClock.bpm):toBe(1000)
    end)

    it("accepts fractional BPM", function()
        mockTime = 0
        BeatClock.init(127.5)
        expect(BeatClock.bpm):toBe(127.5)
    end)

    it("rejects string BPM", function()
        mockTime = 0
        BeatClock.init("fast")
        expect(BeatClock.bpm > 0):toBe(true)
        expect(BeatClock.bpm):toBe(72) -- default
    end)

    it("rejects NaN BPM", function()
        mockTime = 0
        BeatClock.init(0/0)
        expect(BeatClock.bpm):toBe(72) -- default
    end)
end)

-- ============================================================
-- Module constants
-- ============================================================
describe("module constants", function()
    it("exposes ticksPerBeat as 8", function()
        expect(BeatClock.ticksPerBeat):toBe(8)
    end)

    it("ticksPerBeat is a number", function()
        expect(type(BeatClock.ticksPerBeat)):toBe("number")
    end)
end)

-- ============================================================
-- All exported functions exist
-- ============================================================
describe("API completeness", function()
    local expectedFunctions = {
        "init", "setBPM", "syncFromServer", "getBPM", "elapsed",
        "tickDuration", "getCurrentTick", "getCurrentBeat",
        "tickToBeat", "beatToTick", "get32ndNoteDuration",
        "isOnBeat", "getCurrentMeasure", "reset"
    }

    for _, funcName in ipairs(expectedFunctions) do
        it("exports " .. funcName, function()
            expect(type(BeatClock[funcName])):toBe("function")
        end)
    end
end)
