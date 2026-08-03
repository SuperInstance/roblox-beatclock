-- examples/dance-floor.lua
-- A synchronized dance floor: lights pulse on beats, spotlights
-- sweep on 32nd-note grid, and tempo can change mid-song.
-- Place in StarterPlayerScripts (LocalScript).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local BeatClock = require(ReplicatedStorage:WaitForChild("BeatClock"))

-- ============================================================
--  Set up the scene
-- ============================================================

-- Create a dance floor part
local floor = Instance.new("Part")
floor.Name = "DanceFloor"
floor.Size = Vector3.new(32, 1, 32)
floor.Position = Vector3.new(0, 0, 0)
floor.Anchored = true
floor.Material = Enum.Material.Neon
floor.Color = Color3.fromHSV(0.6, 0.8, 0.5)
floor.Parent = workspace

-- Create a spotlight
local spotlight = Instance.new("Spotlight")
spotlight.Name = "BeatLight"
spotlight.Angle = 60
spotlight.Brightness = 5
spotlight.Face = Enum.NormalId.Bottom
spotlight.Parent = floor

-- Audio track (replace with your own asset)
local music = Instance.new("Sound")
music.SoundId = "rbxassetid://1837879082"
music.Volume = 0.8
music.Looped = true
music.Parent = workspace

-- ============================================================
--  Start the clock and music
-- ============================================================

BeatClock.init(128) -- 128 BPM — house/dance tempo
music:Play()

-- ============================================================
--  Beat scheduler: pulse the floor on every beat
-- ============================================================

local lastBeat = -1

RunService.Heartbeat:Connect(function()
    local currentBeat = math.floor(BeatClock.getCurrentBeat())

    if currentBeat ~= lastBeat then
        lastBeat = currentBeat

        -- Every beat: pulse the floor color
        local hue = (currentBeat % 16) / 16 -- cycle through hues every 4 measures
        local flashInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local flashBack = TweenInfo.new(BeatClock.tickDuration() * 4, Enum.EasingStyle.Quad)

        TweenService:Create(floor, flashInfo, {
            Color = Color3.fromHSV(hue, 1, 1),
        }):Play()

        task.delay(0.1, function()
            TweenService:Create(floor, flashBack, {
                Color = Color3.fromHSV(hue, 0.8, 0.5),
            }):Play()
        end)

        -- Every 4th beat (downbeat): bigger flash + spotlight sweep
        if currentBeat % 4 == 0 then
            spotlight.Brightness = 15
            TweenService:Create(spotlight, TweenInfo.new(0.3), {
                Brightness = 5,
            }):Play()

            print(string.format("[Dance Floor] Measure %d — DROP",
                math.floor(currentBeat / 4) + 1))
        end
    end
end)

-- ============================================================
--  Tempo change: simulate a build-up
-- ============================================================

task.delay(15, function()
    print("[Dance Floor] Tempo rising...")
    BeatClock.setBPM(140) -- push the tempo up mid-song
end)

task.delay(30, function()
    print("[Dance Floor] Breakdown — slowing down")
    BeatClock.setBPM(100)
end)

-- ============================================================
--  32nd-note grid: fine-grained shimmer effect
-- ============================================================

local last32nd = -1

RunService.Heartbeat:Connect(function()
    local tick = BeatClock.getCurrentTick()
    if tick ~= last32nd then
        last32nd = tick

        -- Every 32nd note: subtle brightness flicker on the spotlight
        local shimmer = 4 + math.random() * 2
        TweenService:Create(spotlight, TweenInfo.new(BeatClock.get32ndNoteDuration() * 0.5), {
            Brightness = shimmer,
        }):Play()
    end
end)

print("[Dance Floor] Initialized at 128 BPM — let's dance!")
