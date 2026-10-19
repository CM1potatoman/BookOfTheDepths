-- Standalone interface-only smoke test.
-- Run only in an authorized Roblox Studio test environment.
-- Does not load BOTD modules or change game behavior.

local upstream = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/1be38aa599bb1f6a7c28f47e6fc13ade52dd0acd/"
local current
local alive = false

local function loadDependency(path)
    local source = game:HttpGet(upstream .. path)
    assert(type(source) == "string" and #source > 0, "Empty dependency: " .. path)
    local factory, err = loadstring(source)
    assert(type(factory) == "function", tostring(err or path .. " did not compile"))
    return factory()
end

local function initialize()
    assert(type(loadstring) == "function", "loadstring unavailable")
    assert(type(game.HttpGet) == "function", "HttpGet unavailable")

    local Library = loadDependency("Library.lua")
    assert(type(Library) == "table" and type(Library.CreateWindow) == "function",
        "Linoria did not return a Library")
    current = Library

    local Window = Library:CreateWindow({
        Title = "CM1 / Linoria UI Test",
        Center = true,
        AutoShow = true,
        Size = UDim2.fromOffset(525, 420),
    })

    local Test = Window:AddTab("Controls")
    local Main = Test:AddLeftGroupbox("UI TEST")
    local Details = Test:AddRightGroupbox("DIAGNOSTICS")
    local status = Details:AddLabel("Linoria initialized")
    local memory = Details:AddLabel("Memory: measuring")

    Main:AddToggle("CM1_SmokeToggle", {
        Text = "Toggle test",
        Default = false,
        Callback = function(value)
            status:SetText("Toggle: " .. tostring(value))
        end,
    })

    Main:AddInput("CM1_SmokeInput", {
        Text = "Input test",
        Default = "ready",
        Callback = function(value)
            status:SetText("Input: " .. tostring(value):sub(1, 30))
        end,
    })

    Main:AddDropdown("CM1_SmokeDropdown", {
        Text = "Dropdown test",
        Values = { "First", "Second", "Third" },
        Default = 1,
        Callback = function(value)
            status:SetText("Dropdown: " .. tostring(value))
        end,
    })

    Main:AddButton("Unload test UI", function()
        Library:Unload()
    end)

    alive = true
    Library:OnUnload(function()
        alive = false
        current = nil
    end)

    task.spawn(function()
        local stats = game:GetService("Stats")
        while alive do
            local ok, total = pcall(stats.GetTotalMemoryUsageMb, stats)
            if not alive then
                break
            end
            if ok and type(total) == "number" then
                pcall(memory.SetText, memory, string.format("Client memory: %.1f MB", total))
            else
                pcall(memory.SetText, memory, "Client memory unavailable")
                break
            end
            task.wait(2)
        end
    end)

    return Library
end

local ok, result = xpcall(initialize, function(err)
    local message = tostring(err)
    if type(debug) == "table" and type(debug.traceback) == "function" then
        local success, traceback = pcall(debug.traceback, message, 2)
        if success then
            return traceback
        end
    end
    return message
end)

if not ok then
    alive = false
    if current then
        pcall(current.Unload, current)
        current = nil
    end
    warn("[CM1 Linoria test] " .. tostring(result))
    error(result, 0)
end

return result
