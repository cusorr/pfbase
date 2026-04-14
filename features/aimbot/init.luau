local Aimbot = {}

local ReplicationInterface = shared.require("ReplicationInterface")
local CharacterInterface = shared.require("CharacterInterface")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

Aimbot.Init = function()
    local Circle = Aimbot.Drawing("Circle", {
        Visible = true,
        ZIndex = 4,
        Radius = 180,
        Color = Color3.new(1, 1, 1),
    })

    local Outline = Aimbot.Drawing("Circle", {
        Visible = true,
        ZIndex = 3,
        Radius = 180,
        Color = Color3.new(),
        Thickness = 3,
        Transparency = 0.5,
    })

    Aimbot.Render = {Circle, Outline}
end

Aimbot.Drawing = function(Class, Properties)
    local DrawObject = Drawing.new(Class)

    for i,v in Properties do
        DrawObject[i] = v
    end

    return DrawObject
end

Aimbot.GetTarget = function()
    local Target, Max = nil, 180
    local MouseLocation = UserInputService:GetMouseLocation()

    -- Can use getEntry or operateOnAllEntries both function basically the same
    ReplicationInterface.operateOnAllEntries(function(Player, Entry)
        if not CharacterInterface:isAlive() then
            return
        end

        if not Entry:isAlive() or not Entry:isEnemy() then
            return
        end

        local ThirdPersonObject = Entry:getThirdPersonObject()
        -- Haven't found a workaround for this yet will update this once I do
        if not ThirdPersonObject or ThirdPersonObject:getCharacterModel().Parent == nil then
            return
        end

        local CharacterHash = ThirdPersonObject:getCharacterHash()
        for _, BodyPart in CharacterHash do
            local ScreenVector, OnScreen = Camera:WorldToViewportPoint(BodyPart.Position)
            local ScreenPosition = Vector2.new(ScreenVector.X, ScreenVector.Y)
            local Magnitude = (MouseLocation - ScreenPosition).Magnitude
            
            if OnScreen and Magnitude < Max then
                Max = Magnitude
                Target = ScreenPosition
            end
        end
    end)

    return Target
end

Aimbot.Update = function()
    local KeybindDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    local Target = KeybindDown and Aimbot.GetTarget()
    local MouseLocation = UserInputService:GetMouseLocation()

    local Circle, Outline = Aimbot.Render[1], Aimbot.Render[2]
    Circle.Position = MouseLocation
    Outline.Position = Circle.Position

    if Target then
        local Delta = (Target - UserInputService:GetMouseLocation()) * 0.5
        mousemoverel(Delta.X, Delta.Y)
    end
end

Aimbot.Cleanup = function()
    for _, DrawObject in Aimbot.Render do
        DrawObject:Remove()
    end
end

return Aimbot
