local RecoveryScope = {}
RecoveryScope.__index = RecoveryScope

local function release(resource)
    local kind = typeof(resource)
    if kind == "RBXScriptConnection" then
        resource:Disconnect()
    elseif kind == "thread" then
        if coroutine.status(resource) == "suspended" then
            task.cancel(resource)
        end
    elseif kind == "Instance" then
        resource:Destroy()
    elseif type(resource) == "function" then
        resource()
    elseif type(resource) == "table" then
        if type(resource.Disconnect) == "function" then
            resource:Disconnect()
        elseif type(resource.Destroy) == "function" then
            resource:Destroy()
        elseif type(resource.stop) == "function" then
            resource:stop()
        elseif type(resource.close) == "function" then
            resource:close()
        else
            error("RecoveryScope: unsupported table resource")
        end
    else
        error("RecoveryScope: unsupported resource type " .. kind)
    end
end

function RecoveryScope.new(onError)
    assert(onError == nil or type(onError) == "function", "onError must be a function")
    return setmetatable({
        _closed = false,
        _nextId = 0,
        _resources = {},
        _onError = onError,
    }, RecoveryScope)
end

function RecoveryScope:isClosed()
    return self._closed
end

function RecoveryScope:track(resource)
    if resource == nil then
        error("RecoveryScope: cannot track nil", 2)
    end
    if self._closed then
        local ok, err = pcall(release, resource)
        if not ok and self._onError then
            pcall(self._onError, err)
        end
        return resource
    end
    self._nextId += 1
    self._resources[self._nextId] = resource
    return resource
end

function RecoveryScope:forget(resource)
    for id, candidate in pairs(self._resources) do
        if candidate == resource then
            self._resources[id] = nil
            return true
        end
    end
    return false
end

function RecoveryScope:spawn(callback, ...)
    assert(type(callback) == "function", "callback must be a function")
    if self._closed then return nil end
    local args = table.pack(...)
    local finished = false
    local handle
    handle = task.spawn(function()
        if not self._closed then
            local ok, err = xpcall(function()
                callback(table.unpack(args, 1, args.n))
            end, debug.traceback)
            if not ok and self._onError then
                pcall(self._onError, err)
            end
        end
        finished = true
        if handle then self:forget(handle) end
    end)
    if not finished then self:track(handle) end
    return handle
end

function RecoveryScope:every(seconds, callback)
    assert(type(seconds) == "number" and seconds >= 0.05,
        "interval must be a number >= 0.05")
    assert(type(callback) == "function", "callback must be a function")
    if self._closed then return nil end
    local finished = false
    local handle
    handle = task.spawn(function()
        while not self._closed do
            task.wait(seconds)
            if self._closed then break end
            local ok, err = xpcall(callback, debug.traceback)
            if not ok then
                if self._onError then pcall(self._onError, err) end
                break
            end
        end
        finished = true
        if handle then self:forget(handle) end
    end)
    if not finished then self:track(handle) end
    return handle
end

function RecoveryScope:count()
    local count = 0
    for _ in pairs(self._resources) do
        count += 1
    end
    return count
end

function RecoveryScope:close()
    if self._closed then
        return true, {}
    end

    self._closed = true
    local resources = self._resources
    self._resources = {}
    local errors = {}

    for _, kind in ipairs({ "RBXScriptConnection", "thread", "other" }) do
        for _, resource in pairs(resources) do
            local resourceKind = typeof(resource)
            if resourceKind == kind
                or (kind == "other" and resourceKind ~= "RBXScriptConnection" and resourceKind ~= "thread") then
                local ok, err = pcall(release, resource)
                if not ok then
                    errors[#errors + 1] = tostring(err)
                    if self._onError then
                        pcall(self._onError, err)
                    end
                end
            end
        end
    end

    return #errors == 0, errors
end

return RecoveryScope
