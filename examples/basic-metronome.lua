-- examples/basic-metronome.lua
-- A working metronome that ticks on every beat.
-- Place this in StarterPlayerScripts (LocalScript).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BeatClock = require(ReplicatedStorage:WaitForChild("BeatClock"))

-- Start at 120 BPM
BeatClock.init(120)

-- Track the last beat we handled
local lastBeat = -1

-- Use RunService.Heartbeat for precise timing
local RunService = game:GetService("RunService")

RunService.Heartbeat:Connect(function()
    local currentBeat = math.floor(BeatClock.getCurrentBeat())

    if currentBeat ~= lastBeat then
        lastBeat = currentBeat

        -- Play a click sound on every beat
        -- (replace with your own Sound instance)
        local click = Instance.new("Sound")
        click.SoundId = "rbxassetid://9116280080"
        click.Volume = 0.5
        click.Parent = workspace
        click:Play()

        -- Clean up after playback
        click.Ended:Connect(function()
            click:Destroy()
        end)

        -- Log every 4th beat (measure boundary)
        if currentBeat % 4 == 0 then
            print(string.format(".Measure %d — CLICK", math.floor(currentBeat / 4) + 1))
        end
    end
end)
