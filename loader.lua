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
    label.Size = UDim2.fromOffset(510, 96)
    label.Position = UDim2.fromOffset(20, 132)
    label.BackgroundColor3 = Color3.fromRGB(18, 21, 29)
    label.TextColor3 = Color3.fromRGB(226, 233, 245)
    label.BorderSizePixel = 0
    label.TextSize = 16
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

    status("Downloaded 4,349,988 bytes. Compiling Luau.")
    local run, compileError = loadstring(bundle)
    assert(run, "Compilation failed: " .. tostring(compileError))

    status("Compilation passed. Entering main initializer.")
    local value = run()
    status("Initializer returned. UI is not yet verified.")
    return value
end, traceback)

if not success then
    status("FAILED: " .. tostring(result):sub(1, 350))
    error(result, 0)
end

task.delay(4, function()
    if not (shared and shared.Luma) then
        status("WARNING: No Luma instance found. Check initialization.")
    else
        status("Runtime instance found. If no menu appears, initialization/UI failed.")
    end
end)

return result
