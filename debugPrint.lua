--- @author    Mathis Hoarau (@Koaio)
--- @version   1.1.0
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
        ["quat"] = true,
    },
    maxLineLength = 1000
}

local CONTEXT <const> = (IsDuplicityVersion and IsDuplicityVersion()) and "SERVER" or "CLIENT"

--- @class DebugPrintOptions
--- @field public indent? boolean Indented JSON (default true)
--- @field public maxDepth? number Max table depth (default 32)
--- @field public tag? string Custom tag shown after [SERVER]/[CLIENT]
--- @field public showMeta? boolean Show metatable __index table
--- @field public sortKeys? boolean Deterministic key order
--- @field public maxEntries? number Max entries shown per table
--- @field public raw? boolean Print strings as-is (no JSON quotes)
--- @field public silent? boolean Don't print, only return the string

--- Print text line by line, splitting lines longer than maxLineLength
--- without cutting UTF-8 characters in half.
--- @param tag string
--- @param text string
local function printChunked(tag, text)
    local max = CFG.maxLineLength
    for line in (text .. "\n"):gmatch("(.-)\n") do
        while #line > max do
            local cut = max
            while cut > 1 do
                local b = line:byte(cut + 1)
                if not b or b < 0x80 or b >= 0xC0 then break end
                cut = cut - 1
            end
            print(tag .. line:sub(1, cut))
            line = line:sub(cut + 1)
        end
        print(tag .. line)
    end
end

--- debug - Print any data in a readable format (raises on error, use debugPrint instead)
--- @param data any data to print
--- @param opts? DebugPrintOptions
local function _debug(data, opts)
    assert(json, "json not available")
    assert(opts == nil or type(opts) == "table", "opts must be a table")

    opts = opts or {}
    local indent   = opts.indent ~= false
    local maxDepth = type(opts.maxDepth) == "number" and opts.maxDepth or 32
    local showMeta = opts.showMeta == true
    local sortKeys = opts.sortKeys == true
    local raw = opts.raw == true
    local silent = opts.silent == true
    local maxEntries = type(opts.maxEntries) == "number" and opts.maxEntries or math.huge
    local tag = "[" .. CONTEXT .. "] " .. (opts.tag and ("[" .. tostring(opts.tag) .. "] ") or "")

    if raw and type(data) == "string" then
        if not silent then printChunked(tag, data) end
        return data
    end

    local seen, refId = {}, 0
    local function convert(v, depth)
        local t = type(v)

        if t == "number" and (v ~= v or v == math.huge or v == -math.huge) then
            return v ~= v and "<nan>" or (v > 0 and "<inf>" or "<-inf>")
        end

        if t == "function" then
            local ok, info = pcall(debug.getinfo, v, "S")

            if ok and info then
                return "<function: " .. info.short_src .. ":" .. info.linedefined .. ">"
            end
            return "<function>"
        end

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

            local truncated = count > maxEntries

            if isArray then
                if truncated then
                    table.sort(entries, function(a, b) return a[1] < b[1] end)
                end
            elseif sortKeys or truncated then
                table.sort(entries, function(a, b) return tostring(a[1]) < tostring(b[1]) end)
            end

            local limit = truncated and maxEntries or count

            for i = 1, limit do
                local k, val = entries[i][1], entries[i][2]
                local key = k
                if not isArray then
                    key = tostring(k)
                    if out[key] ~= nil then
                        key = key .. " (" .. type(k) .. ")"
                    end
                end
                out[key] = convert(val, depth + 1)
            end

            if truncated then
                local rest = count - limit
                if isArray then
                    out[limit + 1] = "<truncated: " .. rest .. " more>"
                else
                    out["<truncated>"] = rest
                end
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

    local okEnc, encoded = pcall(json.encode, safe, { indent = indent, sort_keys = sortKeys })
    assert(okEnc, string.format("encode error: %s", tostring(encoded)))

    if not silent then
        if #encoded > CFG.maxLineLength then
            printChunked(tag, encoded)
        else
            print(tag .. encoded)
        end
    end

    return encoded
end

--- debugPrint - Print any data in a readable format, never raises
--- @param data any data to print
--- @param opts? DebugPrintOptions
_G.debugPrint = function(data, opts)
    local ok, err = pcall(_debug, data, opts)
    if not ok then
        print("[debugPrint] " .. tostring(err))
    end
end

--- debugFormat - Same formatting as debugPrint but returns the string instead of printing it
--- (useful for Discord logs, files, databases...). Never raises.
--- @param data any data to format
--- @param opts? DebugPrintOptions
--- @return string
_G.debugFormat = function(data, opts)
    local o = {}
    if type(opts) == "table" then
        for k, v in pairs(opts) do o[k] = v end
    end
    o.silent = true

    local ok, res = pcall(_debug, data, o)
    return ok and res or ("[debugFormat] " .. tostring(res))
end