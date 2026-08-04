-- examples/synced_lights.lua
-- Lights that pulse to the beat using BeatClock.
-- Place in StarterPlayerScripts (LocalScript).
--
-- Creates a ring of PointLights around the spawn area that:
--   • Flash bright on every downbeat (beat 1 of each measure)
--   • Dim pulse on every beat
--   · Shimmer on the 32nd-note grid for energy
-- Tempo changes are seamless — BeatClock preserves tick position.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local BeatClock = require(ReplicatedStorage:WaitForChild("BeatClock"))

-- ============================================================
--  Build a ring of light poles
-- ============================================================

local NUM_POLES = 8
local RADIUS = 24
local poles = {}

for i = 1, NUM_POLES do
    local angle = (i - 1) * (math.pi * 2 / NUM_POLES)

    -- Invisible pole carrying the light
    local pole = Instance.new("Part")
    pole.Name = "BeatPole_" .. i
    pole.Size = Vector3.new(0.5, 8, 0.5)
    pole.Position = Vector3.new(math.cos(angle) * RADIUS, 4, math.sin(angle) * RADIUS)
    pole.Anchored = true
    pole.CanCollide = false
    pole.Transparency = 1
    pole.Parent = workspace

    -- The actual light
    local light = Instance.new("PointLight")
    light.Name = "BeatLight"
    light.Range = 20
    light.Brightness = 0.5
    light.Color = Color3.fromHSV((i - 1) / NUM_POLES, 0.7, 1)
    light.Parent = pole

    table.insert(poles, { part = pole, light = light, index = i })
end

-- ============================================================
--  Start the clock
-- ============================================================

BeatClock.init(110) -- 110 BPM — mid-tempo groove

-- Optional: sync to server if you have a RemoteEvent
-- local serverSync = ReplicatedStorage:WaitForChild("BeatSync")
-- serverSync.OnClientEvent:Connect(function(serverTick, bpm)
--     BeatClock.syncFromServer(serverTick, bpm)
-- end)

-- ============================================================
--  Beat-driven light show
-- ============================================================

local lastBeat = -1
local last32nd = -1

RunService.Heartbeat:Connect(function()
    local beat = math.floor(BeatClock.getCurrentBeat())

    -- ── Per-beat: color cycle + brightness pulse ──
    if beat ~= lastBeat then
        lastBeat = beat

        local measure = math.floor(beat / 4)
        local beatInMeasure = beat % 4
        local isDownbeat = beatInMeasure == 0

        for _, pole in ipairs(poles) do
            -- Hue rotates per measure, offset per pole
            local hue = ((measure * 0.05) + (pole.index / NUM_POLES)) % 1
            pole.light.Color = Color3.fromHSV(hue, 0.8, 1)

            if isDownbeat then
                -- Big flash on the downbeat
                pole.light.Brightness = 6
                TweenService:Create(pole.light, TweenInfo.new(
                    BeatClock.tickDuration() * 16,  -- quarter note decay
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ), { Brightness = 1.5 }):Play()
            else
                -- Smaller pulse on other beats
                pole.light.Brightness = 3
                TweenService:Create(pole.light, TweenInfo.new(
                    BeatClock.tickDuration() * 8,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ), { Brightness = 0.8 }):Play()
            end
        end
    end

    -- ── 32nd-note shimmer: subtle brightness flicker ──
    local tick = BeatClock.getCurrentTick()
    if tick ~= last32nd then
        last32nd = tick

        -- Only shimmer every other 32nd to keep it tasteful
        if tick % 2 == 0 then
            for _, pole in ipairs(poles) do
                local shimmer = 0.8 + math.random() * 0.6
                TweenService:Create(pole.light, TweenInfo.new(
                    BeatClock.get32ndNoteDuration() * 1.5
                ), { Brightness = shimmer }):Play()
            end
        end
    end
end)

-- ============================================================
--  Tempo changes — simulate verse / chorus energy shifts
-- ============================================================

task.delay(10, function()
    print("[Synced Lights] Chorus — tempo up")
    BeatClock.setBPM(128)
end)

task.delay(25, function()
    print("[Synced Lights] Bridge — tempo down")
    BeatClock.setBPM(95)
end)

print("[Synced Lights] Initialized — 8 poles, 110 BPM")
