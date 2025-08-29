-- StarterPlayerScripts/RemoveWeaponHUDClient.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Adjust this if your remote event is located elsewhere; for example, it might be in ArenaRemotes.
local arenaRemotes = ReplicatedStorage:WaitForChild("ArenaRemotes")
local removeWeaponHUDEvent = arenaRemotes:WaitForChild("RemoveWeaponHUDEvent")

removeWeaponHUDEvent.OnClientEvent:Connect(function()
	-- Option 1: If you want to simply disable/hide the UI:
	local handgunHUD = player.PlayerGui:FindFirstChild("HandgunHUD")
	if handgunHUD then
		handgunHUD.Enabled = false
	end

	local crosshairGUI = player.PlayerGui:FindFirstChild("CrosshairGUI")
	if crosshairGUI then
		crosshairGUI.Enabled = false
	end

	-- Option 2: If you prefer to completely remove (destroy) them, use:
	-- if handgunHUD then handgunHUD:Destroy() end
	-- if crosshairGUI then crosshairGUI:Destroy() end

	print("[RemoveWeaponHUDClient] Gun UI removed.")
end)
