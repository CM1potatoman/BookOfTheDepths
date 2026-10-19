-- CM1 Deepwoken // Linoria Quiet UI loader
local base = "https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/main/QuietUI/parts/"
local expected = { 1459151, 1210621, 1129481, 554707 }
local parts = {}

local function notify(message)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "CM1 Deepwoken",
            Text = message,
            Duration = 6,
        })
    end)
end

for index, size in ipairs(expected) do
    local url = base .. string.format("CM1_Quiet_%02d.txt", index)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or type(response) ~= "string" or #response ~= size then
        notify("Unable to load source part " .. index .. ".")
        return
    end

    parts[index] = response
end

local source = table.concat(parts)
table.clear(parts)

if #source ~= 4353960 then
    notify("Source validation failed.")
    return
end

local compiled = loadstring(source)
source = nil

if not compiled then
    notify("Script compilation failed.")
    return
end

return compiled()
