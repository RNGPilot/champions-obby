local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponData = ReplicatedStorage:WaitForChild("WeaponData")

local WeaponManager = {}

function WeaponManager:GiveWeapon(player, weaponName)
	local weaponTool = ServerStorage.Weapons:FindFirstChild(weaponName)
	if not weaponTool then
		warn("Weapon not found in ServerStorage: " .. weaponName)
		return
	end

	local weaponClone = weaponTool:Clone()
	weaponClone.Parent = player:WaitForChild("Backpack")

	local configModule = WeaponData:FindFirstChild(weaponName .. "_Config")
	if configModule then
		local config = require(configModule)
		weaponClone:SetAttribute("Damage", config.Damage)
		weaponClone:SetAttribute("FireRate", config.FireRate)
		weaponClone:SetAttribute("AmmoCapacity", config.AmmoCapacity)
		weaponClone:SetAttribute("ReloadTime", config.ReloadTime)
		weaponClone:SetAttribute("Recoil", config.Recoil)
		weaponClone:SetAttribute("BulletSpread", config.BulletSpread)
		weaponClone:SetAttribute("Range", config.Range)
		print("[WeaponManager] Set attributes for", weaponName)
	else
		warn("No config found for", weaponName)
	end

	local character = player.Character
	if character and character:FindFirstChildOfClass("Humanoid") then
		character:FindFirstChildOfClass("Humanoid"):EquipTool(weaponClone)
		print("[WeaponManager] Equipped", weaponName, "to", player.Name)
	end
end

function WeaponManager:HandleFire(player, weaponName, hitPosition)
	print("[WeaponManager] HandleFire called for", player.Name, "with hitPosition", hitPosition)
	local tool = player.Character and player.Character:FindFirstChild(weaponName)
	if not tool then
		warn("Player " .. player.Name .. " does not have the weapon: " .. weaponName)
		return
	end

	if tool:GetAttribute("LastFireTime") then
		local lastFire = tool:GetAttribute("LastFireTime")
		local fireRate = tool:GetAttribute("FireRate")
		if os.clock() - lastFire < fireRate then
			print("[WeaponManager] Firing too fast for", player.Name)
			return
		end
	end

	tool:SetAttribute("LastFireTime", os.clock())
	print("[WeaponManager] Firing validated for", player.Name)

	local DamageHandler = require(script.Parent.DamageHandler)
	DamageHandler:ProcessHit(player, tool, hitPosition)
end

return WeaponManager
