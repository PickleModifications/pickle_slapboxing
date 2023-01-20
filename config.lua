Config = {}

Config.Debug = true

Config.Language = "en"

Config.Slapping = {
    DefaultHealth = 100, -- Initial player's health
    MaxDamage = 30, -- Max removal of health in a turn.
    DeathChance = 0, -- Change this to 1 - 100 for chance of dying from a knockout.
    MinPressDist = math.random(70, 80), -- Prevents macro spamming (Sometimes)
    MaxPresses = 40, -- When the press count for the charge up hits this number, it's max damage.
    SlappingLength = 3 * 1000, -- Max time someone can charge up their slap.
    SkillSize = 25, -- Hit Size
    SkillSpeed = 3, -- Hardest Slap Speed
}

Config.AllowedControls = {
    [51] = true, -- Slap
    [177] = true, -- Leave
    [249] = true, -- Push To Talk
}

Config.Items = {
    ["slaptable"] = {
        table = "default", -- Which table to use in Config.SlapTables
    },
}

Config.SlapTables = {
    ["default"] = {
        model = `v_res_tre_bedsidetable`, -- Model of Table
        offset = vector4(0.0, 1.0, -1.0, 0.0), -- Offset if placed. (x,y,z,heading)
        points = {
            home = vector3(0.0, -0.45, 0.75), -- Home Side Position.
            away = vector3(0.0, 0.45, 0.75), -- Away Side Position.
            menu = vector3(-0.65, 0.0, 0.75), -- Menu Position.
        },
        camera = {
            offset = vector3(2.0, 0.0, 1.5),
            heading = 270.0,
        }
    }
}

Config.CanRemoveTable = function(source, data) 
    if source == data.source then 
        return true
    else
        return false
    end
end
