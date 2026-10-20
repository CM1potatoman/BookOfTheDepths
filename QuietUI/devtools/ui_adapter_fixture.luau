local env = { Toggles = {}, Options = {} }
local function getgenv()
    return env
end

local Color3 = {
    fromRGB = function(r, g, b)
        return { r = r, g = g, b = b }
    end,
}

local game = {
    HttpGet = function(self, url)
        assert(type(url) == "string" and string.find(url, "Library.lua", 1, true))
        return "-- mock native Linoria, loaded by the harness only"
    end,
}

local notifications = 0
local Legacy = {
    OverrideData = {},
    PositionList = {},
    InfoLoggerData = {},
}

function Legacy:Notify(message)
    assert(type(message) == "string")
    notifications += 1
end

local function makeControl(kind, id, details)
    details = details or {}
    local control = {
        Type = kind,
        Id = id,
        Default = details.Default,
        Value = details.Default,
        Values = details.Values,
        Mode = details.Mode,
        Callback = details.Callback,
    }

    function control:SetValue(value)
        self.Value = value
        if self.Callback then
            self.Callback(value)
        end
        if self.Changed then
            self.Changed(value)
        end
    end

    function control:AddKeyPicker(innerId, innerDetails)
        return makeControl("KeyPicker", innerId, innerDetails)
    end

    function control:AddColorPicker(innerId, innerDetails)
        return makeControl("ColorPicker", innerId, innerDetails)
    end

    function control:SetText(value)
        self.Value = value
    end

    return control
end

local function makeGroupbox(name)
    local group = { Name = name }

    function group:AddToggle(id, details)
        return makeControl("Toggle", id, details)
    end

    function group:AddSlider(id, details)
        return makeControl("Slider", id, details)
    end

    function group:AddDropdown(id, details)
        return makeControl("Dropdown", id, details)
    end

    function group:AddInput(id, details)
        return makeControl("Input", id, details)
    end

    function group:AddLabel(value)
        return makeControl("Label", nil, { Default = value })
    end

    function group:AddDependencyBox()
        return makeGroupbox("Dependency")
    end

    return group
end

local native = {
    Created = false,
}

function native:CreateWindow(info)
    assert(type(info) == "table" and type(info.Title) == "string")
    self.Created = true
    local window = { _tabNames = {} }

    function window:AddTab(name)
        table.insert(self._tabNames, name)
        local tab = {}

        function tab:AddLeftGroupbox(label)
            return makeGroupbox(label)
        end

        function tab:AddRightGroupbox(label)
            return makeGroupbox(label)
        end

        function tab:AddLeftTabbox()
            return {
                AddTab = function(self, name)
                    return makeGroupbox(name)
                end,
            }
        end

        function tab:AddRightTabbox()
            return {
                AddTab = function(self, name)
                    return makeGroupbox(name)
                end,
            }
        end

        return tab
    end

    return window
end

local function loadstring(source)
    assert(type(source) == "string")
    return function()
        return native
    end
end

local function requireMock(name)
    assert(name == "GUI/Library", "Unexpected dependency: " .. tostring(name))
    return Legacy
end

-- ADAPTER_MODULE_GOES_HERE

assert(Adapter == native, "The adapter did not retain the upstream library")
local window = Adapter:CreateWindow({ Title = "CM1 isolated UI test" })
assert(native.Created, "CreateWindow was not invoked")

local tab = window:AddTab("UI Compatibility")
local group = tab:AddLeftGroupbox("Options")
local left = tab:AddDynamicGroupbox("Left")
local right = tab:AddDynamicGroupbox("Right")
assert(type(left.AddToggle) == "function")
assert(type(right.AddToggle) == "function")
assert(type(tab:AddFullGroupbox("Full").AddInput) == "function")
assert(type(tab:AddFullTabbox():AddTab("Nested").AddDropdown) == "function")
assert(type(tab:AddDynamicTabbox():AddTab("Nested").AddSlider) == "function")

local callbackCount = 0
local item = group:AddToggle("HarnessToggle", {
    Default = false,
    Callback = function()
        callbackCount += 1
    end,
})
env.Toggles.HarnessToggle = item
assert(type(item.SetRawValue) == "function", "New toggles need SetRawValue")
item:SetRawValue(true)
assert(item.Value == true and callbackCount == 0, "Raw setter triggered callback")
item:SetValue(false)
assert(item.Value == false and callbackCount == 1, "Ordinary setter failed")

local slider = group:AddSlider(nil, { Min = 7 })
assert(slider.Value == 7, "Missing slider default not normalized")
local picker = item:AddKeyPicker(nil, { Default = "N/A" })
assert(picker.Default == "None", "Legacy invalid key value wasn't normalized")

local dropdown = group:AddDropdown(nil, {
    Values = { "first", "second" },
    Default = 1,
})
dropdown:SetValue(2)
assert(dropdown.Value == "second", "Dropdown numeric index not adapted")
env.Options.HarnessDropdown = dropdown
assert(type(dropdown.SetRawValue) == "function", "New options need SetRawValue")
dropdown:SetRawValue(1)
assert(dropdown.Value == "first", "Raw dropdown numeric conversion failed")

local dependency = group:AddDependencyBox()
assert(type(dependency.AddToggle) == "function", "Dependency box wasn't adapted")

local ignored = {}
local manager = {
    SetIgnoreIndexes = function(self, indexes)
        ignored = indexes
    end,
}
Adapter:IgnoreTemporaryControls(manager, { "ExistingTemporary" })
assert(table.find(ignored, "ExistingTemporary") ~= nil)
assert(table.find(ignored, slider.Id) ~= nil, "Generated slider ID is not ignored")
assert(table.find(ignored, picker.Id) ~= nil, "Generated key picker ID is not ignored")

Adapter:Notify("Compatibility fallback")
assert(notifications == 1, "Legacy API fallback is missing")

print("PASS: isolated Linoria adapter UI contract")
