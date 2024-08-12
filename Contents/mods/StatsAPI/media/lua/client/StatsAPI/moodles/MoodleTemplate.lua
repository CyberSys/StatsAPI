local Moodles = require("StatsAPI/Globals").Moodles

---@class MoodleTranslation
---@field name string
---@field desc string

---@class MoodleTemplate
---@field type string
---@field texture Texture
---@field text MoodleTranslation[]
---@field backgrounds Texture[]
local MoodleTemplate = {}
---@type MoodleTemplate[]
MoodleTemplate.templates = table.newarray()
---@type table<string, Texture[]>
MoodleTemplate.Backgrounds = {
    Positive = table.newarray(
        getTexture("media/ui/Moodles/Moodle_Bkg_Good_1.png"),
        getTexture("media/ui/Moodles/Moodle_Bkg_Good_2.png"),
        getTexture("media/ui/Moodles/Moodle_Bkg_Good_3.png"),
        getTexture("media/ui/Moodles/Moodle_Bkg_Good_4.png")
    ),
    Negative = table.newarray(
        getTexture("media/ui/Moodles/Moodle_Bkg_Bad_1.png"),
        getTexture("media/ui/Moodles/Moodle_Bkg_Bad_2.png"),
        getTexture("media/ui/Moodles/Moodle_Bkg_Bad_3.png"),
        getTexture("media/ui/Moodles/Moodle_Bkg_Bad_4.png")
)
}

---@param type string
---@param texture Texture
---@param backgrounds Texture[]
---@param text table<table<string, string>>
---@return MoodleTemplate
MoodleTemplate.new = function(type, texture, backgrounds, text)
    ---@type MoodleTemplate
    local o = {
        type = type,
        texture = texture,
        backgrounds = backgrounds,
        text = text
    }
    setmetatable(o, MoodleTemplate)

    table.insert(MoodleTemplate.templates, o)
    return o
end

-- these are needed for the mod to function
MoodleTemplate.new(Moodles.Dead, getTexture("media/ui/Moodles/Moodle_Icon_Dead.png"), MoodleTemplate.Backgrounds.Negative,
                   {{name=getText("Moodles_dead_lvl1"), desc=getText("Moodles_dead_desc_lvl1")}})

MoodleTemplate.new(Moodles.Zombie, getTexture("media/ui/Moodles/Moodle_Icon_Zombie.png"), MoodleTemplate.Backgrounds.Negative,
                   {{name=getText("Moodles_zombie_lvl1"), desc=getText("Moodles_zombified_desc_lvl1")}})


return MoodleTemplate