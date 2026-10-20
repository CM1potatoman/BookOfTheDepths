local clientMb = 100
local luaKb = 10240
local unavailable = false
game = {
    GetService = function(_, name)
        assert(name == "Stats")
        return {
            GetTotalMemoryUsageMb = function()
                if unavailable then error("stats unavailable") end
                return clientMb
            end,
        }
    end,
}
gcinfo = function()
    return luaKb
end
-- MEMORY_SAMPLER_MODULE_GOES_HERE
local sampler = MemorySampler.new("baseline")
local first, firstErr = sampler:sample()
assert(first and not firstErr)
assert(first.runLabel == "baseline" and first.runId == 1 and first.sampleCount == 1)
assert(first.baselineClientMb == 100 and first.deltaClientMb == 0)
assert(first.baselineLuaHeapMb == 10 and first.deltaLuaHeapMb == 0)
clientMb = 115
luaKb = 12288
local second = sampler:sample()
assert(second.deltaClientMb == 15 and second.deltaLuaHeapMb == 2)
assert(second.peakClientMb == 115 and second.peakLuaHeapMb == 12)
assert(second.sampleCount == 2)
clientMb = 106
luaKb = 11264
local third = sampler:sample()
assert(third.deltaClientMb == 6 and third.deltaLuaHeapMb == 1)
assert(third.peakClientMb == 115 and third.peakLuaHeapMb == 12)
sampler:reset("repeat")
local fourth = sampler:sample()
assert(fourth.runId == 2 and fourth.runLabel == "repeat")
assert(fourth.sampleCount == 1 and fourth.deltaClientMb == 0 and fourth.deltaLuaHeapMb == 0)
local subscribed = nil
local scope = {
    every = function(_, seconds, callback)
        assert(seconds == 3)
        subscribed = callback
        return "watcher"
    end,
}
local received
assert(sampler:watch(scope, 3, function(result, err)
    assert(not err)
    received = result
end) == "watcher")
clientMb = 111
subscribed()
assert(received.deltaClientMb == 5)
unavailable = true
local bad, err = sampler:sample()
assert(bad == nil and type(err) == "string")
assert(sampler._samples == 2, "failed measurement changed sample count")
unavailable = false
luaKb = -1
local fallback = sampler:sample()
assert(fallback.luaHeapMb == nil and fallback.deltaLuaHeapMb == nil)
assert(fallback.deltaClientMb == 5)
print("PASS: MemorySampler repeated baseline and invalid-sample handling")
