---@class OverTimeEffect
---@field timeRemaining number The game time length the effect should remain active
---@field amount number The amount the effect the stat should increase by per second
---@field stat string String name of the stat this effect changes

local OverTimeEffects = {}

---@param stats CharacterStats
---@param stat string
---@param amount number
---@param duration number
---@return OverTimeEffect
OverTimeEffects.create = function(stats, stat, amount, duration)
    if not stats.stats[stat] then error("StatsAPI: Invalid stat identifier for OverTimeEffect") end

    ---@type OverTimeEffect
    local overTimeEffect = {
        stat = stat,
        timeRemaining = duration,
        amount = amount
    }

    table.insert(stats.overTimeEffects, overTimeEffect)
    return overTimeEffect
end

return OverTimeEffects