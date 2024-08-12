local CharacterStats = require "StatsAPI/CharacterStats"

local isoPlayer = __classmetatables[IsoPlayer.class].__index

---@type fun(self:IsoGameCharacter, ForceWakeUpTime:float)
local old_setForceWakeUpTime = isoPlayer.setForceWakeUpTime
---@param self IsoGameCharacter
---@param ForceWakeUpTime float
isoPlayer.setForceWakeUpTime = function(self, ForceWakeUpTime)
    CharacterStats.getOrCreate(self).forceWakeUpTime = ForceWakeUpTime
    old_setForceWakeUpTime(self, ForceWakeUpTime)
end

---@type fun(self:IsoGameCharacter)
local old_forceAwake = isoPlayer.forceAwake
---@param self IsoGameCharacter
isoPlayer.forceAwake = function(self)
    if self:isAsleep() then
        CharacterStats.getOrCreate(self).forceWakeUp = true
    end
    old_forceAwake(self)
end

---@type fun(self:IsoPlayer, maxWeightDelta:float)
local old_setMaxWeightDelta = isoPlayer.setMaxWeightDelta
---@param self IsoPlayer
---@param maxWeightDelta float
isoPlayer.setMaxWeightDelta = function(self, maxWeightDelta)
    CharacterStats.getOrCreate(self).maxWeightDelta = maxWeightDelta
    old_setMaxWeightDelta(self, maxWeightDelta)
end

-- TODO: possible optimisation: this delegates to Moodles.getMoodleLevel but that function then searches for the IsoPlayer, which we already have in this case
-- TODO: hard overwrite :(
---@param self IsoPlayer
---@param moodleType MoodleType
---@return integer
isoPlayer.getMoodleLevel = function(self, moodleType)
    return self:getMoodles():getMoodleLevel(moodleType)
end