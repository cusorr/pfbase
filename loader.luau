if game.GameId ~= 113491250 then
    return
end

local Executor = string.lower(identifyexecutor and identifyexecutor() or "")
local Supported = {
    wave = {run_on_actor, getdeletedactors},
    potassium = {run_on_thread, getactorthreads},
    volt = {run_on_actor, getactors}
}

if not Supported[Executor] then
    return warn("Unsupported executor")
end

local Runner, GetAll = table.unpack(Supported[Executor])
local ThreadSource = [=[
    if getrenv().shared.require then
        loadfile("pfbase/main.luau")()
    end
]=]

local Actors = GetAll()
if not Actors or #Actors == 0 then
    return warn("No actors/threads found...")
end

for _, Actor in Actors do
    Runner(Actor, ThreadSource)
end