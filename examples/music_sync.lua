-- examples/music_sync.lua
-- Syncing a Roblox Sound object to BeatClock tempo.
-- Place in StarterPlayerScripts (LocalScript).
--
-- Demonstrates:
--   • Starting music on a downbeat (not mid-beat)
--   • Adjusting PlaybackSpeed to match tempo changes
--   • Using beat position for visual cues (progress bar)
--   • Switching between tracks on measure boundaries

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local BeatClock = require(ReplicatedStorage:WaitForChild("BeatClock"))

-- ============================================================
--  Music track definitions
-- ============================================================

-- Replace these asset IDs with your own tracks
local TRACKS = {
    exploration = {
        id = "rbxassetid://1837879082",
        bpm = 90,
        volume = 0.35,
    },
    combat = {
        id = "rbxassetid://1837879083",
        bpm = 140,
        volume = 0.50,
    },
    settlement = {
        id = "rbxassetid://1837879084",
        bpm = 72,
        volume = 0.30,
    },
}

local currentTrack = nil
local currentSound = nil

-- ============================================================
--  Start a track aligned to the next downbeat
-- ============================================================

local function playTrack(trackName)
    local track = TRACKS[trackName]
    if not track then return end

    -- Fade out existing track
    if currentSound then
        local oldSound = currentSound
        TweenService:Create(oldSound, TweenInfo.new(1.0), { Volume = 0 }):Play()
        task.delay(1.2, function()
            oldSound:Stop()
            oldSound:Destroy()
        end)
    end

    -- Set the tempo BEFORE starting so the clock is aligned
    BeatClock.setBPM(track.bpm)

    -- Wait for the next downbeat (beat % 4 == 0) to start cleanly
    -- This ensures the music starts on beat 1 of a measure
    task.spawn(function()
        -- Wait for next measure boundary
        while math.floor(BeatClock.getCurrentBeat()) % 4 ~= 0 do
            RunService.Heartbeat:Wait()
        end

        -- Tiny offset: wait half a tick for safety
        task.wait(BeatClock.tickDuration() * 0.5)

        local sound = Instance.new("Sound")
        sound.SoundId = track.id
        sound.Volume = 0
        sound.Looped = true
        sound.PlaybackSpeed = 1.0  -- We sync the clock TO the track, not vice-versa
        sound.Parent = workspace
        sound:Play()

        -- Fade in
        TweenService:Create(sound, TweenInfo.new(1.5), {
            Volume = track.volume,
        }):Play()

        currentSound = sound
        currentTrack = trackName

        print(string.format("[Music Sync] ▶ %s @ %d BPM (started on downbeat)",
            trackName, track.bpm))
    end)
end

-- ============================================================
--  Visual: beat indicator GUI
-- ============================================================

local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BeatIndicator"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Beat dots (4 per measure)
local beatDots = {}
for i = 1, 4 do
    local frame = Instance.new("Frame")
    frame.Name = "BeatDot" .. i
    frame.Size = UDim2.new(0, 16, 0, 16)
    frame.Position = UDim2.new(0.5, -40 + (i - 1) * 24, 0.9, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    table.insert(beatDots, frame)
end

-- BPM display
local bpmLabel = Instance.new("TextLabel")
bpmLabel.Name = "BPMLabel"
bpmLabel.Size = UDim2.new(0, 100, 0, 20)
bpmLabel.Position = UDim2.new(0.5, 0, 0.92, 0)
bpmLabel.AnchorPoint = Vector2.new(0.5, 0.5)
bpmLabel.BackgroundTransparency = 1
bpmLabel.Text = "90 BPM"
bpmLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
bpmLabel.Font = Enum.Font.Gotham
bpmLabel.TextSize = 12
bpmLabel.Parent = screenGui

-- ============================================================
--  Update loop: light up beat dots
-- ============================================================

local lastBeat = -1

RunService.Heartbeat:Connect(function()
    local beat = math.floor(BeatClock.getCurrentBeat())
    local beatInMeasure = beat % 4

    -- Highlight the current beat dot
    if beat ~= lastBeat then
        lastBeat = beat

        -- Reset all dots
        for i, dot in ipairs(beatDots) do
            if (i - 1) == beatInMeasure then
                -- Active dot: bright
                TweenService:Create(dot, TweenInfo.new(0.05), {
                    BackgroundColor3 = Color3.fromRGB(100, 200, 255),
                    Size = UDim2.new(0, 22, 0, 22),
                }):Play()

                -- Decay back
                task.delay(BeatClock.tickDuration() * 6, function()
                    TweenService:Create(dot, TweenInfo.new(0.2), {
                        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                        Size = UDim2.new(0, 16, 0, 16),
                    }):Play()
                end)
            end
        end
    end

    -- Update BPM label
    bpmLabel.Text = string.format("%d BPM", BeatClock.getBPM())
end)

-- ============================================================
--  Track switching demo
-- ============================================================

playTrack("exploration")

task.delay(12, function()
    print("[Music Sync] Switching to combat...")
    playTrack("combat")
end)

task.delay(24, function()
    print("[Music Sync] Returning to settlement...")
    playTrack("settlement")
end)

print("[Music Sync] Initialized — waiting for first downbeat...")
