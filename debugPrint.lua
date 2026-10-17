--- @author    Mathis Hoarau (@Koaio)
--- @version   1.0.0
--- @license   Custom (based on MIT) - see LICENSE file
--- @repo      https://github.com/Koaio/fivem-debugprint

local CFG <const> = {
    availableTypes = {
        ["string"] = true,
        ["number"] = true,
        ["boolean"] = true,
        ["vector2"] = true,
        ["vector3"] = true,
        ["vector4"] = true,
        ["quat"] = true
    },
    maxLineLength = 1000
}

--- @class options
--- @field public indent? boolean
--- @field public maxDepth? number
--- @field public tag? string
--- @field public showMeta? boolean

--- debug - Print any data in a readable format (raises on error, use debugPrint instead)
--- @param data any data to print
--- @param opts? options
local function debug(data, opts)
    assert(json, "json not available")
    assert(opts == nil or type(opts) == "table", "opts must be a table")

    opts = opts or {}
    local indent   = opts.indent ~= false
    local maxDepth = type(opts.maxDepth) == "number" and opts.maxDepth or 32
    local tag      = opts.tag and ("[" .. tostring(opts.tag) .. "] ") or ""
    local showMeta = opts.showMeta == true

    local seen, refId = {}, 0
    local function convert(v, depth)
        local t = type(v)

        if CFG.availableTypes[t] then
            return v
        end

        if t == "userdata" then
            local ok, s = pcall(tostring, v)
            return ok and s or "<userdata>"
        end

        if t ~= "table" then
            return "<" .. t .. ">"
        end

        if seen[v] then
            return "<cycle:" .. seen[v] .. ">"
        end
        if depth >= maxDepth then
            return "<max-depth>"
        end

        local mt = getmetatable(v)
        if type(mt) ~= "table" then
            mt = nil
        end

        if mt and type(mt.__index) == "function" and next(v) == nil then
            return "<proxy:" .. (mt.__name or "table") .. ">"
        end

        refId = refId + 1
        seen[v] = refId

        local out = {}
        local okIter = pcall(function()
            local entries, count, maxKey, isArray = {}, 0, 0, true

            for k, val in pairs(v) do
                count = count + 1
                entries[count] = { k, val }

                if math.type(k) == "integer" and k >= 1 then
                    maxKey = math.max(maxKey, k)
                else
                    isArray = false
                end
            end

            local meta = showMeta and mt and type(mt.__index) == "table" and mt.__index or nil
            isArray = isArray and maxKey == count and not meta

            for i = 1, count do
                local k, val = entries[i][1], entries[i][2]
                out[isArray and k or tostring(k)] = convert(val, depth + 1)
            end

            if meta then
                out["<meta>"] = convert(meta, depth + 1)
            end
        end)

        seen[v] = nil

        if not okIter then
            return "<uniterable:" .. (mt and mt.__name or "table") .. ">"
        end
        return out
    end

    local okConv, safe = pcall(convert, data, 0)
    assert(okConv, string.format("convert error: %s", tostring(safe)))

    local okEnc, encoded = pcall(json.encode, safe, { indent = indent })
    assert(okEnc, string.format("encode error: %s", tostring(encoded)))

    if #encoded > CFG.maxLineLength then
        local lineStart = 1
        for i = 1, #encoded do
            if encoded:byte(i) == 10 then
                print(tag .. encoded:sub(lineStart, i - 1))
                lineStart = i + 1
            elseif i - lineStart + 1 >= CFG.maxLineLength then
                print(tag .. encoded:sub(lineStart, i))
                lineStart = i + 1
            end
        end
        if lineStart <= #encoded then
            print(tag .. encoded:sub(lineStart))
        end
    else
        print(tag .. encoded)
    end
end

--- debugPrint - Print any data in a readable format, never raises
--- @param data any data to print
--- @param opts? options
_G.debugPrint = function(data, opts)
    local ok, err = pcall(debug, data, opts)
    if not ok then
        print("[debugPrint] " .. tostring(err))
    end
end
