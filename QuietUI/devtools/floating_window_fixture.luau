local function signal()
    local callbacks = {}
    return {
        Connect = function(_, callback)
            callbacks[#callbacks + 1] = callback
            return {Disconnect = function() end}
        end,
        Fire = function()
            for _, callback in ipairs(callbacks) do callback() end
        end,
    }
end
UDim2 = {
    new = function(...) return {...} end,
    fromOffset = function(...) return {...} end,
    fromScale = function(...) return {...} end,
}
UDim = {new = function(...) return {...} end}
Vector2 = {new = function(...) return {...} end}
Enum = {Font = {GothamBold = "bold"}, TextXAlignment = {Left = "left"}, TextTruncate = {AtEnd = "end"}}
local created = {}
local registryCount = 0
local native = {
    MainColor = "main", BackgroundColor = "background", AccentColor = "accent",
    FontColor = "font", ScreenGui = {Name = "NativeLinoriaGui"},
}
function native:Create(kind, props)
    local instance = {
        ClassName = kind,
        MouseEnter = signal(), MouseLeave = signal(),
        MouseButton1Click = signal(),
    }
    for key, value in pairs(props) do instance[key] = value end
    created[#created + 1] = instance
    return instance
end
function native:AddToRegistry(instance, theme)
    assert(type(instance) == "table" and type(theme) == "table")
    registryCount += 1
end
function native:MakeDraggable(frame, barHeight)
    assert(barHeight == 26 and frame.Parent == self.ScreenGui)
    frame.DraggableAttached = true
end
local function mockRequire(name)
    assert(name == "GUI/Linoria", "legacy library dependency remains: " .. tostring(name))
    return native
end
-- FLOATING_WINDOW_MODULE_GOES_HERE
local panel = FloatingWindow.new({title = "Initial"})
assert(panel.frame.Parent == native.ScreenGui, "not parented to native Linoria")
assert(panel.frame.DraggableAttached, "native dragging not attached")
assert(registryCount >= 4, "native theme registry ignored")
assert(not panel:IsOpen(), "panel should start hidden")
panel:Show()
assert(panel:IsOpen(), "show failed")
panel:Hide()
assert(not panel:IsOpen(), "hide failed")
panel:Toggle()
assert(panel:IsOpen(), "toggle failed")
panel:SetTitle("Renamed")
local closeButton
local titleLabel
for _, instance in ipairs(created) do
    if instance.ClassName == "TextButton" and instance.Text == "X" then closeButton = instance end
    if instance.ClassName == "TextLabel" and instance.Text == "Renamed" then titleLabel = instance end
end
assert(closeButton and titleLabel, "native window controls were not constructed")
closeButton.MouseEnter:Fire()
assert(closeButton.TextColor3 == native.AccentColor)
closeButton.MouseLeave:Fire()
assert(closeButton.TextColor3 == native.FontColor)
closeButton.MouseButton1Click:Fire()
assert(not panel:IsOpen(), "close button failed")
print("PASS: FloatingWindow native Linoria contract")
