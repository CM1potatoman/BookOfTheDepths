local repository = "https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/main/"
local expectedBytes = 4349988
local partCount = 14
local parts = table.create(partCount)

for index = 1, partCount do
    local path = string.format("parts/part_%02d.lua.txt", index)
    local success, response = pcall(function()
        return game:HttpGet(repository .. path)
    end)
    if not success or type(response) ~= "string" then
        error(string.format("Book of the Depths: failed to download %s: %s", path, tostring(response)))
    end
    parts[index] = response
end

local bundle = table.concat(parts)
if #bundle ~= expectedBytes then
    error(string.format("Book of the Depths: incomplete source (%d / %d bytes)", #bundle, expectedBytes))
end

local run, compileError = loadstring(bundle)
if not run then
    error("Book of the Depths: compile failed: " .. tostring(compileError))
end
return run()
