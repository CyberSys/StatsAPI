local Math = require "StatsAPI/lib/Math"
local Globals = require "StatsAPI/Globals"

local StatsContainer = require "StatsAPI/StatsContainer"
local LuaMoodles = require "StatsAPI/moodles/LuaMoodles"

local Thirst = require "StatsAPI/stats/Thirst"
local Hunger = require "StatsAPI/stats/Hunger"
local Panic = require "StatsAPI/stats/Panic"
local Stress = require "StatsAPI/stats/Stress"
local Fatigue = require "StatsAPI/stats/Fatigue"
local Boredom = require "StatsAPI/stats/Boredom"
local Sadness = require "StatsAPI/stats/Sadness"
local CarryWeight = require "StatsAPI/stats/CarryWeight"

---@class CharacterStats
---@field stats StatsContainer The character's stats
---
---@field character IsoGameCharacter The character this StatsData belongs to
---@field playerNum int The character's playerNum
---@field bodyDamage BodyDamage The character's BodyDamage object
---@field javaStats Stats The character's Stats object
---@field moodles Moodles The character's Moodles object
---@field thermoregulator Thermoregulator The character's Thermoregulator object
---@field luaMoodles LuaMoodles The character's LuaMoodles object
---@field tickCount int How many times this character's stats have been updated
---@field private modData table Mod data table to store persistent data in
---
---@field maxWeightDelta number The character's carry weight multiplier from traits
---@field panicMultiplier number The character's panic multiplier from traits
---@field thirstMultiplier number The character's thirst multiplier from traits
---@field hungerMultiplier number The character's hunger multiplier from traits
---@field sleepEfficiency number The character's sleeping efficiency
---@field fatigueMultiplierAwake number The character's fatigue multiplier from traits while awake
---@field fatigueMultiplierAsleep number The character's fatigue multiplier from traits while asleep
---@field panicIncrease number Multiplier on the character's panic increases
---@field panicReduction number Multiplier on the character's panic reductions
---
---@field forceWakeUp boolean Forces the character to wake up on the next frame if true
---@field forceWakeUpTime number Forces the character to wake up at this time if not nil
---@field timeUntilSleep number A timer, in hours, until the player will actually regain fatigue from sleeping
---
---@field oldNumZombiesVisible number The number of zombies the character could see on the previous frame
---@field wellFed boolean Does the character have a food buff active?
---@field carryWeight number The character's current maximum carry weight
---@field temperature number The character's current temperature
---@field vehicle BaseVehicle? The character's current vehicle
---@field reading boolean Is the character currently reading?
---@field overTimeEffects OverTimeEffect[] The character's active OverTimeEffects
local CharacterStats = {}
CharacterStats.panicIncrease = 7
CharacterStats.panicReduction = 0.06
CharacterStats.oldNumZombiesVisible = 0
CharacterStats.forceWakeUp = false
CharacterStats.asleep = false
CharacterStats.timeUntilSleep = 0
CharacterStats.staticCarryMod = 0
CharacterStats.tickCount = 0

CharacterStats.persistentStats = {forceWakeUpTime = true, overTimeEffects = true}

---@param key any
CharacterStats.__index = function(self, key)
    if CharacterStats.persistentStats[key] then
        return self.modData[key]
    end
    return CharacterStats[key]
end

---@param key any
---@param value any
CharacterStats.__newindex = function(self, key, value)
    if CharacterStats.persistentStats[key] then
        self.modData[key] = value
    else
        rawset(self, key, value)
    end
end

---@private
---@param character IsoPlayer
---@return CharacterStats
CharacterStats.new = function(character)
    local o = {}
    setmetatable(o, CharacterStats)
    ---@cast o CharacterStats

    o.character = character
    o.playerNum = character:getPlayerNum()
    o.bodyDamage = character:getBodyDamage()
    o.moodles = character:getMoodles()
    o.javaStats = character:getStats()
    o.thermoregulator = o.bodyDamage:getThermoregulator()
    o.stats = StatsContainer.new(o.javaStats, o.bodyDamage)

    local modData = character:getModData()
    modData.StatsAPI = modData.StatsAPI or {}
    modData.StatsAPI.StatsData = modData.StatsAPI.StatsData or {}
    o.modData = modData.StatsAPI.StatsData

    o.modData.overTimeEffects = o.modData.overTimeEffects or {}

    return o
end

CharacterStats.updateThirst = Thirst.updateThirst
CharacterStats.updateHunger = Hunger.updateHunger
CharacterStats.updatePanic = Panic.updatePanic
CharacterStats.updateStress = Stress.updateStress
CharacterStats.updateFatigue = Fatigue.updateFatigue
CharacterStats.updateSleep = Fatigue.updateSleep
CharacterStats.updateBoredom = Boredom.updateBoredom
CharacterStats.getIdleBoredom = Boredom.getIdleBoredom
CharacterStats.updateSadness = Sadness.updateSadness
CharacterStats.updateCarryWeight = CarryWeight.updateCarryWeight

CharacterStats.updateEndurance = function(self)
    if self.character:isUnlimitedEndurance() then
        self.stats.endurance = 1
        return
    end
    
    if self.asleep then
        local enduranceMultiplier = 2
        if IsoPlayer.allPlayersAsleep() then
            enduranceMultiplier = enduranceMultiplier * Globals.deltaMinutesPerDay
        end
        self.stats.endurance = self.stats.endurance + ZomboidGlobals.ImobileEnduranceIncrease * Globals.sandboxOptions:getEnduranceRegenMultiplier() * self.character:getRecoveryMod() * Globals.multiplier * enduranceMultiplier
    end
end

CharacterStats.updateFitness = function(self)
    self.javaStats:setFitness(self.character:getPerkLevel(Perks.Fitness) / 5 - 1)
end

CharacterStats.updateCache = function(self)
    self.asleep = self.character:isAsleep()
    self.vehicle = self.character:getVehicle()
    self.reading = self.character:isReading()
    self.wellFed = self:getMoodleLevel(Globals.Moodles.FoodEaten) ~= 0
    self.temperature = self.bodyDamage:getTemperature()
end

CharacterStats.refreshTraits = function(self)
    self.maxWeightDelta = CarryWeight.getMaxWeightDelta(self.character)
    self.panicMultiplier = Panic.getTraitMultiplier(self.character)
    self.thirstMultiplier = Thirst.getThirstMultiplier(self.character)
    self.hungerMultiplier = Hunger.getAppetiteMultiplier(self.character)
    self.sleepEfficiency = Fatigue.getSleepEfficiency(self.character)
    self.fatigueMultiplierAwake, self.fatigueMultiplierAsleep = Fatigue.getFatigueRates(self.character)
end

CharacterStats.CalculateStats = function(self)
    self.stats:fromJava()
    
    if self.tickCount % 2000 == 0 then -- weight traits update every 2000 ticks
        self:refreshTraits()
    end
    
    self:updateCache()

    -- Stats stats
    self:updateStress()
    self:updateEndurance()
    self:updateThirst()
    self:updateFatigue()
    self:updateHunger()
    self:updateFitness()
    
    -- BodyDamage stats
    self:updatePanic()
    self:updateBoredom()
    self:updateSadness()
    
    if self.asleep then
        self:updateSleep()
    end
    
    self:applyOverTimeEffects()
    
    self:updateCarryWeight()
    
    self:updateMoodles()
    
    self.stats:toJava()
    self.tickCount = self.tickCount + 1
    
    self.character:autoDrink()
end

CharacterStats.moodleThresholds = {
    stress = {0.25, 0.5, 0.75, 0.9},
    foodeaten = {0, 1600, 3200, 4800},
    endurance = {0.25, 0.5, 0.75, 0.9},
    tired = {0.6, 0.7, 0.8, 0.9},
    hungry = {0.15, 0.25, 0.45, 0.7},
    panic = {6, 30, 65, 80},
    sick = {0.25, 0.5, 0.75, 0.9},
    bored = {25, 50, 75, 90},
    unhappy = {20, 45, 60, 80},
    thirst = {0.12, 0.25, 0.7, 0.84},
    wet = {15, 40, 70, 90},
    hasacold = {20, 40, 60, 75},
    injured = {20, 40, 60, 75},
    pain = {10, 20, 50, 75},
    heavyload = {1, 1.25, 1.5, 1.75},
    drunk = {10, 30, 50, 70},
    windchill = {5, 10, 15, 20},
    hyperthermia = {37.5, 39, 40, 41}
}

CharacterStats.updateMoodles = function(self)
    -- TODO: ugh
    local stats = {stress = self.stats.stress + self.javaStats:getStressFromCigarettes(), foodeaten = self.bodyDamage:getHealthFromFoodTimer(), endurance = 1 - self.stats.endurance,
    tired = self.stats.fatigue, hungry = self.stats.hunger, panic = self.stats.panic, sick = self.javaStats:getSickness(),
    bored = self.stats.boredom, unhappy = self.stats.sadness, thirst = self.stats.thirst, wet = self.bodyDamage:getWetness(),
    hasacold = self.bodyDamage:getColdStrength(), injured = 100 - self.bodyDamage:getHealth(), pain = self.javaStats:getPain(),
    heavyload = self.character:getInventory():getCapacityWeight() / self.carryWeight, drunk = self.javaStats:getDrunkenness(),
    windchill = Temperature.getWindChillAmountForPlayer(self.character), hyperthermia = self.temperature}
    
    for moodle, thresholds in pairs(CharacterStats.moodleThresholds) do
        local desiredLevel = 0
        for i = #thresholds, 1, -1 do
            if stats[moodle] > thresholds[i] then
                desiredLevel = i
                break
            end
        end
        self.luaMoodles.moodles[moodle]:setLevel(desiredLevel)
    end
    
    self.luaMoodles.moodles.bleeding:setLevel(Math.min(self.bodyDamage:getNumPartsBleeding(), 4))
    local cantSprint = self.luaMoodles.moodles.CantSprint
    if self.character.MoodleCantSprint then
        cantSprint:setLevel(1)
        cantSprint:wiggle()
    else
        cantSprint:setLevel(0)
    end
    
    self:updateTemperatureMoodles()
end

CharacterStats.updateTemperatureMoodles = function(self)
    local drunkenness = self.javaStats:getDrunkenness()
    local hypothermia = self.luaMoodles.moodles.hypothermia
    
    local desiredLevel = 0
    if self.temperature < 25 then
        desiredLevel = 4
    elseif self.temperature < 30 then
        desiredLevel = 3
    elseif self.temperature < 35 and drunkenness <= 70 then
        desiredLevel = 2
    elseif self.temperature < 36.5 and drunkenness <= 30 then
        desiredLevel = 1
    end
    hypothermia:setLevel(desiredLevel)
    
    if desiredLevel > 0 then
        hypothermia.chevronCount = self.thermoregulator:thermalChevronCount()
        local up = self.thermoregulator:thermalChevronUp()
        hypothermia.chevronUp = up
        hypothermia.chevronPositive = up
    end
    
    -- hyperthermia already gets set by the main loop
    local hyperthermia = self.luaMoodles.moodles.hyperthermia
    if hyperthermia.level > 0 then
        hyperthermia.chevronCount = self.thermoregulator:thermalChevronCount()
        local up  = self.thermoregulator:thermalChevronUp()
        hyperthermia.chevronUp = up
        hyperthermia.chevronPositive = not up
    end
end

CharacterStats.applyOverTimeEffects = function(self)
    for j = 1, #self.overTimeEffects do
        local effect = self.overTimeEffects[j]
        local delta = Globals.delta
        effect.timeRemaining = effect.timeRemaining - delta
        if effect.timeRemaining <= 0 then
            table.remove(self.overTimeEffects, j)
            delta = delta + effect.timeRemaining
        end
        self.stats[effect.stat] = self.stats[effect.stat] + effect.amount * delta
    end
end

---@param moodle string
---@return int
---@see LuaMoodles.getMoodleLevel
CharacterStats.getMoodleLevel = function(self, moodle)
    return self.luaMoodles:getMoodleLevel(moodle)
end

---@type table<IsoGameCharacter, CharacterStats>
CharacterStats.CharacterStatsMap = {}

---@param character IsoGameCharacter
---@return CharacterStats
CharacterStats.create = function(character)
    local stats = CharacterStats.new(character)
    CharacterStats.CharacterStatsMap[character] = stats
    return stats
end

---@param character IsoGameCharacter
---@return CharacterStats
CharacterStats.getOrCreate = function(character)
    local stats = CharacterStats.CharacterStatsMap[character]
    if not stats then
        stats = CharacterStats.new(character)
        CharacterStats.CharacterStatsMap[character] = stats
    end
    return stats
end

---@param character IsoGameCharacter
---@return CharacterStats?
CharacterStats.get = function(character)
    return CharacterStats.CharacterStatsMap[character]
end



---@param character IsoPlayer
CharacterStats.OnCalculateStats = function(character)
    local stats = CharacterStats.get(character)
    if not stats then return end
    stats:CalculateStats()
end

Hook.CalculateStats.Add(CharacterStats.OnCalculateStats)

---@param playerIndex int
---@param player IsoPlayer
CharacterStats.preparePlayer = function(playerIndex, player)
    if LuaMoodles.instanceMap[playerIndex] then
        LuaMoodles.instanceMap[playerIndex]:cleanup()
    end
    local stats = CharacterStats.create(player)
    stats.luaMoodles = LuaMoodles.create(stats)
    Panic.disableVanillaPanic(player)
end

Events.OnCreatePlayer.Add(CharacterStats.preparePlayer)

---@param player IsoPlayer
CharacterStats.onDeath = function(player)
    CharacterStats.get(player).luaMoodles:onDeath()
end
Events.OnPlayerDeath.Add(CharacterStats.onDeath)

return CharacterStats