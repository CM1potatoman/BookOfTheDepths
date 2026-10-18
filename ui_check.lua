local PREFIX = "[BOTD/UI-Check] "
local url = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"

local function report(message)
    warn(PREFIX .. tostring(message))
end

report("Starting UI-only test. No game hooks will be loaded.")

local success, err = xpcall(function()
    report("Fetching Linoria.")
    local source = game:HttpGet(url)
    assert(type(source) == "string" and #source > 1000, "Linoria download failed or was empty")

    report("Compiling Linoria.")
    local chunk, compilationError = loadstring(source)
    assert(chunk, "Linoria compilation failed: " .. tostring(compilationError))

    local Library = chunk()
    assert(type(Library) == "table", "Linoria did not return a library")

    report("Opening independent window.")
    local Window = Library:CreateWindow({
        Title = "Book of the Depths | UI Check",
        Center = true,
        AutoShow = true,
        TabPadding = 8,
        MenuFadeTime = 0.2
    })
    local Tab = Window:AddTab("Diagnostics")
    local Info = Tab:AddLeftGroupbox("Interface Status")
    Info:AddLabel("Linoria loaded successfully.")
    Info:AddLabel("Game hooking was not initialized.")
    Info:AddLabel("This is only an interface test.")
    Info:AddButton("Close UI", function()
        Library:Unload()
    end)
    report("SUCCESS: Standalone Linoria window opened.")
end, function(e)
    local trace = tostring(e)
    if debug and type(debug.traceback) == "function" then
        trace = debug.traceback(trace, 2)
    end
    return trace
end)

if not success then
    report("FAILED: " .. tostring(err))
    local player = game:GetService("Players").LocalPlayer
    pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "BOTD_UI_Check_Error"
        gui.ResetOnSpawn = false
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromOffset(480, 100)
        label.Position = UDim2.fromOffset(20, 135)
        label.TextWrapped = true
        label.TextSize = 14
        label.Text = "BOTD UI CHECK FAILED:\n" .. tostring(err):sub(1, 230)
        label.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
        label.TextColor3 = Color3.fromRGB(245, 245, 245)
        label.Parent = gui
        gui.Parent = player:WaitForChild("PlayerGui")
    end)
end
