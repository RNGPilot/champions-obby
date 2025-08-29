local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for the remote event; ensure it exists in ReplicatedStorage.
local checkpointSoundEvent = ReplicatedStorage:WaitForChild("CheckpointSoundEvent", 10)
if not checkpointSoundEvent then
	warn("CheckpointSoundEvent not found in ReplicatedStorage!")
	return
end

-- Wait for a sound asset (e.g. "CheckpointReachedSound") in ReplicatedStorage.
local soundTemplate = ReplicatedStorage:WaitForChild("CheckpointReachedSound", 10)
if not soundTemplate then
	warn("CheckpointReachedSound not found in ReplicatedStorage!")
	return
end

checkpointSoundEvent.OnClientEvent:Connect(function()
	-- Clone the sound and parent it to the player's camera for local playback.
	local soundClone = soundTemplate:Clone()
	soundClone.Parent = workspace.CurrentCamera
	soundClone:Play()
	-- Clean up after the sound finishes.
	game.Debris:AddItem(soundClone, soundClone.TimeLength or 3)
end)
