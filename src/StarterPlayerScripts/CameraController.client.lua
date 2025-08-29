-- CameraController (LocalScript in StarterPlayerScripts)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for the ArenaRemotes folder and SetCameraMode event
local arenaRemotesFolder = ReplicatedStorage:WaitForChild("ArenaRemotes")
local setCameraModeEvent = arenaRemotesFolder:WaitForChild("SetCameraMode")

-- Define the desired default camera settings
local DEFAULT_CAMERA_MODE = Enum.CameraMode.Classic  -- or whatever default you want
local DEFAULT_MIN_ZOOM = 5
local DEFAULT_MAX_ZOOM = 25

-- A simple function to force first-person in arena matches
local function forceFirstPerson()
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	-- In first-person mode, restrict zoom tightly
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 0.5
end

-- A function to revert the camera to the default settings
local function revertCamera()
	player.CameraMode = DEFAULT_CAMERA_MODE
	player.CameraMinZoomDistance = DEFAULT_MIN_ZOOM
	player.CameraMaxZoomDistance = DEFAULT_MAX_ZOOM
end

-- Listen for the remote event to change camera modes
setCameraModeEvent.OnClientEvent:Connect(function(mode)
	if mode == "Arena" then
		forceFirstPerson()
	elseif mode == "Default" then
		revertCamera()
	end
end)

-- Ensure the default camera zoom is set on load.
player.CameraMinZoomDistance = DEFAULT_MIN_ZOOM
player.CameraMaxZoomDistance = DEFAULT_MAX_ZOOM

print("Camera zoom limited: Min =", player.CameraMinZoomDistance, "Max =", player.CameraMaxZoomDistance)
