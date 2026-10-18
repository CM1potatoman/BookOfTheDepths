local BASE_URL = "https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/main/"
local EXPECTED_BYTES = 4349988
local PART_COUNT = 14
local PREFIX = "[BOTD/startup] "

local player = game:GetService("Players").LocalPlayer
local gui
local label

pcall(function()
    local parent = player:WaitForChild("PlayerGui", 15)
    assert(parent, "PlayerGui unavailable")

    local previous = parent:FindFirstChild("BOTD_StartupStatus")
    if previous then
        previous:Destroy()
    end

    gui = Instance.new("ScreenGui")
    gui.Name = "BOTD_StartupStatus"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 2000

    label = Instance.new("TextLabel")
    label.Size = UDim2.fromOffset(550, 126)
    label.Position = UDim2.fromOffset(20, 132)
    label.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
    label.TextColor3 = Color3.fromRGB(226, 233, 245)
    label.BorderSizePixel = 0
    label.TextSize = 15
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.Text = "BOOK OF THE DEPTHS | STARTING"
    label.Parent = gui

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = label

    gui.Parent = parent
end)

local function status(message)
    warn(PREFIX .. message)
    if label and label.Parent then
        label.Text = "BOOK OF THE DEPTHS | STARTUP\n" .. message
    end
    task.wait()
end

local function traceback(message)
    local detail = tostring(message)
    if debug and type(debug.traceback) == "function" then
        detail = debug.traceback(detail, 2)
    end
    return detail
end

shared.BOTD_ReportStage = status
shared.BOTD_InitError = nil
shared.BOTD_MenuError = nil

status("Loader entered. Preparing downloads.")

local success, result = xpcall(function()
    local parts = table.create(PART_COUNT)

    for index = 1, PART_COUNT do
        local path = string.format("parts/part_%02d.lua.txt", index)
        status(string.format("Downloading source part %d/%d", index, PART_COUNT))

        local fetched, response = pcall(function()
            return game:HttpGet(BASE_URL .. path)
        end)
        if not fetched or type(response) ~= "string" then
            error("Failed to download " .. path .. ": " .. tostring(response))
        end
        parts[index] = response
    end

    status("Joining source parts.")
    local bundle = table.concat(parts)
    assert(#bundle == EXPECTED_BYTES, string.format(
        "Source size mismatch: %d bytes received, expected %d",
        #bundle, EXPECTED_BYTES
    ))


    local function replaceOnce(text, old, new, label)
        local first = text:find(old, 1, true)
        assert(first, "Patch marker missing: " .. label)
        assert(not text:find(old, first + #old, true), "Patch marker duplicated: " .. label)
        return text:sub(1, first - 1) .. new .. text:sub(first + #old)
    end

    local function patchModule(text, name, nextName, replacements)
        local marker = '__bundle_register("' .. name .. '",'
        local nextMarker = '__bundle_register("' .. nextName .. '",'
        local first = assert(text:find(marker, 1, true), "Missing module " .. name)
        local following = assert(text:find(nextMarker, first + #marker, true), "Missing module " .. nextName)
        local section = text:sub(first, following - 1)
        for _, pair in ipairs(replacements) do
            section = replaceOnce(section, pair[1], pair[2], name .. ": " .. pair[1]:sub(1, 40))
        end
        return text:sub(1, first - 1) .. section .. text:sub(following)
    end

    local function checkpoint(name)
        return 'shared.BOTD_LastCoreStage = ' .. string.format("%q", name) .. '\n\tif shared.BOTD_ReportStage then shared.BOTD_ReportStage(' .. string.format("%q", name) .. ') end\n\t'
    end

    bundle = patchModule(bundle, "__root", "Luma", {
        {
            'warn("[Luma/diag] INIT ERROR: " .. tostring(error))',
            'shared.BOTD_InitError = tostring(error)\n\tshared.BOTD_InitErrorStage = tostring(shared.BOTD_LastCoreStage or "before first checkpoint")\n\tshared.BOTD_InitTrace = (debug and debug.traceback and debug.traceback()) or "Trace unavailable"\n\tif shared.BOTD_ReportStage then shared.BOTD_ReportStage("ERROR AT " .. shared.BOTD_InitErrorStage .. "\\n" .. tostring(error)) end\n\twarn("[Luma/diag] INIT ERROR AT " .. shared.BOTD_InitErrorStage .. ": " .. tostring(error) .. "\\n" .. shared.BOTD_InitTrace)'
        },
    })

    bundle = patchModule(bundle, "Luma", "Features/Automation/AutoSaramed", {
        { 'function Luma.init()', 'function Luma.init()\n\t' .. checkpoint("CORE: entered Luma.init") },
        { '\t\tHooking.earlyInit()', '\t\t' .. checkpoint("CORE: early hooking") .. 'Hooking.earlyInit()' },
        { '\t\tKeyHandling.init()', '\t\t' .. checkpoint("CORE: key handling") .. 'KeyHandling.init()' },
        { '\t\tHooking.init()', '\t\t' .. checkpoint("CORE: main hooking") .. 'Hooking.init()' },
        { '\tCoreGuiManager.set()', '\t' .. checkpoint("CORE: GUI parent setup") .. 'CoreGuiManager.set()' },
        { '\tPersistentData.init()', '\t' .. checkpoint("CORE: persistent data") .. 'PersistentData.init()' },
        { '\tQueuedBlocking.init()', '\t' .. checkpoint("CORE: queued blocking") .. 'QueuedBlocking.init()' },
        { '\tSaveManager.init()', '\t' .. checkpoint("CORE: timing manager") .. 'SaveManager.init()' },
        { '\tModuleManager.refresh()', '\t' .. checkpoint("CORE: module refresh") .. 'ModuleManager.refresh()' },
        { '\tControlModule.init()', '\t' .. checkpoint("CORE: control module") .. 'ControlModule.init()' },
        { '\tFeatures.init()', '\t' .. checkpoint("CORE: feature initialization") .. 'Features.init()' },
        { '\tMenu.init()', '\t' .. checkpoint("CORE: opening Linoria menu") .. 'Menu.init()\n\t' .. checkpoint("CORE: menu initialized") },
    })

    bundle = patchModule(bundle, "Menu", "Features/Custom/Custom", {
        { 'function Menu.init()', 'function Menu.init()\n\t' .. checkpoint("MENU: creating window") },
        { 'AutoShow = not shared.Luma.silent', 'AutoShow = true' },
        { '\tHomeTab.init(window)', '\t' .. checkpoint("MENU: creating Home tab") .. 'HomeTab.init(window)' },
        {
            '\tCombatTab.init(window)',
            '\tlocal combatOK, combatError = pcall(CombatTab.init, window)\n\tif not combatOK then\n\t\tshared.BOTD_MenuError = "Combat tab: " .. tostring(combatError)\n\t\tif shared.BOTD_ReportStage then shared.BOTD_ReportStage("MENU ERROR: " .. shared.BOTD_MenuError) end\n\t\twarn("[BOTD/menu] " .. shared.BOTD_MenuError)\n\tend'
        },
        {
            '\tCombatTab.initAntiExploit(window)',
            '\tlocal antiOK, antiError = pcall(CombatTab.initAntiExploit, window)\n\tif not antiOK then\n\t\tshared.BOTD_MenuError = "Anti-Exploit tab: " .. tostring(antiError)\n\t\tif shared.BOTD_ReportStage then shared.BOTD_ReportStage("MENU ERROR: " .. shared.BOTD_MenuError) end\n\t\twarn("[BOTD/menu] " .. shared.BOTD_MenuError)\n\tend'
        },
    })


    status("Downloaded 4,349,988 bytes. Compiling Luau.")
    local run, compileError = loadstring(bundle)
    assert(run, "Compilation failed: " .. tostring(compileError))

    status("Compilation passed. Entering main initializer.")
    local value = run()
    if shared.BOTD_InitError then
        status("INIT ERROR AT " .. tostring(shared.BOTD_InitErrorStage or shared.BOTD_LastCoreStage or "unknown") .. "\n" .. tostring(shared.BOTD_InitError))
    elseif shared.BOTD_MenuError then
        status("MENU ERROR: " .. tostring(shared.BOTD_MenuError))
    else
        status("Initializer returned. Inspect UI; no error captured.")
    end
    return value
end, traceback)

if not success then
    status("FAILED: " .. tostring(result):sub(1, 350))
    error(result, 0)
end

task.delay(4, function()
    if shared.BOTD_InitError then
        status("INIT ERROR AT " .. tostring(shared.BOTD_InitErrorStage or shared.BOTD_LastCoreStage or "unknown") .. "\n" .. tostring(shared.BOTD_InitError))
    elseif shared.BOTD_MenuError then
        status("MENU ERROR: " .. tostring(shared.BOTD_MenuError))
    elseif not shared.Luma then
        status("WARNING: No Luma instance created. Check [Luma/diag] warnings.")
    else
        status("Last stage: " .. tostring(shared.BOTD_LastCoreStage or "unknown") .. ". If menu is missing, inspect F9.")
    end
end)

return result
