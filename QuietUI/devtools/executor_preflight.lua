-- CM1 / QuietUI executor preflight
-- Runs isolated environment checks. Does not load or execute BOTD gameplay code.
-- Does not inspect other scripts, hook calls, or send any data.
local name = "CM1QuietUIPreflight"
local results = {}
local started = os.clock()
local function record(label, ok, detail)
    results[#results + 1] = {
        name = label,
        passed = ok == true,
        detail = tostring(detail or ""),
    }
    local message = "[CM1 Preflight] " .. (ok and "PASS" or "FAIL") .. " " .. label
    if detail and detail ~= "" then
        message = message .. " - " .. tostring(detail)
    end
    print(message)
end

local function check(label, callback)
    local ok, value = pcall(callback)
    if not ok then
        record(label, false, value)
        return
    end
    if value == false or value == nil then
        record(label, false, "No usable result")
        return
    end
    record(label, true, value == true and "OK" or value)
end

check("Luau task API", function()
    return type(task) == "table" and type(task.spawn) == "function"
        and type(task.wait) == "function" or false
end)

check("loadstring compilation", function()
    if type(loadstring) ~= "function" then
        error("loadstring is unavailable")
    end
    local fn, err = loadstring("return 40 + 2")
    if type(fn) ~= "function" then
        error(tostring(err or "Compilation returned no function"))
    end
    assert(fn() == 42, "Compiled function produced an unexpected value")
    return "Simple compilation and execution passed"
end)

check("getgenv shared state", function()
    if type(getgenv) ~= "function" then
        error("getgenv is unavailable")
    end
    local env = getgenv()
    assert(type(env) == "table", "getgenv returned " .. typeof(env))
    return "Writable environment available"
end)

check("Roblox services", function()
    local players = game:GetService("Players")
    local stats = game:GetService("Stats")
    local localPlayer = players.LocalPlayer
    assert(localPlayer ~= nil, "Players.LocalPlayer unavailable")
    assert(stats ~= nil, "Stats service unavailable")
    return "Players and Stats are available"
end)

check("Client memory read", function()
    local stats = game:GetService("Stats")
    local mb = stats:GetTotalMemoryUsageMb()
    assert(type(mb) == "number", "Memory result is not numeric")
    return string.format("%.1f MB total client memory", mb)
end)

check("GitHub HTTP download", function()
    local url = "https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/main/QuietUI/README.md"
    local body = game:HttpGet(url)
    assert(type(body) == "string", "Response is not a string")
    assert(body:find("CM1 Deepwoken Quiet UI", 1, true), "Unexpected GitHub response")
    return string.format("README fetched (%d bytes); source not executed", #body)
end)

record("Optional gethui", type(gethui) == "function",
    type(gethui) == "function" and "Available" or "Unavailable, not required by this test")
record("Optional filesystem APIs",
    type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function",
    "Availability only; no files written")

local passed = 0
for _, result in ipairs(results) do
    if result.passed then
        passed += 1
    end
end

local heading = string.format("CM1 QUIETUI PREFLIGHT | %d/%d PASS | %.2fs",
    passed, #results, os.clock() - started)
local lines = { heading }
for _, result in ipairs(results) do
    lines[#lines + 1] = string.format("%s  %s%s",
        result.passed and "[PASS]" or "[FAIL]",
        result.name,
        result.detail ~= "" and (" - " .. result.detail) or "")
end
lines[#lines + 1] = "Only basic environment compatibility was checked."
lines[#lines + 1] = "No BOTD module was loaded or executed."
local report = table.concat(lines, "\n")
print(report)

if type(getgenv) == "function" then
    pcall(function()
        getgenv().CM1QuietUIPreflight = {
            summary = heading,
            results = results,
            text = report,
        }
    end)
end

local ok, uiError = pcall(function()
    local players = game:GetService("Players")
    local player = assert(players.LocalPlayer, "LocalPlayer unavailable")
    local playerGui = assert(player:WaitForChild("PlayerGui", 5), "PlayerGui unavailable")

    local previous = playerGui:FindFirstChild(name)
    if previous then
        previous:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = name
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local frame = Instance.new("Frame")
    frame.Name = "Panel"
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.Size = UDim2.new(0.88, 0, 0.72, 0)
    frame.BackgroundColor3 = Color3.fromRGB(23, 28, 39)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local cap = Instance.new("UISizeConstraint")
    cap.MaxSize = Vector2.new(680, 530)
    cap.MinSize = Vector2.new(280, 230)
    cap.Parent = frame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(230, 236, 245)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Text = "CM1 | EXECUTOR PREFLIGHT"
    title.Position = UDim2.fromOffset(16, 12)
    title.Size = UDim2.new(1, -130, 0, 28)
    title.Parent = frame

    local box = Instance.new("ScrollingFrame")
    box.Name = "Results"
    box.Position = UDim2.fromOffset(16, 52)
    box.Size = UDim2.new(1, -32, 1, -110)
    box.BackgroundColor3 = Color3.fromRGB(15, 19, 28)
    box.BorderSizePixel = 0
    box.ScrollBarThickness = 6
    box.AutomaticCanvasSize = Enum.AutomaticSize.Y
    box.CanvasSize = UDim2.fromOffset(0, 0)
    box.Parent = frame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)

    local label = Instance.new("TextLabel")
    label.Name = "Output"
    label.Text = report
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(219, 226, 239)
    label.TextWrapped = true
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.Position = UDim2.fromOffset(10, 10)
    label.Size = UDim2.new(1, -22, 0, 0)
    label.Parent = box

    local function addButton(buttonName, caption, x, click)
        local button = Instance.new("TextButton")
        button.Name = buttonName
        button.Text = caption
        button.Font = Enum.Font.GothamSemibold
        button.TextSize = 14
        button.TextColor3 = Color3.fromRGB(248, 250, 252)
        button.BackgroundColor3 = Color3.fromRGB(66, 83, 116)
        button.BorderSizePixel = 0
        button.Size = UDim2.fromOffset(130, 34)
        button.AnchorPoint = Vector2.new(1, 1)
        button.Position = UDim2.new(1, x, 1, -12)
        button.Parent = frame
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
        button.MouseButton1Click:Connect(click)
    end

    addButton("Close", "Close", -14, function()
        gui:Destroy()
    end)
    addButton("Copy", "Copy report", -152, function()
        if type(setclipboard) == "function" then
            local copied = pcall(setclipboard, report)
            if copied then
                title.Text = "CM1 | REPORT COPIED"
                return
            end
        end
        title.Text = "CM1 | REPORT IN EXECUTOR CONSOLE"
    end)

    gui.Parent = playerGui
end)

if not ok then
    warn("[CM1 Preflight] Could not display results UI: " .. tostring(uiError))
    warn("[CM1 Preflight] Report is still available in output, if supported.")
end

return {
    passed = passed,
    total = #results,
    report = report,
    uiCreated = ok,
}
