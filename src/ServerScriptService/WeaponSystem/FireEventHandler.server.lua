local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local WeaponRemotes = ReplicatedStorage:WaitForChild("WeaponRemotes")
local FireEvent = WeaponRemotes:WaitForChild("FireEvent")

local damageHandlerModule = game.ServerScriptService.WeaponSystem:FindFirstChild("DamageHandler")
if not damageHandlerModule then
	warn("[FireEventHandler] DamageHandler ModuleScript not found in WeaponSystem!")
	return
end

local DamageHandler = require(damageHandlerModule)

FireEvent.OnServerEvent:Connect(function(player, toolName, camOrigin, camDirection)
	if not player or not player.Character then
		warn("[FireEventHandler] Player or character missing for", player and player.Name)
		return
	end

	local tool = player.Character:FindFirstChild(toolName) or player.Backpack:FindFirstChild(toolName)
	if not tool then
		warn("[FireEventHandler] Tool '" .. toolName .. "' not found for " .. player.Name)
		return
	end

	if typeof(camOrigin) ~= "Vector3" or typeof(camDirection) ~= "Vector3" then
		warn("[FireEventHandler] camOrigin or camDirection is not a Vector3 for " .. player.Name)
		return
	end

	DamageHandler:ProcessHit(player, tool, camOrigin, camDirection)
end)
