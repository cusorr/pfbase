local ESP = {}

local ReplicationInterface = shared.require("ReplicationInterface")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

ESP.Init = function()
    ESP.Connection = Players.PlayerRemoving:Connect(ESP.RemoveCache)
    ESP.DrawCache = {}
end

ESP.Drawing = function(Class, Properties)
    local DrawObject = Drawing.new(Class)

    for i,v in Properties do
        DrawObject[i] = v
    end

    return DrawObject
end

ESP.CreateCache = function(Player)
    ESP.DrawCache[Player] = {
        Box = ESP.Drawing("Square", {ZIndex = 2, Visible = false, Color = Color3.new(1, 1, 1)}),
        Outline = ESP.Drawing("Square", {ZIndex = 1, Visible = false, Thickness = 3, Transparency = 0.5, Color = Color3.new()}),
    }

    return ESP.DrawCache[Player]
end

ESP.HideCache = function(Player)
    local Cache = ESP.DrawCache[Player]
    if not Cache then
        return
    end

    for _, DrawObject in Cache do
        DrawObject.Visible = false
    end
end

ESP.RemoveCache = function(Player)
    local Cache = ESP.DrawCache[Player]
    if not Cache then
        return
    end

    for _, DrawObject in Cache do
        DrawObject:Remove()
    end
end

local CornerOffsets = {
    Vector3.new(-1, -1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, 1, 1),
    Vector3.new(1, -1, -1), Vector3.new(1, -1, 1), Vector3.new(1, 1, -1), Vector3.new(1, 1, 1),
}

ESP.CalculateBox = function(ThirdPersonObject)
    local MinX, MinY = math.huge, math.huge
    local MaxX, MaxY = -math.huge, -math.huge

    for Part, Size in ThirdPersonObject._partSizes do
        local HalfSize = Size / 2
        local CF = Part.CFrame

        for _, Offset in CornerOffsets do
            local ScreenVector, Visible = Camera:WorldToViewportPoint((CF * CFrame.new(Offset.X * HalfSize.X, Offset.Y * HalfSize.Y, Offset.Z * HalfSize.Z)).Position)
            if Visible then
                MinX = math.min(MinX, ScreenVector.X)
                MinY = math.min(MinY, ScreenVector.Y)
                MaxX = math.max(MaxX, ScreenVector.X)
                MaxY = math.max(MaxY, ScreenVector.Y)
            end
        end
    end

    if MinX == math.huge then
        return
    end

    return {
        Position = Vector2.new(MinX, MinY),
        Size = Vector2.new(MaxX - MinX, MaxY - MinY),
    }
end

ESP.Update = function()
    ReplicationInterface.operateOnAllEntries(function(Player, Entry)
        if not Entry:isAlive() or not Entry:isEnemy() then
            return ESP.HideCache(Player)
        end

        local ThirdPersonObject = Entry:getThirdPersonObject()
        if not ThirdPersonObject or ThirdPersonObject:getCharacterModel().Parent == nil then
            return ESP.HideCache(Player)
        end

        local Bounds = ESP.CalculateBox(ThirdPersonObject)
        if not Bounds then
            return ESP.HideCache(Player)
        end

        local Cache = ESP.DrawCache[Player] or ESP.CreateCache(Player)
        local Box, Outline = Cache.Box, Cache.Outline do
            Box.Visible = true
            Box.Size = Bounds.Size
            Box.Position = Bounds.Position

            Outline.Visible = Box.Visible
            Outline.Size = Box.Size
            Outline.Position = Box.Position
        end
    end)
end

ESP.Cleanup = function()
    ESP.Connection:Disconnect()

    for _, Player in Players:GetPlayers() do
        ESP.RemoveCache(Player)
    end

    table.clear(ESP.DrawCache)
end

return ESP
