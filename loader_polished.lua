-- Book of the Depths | Performance Polish v1 (experimental)
-- Original BotD is the only executed game source. No Project Rain runtime.
local BASE = "https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/main/"
local PARTS = 14
local EXPECTED_BYTES = 4349988
local function status(text)
    warn("[BOTD/polished] " .. tostring(text))
    if shared then shared.BOTD_Stage = tostring(text) end
    local lp = game:GetService("Players").LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    if not pg then return end
    local gui = pg:FindFirstChild("BOTD_Polish_Status")
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "BOTD_Polish_Status"
        gui.DisplayOrder = 1500
        gui.ResetOnSpawn = false
        local label = Instance.new("TextLabel")
        label.Name = "Status"
        label.Size = UDim2.fromOffset(525, 90)
        label.Position = UDim2.fromOffset(20, 135)
        label.BackgroundColor3 = Color3.fromRGB(18, 23, 33)
        label.TextColor3 = Color3.fromRGB(240, 240, 245)
        label.TextSize = 15
        label.Font = Enum.Font.Code
        label.TextWrapped = true
        label.Parent = gui
        gui.Parent = pg
    end
    gui.Status.Text = "BOOK OF THE DEPTHS | POLISH\n" .. tostring(text):sub(1, 250)
end
local function replaceOnce(s, a, b, module)
    local at = assert(s:find(a, 1, true), "Missing " .. module .. ": " .. a:sub(1, 60))
    assert(not s:find(a, at + #a, true), "Ambiguous patch: " .. module)
    return s:sub(1, at - 1) .. b .. s:sub(at + #a)
end
local function patchModule(s, name, changes)
    local marker = '__bundle_register("' .. name .. '",'
    local first = assert(s:find(marker, 1, true), "Missing module " .. name)
    local last = s:find('\n__bundle_register("', first + #marker, true)
    if not last then
        last = assert(s:find('\nreturn __bundle_require("__root")', first + #marker, true), "Missing module end: " .. name)
    end
    local body = s:sub(first, last - 1)
    for _, change in ipairs(changes) do
        body = replaceOnce(body, change[1], change[2], name)
    end
    return s:sub(1, first - 1) .. body .. s:sub(last)
end

local COMPAT = {
["__root"] = {
{"warn(\"[Luma/diag] INIT ERROR: \" .. tostring(error))", "shared.BOTD_StartupError = tostring(error)\n\tif type(shared.BOTD_Status) == \"function\" then shared.BOTD_Status(\"INIT ERROR: \" .. tostring(error)) end\n\twarn(\"[Luma/diag] INIT ERROR: \" .. tostring(error))"}
},
["Luma"] = {
{"function Luma.init()", "function Luma.init()\n    shared.BOTD_CompatibilityMode = true\n    shared.BOTD_RestrictedHooks = false\n    local function step(name, fn)\n        if type(shared.BOTD_Status) == \"function\" then shared.BOTD_Status(name) end\n        local ok, value = xpcall(fn, function(err)\n            local trace = tostring(err)\n            if debug and type(debug.traceback) == \"function\" then\n                trace = debug.traceback(trace, 2)\n            end\n            return trace\n        end)\n        if not ok then\n            shared.BOTD_LastError = name .. \": \" .. tostring(value)\n            warn(\"[BOTD/compat] \" .. shared.BOTD_LastError)\n        end\n        return ok, value\n    end\n"},
{"\t\tHooking.earlyInit()", "        shared.BOTD_RestrictedHooks = false\n        warn(\"[BOTD/compat] Restricted early hooks disabled. Protected game operations are not attempted.\")"},
{"\t\tHooking.init()", "        warn(\"[BOTD/compat] Restricted main hooking disabled. Dependent features may not function.\")"},
{"\tCoreGuiManager.set()", "\tstep(\"GUI parent\", function() CoreGuiManager.set() end)"},
{"\tPersistentData.init()", "\tstep(\"Persistent data\", function() PersistentData.init() end)"},
{"\tQueuedBlocking.init()", "\tstep(\"Queued blocking\", function() QueuedBlocking.init() end)"},
{"\tSaveManager.init()", "\tstep(\"Timing save manager\", function() SaveManager.init() end)"},
{"\tModuleManager.refresh()", "\tstep(\"Timing registry\", function() ModuleManager.refresh() end)"},
{"\tControlModule.init()", "\tstep(\"Controls\", function() ControlModule.init() end)"},
{"\tFeatures.init()", "\tstep(\"Feature modules\", function() Features.init() end)"},
{"\tMenu.init()", "    local menuOK, menuError = step(\"Linoria menu\", function() Menu.init() end)\n    if not menuOK then\n        warn(\"[BOTD/compat] Main interface could not open: \" .. tostring(menuError))\n    end"},
{"if PersistentData.get(\"efdata\") then", "if not shared.BOTD_CompatibilityMode and PersistentData.get(\"efdata\") then"},
{"if PersistentData.get(\"l2data\") then", "if not shared.BOTD_CompatibilityMode and PersistentData.get(\"l2data\") then"},
{"if PersistentData.get(\"abdata\") then", "if not shared.BOTD_CompatibilityMode and PersistentData.get(\"abdata\") then"},
{"if PersistentData.get(\"to1data\") then", "if not shared.BOTD_CompatibilityMode and PersistentData.get(\"to1data\") then"},
{"if PersistentData.get(\"voidata\") then", "if not shared.BOTD_CompatibilityMode and PersistentData.get(\"voidata\") then"},
{"if PersistentData.get(\"afdata\") then", "if not shared.BOTD_CompatibilityMode and PersistentData.get(\"afdata\") then"},
{"if PersistentData.get(\"titusdata\") then", "if not shared.BOTD_CompatibilityMode and PersistentData.get(\"titusdata\") then"},
{"if PersistentData.get(\"authoritydata\") then", "if not shared.BOTD_CompatibilityMode and PersistentData.get(\"authoritydata\") then"},
{"if PersistentData.get(\"dukedata\") then", "if not shared.BOTD_CompatibilityMode and PersistentData.get(\"dukedata\") then"},
{"if PersistentData.get(\"mooneyriedata\") then", "if not shared.BOTD_CompatibilityMode and PersistentData.get(\"mooneyriedata\") then"},
{"if PersistentData.get(\"notesdata\") then", "if not shared.BOTD_CompatibilityMode and PersistentData.get(\"notesdata\") then"},
{"if PersistentData.get(\"sarameddata\") then", "if not shared.BOTD_CompatibilityMode and PersistentData.get(\"sarameddata\") then"}
},
["Menu"] = {
{"AutoShow = not shared.Luma.silent,", "AutoShow = true,"},
{"\tCombatTab.init(window)", "    local combatOK, combatError = pcall(CombatTab.init, window)\n    if not combatOK then warn(\"[BOTD/compat] Combat tab failed: \" .. tostring(combatError)) end"},
{"\tCombatTab.initAntiExploit(window)", "    local antiOK, antiError = pcall(CombatTab.initAntiExploit, window)\n    if not antiOK then warn(\"[BOTD/compat] Secondary combat tab failed: \" .. tostring(antiError)) end"},
{"\t\tSaveManager:LoadAutoloadConfig()", "        local loaded, loadErr = pcall(function() SaveManager:LoadAutoloadConfig() end)\n        if not loaded then warn(\"[BOTD/compat] Config autoload failed: \" .. tostring(loadErr)) end"}
},
["Features"] = {
{"\tpcall(fn)", "    local ok, err = pcall(fn)\n    if not ok then warn(\"[BOTD/feature] \" .. method .. \" failed: \" .. tostring(err)) end"}
},
["Menu/HomeTab"] = {
{"intro:AddLabel(\"CM1 Edition | Linoria interface\")", "intro:AddLabel(\"CM1 Edition | Linoria interface\")\n    intro:AddLabel(\"Compatibility: privileged hooks OFF\")\n    intro:AddLabel(\"Some dependent functions will remain unavailable.\")"},
{"session:AddButton(\"Unload\", function()", "session:AddButton(\"Copy startup status\", function()\n        if type(setclipboard) == \"function\" and shared then\n            setclipboard(tostring(shared.BOTD_LastError or shared.BOTD_StartupError or \"No reported errors\"))\n        end\n    end)\n    session:AddButton(\"Unload\", function()"}
}
}
local POLISH = {
["Features/Visuals/Visuals"] = {
{"local updateESP = LPH_NO_VIRTUALIZE(function()\n\tif os.clock() - lastESPUpdate <= (1 / (Configuration.expectOptionValue(\"ESPRefreshRate\") or 30)) then\n\t\treturn\n\tend\n\n\tlastESPUpdate = os.clock()\n\n\tfor _, group in next, groups do\n\t\tgroup:update()\n\tend\nend)", "local updateESP = LPH_NO_VIRTUALIZE(function()\n    local now = os.clock()\n    local limitToggle = Toggles and Toggles.ESPLimitUpdates\n    local limited = not limitToggle or limitToggle.Value\n    if limited then\n        local rate = math.clamp(tonumber(Configuration.expectOptionValue(\"ESPRefreshRate\")) or 30, 1, 144)\n        if now - lastESPUpdate < (1 / rate) then\n            return\n        end\n    end\n    lastESPUpdate = now\n    for _, group in next, groups do\n        group:update()\n    end\nend)"},
{"\nreturn Visuals\n", "\nfunction Visuals.espStats()\n    local result = {}\n    for name, group in pairs(groups) do\n        local count = group:size()\n        if count > 0 then\n            result[#result + 1] = {\n                name = name,\n                objects = count,\n                updated = group.lastUpdated or 0,\n                durationMs = group.lastDurationMs or 0,\n                failures = group.failedUpdates or 0,\n            }\n        end\n    end\n    table.sort(result, function(a, b)\n        return a.durationMs > b.durationMs\n    end)\n    return result\nend\n\nreturn Visuals\n"},
{"FilteredESP.new(MobESP.new(\"Mob\", child, child:GetAttribute(\"MOB_rich_name\") or child.Name))", "FilteredESP.new(MobESP.new(\"Mob\", child,\n            child.Name:match(\"^%.?trainer_dummy%d*$\") and \"Training Dummy\"\n            or child:GetAttribute(\"MOB_rich_name\") or child.Name))"}
},
["Menu/VisualsTab"] = {
{"\tgroupbox:AddToggle(\"ESPSplitUpdates\", {", "    groupbox:AddSlider(\"ESPUpdateBudget\", {\n        Text = \"ESP Updates Per Group\",\n        Tooltip = \"Max object updates per refresh. Lower values reduce frame spikes; updates rotate fairly.\",\n        Default = 200,\n        Min = 25,\n        Max = 500,\n        Rounding = 0,\n    })\n\n    groupbox:AddButton(\"ESP Performance Stats\", function()\n        local stats = Visuals.espStats()\n        if #stats == 0 then\n            return Logger.notify(\"ESP: no active tracked objects.\")\n        end\n        local allObjects, changed, totalMs, errors = 0, 0, 0, 0\n        for _, item in ipairs(stats) do\n            allObjects += item.objects\n            changed += item.updated\n            totalMs += item.durationMs\n            errors += item.failures\n        end\n        Logger.longNotify(\"ESP groups: %d | objects: %d | latest updates: %d | %.2f ms | failures: %d\",\n            #stats, allObjects, changed, totalMs, errors)\n        for i = 1, math.min(5, #stats) do\n            local item = stats[i]\n            Logger.warn(\"[ESP] %s: %d objects, %d updated, %.2f ms, %d errors\",\n                item.name, item.objects, item.updated, item.durationMs, item.failures)\n        end\n    end)\n\n\tgroupbox:AddToggle(\"ESPSplitUpdates\", {"},
{"function VisualsTab.initTargetHUDSection(groupbox)", "function VisualsTab.initParryHUDSection(groupbox)\n    groupbox:AddToggle(\"ParryCooldownHUD\", {\n        Text = \"Estimated Parry Cooldown\",\n        Tooltip = \"Local F-key timer only. Does not guarantee that a parry succeeded.\",\n        Default = false,\n    })\n    local dep = groupbox:AddDependencyBox()\n    dep:AddSlider(\"ParryHUDCooldown\", {\n        Text = \"Estimated Cooldown\",\n        Default = 1.4,\n        Min = 0.2,\n        Max = 5,\n        Rounding = 1,\n        Suffix = \"s\",\n    })\n    dep:SetupDependencies({{ Toggles.ParryCooldownHUD, true }})\nend\n\nfunction VisualsTab.initTargetHUDSection(groupbox)"},
{"\tVisualsTab.initTargetHUDSection(tab:AddDynamicGroupbox(\"Target HUD\"))", "    VisualsTab.initTargetHUDSection(tab:AddDynamicGroupbox(\"Target HUD\"))\n    VisualsTab.initParryHUDSection(tab:AddDynamicGroupbox(\"Parry Timer\"))"}
},
["Features/Visuals/Objects/InstanceESP"] = {
{"\ttext.Text = self:build(label, tags)\n\ttext.TextColor3 = Configuration.idOptionValue(identifier, \"Color\")\n\ttext.TextSize = Configuration.expectOptionValue(\"FontSize\")\n\ttext.Font = Enum.Font[Configuration.expectOptionValue(\"Font\")] or Enum.Font.Code\n\n\tlocal transparency = 1 - (Configuration.idOptionValue(identifier, \"TextOpacity\") or 100) / 100\n\ttext.TextTransparency = transparency\n\ttext.TextStrokeTransparency = transparency", "    local currentText = self:build(label, tags)\n    if text.Text ~= currentText then text.Text = currentText end\n    local color = Configuration.idOptionValue(identifier, \"Color\")\n    if color and text.TextColor3 ~= color then text.TextColor3 = color end\n    local size = Configuration.expectOptionValue(\"FontSize\") or 14\n    if text.TextSize ~= size then text.TextSize = size end\n    local font = Enum.Font[Configuration.expectOptionValue(\"Font\") or \"Code\"] or Enum.Font.Code\n    if text.Font ~= font then text.Font = font end\n    local transparency = 1 - (Configuration.idOptionValue(identifier, \"TextOpacity\") or 100) / 100\n    if text.TextTransparency ~= transparency then text.TextTransparency = transparency end\n    if text.TextStrokeTransparency ~= transparency then text.TextStrokeTransparency = transparency end"}
},
["Features/Visuals/Objects/EntityESP"] = {
{"\ttextLabel.Text = text\n\ttextLabel.TextSize = Configuration.expectOptionValue(\"FontSize\") or 13\n\ttextLabel.Font = Enum.Font[Configuration.expectOptionValue(\"Font\") or \"Code\"] or Enum.Font.Code\n\ttextLabel.TextColor3 = Configuration.idOptionValue(self.identifier, \"Color\") or Color3.new(1, 1, 1)\n\n\tlocal transparency = 1 - (Configuration.idOptionValue(self.identifier, \"TextOpacity\") or 100) / 100\n\ttextLabel.TextTransparency = transparency\n\ttextLabel.TextStrokeTransparency = transparency", "    if textLabel.Text ~= text then textLabel.Text = text end\n    local size = Configuration.expectOptionValue(\"FontSize\") or 13\n    if textLabel.TextSize ~= size then textLabel.TextSize = size end\n    local font = Enum.Font[Configuration.expectOptionValue(\"Font\") or \"Code\"] or Enum.Font.Code\n    if textLabel.Font ~= font then textLabel.Font = font end\n    local color = Configuration.idOptionValue(self.identifier, \"Color\") or Color3.new(1, 1, 1)\n    if textLabel.TextColor3 ~= color then textLabel.TextColor3 = color end\n    local transparency = 1 - (Configuration.idOptionValue(self.identifier, \"TextOpacity\") or 100) / 100\n    if textLabel.TextTransparency ~= transparency then textLabel.TextTransparency = transparency end\n    if textLabel.TextStrokeTransparency ~= transparency then textLabel.TextStrokeTransparency = transparency end"}
},
["Features/Visuals/ProximityList"] = {
{"\t\tlabel.Text = name .. \" (\" .. formatDistance(data.distance) .. \")\"\n\t\tlabel.LayoutOrder = order", "        local nextText = name .. \" (\" .. formatDistance(data.distance) .. \")\"\n        if label.Text ~= nextText then label.Text = nextText end\n        if not label.Visible then label.Visible = true end\n        if label.LayoutOrder ~= order then label.LayoutOrder = order end"},
{"\t-- Labels track the instantaneous range (remove when not seen this cycle).\n\tfor key, label in pairs(labelMap) do\n\t\tif not seen[key] then\n\t\t\tpcall(function()\n\t\t\t\tlabel:Destroy()\n\t\t\tend)\n\t\t\tlabelMap[key] = nil\n\t\tend\n\tend", "    -- Hide transient misses, but reuse the label if the player returns within the grace period.\n    for key, label in pairs(labelMap) do\n        if not seen[key] and label.Visible then\n            label.Visible = false\n        end\n    end"},
{"\t\t\tnotified[key] = nil\n\t\t\tlastInRange[key] = nil", "            local label = labelMap[key]\n            if label then\n                label:Destroy()\n                labelMap[key] = nil\n            end\n            notified[key] = nil\n            lastInRange[key] = nil"},
{"\tfor _ in pairs(labelMap) do\n\t\tcount = count + 1\n\tend", "    for _, label in pairs(labelMap) do\n        if label.Visible then count += 1 end\n    end"},
{"\t\t\ttask.wait(0.15)", "            task.wait(Configuration.expectToggleValue(\"ProximityList\") and 0.25 or 0.5)"}
},
["Features"] = {
{"local TargetHUD = require(\"Features/Visuals/TargetHUD\")", "local TargetHUD = require(\"Features/Visuals/TargetHUD\")\n\n---@module Features.Visuals.ParryHUD\nlocal ParryHUD = require(\"Features/Visuals/ParryHUD\")"},
{"\tTargetHUD,\n\tMovement,", "    TargetHUD,\n    ParryHUD,\n    Movement,"},
{"\tTargetHUD,\n\tAutoLoot,", "    TargetHUD,\n    ParryHUD,\n    AutoLoot,"}
}
}

local GROUP_OLD = "---@module Utility.ReferencedMap\nlocal ReferencedMap = require(\"Utility/ReferencedMap\")\n\n---@module Utility.Profiler\nlocal Profiler = require(\"Utility/Profiler\")\n\n---@module Utility.Logger\nlocal Logger = require(\"Utility/Logger\")\n\n---@module Utility.Configuration\nlocal Configuration = require(\"Utility/Configuration\")\n\n---@class Group: ReferencedMap\n---@field part number\n---@field icount number\n---@field updated boolean\n---@field identifier string\nlocal Group = setmetatable({}, ReferencedMap)\nGroup.__index = Group\n\n---@param self Group\n---@param object ModelESP|PartESP|FilteredESP\nGroup.object = LPH_NO_VIRTUALIZE(function(self, object)\n\tself.count = self.count + 1\n\n\tif not self.warned and self.count >= 500 then\n\t\tLogger.longNotify(\"(%s) Too many objects will cause your elements to stop updating.\", object.identifier)\n\n\t\tself.warned = true\n\tend\n\n\t---@note: If we're updating too many objects, it will cause Roblox to hide UI elements and kick us from the game.\n\tif self.count >= 500 then\n\t\treturn\n\tend\n\n\tProfiler.run(self.updateLabel, object.update, object)\nend)\n\n---@param self Group\nGroup.update = LPH_NO_VIRTUALIZE(function(self)\n\tlocal map = self:data()\n\n\tif not Configuration.idToggleValue(self.identifier, \"Enable\") then\n\t\treturn self:hide()\n\tend\n\n\tif Configuration.expectToggleValue(\"ESPSplitUpdates\") then\n\t\tlocal totalElements = #map\n\t\tlocal totalFrames = Configuration.expectOptionValue(\"ESPSplitFrames\")\n\n\t\tlocal objectsPerPart = math.ceil(totalElements / totalFrames)\n\t\tlocal currentPart = self.part\n\n\t\tlocal startIdx = (currentPart - 1) * objectsPerPart + 1\n\t\tlocal endIdx = math.min(currentPart * objectsPerPart, totalElements)\n\n\t\tfor idx = startIdx, endIdx do\n\t\t\tself:object(map[idx])\n\t\tend\n\n\t\tself.part = self.part + 1\n\n\t\tif self.part > totalFrames then\n\t\t\tself.count = 0\n\t\t\tself.part = 1\n\t\tend\n\telse\n\t\tfor _, object in next, map do\n\t\t\tself:object(object)\n\t\tend\n\n\t\tself.part = 1\n\t\tself.count = 0\n\tend\n\n\tself.updated = true\nend)\n\n---@param self Group\nGroup.hide = LPH_NO_VIRTUALIZE(function(self)\n\tif not self.updated then\n\t\treturn\n\tend\n\n\tfor _, object in next, self:data() do\n\t\tobject:visible(false)\n\tend\n\n\tself.updated = false\nend)\n\n---@param self Group\nGroup.detach = LPH_NO_VIRTUALIZE(function(self)\n\tfor _, object in next, self:data() do\n\t\tobject:detach()\n\tend\nend)\n\n---@param identifier string\n---@return Group\nfunction Group.new(identifier)\n\tlocal self = setmetatable(ReferencedMap.new(), Group)\n\tself.part = 1\n\tself.count = 0\n\tself.warned = false\n\tself.updated = true\n\tself.identifier = identifier\n\tself.updateLabel = string.format(\"ESP_Update_%s\", identifier)\n\treturn self\nend\n\nreturn Group\nend)\n"
local GROUP_NEW = "---@module Utility.ReferencedMap\nlocal ReferencedMap = require(\"Utility/ReferencedMap\")\n---@module Utility.Profiler\nlocal Profiler = require(\"Utility/Profiler\")\n---@module Utility.Logger\nlocal Logger = require(\"Utility/Logger\")\n---@module Utility.Configuration\nlocal Configuration = require(\"Utility/Configuration\")\n\nlocal Group = setmetatable({}, ReferencedMap)\nGroup.__index = Group\n\nlocal MAX_VISIBLE_WORK = 500\n\nlocal function boundedInteger(value, default, minimum, maximum)\n    value = tonumber(value) or default\n    return math.clamp(math.floor(value), minimum, maximum)\nend\n\nfunction Group:object(object)\n    if not object or type(object.update) ~= \"function\" then\n        return\n    end\n    local ok, err = pcall(Profiler.run, self.updateLabel, object.update, object)\n    if not ok then\n        local now = os.clock()\n        self.failedUpdates = self.failedUpdates + 1\n        if now - self.lastWarning > 30 then\n            self.lastWarning = now\n            Logger.warn(\"ESP %s update error: %s\", self.identifier, tostring(err))\n        end\n    end\nend\n\nfunction Group:update()\n    if not Configuration.idToggleValue(self.identifier, \"Enable\") then\n        return self:hide()\n    end\n\n    local objects = self:data()\n    local total = #objects\n    if total == 0 then\n        self.cursor = 1\n        self.lastUpdated = 0\n        self.lastDurationMs = 0\n        self.updated = true\n        return\n    end\n\n    local split = Configuration.expectToggleValue(\"ESPSplitUpdates\")\n    local frames = split and boundedInteger(Configuration.expectOptionValue(\"ESPSplitFrames\"), 32, 1, 64) or 1\n    local option = Options and Options.ESPUpdateBudget\n    local budget = boundedInteger(option and option.Value, 200, 10, MAX_VISIBLE_WORK)\n    if split then\n        budget = math.min(budget, math.max(1, math.ceil(total / frames)))\n    end\n    budget = math.min(total, budget)\n\n    local first = boundedInteger(self.cursor, 1, 1, total)\n    local timestamp = os.clock()\n    for offset = 0, budget - 1 do\n        local index = ((first + offset - 1) % total) + 1\n        self:object(objects[index])\n    end\n    self.cursor = ((first + budget - 1) % total) + 1\n    self.lastUpdated = budget\n    self.lastDurationMs = (os.clock() - timestamp) * 1000\n    self.totalUpdated = self.totalUpdated + budget\n    self.updated = true\nend\n\nfunction Group:hide()\n    if not self.updated then return end\n    for _, object in next, self:data() do\n        if object and type(object.visible) == \"function\" then\n            pcall(object.visible, object, false)\n        end\n    end\n    self.updated = false\n    self.cursor = 1\nend\n\nfunction Group:detach()\n    for _, object in next, self:data() do\n        if object and type(object.detach) == \"function\" then\n            pcall(object.detach, object)\n        end\n    end\n    self.updated = false\nend\n\nfunction Group.new(identifier)\n    local self = setmetatable(ReferencedMap.new(), Group)\n    self.identifier = identifier\n    self.updateLabel = string.format(\"ESP_Update_%s\", identifier)\n    self.cursor = 1\n    self.updated = false\n    self.totalUpdated = 0\n    self.lastUpdated = 0\n    self.lastDurationMs = 0\n    self.failedUpdates = 0\n    self.lastWarning = -math.huge\n    return self\nend\n\nreturn Group\n\nend)\n"
local EXTRA_MODULE = "__bundle_register(\"Features/Visuals/ParryHUD\", function(require, _LOADED, __bundle_register, __bundle_modules)\nlocal ParryHUD = {}\nlocal UserInputService = game:GetService(\"UserInputService\")\nlocal RunService = game:GetService(\"RunService\")\nlocal Players = game:GetService(\"Players\")\n\nlocal gui, bar, label, outer\nlocal connections = {}\nlocal pressedAt = -math.huge\nlocal tickElapsed = 0\nlocal lastText = \"\"\nlocal started = false\n\nlocal function enabled()\n    local toggle = Toggles and Toggles.ParryCooldownHUD\n    return toggle and toggle.Value == true\nend\n\nlocal function option(name, fallback)\n    local v = Options and Options[name]\n    return v and tonumber(v.Value) or fallback\nend\n\nlocal function makeGui()\n    local lp = Players.LocalPlayer\n    local parent = lp and lp:FindFirstChildOfClass(\"PlayerGui\")\n    if not parent then return end\n    gui = Instance.new(\"ScreenGui\")\n    gui.Name = \"BOTD_EstimatedParryCooldown\"\n    gui.ResetOnSpawn = false\n    gui.DisplayOrder = 60\n    gui.Enabled = false\n    outer = Instance.new(\"Frame\")\n    outer.Size = UDim2.fromOffset(240, 36)\n    outer.AnchorPoint = Vector2.new(0.5, 1)\n    outer.Position = UDim2.fromScale(0.5, 0.88)\n    outer.BackgroundColor3 = Color3.fromRGB(18, 23, 33)\n    outer.BorderSizePixel = 0\n    outer.Parent = gui\n    local corner = Instance.new(\"UICorner\")\n    corner.CornerRadius = UDim.new(0, 5)\n    corner.Parent = outer\n    bar = Instance.new(\"Frame\")\n    bar.Size = UDim2.fromScale(1, 0)\n    bar.Position = UDim2.fromScale(0, 1)\n    bar.AnchorPoint = Vector2.new(0, 1)\n    bar.BackgroundColor3 = Color3.fromRGB(95, 175, 135)\n    bar.BorderSizePixel = 0\n    bar.Parent = outer\n    label = Instance.new(\"TextLabel\")\n    label.Size = UDim2.new(1, -12, 1, 0)\n    label.Position = UDim2.fromOffset(6, 0)\n    label.BackgroundTransparency = 1\n    label.Font = Enum.Font.Code\n    label.TextColor3 = Color3.fromRGB(240, 242, 247)\n    label.TextSize = 14\n    label.Text = \"Parry estimate | Ready\"\n    label.ZIndex = 2\n    label.Parent = outer\n    gui.Parent = parent\nend\n\nlocal function update(delta)\n    tickElapsed += delta\n    if tickElapsed < 0.05 then return end\n    tickElapsed = 0\n    local shouldShow = enabled()\n    if not gui or not gui.Parent then makeGui() end\n    if not gui then return end\n    if gui.Enabled ~= shouldShow then gui.Enabled = shouldShow end\n    if not shouldShow then return end\n\n    local cooldown = math.clamp(option(\"ParryHUDCooldown\", 1.4), 0.2, 5)\n    local elapsed = os.clock() - pressedAt\n    local fraction = math.clamp(elapsed / cooldown, 0, 1)\n    local remaining = math.max(0, cooldown - elapsed)\n    local message = remaining == 0 and \"Parry estimate | Ready\"\n        or string.format(\"Parry estimate | %.1fs\", remaining)\n    if message ~= lastText then\n        label.Text = message\n        lastText = message\n    end\n    local target = UDim2.fromScale(fraction, 1)\n    if bar.Size ~= target then bar.Size = target end\n    local color = remaining == 0 and Color3.fromRGB(95, 175, 135) or Color3.fromRGB(222, 116, 113)\n    if bar.BackgroundColor3 ~= color then bar.BackgroundColor3 = color end\nend\n\nfunction ParryHUD.init()\n    if started then return end\n    started = true\n    connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, processed)\n        if processed or not enabled() or UserInputService:GetFocusedTextBox() then return end\n        if input.KeyCode == Enum.KeyCode.F then\n            pressedAt = os.clock()\n        end\n    end)\n    connections[#connections + 1] = RunService.Heartbeat:Connect(update)\nend\n\nfunction ParryHUD.detach()\n    started = false\n    for _, connection in ipairs(connections) do connection:Disconnect() end\n    table.clear(connections)\n    if gui then gui:Destroy() end\n    gui, outer, bar, label = nil, nil, nil, nil\n    lastText = \"\"\nend\n\nreturn ParryHUD\n\nend)\n"

if shared then
    shared.BOTD_Status = status
    shared.BOTD_StartupError = nil
    shared.BOTD_LastError = nil
end
local success, result = xpcall(function()
    local parts = table.create(PARTS)
    for i = 1, PARTS do
        status(string.format("Downloading %d/%d", i, PARTS))
        local path = string.format("parts/part_%02d.lua.txt", i)
        local ok, data = pcall(function() return game:HttpGet(BASE .. path) end)
        assert(ok and type(data)=="string", "Download failed: " .. path .. ": " .. tostring(data))
        parts[i] = data
    end
    local bundle = table.concat(parts)
    assert(#bundle == EXPECTED_BYTES, "Source size mismatch: " .. #bundle)
    for _, name in ipairs({"__root", "Luma", "Menu", "Features", "Menu/HomeTab"}) do
        status("Compatibility: " .. name)
        bundle = patchModule(bundle, name, COMPAT[name])
    end
    for _, name in ipairs({"Features", "Features/Visuals/Visuals", "Features/Visuals/Objects/InstanceESP", "Features/Visuals/Objects/EntityESP", "Features/Visuals/ProximityList", "Menu/VisualsTab"}) do
        status("Polishing " .. name)
        bundle = patchModule(bundle, name, POLISH[name])
    end
    bundle = patchModule(bundle, "Features/Visuals/Group", {{GROUP_OLD, GROUP_NEW}})
    local anchor = '__bundle_register("Features", function(require, _LOADED, __bundle_register, __bundle_modules)\n'
    bundle = replaceOnce(bundle, anchor, EXTRA_MODULE .. anchor, "ParryHUD insertion")
    status("Compiling polished BotD")
    local run, errorMessage = loadstring(bundle)
    assert(run, "Luau compilation failed: " .. tostring(errorMessage))
    status("Starting BotD with restricted hooks OFF")
    local output = run()
    if shared and shared.BOTD_StartupError then
        status("INIT ERROR: " .. tostring(shared.BOTD_StartupError))
    elseif shared and shared.BOTD_LastError then
        status("Some modules unavailable: " .. tostring(shared.BOTD_LastError))
    else
        status("Initializer returned. Live testing still required.")
    end
    return output
end, function(err)
    local detail = tostring(err)
    if debug and type(debug.traceback) == "function" then detail = debug.traceback(detail, 2) end
    return detail
end)
if not success then
    status("FAILED: " .. tostring(result))
    error(result, 0)
end
return result
