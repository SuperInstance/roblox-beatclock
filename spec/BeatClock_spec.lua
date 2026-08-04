--[[
    BeatClock Test Suite
    ────────────────────
    Tests for the musical timing system. Uses a mock os.clock() to
    verify tick computation deterministically without relying on
    real wall-clock time.

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

-- Override os.clock for the test environment
os.clock = function()
    return mockTime
end

-- Load the module AFTER mocking os.clock
local BeatClock = require(script.Parent.src.BeatClock)

-- ── Tests ──────────────────────────────────────────────────────

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
    end)

    describe("tick computation at 120 BPM", function()
        beforeAll(function()
            setMockTime(0)
            BeatClock.init(120)
            -- At 120 BPM: tickDuration = 60 / (120 * 8) = 0.0625s
        end)

        it("returns tick 0 at start", function()
            expect(BeatClock.getCurrentTick()).to.equal(0)
        end)

        it("computes correct tick after 1 beat (0.5s)", function()
            advanceMockTime(0.5)
            -- 0.5s / 0.0625 = 8 ticks = beat 1.0
            expect(BeatClock.getCurrentTick()).to.equal(8)
            expect(BeatClock.getCurrentBeat()).to.equal(1.0)
        end)

        it("computes correct tick after 4 beats (2.0s)", function()
            setMockTime(0)
            BeatClock.init(120)
            advanceMockTime(2.0)
            -- 2.0s / 0.0625 = 32 ticks = beat 4.0
            expect(BeatClock.getCurrentTick()).to.equal(32)
            expect(BeatClock.getCurrentBeat()).to.equal(4.0)
        end)
    end)

    describe("setBPM preserves tick position", function()
        it("does not jump when tempo changes", function()
            setMockTime(0)
            BeatClock.init(120)
            advanceMockTime(1.0) -- 16 ticks at 120 BPM

            local tickBefore = BeatClock.getCurrentTick()
            expect(tickBefore).to.equal(16)

            BeatClock.setBPM(90)
            local tickAfter = BeatClock.getCurrentTick()
            -- Tick should be approximately the same (floor may differ by 1)
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
    end)

    describe("syncFromServer", function()
        it("sets the tick to the server value", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.syncFromServer(1000, 90)
            expect(BeatClock.getCurrentTick()).to.equal(1000)
            expect(BeatClock.getBPM()).to.equal(90)
        end)

        it("ignores invalid server tick", function()
            setMockTime(0)
            BeatClock.init(120)
            BeatClock.syncFromServer(nil)
            -- Should not crash; state unchanged
            expect(BeatClock.getBPM()).to.equal(120)
        end)
    end)

    describe("unit conversion", function()
        it("tickToBeat converts correctly", function()
            -- At 8 ticks/beat: tick 20 = beat 2.5
            expect(BeatClock.tickToBeat(20)).to.equal(2.5)
            expect(BeatClock.tickToBeat(0)).to.equal(0)
            expect(BeatClock.tickToBeat(8)).to.equal(1.0)
        end)

        it("beatToTick converts and floors", function()
            -- beat 2.5 = tick 20
            expect(BeatClock.beatToTick(2.5)).to.equal(20)
            expect(BeatClock.beatToTick(0)).to.equal(0)
            expect(BeatClock.beatToTick(1.0)).to.equal(8)
        end)
    end)

    describe("note durations", function()
        it("tickDuration matches 32nd note at various BPMs", function()
            -- At 120 BPM: 60 / (120 * 8) = 0.0625
            setMockTime(0)
            BeatClock.init(120)
            expect(BeatClock.tickDuration()).to.equal(0.0625)
            expect(BeatClock.get32ndNoteDuration()).to.equal(0.0625)

            -- At 90 BPM: 60 / (90 * 8) = 0.0833...
            BeatClock.init(90)
            local dur = BeatClock.tickDuration()
            expect(math.abs(dur - 0.0833)).to.be.at.most(0.001)
        end)
    end)

    describe("long session drift", function()
        it("maintains accuracy over simulated 1-hour session", function()
            setMockTime(0)
            BeatClock.init(120)
            advanceMockTime(3600) -- 1 hour

            local tick = BeatClock.getCurrentTick()
            local expected = math.floor(3600 / 0.0625) -- 57600 ticks

            -- The anchor model means zero drift — every query reads os.clock fresh
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
    end)

    -- Restore os.clock after all tests
    afterAll(function()
        os.clock = _origOsClock
    end)
end
