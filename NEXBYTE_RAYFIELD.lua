-- NEXBYTE OLD GUI CLEANUP
local _nxPlayer = game:GetService("Players").LocalPlayer
local _nxParents = {}

pcall(function()
    table.insert(_nxParents, _nxPlayer:WaitForChild("PlayerGui"))
end)

pcall(function()
    table.insert(_nxParents, game:GetService("CoreGui"))
end)

for _, _nxParent in ipairs(_nxParents) do
    for _, _nxGui in ipairs(_nxParent:GetDescendants()) do
        if _nxGui:IsA("ScreenGui") then
            local _nxName = string.lower(_nxGui.Name)
            if string.find(_nxName, "nexbyte", 1, true)
            or _nxName == "rayfield"
            or _nxName == "rayfieldgen2" then
                pcall(function()
                    _nxGui:Destroy()
                end)
            end
        end
    end

    for _, _nxGui in ipairs(_nxParent:GetChildren()) do
        if _nxGui:IsA("ScreenGui") then
            local _nxName = string.lower(_nxGui.Name)
            if string.find(_nxName, "nexbyte", 1, true)
            or _nxName == "rayfield"
            or _nxName == "rayfieldgen2" then
                pcall(function()
                    _nxGui:Destroy()
                end)
            end
        end
    end
end


-- NEXBYTE OLD GUI CLEANUP
local _nxPlayer = game:GetService("Players").LocalPlayer
local _nxParents = {}

pcall(function()
    table.insert(_nxParents, _nxPlayer:WaitForChild("PlayerGui"))
end)

pcall(function()
    table.insert(_nxParents, game:GetService("CoreGui"))
end)

local _nxOldNames = {
    NEXBYTEFlingGUI = true,
    NEXBYTE_ADMIN = true,
    TPList = true,
    NEXBYTE_TROLL = true
}

for _, _nxParent in ipairs(_nxParents) do
    for _, _nxGui in ipairs(_nxParent:GetChildren()) do
        if _nxOldNames[_nxGui.Name] then
            pcall(function()
                _nxGui:Destroy()
            end)
        end
    end
end

-- NEXBYTE ADMIN | RAYFIELD GEN2
-- Player controls build 1.1

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Window = Rayfield:CreateWindow({
    name = "NEXBYTE ADMIN",
    subtitle = "Universal Client Toolkit • v1.1",
    sidebarLayout = true,
    theme = "Default"
})

local function Notify(title, content)
    Window:Notify({
        title = title,
        content = content,
        duration = 4
    })
end

local function GetCharacter(player)
    player = player or LocalPlayer
    return player.Character
end

local function GetHumanoid(player)
    local character = GetCharacter(player)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function GetRoot(player)
    local character = GetCharacter(player)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function GetPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    table.sort(names)
    return names
end

local selectedPlayerName = nil
local spectating = false
local originalCameraSubject = nil
local playerDropdown

local function FindSelectedPlayer()
    if not selectedPlayerName then return nil end
    return Players:FindFirstChild(selectedPlayerName)
end

local function RefreshPlayers()
    local names = GetPlayerNames()

    if playerDropdown then
        playerDropdown:Refresh(names)
    end

    if selectedPlayerName and not table.find(names, selectedPlayerName) then
        selectedPlayerName = nil
    end

    Notify("PLAYER LIST", "Players found: " .. #names)
end

local function StopSpectating()
    spectating = false

    local humanoid = GetHumanoid(LocalPlayer)
    if Camera and humanoid then
        Camera.CameraSubject = humanoid
    elseif Camera and originalCameraSubject then
        Camera.CameraSubject = originalCameraSubject
    end

    originalCameraSubject = nil
    Notify("SPECTATE", "Returned to your character")
end

local function StartSpectating()
    local target = FindSelectedPlayer()
    local humanoid = target and GetHumanoid(target)

    if not humanoid then
        Notify("SPECTATE", "Selected player is unavailable")
        return
    end

    Camera = workspace.CurrentCamera
    originalCameraSubject = Camera.CameraSubject
    Camera.CameraSubject = humanoid
    spectating = true

    Notify("SPECTATE", "Watching " .. target.Name)
end

-- TABS
local Home = Window:CreateTab({
    name = "HOME",
    icon = "house"
})

local PlayerTab = Window:CreateTab({
    name = "PLAYER",
    icon = "users"
})

local Movement = Window:CreateTab({
    name = "MOVEMENT",
    icon = "move"
})

local CameraTab = Window:CreateTab({
    name = "CAMERA",
    icon = "camera"
})

local Visuals = Window:CreateTab({
    name = "VISUALS",
    icon = "eye"
})

local Settings = Window:CreateTab({
    name = "SETTINGS",
    icon = "settings"
})

-- HOME
Home:CreateSection({name = "NEXBYTE ADMIN"})

Home:CreateText({
    name = "Status",
    text = "Rayfield Gen2 loaded\nUser: " .. LocalPlayer.Name
})

Home:CreateButton({
    name = "Show status",
    callback = function()
        Notify("NEXBYTE", "Interface is running")
    end
})

-- PLAYER
PlayerTab:CreateSection({name = "TARGET CONTROL"})

PlayerTab:CreateButton({
    name = "REFRESH PLAYER LIST",
    callback = RefreshPlayers
})

PlayerTab:CreateButton({
    name = "TP TO SELECTED",
    callback = function()
        local target = FindSelectedPlayer()
        local targetRoot = target and GetRoot(target)
        local myRoot = GetRoot(LocalPlayer)

        if not targetRoot or not myRoot then
            Notify("TP TO", "Select an available player first")
            return
        end

        local character = GetCharacter(LocalPlayer)
        if character then
            character:PivotTo(targetRoot.CFrame * CFrame.new(0, 0, 3))
            Notify("TP TO", "Moved near " .. target.Name)
        end
    end
})

PlayerTab:CreateButton({
    name = "SPECTATE SELECTED",
    callback = StartSpectating
})

PlayerTab:CreateButton({
    name = "STOP SPECTATING",
    callback = StopSpectating
})

PlayerTab:CreateSection({name = "PLAYER SELECTION"})

local function SafePlayerOptions()
    local names = GetPlayerNames()
    if #names == 0 then
        return {"No other players"}
    end
    return names
end

local dropdownOK, dropdownError = pcall(function()
    playerDropdown = PlayerTab:CreateDropdown({
        name = "SELECT PLAYER",
        options = SafePlayerOptions(),
        value = SafePlayerOptions()[1],
        placeholder = "Choose a player",
        callback = function(value)
            if type(value) == "table" then
                value = value[1]
            end

            if value == "No other players" then
                selectedPlayerName = nil
                return
            end

            selectedPlayerName = value
            Notify("TARGET", "Selected: " .. tostring(value))
        end
    })
end)

if not dropdownOK then
    PlayerTab:CreateText({
        name = "Dropdown error",
        text = tostring(dropdownError)
    })
end

local function UpdatePlayerDropdown()
    if not playerDropdown then return end
    local options = SafePlayerOptions()
    pcall(function()
        playerDropdown:Refresh(options)
    end)
end

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    UpdatePlayerDropdown()
end)

Players.PlayerRemoving:Connect(function(player)
    if player.Name == selectedPlayerName then
        selectedPlayerName = nil
        if spectating then
            StopSpectating()
        end
    end

    task.wait(0.2)
    UpdatePlayerDropdown()
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    if spectating then
        task.wait(0.5)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and workspace.CurrentCamera then
            workspace.CurrentCamera.CameraSubject = humanoid
        end
        spectating = false
        originalCameraSubject = nil
    end
end)

-- MOVEMENT
Movement:CreateSection({name = "Character"})

Movement:CreateSlider({
    name = "WalkSpeed",
    range = {16, 40},
    increment = 1,
    value = 16,
    suffix = " studs",
    callback = function(value)
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end
})

Movement:CreateSlider({
    name = "JumpPower",
    range = {25, 100},
    increment = 5,
    value = 50,
    callback = function(value)
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = value
        end
    end
})

Movement:CreateButton({
    name = "Reset movement",
    callback = function()
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.UseJumpPower = true
            humanoid.JumpPower = 50
        end
    end
})

-- CAMERA
CameraTab:CreateSection({name = "Camera controls"})

CameraTab:CreateSlider({
    name = "Field of View",
    range = {50, 120},
    increment = 1,
    value = 70,
    callback = function(value)
        Camera = workspace.CurrentCamera
        if Camera then
            Camera.FieldOfView = value
        end
    end
})

CameraTab:CreateSlider({
    name = "Maximum zoom",
    range = {10, 100},
    increment = 5,
    value = 20,
    callback = function(value)
        LocalPlayer.CameraMaxZoomDistance = value
    end
})

CameraTab:CreateButton({
    name = "Reset camera",
    callback = function()
        Camera = workspace.CurrentCamera
        if Camera then
            Camera.FieldOfView = 70
        end
        LocalPlayer.CameraMaxZoomDistance = 128
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
})

-- VISUALS
Visuals:CreateSection({name = "Local environment"})

Visuals:CreateSlider({
    name = "Brightness",
    range = {0, 5},
    increment = 0.25,
    value = Lighting.Brightness,
    callback = function(value)
        Lighting.Brightness = value
    end
})

Visuals:CreateButton({
    name = "Reset brightness",
    callback = function()
        Lighting.Brightness = 2
    end
})

-- SETTINGS
Settings:CreateSection({name = "Interface"})

Settings:CreateText({
    name = "Build information",
    text = "NEXBYTE ADMIN\nRayfield Gen2\nBuild 1.1"
})

Settings:CreateButton({
    name = "Unload interface",
    callback = function()
        if spectating then
            StopSpectating()
        end
        Window:Unload()
    end
})

Notify("NEXBYTE ADMIN", "Build 1.1 loaded")
