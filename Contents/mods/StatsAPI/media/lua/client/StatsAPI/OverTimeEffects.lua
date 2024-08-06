local OverTimeEffects = {}

---@param stats CharacterStats
---@param stat string
---@param amount number
---@param duration number
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