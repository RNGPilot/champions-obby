-- ServerScriptService/ArenaManager.lua
local ArenaManager = {}

--------------------------------------------------------------------------------
-- Services & References
--------------------------------------------------------------------------------
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerManager = require(ServerStorage:WaitForChild("PlayerManager"))
local arenasFolder = ServerStorage:WaitForChild("Arenas")

-- Remotes folder in ReplicatedStorage
local arenaRemotesFolder = ReplicatedStorage:WaitForChild("ArenaRemotes")
local setCameraModeEvent = arenaRemotesFolder:WaitForChild("SetCameraMode")
local showMatchCountdownEvent = arenaRemotesFolder:WaitForChild("ShowMatchCountdown")
local freezeForMatchEvent = arenaRemotesFolder:WaitForChild("FreezeForMatchEvent")
local removeWeaponHUDEvent = arenaRemotesFolder:WaitForChild("RemoveWeaponHUDEvent", 5)
if not removeWeaponHUDEvent then
	warn("RemoveWeaponHUDEvent not found in ReplicatedStorage.ArenaRemotes")
end

-- The name of the weapon/tool to give players during PvP
local WEAPON_NAME = "Handgun"

-- Define your final checkpoint name. Adjust as needed (for looping).
local FINAL_CHECKPOINT = "CP15"

--------------------------------------------------------------------------------
-- Module Variables
--------------------------------------------------------------------------------
-- ActiveMatches holds ongoing matches.
-- ActiveMatches[arenaInstance] = {
--   player1 = Player,
--   cpName1 = "CP5",
--   player2 = Player,
--   cpName2 = "CP3",
--   connections = {}
-- }
ArenaManager.ActiveMatches = {}

--------------------------------------------------------------------------------
-- 1) RequestPvP: Called when a player triggers a PvP checkpoint
--------------------------------------------------------------------------------
function ArenaManager:RequestPvP(triggeringPlayer, checkpointName)
	print(("[ArenaManager] %s triggered PvP at checkpoint: %s"):format(triggeringPlayer.Name, checkpointName))

	-- Find a free random opponent
	local opponent = self:FindRandomOpponent(triggeringPlayer)
	if not opponent then
		print("[ArenaManager] No available opponents for " .. triggeringPlayer.Name)
		return
	end

	print(("[ArenaManager] Found opponent: %s for %s"):format(opponent.Name, triggeringPlayer.Name))

	-- Opponent's checkpoint can be their current one
	local oppCheckpoint = PlayerManager.getCheckpoint(opponent)

	-- Start the match
	self:StartMatch(triggeringPlayer, checkpointName, opponent, oppCheckpoint)
end

--------------------------------------------------------------------------------
-- 2) FindRandomOpponent: Returns any player NOT in a match (InArena = false),
-- excluding the triggering player.
--------------------------------------------------------------------------------
function ArenaManager:FindRandomOpponent(excludePlayer)
	local candidates = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= excludePlayer and not PlayerManager.isInArena(plr) then
			table.insert(candidates, plr)
		end
	end

	if #candidates == 0 then
		return nil
	end

	return candidates[math.random(#candidates)]
end

--------------------------------------------------------------------------------
-- 3) StartMatch: Shows countdown UI, then clones an arena, teleports both players,
-- forces first-person, gives weapons, etc.
--------------------------------------------------------------------------------
function ArenaManager:StartMatch(player1, cpName1, player2, cpName2)
	-- Fire freeze event so players are frozen
	if freezeForMatchEvent then
		freezeForMatchEvent:FireClient(player1)
		freezeForMatchEvent:FireClient(player2)
	end

	local function freezeCharacter(plr)
		if plr.Character then
			for _, part in ipairs(plr.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
		end
	end

	local function unfreezeCharacter(plr)
		if plr.Character then
			for _, part in ipairs(plr.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
				end
			end
		end
	end

	-- Freeze both players
	freezeCharacter(player1)
	freezeCharacter(player2)

	-- Disable auto-healing in the arena
	if player1.Character then
		local hum = player1.Character:FindFirstChildOfClass("Humanoid")
		if hum then pcall(function() hum.AutoHeal = false end) end
	end
	if player2.Character then
		local hum = player2.Character:FindFirstChildOfClass("Humanoid")
		if hum then pcall(function() hum.AutoHeal = false end) end
	end

	-- Show countdown UI
	local countdownTime = 5
	showMatchCountdownEvent:FireClient(player1, player2.Name, countdownTime)
	showMatchCountdownEvent:FireClient(player2, player1.Name, countdownTime)
	task.wait(countdownTime)

	unfreezeCharacter(player1)
	unfreezeCharacter(player2)
	if player1.Character then
		local hum = player1.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = hum.MaxHealth end
	end
	if player2.Character then
		local hum = player2.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = hum.MaxHealth end
	end

	-- Clone and teleport arena
	local allArenas = arenasFolder:GetChildren()
	if #allArenas == 0 then
		warn("[ArenaManager] No arena templates found in ServerStorage/Arenas!")
		return
	end
	local chosenArenaModel = allArenas[math.random(#allArenas)]:Clone()
	chosenArenaModel.Parent = workspace

	-- Mark players as in arena and update their obby state
	PlayerManager.setInArena(player1, true)
	PlayerManager.setInArena(player2, true)
	PlayerManager.setInObby(player1, false)
	PlayerManager.setInObby(player2, false)

	-- Teleport players to arena spawns
	local spawnsFolder = chosenArenaModel:WaitForChild("Spawns")
	local spawnA = spawnsFolder:WaitForChild("Spawn1")
	local spawnB = spawnsFolder:WaitForChild("Spawn2")

	local hrp1 = player1.Character and player1.Character:WaitForChild("HumanoidRootPart", 5)
	if hrp1 then
		hrp1.CFrame = spawnA.CFrame + Vector3.new(0, 3, 0)
	else
		warn("Arena teleport: HumanoidRootPart not found for player: " .. player1.Name)
	end

	local hrp2 = player2.Character and player2.Character:WaitForChild("HumanoidRootPart", 5)
	if hrp2 then
		hrp2.CFrame = spawnB.CFrame + Vector3.new(0, 3, 0)
	else
		warn("Arena teleport: HumanoidRootPart not found for player: " .. player2.Name)
	end

	-- Force first-person
	setCameraModeEvent:FireClient(player1, "Arena")
	setCameraModeEvent:FireClient(player2, "Arena")

	-- Record match info
	self.ActiveMatches[chosenArenaModel] = {
		player1 = player1,
		cpName1 = cpName1,
		player2 = player2,
		cpName2 = cpName2,
		connections = {}
	}

	-- Give weapons and monitor deaths
	self:GiveWeapons(player1, player2)
	self:MonitorDeaths(chosenArenaModel, player1, player2)

	print(("[ArenaManager] Started match in %s between %s (%s) and %s (%s)"):format(chosenArenaModel.Name, player1.Name, cpName1, player2.Name, cpName2))
end

--------------------------------------------------------------------------------
-- 4) GiveWeapons: Clones a tool (e.g., "Handgun") from ServerStorage for each player,
-- and auto-equips it in slot 1.
--------------------------------------------------------------------------------
function ArenaManager:GiveWeapons(player1, player2)
	local weaponsFolder = ServerStorage:WaitForChild("Weapons")
	local weapon = weaponsFolder:FindFirstChild(WEAPON_NAME)
	if not weapon then
		warn("[ArenaManager] Weapon '" .. WEAPON_NAME .. "' not found in ServerStorage.Weapons!")
		return
	end

	local WeaponData = ReplicatedStorage:WaitForChild("WeaponData")
	local HandgunConfig = require(WeaponData:WaitForChild("Handgun_Config"))

	local function giveWeaponAndEquip(plr)
		local char = plr.Character
		local backpack = plr:WaitForChild("Backpack")

		local clone = weapon:Clone()
		clone.Parent = backpack

		-- Copy config values as attributes
		for key, value in pairs(HandgunConfig) do
			clone:SetAttribute(key, value)
		end

		-- Auto-equip
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local toolInBackpack = backpack:FindFirstChild(clone.Name)
				if toolInBackpack then
					humanoid:EquipTool(toolInBackpack)
				end
			end
		end

		print("[ArenaManager] Gave and auto-equipped weapon to " .. plr.Name)
	end

	giveWeaponAndEquip(player1)
	giveWeaponAndEquip(player2)
end

--------------------------------------------------------------------------------
-- 5) MonitorDeaths: Attach Humanoid.Died events so we know who loses/wins
--------------------------------------------------------------------------------
function ArenaManager:MonitorDeaths(arenaInstance, player1, player2)
	local matchData = self.ActiveMatches[arenaInstance]
	if not matchData then
		warn("[ArenaManager] MonitorDeaths called but matchData not found!")
		return
	end

	local function onDied(deadPlayer)
		local otherPlayer = (deadPlayer == player1) and player2 or player1
		task.wait(0.1)
		local deadHum = deadPlayer.Character and deadPlayer.Character:FindFirstChild("Humanoid")
		local otherHum = otherPlayer.Character and otherPlayer.Character:FindFirstChild("Humanoid")
		local bothDead = (otherHum and otherHum.Health <= 0)

		if bothDead then
			print("[ArenaManager] Both players died at the same time! Tie.")
			self:EndMatch(arenaInstance, nil, nil)
		else
			print(("[ArenaManager] %s died. %s wins."):format(deadPlayer.Name, otherPlayer.Name))
			self:EndMatch(arenaInstance, otherPlayer, deadPlayer)
		end
	end

	local hum1 = player1.Character and player1.Character:FindFirstChildOfClass("Humanoid")
	local hum2 = player2.Character and player2.Character:FindFirstChildOfClass("Humanoid")

	if hum1 then
		local conn1 = hum1.Died:Connect(function() onDied(player1) end)
		table.insert(matchData.connections, conn1)
	end
	if hum2 then
		local conn2 = hum2.Died:Connect(function() onDied(player2) end)
		table.insert(matchData.connections, conn2)
	end
end

--------------------------------------------------------------------------------
-- 6) EndMatch: Decide tie/winner-loser, handle final checkpoint logic, cleanup
--------------------------------------------------------------------------------
function ArenaManager:EndMatch(arenaInstance, winner, loser)
	local matchData = self.ActiveMatches[arenaInstance]
	if not matchData then
		warn("[ArenaManager] EndMatch called, but no matchData found for this arena.")
		return
	end

	local player1 = matchData.player1
	local cpName1 = matchData.cpName1
	local player2 = matchData.player2
	local cpName2 = matchData.cpName2

	-- Disconnect death listeners
	for _, conn in ipairs(matchData.connections) do
		conn:Disconnect()
	end

	-- Remove invincibility from both players (if any)
	local function removeInvincibility(plr)
		if plr.Character then
			local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:SetAttribute("Invincible", false)
			end
		end
	end
	removeInvincibility(player1)
	removeInvincibility(player2)

	-- Remove weapons
	self:RemoveWeapons(player1)
	self:RemoveWeapons(player2)

	-- Check if one triggered the final checkpoint
	local finalChallenger
	if cpName1 == FINAL_CHECKPOINT then
		finalChallenger = player1
	elseif cpName2 == FINAL_CHECKPOINT then
		finalChallenger = player2
	end

	if not winner and not loser then
		print("[ArenaManager] Tie! Both players lose one checkpoint.")
		self:RevertPlayerCheckpoint(player1)
		self:RevertPlayerCheckpoint(player2)
	else
		if winner then
			self:ReturnPlayerToCheckpoint(winner)
		end
		if loser then
			self:RevertPlayerCheckpoint(loser)
		end
	end

	if finalChallenger then
		if finalChallenger == winner then
			print("[ArenaManager] Final checkpoint challenger WON! Looping to CP1.")
			self:LoopPlayerToCP1(finalChallenger)
		else
			print("[ArenaManager] Final challenger did NOT win, no loop to CP1.")
		end
	end

	setCameraModeEvent:FireClient(player1, "Default")
	setCameraModeEvent:FireClient(player2, "Default")

	if removeWeaponHUDEvent then
		removeWeaponHUDEvent:FireClient(player1)
		removeWeaponHUDEvent:FireClient(player2)
	end

	self:CleanupArena(arenaInstance)
end

--------------------------------------------------------------------------------
-- 7) RemoveWeapons: Clears the given weapon from a player's Backpack & Character
--------------------------------------------------------------------------------
function ArenaManager:RemoveWeapons(player)
	local function removeFromContainer(container)
		for _, item in ipairs(container:GetChildren()) do
			if item.Name == WEAPON_NAME then
				item:Destroy()
			end
		end
	end

	if player and player.Backpack then
		removeFromContainer(player.Backpack)
	end
	if player and player.Character then
		removeFromContainer(player.Character)
	end
	print("[ArenaManager] Removed weapons from " .. player.Name)
end

--------------------------------------------------------------------------------
-- 8) RevertPlayerCheckpoint: Loser or Tie => revert to previous checkpoint
-- (UPDATED: Now also sets InObby to true so the respawn system uses the checkpoint)
--------------------------------------------------------------------------------
function ArenaManager:RevertPlayerCheckpoint(player)
	local currentCP = PlayerManager.getCheckpoint(player)
	local prevCP = PlayerManager.getPreviousCheckpoint(currentCP)
	if prevCP then
		-- Save the previous checkpoint and teleport the player there
		PlayerManager.saveCheckpoint(player, prevCP)
		local cpPart = workspace.Obbys.Checkpoints:FindFirstChild(prevCP)
		if cpPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = cpPart.CFrame + Vector3.new(0,5,0)
		end
		print(player.Name .. " was reverted to checkpoint " .. prevCP)
	end

	-- For losing players, ensure they remain in the obby so they respawn at a checkpoint.
	PlayerManager.setInArena(player, false)
	PlayerManager.setInObby(player, true)  -- Added: Reset obby state
end

--------------------------------------------------------------------------------
-- 9) ReturnPlayerToCheckpoint: Teleports winner to their current checkpoint and fully heals them.
-- (UPDATED: Now also sets InObby to true so the respawn system uses the checkpoint)
--------------------------------------------------------------------------------
function ArenaManager:ReturnPlayerToCheckpoint(player)
	local cpName = PlayerManager.getCheckpoint(player)
	if cpName then
		local cpPart = workspace.Obbys.Checkpoints:FindFirstChild(cpName)
		if cpPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = cpPart.CFrame + Vector3.new(0,5,0)
		end
		print(player.Name .. " returned to checkpoint " .. cpName)
	end

	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
			pcall(function() humanoid.AutoHeal = true end)
		end
	end

	PlayerManager.setInArena(player, false)
	PlayerManager.setInObby(player, true)  -- Added: Reset obby state
end

--------------------------------------------------------------------------------
-- 10) LoopPlayerToCP1: Called only if final-challenger actually won
--------------------------------------------------------------------------------
function ArenaManager:LoopPlayerToCP1(player)
	local cpPart = workspace.Obbys.Checkpoints:FindFirstChild("CP1")
	if cpPart then
		PlayerManager.saveCheckpoint(player, "CP1")
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = cpPart.CFrame + Vector3.new(0,5,0)
		end
		print(player.Name .. " was looped back to CP1!")
	else
		warn("[ArenaManager] CP1 not found!")
	end

	PlayerManager.setInArena(player, false)
end

--------------------------------------------------------------------------------
-- 11) CleanupArena: Destroys arena clone and clears from ActiveMatches
--------------------------------------------------------------------------------
function ArenaManager:CleanupArena(arenaInstance)
	self.ActiveMatches[arenaInstance] = nil
	if arenaInstance then
		arenaInstance:Destroy()
		print("[ArenaManager] Arena destroyed.")
	end
end

return ArenaManager
