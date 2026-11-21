-- CM1 Book of the Depths / QuietUI
-- Verbose loader diagnostics. No global print/warn overrides.
local BASE = "https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/main/QuietUI/parts/"
local EXPECTED = { 1459151, 1210621, 1129481, 554707 }
local EXPECTED_TOTAL = 4353960
local LOG_PREFIX = "[CM1][BookOfTheDepths][QuietUI]"
local LOG_PATH = "CM1_BookOfTheDepths_QuietUI.log"
local BUFFER_KEY = "__CM1_BOTD_QUIETUI_LOGS"
local BUFFER_LIMIT = 300

local function globalFunction(name)
    local envs = { _G }
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            table.insert(envs, 1, env)
        end
    end
    if type(getfenv) == "function" then
        local ok, env = pcall(getfenv, 0)
        if ok and type(env) == "table" then
            envs[#envs + 1] = env
        end
    end
    for _, env in ipairs(envs) do
        local value = rawget(env, name)
        if type(value) == "function" then
            return value
        end
    end
    return nil
end

local console = globalFunction("rconsoleprint") or globalFunction("consoleprint")
local append = globalFunction("appendfile")
local write = globalFunction("writefile")
local isfile = globalFunction("isfile")
local hostEnv = nil
if type(getgenv) == "function" then
    local ok, env = pcall(getgenv)
    if ok and type(env) == "table" then
        hostEnv = env
    end
end

local logs = {}
local status = {
    phase = "starting",
    parts_loaded = 0,
    errors = {},
    started_at = (type(os) == "table" and type(os.clock) == "function") and os.clock() or nil,
}
if hostEnv then
    hostEnv[BUFFER_KEY] = logs
    hostEnv.__CM1_BOTD_LOADER_STATUS = status
end

local function mark(phase)
    status.phase = phase
end

local function log(level, ...)
    local fields = {}
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        local ok, str = pcall(tostring, value)
        fields[i] = ok and str or "<tostring failed>"
    end
    local line = LOG_PREFIX .. "[" .. level .. "] " .. table.concat(fields, " ")
    logs[#logs + 1] = line
    if level == "ERROR" then
        status.errors[#status.errors + 1] = line
    end
    if #logs > BUFFER_LIMIT then
        table.remove(logs, 1)
    end

    if console then
        local ok = pcall(console, line .. "\n")
        if ok then
            return
        end
        console = nil
    end

    if append then
        local ok = pcall(append, LOG_PATH, line .. "\n")
        if ok then
            return
        end
    end
    -- Intentionally no print/warn/SetCore fallback: never send loader logs to F9.
end

if not console and append and write and isfile then
    local ok, exists = pcall(isfile, LOG_PATH)
    if ok and not exists then
        pcall(write, LOG_PATH, "")
    end
end

log("INFO", "Starting verbose loader; console:", console and "available" or "unavailable")
if not console then
    log("WARN", "No executor console function detected; using file/buffer fallback")
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

local parts = {}
for index, size in ipairs(EXPECTED) do
    mark("downloading_part_" .. index)
    local name = string.format("CM1_Quiet_%02d.txt", index)
    log("INFO", "Fetching", name, "expected bytes:", size)
    local ok, body = pcall(function()
        return game:HttpGet(BASE .. name)
    end)
    if not ok then
        log("ERROR", "Download failed:", name, body)
        return
    end
    if type(body) ~= "string" then
        log("ERROR", "Invalid response type:", name, type(body))
        return
    end
    if #body ~= size then
        log("ERROR", "Size mismatch:", name, "expected", size, "received", #body)
        return
    end
    parts[index] = body
    status.parts_loaded = index
    log("INFO", "Validated part:", name)
end

local source = table.concat(parts)
parts = nil
if #source ~= EXPECTED_TOTAL then
    log("ERROR", "Combined source size mismatch:", #source, "expected", EXPECTED_TOTAL)
    return
end

mark("compiling")
log("INFO", "Compiling source:", #source, "bytes")
local compiled, compileError = loadstring(source, "@CM1/BookOfTheDepths/QuietUI")
source = nil
if not compiled then
    log("ERROR", "Compilation failed:", compileError)
    return
end
log("INFO", "Compilation succeeded")

-- Redirect only this compiled chunk's print/warn, not global Roblox output.
if type(getfenv) == "function" and type(setfenv) == "function" then
    local envOk, parent = pcall(getfenv, compiled)
    if envOk and type(parent) == "table" then
        local scoped = setmetatable({
            print = function(...) log("INFO", ...) end,
            warn = function(...) log("WARN", ...) end,
        }, {
            __index = parent,
            __newindex = parent,
        })
        local ok, err = pcall(setfenv, compiled, scoped)
        if ok then
            log("INFO", "Scoped print/warn output redirection enabled")
        else
            log("WARN", "Scoped output redirection unavailable:", err)
        end
    else
        log("WARN", "Unable to read compiled chunk environment")
    end
else
    log("WARN", "Scoped output redirection unsupported in this runtime")
end

-- Install optional event/support services independently of the opaque source bundle.
-- On merged builds, main is preferred; branch fallback enables pre-merge testing.
local SUPPORT_URLS = {
    "https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/main/QuietUI/support.lua",
    "https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/feature/botd-integrated-event-support-20261121/QuietUI/support.lua",
}
local function startSupport()
    for _, url in ipairs(SUPPORT_URLS) do
        local fetched, body = pcall(function() return game:HttpGet(url) end)
        if fetched and type(body) == "string" and #body >= 2000 then
            local chunk, compileErr = loadstring(body, "@CM1/BookOfTheDepths/QuietUI/support")
            body = nil
            if chunk then
                local worked, supportOrError = xpcall(chunk, traceback)
                if worked then
                    log("INFO", "Event/support module initialized")
                    return supportOrError
                end
                log("ERROR", "Event/support initialization failed:", supportOrError)
            else
                log("ERROR", "Event/support compilation failed:", compileErr)
            end
            return
        end
    end
    log("WARN", "Event/support module unavailable; primary bundle remains unaffected")
end

startSupport()

mark("executing")
log("INFO", "Executing compiled chunk")
local ok, result = xpcall(compiled, traceback)
if not ok then
    mark("runtime_error")
    log("ERROR", "Runtime failure:", result)
    return
end
mark("complete")
log("INFO", "Compiled chunk returned successfully")
return result
