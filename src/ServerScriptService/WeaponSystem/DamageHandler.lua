local DamageHandler = {}

function DamageHandler:ProcessHit(player, tool, origin, direction)
	-- Ensure the player's character and HumanoidRootPart exist
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	-- Retrieve the configured range (defaulting to 10000 if not set)
	local range = tool:GetAttribute("Range") or 10000

	-- Normalize the direction vector to ensure correct range scaling
	direction = direction.Unit

	-- Create the ray with a normalized direction multiplied by the range
	local ray = Ray.new(origin, direction * range)

	-- Server debug visualization
	local debugPart = Instance.new("Part")
	debugPart.Size = Vector3.new(0.2, 0.2, range)
	debugPart.CFrame = CFrame.new(origin, origin + direction * range) * CFrame.new(0, 0, -range/2)
	debugPart.Color = Color3.new(0, 0, 1)
	debugPart.Anchored = true
	debugPart.CanCollide = false
	debugPart.Parent = workspace
	game.Debris:AddItem(debugPart, 3)

	-- Cast the ray and check for a hit (ignoring the shooter's character)
	local hitPart, hitPoint = workspace:FindPartOnRay(ray, character)

	if hitPart then
		local hitHumanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")
		if hitHumanoid and hitHumanoid.Health > 0 then
			local baseDamage = tool:GetAttribute("Damage") or 0
			local isHeadshot = hitPart.Name == "Head"
			-- Apply headshot multiplier if applicable
			local damage = isHeadshot and (baseDamage * (tool:GetAttribute("HeadshotMultiplier") or 1)) or baseDamage

			hitHumanoid:TakeDamage(damage)
			print(string.format("%s hit %s (%s) for %d damage", 
				player.Name, hitPart.Parent.Name, 
				isHeadshot and "headshot" or "body shot", damage))
		end
	end
end

return DamageHandler
