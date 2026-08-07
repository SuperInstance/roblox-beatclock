-- tests/beatclock_test.lua
-- TestKit-compatible tests for BeatClock musical timing system.

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
local origOsClock = os.clock
os.clock = function() return mockTime end

local BeatClock = testkit.loadModule("/home/eileen/projects/roblox-beatclock/src/BeatClock.lua")

describe("BeatClock module structure", function()
    it("exports a table", function()
        expect(type(BeatClock)):toBe("table")
    end)

    it("has init function", function()
        expect(type(BeatClock.init)):toBe("function")
    end)

    it("has getCurrentTick function", function()
        expect(type(BeatClock.getCurrentTick)):toBe("function")
    end)

    it("has setBPM function", function()
        expect(type(BeatClock.setBPM)):toBe("function")
    end)
end)

describe("BeatClock init", function()
    it("initializes with default BPM", function()
        mockTime = 0
        BeatClock.init()
        expect(BeatClock.bpm > 0):toBe(true)
    end)

    it("initializes with custom BPM", function()
        mockTime = 0
        BeatClock.init(140)
        expect(BeatClock.bpm):toBe(140)
    end)

    it("falls back to default for nil BPM", function()
        mockTime = 0
        BeatClock.init(nil)
        expect(BeatClock.bpm > 0):toBe(true)
    end)

    it("falls back to default for BPM of 0", function()
        mockTime = 0
        BeatClock.init(0)
        expect(BeatClock.bpm > 0):toBe(true)
    end)

    it("falls back to default for negative BPM", function()
        mockTime = 0
        BeatClock.init(-10)
        expect(BeatClock.bpm > 0):toBe(true)
    end)
end)

describe("BeatClock tick computation", function()
    it("returns tick at start", function()
        mockTime = 0
        BeatClock.init(120)
        local tick = BeatClock.getCurrentTick()
        expect(tick >= 0):toBe(true)
    end)

    it("advances ticks with time", function()
        mockTime = 0
        BeatClock.init(120)
        -- At 120 BPM, 1 beat = 0.5 seconds, with default ticksPerBeat
        mockTime = 1.0
        local tick = BeatClock.getCurrentTick()
        expect(tick > 0):toBe(true)
    end)

    it("ticks advance more at higher BPM", function()
        -- Test with slow BPM
        mockTime = 0
        BeatClock.init(60)
        mockTime = 2.0
        local slowTick = BeatClock.getCurrentTick()

        -- Test with fast BPM
        mockTime = 0
        BeatClock.init(240)
        mockTime = 2.0
        local fastTick = BeatClock.getCurrentTick()

        expect(fastTick > slowTick):toBe(true)
    end)
end)

describe("BeatClock BPM change", function()
    it("setBPM changes the BPM", function()
        mockTime = 0
        BeatClock.init(120)
        BeatClock.setBPM(180)
        expect(BeatClock.bpm):toBe(180)
    end)
end)

describe("BeatClock beat detection", function()
    it("isOnBeat returns a boolean", function()
        mockTime = 0
        BeatClock.init(120)
        local result = BeatClock.isOnBeat()
        expect(type(result)):toBe("boolean")
    end)

    it("returns current beat as number", function()
        mockTime = 0
        BeatClock.init(120)
        local beat = BeatClock.getCurrentBeat()
        expect(type(beat)):toBe("number")
        expect(beat >= 0):toBe(true)
    end)
end)

describe("BeatClock reset", function()
    it("reset returns without error", function()
        mockTime = 5.0
        BeatClock.init(120)
        BeatClock.reset()
        local tick = BeatClock.getCurrentTick()
        expect(tick >= 0):toBe(true)
    end)
end)

describe("BeatClock measure tracking", function()
    it("getCurrentMeasure returns a number", function()
        mockTime = 0
        BeatClock.init(120)
        mockTime = 4.0
        local measure = BeatClock.getCurrentMeasure()
        expect(type(measure)):toBe("number")
        expect(measure >= 0):toBe(true)
    end)
end)
