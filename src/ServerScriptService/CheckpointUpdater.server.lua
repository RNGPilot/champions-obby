local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local PlayerManager = require(ServerStorage:WaitForChild("PlayerManager"))
local CheckpointEvent = game.ReplicatedStorage:WaitForChild("CheckpointEvent", 10)
if not CheckpointEvent then
	warn("CheckpointEvent not found in ReplicatedStorage!")
	return
end

local function onCheckpointChanged(player, checkpointName)
	local inObby = PlayerManager.isInObby(player)
	CheckpointEvent:FireClient(player, checkpointName, inObby)
end

Players.PlayerAdded:Connect(function(player)
	local dataFolder = PlayerManager.getPlayerDataFolder(player)
	local checkpointValue = dataFolder:WaitForChild("Checkpoint")

	checkpointValue:GetPropertyChangedSignal("Value"):Connect(function()
		onCheckpointChanged(player, checkpointValue.Value)
	end)

	-- Initial update
	onCheckpointChanged(player, checkpointValue.Value)
end)
