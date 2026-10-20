local pending, cancelled = {}, {}
task = {
    spawn = function(callback)
        local thread = coroutine.create(callback)
        pending[#pending + 1] = thread
        return thread
    end,
    wait = function() coroutine.yield() end,
    cancel = function(thread)
        assert(coroutine.status(thread) == "suspended")
        cancelled[thread] = true
    end,
}
local function tick()
    local tasks = pending
    pending = {}
    for _, thread in ipairs(tasks) do
        if not cancelled[thread] and coroutine.status(thread) == "suspended" then
            local ok, err = coroutine.resume(thread)
            assert(ok, tostring(err))
        end
        if not cancelled[thread] and coroutine.status(thread) == "suspended" then
            pending[#pending + 1] = thread
        end
    end
end
-- RECOVERY_SCOPE_MODULE_GOES_HERE
local errors = {}
local scope = RecoveryScope.new(function(err) errors[#errors + 1] = tostring(err) end)
local count = 0
scope:spawn(function() count += 1 end)
assert(scope:count() == 1)
tick()
assert(count == 1 and scope:count() == 0, "completed worker retained")
scope:spawn(function() error("expected worker failure") end)
tick()
assert(#errors == 1 and scope:count() == 0, "failed worker retained")
local intervalCalls = 0
scope:every(0.05, function()
    intervalCalls += 1
    if intervalCalls == 2 then error("expected interval failure") end
end)
tick()
tick()
assert(intervalCalls == 1 and scope:count() == 1)
tick()
tick()
assert(intervalCalls == 2 and scope:count() == 0)
assert(#errors == 2)
local cancelledScope = RecoveryScope.new()
local ran = false
cancelledScope:spawn(function() ran = true end)
local repeating = cancelledScope:every(0.05, function() ran = true end)
assert(cancelledScope:close())
assert(cancelled[repeating] and cancelledScope:count() == 0)
tick()
assert(not ran and cancelledScope:close(), "closed scope still runs")
local released = 0
local broken = RecoveryScope.new()
broken:track(function() released += 1 end)
broken:track(function() error("expected cleanup failure") end)
local ok, failures = broken:close()
assert(not ok and #failures == 1 and released == 1)
for i = 1, 50 do
    local iteration = RecoveryScope.new()
    iteration:spawn(function() end)
    tick()
    assert(iteration:count() == 0 and iteration:close(), "cycle failed " .. i)
end
print("PASS: RecoveryScope task ownership and reload lifecycle")
