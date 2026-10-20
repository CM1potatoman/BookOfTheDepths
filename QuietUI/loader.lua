-- CM1 Deepwoken / QuietUI loader
-- Loading and diagnostics only. Does not alter gameplay modules.
local base = "https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/quietui-linoria-stability-20261019/QuietUI/parts/"
local expected = { 1459447, 1210982, 1129481, 554779 }
local expectedTotal = 4354689
local startedAt = os.clock()
local stage = "initializing"

local environment
if type(getgenv) == "function" then
    local ok, value = pcall(getgenv)
    if ok and type(value) == "table" then
        environment = value
    end
end

local function record(nextStage, detail)
    stage = nextStage
    if environment then
        environment.CM1QuietUIStatus = {
            stage = stage,
            detail = detail,
            elapsedSeconds = os.clock() - startedAt,
        }
    end
end

local function report(message)
    local output = "[CM1 QuietUI / " .. stage .. "] " .. tostring(message)
    pcall(warn, output)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "CM1 QuietUI: " .. stage,
            Text = tostring(message):sub(1, 190),
            Duration = 8,
        })
    end)
end

local parts = {}

for index, size in ipairs(expected) do
    record("downloading", "Part " .. index .. " of " .. #expected)
    local url = base .. string.format("CM1_Quiet_%02d.txt", index)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        record("download-error", "Part " .. index)
        report("Could not fetch part " .. index .. ": " .. tostring(response))
        return
    end

    if type(response) ~= "string" then
        record("download-error", "Part " .. index)
        report("Part " .. index .. " was not a string.")
        return
    end

    if #response ~= size then
        record("size-error", "Part " .. index)
        report(string.format("Part %d: expected %d bytes, received %d bytes.",
            index, size, #response))
        return
    end

    parts[index] = response
end

record("assembling", nil)
local source = table.concat(parts)
parts = nil

if #source ~= expectedTotal then
    record("size-error", "Assembled source")
    report(string.format("Expected %d bytes, received %d bytes.", expectedTotal, #source))
    return
end

if type(loadstring) ~= "function" then
    record("compile-error", "loadstring unavailable")
    report("This environment does not provide loadstring.")
    return
end

record("compiling", nil)
local compileOk, compiled, compileError = pcall(loadstring, source)
source = nil

if not compileOk then
    record("compile-error", tostring(compiled))
    report(compiled)
    return
end

if type(compiled) ~= "function" then
    record("compile-error", tostring(compileError))
    report(compileError or "The source did not compile.")
    return
end

record("executing", nil)
local function traceError(err)
    if type(debug) == "table" and type(debug.traceback) == "function" then
        local ok, traceback = pcall(debug.traceback, tostring(err), 2)
        if ok then
            return traceback
        end
    end
    return tostring(err)
end

local executeOk, result = xpcall(compiled, traceError)
compiled = nil

if not executeOk then
    record("runtime-error", tostring(result))
    report(result)
    return
end

record("returned", "Top-level execution returned. Background initialization is not verified.")
return result
