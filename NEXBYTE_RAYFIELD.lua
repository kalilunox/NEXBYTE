-- NEXBYTE ADMIN - RAYFIELD GEN2
-- First interface build

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Window = Rayfield:CreateWindow({
    name = "NEXBYTE ADMIN",
    subtitle = "Universal Client Toolkit • v1.0",
    sidebarLayout = true,
    theme = "Default"
})

local function GetHumanoid()
    local Character = Player.Character
    if not Character then return nil end
    return Character:FindFirstChildOfClass("Humanoid")
end

local Home = Window:CreateTab({
    name = "HOME",
    icon = "house"
})

local PlayerTab = Window:CreateTab({
    name = "PLAYER",
    icon = "user"
})

local CameraTab = Window:CreateTab({
    name = "CAMERA",
    icon = "camera"
})

local VisualTab = Window:CreateTab({
    name = "VISUALS",
    icon = "eye"
})

local Settings = Window:CreateTab({
    name = "SETTINGS",
    icon = "settings"
})

-- HOME
Home:CreateText({
    name = "NEXBYTE ADMIN",
    text = "Rayfield interface initialized.\nClient: " .. Player.Name
})

Home:CreateButton({
    name = "Show status",
    callback = function()
        Window:Notify({
            title = "NEXBYTE",
            content = "Interface is running.",
            duration = 4
        })
    end
})

-- PLAYER
PlayerTab:CreateSection({
    name = "Movement"
})

PlayerTab:CreateSlider({
    name = "WalkSpeed",
    range = {16, 40},
    increment = 1,
    value = 16,
    suffix = " studs",
    callback = function(Value)
        local Humanoid = GetHumanoid()
        if Humanoid then
            Humanoid.WalkSpeed = Value
        end
    end
})

PlayerTab:CreateSlider({
    name = "JumpPower",
    range = {25, 100},
    increment = 5,
    value = 50,
    callback = function(Value)
        local Humanoid = GetHumanoid()
        if Humanoid then
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = Value
        end
    end
})

PlayerTab:CreateButton({
    name = "Reset movement",
    callback = function()
        local Humanoid = GetHumanoid()
        if Humanoid then
            Humanoid.WalkSpeed = 16
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = 50
        end
    end
})

-- CAMERA
CameraTab:CreateSection({
    name = "Camera controls"
})

CameraTab:CreateSlider({
    name = "Field of View",
    range = {50, 120},
    increment = 1,
    value = 70,
    callback = function(Value)
        local Camera = workspace.CurrentCamera
        if Camera then
            Camera.FieldOfView = Value
        end
    end
})

CameraTab:CreateSlider({
    name = "Maximum zoom",
    range = {10, 100},
    increment = 5,
    value = 20,
    callback = function(Value)
        Player.CameraMaxZoomDistance = Value
    end
})

CameraTab:CreateButton({
    name = "Reset camera",
    callback = function()
        local Camera = workspace.CurrentCamera
        if Camera then
            Camera.FieldOfView = 70
        end
        Player.CameraMaxZoomDistance = 128
        Player.CameraMinZoomDistance = 0.5
    end
})

-- VISUALS
VisualTab:CreateSection({
    name = "Local environment"
})

VisualTab:CreateSlider({
    name = "Brightness",
    range = {0, 5},
    increment = 0.25,
    value = Lighting.Brightness,
    callback = function(Value)
        Lighting.Brightness = Value
    end
})

VisualTab:CreateButton({
    name = "Reset brightness",
    callback = function()
        Lighting.Brightness = 2
    end
})

-- SETTINGS
Settings:CreateText({
    name = "Information",
    text = "NEXBYTE ADMIN\nRayfield Gen2 Stable\nBuild 1.0"
})

Settings:CreateButton({
    name = "Unload interface",
    callback = function()
        Window:Unload()
    end
})

Window:Notify({
    title = "NEXBYTE ADMIN",
    content = "Rayfield interface loaded successfully.",
    duration = 5
})
