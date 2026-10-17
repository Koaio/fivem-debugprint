--- @author    (@ItsZmainDev)
--- @version   1.0.0
--- @license   Custom (based on MIT) - see LICENSE file
--- @repo      https://github.com/Koaio/fivem-debugprint

--- Basic ---

do
    local function isAdmin()
        return true
    end

    local player <const> = {
        name = "Zmain",
        health = 100,
        coords = vec3(0.0, 0.0, 0.0),
        admin = isAdmin(),
        func = isAdmin
    }

    debugPrint(player)
    --- Tag ---

    local CFG <const> = {
        anticheat = {
            antiNoclip = true,
            antiFreecam = true,
        },
    }

    local TAG <const> = "Config"

    debugPrint(CFG, {
        tag = TAG
    })
end

--- Identation ---

do
    local ENTITIES <const> = {
        "entity:1",
        "entity:2",
        "entity: 3"
    }

    local INDENT <const> = true

    debugPrint(ENTITIES, {
        indent = INDENT
    })
end

--- Limit ---

do
    local VEHICLES <const> = {
        compact = {
            panto = joaat("panto"),
        },
        sport = {
            sultanrs = joaat("sultanrs"),
            super = {
                t20 = joaat("t20"),
                osiris = {
                    hash = joaat("osiris") -- depth 3 -> <max-depth>
                }
            }
        }
    }

    local MAX_DEPTH <const> = 3

    debugPrint(VEHICLES, {
        maxDepth = MAX_DEPTH
    })
end

--- Combined ---

do
    local DATA <const> = {
        game = "gta5",
        server = {
            name = "fivem",
            owner = {
                discord = "Koaio" -- depth 2 -> <max-depth>
            }
        }
    }

    local CFG <const> = {
        tag = "Player",
        indent = true,
        maxDepth = 2
    }

    debugPrint(DATA, CFG)
end

--- Metatable ---

do
    local myTable = {}
    
    local __instance = {
        __index = myTable,
    }
    
    function myTable.New(data)
        return setmetatable({
            name = data.name
        }, __instance)
    end
    
    --- @param name string
    function myTable:updateName(name)
        assert(type(name) == "string", "name is not a string")
    
        self.name = name
    end
    
    local instance <const> = myTable.New({
        name = "ItsZmainDev"
    })
    
    instance:updateName("Koaio")
    
    debugPrint(instance)

    debugPrint(instance, {
        showMeta = true
    })
end

--- Not iterable ---

do
    debugPrint(function() end)
end

--- No Data ---

do
    debugPrint(nil)
end
