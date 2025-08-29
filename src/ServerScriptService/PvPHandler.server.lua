-- ServerScriptService/PvPHandler.lua

local PvP = game.ServerScriptService:WaitForChild("PvP")
local ArenaManager = require(game.ServerScriptService:WaitForChild("ArenaManager"))

-- This event fires when a player touches a checkpoint that is flagged for PvP
PvP.Event:Connect(function(player, checkpointName)
	print(("[PvPHandler] %s triggered a PvP battle at checkpoint: %s")
		:format(player.Name, checkpointName))

	-- Now we pass both the player and the checkpointName to ArenaManager.
	ArenaManager:RequestPvP(player, checkpointName)
end)
