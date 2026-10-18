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
        func = isAdmin -- -> "<function: test.lua:LINE>"
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

--- Indentation ---

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

    -- indent disabled -> single line
    debugPrint(ENTITIES, {
        indent = false
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

    debugPrint(instance) -- only { name = "Koaio" }

    debugPrint(instance, {
        showMeta = true -- adds "<meta>" with New / updateName
    })
end

--- Functions ---

do
    debugPrint(function() end) -- "<function: test.lua:LINE>"
end

--- No Data ---

do
    debugPrint(nil) -- "<nil>"
end

--- FiveM types ---

do
    debugPrint({
        vec2 = vec2(1.0, 2.0),
        vec3 = vec3(1.0, 2.0, 3.0),
        vec4 = vec4(1.0, 2.0, 3.0, 4.0),
        quat = quat(1.0, 0.0, 0.0, 0.0),
    })
end

--- NaN / inf ---

do
    debugPrint({
        nan = 0 / 0,          -- "<nan>"
        inf = math.huge,      -- "<inf>"
        negInf = -math.huge,  -- "<-inf>"
        normal = 42
    })
end

--- Cycle ---

do
    local node <const> = { name = "root" }
    node.self = node -- "<cycle:1>"

    local a, b = { name = "a" }, { name = "b" }
    a.other = b
    b.other = a -- indirect cycle

    debugPrint(node)
    debugPrint(a)
end

--- Proxy ---

do
    -- empty table with __index function -> "<proxy:MyProxy>"
    local proxy <const> = setmetatable({}, {
        __index = function() return nil end,
        __name = "MyProxy"
    })

    debugPrint(proxy)
end

--- Uniterable ---

do
    -- pairs() raises -> "<uniterable:Broken>"
    local broken <const> = setmetatable({}, {
        __pairs = function() error("cannot iterate") end,
        __name = "Broken"
    })

    debugPrint({ data = broken })
end

--- Key collision / sparse array ---

do
    -- 1 (number) and "1" (string) give the same key -> one gets a "(type)" suffix
    debugPrint({
        [1] = "number key",
        ["1"] = "string key"
    })

    -- holes in the array -> printed as an object, not an array
    debugPrint({
        [1] = "a",
        [3] = "c"
    })
end

--- sortKeys ---

do
    local unsorted <const> = {
        zebra = 1,
        apple = 2,
        mango = 3,
        banana = 4
    }

    debugPrint(unsorted, { sortKeys = true }) -- apple, banana, mango, zebra
end

--- maxEntries ---

do
    -- array: first 3 items + "<truncated: 7 more>"
    debugPrint({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }, {
        maxEntries = 3
    })

    -- object: first 2 keys (alphabetical) + "<truncated>": 3
    debugPrint({
        a = 1, b = 2, c = 3, d = 4, e = 5
    }, {
        maxEntries = 2
    })
end

--- Raw ---

do
    debugPrint("hello world", { raw = true }) -- no JSON quotes
    debugPrint("hello world")                  -- "hello world" (with quotes)
    debugPrint({ a = 1 }, { raw = true })      -- raw is ignored for non-strings
end

--- debugFormat / silent ---

do
    -- nothing is printed by debugFormat itself
    local str <const> = debugFormat({ name = "Zmain", health = 100 }, { indent = false })
    print("debugFormat returned (" .. #str .. " chars): " .. str)

    -- silent on debugPrint: nothing printed
    debugPrint({ hidden = true }, { silent = true })

    -- the options table passed by the user must not be modified
    local opts <const> = { indent = false }
    debugFormat({ a = 1 }, opts)
    print("opts.silent after debugFormat: " .. tostring(opts.silent)) -- nil
end

--- Long output (chunking) ---

do
    local big <const> = {}
    for i = 1, 150 do
        big["key_" .. i] = "value_" .. i
    end

    -- single huge line (indent = false) -> split in chunks of 1000 chars
    debugPrint(big, { indent = false, sortKeys = true, tag = "Chunked" })

    -- multi-byte UTF-8 characters must not be cut in half
    debugPrint({ text = string.rep("é", 1500) }, { indent = false, tag = "UTF-8" })
end

--- Invalid options ---

do
    debugPrint({ a = 1 }, "not a table") -- "[debugPrint] ... opts must be a table"
end