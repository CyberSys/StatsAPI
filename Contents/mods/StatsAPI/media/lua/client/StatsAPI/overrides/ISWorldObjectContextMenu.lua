local CharacterStats = require "StatsAPI/CharacterStats"
local Fatigue = require "StatsAPI/stats/Fatigue"

---@param player integer
---@param bed IsoObject|nil
ISWorldObjectContextMenu.onSleepWalkToComplete = function(player, bed)
    Fatigue.trySleep(CharacterStats.get(getSpecificPlayer(player)), bed)
end