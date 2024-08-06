local MoodleTemplate = require "StatsAPI/moodles/MoodleTemplate"
local LuaMoodle = require "StatsAPI/moodles/LuaMoodle"

---@class LuaMoodles
---@field playerNum int
---@field stats CharacterStats
---@field moodles table<string, LuaMoodle>
---@field showingMoodles LuaMoodle[]
local LuaMoodles = {}
---@type LuaMoodles[]
LuaMoodles.instanceMap = {}
LuaMoodles.scale = 1
LuaMoodles.spacing = 36
LuaMoodles.rightOffset = 18
LuaMoodles.topOffset = 100

---@private
---@param self LuaMoodles
---@param stats CharacterStats
LuaMoodles.new = function(self, stats)
    local o = {}
    setmetatable(o, self)
    
    o.stats = stats
    o.playerNum = stats.playerNum
    
    o.showingMoodles = {}
    o.moodles = {}
    for i = 1, #MoodleTemplate.templates do
        local template = MoodleTemplate.templates[i]
        local moodle = LuaMoodle:new(0, 0, template, o) -- position will be overriden by adjustPosition anyway
        o.moodles[template.type] = moodle
    end
    
    return o
end

---@param self LuaMoodles
---@param moodle LuaMoodle
LuaMoodles.showMoodle = function(self, moodle)
    table.insert(self.showingMoodles, moodle)
    self:sortMoodles()
end

---@param self LuaMoodles
---@param moodle LuaMoodle
LuaMoodles.hideMoodle = function(self, moodle)
    for i = 1, #self.showingMoodles do
        if self.showingMoodles[i] == moodle then
            table.remove(self.showingMoodles, i)
            break
        end
    end
    self:sortMoodles()
end

---@param self LuaMoodles
LuaMoodles.sortMoodles = function(self)
    for i = 1, #self.showingMoodles do
        self.showingMoodles[i]:setRenderIndex(i)
    end
end

---@param self LuaMoodles
LuaMoodles.adjustPosition = function(self)
    local x = getPlayerScreenLeft(self.playerNum) + getPlayerScreenWidth(self.playerNum) - LuaMoodles.rightOffset - 32 * self.scale
    local y = getPlayerScreenTop(self.playerNum) + LuaMoodles.topOffset
    
    for _, moodle in pairs(self.moodles) do
        moodle:setX(x)
        moodle.baseY = y
        moodle:updateHeightWidth()
    end
    self:sortMoodles()
end

---@param self LuaMoodles
---@param moodle string
---@return int
LuaMoodles.getMoodleLevel = function(self, moodle)
    return self.moodles[moodle].level
end

---@param stats CharacterStats
LuaMoodles.create = function(stats)
    local moodles = LuaMoodles:new(stats)
    LuaMoodles.instanceMap[stats.playerNum] = moodles
    LuaMoodles.adjustPositions()
    return moodles
end

LuaMoodles.adjustPositions = function()
    for i = 0, 3 do
        local instance = LuaMoodles.instanceMap[i]
        if instance then
            instance:adjustPosition()
        end
    end
end

Events.OnResolutionChange.Add(LuaMoodles.adjustPositions)

---@param self LuaMoodles
LuaMoodles.cleanup = function(self)
    for _,moodle in pairs(self.moodles) do
        moodle:cleanup()
    end
    LuaMoodles.instanceMap[self.playerNum] = nil
end

---@param self LuaMoodles
LuaMoodles.onDeath = function(self)
    for i = #self.showingMoodles, 1, -1 do
        self.showingMoodles[i]:setLevel(0)
    end
    self.moodles.dead:setLevel(4)
    if self.stats.bodyDamage:getInfectionLevel() > 0.001 then
        self.moodles.zombie:setLevel(4)
    end
end



LuaMoodles.disableVanillaMoodles = function()
    local ui = UIManager.getUI()
    for i = 0, 3 do
        ui:remove(UIManager.getMoodleUI(i))
    end
end

Events.OnGameStart.Add(LuaMoodles.disableVanillaMoodles)

Events.OnTickEvenPaused.Add(function()
    for i = 0, 3 do
        local moodles = LuaMoodles.instanceMap[i]
        if moodles then
            for j = 1, #moodles.showingMoodles do
                moodles.showingMoodles[j]:updateOscillationLevel()
            end
        end
    end
end)

return LuaMoodles