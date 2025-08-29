local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerManager = require(ServerStorage:WaitForChild("PlayerManager"))

local Checkpoints = workspace:WaitForChild("Obbys"):WaitForChild("Checkpoints")
local LobbySpawns = workspace:WaitForChild("Lobby"):WaitForChild("Spawns")
local CheckpointEvent = ReplicatedStorage:WaitForChild("CheckpointEvent")

local function getRandomLobbySpawn()
	local spawns = LobbySpawns:GetChildren()
	if #spawns == 0 then
		warn("No lobby spawn points found!")
		return nil
	end
	return spawns[math.random(#spawns)]
end

local function respawnPlayerAtCheckpoint(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")

	-- If in arena, arena logic handles respawns.
	if playerManager.isInArena(player) then
		return
	end

	-- Get the saved checkpoint
	local checkpointName = playerManager.getCheckpoint(player)

	-- Handle lobby spawns (if checkpointName indicates a lobby spawn)
	if checkpointName:match("^Lobby") then
		local spawn = getRandomLobbySpawn()
		if spawn then
			hrp.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
			print(player.Name.." respawned in lobby at "..spawn.Name)
		end
	else
		-- Handle obby checkpoints
		if playerManager.isInObby(player) then
			local checkpoint = Checkpoints:FindFirstChild(checkpointName)
			if checkpoint then
				hrp.CFrame = checkpoint.CFrame + Vector3.new(0, 5, 0)
				print(player.Name.." respawned at checkpoint: "..checkpointName)
			else
				warn("Checkpoint not found: "..checkpointName)
			end
		end
	end

	-- Update the client’s checkpoint display with the current checkpoint.
	CheckpointEvent:FireClient(player, checkpointName, playerManager.isInObby(player))
end

local function onPlayerAdded(player)
	-- Initialize player data if not already present.
	if not player:FindFirstChild("PlayerData") then
		playerManager.initializePlayerData(player)
	end

	-- If the player is not in the obby already, set their checkpoint to "Lobby1"
	-- (This line may need to be adjusted if you want to persist the checkpoint across sessions.)
	if not playerManager.isInObby(player) then
		playerManager.saveCheckpoint(player, "Lobby1")
	end

	player.CharacterAdded:Connect(function(character)
		-- Clear arena state if lingering.
		if playerManager.isInArena(player) then
			playerManager.setInArena(player, false)
		end

		-- Allow physics to settle before respawning.
		task.wait()
		respawnPlayerAtCheckpoint(player)
	end)
end

local function onPlayerRemoving(player)
	playerManager.cleanupPlayerData(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
