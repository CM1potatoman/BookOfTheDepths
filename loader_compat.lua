-- Book of the Depths | Restricted-capability compatibility test
-- Original BotD is the only executed source. No donor code is imported.
local BASE = "https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/main/"
local PART_COUNT = 14
local EXPECTED_BYTES = 4349988
local function status(message)
    warn("[BOTD/compat] " .. tostring(message))
    if shared then shared.BOTD_Stage = message end
    local parent = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if parent then
        local gui = parent:FindFirstChild("BOTD_Compat_Status")
        if not gui then
            gui = Instance.new("ScreenGui")
            gui.Name = "BOTD_Compat_Status"
            gui.ResetOnSpawn = false
            gui.DisplayOrder = 1500
            local label = Instance.new("TextLabel")
            label.Name = "Status"
            label.Size = UDim2.fromOffset(510, 90)
            label.Position = UDim2.fromOffset(20, 130)
            label.BackgroundColor3 = Color3.fromRGB(19, 23, 32)
            label.TextColor3 = Color3.fromRGB(240, 240, 240)
            label.TextSize = 15
            label.Font = Enum.Font.Code
            label.TextWrapped = true
            label.Parent = gui
            gui.Parent = parent
        end
        local label = gui:FindFirstChild("Status")
        if label then label.Text = "BOOK OF THE DEPTHS | COMPATIBILITY\n" .. tostring(message):sub(1, 250) end
    end
end
if shared then
    shared.BOTD_Status = status
    shared.BOTD_StartupError = nil
    shared.BOTD_LastError = nil
end
local function replaceOnce(s, a, b, module)
    local i = assert(s:find(a, 1, true), "Missing patch marker: " .. module .. "/" .. a:sub(1, 40))
    assert(not s:find(a, i + #a, true), "Ambiguous patch marker: " .. module)
    return s:sub(1, i-1) .. b .. s:sub(i + #a)
end
local PATCHES = {
["__root"]={{"warn(\"[Luma/diag] INIT ERROR: \" .. tostring(error))","shared.BOTD_StartupError = tostring(error)\n\tif type(shared.BOTD_Status) == \"function\" then shared.BOTD_Status(\"INIT ERROR: \" .. tostring(error)) end\n\twarn(\"[Luma/diag] INIT ERROR: \" .. tostring(error))"}},
["Luma"]={{"function Luma.init()","function Luma.init()\n    shared.BOTD_CompatibilityMode = true\n    shared.BOTD_RestrictedHooks = false\n    local function step(name, fn)\n        if type(shared.BOTD_Status) == \"function\" then shared.BOTD_Status(name) end\n        local ok, value = xpcall(fn, function(err)\n            local trace = tostring(err)\n            if debug and type(debug.traceback) == \"function\" then\n                trace = debug.traceback(trace, 2)\n            end\n            return trace\n        end)\n        if not ok then\n            shared.BOTD_LastError = name .. \": \" .. tostring(value)\n            warn(\"[BOTD/compat] \" .. shared.BOTD_LastError)\n        end\n        return ok, value\n    end\n"},{"\t\tHooking.earlyInit()","        shared.BOTD_RestrictedHooks = false\n        warn(\"[BOTD/compat] Restricted early hooks disabled. Protected game operations are not attempted.\")"},{"\t\tHooking.init()","        warn(\"[BOTD/compat] Restricted main hooking disabled. Dependent features may not function.\")"},{"\tCoreGuiManager.set()","\tstep(\"GUI parent\", function() CoreGuiManager.set() end)"},{"\tPersistentData.init()","\tstep(\"Persistent data\", function() PersistentData.init() end)"},{"\tQueuedBlocking.init()","\tstep(\"Queued blocking\", function() QueuedBlocking.init() end)"},{"\tSaveManager.init()","\tstep(\"Timing save manager\", function() SaveManager.init() end)"},{"\tModuleManager.refresh()","\tstep(\"Timing registry\", function() ModuleManager.refresh() end)"},{"\tControlModule.init()","\tstep(\"Controls\", function() ControlModule.init() end)"},{"\tFeatures.init()","\tstep(\"Feature modules\", function() Features.init() end)"},{"\tMenu.init()","    local menuOK, menuError = step(\"Linoria menu\", function() Menu.init() end)\n    if not menuOK then\n        warn(\"[BOTD/compat] Main interface could not open: \" .. tostring(menuError))\n    end"},{"if PersistentData.get(\"efdata\") then","if not shared.BOTD_CompatibilityMode and PersistentData.get(\"efdata\") then"},{"if PersistentData.get(\"l2data\") then","if not shared.BOTD_CompatibilityMode and PersistentData.get(\"l2data\") then"},{"if PersistentData.get(\"abdata\") then","if not shared.BOTD_CompatibilityMode and PersistentData.get(\"abdata\") then"},{"if PersistentData.get(\"to1data\") then","if not shared.BOTD_CompatibilityMode and PersistentData.get(\"to1data\") then"},{"if PersistentData.get(\"voidata\") then","if not shared.BOTD_CompatibilityMode and PersistentData.get(\"voidata\") then"},{"if PersistentData.get(\"afdata\") then","if not shared.BOTD_CompatibilityMode and PersistentData.get(\"afdata\") then"},{"if PersistentData.get(\"titusdata\") then","if not shared.BOTD_CompatibilityMode and PersistentData.get(\"titusdata\") then"},{"if PersistentData.get(\"authoritydata\") then","if not shared.BOTD_CompatibilityMode and PersistentData.get(\"authoritydata\") then"},{"if PersistentData.get(\"dukedata\") then","if not shared.BOTD_CompatibilityMode and PersistentData.get(\"dukedata\") then"},{"if PersistentData.get(\"mooneyriedata\") then","if not shared.BOTD_CompatibilityMode and PersistentData.get(\"mooneyriedata\") then"},{"if PersistentData.get(\"notesdata\") then","if not shared.BOTD_CompatibilityMode and PersistentData.get(\"notesdata\") then"},{"if PersistentData.get(\"sarameddata\") then","if not shared.BOTD_CompatibilityMode and PersistentData.get(\"sarameddata\") then"}},
["Menu"]={{"AutoShow = not shared.Luma.silent,","AutoShow = true,"},{"\tCombatTab.init(window)","    local combatOK, combatError = pcall(CombatTab.init, window)\n    if not combatOK then warn(\"[BOTD/compat] Combat tab failed: \" .. tostring(combatError)) end"},{"\tCombatTab.initAntiExploit(window)","    local antiOK, antiError = pcall(CombatTab.initAntiExploit, window)\n    if not antiOK then warn(\"[BOTD/compat] Secondary combat tab failed: \" .. tostring(antiError)) end"},{"\t\tSaveManager:LoadAutoloadConfig()","        local loaded, loadErr = pcall(function() SaveManager:LoadAutoloadConfig() end)\n        if not loaded then warn(\"[BOTD/compat] Config autoload failed: \" .. tostring(loadErr)) end"}},
["Features"]={{"\tpcall(fn)","    local ok, err = pcall(fn)\n    if not ok then warn(\"[BOTD/feature] \" .. method .. \" failed: \" .. tostring(err)) end"}},
["Menu/HomeTab"]={{"intro:AddLabel(\"CM1 Edition | Linoria interface\")","intro:AddLabel(\"CM1 Edition | Linoria interface\")\n    intro:AddLabel(\"Compatibility: privileged hooks OFF\")\n    intro:AddLabel(\"Some dependent functions will remain unavailable.\")"},{"session:AddButton(\"Unload\", function()","session:AddButton(\"Copy startup status\", function()\n        if type(setclipboard) == \"function\" and shared then\n            setclipboard(tostring(shared.BOTD_LastError or shared.BOTD_StartupError or \"No reported errors\"))\n        end\n    end)\n    session:AddButton(\"Unload\", function()"}}
}
local function patchModule(s, name, patches)
    local marker = '__bundle_register("' .. name .. '",'
    local start = assert(s:find(marker, 1, true), "Missing module: " .. name)
    local stop = s:find('\n__bundle_register("', start + #marker, true)
    if not stop then
        stop = assert(s:find('\nreturn __bundle_require("__root")', start + #marker, true), "No module terminator: " .. name)
    end
    local body = s:sub(start, stop - 1)
    for _, change in ipairs(patches) do
        body = replaceOnce(body, change[1], change[2], name)
    end
    return s:sub(1, start-1) .. body .. s:sub(stop)
end
local success, result = xpcall(function()
    status("Downloading 14 original BotD source parts")
    local parts = table.create(PART_COUNT)
    for i = 1, PART_COUNT do
        local path = string.format("parts/part_%02d.lua.txt", i)
        local ok, value = pcall(function() return game:HttpGet(BASE .. path) end)
        assert(ok and type(value)=="string", "Download failed: " .. path .. ": " .. tostring(value))
        parts[i] = value
        if i % 4 == 0 or i == PART_COUNT then status("Downloaded "..i.."/"..PART_COUNT) end
    end
    local bundle = table.concat(parts)
    assert(#bundle == EXPECTED_BYTES, "Source mismatch: " .. #bundle .. "/" .. EXPECTED_BYTES)
    for _, name in ipairs({"__root", "Luma", "Menu", "Features", "Menu/HomeTab"}) do
        status("Validating " .. name)
        bundle = patchModule(bundle, name, PATCHES[name])
    end
    status("Compiling guarded BotD module bundle")
    local run, compileError = loadstring(bundle)
    assert(run, "Compilation failed: " .. tostring(compileError))
    status("Initializing modules, restricted hooks disabled")
    local value = run()
    if shared and shared.BOTD_StartupError then
        status("INIT ERROR: " .. tostring(shared.BOTD_StartupError))
    elseif shared and shared.BOTD_LastError then
        status("Some modules unavailable: " .. tostring(shared.BOTD_LastError))
    else
        status("Initializer returned; live feature validation pending")
    end
    return value
end, function(err)
    local out = tostring(err)
    if debug and type(debug.traceback)=="function" then out = debug.traceback(out, 2) end
    return out
end)
if not success then
    status("FAILED: " .. tostring(result))
    error(result, 0)
end
return result
