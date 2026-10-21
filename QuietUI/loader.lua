-- CM1 Deepwoken // Linoria Quiet UI loader
-- Loader diagnostics and error handling. Gameplay source is unchanged.
local base = "https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/main/QuietUI/parts/"
local expected = { 1459151, 1210621, 1129481, 554707 }
local expectedTotal = 4353960
local parts = {}

local function report(stage, detail)
    local message = "[CM1 QuietUI][" .. tostring(stage) .. "] " .. tostring(detail)
    warn(message)
end

local function traceback(err)
    local message = tostring(err)
    if type(debug) == "table" and type(debug.traceback) == "function" then
        local ok, trace = pcall(debug.traceback, message, 2)
        if ok and type(trace) == "string" then
            return trace
        end
    end
    return message
end

for index, size in ipairs(expected) do
    local url = base .. string.format("CM1_Quiet_%02d.txt", index)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        report("download", "Part " .. index .. " request failed: " .. tostring(response))
        return
    end

    if type(response) ~= "string" then
        report("download", "Part " .. index .. " returned " .. type(response))
        return
    end

    if #response ~= size then
        report("integrity", string.format("Part %d: expected %d bytes, received %d", index, size, #response))
        return
    end

    parts[index] = response
end

local source = table.concat(parts)
table.clear(parts)

if #source ~= expectedTotal then
    report("integrity", string.format("Combined source: expected %d bytes, received %d", expectedTotal, #source))
    return
end

local okCompile, compiled, compileError = pcall(loadstring, source)
source = nil

if not okCompile then
    report("compile", compiled)
    return
end

if type(compiled) ~= "function" then
    report("compile", compileError or "Compiler returned no function")
    return
end

local okRun, result = xpcall(compiled, traceback)
if not okRun then
    report("runtime", result)
    return
end

return result
