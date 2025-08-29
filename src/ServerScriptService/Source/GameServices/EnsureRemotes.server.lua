-- EnsureRemotes.server.lua
-- Creates missing RemoteEvents at runtime to ensure all required remotes exist

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Define the remote structure we need
local REMOTE_STRUCTURE = {
	Weapons = {
		"FireWeapon",
		"ReloadWeapon", 
		"ShotResult"
	},
	Arena = {
		"ShowMatchCountdown",
		"SetCameraMode",
		"FreezeForMatch"
	},
	Checkpoints = {
		"CheckpointEvent",
		"PlayCheckpointSound"
	}
}

local function ensureFolder(parent, folderName)
	local folder = parent:FindFirstChild(folderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = parent
		print("[EnsureRemotes] Created folder:", folderName)
	end
	return folder
end

local function ensureRemoteEvent(parent, eventName)
	local event = parent:FindFirstChild(eventName)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = eventName
		event.Parent = parent
		print("[EnsureRemotes] Created RemoteEvent:", eventName)
	end
	return event
end

local function setupRemotes()
	-- Ensure main Remotes folder exists
	local remotesFolder = ensureFolder(ReplicatedStorage, "Remotes")
	
	-- Create each category folder and its RemoteEvents
	for categoryName, eventNames in pairs(REMOTE_STRUCTURE) do
		local categoryFolder = ensureFolder(remotesFolder, categoryName)
		
		for _, eventName in ipairs(eventNames) do
			ensureRemoteEvent(categoryFolder, eventName)
		end
	end
	
	print("[EnsureRemotes] All remotes ensured successfully")
end

-- Run on server start
setupRemotes()
