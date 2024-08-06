local CharacterStats = require "StatsAPI/CharacterStats"
local OverTimeEffects = require "StatsAPI/OverTimeEffects"
local MoodleTemplate = require "StatsAPI/moodles/MoodleTemplate"

local Fatigue = require "StatsAPI/stats/Fatigue"
local Hunger = require "StatsAPI/stats/Hunger"
local Thirst = require "StatsAPI/stats/Thirst"
local Stress = require "StatsAPI/stats/Stress"
local Panic = require "StatsAPI/stats/Panic"
local CarryWeight = require "StatsAPI/stats/CarryWeight"

local StatsAPI = {}

---Adds a fatigue multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param awakeModifier number The fatigue multiplier to give characters with the trait while they are awake
---@param asleepModifier number The fatigue multiplier to give characters with the trait while they are asleep
---@overload fun(trait:string, awakeModifier:number)
---@overload fun(trait:string, awakeModifier:nil, asleepModifier:number)
StatsAPI.addTraitFatigueModifier = function(trait, awakeModifier, asleepModifier)
    Fatigue.fatigueRate.awake[trait] = awakeModifier
    Fatigue.fatigueRate.asleep[trait] = asleepModifier
end

---Adds a sleeping efficiency multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param modifier number The sleeping efficiency multiplier to give characters with the trait
StatsAPI.addTraitSleepModifier = function(trait, modifier)
    Fatigue.sleepEfficiency[trait] = modifier
end

---Adds a sleep duration multiplier to apply to characters who have the given trait.
StatsAPI.addTraitSleepDurationModifier = function(trait, modifier)
    Fatigue.sleepLength[trait] = modifier
end

---Adds a hunger multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param modifier number The hunger multiplier to give characters with the trait
StatsAPI.addTraitHungerModifier = function(trait, modifier)
    Hunger.appetiteMultipliers[trait] = modifier
end

---Adds a thirst multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param modifier number The thirst multiplier to give characters with the trait
StatsAPI.addTraitThirstModifier = function(trait, modifier)
    Thirst.thirstMultipliers[trait] = modifier
end

---Adds a panic multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param modifier number The panic multiplier to give characters with the trait
StatsAPI.addTraitPanicModifier = function(trait, modifier)
    Panic.traitMultipliers[trait] = modifier
end

---Adds a carry weight multiplier to apply to characters who have the given trait.
---@param trait string The ID of the trait
---@param modifier number The panic multiplier to give characters with the trait
StatsAPI.addCarryWeightModifier = function(trait, modifier)
    CarryWeight.maxWeightMultipliers[trait] = modifier
end


---Adds an amount of a stat to a character over the specified time in real seconds, adjusted by day length.
---@param character IsoGameCharacter The character to apply the effect to
---@param stat string The stat to add to
---@param total number The total amount of the stat to add
---@param time number The time in seconds it should take to complete the effect
StatsAPI.addOverTimeEffect = function(character, stat, total, time)
    time = time * 24
    OverTimeEffects.create(CharacterStats.get(character), stat, total / time, time)
end

---Adds an amount of a stat to a character over the specified time in game-world hours.
---@param character IsoGameCharacter The character to apply the effect to
---@param stat string The stat to add to
---@param total number The total amount of the stat to add
---@param time number The time in seconds it should take to complete the effect
StatsAPI.addOverTimeEffectHours = function(character, stat, total, time)
    StatsAPI.addOverTimeEffect(character, stat, total, time * 150)
end

---Adds a constant amount of the stat to the character for the duration in seconds.
---@param character IsoGameCharacter The character to apply the effect to
---@param stat string The stat to add to
---@param amount number The amount of the stat to add every second
---@param duration number The number of seconds the effect should be active
StatsAPI.addConstantEffect = function(character, stat, amount, duration)
    duration = duration * 24
    OverTimeEffects.create(CharacterStats.get(character), stat, amount / 24, duration)
end

---Adds a constant amount of the stat to the character for the duration in hours.
---@param character IsoGameCharacter The character to apply the effect to
---@param stat string The stat to add to
---@param amount number The amount of the stat to add every hour
---@param duration number The number of hours the effect should be active
StatsAPI.addConstantEffectHours = function(character, stat, amount, duration)
    StatsAPI.addConstantEffect(character, stat, amount / 3600, duration * 3600)
end

---Toggles whether being injured causes characters to gain stress.
---@param injuryStress boolean Should injuries cause stress?
StatsAPI.setStressFromInjuries = function(injuryStress)
    Stress.injuryStress = injuryStress
end

---Toggles whether being infected with the Knox virus causes characters to gain stress.
---@param infectionStress boolean Should infection cause stress?
StatsAPI.setStressFromInfection = function(infectionStress)
    Stress.infectionStress = infectionStress
end

---Adds a constant change to stress, with the value set to a percent of the maximum over a day
---@param sourceName string The name of the stress source for later identification
---@param dailyChange number The percent amount the stat should change by over a day
StatsAPI.addStressChangeDaily = function(sourceName, dailyChange)
    Stress.modChanges[sourceName] = dailyChange / 86400
end

---Adds a constant change to stress, with the value set to a percent of the maximum over an hour
---@param sourceName string The name of the stress source for later identification
---@param hourlyChange number The percent amount the stat should change by over an hour
StatsAPI.addStressChangeHourly = function(sourceName, hourlyChange)
    Stress.modChanges[sourceName] = hourlyChange / 3600
end

---Removes a previously added change to stress
---@param sourceName string The name of the stress source for later identification
StatsAPI.removeStressChange = function(sourceName)
    Stress.modChanges[sourceName] = nil
end

---Adds a constant change to hunger, with the value set to a percent of the maximum over a day
---@param sourceName string The name of the stress source for later identification
---@param dailyChange number The percent amount the stat should change by over a day
StatsAPI.addHungerChangeDaily = function(sourceName, dailyChange)
    Hunger.modChanges[sourceName] = dailyChange / 86400
end

---Adds a constant change to hunger, with the value set to a percent of the maximum over an hour
---@param sourceName string The name of the stress source for later identification
---@param hourlyChange number The percent amount the stat should change by over an hour
StatsAPI.addHungerChangeHourly = function(sourceName, hourlyChange)
    Hunger.modChanges[sourceName] = hourlyChange / 3600
end

---Removes a previously added change to hunger
---@param sourceName string The name of the stress source for later identification
StatsAPI.removeHungerChange = function(sourceName)
    Hunger.modChanges[sourceName] = nil
end

---Adds a constant change to thirst, with the value set to a percent of the maximum over a day
---@param sourceName string The name of the stress source for later identification
---@param dailyChange number The percent amount the stat should change by over a day
StatsAPI.addThirstChangeDaily = function(sourceName, dailyChange)
    Thirst.modChanges[sourceName] = dailyChange / 86400
end

---Adds a constant change to thirst, with the value set to a percent of the maximum over an hour
---@param sourceName string The name of the stress source for later identification
---@param hourlyChange number The percent amount the stat should change by over an hour
StatsAPI.addThirstChangeHourly = function(sourceName, hourlyChange)
    Thirst.modChanges[sourceName] = hourlyChange / 3600
end

---Removes a previously added change to fatigue
---@param sourceName string The name of the stress source for later identification
StatsAPI.removeThirstChange = function(sourceName)
    Thirst.modChanges[sourceName] = nil
end

---Adds a function that has to return a change in stress, with the value adjusted for daily change
---@param sourceName string The name of the stress source for later identification
---@param dailyChange function The function that returns a percentage change over a day
StatsAPI.addStressChangeFunctionDaily = function(sourceName, dailyChange)
    Stress.modFunctions[sourceName] = {dailyChange, 86400}
end

---Adds a function that has to return a change in stress, with the value adjusted for hourly change
---@param sourceName string The name of the stress source for later identification
---@param hourlyChange function The function that returns a percentage change over an hour
StatsAPI.addStressChangeFunctionHourly = function(sourceName, hourlyChange)
    Stress.modFunctions[sourceName] = {hourlyChange, 3600}
end

---Removes a previously added change to stress
---@param sourceName string The name of the stress source for later identification
StatsAPI.removeStressFunctionChange = function(sourceName)
    Stress.modFunctions[sourceName] = nil
end

---Adds a function that has to return a change in hunger, with the value adjusted for daily change
---@param sourceName string The name of the stress source for later identification
---@param dailyChange function The function that returns a percentage change over a day
StatsAPI.addHungerFunctionChangeDaily = function(sourceName, dailyChange)
    Hunger.modFunctions[sourceName] = {dailyChange, 86400}
end

---Adds a function that has to return a change in hunger, with the value adjusted for hourly change
---@param sourceName string The name of the stress source for later identification
---@param hourlyChange function The function that returns a percentage change over an hour
StatsAPI.addHungerFunctionChangeHourly = function(sourceName, hourlyChange)
    Hunger.modFunctions[sourceName] = {hourlyChange, 3600}
end

---Removes a previously added change to hunger
---@param sourceName string The name of the stress source for later identification
StatsAPI.removeHungerFunctionChange = function(sourceName)
    Hunger.modFunctions[sourceName] = nil
end

---Adds a function that has to return a change in thurst, with the value adjusted for daily change
---@param sourceName string The name of the stress source for later identification
---@param dailyChange function The function that returns a percentage change over a day
StatsAPI.addThirstFunctionChangeDaily = function(sourceName, dailyChange)
    Thirst.modFunctions[sourceName] = {dailyChange, 86400}
end

---Adds a function that has to return a change in thirst, with the value adjusted for hourly change
---@param sourceName string The name of the stress source for later identification
---@param hourlyChange function The function that returns a percentage change over an hour
StatsAPI.addThirstFunctionChangeHourly = function(sourceName, hourlyChange)
    Thirst.modFunctions[sourceName] = {hourlyChange, 3600}
end

---Removes a previously added change to fatigue
---@param sourceName string The name of the stress source for later identification
StatsAPI.removeThirstChange = function(sourceName)
    Thirst.modChanges[sourceName] = nil
end

---Prevents the vanilla trait effects from being added. Must be called before OnGameBoot or it will have no effect.
StatsAPI.disableVanillaTraits = function()
    local Vanilla = require "StatsAPI/vanilla/VanillaTraits"
    Vanilla.wantVanilla = false
end

---Increases the character's maximum carry weight by amount. If character is nil, it changes the default value instead.
---@param character IsoGameCharacter
---@param amount number
---@overload fun(character:nil, amount:IsoGameCharacter)
StatsAPI.addCarryWeight = function(character, amount)
    if character then
        local stats = CharacterStats.get(character)
        if not stats then error("StatsAPI: Invalid character for carry weight modifier") return end
        stats.staticCarryMod = stats.staticCarryMod + amount
    else
        CharacterStats.staticCarryMod = CharacterStats.staticCarryMod + amount
    end
end

local moodleName = "Moodles_%s_lvl%d"
local moodleDesc = "Moodles_%s_desc_lvl%d"

---Adds a new moodle. The new moodle will not be added retroactively to existing players, so this should be used before gameplay starts.
---@param moodleType string Identifier for the moodle. Also used in determining the translation string for its names
---@param icon Texture|string Icon for the moodle.
---@param levels? int How many levels the moodle should have. (Default: 4)
---@param positive? boolean Whether the moodle is a positive moodle. (Changes the background sprite, defaults to false)
---@param translationId? string Identifier for the moodle's translations, if it is different to moodleType
---@param descIdentifier? string Identifier for the moodle's description translations, if it is different to moodleType *and* translationId
StatsAPI.addMoodle = function(moodleType, icon, levels, positive, translationId, descIdentifier)
    if type(icon) == "string" then
        icon = getTexture(icon)
    end
    levels = levels or 4
    
    local backgrounds = not positive and MoodleTemplate.Backgrounds.Negative or MoodleTemplate.Backgrounds.Positive
    local translations = {}
    
    local nameId = translationId or moodleType
    local descId = descIdentifier or nameId
    
    if levels == 1 then
        translations[1] = {name = getText("Moodles_" .. nameId), desc = getText("Moodles_" .. descId .. "_desc")}
    else
        for i = 1, levels do
            local name = getText(string.format(moodleName, nameId, i))
            local desc = getText(string.format(moodleDesc, descId, i))
            translations[i] = {name = name, desc = desc}
        end
    end
    
    MoodleTemplate:new(moodleType, icon, backgrounds, translations)
end

---Sets the level of a player's moodle.
---@param player IsoPlayer The player whose moodle to change.
---@param moodleType string The type of moodle to change.
---@param level int The moodle level to set.
StatsAPI.setMoodleLevel = function(player, moodleType, level)
    CharacterStats.get(player).luaMoodles.moodles[moodleType]:setLevel(level)
end

---Returns the level of a player's moodle.
---@param player IsoPlayer The player whose moodle level to return.
---@param moodleType string The type of moodle to return.
StatsAPI.getMoodleLevel = function(player, moodleType)
    return CharacterStats.get(player):getMoodleLevel(moodleType)
end

---Makes a moodle wiggle. Generally used to indicate when a moodle is affecting a player. Called automatically when the moodle's level changes.
---@param player IsoPlayer The player whose moodle to wiggle.
---@param moodleType string The type of moodle to wiggle.
StatsAPI.wiggleMoodle = function(player, moodleType)
    CharacterStats.get(player).luaMoodles.moodles[moodleType]:wiggle()
end

---Sets the chevron (arrows) on a moodle. Generally used to indicate the trend in change in intensity of a moodle.
---@param player IsoPlayer The player whose moodle to change.
---@param moodleType string The type of moodle to change.
---@param numChevrons int The amount of chevrons to display.
---@param down? boolean Should the chevron point down? Defaults to no change (false if unset)
---@param positive? boolean Changes the colour of the chevron based on whether it's a positive or negative change. Defaults to no change (true if unset)
StatsAPI.setMoodleChevron = function(player, moodleType, numChevrons, down, positive)
    local moodle = CharacterStats.get(player).luaMoodles.moodles[moodleType]
    moodle.chevronCount = numChevrons
    if down ~= nil then
        moodle.chevronUp = down
    end
    if positive ~= nil then
        moodle.chevronPositive = positive
    end
end

StatsAPI.MoodleType = require("StatsAPI/Globals").Moodles

return StatsAPI