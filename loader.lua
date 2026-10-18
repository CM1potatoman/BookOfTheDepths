local BASE_URL = "https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/main/"
local EXPECTED_BYTES = 4349988
local PART_COUNT = 14
local PREFIX = "[BOTD/startup] "

local function log(message)
    print(PREFIX .. message)
end

local function traceback(message)
    local output = tostring(message)
    if debug and type(debug.traceback) == "function" then
        output = debug.traceback(output, 2)
    end
    return output
end

log("Loader entered.")

local success, result = xpcall(function()
    local parts = table.create(PART_COUNT)

    for index = 1, PART_COUNT do
        local path = string.format("parts/part_%02d.lua.txt", index)
        local fetched, response = pcall(function()
            return game:HttpGet(BASE_URL .. path)
        end)

        if not fetched or type(response) ~= "string" then
            error("Failed to download " .. path .. ": " .. tostring(response))
        end

        parts[index] = response
        if index == 1 or index == 7 or index == PART_COUNT then
            log(string.format("Download progress: %d/%d parts.", index, PART_COUNT))
        end
    end

    local bundle = table.concat(parts)
    log(string.format("Downloaded %d bytes; expected %d.", #bundle, EXPECTED_BYTES))
    assert(#bundle == EXPECTED_BYTES, "Source size mismatch. One or more parts are incomplete.")

    log("Compiling bundled Luau.")
    local compiled, compileError = loadstring(bundle)
    assert(compiled, "Compilation failed: " .. tostring(compileError))

    log("Compilation succeeded. Entering main initializer.")
    local value = compiled()
    log("Main initializer returned. Menu availability has not been verified.")
    return value
end, traceback)

if not success then
    warn(PREFIX .. "FATAL: " .. tostring(result))
    error(result, 0)
end

task.delay(5, function()
    local luma = shared and shared.Luma
    if not luma then
        warn(PREFIX .. "No initialized Luma instance detected. Check preceding errors.")
    else
        log("Luma instance detected. If the menu is missing, inspect [Luma/diag] warnings above.")
    end
end)

return result
