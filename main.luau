local Modules = {}

shared.require = getrenv().shared.require
-- In this case you won't need this but useful for grabbing functions from other modules
shared.fetch = function(Name)
    local Data = Modules[Name]
    if Data then
        return Data
    end

    warn(`Failed to fetch module "{Name}"`)
end

-- These don't have to be folders you can edit them so they're files instead
for _, Path in listfiles("pfbase/features") do
    local Name = Path:match("[^\\]+$")
    local Ok, Data = pcall(loadfile(Path.."/init.luau"))

    if not Ok then
        warn(`Failed to load module {Name}: {Data}`)
        continue
    end

    Modules[Name] = Data
end

local ModuleUpdates = {}
for Name, Data in Modules do
    ModuleUpdates[Name] = Data.Update

    if not Data.Init then
        continue
    end

    local Ok, Err = pcall(Data.Init)
    if not Ok then
        warn(`Failed to init module "{Name}": {Err}`)
    end
end

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Connection
Connection = RunService.RenderStepped:Connect(function(DeltaTime)
    -- Unload
    if UserInputService:IsKeyDown(Enum.KeyCode.End) then
        Connection:Disconnect()

        for _, Module in Modules do
            if Module.Cleanup then
                Module.Cleanup()
            end
        end

        return
    end

    for Name, Update in ModuleUpdates do
        local Ok, Err = pcall(Update, DeltaTime)
        if not Ok then
            warn(`Update error: {Name}, {Err}`)
        end
    end
end)