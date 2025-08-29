-- ServerStorage/PlayerManager.lua
local PlayerManager = {}

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

-- Constants
local PLAYER_DATA_FOLDER_NAME = "PlayerData"
local DEFAULT_CHECKPOINT = "Lobby1"  -- Default value if not in an obby

--------------------------------------------------------------------------------
-- 1) Helper: Get or create the main PlayerData folder in ServerStorage
--------------------------------------------------------------------------------
local function getMainPlayerDataFolder()
	local folder = ServerStorage:FindFirstChild(PLAYER_DATA_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = PLAYER_DATA_FOLDER_NAME
		folder.Parent = ServerStorage
	end
	return folder
end

--------------------------------------------------------------------------------
-- 2) Helper: Get a specific player's data folder (create if needed)
--------------------------------------------------------------------------------
function PlayerManager.getPlayerDataFolder(player)
	local mainFolder = getMainPlayerDataFolder()
	local userFolder = mainFolder:FindFirstChild(tostring(player.UserId))
	if not userFolder then
		-- Create a new folder for this player
		userFolder = Instance.new("Folder")
		userFolder.Name = tostring(player.UserId)
		userFolder.Parent = mainFolder

		-- Create default checkpoint value
		local checkpoint = Instance.new("StringValue")
		checkpoint.Name = "Checkpoint"
		checkpoint.Value = DEFAULT_CHECKPOINT
		checkpoint.Parent = userFolder

		-- Create InArena state
		local inArena = Instance.new("BoolValue")
		inArena.Name = "InArena"
		inArena.Value = false
		inArena.Parent = userFolder

		-- Create InObby state
		local inObby = Instance.new("BoolValue")
		inObby.Name = "InObby"
		inObby.Value = false
		inObby.Parent = userFolder
	end
	return userFolder
end

--------------------------------------------------------------------------------
-- 3) Initialize player data (call when the player first joins)
--------------------------------------------------------------------------------
function PlayerManager.initializePlayerData(player)
	-- Only create data if it doesn't already exist.
	PlayerManager.getPlayerDataFolder(player)
end

--------------------------------------------------------------------------------
-- 4) Get the player's current checkpoint
--------------------------------------------------------------------------------
function PlayerManager.getCheckpoint(player)
	local dataFolder = PlayerManager.getPlayerDataFolder(player)
	local checkpoint = dataFolder:FindFirstChild("Checkpoint")
	return checkpoint and checkpoint.Value or DEFAULT_CHECKPOINT
end

--------------------------------------------------------------------------------
-- 4a) (Optional) Get the numeric portion of the checkpoint for display
--------------------------------------------------------------------------------
function PlayerManager.getDisplayCheckpoint(player)
	local checkpoint = PlayerManager.getCheckpoint(player)
	-- Remove the "CP" prefix if present. If in lobby, it might be "Lobby1", so you might adjust as needed.
	local displayValue = string.gsub(checkpoint, "^CP", "")
	return displayValue
end

--------------------------------------------------------------------------------
-- 5) Save the player's checkpoint
--------------------------------------------------------------------------------
function PlayerManager.saveCheckpoint(player, checkpointName)
	local dataFolder = PlayerManager.getPlayerDataFolder(player)
	local checkpoint = dataFolder:FindFirstChild("Checkpoint")
	if checkpoint then
		-- Only update the checkpoint if the new checkpoint is different.
		if checkpoint.Value ~= checkpointName then
			checkpoint.Value = checkpointName
			print(player.Name .. "'s checkpoint saved as:", checkpointName)
		end
	else
		warn("[PlayerManager] Checkpoint data not found for player:", player.Name)
	end
end

--------------------------------------------------------------------------------
-- 6) Dynamically get the previous checkpoint (e.g., "CP1" -> none, "CP2" -> "CP1", etc.)
--------------------------------------------------------------------------------
function PlayerManager.getPreviousCheckpoint(currentCheckpoint)
	local checkpointsFolder = Workspace:FindFirstChild("Obbys"):FindFirstChild("Checkpoints")
	if not checkpointsFolder then
		warn("[PlayerManager] Checkpoints folder not found!")
		return nil
	end

	-- Collect checkpoint names in a table
	local checkpointNames = {}
	for _, checkpoint in ipairs(checkpointsFolder:GetChildren()) do
		table.insert(checkpointNames, checkpoint.Name)
	end

	-- Sort them by the numeric portion (CP1 < CP2 < CP3, etc.)
	table.sort(checkpointNames, function(a, b)
		local aNum = tonumber(a:match("%d+"))
		local bNum = tonumber(b:match("%d+"))
		return aNum < bNum
	end)

	-- Find where currentCheckpoint is in the sorted list
	local index = table.find(checkpointNames, currentCheckpoint)
	if index and index > 1 then
		return checkpointNames[index - 1]
	end

	-- If there's no previous checkpoint, return nil
	return nil
end

--------------------------------------------------------------------------------
-- 7) Set the player's arena status (InArena = true/false)
--------------------------------------------------------------------------------
function PlayerManager.setInArena(player, inArena)
	local dataFolder = PlayerManager.getPlayerDataFolder(player)
	local arenaStatus = dataFolder:FindFirstChild("InArena")
	if arenaStatus then
		arenaStatus.Value = inArena
		print(player.Name .. " arena status updated to:", inArena)
	else
		warn("[PlayerManager] Arena status not found for player:", player.Name)
	end
end

--------------------------------------------------------------------------------
-- 8) Check if the player is in an arena
--------------------------------------------------------------------------------
function PlayerManager.isInArena(player)
	local dataFolder = PlayerManager.getPlayerDataFolder(player)
	local arenaStatus = dataFolder:FindFirstChild("InArena")
	return arenaStatus and arenaStatus.Value or false
end

--------------------------------------------------------------------------------
-- 9) Set the player's obby status (InObby = true/false)
--------------------------------------------------------------------------------
function PlayerManager.setInObby(player, inObby)
	local dataFolder = PlayerManager.getPlayerDataFolder(player)
	local obbyStatus = dataFolder:FindFirstChild("InObby")
	if obbyStatus then
		obbyStatus.Value = inObby
		print(player.Name .. " obby status updated to:", inObby)
	else
		warn("[PlayerManager] Obby status not found for player:", player.Name)
	end
end

--------------------------------------------------------------------------------
-- 10) Check if the player is in the obby
--------------------------------------------------------------------------------
function PlayerManager.isInObby(player)
	local dataFolder = PlayerManager.getPlayerDataFolder(player)
	local obbyStatus = dataFolder:FindFirstChild("InObby")
	return obbyStatus and obbyStatus.Value or false
end

--------------------------------------------------------------------------------
-- 11) Cleanup player data when they leave
--------------------------------------------------------------------------------
function PlayerManager.cleanupPlayerData(player)
	local mainFolder = getMainPlayerDataFolder()
	local userFolder = mainFolder:FindFirstChild(tostring(player.UserId))
	if userFolder then
		userFolder:Destroy()
		print("Player data removed for:", player.Name)
	end
end

return PlayerManager
