--[[
    BeatClock Test Suite
    ────────────────────
    Tests for the musical timing system. Uses a mock os.clock() to
    verify tick computation deterministically without relying on
    real wall-clock time.

    Covers: module structure, init, tick computation, BPM changes,
    sync, conversions, note durations, drift, edge cases, nil inputs,
    and extreme values.

    Run with TestEZ or any Lua test runner that understands describe/it.
]]

-- ── Mock os.clock for deterministic testing ───────────────────

local mockTime = 0
local _origOsClock = os.clock

local function setMockTime(t)
    mockTime = t
end

local function advanceMockTime(dt)
    mockTime = mockTime + dt
end

os.clock = function()
    return mockTime
end

local BeatClock = require(script.Parent.src.BeatClock)

return function()

    describe("BeatClock module", function()
        it("is a table", function()
            expect(type(BeatClock)).to.equal("table")
        end)

        it("has all public methods", function()
            expect(BeatClock.init).to.be.a("function")
            expect(BeatClock.setBPM).to.be.a("function")
            expect(BeatClock.syncFromServer).to.be.a("function")
            expect(BeatClock.getBPM).to.be.a("function")
            expect(BeatClock.getCurrentTick).to.be.a("function")
            expect(BeatClock.getCurrentBeat).to.be.a("function")
            expect(BeatClock.tickToBeat).to.be.a("function")
            expect(BeatClock.beatToTick).to.be.a("function")
            expect(BeatClock.elapsed).to.be.a("function")
            expect(BeatClock.tickDuration).to.be.a("function")
            expect(BeatClock.get32ndNoteDuration).to.be.a("function")
            expect(BeatClock.isOnBeat).to.be.a("function")
            expect(BeatClock.getCurrentMeasure).to.be.a("function")
            expect(BeatClock.reset).to.be.a("function")
        end)

        it("exposes ticksPerBeat constant", function()
            expect(BeatClock.ticksPerBeat).to.equal(8)
        end)
    end)

    describe("BeatClock.init", function()
        beforeAll(function()
            setMockTime(0)
            BeatClock.init(120)
        end)

        it("sets BPM to the provided value", function()
            expect(BeatClock.getBPM()).to.equal(120)
        end)

        it("defaults to 72 BPM when called with nil", function()
            setMockTime(0)
            BeatClock.init(nil)
            expect(BeatClock.getBPM()).to.equal(72)
        end)

        it("sets startTime to current mock time", function()
            setMockTime(100)
            BeatClock.init(120)
            expect(BeatClock.elapsed()).to.equal(0)
        end)

        it("resets startTick to 0 on init", function()
            setMockTime(50)
            BeatClock.init(90)
            expect(BeatClock.getCurrentTick()).to.equal(0)
        end)

        it("handles negative BPM by using default", function()
            setMockTime(0)
            BeatClock.init(-120)
            expect(BeatClock.getBPM()).to.equal(72)
        end)

        it("rejects zero BPM and uses default", function()
            setMockTime(0)
            BeatClock.init(0)
            expect(BeatClock.getBPM()).to.equal(72)
        end)
    end)

    describe("tick computation at 120 BPM", function()
        beforeAll(function()
            setMockTime(0)
            BeatClock.init(120)
        end)

        it("returns tick 0 at start", function()
            expect(BeatClock.getCurrentTick()).to.equal(0)
        end)

        it("computes correct tick after 1 beat (0.5s)", function()
            advanceMockTime(0.5)
            expect(BeatClock.getCurrentTick()).to.equal(8)
            expect(BeatClock.getCurrentBeat()).to.equal(1.0)
        end)

        it("computes correct tick after 4 beats (2.0s)", function()
            setMockTime(0)
            BeatClock.init(120)
            advanceMockTime(2.0)
            expect(BeatClock.getCurrentTick()).to.equal(32)
            expect(BeatClock.getCurrentBeat()).to.equal(4.0)
        end)

        it("tick at half-beat (0.25s) is 4", function()
            setMockTime(0)
            BeatClock.init(120)
            advanceMockTime(0.25)
            expect(BeatClock.getCurrentTick()).to.equal(4)
        end)
    end)

    describe("setBPM preserves tick position", function()
        it("does not jump when tempo changes", function()
            setMockTime(0)
            BeatClock.init(120)
            advanceMockTime(1.0)
            local tickBefore = BeatClock.getCurrentTick()
            expect(tickBefore).to.equal(16)
            BeatClock.setBPM(90)
            local tickAfter = BeatClock.getCurrentTick()
            expect(math.abs(tickAfter - tickBefore)).to.be.at.most(1)
        end)

        it("ignores invalid BPM values", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.setBPM(0)
            expect(BeatClock.getBPM()).to.equal(120)
            BeatClock.setBPM(-10)
            expect(BeatClock.getBPM()).to.equal(120)
            BeatClock.setBPM(nil)
            expect(BeatClock.getBPM()).to.equal(120)
        end)

        it("ignores string BPM", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.setBPM("fast")
            expect(BeatClock.getBPM()).to.equal(120)
        end)

        it("ignores boolean BPM", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.setBPM(true)
            expect(BeatClock.getBPM()).to.equal(120)
        end)

        it("ignores table BPM", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.setBPM({})
            expect(BeatClock.getBPM()).to.equal(120)
        end)

        it("accepts very high BPM (1000)", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.setBPM(1000)
            expect(BeatClock.getBPM()).to.equal(1000)
            local dur = BeatClock.tickDuration()
            expect(dur).to.equal(60.0 / (1000 * 8))
        end)

        it("accepts very low BPM (1)", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.setBPM(1)
            expect(BeatClock.getBPM()).to.equal(1)
        end)
    end)

    describe("syncFromServer", function()
        it("sets the tick to the server value", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.syncFromServer(1000, 90)
            expect(BeatClock.getCurrentTick()).to.equal(1000)
            expect(BeatClock.getBPM()).to.equal(90)
        end)

        it("ignores invalid server tick (nil)", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.syncFromServer(nil)
            expect(BeatClock.getBPM()).to.equal(120)
        end)

        it("ignores string server tick", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.syncFromServer("not_a_number")
            expect(BeatClock.getBPM()).to.equal(120)
        end)

        it("ignores negative BPM in sync", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.syncFromServer(500, -50)
            -- BPM should remain 120 since -50 is invalid
            expect(BeatClock.getBPM()).to.equal(120)
        end)

        it("accepts sync without BPM parameter", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.syncFromServer(42)
            expect(BeatClock.getCurrentTick()).to.equal(42)
        end)
    end)

    describe("unit conversion", function()
        it("tickToBeat converts correctly", function()
            expect(BeatClock.tickToBeat(20)).to.equal(2.5)
            expect(BeatClock.tickToBeat(0)).to.equal(0)
            expect(BeatClock.tickToBeat(8)).to.equal(1.0)
        end)

        it("beatToTick converts and floors", function()
            expect(BeatClock.beatToTick(2.5)).to.equal(20)
            expect(BeatClock.beatToTick(0)).to.equal(0)
            expect(BeatClock.beatToTick(1.0)).to.equal(8)
        end)

        it("tickToBeat handles negative ticks", function()
            expect(BeatClock.tickToBeat(-8)).to.equal(-1.0)
        end)

        it("beatToTick handles negative beats", function()
            expect(BeatClock.beatToTick(-1.0)).to.equal(-8)
        end)

        it("beatToTick floors fractional beats", function()
            expect(BeatClock.beatToTick(1.9)).to.equal(15)
        end)

        it("tickToBeat handles very large tick values", function()
            local result = BeatClock.tickToBeat(8000000)
            expect(result).to.equal(1000000)
        end)
    end)

    describe("note durations", function()
        it("tickDuration matches 32nd note at 120 BPM", function()
            setMockTime(0)
            BeatClock.init(120)
            expect(BeatClock.tickDuration()).to.equal(0.0625)
            expect(BeatClock.get32ndNoteDuration()).to.equal(0.0625)
        end)

        it("tickDuration matches 32nd note at 90 BPM", function()
            setMockTime(0)
            BeatClock.init(90)
            local dur = BeatClock.tickDuration()
            expect(math.abs(dur - 0.0833)).to.be.at.most(0.001)
        end)

        it("tickDuration at 72 BPM", function()
            setMockTime(0)
            BeatClock.init(72)
            local dur = BeatClock.tickDuration()
            expect(math.abs(dur - 0.1042)).to.be.at.most(0.001)
        end)

        it("tickDuration equals get32ndNoteDuration", function()
            setMockTime(0)
            BeatClock.init(144)
            expect(BeatClock.tickDuration()).to.equal(BeatClock.get32ndNoteDuration())
        end)
    end)

    describe("long session drift", function()
        it("maintains accuracy over simulated 1-hour session", function()
            setMockTime(0)
            BeatClock.init(120)
            advanceMockTime(3600)
            local tick = BeatClock.getCurrentTick()
            local expected = math.floor(3600 / 0.0625)
            expect(tick).to.equal(expected)
        end)

        it("maintains accuracy over simulated 10-minute session at 90 BPM", function()
            setMockTime(0)
            BeatClock.init(90)
            advanceMockTime(600)
            local tick = BeatClock.getCurrentTick()
            local tickDur = 60.0 / (90 * 8)
            local expected = math.floor(600 / tickDur)
            expect(tick).to.equal(expected)
        end)
    end)

    describe("elapsed", function()
        it("returns seconds since init", function()
            setMockTime(42)
            BeatClock.init(120)
            advanceMockTime(10)
            expect(BeatClock.elapsed()).to.equal(10)
        end)

        it("returns 0 immediately after init", function()
            setMockTime(100)
            BeatClock.init(120)
            expect(BeatClock.elapsed()).to.equal(0)
        end)
    end)

    describe("isOnBeat", function()
        it("returns true at beat boundary", function()
            setMockTime(0)
            BeatClock.init(120)
            expect(BeatClock.isOnBeat()).to.equal(true)
        end)

        it("returns false between beats", function()
            setMockTime(0)
            BeatClock.init(120)
            advanceMockTime(0.03) -- less than one tick
            expect(BeatClock.isOnBeat()).to.equal(false)
        end)

        it("returns true after exactly 1 beat", function()
            setMockTime(0)
            BeatClock.init(120)
            advanceMockTime(0.5)
            expect(BeatClock.isOnBeat()).to.equal(true)
        end)
    end)

    describe("getCurrentMeasure", function()
        it("returns 0 at start", function()
            setMockTime(0)
            BeatClock.init(120)
            expect(BeatClock.getCurrentMeasure()).to.equal(0)
        end)

        it("returns 1.0 after 4 beats at 120 BPM", function()
            setMockTime(0)
            BeatClock.init(120)
            advanceMockTime(2.0)
            expect(BeatClock.getCurrentMeasure()).to.equal(1.0)
        end)

        it("returns 0.5 after 2 beats", function()
            setMockTime(0)
            BeatClock.init(120)
            advanceMockTime(1.0)
            expect(BeatClock.getCurrentMeasure()).to.equal(0.5)
        end)
    end)

    describe("reset", function()
        it("resets tick to 0", function()
            setMockTime(0)
            BeatClock.init(120)
            advanceMockTime(2.0)
            expect(BeatClock.getCurrentTick()).to.equal(32)
            BeatClock.reset()
            expect(BeatClock.getCurrentTick()).to.equal(0)
        end)

        it("preserves current BPM", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.setBPM(90)
            BeatClock.reset()
            expect(BeatClock.getBPM()).to.equal(90)
        end)
    end)

    -- Restore os.clock after all tests
    afterAll(function()
        os.clock = _origOsClock
    end)
end
