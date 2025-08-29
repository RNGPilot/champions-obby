-- CheckpointDisplayerHandler (LocalScript in StarterPlayerScripts)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Wait for the CheckpointDisplay GUI in ReplicatedStorage (with a 10-second timeout)
local CheckpointDisplay = ReplicatedStorage:WaitForChild("CheckpointDisplay", 10)
if not CheckpointDisplay then
	warn("CheckpointDisplay not found in ReplicatedStorage!")
	return
end
CheckpointDisplay = CheckpointDisplay:Clone()
-- Prevent the GUI from resetting on respawn
CheckpointDisplay.ResetOnSpawn = false
CheckpointDisplay.Parent = PlayerGui

-- Wait for the CheckpointText inside the cloned CheckpointDisplay (with a 10-second timeout)
local CheckpointText = CheckpointDisplay:WaitForChild("CheckpointText", 10)
if not CheckpointText then
	warn("CheckpointText not found in CheckpointDisplay!")
	return
end

-- Wait for the CheckpointEvent in ReplicatedStorage (with a 10-second timeout)
local CheckpointEvent = ReplicatedStorage:WaitForChild("CheckpointEvent", 10)
if not CheckpointEvent then
	warn("CheckpointEvent not found in ReplicatedStorage!")
	return
end

-- Style adjustments:
-- Position the text at the top center (closer to the top)
CheckpointText.AnchorPoint = Vector2.new(0.5, 0)        -- Center horizontally, top vertically
CheckpointText.Position = UDim2.new(0.5, 0, 0, 0)         -- 0 pixels from the top

-- Remove background by setting transparency to 1 (fully transparent)
CheckpointText.BackgroundTransparency = 1

-- Increase text size and adjust font properties as desired
CheckpointText.TextScaled = false       -- Disable scaled text to use explicit TextSize
CheckpointText.TextSize = 36            -- Increase the text size
CheckpointText.Font = Enum.Font.GothamBold -- Use a bold, modern font
CheckpointText.TextColor3 = Color3.new(0, 0, 0) -- Black text (change if needed)

-- Function to update the display.
local function updateDisplay(checkpointName, inObby)
	CheckpointText.Visible = inObby
	if inObby then
		-- Remove the "CP" prefix if present (e.g., "CP1" becomes "1")
		local numericCheckpoint = string.gsub(checkpointName, "^CP", "")
		CheckpointText.Text = "Checkpoint: " .. numericCheckpoint
	end
end

CheckpointEvent.OnClientEvent:Connect(function(checkpointName, inObby)
	updateDisplay(checkpointName, inObby)
end)

-- Initial state: not in obby; display "Lobby" (adjust as needed)
updateDisplay("Lobby", false)
