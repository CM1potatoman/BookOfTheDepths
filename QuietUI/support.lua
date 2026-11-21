-- Book of the Depths: standalone event information + safe runtime support.
-- Timer model adapted from whensthenextworldevent (MIT, copyright 2026 riven).
-- See https://github.com/riven/whensthenextworldevent for upstream licensing.
-- The clock is an estimate based on a public schedule, not server-confirmed.
local ROOT_KEY = "__CM1_BOTD_SUPPORT_V1"
local SETTINGS_PATH = "CM1_BOTD_SupportSettings.json"
local LOG_PATH = "CM1_BOTD_Support.log"
local TITLE = "[BotD Support]"

local host = _G
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then host = result end
end

local function capability(name)
    local value = rawget(host, name) or rawget(_G, name)
    return type(value) == "function" and value or nil
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return false, "unavailable" end
    return pcall(fn, ...)
end

local old = rawget(host, ROOT_KEY)
if type(old) == "table" and type(old.stop) == "function" then
    pcall(old.stop, old)
end

local state = {
    active = true,
    connections = {},
    instances = {},
    logs = {},
    settings = { visible = false, showDisasters = true },
}
host[ROOT_KEY] = state

local console = capability("rconsoleprint") or capability("consoleprint")
local appendFile = capability("appendfile")
local writeFile = capability("writefile")
local readFile = capability("readfile")
local isFile = capability("isfile")
local http = game:GetService("HttpService")

local logFileReady = false
local function log(level, message)
    local line = string.format("%s [%s] %s", TITLE, level, tostring(message))
    state.logs[#state.logs + 1] = line
    if #state.logs > 200 then table.remove(state.logs, 1) end
    if console then
        local ok = safeCall(console, line .. "\n")
        if ok then return end
        console = nil
    end
    if appendFile then
        if not logFileReady and writeFile then
            local ok, exists = safeCall(isFile, LOG_PATH)
            if not ok or not exists then safeCall(writeFile, LOG_PATH, "") end
            logFileReady = true
        end
        safeCall(appendFile, LOG_PATH, line .. "\n")
    end
    -- Do not redirect messages into Roblox's developer console.
end
state.log = log

local function trackConnection(connection)
    state.connections[#state.connections + 1] = connection
    return connection
end
local function trackInstance(instance)
    state.instances[#state.instances + 1] = instance
    return instance
end

function state:stop()
    if not self.active then return end
    self.active = false
    for i = #self.connections, 1, -1 do
        pcall(function() self.connections[i]:Disconnect() end)
        self.connections[i] = nil
    end
    for i = #self.instances, 1, -1 do
        pcall(function() self.instances[i]:Destroy() end)
        self.instances[i] = nil
    end
    if rawget(host, ROOT_KEY) == self then host[ROOT_KEY] = nil end
    log("INFO", "Support module stopped and resources released")
end

local function loadSettings()
    if not readFile then return end
    if isFile then
        local ok, exists = safeCall(isFile, SETTINGS_PATH)
        if not ok or not exists then return end
    end
    local ok, contents = safeCall(readFile, SETTINGS_PATH)
    if not ok or type(contents) ~= "string" then return end
    local parsed, settings = pcall(http.JSONDecode, http, contents)
    if not parsed or type(settings) ~= "table" then
        log("WARN", "Saved settings were invalid; defaults restored")
        return
    end
    for key, _ in pairs(state.settings) do
        if type(settings[key]) == "boolean" then state.settings[key] = settings[key] end
    end
end

local function saveSettings()
    if not writeFile then return end
    local ok, contents = pcall(http.JSONEncode, http, state.settings)
    if ok then safeCall(writeFile, SETTINGS_PATH, contents) end
end
state.saveSettings = saveSettings

-- Upstream schedule model: 20 Sep 2026 UTC, alternating 30/60-minute slots.
local WORLD_ANCHOR = 1789943400 -- 2026-09-20 22:30:00 UTC
local DISASTER_ANCHOR = 1789941600 -- 2026-09-20 22:00:00 UTC
local WORLD_INTERVAL = 30 * 60
local DISASTER_INTERVAL = 60 * 60
local JOIN_SECONDS = 5 * 60
local WORLD_NAMES = { "Battle Royale", "Carnival of Hearts", "Interluminary Interloper" }
local DISASTER_NAMES = { "Cinders of Etris", "Doom of Caeranthil" }

local function getSlot(now, anchor, interval, names)
    local n = math.floor((now - anchor) / interval)
    local idx = (n % #names) + 1
    local prev = ((n - 1) % #names) + 1
    local nextIndex = ((n + 1) % #names) + 1
    local started = anchor + n * interval
    return {
        current = names[idx],
        previous = names[prev],
        next = names[nextIndex],
        started = started,
        untilNext = math.max(0, started + interval - now),
        joinRemaining = math.max(0, JOIN_SECONDS - (now - started)),
    }
end

function state.eventsAt(now)
    now = tonumber(now) or os.time()
    return {
        world = getSlot(now, WORLD_ANCHOR, WORLD_INTERVAL, WORLD_NAMES),
        disaster = getSlot(now, DISASTER_ANCHOR, DISASTER_INTERVAL, DISASTER_NAMES),
    }
end

local function countdown(seconds)
    seconds = math.max(0, math.floor(seconds))
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function rounded(ui, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = ui
end

local function makeGui()
    local players = game:GetService("Players")
    local player = players.LocalPlayer
    if not player then error("LocalPlayer unavailable") end
    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then error("PlayerGui unavailable") end

    local existing = playerGui:FindFirstChild("CM1_BotD_EventPanel")
    if existing then existing:Destroy() end

    local screen = trackInstance(Instance.new("ScreenGui"))
    screen.Name = "CM1_BotD_EventPanel"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = playerGui

    local toggle = Instance.new("TextButton")
    toggle.Name = "EventToggle"
    toggle.Size = UDim2.fromOffset(82, 32)
    toggle.Position = UDim2.new(1, -94, 0.54, 0)
    toggle.BackgroundColor3 = Color3.fromRGB(45, 42, 35)
    toggle.TextColor3 = Color3.fromRGB(231, 207, 148)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 13
    toggle.Text = "EVENTS"
    toggle.BorderSizePixel = 0
    toggle.Parent = screen
    rounded(toggle, 7)

    local panel = Instance.new("Frame")
    panel.Name = "EventInfo"
    panel.Size = UDim2.fromOffset(290, 181)
    panel.Position = UDim2.new(1, -304, 0.54, 38)
    panel.BackgroundColor3 = Color3.fromRGB(26, 27, 28)
    panel.BackgroundTransparency = 0.06
    panel.BorderSizePixel = 0
    panel.Visible = state.settings.visible
    panel.Parent = screen
    rounded(panel, 9)

    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, -12, 0, 30)
    header.Position = UDim2.fromOffset(6, 5)
    header.BackgroundTransparency = 1
    header.Text = "BOTD  /  WORLD EVENTS"
    header.TextColor3 = Color3.fromRGB(231, 207, 148)
    header.TextSize = 13
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Font = Enum.Font.GothamBold
    header.Parent = panel

    local function makeLabel(y)
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, -20, 0, 23)
        text.Position = UDim2.fromOffset(10, y)
        text.BackgroundTransparency = 1
        text.TextColor3 = Color3.fromRGB(237, 236, 231)
        text.TextSize = 12
        text.Font = Enum.Font.Gotham
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.Parent = panel
        return text
    end

    local worldLabel = makeLabel(40)
    local nextLabel = makeLabel(65)
    local disasterLabel = makeLabel(91)
    local disasterNext = makeLabel(116)
    local footer = makeLabel(142)
    footer.TextSize = 10
    footer.TextColor3 = Color3.fromRGB(174, 169, 158)

    local function update()
        if not state.active or not screen.Parent then return end
        local data = state.eventsAt()
        worldLabel.Text = "Now: " .. data.world.current
        nextLabel.Text = "Next: " .. data.world.next .. "  " .. countdown(data.world.untilNext)
        disasterLabel.Visible = state.settings.showDisasters
        disasterNext.Visible = state.settings.showDisasters
        disasterLabel.Text = "Disaster: " .. data.disaster.current
        disasterNext.Text = "Next: " .. data.disaster.next .. "  " .. countdown(data.disaster.untilNext)
        footer.Text = (data.world.joinRemaining > 0
            and ("Estimated join window: " .. countdown(data.world.joinRemaining))
            or "Join window: estimated closed") .. "  |  tap header"
    end

    local function setVisible(value)
        state.settings.visible = value
        panel.Visible = value
        toggle.Text = value and "HIDE" or "EVENTS"
        saveSettings()
    end
    setVisible(state.settings.visible)
    trackConnection(toggle.MouseButton1Click:Connect(function()
        setVisible(not state.settings.visible)
    end))
    trackConnection(header.MouseButton1Click:Connect(function()
        state.settings.showDisasters = not state.settings.showDisasters
        saveSettings()
        update()
    end))

    -- Mouse/touch dragging is scoped to this panel; no global input overrides.
    local inputService = game:GetService("UserInputService")
    local dragStart, panelStart, dragging
    trackConnection(header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            panelStart = panel.Position
        end
    end))
    trackConnection(header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    trackConnection(inputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(panelStart.X.Scale, panelStart.X.Offset + delta.X,
                panelStart.Y.Scale, panelStart.Y.Offset + delta.Y)
        end
    end))

    local elapsed = 0
    trackConnection(game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not state.active or not panel.Visible then return end
        elapsed = elapsed + dt
        if elapsed >= 1 then
            elapsed = 0
            local ok, err = pcall(update)
            if not ok then log("ERROR", "Event UI refresh: " .. tostring(err)) end
        end
    end))
    update()
end

loadSettings()
log("INFO", "Starting event information module")
local ok, err = xpcall(makeGui, function(message)
    if type(debug) == "table" and type(debug.traceback) == "function" then
        return debug.traceback(tostring(message), 2)
    end
    return tostring(message)
end)
if not ok then
    log("ERROR", "UI start failed: " .. tostring(err))
end
return state
