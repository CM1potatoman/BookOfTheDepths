local MemorySampler = {}
MemorySampler.__index = MemorySampler

function MemorySampler.new()
    return setmetatable({
        _stats = game:GetService("Stats"),
        _startTime = os.clock(),
        _first = nil,
        _peak = nil,
        _samples = 0,
    }, MemorySampler)
end

function MemorySampler:sample()
    local ok, total = pcall(self._stats.GetTotalMemoryUsageMb, self._stats)
    if not ok or type(total) ~= "number" then
        return nil, "Stats.GetTotalMemoryUsageMb is unavailable"
    end

    local luaMb = nil
    if type(gcinfo) == "function" then
        local gcOk, kb = pcall(gcinfo)
        if gcOk and type(kb) == "number" then
            luaMb = kb / 1024
        end
    end

    self._first = self._first or total
    self._peak = math.max(self._peak or total, total)
    self._samples += 1

    return {
        elapsedSec = os.clock() - self._startTime,
        totalClientMb = total,
        luaHeapMb = luaMb,
        baselineClientMb = self._first,
        peakClientMb = self._peak,
        deltaClientMb = total - self._first,
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
