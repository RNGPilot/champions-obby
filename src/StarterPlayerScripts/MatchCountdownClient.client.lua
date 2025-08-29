-- StarterPlayerScripts/MatchCountdownClient.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local arenaRemotes = ReplicatedStorage:WaitForChild("ArenaRemotes")
local showMatchCountdownEvent = arenaRemotes:WaitForChild("ShowMatchCountdown")

-- Create a ScreenGui to hold our blackout and countdown elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MatchCountdownGui"
screenGui.ResetOnSpawn = false
-- This setting makes the GUI cover the entire screen, including areas normally reserved for the top inset.
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Create a full-screen blackout frame.
local blackoutFrame = Instance.new("Frame")
blackoutFrame.Name = "BlackoutFrame"
blackoutFrame.Size = UDim2.new(1, 0, 1, 0)
blackoutFrame.Position = UDim2.new(0, 0, 0, 0)
blackoutFrame.BackgroundColor3 = Color3.new(0, 0, 0)
-- Initially hidden (fully transparent)
blackoutFrame.BackgroundTransparency = 1
blackoutFrame.ZIndex = 1  -- Lower ZIndex so that the countdown text appears on top.
blackoutFrame.Parent = screenGui

-- Create the countdown label for "[PlayerName] vs [OpponentName]" and timer.
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "CountdownLabel"
countdownLabel.Size = UDim2.new(0.4, 0, 0.2, 0)
-- Center the label on the screen
countdownLabel.Position = UDim2.new(0.3, 0, 0.4, 0)
countdownLabel.BackgroundColor3 = Color3.new(0, 0, 0)
countdownLabel.BackgroundTransparency = 0.5
countdownLabel.TextScaled = true
countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
countdownLabel.Visible = false
countdownLabel.ZIndex = 2  -- Higher ZIndex so it appears on top of the blackout.
countdownLabel.Parent = screenGui

local function showCountdown(opponentName, countdownTime)
	-- Show the blackout overlay by making it fully opaque.
	blackoutFrame.BackgroundTransparency = 0
	countdownLabel.Visible = true

	local vsText = player.Name .. " vs " .. opponentName
	countdownLabel.Text = vsText
	wait(1)  -- Display the matchup text for a moment.

	for i = countdownTime, 1, -1 do
		countdownLabel.Text = vsText .. "\nTeleporting in " .. i
		wait(1)
	end

	-- After the countdown, hide both the label and the blackout overlay.
	countdownLabel.Visible = false
	blackoutFrame.BackgroundTransparency = 1
end

-- Listen for the match countdown event from the server.
showMatchCountdownEvent.OnClientEvent:Connect(function(opponentName, countdownTime)
	showCountdown(opponentName, countdownTime)
end)
