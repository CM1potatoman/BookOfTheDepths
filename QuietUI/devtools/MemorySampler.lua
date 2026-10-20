local MemorySampler = {}
MemorySampler.__index = MemorySampler

function MemorySampler.new(label)
    local self = setmetatable({
        _stats = game:GetService("Stats"),
        _runId = 0,
    }, MemorySampler)
    return self:reset(label)
end

function MemorySampler:reset(label)
    self._runId += 1
    self._runLabel = label or "run-" .. tostring(self._runId)
    self._startTime = os.clock()
    self._first = nil
    self._firstLua = nil
    self._peak = nil
    self._peakLua = nil
    self._samples = 0
    return self
end

function MemorySampler:sample()
    local ok, total = pcall(self._stats.GetTotalMemoryUsageMb, self._stats)
    if not ok or type(total) ~= "number" or total ~= total or total < 0 or total == math.huge then
        return nil, "Stats.GetTotalMemoryUsageMb is unavailable or invalid"
    end

    local luaMb = nil
    if type(gcinfo) == "function" then
        local gcOk, kb = pcall(gcinfo)
        if gcOk and type(kb) == "number" and kb == kb and kb >= 0 and kb ~= math.huge then
            luaMb = kb / 1024
        end
    end

    if self._first == nil then
        self._first = total
    end
    self._peak = math.max(self._peak or total, total)
    if luaMb ~= nil then
        if self._firstLua == nil then
            self._firstLua = luaMb
        end
        self._peakLua = math.max(self._peakLua or luaMb, luaMb)
    end
    self._samples += 1

    return {
        runId = self._runId,
        runLabel = self._runLabel,
        elapsedSec = os.clock() - self._startTime,
        totalClientMb = total,
        luaHeapMb = luaMb,
        baselineClientMb = self._first,
        baselineLuaHeapMb = self._firstLua,
        peakClientMb = self._peak,
        peakLuaHeapMb = self._peakLua,
        deltaClientMb = total - self._first,
        deltaLuaHeapMb = luaMb and self._firstLua and (luaMb - self._firstLua) or nil,
        sampleCount = self._samples,
    }
end

function MemorySampler:watch(scope, interval, onSample)
    assert(type(scope) == "table" and type(scope.every) == "function",
        "watch requires a RecoveryScope instance")
    assert(type(onSample) == "function", "onSample must be a function")
    return scope:every(interval or 2, function()
        local result, err = self:sample()
        onSample(result, err)
    end)
end

return MemorySampler
