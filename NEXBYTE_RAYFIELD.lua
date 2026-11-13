-- NEXBYTE STARTUP CLEANUP
local _nxPlayer = game:GetService("Players").LocalPlayer
if _nxPlayer then
    local _nxParents = {_nxPlayer:WaitForChild("PlayerGui")}
    pcall(function()
        table.insert(_nxParents, game:GetService("CoreGui"))
    end)
    for _, _nxParent in ipairs(_nxParents) do
        for _, _nxGui in ipairs(_nxParent:GetChildren()) do
            if _nxGui.Name == "NEXBYTE_ADMIN" or _nxGui.Name == "TPList" then
                _nxGui:Destroy()
            end
        end
    end
end

--[[
    NEXBYTE ADMIN
    Based on the working fling mechanism from zqyDSUWX
    Features:
    - Select multiple targets
    - Continuous flinging until stopped
    - Preserves player mobility (no teleporting to targets)
    - Flings targets very far
    - Compatible with JJSploit, Synapse X, etc.
]]
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NEXBYTEFlingGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")
-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "NEXBYTE ADMIN"
Title.TextColor3 = Color3.fromRGB(255, 80, 80)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = TitleBar
-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 18
CloseButton.Parent = TitleBar
-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Position = UDim2.new(0, 10, 0, 40)
StatusLabel.Size = UDim2.new(1, -20, 0, 25)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Select targets to fling"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.SourceSans
StatusLabel.TextSize = 16
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame
-- Player Selection Frame
local SelectionFrame = Instance.new("Frame")
SelectionFrame.Position = UDim2.new(0, 10, 0, 70)
SelectionFrame.Size = UDim2.new(1, -20, 0, 200)
SelectionFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SelectionFrame.BorderSizePixel = 0
SelectionFrame.Parent = MainFrame
-- Player List ScrollFrame
local PlayerScrollFrame = Instance.new("ScrollingFrame")
PlayerScrollFrame.Position = UDim2.new(0, 5, 0, 5)
PlayerScrollFrame.Size = UDim2.new(1, -10, 1, -10)
PlayerScrollFrame.BackgroundTransparency = 1
PlayerScrollFrame.BorderSizePixel = 0
PlayerScrollFrame.ScrollBarThickness = 6
PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerScrollFrame.Parent = SelectionFrame
-- Start Fling Button
local StartButton = Instance.new("TextButton")
StartButton.Position = UDim2.new(0, 10, 0, 280)
StartButton.Size = UDim2.new(0.5, -15, 0, 40)
StartButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
StartButton.BorderSizePixel = 0
StartButton.Text = "START FLING"
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StartButton.Font = Enum.Font.SourceSansBold
StartButton.TextSize = 18
StartButton.Parent = MainFrame
-- Stop Fling Button
local StopButton = Instance.new("TextButton")
StopButton.Position = UDim2.new(0.5, 5, 0, 280)
StopButton.Size = UDim2.new(0.5, -15, 0, 40)
StopButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
StopButton.BorderSizePixel = 0
StopButton.Text = "STOP FLING"
StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StopButton.Font = Enum.Font.SourceSansBold
StopButton.TextSize = 18
StopButton.Parent = MainFrame
-- Select/Deselect Buttons
local SelectAllButton = Instance.new("TextButton")
SelectAllButton.Position = UDim2.new(0, 10, 0, 330)
SelectAllButton.Size = UDim2.new(0.5, -15, 0, 30)
SelectAllButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SelectAllButton.BorderSizePixel = 0
SelectAllButton.Text = "SELECT ALL"
SelectAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectAllButton.Font = Enum.Font.SourceSans
SelectAllButton.TextSize = 14
SelectAllButton.Parent = MainFrame
local DeselectAllButton = Instance.new("TextButton")
DeselectAllButton.Position = UDim2.new(0.5, 5, 0, 330)
DeselectAllButton.Size = UDim2.new(0.5, -15, 0, 30)
DeselectAllButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
DeselectAllButton.BorderSizePixel = 0
DeselectAllButton.Text = "DESELECT ALL"
DeselectAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DeselectAllButton.Font = Enum.Font.SourceSans
DeselectAllButton.TextSize = 14
DeselectAllButton.Parent = MainFrame
-- Variables
local SelectedTargets = {}
local PlayerCheckboxes = {}
local FlingActive = false
local FlingConnection = nil
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight
-- Function to update player list
local function RefreshPlayerList()
    -- Clear existing player entries
    for _, child in pairs(PlayerScrollFrame:GetChildren()) do
        child:Destroy()
    end
    PlayerCheckboxes = {}
    
    -- Get players and sort them
    local PlayerList = Players:GetPlayers()
    table.sort(PlayerList, function(a, b) return a.Name:lower() < b.Name:lower() end)
    
    -- Create entries for each player
    local yPosition = 5
    for _, player in ipairs(PlayerList) do
        if player ~= Player then -- Don't include yourself
            -- Create player entry frame
            local PlayerEntry = Instance.new("Frame")
            PlayerEntry.Size = UDim2.new(1, -10, 0, 30)
            PlayerEntry.Position = UDim2.new(0, 5, 0, yPosition)
            PlayerEntry.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            PlayerEntry.BorderSizePixel = 0
            PlayerEntry.Parent = PlayerScrollFrame
            
            -- Create checkbox
            local Checkbox = Instance.new("TextButton")
            Checkbox.Size = UDim2.new(0, 24, 0, 24)
            Checkbox.Position = UDim2.new(0, 3, 0.5, -12)
            Checkbox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            Checkbox.BorderSizePixel = 0
            Checkbox.Text = ""
            Checkbox.Parent = PlayerEntry
            
            -- Checkmark (initially invisible)
            local Checkmark = Instance.new("TextLabel")
            Checkmark.Size = UDim2.new(1, 0, 1, 0)
            Checkmark.BackgroundTransparency = 1
            Checkmark.Text = "✓"
            Checkmark.TextColor3 = Color3.fromRGB(0, 255, 0)
            Checkmark.TextSize = 18
            Checkmark.Font = Enum.Font.SourceSansBold
            Checkmark.Visible = SelectedTargets[player.Name] ~= nil
            Checkmark.Parent = Checkbox
            
            -- Player name label
            local NameLabel = Instance.new("TextLabel")
            NameLabel.Size = UDim2.new(1, -35, 1, 0)
            NameLabel.Position = UDim2.new(0, 30, 0, 0)
            NameLabel.BackgroundTransparency = 1
            NameLabel.Text = player.Name
            NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            NameLabel.TextSize = 16
            NameLabel.Font = Enum.Font.SourceSans
            NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            NameLabel.Parent = PlayerEntry
            
            -- Make entire entry clickable
            local ClickArea = Instance.new("TextButton")
            ClickArea.Size = UDim2.new(1, 0, 1, 0)
            ClickArea.BackgroundTransparency = 1
            ClickArea.Text = ""
            ClickArea.ZIndex = 2
            ClickArea.Parent = PlayerEntry
            
            -- Selection toggle on click
            ClickArea.MouseButton1Click:Connect(function()
                if SelectedTargets[player.Name] then
                    SelectedTargets[player.Name] = nil
                    Checkmark.Visible = false
                else
                    SelectedTargets[player.Name] = player
                    Checkmark.Visible = true
                end
                
                UpdateStatus()
            end)
            
            -- Store reference to this player's UI
            PlayerCheckboxes[player.Name] = {
                Entry = PlayerEntry,
                Checkmark = Checkmark
            }
            
            yPosition = yPosition + 35
        end
    end
    
    -- Update scrollframe canvas size
    PlayerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPosition + 5)
end
-- Count selected targets
local function CountSelectedTargets()
    local count = 0
    for _ in pairs(SelectedTargets) do
        count = count + 1
    end
    return count
end
-- Update status display
local function UpdateStatus()
    local count = CountSelectedTargets()
    if FlingActive then
        StatusLabel.Text = "Flinging " .. count .. " target(s)"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    else
        StatusLabel.Text = count .. " target(s) selected" 
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end
-- Function to select/deselect all players
local function ToggleAllPlayers(select)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player then
            local checkboxData = PlayerCheckboxes[player.Name]
            if checkboxData then
                if select then
                    SelectedTargets[player.Name] = player
                    checkboxData.Checkmark.Visible = true
                else
                    SelectedTargets[player.Name] = nil
                    checkboxData.Checkmark.Visible = false
                end
            end
        end
    end
    
    UpdateStatus()
end
-- Show notification
local function Message(Title, Text, Time)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = Title,
        Text = Text,
        Duration = Time or 5
    })
end
-- The fling function from zqyDSUWX
local function SkidFling(TargetPlayer)
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    
    local THumanoid
    local TRootPart
    local THead
    local Accessory
    local Handle
    if TCharacter:FindFirstChildOfClass("Humanoid") then
        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    end
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    if TCharacter:FindFirstChildOfClass("Accessory") then
        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    end
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end
    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        
        if THumanoid and THumanoid.Sit then
            return Message("Error", TargetPlayer.Name .. " is sitting", 2)
        end
        
        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end
        
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end
        
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = 2
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                end
            until Time + TimeToWait < tick() or not FlingActive
        end
        
        workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if TRootPart then
            SFBasePart(TRootPart)
        elseif THead then
            SFBasePart(THead)
        elseif Handle then
            SFBasePart(Handle)
        else
            return Message("Error", TargetPlayer.Name .. " has no valid parts", 2)
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        
        -- Reset character position
        if getgenv().OldPos then
            repeat
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, part in pairs(Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
                task.wait()
            until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
            workspace.FallenPartsDestroyHeight = getgenv().FPDH
        end
    else
        return Message("Error", "Your character is not ready", 2)
    end
end
-- Start flinging selected targets
local function StartFling()
    if FlingActive then return end
    
    local count = CountSelectedTargets()
    if count == 0 then
        StatusLabel.Text = "No targets selected!"
        wait(1)
        StatusLabel.Text = "Select targets to fling"
        return
    end
    
    FlingActive = true
    UpdateStatus()
    Message("Started", "Flinging " .. count .. " targets", 2)
    
    -- Start flinger in separate thread
    spawn(function()
        while FlingActive do
            local validTargets = {}
            
            -- Process all targets first to determine which are valid
            for name, player in pairs(SelectedTargets) do
                if player and player.Parent then
                    validTargets[name] = player
                else
                    -- Remove players who left
                    SelectedTargets[name] = nil
                    local checkbox = PlayerCheckboxes[name]
                    if checkbox then
                        checkbox.Checkmark.Visible = false
                    end
                end
            end
            
            -- Then attempt to fling each valid target
            for _, player in pairs(validTargets) do
                if FlingActive then
                    SkidFling(player)
                    -- Brief wait between targets to allow movement to reset
                    wait(0.1)
                else
                    break
                end
            end
            
            -- Update status periodically
            UpdateStatus()
            
            -- Wait a moment before starting next fling cycle
            wait(0.5)
        end
    end)
end
-- Stop flinging
local function StopFling()
    if not FlingActive then return end
    
    FlingActive = false
    
    UpdateStatus()
    Message("Stopped", "Fling has been stopped", 2)
end
local MiniButton

-- Set up button connections
StartButton.MouseButton1Click:Connect(StartFling)
StopButton.MouseButton1Click:Connect(StopFling)
SelectAllButton.MouseButton1Click:Connect(function() ToggleAllPlayers(true) end)
DeselectAllButton.MouseButton1Click:Connect(function() ToggleAllPlayers(false) end)
CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniButton.Visible = true
end)
-- Handle player joining/leaving
Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(function(player)
    if SelectedTargets[player.Name] then
        SelectedTargets[player.Name] = nil
    end
    RefreshPlayerList()
    UpdateStatus()
end)
-- Initialize
RefreshPlayerList()
UpdateStatus()
-- Success message

-- =====================================================
-- NEXBYTE ADMIN INTEGRATION
-- =====================================================

local GuiService = game:GetService("GuiService")

local BG = Color3.fromRGB(7, 15, 27)
local PANEL = Color3.fromRGB(13, 25, 40)
local ROW = Color3.fromRGB(18, 35, 53)
local ACCENT = Color3.fromRGB(0, 195, 235)
local ACCENT_DARK = Color3.fromRGB(0, 105, 145)
local TEXT = Color3.fromRGB(225, 240, 250)
local MUTED = Color3.fromRGB(105, 145, 170)
local RED = Color3.fromRGB(175, 55, 65)

ScreenGui.Name = "NEXBYTE_ADMIN"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999

MainFrame.Name = "NEXBYTE_MAIN"
MainFrame.Size = UDim2.fromOffset(340, 500)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.BackgroundColor3 = BG
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

TitleBar.Size = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = PANEL
TitleBar.BorderSizePixel = 0

Title.Position = UDim2.new(0, 12, 0, 0)
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Text = "NEXBYTE  /  ADMIN"
Title.TextColor3 = ACCENT
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

CloseButton.Position = UDim2.new(1, -34, 0, 4)
CloseButton.Size = UDim2.fromOffset(28, 28)
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 13
CloseButton.BackgroundColor3 = RED
CloseButton.TextColor3 = TEXT

StatusLabel.Position = UDim2.new(0, 12, 0, 44)
StatusLabel.Size = UDim2.new(1, -24, 0, 24)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 12
StatusLabel.TextColor3 = MUTED
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

SelectionFrame.Position = UDim2.new(0, 10, 0, 76)
SelectionFrame.Size = UDim2.new(1, -20, 0, 216)
SelectionFrame.BackgroundColor3 = PANEL
SelectionFrame.BorderSizePixel = 0

PlayerScrollFrame.Position = UDim2.new(0, 6, 0, 6)
PlayerScrollFrame.Size = UDim2.new(1, -12, 1, -12)
PlayerScrollFrame.ScrollBarThickness = 4
PlayerScrollFrame.ScrollBarImageColor3 = ACCENT

StartButton.Position = UDim2.new(0, 10, 0, 302)
StartButton.Size = UDim2.new(0.5, -15, 0, 40)
StartButton.BackgroundColor3 = ACCENT_DARK
StartButton.Text = "START FLING"
StartButton.Font = Enum.Font.GothamBold
StartButton.TextSize = 13
StartButton.TextColor3 = TEXT

StopButton.Position = UDim2.new(0.5, 5, 0, 302)
StopButton.Size = UDim2.new(0.5, -15, 0, 40)
StopButton.BackgroundColor3 = RED
StopButton.Text = "STOP FLING"
StopButton.Font = Enum.Font.GothamBold
StopButton.TextSize = 13
StopButton.TextColor3 = TEXT

SelectAllButton.Position = UDim2.new(0, 10, 0, 348)
SelectAllButton.Size = UDim2.new(0.5, -15, 0, 32)
SelectAllButton.BackgroundColor3 = ROW
SelectAllButton.Text = "SELECT ALL"
SelectAllButton.Font = Enum.Font.GothamBold
SelectAllButton.TextSize = 11
SelectAllButton.TextColor3 = TEXT

DeselectAllButton.Position = UDim2.new(0.5, 5, 0, 348)
DeselectAllButton.Size = UDim2.new(0.5, -15, 0, 32)
DeselectAllButton.BackgroundColor3 = ROW
DeselectAllButton.Text = "CLEAR SELECT"
DeselectAllButton.Font = Enum.Font.GothamBold
DeselectAllButton.TextSize = 11
DeselectAllButton.TextColor3 = TEXT

local function Decorate(obj, radius)
    obj.BorderSizePixel = 0

    if not obj:FindFirstChildOfClass("UICorner") then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius or 8)
        corner.Parent = obj
    end

    if not obj:FindFirstChildOfClass("UIStroke") then
        local outline = Instance.new("UIStroke")
        outline.Color = ACCENT
        outline.Transparency = 0.78
        outline.Thickness = 1
        outline.Parent = obj
    end
end

local function MakeButton(name, caption, position, size, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Position = position
    button.Size = size
    button.BackgroundColor3 = color or ROW
    button.Text = caption
    button.TextColor3 = TEXT
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.AutoButtonColor = true
    button.BorderSizePixel = 0
    button.Parent = MainFrame
    Decorate(button, 7)
    return button
end

Decorate(MainFrame, 12)
Decorate(SelectionFrame, 9)
Decorate(StartButton, 8)
Decorate(StopButton, 8)
Decorate(SelectAllButton, 7)
Decorate(DeselectAllButton, 7)
Decorate(CloseButton, 6)

-- Player list visuals and clickable selection layers
local function StylePlayerRows()
    for _, entry in ipairs(PlayerScrollFrame:GetChildren()) do
        if entry:IsA("Frame") then
            entry.BackgroundColor3 = ROW
            Decorate(entry, 7)

            for _, item in ipairs(entry:GetDescendants()) do
                if item:IsA("TextButton") then
                    if item.Size.X.Scale >= 0.9 then
                        item.ZIndex = 1
                    else
                        item.ZIndex = 2
                        item.BackgroundColor3 = PANEL
                        Decorate(item, 5)
                    end
                elseif item:IsA("TextLabel") then
                    item.ZIndex = item.Text == "✓" and 3 or 2
                    item.TextColor3 = item.Text == "✓" and ACCENT or TEXT
                    item.Font = Enum.Font.GothamMedium
                    item.TextSize = item.Text == "✓" and 16 or 13
                end
            end
        end
    end
end

-- Branded status
local OriginalUpdateStatus = UpdateStatus

UpdateStatus = function()
    OriginalUpdateStatus()

    local count = CountSelectedTargets()
    if FlingActive then
        StatusLabel.Text = "NEXBYTE // FLING ACTIVE // " .. count .. " TARGETS"
        StatusLabel.TextColor3 = ACCENT
    else
        StatusLabel.Text = "NEXBYTE // " .. count .. " SELECTED"
        StatusLabel.TextColor3 = MUTED
    end
end

-- Utility buttons
local TPButton = MakeButton(
    "TPButton", "TP TO",
    UDim2.new(0, 10, 0, 393),
    UDim2.fromOffset(74, 34),
    ACCENT_DARK
)

local EyeButton = MakeButton(
    "EyeButton", "EYE",
    UDim2.new(0, 90, 0, 393),
    UDim2.fromOffset(74, 34)
)

local RefreshButton = MakeButton(
    "RefreshButton", "REFRESH",
    UDim2.new(0, 170, 0, 393),
    UDim2.fromOffset(74, 34)
)

local PauseButton = MakeButton(
    "PauseButton", "PAUSE UI",
    UDim2.new(0, 250, 0, 393),
    UDim2.fromOffset(78, 34)
)

-- Footer
local Footer = Instance.new("TextLabel")
Footer.Name = "NEXBYTE_FOOTER"
Footer.Position = UDim2.new(0, 12, 0, 480)
Footer.Size = UDim2.new(1, -24, 0, 14)
Footer.BackgroundTransparency = 1
Footer.Text = "NEXBYTE TOOLKIT  •  CLIENT CONTROL"
Footer.TextColor3 = MUTED
Footer.Font = Enum.Font.Gotham
Footer.TextSize = 9
Footer.TextXAlignment = Enum.TextXAlignment.Left
Footer.Parent = MainFrame

-- Minimize / restore
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Position = UDim2.new(1, -66, 0, 4)
MinimizeButton.Size = UDim2.fromOffset(28, 28)
MinimizeButton.BackgroundColor3 = ROW
MinimizeButton.Text = "_"
MinimizeButton.TextColor3 = ACCENT
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 17
MinimizeButton.Parent = TitleBar
Decorate(MinimizeButton, 6)

MiniButton = Instance.new("TextButton")
MiniButton.Name = "NEXBYTE_RESTORE"
MiniButton.Size = UDim2.fromOffset(126, 38)
MiniButton.Position = UDim2.new(0, 12, 0.5, -19)
MiniButton.BackgroundColor3 = BG
MiniButton.Text = "NEXBYTE  +"
MiniButton.TextColor3 = ACCENT
MiniButton.Font = Enum.Font.GothamBold
MiniButton.TextSize = 13
MiniButton.Visible = false
MiniButton.ZIndex = 50
MiniButton.Parent = ScreenGui
Decorate(MiniButton, 9)

MinimizeButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniButton.Visible = true
end)

MiniButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MiniButton.Visible = false
end)

-- Selected player helper
local function GetSelectedTarget()
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= Player and SelectedTargets[target.Name] then
            return target
        end
    end
    return nil
end


-- NEXBYTE TROLL CONTROLS
local TrollBring = MakeButton(
    "TrollBring", "BRING",
    UDim2.new(0, 10, 0, 445),
    UDim2.fromOffset(100, 32), ACCENT_DARK
)

local TrollToolKill = MakeButton(
    "TrollToolKill", "TOOL KILL",
    UDim2.new(0, 120, 0, 445),
    UDim2.fromOffset(100, 32), ACCENT_DARK
)

local TrollTouchFling = MakeButton(
    "TrollTouchFling", "TOUCH FLING: OFF",
    UDim2.new(0, 230, 0, 445),
    UDim2.fromOffset(100, 32), ACCENT_DARK
)

-- BRING
local BringActive = false

TrollBring.MouseButton1Click:Connect(function()
    if BringActive then
        BringActive = false
        TrollBring.Text = "BRING"
        TrollBring.BackgroundColor3 = ACCENT_DARK
        return
    end

    local target = GetSelectedTarget()
    local myChar = Player.Character
    local targetChar = target and target.Character

    local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

    if not (hrp and targetRoot) then
        Message("NEXBYTE", "Target unavailable", 2)
        return
    end

    BringActive = true
    TrollBring.Text = "BRINGING..."
    TrollBring.BackgroundColor3 = ACCENT

    task.spawn(function()
        local speeding = 32
        local maxspeed = 75
        local off = CFrame.Angles(-math.pi / 2, 0, 0)

        local fromP = targetRoot.Position
        local toP = hrp.Position
        local destination = hrp.CFrame
        local mag = (fromP - toP).Magnitude - 3
        local lv = CFrame.new(fromP, toP).LookVector
        local vel = 0
        local pos = fromP - Vector3.new(0, 2, 0)
        toP = toP - Vector3.new(0, 2, 0)

        local last = os.clock()
        local way = 0
        local reachedMax = false

        while BringActive
            and myChar:IsDescendantOf(workspace)
            and targetChar:IsDescendantOf(workspace) do

            local now = os.clock()
            local dt = now - last
            last = now

            if reachedMax then
                if mag - way < reachedMax then
                    vel = vel - dt * speeding
                    if vel < 0 then break end
                end
            else
                if way > mag / 2 then
                    vel = vel - dt * speeding
                    if vel < 0 then break end
                else
                    vel = vel + dt * speeding
                    if vel > maxspeed then
                        reachedMax = way
                        vel = maxspeed
                    end
                end
            end

            way = way + vel * dt

            local humanoid = myChar:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
                hrp.CFrame = CFrame.new(pos + lv * way, toP) * off
                hrp.AssemblyLinearVelocity = lv * (vel + 1)
                hrp.AssemblyAngularVelocity = Vector3.zero
            end

            task.wait()
        end

        if hrp.Parent then
            hrp.CFrame = destination
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end

        BringActive = false
        TrollBring.Text = "BRING"
        TrollBring.BackgroundColor3 = ACCENT_DARK
    end)
end)

-- TOOL KILL
TrollToolKill.MouseButton1Click:Connect(function()
    local target = GetSelectedTarget()
    local char = Player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    local handle = tool and tool:FindFirstChild("Handle")
    local touch = handle and handle:FindFirstChildOfClass("TouchTransmitter")
    local root = target and target.Character
        and target.Character:FindFirstChild("HumanoidRootPart")

    if not tool or not handle or not touch then
        Message("NEXBYTE", "Equip a compatible Tool first", 2)
        return
    end

    if not root then
        Message("NEXBYTE", "Select a player first", 2)
        return
    end

    if type(firetouchinterest) ~= "function" then
        Message("NEXBYTE", "Touch function unavailable", 2)
        return
    end

    for _ = 1, 10 do
        firetouchinterest(handle, root, 0)
        firetouchinterest(handle, root, 1)
        firetouchinterest(handle, root, 0)
        firetouchinterest(handle, root, 1)
        firetouchinterest(handle, root, 0)
        firetouchinterest(handle, root, 1)
        firetouchinterest(handle, root, 0)
        firetouchinterest(handle, root, 1)
        firetouchinterest(handle, root, 0)
        firetouchinterest(handle, root, 1)
    end

    Message("NEXBYTE", "Tool interaction sent to " .. target.Name, 2)
end)

-- TOUCH FLING
local TouchFlingActive = false
local TouchFlingMove = 0.1

TrollTouchFling.MouseButton1Click:Connect(function()
    TouchFlingActive = not TouchFlingActive

    TrollTouchFling.Text = TouchFlingActive
        and "TOUCH FLING: ON"
        or "TOUCH FLING: OFF"

    TrollTouchFling.BackgroundColor3 = TouchFlingActive
        and ACCENT
        or ACCENT_DARK

    if TouchFlingActive then
        task.spawn(function()
            while TouchFlingActive do
                RunService.Heartbeat:Wait()

                local char = Player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")

                if root then
                    local vel = root.AssemblyLinearVelocity

                    root.AssemblyLinearVelocity =
                        vel * 10000 + Vector3.new(0, 10000, 0)

                    RunService.RenderStepped:Wait()
                    if not TouchFlingActive then break end

                    root.AssemblyLinearVelocity = vel
                    RunService.Stepped:Wait()

                    root.AssemblyLinearVelocity =
                        vel + Vector3.new(0, TouchFlingMove, 0)

                    TouchFlingMove = -TouchFlingMove
                end
            end
        end)
    end
end)


-- Teleport to selected player
TPButton.MouseButton1Click:Connect(function()
    local target = GetSelectedTarget()
    if not target then
        Message("NEXBYTE", "Select a player first", 2)
        return
    end

    local targetCharacter = target.Character
    local myCharacter = Player.Character

    local targetRoot = targetCharacter and (
        targetCharacter:FindFirstChild("HumanoidRootPart")
        or targetCharacter:FindFirstChild("Torso")
    )

    local myRoot = myCharacter and (
        myCharacter:FindFirstChild("HumanoidRootPart")
        or myCharacter:FindFirstChild("Torso")
    )

    if targetRoot and myRoot then
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        Message("NEXBYTE", "Teleported to " .. target.Name, 2)
    else
        Message("NEXBYTE", "Character is not ready", 2)
    end
end)

-- EYE / spectate
local WatchingTarget = nil

local function RestoreCamera()
    WatchingTarget = nil
    local character = Player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid and workspace.CurrentCamera then
        workspace.CurrentCamera.CameraSubject = humanoid
    end

    EyeButton.Text = "EYE"
end

EyeButton.MouseButton1Click:Connect(function()
    if WatchingTarget then
        RestoreCamera()
        return
    end

    local target = GetSelectedTarget()
    local character = target and target.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid or not workspace.CurrentCamera then
        Message("NEXBYTE", "Select an available player", 2)
        return
    end

    WatchingTarget = target
    workspace.CurrentCamera.CameraSubject = humanoid
    EyeButton.Text = "EYE: ON"
end)

-- Refresh list
RefreshButton.MouseButton1Click:Connect(function()
    RefreshPlayerList()
    task.wait(0.1)
    StylePlayerRows()
    UpdateStatus()
end)

-- Pause notification switch
-- This changes the built-in notification only, not the actual game pause.
local OriginalPauseState = false

pcall(function()
    OriginalPauseState = GuiService:GetGameplayPausedNotificationEnabled()
end)

local PauseDisabled = OriginalPauseState

local function ApplyPauseState()
    pcall(function()
        GuiService:SetGameplayPausedNotificationEnabled(PauseDisabled)
    end)

    PauseButton.Text = PauseDisabled and "PAUSE: OFF" or "PAUSE: ON"
end

ApplyPauseState()

PauseButton.MouseButton1Click:Connect(function()
    PauseDisabled = not PauseDisabled
    ApplyPauseState()
end)

-- Style the first player list and future updates
StylePlayerRows()

Players.PlayerAdded:Connect(function()
    task.wait(0.25)
    StylePlayerRows()
end)

Players.PlayerRemoving:Connect(function(target)
    if WatchingTarget == target then
        RestoreCamera()
    end

    task.wait(0.1)
    StylePlayerRows()
end)

-- Cleanup
ScreenGui.Destroying:Connect(function()
    pcall(function()
        StopFling()
        GuiService:SetGameplayPausedNotificationEnabled(OriginalPauseState)
    end)

    RestoreCamera()
end)

UpdateStatus()
Message("NEXBYTE", "NEXBYTE ADMIN loaded successfully", 3)


-- =====================================================

-- =====================================================
-- NEXBYTE MOBILE UI v2
-- =====================================================

local mobileScale = MainFrame:FindFirstChildOfClass("UIScale")

if not mobileScale then
    mobileScale = Instance.new("UIScale")
    mobileScale.Parent = MainFrame
end

mobileScale.Scale = 0.68

MainFrame.Size = UDim2.fromOffset(340, 500)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 12, 22)
MainFrame.BackgroundTransparency = 0.18
MainFrame.ClipsDescendants = true

TitleBar.BackgroundColor3 = Color3.fromRGB(9, 23, 38)
TitleBar.BackgroundTransparency = 0.12

SelectionFrame.BackgroundColor3 = Color3.fromRGB(10, 25, 40)
SelectionFrame.BackgroundTransparency = 0.2

for _, object in ipairs(MainFrame:GetDescendants()) do
    if object:IsA("TextButton") then
        object.BackgroundTransparency = 0.18
        object.TextScaled = false
    elseif object:IsA("TextLabel") then
        object.BackgroundTransparency = 1
    elseif object:IsA("Frame") then
        object.BackgroundTransparency = 0.2
    elseif object:IsA("ScrollingFrame") then
        object.BackgroundTransparency = 0.25
        object.ScrollBarThickness = 3
        object.ScrollBarImageColor3 = Color3.fromRGB(0, 195, 235)
    end
end

-- Compact mobile buttons
StartButton.TextSize = 11
StopButton.TextSize = 11
SelectAllButton.TextSize = 10
DeselectAllButton.TextSize = 10

-- NEXBYTE accent
local accent = Color3.fromRGB(0, 195, 235)

for _, object in ipairs(MainFrame:GetDescendants()) do
    if object:IsA("UIStroke") then
        object.Color = accent
        object.Transparency = 0.78
        object.Thickness = 1
    end
end

Message("NEXBYTE", "Mobile interface updated", 3)
-- NEXBYTE RAYFIELD RESTORE
-- Old handlers retained, BRING intentionally excluded.

pcall(function() MainFrame.Visible = false end)
pcall(function() if MiniButton then MiniButton.Visible = false end end)

local NXPlayers = game:GetService("Players")
local NXPlayer = NXPlayers.LocalPlayer
local NXLighting = game:GetService("Lighting")
local NXHttp = game:GetService("HttpService")

local NXRayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local NXWindow = NXRayfield:CreateWindow({
    name = "NEXBYTE ADMIN",
    subtitle = "Universal Client Toolkit • v1.1",
    sidebarLayout = true,
    theme = "Default"
})

local function NXNotify(title, content)
    NXWindow:Notify({
        title = title,
        content = content,
        duration = 4
    })
end

local function NXGetNames()
    local names = {}
    for _, p in ipairs(NXPlayers:GetPlayers()) do
        if p ~= NXPlayer then
            table.insert(names, p.Name)
        end
    end
    table.sort(names)
    return names
end

local function NXGetTarget()
    for _, p in ipairs(NXPlayers:GetPlayers()) do
        if p ~= NXPlayer and SelectedTargets[p.Name] then
            return p
        end
    end
end

-- HOME
local NXHome = NXWindow:CreateTab({name="HOME", icon="house"})
NXHome:CreateSection({name="NEXBYTE ADMIN"})
NXHome:CreateText({
    name="Status",
    text="Build 1.1 | Rayfield Gen2 | Legacy handlers restored"
})

NXHome:CreateButton({
    name="REFRESH STATUS",
    callback=function()
        NXNotify("NEXBYTE", "Interface is running")
    end
})

-- PLAYER / FLING
local NXPlayerTab = NXWindow:CreateTab({name="PLAYER", icon="users"})
NXPlayerTab:CreateSection({name="TARGET SELECTION"})

local NXDropdown
NXDropdown = NXPlayerTab:CreateDropdown({
    name="SELECT PLAYERS",
    options=NXGetNames(),
    value={},
    multiSelect=true,
    placeholder="Choose players",
    callback=function(value)
        for name in pairs(SelectedTargets) do
            SelectedTargets[name] = nil
        end

        local chosen = type(value) == "table" and value or {value}
        for _, name in ipairs(chosen) do
            local p = NXPlayers:FindFirstChild(name)
            if p and p ~= NXPlayer then
                SelectedTargets[name] = p
            end
        end

        UpdateStatus()
    end
})

NXPlayerTab:CreateButton({
    name="REFRESH PLAYER LIST",
    callback=function()
        RefreshPlayerList()
        pcall(function() StylePlayerRows() end)
        NXDropdown:Refresh(NXGetNames())
        UpdateStatus()
        NXNotify("PLAYER LIST", "Updated")
    end
})

NXPlayerTab:CreateButton({
    name="SELECT ALL",
    callback=function()
        RefreshPlayerList()
        ToggleAllPlayers(true)
        NXNotify("NEXBYTE", "All players selected")
    end
})

NXPlayerTab:CreateButton({
    name="DESELECT ALL",
    callback=function()
        ToggleAllPlayers(false)
        NXNotify("NEXBYTE", "Selection cleared")
    end
})

NXPlayerTab:CreateButton({
    name="START FLING",
    callback=function()
        StartFling()
    end
})

NXPlayerTab:CreateButton({
    name="STOP FLING",
    callback=function()
        StopFling()
    end
})

NXPlayerTab:CreateButton({
    name="TP TO SELECTED",
    callback=function()
        local target = NXGetTarget()
        local myChar = NXPlayer.Character
        local targetChar = target and target.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

        if myRoot and targetRoot then
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0,0,3)
            NXNotify("NEXBYTE", "TP complete")
        else
            NXNotify("NEXBYTE", "Select an available player")
        end
    end
})

-- TROLL
local NXTroll = NXWindow:CreateTab({name="TROLL", icon="zap"})
NXTroll:CreateSection({name="TOOL CONTROL"})

NXTroll:CreateButton({
    name="TOOL KILL",
    callback=function()
        local target = NXGetTarget()
        local char = NXPlayer.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        local handle = tool and tool:FindFirstChild("Handle")
        local touch = handle and handle:FindFirstChildOfClass("TouchTransmitter")
        local root = target and target.Character
            and target.Character:FindFirstChild("HumanoidRootPart")

        if not (tool and handle and touch and root) then
            NXNotify("TOOL KILL", "Need a compatible equipped Tool and selected player")
            return
        end

        if type(firetouchinterest) ~= "function" then
            NXNotify("TOOL KILL", "Touch function unavailable")
            return
        end

        for i=1,10 do
            firetouchinterest(handle, root, 0)
            firetouchinterest(handle, root, 1)
        end
        NXNotify("TOOL KILL", "Interaction sent")
    end
})

NXTroll:CreateButton({
    name="TOUCH FLING: TOGGLE",
    callback=function()
        TouchFlingActive = not TouchFlingActive
        if TouchFlingActive then
            task.spawn(function()
                while TouchFlingActive do
                    game:GetService("RunService").Heartbeat:Wait()
                    local char = NXPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local vel = root.AssemblyLinearVelocity
                        root.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0,10000,0)
                        game:GetService("RunService").RenderStepped:Wait()
                        if not TouchFlingActive then break end
                        root.AssemblyLinearVelocity = vel
                        game:GetService("RunService").Stepped:Wait()
                        root.AssemblyLinearVelocity = vel + Vector3.new(0,TouchFlingMove,0)
                        TouchFlingMove = -TouchFlingMove
                    end
                end
            end)
        end
        NXNotify("TOUCH FLING", TouchFlingActive and "ON" or "OFF")
    end
})

-- NEXBYTE C00LCLAN V1 PORT
-- Original C00LCLAN menu is intentionally omitted. All registered callbacks are exposed in Rayfield TROLL.
do
    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    local player = Player
    local PlayerGui = Player:WaitForChild("PlayerGui")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local PhysicsService = game:GetService("PhysicsService")
    local CollectionService = game:GetService("CollectionService")
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local MarketplaceService = game:GetService("MarketplaceService")
    local StarterGui = game:GetService("StarterGui")
    local Debris = game:GetService("Debris")
    local Lighting = game:GetService("Lighting")
    local SoundService = game:GetService("SoundService")
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local HRP = Character:WaitForChild("HumanoidRootPart")
    local Mouse = Player:GetMouse()
    local PlaceId = game.PlaceId
    local JobId = game.JobId

    local infjump = false
    local invisRunning = false
    local noclipOn = false
    local noclipConn
    local hoverHeight
    local bindFrame, bindConn, waitingBindFunction
    local customBinds = {}
    local infJumpEnabled = false
    local infJumpConnection = nil
    local espOn = false
    local spinOn = false
    local spinBAV, lockBP
    local savedCFrame
    local InvisibleCharacter = nil
    local OriginalCharacter = nil
    local voidConn = nil
    local flyingEnabled = false
    local flyBG, flyBV, flyConn
    local ray, hit, pos
    local decalSpamRunning = false

    Player.CharacterAdded:Connect(function(character)
        Character = character
        Humanoid = character:WaitForChild("Humanoid")
        HRP = character:WaitForChild("HumanoidRootPart")
    end)

    math.randomseed(os.time())
    local character_set = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local string_sub = string.sub
    local math_random = math.random
    local table_concat = table.concat
    local character_set_amount = #character_set
    local number_one = 1
    local default_length = 10

    local function generate_string(length)
        local random_string = {}
        for int = number_one, length or default_length do
            local random_number = math_random(number_one, character_set_amount)
            local character = string_sub(character_set, random_number, random_number)
            random_string[#random_string + number_one] = character
        end
        return table_concat(random_string)
    end

    -- Utility container only; the original C00LCLAN hub UI is not created.
    local previousUtilityGui = PlayerGui:FindFirstChild("NEXBYTE_TrollUtilities")
    if previousUtilityGui then previousUtilityGui:Destroy() end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NEXBYTE_TrollUtilities"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    local die = screenGui.Name

    local function Notify(message, title, duration)
        NXNotify(tostring(title or "C00LCLAN"), tostring(message))
    end
    local function NotifyERROR(message)
        NXNotify("C00LCLAN", tostring(message))
    end

    local FunctionManager = {
        CategorizedFunctions = { All = {} },
        Categories = { "All" },
        CurrentCategoryIndex = 1,
        Descriptions = {},
        ISFE = {},
        OnFunctionAdded = Instance.new("BindableEvent"),
    }

    function FunctionManager:register(name, callback, category, description, FE)
        category = category or "General"
        if not self.CategorizedFunctions[category] then
            self.CategorizedFunctions[category] = {}
            table.insert(self.Categories, category)
        end
        self.CategorizedFunctions[category][name] = callback
        self.CategorizedFunctions.All[name] = callback
        self.Descriptions[name] = description or ""
        self.ISFE[name] = FE or "yes"
        if description == "NOT FE" then
            self.ISFE[name] = "no"
        end
        self.OnFunctionAdded:Fire(category, name, callback)
        self.OnFunctionAdded:Fire("All", name, callback)
    end

    function FunctionManager:getCurrentCategory()
        return self.Categories[self.CurrentCategoryIndex]
    end
    function FunctionManager:cycleCategory()
        self.CurrentCategoryIndex = self.CurrentCategoryIndex % #self.Categories + 1
        return self:getCurrentCategory()
    end
    function FunctionManager:getFunctionsInCategory(category)
        return self.CategorizedFunctions[category] or {}
    end

FunctionManager:register("Decal Spam", function()
	if decalSpamRunning then
		decalSpamRunning = false
		Notify("Decal Spam stopped", "NEXBYTE", 3)
		return
	end
	decalSpamRunning = true
	Notify("Decal Spam started. Press its button again to stop.", "NEXBYTE", 3)
	local decalID = 8408806737
	local function exPro(root)
		for _, v in pairs(root:GetChildren()) do
			if v:IsA("Decal") and v.Texture ~= "http://www.roblox.com/asset/?id="..decalID then
				v.Parent = nil
			elseif v:IsA("BasePart") then
				v.Material = "Plastic"
				v.Transparency = 0
				local One = Instance.new("Decal", v)
				local Two = Instance.new("Decal", v)
				local Three = Instance.new("Decal", v)
				local Four = Instance.new("Decal", v)
				local Five = Instance.new("Decal", v)
				local Six = Instance.new("Decal", v)
				One.Texture = "http://www.roblox.com/asset/?id="..decalID
				Two.Texture = "http://www.roblox.com/asset/?id="..decalID
				Three.Texture = "http://www.roblox.com/asset/?id="..decalID
				Four.Texture = "http://www.roblox.com/asset/?id="..decalID
				Five.Texture = "http://www.roblox.com/asset/?id="..decalID
				Six.Texture = "http://www.roblox.com/asset/?id="..decalID
				One.Face = "Front"
				Two.Face = "Back"
				Three.Face = "Right"
				Four.Face = "Left"
				Five.Face = "Top"
				Six.Face = "Bottom"
			end
			exPro(v)
		end
	end
	local function asdf(root)
		for _, v in pairs(root:GetChildren()) do
			asdf(v)
		end
	end
	exPro(game.Workspace)
	asdf(game.Workspace)

	local s = Instance.new("Sky")
	s.Name = "Sky"
	s.Parent = game.Lighting
	local skyboxID = 8408806737
	s.SkyboxBk = "http://www.roblox.com/asset/?id="..skyboxID
	s.SkyboxDn = "http://www.roblox.com/asset/?id="..skyboxID
	s.SkyboxFt = "http://www.roblox.com/asset/?id="..skyboxID
	s.SkyboxLf = "http://www.roblox.com/asset/?id="..skyboxID
	s.SkyboxRt = "http://www.roblox.com/asset/?id="..skyboxID
	s.SkyboxUp = "http://www.roblox.com/asset/?id="..skyboxID
	game.Lighting.TimeOfDay = 12

	for i, v in pairs(game.Players:GetChildren()) do
		local emit = Instance.new("ParticleEmitter")
		emit.Parent = v.Character.Torso
		emit.Texture = "http://www.roblox.com/asset/?id=8408806737"
		emit.VelocitySpread = 20
	end
	for i, v in pairs(game.Players:GetChildren()) do
		local emit = Instance.new("ParticleEmitter")
		emit.Parent = v.Character.Torso
		emit.Texture = "http://www.roblox.com/asset/?id=8408806737"
		emit.VelocitySpread = 20
	end
	for i, v in pairs(game.Players:GetChildren()) do
		local emit = Instance.new("ParticleEmitter")
		emit.Parent = v.Character.Torso
		emit.Texture = "http://www.roblox.com/asset/?id=8408806737"
		emit.VelocitySpread = 20
	end
	while decalSpamRunning do
		game.Lighting.Ambient = Color3.new(math.random() , math.random() , math.random())
		wait(0.2)
		game.Lighting.ShadowColor = Color3.new(math.random() , math.random() , math.random())
		wait(0.2) 
	end
end, "Troll", "NOT FE")
FunctionManager:register("JOHN DOE", function()

	local redSkyboxAssetId = "rbxassetid://1012887"
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky", Lighting)
	end
	sky.SkyboxBk = redSkyboxAssetId
	sky.SkyboxDn = redSkyboxAssetId
	sky.SkyboxFt = redSkyboxAssetId
	sky.SkyboxLf = redSkyboxAssetId
	sky.SkyboxRt = redSkyboxAssetId
	sky.SkyboxUp = redSkyboxAssetId

	if not ReplicatedStorage:FindFirstChild("juisdfj0i32i0eidsuf0iok") then
		local detection = Instance.new("Decal")
		detection.Name = "juisdfj0i32i0eidsuf0iok"
		detection.Parent = ReplicatedStorage
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PersistentSoundGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 150, 0, 50)
	button.Position = UDim2.new(0.02, 0, 0.477, 0)
	button.Text = "Sound Toggle"
	button.Font = Enum.Font.SourceSansBold
	button.TextSize = 20
	button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = screenGui

	local backgroundSound = SoundService:FindFirstChild("PersistentBGSound")
	if not backgroundSound then
		backgroundSound = Instance.new("Sound")
		backgroundSound.Name = "PersistentBGSound"
		backgroundSound.SoundId = "rbxassetid://19094700"
		backgroundSound.PlaybackSpeed = 0.221
		backgroundSound.Looped = true
		backgroundSound.Volume = 1
		backgroundSound.Parent = SoundService
		backgroundSound:Play()
	end

	button.Activated:Connect(function()
		backgroundSound.Playing = not backgroundSound.Playing
	end)

	local function setupCharacter(character)
		local humanoid = character:WaitForChild("Humanoid")
		local torso = character:WaitForChild("Torso")
		local hrp = character:WaitForChild("HumanoidRootPart")

		local tool = Instance.new("Tool")
		tool.Name = "Slash"
		tool.RequiresHandle = false
		tool.Parent = player.Backpack

		tool.Activated:Connect(function()
			local animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://186934658"
			local track = humanoid:LoadAnimation(animation)
			track:Play()
			track:AdjustSpeed(2)

			local s = Instance.new("Sound", torso)
			s.SoundId = "rbxassetid://28144425"
			s:Play()

			task.wait(0.2)

			local s2 = Instance.new("Sound", torso)
			s2.SoundId = "rbxassetid://429400881"
			s2.Volume = 0.2
			s2:Play()
		end)

		local naeeym = Instance.new("BillboardGui", character)
		naeeym.Size = UDim2.new(0, 100, 0, 40)
		naeeym.StudsOffset = Vector3.new(0, 2, 0)
		naeeym.Adornee = character:WaitForChild("Head")

		local tecks = Instance.new("TextLabel", naeeym)
		tecks.BackgroundTransparency = 1
		tecks.BorderSizePixel = 0
		tecks.Font = Enum.Font.Fantasy
		tecks.TextSize = 24
		tecks.TextStrokeTransparency = 0
		tecks.TextStrokeColor3 = Color3.new(0, 0, 0)
		tecks.TextColor3 = Color3.new(0, 0, 0)
		tecks.Size = UDim2.new(1, 0, 0.5, 0)
		tecks.Text = "John Doe"

		local function changeName(newName)
			tecks.Text = newName
		end

		local function shakeTag()
			local originalOffset = naeeym.StudsOffset
			for _ = 1, 10 do
				naeeym.StudsOffset = originalOffset + Vector3.new(math.random(-1,1), math.random(-1,1), math.random(-1,1))
				task.wait(0.05)
			end
			naeeym.StudsOffset = originalOffset
		end

		coroutine.wrap(function()
			while character:IsDescendantOf(workspace) do
				changeName("BURN IN HELL")
				shakeTag()
				task.wait(0.2)
				changeName("STOP")
				task.wait(0.1)
				changeName("JUST GIVE UP")
				shakeTag()
				task.wait(0.2)
				changeName("STOP")
				shakeTag()
				task.wait(0.2)
				changeName("JOHN DOE")
				shakeTag()
				task.wait(0.3)
				changeName("HOPELESS")
				shakeTag()
				task.wait(0.3)
			end
		end)()

		local footPartSize = Vector3.new(10, 0.5, 10)
		local floorPartColor = BrickColor.Black()
		local floorMaterial = Enum.Material.Neon
		local yOffset = -2.8
		local lastPosition = hrp.Position
		local standingTimer = 0

		RunService.Heartbeat:Connect(function(dt)
			if not character:IsDescendantOf(workspace) then return end
			local currentPosition = hrp.Position
			standingTimer += dt
			local distanceMoved = (currentPosition - lastPosition).Magnitude
			local stepPosition = Vector3.new(currentPosition.X, hrp.Position.Y + yOffset, currentPosition.Z)

			local function createFootstep(position)
				local part = Instance.new("Part")
				part.Size = footPartSize
				part.Position = position
				part.Anchored = true
				part.CanCollide = false
				part.BrickColor = floorPartColor
				part.Material = floorMaterial
				part.Transparency = 0.5
				part.Parent = workspace
				task.spawn(function()
					for i = 1, 10 do
						part.Transparency = i * 0.03
						task.wait(0.05)
					end
				end)
				Debris:AddItem(part, 1)
			end

			if distanceMoved > 1 then
				createFootstep(stepPosition)
				lastPosition = currentPosition
				standingTimer = 0
			elseif standingTimer > 0.5 then
				createFootstep(stepPosition)
				standingTimer = 0
			end
		end)

		local movel = 0.1
		local hiddenfling = true

		local function fling()
			while hiddenfling and character:IsDescendantOf(workspace) do
				if hrp then
					local originalVelocity = hrp.Velocity
					hrp.Velocity = originalVelocity * 10000 + Vector3.new(0, 10000, 0)
					RunService.RenderStepped:Wait()
					hrp.Velocity = originalVelocity
					RunService.Stepped:Wait()
					hrp.Velocity = originalVelocity + Vector3.new(0, movel, 0)
					movel = -movel
				end
				RunService.Heartbeat:Wait()
			end
		end
		coroutine.wrap(fling)()
	end

	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		setupCharacter(player.Character)
	end

	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")

	local player = Players.LocalPlayer
	local mouse = player:GetMouse()

	local function teleportToMousePosition()
		local character = player.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			return
		end

		local target = mouse.Hit
		if target then
			character:MoveTo(target.Position)
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.T then
			teleportToMousePosition()
		end
	end)
end, "Trolling", "BROKEN")
FunctionManager:register("Invis gui", function()
	loadstring(game:HttpGet('https://pastebin.com/raw/3Rnd9rHf'))()
end, "Trolling", "Credits to the original maker!")
FunctionManager:register("DANCE", function()
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://27789359" 
	local track = game.Players.LocalPlayer.Character.Humanoid:LoadAnimation(anim)
	track:Play()
end, "Fun", "DANCE DANCE")
FunctionManager:register("Sound GUI", function()
	local gui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("SoundGui")
	if gui then
		gui:Destroy()
		return
	end
	local SoundGui = Instance.new("ScreenGui")
	local Frame = Instance.new("Frame")
	local AddSoundId = Instance.new("TextButton")
	local SoundIds = Instance.new("TextBox")
	local Default = Instance.new("TextButton")
	local Credits = Instance.new("TextLabel")
	local Title = Instance.new("TextLabel")
	local Swap = Instance.new("ImageButton")
	local PlayBackSpeed = Instance.new("TextBox")
	local Volume = Instance.new("TextBox")
	local Looped = Instance.new("TextBox")
	local Exit = Instance.new("ImageButton")
	local Frame2 = Instance.new("Frame")
	local Open = Instance.new("ImageButton")
	local spoky = Instance.new("Sound")
	local c00lflag = Instance.new("Sound")
	local drag = Instance.new("UIDragDetector")
	drag.Parent = Frame
	c00lflag.Name = "c00lsound23sas"
	c00lflag.Parent = Frame
	spoky.Parent = Frame
	spoky.SoundId = "rbxassetid://95156028272944"
	spoky.Volume = 3
	spoky.PlaybackSpeed = 0.2
	spoky.Name = "spoky"
	--Properties:

	SoundGui.Name = "SoundGui"
	SoundGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	SoundGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	SoundGui.ResetOnSpawn = false

	Frame.Parent = SoundGui
	Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BorderColor3 = Color3.fromRGB(255, 0, 4)
	Frame.BorderSizePixel = 2
	Frame.Position = UDim2.new(0, 700, 0, 300)
	Frame.Size = UDim2.new(0, 398, 0, 206)

	AddSoundId.Name = "AddSoundId"
	AddSoundId.Parent = Frame
	AddSoundId.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	AddSoundId.BorderColor3 = Color3.fromRGB(255, 0, 0)
	AddSoundId.BorderSizePixel = 2
	AddSoundId.Position = UDim2.new(0.118090451, 0, 0.718446612, 0)
	AddSoundId.Size = UDim2.new(0, 307, 0, 36)
	AddSoundId.Font = Enum.Font.Arial
	AddSoundId.Text = "Add Sound!"
	AddSoundId.TextColor3 = Color3.fromRGB(255, 255, 255)
	AddSoundId.TextSize = 29.000

	SoundIds.Name = "SoundIds"
	SoundIds.Parent = Frame
	SoundIds.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	SoundIds.BorderColor3 = Color3.fromRGB(255, 0, 0)
	SoundIds.BorderSizePixel = 2
	SoundIds.Position = UDim2.new(0.118090451, 0, 0.305825233, 0)
	SoundIds.Size = UDim2.new(0, 307, 0, 33)
	SoundIds.Font = Enum.Font.Arial
	SoundIds.PlaceholderText = "Add a sound ID here!, No rbx://"
	SoundIds.Text = ""
	SoundIds.TextColor3 = Color3.fromRGB(255, 255, 255)
	SoundIds.TextScaled = true
	SoundIds.TextSize = 14.000
	SoundIds.TextWrapped = true

	Default.Name = "Default"
	Default.Parent = Frame
	Default.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Default.BorderColor3 = Color3.fromRGB(255, 0, 0)
	Default.BorderSizePixel = 2
	Default.Position = UDim2.new(0.118090451, 0, 0.529126227, 0)
	Default.Size = UDim2.new(0, 307, 0, 28)
	Default.Font = Enum.Font.Arial
	Default.Text = "Spooky Scary Skeletons!"
	Default.TextColor3 = Color3.fromRGB(255, 255, 255)
	Default.TextSize = 23.000

	Credits.Name = "Credits"
	Credits.Parent = Frame
	Credits.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Credits.BackgroundTransparency = 1.000
	Credits.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Credits.BorderSizePixel = 0
	Credits.Position = UDim2.new(0.577889442, 0, 0.9174757, 0)
	Credits.Size = UDim2.new(0, 153, 0, 17)
	Credits.Font = Enum.Font.SourceSans
	Credits.Text = "made by: 1known. On discord!"
	Credits.TextColor3 = Color3.fromRGB(255, 255, 255)
	Credits.TextSize = 14.000

	Title.Name = "Title"
	Title.Parent = Frame
	Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Title.BackgroundTransparency = 1.000
	Title.BorderColor3 = Color3.fromRGB(255, 0, 4)
	Title.BorderSizePixel = 2
	Title.Position = UDim2.new(0.208542719, 0, 0.0291262139, 0)
	Title.Size = UDim2.new(0, 231, 0, 48)
	Title.Font = Enum.Font.Arial
	Title.Text = "c00lSound GUI!"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 33.000
	Title.TextWrapped = true

	Swap.Name = "Swap"
	Swap.Parent = Frame
	Swap.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Swap.BorderColor3 = Color3.fromRGB(255, 0, 0)
	Swap.BorderSizePixel = 0
	Swap.Position = UDim2.new(0.904522598, 0, 0.33495146, 0)
	Swap.Size = UDim2.new(0, 23, 0, 21)
	Swap.Image = "rbxassetid://2500573769"

	PlayBackSpeed.Name = "PlayBackSpeed"
	PlayBackSpeed.Parent = Frame
	PlayBackSpeed.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	PlayBackSpeed.BorderColor3 = Color3.fromRGB(255, 0, 0)
	PlayBackSpeed.BorderSizePixel = 2
	PlayBackSpeed.Position = UDim2.new(0.118090451, 0, 0.305825233, 0)
	PlayBackSpeed.Size = UDim2.new(0, 307, 0, 33)
	PlayBackSpeed.Visible = false
	PlayBackSpeed.Font = Enum.Font.Arial
	PlayBackSpeed.PlaceholderText = "Playback speed, Enter a number!"
	PlayBackSpeed.Text = "1"
	PlayBackSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
	PlayBackSpeed.TextScaled = true
	PlayBackSpeed.TextSize = 14.000
	PlayBackSpeed.TextWrapped = true

	Volume.Name = "Volume"
	Volume.Parent = Frame
	Volume.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Volume.BorderColor3 = Color3.fromRGB(255, 0, 0)
	Volume.BorderSizePixel = 2
	Volume.Position = UDim2.new(0.118090451, 0, 0.305825233, 0)
	Volume.Size = UDim2.new(0, 307, 0, 33)
	Volume.Visible = false
	Volume.Font = Enum.Font.Arial
	Volume.PlaceholderText = "Volume! Enter a number."
	Volume.Text = "0.5"
	Volume.TextColor3 = Color3.fromRGB(255, 255, 255)
	Volume.TextScaled = true
	Volume.TextSize = 14.000
	Volume.TextWrapped = true

	Looped.Name = "Looped"
	Looped.Parent = Frame
	Looped.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Looped.BorderColor3 = Color3.fromRGB(255, 0, 0)
	Looped.BorderSizePixel = 2
	Looped.Position = UDim2.new(0.118090451, 0, 0.305825233, 0)
	Looped.Size = UDim2.new(0, 307, 0, 33)
	Looped.Visible = false
	Looped.Font = Enum.Font.Arial
	Looped.PlaceholderText = "Is it looped?, Type: False or True"
	Looped.Text = "False"
	Looped.TextColor3 = Color3.fromRGB(255, 255, 255)
	Looped.TextScaled = true
	Looped.TextSize = 14.000
	Looped.TextWrapped = true

	Exit.Name = "Exit"
	Exit.Parent = Frame
	Exit.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Exit.BorderColor3 = Color3.fromRGB(255, 0, 0)
	Exit.BorderSizePixel = 2
	Exit.Position = UDim2.new(0.921999991, 0, 0.0289999992, 0)
	Exit.Size = UDim2.new(0, 25, 0, 23)
	Exit.Image = "rbxassetid://14930908086"

	Frame2.Name = "Frame2"
	Frame2.Parent = SoundGui
	Frame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Frame2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame2.BorderSizePixel = 0
	Frame2.Position = UDim2.new(0.984443069, 0, 0.841666639, 0)
	Frame2.Size = UDim2.new(0, 25, 0, 23)
	Frame2.Visible = false

	Open.Name = "Open"
	Open.Parent = Frame2
	Open.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Open.BorderColor3 = Color3.fromRGB(255, 0, 0)
	Open.BorderSizePixel = 2
	Open.Position = UDim2.new(-0.0312646478, 0, -0.0113339629, 0)
	Open.Size = UDim2.new(0, 25, 0, 23)
	Open.Image = "rbxassetid://14930908086"

	-- Scripts:

	local function GSSVM_fake_script() -- AddSoundId.LocalScript 
		local script = Instance.new('LocalScript', AddSoundId)

		local parent = script.Parent

		parent.Activated:Connect(function()
			local SoundId = parent.Parent:WaitForChild("SoundIds").Text
			local Playbackspeed = parent.Parent:WaitForChild("PlayBackSpeed").Text
			local Volume = parent.Parent:WaitForChild("Volume").Text
			local looped = parent.Parent:WaitForChild("Looped").Text
			if SoundId == "" then
				parent.Text = "No Sound ID!"
				wait(2)
				parent.Text = "Add Sound!"
				return
			end

			local id = "rbxassetid://" .. SoundId
			local speed = tonumber(Playbackspeed) or 1
			local existingSound = game.Workspace:FindFirstChild("c00lsound23sas")

			if existingSound then
				existingSound.SoundId = id
				existingSound.PlaybackSpeed = speed
				existingSound.Volume = Volume
				if looped == "False" then
					existingSound.Looped = false
				elseif looped == "True"	then
					existingSound.Looped = true
				else
					existingSound.Looped = false
				end
				existingSound:Play()
			else
				local clonedSound = parent.Parent.c00lsound23sas:Clone()
				clonedSound.Parent = game.Workspace
				clonedSound.SoundId = id
				clonedSound.PlaybackSpeed = speed
				clonedSound.Volume = Volume
				if looped == "False" then
					clonedSound.Looped = false
				elseif looped == "True"	then
					clonedSound.Looped = true
				else
					clonedSound.Looped = false
				end
				clonedSound.Looped = looped

				clonedSound:Play()
			end

			parent.Text = "Injected Sound Succesfully!, Be sure to enter a correct ID if it doesnt work!"
			parent.TextScaled = true
			wait(3.5)
			parent.TextScaled = false
			parent.Text = "Add Sound!"
		end)

	end
	coroutine.wrap(GSSVM_fake_script)()
	local function MWUVEW_fake_script() -- Default.LocalScript 
		local script = Instance.new('LocalScript', Default)

		local parent = script.Parent
		local sound = parent.Parent.spoky

		parent.Activated:Connect(function()
			if sound.Playing == true then
				sound.Playing = false
			else
				sound.Playing = true
			end
		end)
	end
	coroutine.wrap(MWUVEW_fake_script)()
	local function BIKZQ_fake_script() -- Swap.LocalScript 
		local script = Instance.new('LocalScript', Swap)

		local parent = script.Parent
		local playback = parent.Parent.PlayBackSpeed
		local Sound = parent.Parent.SoundIds
		local volume = parent.Parent.Volume
		local looped = parent.Parent.Looped
		parent.Activated:Connect(function()
			if Sound.Visible == true then
				Sound.Visible = false
				playback.Visible = true
				volume.Visible = false
				looped.Visible = false

			elseif playback.Visible ==true then
				playback.Visible = false
				Sound.Visible = false
				volume.Visible = true
				looped.Visible = false

			elseif volume.Visible == true then
				Sound.Visible = false
				playback.Visible = false
				volume.Visible = false
				looped.Visible = true
			elseif looped.Visible == true then
				Sound.Visible = true
				playback.Visible = false
				volume.Visible = false
				looped.Visible = false
			end
		end)
	end
	coroutine.wrap(BIKZQ_fake_script)()
	local function AXYPXC_fake_script() -- Exit.LocalScript 
		local script = Instance.new('LocalScript', Exit)

		local parent = script.Parent
		local main = parent.Parent

		parent.Activated:Connect(function()
			main.Parent.Frame2.Visible = true
			main.Visible = false

		end)
	end
	coroutine.wrap(AXYPXC_fake_script)()
	local function WHTXC_fake_script() -- Open.LocalScript 
		local script = Instance.new('LocalScript', Open)

		local parent = script.Parent
		local main = parent.Parent.Parent.Frame

		parent.Activated:Connect(function()
			main.Visible = true
			parent.Parent.Visible = false
		end)
	end
	coroutine.wrap(WHTXC_fake_script)()
end, "General", "NOT FE")
FunctionManager:register("Bind Key", function()
	if bindFrame then return end 

	local gui = Player:FindFirstChild("PlayerGui"):FindFirstChild(die)
	if not gui then NotifyERROR("Gui not found!"); return end
	screenGui = gui

	bindFrame = Instance.new("Frame")
	bindFrame.Name = generate_string(math_random(1, 10))
	bindFrame.Size = UDim2.new(1,0,1,0)
	bindFrame.BackgroundColor3 = Color3.new(0,0,0)
	bindFrame.BackgroundTransparency = 0.5
	bindFrame.ZIndex = 50
	bindFrame.Parent = screenGui

	local panel = Instance.new("Frame")
	panel.Name = generate_string(math_random(1, 10))
	panel.Size = UDim2.new(0, 300, 0, 400)
	panel.Position = UDim2.new(0.5, -150, 0.5, -200)
	panel.BackgroundColor3 = Color3.fromRGB(35,35,35)
	panel.BorderSizePixel = 0
	panel.ZIndex = 51
	panel.Parent = bindFrame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 60, 0, 24)
	closeBtn.Position = UDim2.new(1, -64, 0, 4)
	closeBtn.Text = "Close"
	closeBtn.Font = Enum.Font.SourceSansBold
	closeBtn.TextSize = 14
	closeBtn.BackgroundColor3 = Color3.fromRGB(150,50,50)
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.ZIndex = 52
	closeBtn.Parent = panel
	closeBtn.MouseButton1Click:Connect(function()
		bindFrame:Destroy()
		bindFrame = nil
		if bindConn then bindConn:Disconnect(); bindConn = nil end
	end)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -8, 0, 24)
	title.Position = UDim2.new(0, 4, 0, 4)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 18
	title.TextColor3 = Color3.new(1,1,1)
	title.Text = "Bind Key to Function"
	title.ZIndex = 52
	title.Parent = panel

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -8, 1, -40)
	list.Position = UDim2.new(0, 4, 0, 32)
	list.CanvasSize = UDim2.new(0,0,0,0)
	list.ScrollBarThickness = 6
	list.ZIndex = 51
	list.Parent = panel

	local uiList = Instance.new("UIListLayout")
	uiList.Padding = UDim.new(0,4)
	uiList.SortOrder = Enum.SortOrder.LayoutOrder
	uiList.Parent = list

	local function refreshList()
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end

		for _, cat in ipairs(FunctionManager.Categories) do
			local hdr = Instance.new("TextLabel")
			hdr.Size = UDim2.new(1,0,0,24)
			hdr.BackgroundTransparency = 1
			hdr.Font = Enum.Font.SourceSansBold
			hdr.TextSize = 16
			hdr.TextColor3 = Color3.new(1,1,0)
			hdr.Text = "["..cat.."]"
			hdr.ZIndex = 51
			hdr.Parent = list

			for name, cb in pairs(FunctionManager:getFunctionsInCategory(cat)) do
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1,0,0,24)
				btn.Font = Enum.Font.SourceSans
				btn.TextSize = 14
				btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
				btn.TextColor3 = Color3.new(1,1,1)
				btn.ZIndex = 51

				local bound = {}
				for key, fn in pairs(customBinds) do
					if fn == cb then table.insert(bound, tostring(key)) end
				end
				local suffix = #bound>0 and " ("..table.concat(bound, ",")..")" or ""
				btn.Text = name..suffix
				btn.Parent = list

				btn.MouseButton1Click:Connect(function()
					waitingBindFunction = { cb = cb, btn = btn, name = name }
					btn.Text = name.." → [Press a key]"
				end)
			end
		end

		list.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 8)
	end
	bindConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not waitingBindFunction then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			customBinds[input.KeyCode] = waitingBindFunction.cb
			waitingBindFunction.btn.Text = waitingBindFunction.name.." ("..tostring(input.KeyCode)..")"
			waitingBindFunction = nil
		end
	end)
	refreshList()

end, "Utility", "BUGGED")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		local fn = customBinds[input.KeyCode]
		if fn and type(fn) == "function" then
			pcall(fn)
		end
	end
end)
FunctionManager:register("JumpUp", function()
	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.Velocity = Vector3.new(0, 100, 0) end
end, "Movement", "Leap into the air!")


FunctionManager:register("Sit", function()
	local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.Sit = true end
end, "Movement", "SIT DOWN")


FunctionManager:register("INF JUMP", function()
	infJumpEnabled = not infJumpEnabled

	if infJumpEnabled then
		local debounce = false

		infJumpConnection = UserInputService.JumpRequest:Connect(function()
			if debounce then return end
			debounce = true

			local character = Player.Character
			local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end

			task.wait()
			debounce = false
		end)
	else
		if infJumpConnection then
			infJumpConnection:Disconnect()
			infJumpConnection = nil
		end
	end
end, "Movement", "Jump Forever!")

FunctionManager:register("WalkSpeed Slider", function()
	if screenGui:FindFirstChild("WalkSpeedModal") then return end


	local overlay = Instance.new("Frame")
	overlay.Name               = "WalkSpeedModal"
	overlay.Size               = UDim2.new(1,0,1,0)
	overlay.Position           = UDim2.new(0,0,0,0)
	overlay.BackgroundColor3   = Color3.new(0,0,0)
	overlay.BackgroundTransparency = 0.5
	overlay.ZIndex             = 50
	overlay.Parent             = screenGui

	local panel = Instance.new("Frame")
	panel.Name                  = "SliderPanel"
	panel.Size                  = UDim2.new(0, 300, 0, 100)
	panel.Position              = UDim2.new(0.5, -150, 0.5, -50)
	panel.BackgroundColor3      = Color3.fromRGB(40,40,40)
	panel.BorderSizePixel       = 0
	panel.ZIndex                = 51
	panel.Parent                = overlay

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name               = "Close"
	closeBtn.Size               = UDim2.new(0,60,0,24)
	closeBtn.Position           = UDim2.new(1,-64,0,4)
	closeBtn.Font               = Enum.Font.SourceSansBold
	closeBtn.TextSize           = 14
	closeBtn.Text               = "Close"
	closeBtn.BackgroundColor3   = Color3.fromRGB(150,50,50)
	closeBtn.TextColor3         = Color3.new(1,1,1)
	closeBtn.ZIndex             = 52
	closeBtn.Parent             = panel
	closeBtn.MouseButton1Click:Connect(function()
		overlay:Destroy()
	end)

	local label = Instance.new("TextLabel")
	label.Name                  = "ValueLabel"
	label.Size                  = UDim2.new(1,-8,0,24)
	label.Position              = UDim2.new(0,4,0,4)
	label.BackgroundTransparency= 1
	label.Font                  = Enum.Font.SourceSansBold
	label.TextSize              = 18
	label.TextColor3            = Color3.new(1,1,1)
	label.Text                  = "WalkSpeed: " .. tostring(Humanoid.WalkSpeed)
	label.ZIndex                = 52
	label.Parent                = panel

	local track = Instance.new("Frame")
	track.Name                  = "Track"
	track.Size                  = UDim2.new(1,-16,0,20)
	track.Position              = UDim2.new(0,8,0,40)
	track.BackgroundColor3      = Color3.fromRGB(60,60,60)
	track.BorderSizePixel       = 0
	track.ZIndex                = 51
	track.Parent                = panel

	local fill = Instance.new("Frame")
	fill.Name                   = "Fill"
	fill.Size                   = UDim2.new(
		math.clamp((Humanoid.WalkSpeed - 8)/(100-8),0,1), 0,
		1, 0
	)
	fill.BackgroundColor3       = Color3.fromRGB(100,200,100)
	fill.BorderSizePixel        = 0
	fill.ZIndex                 = 52
	fill.Parent                 = track

	local dragging = false
	local minS, maxS = 8, 100

	local function update(x)
		local rel = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0,1)
		local v = math.floor(minS + (maxS-minS)*rel)
		Humanoid.WalkSpeed = v
		label.Text = "WalkSpeed: "..v
		fill.Size = UDim2.new(rel,0,1,0)
	end

	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			update(i.Position.X)
		end
	end)
	track.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
			update(i.Position.X)
		end
	end)
end, "Movement", "Control your walkspeed!")



FunctionManager:register("Server Hop", function()
	local success, res = pcall(function()
		return game:HttpGet(
			"https://games.roblox.com/v1/games/" ..
				PlaceId ..
				"/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
		)
	end)

	if not success then
		return NotifyERROR("[Server Hop] HTTP request failed")
	end

	local body
	local ok, err = pcall(function()
		body = HttpService:JSONDecode(res)
	end)
	if not ok or type(body) ~= "table" or type(body.data) ~= "table" then
		return NotifyERROR("[Server Hop] Invalid JSON response")
	end

	local servers = {}
	for _, v in ipairs(body.data) do
		if type(v) == "table"
			and tonumber(v.playing)
			and tonumber(v.maxPlayers)
			and v.playing < v.maxPlayers
			and v.id ~= JobId then
			table.insert(servers, v.id)
		end
	end

	if #servers == 0 then
		return NotifyERROR("[Server Hop] No available servers found")
	end

	local choice = servers[math.random(1, #servers)]
	TeleportService:TeleportToPlaceInstance(PlaceId, choice, Players.LocalPlayer)
end, "Utility","Changes Servers")

FunctionManager:register("TP Behind Closest", function()

	if not  HRP then
		NotifyERROR("No HumanoidRootPart found.")
		return
	end

	local closestPlayer
	local shortestDistance = math.huge


	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= Player and otherPlayer.Character then
			local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local distance = (otherRoot.Position - HRP.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					closestPlayer = otherPlayer
				end
			end
		end
	end

	if closestPlayer and closestPlayer.Character then
		local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
		if targetRoot then
			local behindPosition = targetRoot.CFrame.Position - targetRoot.CFrame.LookVector * 3
			local newCFrame = CFrame.new(behindPosition, targetRoot.Position) 
			HRP.CFrame = newCFrame
		end
	else
		NotifyERROR("No nearby player found.")
	end
end, "Movement", "Owai moi, shinderu. NANI?")
FunctionManager:register("Scare Closest Player", function()

	if not HRP then
		NotifyERROR("Could not find your HumanoidRootPart.")
		return
	end

	local closestPlayer, closestDistance = nil, math.huge
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= Player and otherPlayer.Character then
			local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local dist = (otherRoot.Position - HRP.Position).Magnitude
				if dist < closestDistance then
					closestDistance = dist
					closestPlayer = otherPlayer
				end
			end
		end
	end

	if closestPlayer and closestPlayer.Character then
		local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
		if targetRoot then
			local oldPos = HRP.CFrame
			HRP.CFrame = targetRoot.CFrame + targetRoot.CFrame.lookVector * 2
			HRP.CFrame = CFrame.new(HRP.Position, targetRoot.Position)
			task.wait(0.5)
			HRP.CFrame = oldPos
		end
	else
		NotifyERROR("No target player nearby.")
	end
end, "Fun", "FNAF reference")
FunctionManager:register("ESP Toggle", function()
	espOn = not espOn
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and plr ~= Player then
			local head = plr.Character:FindFirstChild("Head")
			if head then
				local bb = head:FindFirstChild("ESP") or Instance.new("BillboardGui", head)
				bb.Name = "ESP"
				bb.Size = UDim2.new(0,80,0,20)
				bb.AlwaysOnTop = true
				local lbl = bb:FindFirstChild("Name") or Instance.new("TextLabel", bb)
				lbl.Name = "Name"
				lbl.BackgroundTransparency = 1
				lbl.Size = UDim2.new(1,0,1,0)
				lbl.TextColor3 = Color3.new(1,0,0)
				lbl.TextScaled = true
				lbl.Text = plr.Name
				bb.Enabled = espOn
			end
		end
	end
	Notify("ESP " .. (espOn and "Enabled" or "Disabled"), "SYSTEM", 3)
end, "Visual", "ur cooked i just got wallhacks")
FunctionManager:register("JumpPowerSlider", function()
	if screenGui:FindFirstChild("JumpPowerModal") then return end
	Humanoid.UseJumpPower = true
	local overlay = Instance.new("Frame")
	overlay.Name               = "JumpPowerModal"
	overlay.Size               = UDim2.new(1,0,1,0)
	overlay.Position           = UDim2.new(0,0,0,0)
	overlay.BackgroundColor3   = Color3.new(0,0,0)
	overlay.BackgroundTransparency = 0.5
	overlay.ZIndex             = 50
	overlay.Parent             = screenGui


	local panel = Instance.new("Frame")
	panel.Name                  = "JumpPanel"
	panel.Size                  = UDim2.new(0, 300, 0, 100)
	panel.Position              = UDim2.new(0.5, -150, 0.5, -50)
	panel.BackgroundColor3      = Color3.fromRGB(40,40,40)
	panel.BorderSizePixel       = 0
	panel.ZIndex                = 51
	panel.Parent                = overlay


	local closeBtn = Instance.new("TextButton")
	closeBtn.Name               = "Close"
	closeBtn.Size               = UDim2.new(0,60,0,24)
	closeBtn.Position           = UDim2.new(1,-64,0,4)
	closeBtn.Font               = Enum.Font.SourceSansBold
	closeBtn.TextSize           = 14
	closeBtn.Text               = "Close"
	closeBtn.BackgroundColor3   = Color3.fromRGB(150,50,50)
	closeBtn.TextColor3         = Color3.new(1,1,1)
	closeBtn.ZIndex             = 52
	closeBtn.Parent             = panel
	closeBtn.MouseButton1Click:Connect(function()
		overlay:Destroy()
	end)


	local label = Instance.new("TextLabel")
	label.Name                  = "ValueLabel"
	label.Size                  = UDim2.new(1,-8,0,24)
	label.Position              = UDim2.new(0,4,0,4)
	label.BackgroundTransparency= 1
	label.Font                  = Enum.Font.SourceSansBold
	label.TextSize              = 18
	label.TextColor3            = Color3.new(1,1,1)
	label.Text                  = "JumpPower: " .. tostring(Humanoid.JumpPower)
	label.ZIndex                = 52
	label.Parent                = panel


	local track = Instance.new("Frame")
	track.Name                  = "Track"
	track.Size                  = UDim2.new(1,-16,0,20)
	track.Position              = UDim2.new(0,8,0,40)
	track.BackgroundColor3      = Color3.fromRGB(60,60,60)
	track.BorderSizePixel       = 0
	track.ZIndex                = 51
	track.Parent                = panel

	local fill = Instance.new("Frame")
	fill.Name                   = "Fill"
	fill.Size                   = UDim2.new(
		math.clamp((Humanoid.JumpPower - 50)/(200-50),0,1), 0,
		1, 0
	)
	fill.BackgroundColor3       = Color3.fromRGB(100,200,100)
	fill.BorderSizePixel        = 0
	fill.ZIndex                 = 52
	fill.Parent                 = track


	local dragging = false
	local minJ, maxJ = 50, 200

	local function update(x)
		local rel = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0,1)
		local v = math.floor(minJ + (maxJ-minJ)*rel)
		Humanoid.JumpPower = v
		label.Text = "JumpPower: "..v
		fill.Size = UDim2.new(rel,0,1,0)
	end

	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			update(i.Position.X)
		end
	end)
	track.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
			update(i.Position.X)
		end
	end)
end, "Movement", "Control your jumppower")



FunctionManager:register("Spin Bot", function()
	spinOn = not spinOn
	if spinOn then
		if not HRP then return NotifyERROR("No HRP!") end


		lockBP = Instance.new("BodyPosition")
		lockBP.Name = "SpinLockBP"
		lockBP.Position = HRP.Position
		lockBP.MaxForce = Vector3.new(1e6, 1e6, 1e6)
		lockBP.P = 1e5
		lockBP.D = 0
		lockBP.Parent = HRP


		spinBAV = Instance.new("BodyAngularVelocity")
		spinBAV.Name = "SpinBAV"
		spinBAV.AngularVelocity = Vector3.new(0, 10000, 0) 
		spinBAV.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
		spinBAV.P = 1e5
		spinBAV.Parent = HRP

		NotifyERROR("Spin Bot On")
	else
		if spinBAV then
			spinBAV:Destroy()
			spinBAV = nil
		end
		if lockBP then
			lockBP:Destroy()
			lockBP = nil
		end
		NotifyERROR("Spin Bot Off")
	end
end, "Visual", "Speeeeen")

FunctionManager:register("TP To Mouse", function()
	local character = Player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	if not (root and camera and Mouse) then
		return NotifyERROR("Mouse or character unavailable")
	end
	local currentRay = camera:ScreenPointToRay(Mouse.X, Mouse.Y)
	local currentHit, currentPos = workspace:FindPartOnRay(currentRay, character)
	if currentHit then
		root.CFrame = CFrame.new(currentPos + Vector3.new(0, 3, 0))
		warn("Teleported to mouse")
	else
		NotifyERROR("No target under mouse")
	end
end, "Movement", "Teleport to the current mouse position")
FunctionManager:register("Save Position", function()
	savedCFrame = HRP.CFrame
	Notify("Position Saved", "SYSTEM", 3)
end, "Utility", "Checkpoint")
FunctionManager:register("Load Position", function()
	if savedCFrame then
		HRP.CFrame = savedCFrame
		Notify("Position Loaded", "SYSTEM", 3)
	else
		NotifyERROR("No Position Saved")
	end
end, "Utility", "Reload")


FunctionManager:register("No‑Clip", function()
	noclipOn = not noclipOn

	if noclipOn then
		hoverHeight = HRP.Position.Y

		while noclipOn == true do
			task.wait(0.01)
		
			for _, part in ipairs(Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end

			local pos = HRP.Position
			HRP.CFrame = CFrame.new(pos.X, hoverHeight, pos.Z)
		end

		Notify("No‑Clip ON (locked at height)", "SYSTEM", 3)
	else
		for _, part in ipairs(Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
		Notify("No‑Clip OFF", "SYSTEM", 3)
	end
end, "Movement", "NOCLIP")

FunctionManager:register("DarkDex", function()
	--Maybe works?
	loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua", true))()	
end, "General", "Take a peek under the hood")
FunctionManager:register("SimpleSpy", function()
	--also maybe works?
	loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
end, "Catch remotes")
FunctionManager:register("Orbit All Nearby Parts", function()
	local radius = 20
	local height = 3
	local orbitSpeed = 2

	local speaker = Players.LocalPlayer
	local character = speaker.Character or speaker.CharacterAdded:Wait()
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		NotifyERROR("No HumanoidRootPart found.")
		return
	end

	local origin = root.Position
	local orbitParts = {}

	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(workspace.Terrain) then
			local isInCharacter = false

			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				if char and part:IsDescendantOf(char) then
					isInCharacter = true
					break
				end
			end


			if not isInCharacter and (part.Position - origin).Magnitude <= radius then
				if not CollectionService:HasTag(part, "OrbitPart") then
					if part:CanSetNetworkOwnership() then
						part:SetNetworkOwner(speaker)
					else
						warn("Cannot set network owner for part:", part.Name)
					end
					part.CanCollide = false
					CollectionService:AddTag(part, "OrbitPart")
					table.insert(orbitParts, part)
				end

			end
		end
	end

	if #orbitParts == 0 then
		warn("No parts found for orbit.")
		return
	end

	local angleOffset = 2 * math.pi / #orbitParts

	for i, part in ipairs(orbitParts) do
		local angle = angleOffset * i

		local startPos = root.Position + Vector3.new(
			math.cos(angle) * radius,
			height,
			math.sin(angle) * radius
		)

		part.Position = startPos

		local bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
		bodyGyro.P = 1e4
		bodyGyro.CFrame = CFrame.new(part.Position, root.Position)
		bodyGyro.Parent = part

		local bodyVel = Instance.new("BodyVelocity")
		bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		bodyVel.P = 1e4
		bodyVel.Parent = part

		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not root or not root.Parent then
				conn:Disconnect()
				return
			end

			angle += orbitSpeed * dt

			local orbitCenter = root.Position
			local orbitPoint = orbitCenter + Vector3.new(
				math.cos(angle) * radius,
				height,
				math.sin(angle) * radius
			)

			local tangent = Vector3.new(
				-math.sin(angle),
				0,
				math.cos(angle)
			).Unit * orbitSpeed * radius

			bodyVel.Velocity = tangent
			bodyGyro.CFrame = CFrame.new(part.Position, orbitCenter)
			part.Position = orbitPoint
		end)
	end

	warn("Orbiting", #orbitParts, "parts around you.")
end, "Fun", "You have to be near the parts for a while for it to work")


local function toggleInvisibility()
	if invisRunning then return end
	invisRunning = true

	local player = Players.LocalPlayer
	repeat task.wait(0.1) until player.Character
	local originalChar = player.Character
	originalChar.Archivable = true

	local invisibleChar = originalChar:Clone()
	invisibleChar.Name   = ""
	invisibleChar.Parent = Lighting

	-- clone transparency
	for _, part in ipairs(invisibleChar:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = (part.Name == "HumanoidRootPart") and 1 or 0.5
		end
	end

	-- we’ll need these in nested functions:
	local isInvis = false
	local voidConn, deathConn, steppedConn

	-- Respawn helper (puts you back to originalChar)
	local function Respawn()
		invisRunning = false
		if steppedConn then steppedConn:Disconnect() end
		if deathConn   then deathConn:Disconnect()   end

		player.Character = originalChar
		originalChar.Parent = workspace
		-- destroy the extra humanoid
		local clonedHum = originalChar:FindFirstChildWhichIsA("Humanoid")
		if clonedHum then clonedHum:Destroy() end

		invisibleChar.Parent = nil
	end

	-- fix for falling through the void
	local voidY = workspace.FallenPartsDestroyHeight
	steppedConn = RunService.Stepped:Connect(function()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local y = hrp.Position.Y
		if (voidY < 0 and y <= voidY) or (voidY >= 0 and y >= voidY) then
			Respawn()
		end
	end)

	-- if cloned character dies
	local clonedHum = invisibleChar:FindFirstChildWhichIsA("Humanoid")
	deathConn = clonedHum.Died:Connect(Respawn)

	-- now swap them
	local camCF = workspace.CurrentCamera.CFrame
	local hrpCF = originalChar.HumanoidRootPart.CFrame

	originalChar:MoveTo(Vector3.new(0, math.pi*1e6, 0))
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	task.wait(0.2)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom

	invisibleChar.Parent = workspace
	invisibleChar.HumanoidRootPart.CFrame = hrpCF
	player.Character = invisibleChar

	-- re‑enable animations
	for _, a in ipairs(player.Character:GetDescendants()) do
		if a.Name == "Animate" and a:IsA("Model") then
			a.Disabled = true; a.Disabled = false
		end
	end
	workspace.CurrentCamera:remove()
	wait(.1)
	repeat wait() until player.Character ~= nil
	workspace.CurrentCamera.CameraSubject = player.Character:FindFirstChildWhichIsA('Humanoid')
	workspace.CurrentCamera.CameraType = "Custom"
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 400
	player.CameraMode = "Classic"
	player.Character.Head.Anchored = false
	player.Character.Animate.Enabled = false
	player.Character.Animate.Enabled = true
	Notify("You are now invisible!", "System", 3)
end

FunctionManager:register(
	"Invisible",
	toggleInvisibility,
	"Fun",
	"Make your character invisible until you respawn or die"
)


FunctionManager:register("Fly", function()
	if not HRP then
		warn("No HumanoidRootPart found; cannot fly.")
		return
	end

	flyingEnabled = not flyingEnabled

	if flyingEnabled then

		flyBG = Instance.new("BodyGyro")
		flyBG.P = 9e4
		flyBG.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
		flyBG.CFrame = HRP.CFrame
		flyBG.Parent = HRP


		flyBV = Instance.new("BodyVelocity")
		flyBV.MaxForce = Vector3.new(9e4, 9e4, 9e4)
		flyBV.Velocity = Vector3.new(0, 0, 0)
		flyBV.Parent = HRP

		flyConn = RunService.Heartbeat:Connect(function()
			local camCFrame = workspace.CurrentCamera.CFrame
			local dir = Vector3.new()

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				dir = dir + camCFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				dir = dir - camCFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				dir = dir - camCFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				dir = dir + camCFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				dir = dir + Vector3.new(0, 1, 0)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				dir = dir - Vector3.new(0, 1, 0)
			end

			if dir.Magnitude > 0 then
				dir = dir.Unit * 50
			end
			flyBV.Velocity = dir
			flyBG.CFrame = CFrame.new(HRP.Position, HRP.Position + camCFrame.LookVector)
		end)

	else
		if flyConn then flyConn:Disconnect() flyConn = nil end
		if flyBG then flyBG:Destroy() flyBG = nil end
		if flyBV then flyBV:Destroy() flyBV = nil end


	end
end, "Movement", "Fly around!")

FunctionManager:register("HatHub", function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/inkdupe/hat-scripts/refs/heads/main/updatedhathub.lua"))()
end, "Troll", "Credits to original maker!")
FunctionManager:register("Part Grab", function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/v0c0n1337/scripts/refs/heads/main/Unachored_parts_controller_v2.lua.txt"))()
end, "Troll", "Much better part grab")
FunctionManager:register("Hat Script", function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/ocfi/Scp-096-Obfuscated/refs/heads/main/obuf"))()
end, "Troll", "HATS")



FunctionManager:register("PART ORBIT", function()
	loadstring(game:HttpGet("https://pastebin.com/raw/aZjaAr6F", true))()
end, "Troll", "Probs better orbit")


FunctionManager:register("chat unbanner", function()
	loadstring(game:HttpGet("https://pastebin.com/raw/aDFhvMC4", true))()
end, "Utility", "Credits to the original maker!")
FunctionManager:register("Fling GUI", function()
	loadstring(game:HttpGet("https://pastebin.com/raw/VynRhxJV", true))()
end, "Troll", "Credits to the original maker!")



--init
updateGrid()
    local C00LCLAN_ORDER = {
        'Decal Spam',
        'JOHN DOE',
        'Invis gui',
        'DANCE',
        'Sound GUI',
        'Bind Key',
        'JumpUp',
        'Sit',
        'INF JUMP',
        'WalkSpeed Slider',
        'Server Hop',
        'TP Behind Closest',
        'Scare Closest Player',
        'ESP Toggle',
        'JumpPowerSlider',
        'Spin Bot',
        'TP To Mouse',
        'Save Position',
        'Load Position',
        'No‑Clip',
        'DarkDex',
        'SimpleSpy',
        'Orbit All Nearby Parts',
        'Invisible',
        'Fly',
        'HatHub',
        'Part Grab',
        'Hat Script',
        'PART ORBIT',
        'chat unbanner',
        'Fling GUI',
    }

    NXTroll:CreateSection({name="C00LCLAN V1 FUNCTIONS"})
    local lastCategory = nil
    for _, functionName in ipairs(C00LCLAN_ORDER) do
        local callback = FunctionManager.CategorizedFunctions.All[functionName]
        local category = "General"
        for categoryName, categoryFunctions in pairs(FunctionManager.CategorizedFunctions) do
            if categoryName ~= "All" and categoryFunctions[functionName] then
                category = categoryName
                break
            end
        end
        if category ~= lastCategory then
            NXTroll:CreateSection({name=string.upper(category)})
            lastCategory = category
        end
        local capturedName = functionName
        local capturedCallback = callback
        NXTroll:CreateButton({
            name = capturedName,
            callback = function()
                if type(capturedCallback) ~= "function" then
                    NXNotify("C00LCLAN", "Callback missing: " .. capturedName)
                    return
                end
                local ok, err = pcall(capturedCallback)
                if not ok then
                    NXNotify("C00LCLAN ERROR", capturedName .. ": " .. tostring(err))
                end
            end
        })
    end
    FunctionManager.OnFunctionAdded:Destroy()
end

-- CAMERA
local NXCamera = NXWindow:CreateTab({name="CAMERA", icon="camera"})
NXCamera:CreateSlider({
    name="Field of View",
    range={50,120},
    value=70,
    callback=function(v)
        if workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView=v
        end
    end
})

NXCamera:CreateButton({
    name="EYE / SPECTATE SELECTED",
    callback=function()
        if WatchingTarget then
            RestoreCamera()
            return
        end

        local target = NXGetTarget()
        local hum = target and target.Character
            and target.Character:FindFirstChildOfClass("Humanoid")

        if hum and workspace.CurrentCamera then
            WatchingTarget = target
            workspace.CurrentCamera.CameraSubject = hum
            NXNotify("EYE", "Spectating "..target.Name)
        else
            NXNotify("EYE", "Select an available player")
        end
    end
})

NXCamera:CreateButton({
    name="RESET CAMERA",
    callback=function()
        RestoreCamera()
        if workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView=70
        end
    end
})

-- MOVEMENT
local NXMovement = NXWindow:CreateTab({name="MOVEMENT", icon="move"})
NXMovement:CreateSlider({
    name="WalkSpeed",
    range={16,40},
    value=16,
    callback=function(v)
        local h = NXPlayer.Character and NXPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed=v end
    end
})
NXMovement:CreateSlider({
    name="JumpPower",
    range={25,100},
    value=50,
    callback=function(v)
        local h = NXPlayer.Character and NXPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.UseJumpPower=true h.JumpPower=v end
    end
})

-- VISUALS
local NXVisuals = NXWindow:CreateTab({name="VISUALS", icon="eye"})
NXVisuals:CreateSlider({
    name="Brightness",
    range={0,5},
    value=NXLighting.Brightness,
    callback=function(v) NXLighting.Brightness=v end
})

-- SETTINGS
local NXSettings = NXWindow:CreateTab({name="SETTINGS", icon="settings"})
NXSettings:CreateButton({
    name="PAUSE NOTIFICATION TOGGLE",
    callback=function()
        PauseDisabled = not PauseDisabled
        ApplyPauseState()
    end
})
NXSettings:CreateButton({
    name="UNLOAD",
    callback=function()
        StopFling()
        TouchFlingActive = false
        RestoreCamera()
        pcall(function()
            GuiService:SetGameplayPausedNotificationEnabled(OriginalPauseState)
        end)
        NXWindow:Unload()
    end
})

-- SCRIPT HUB
local NXHub = NXWindow:CreateTab({name="SCRIPT HUB", icon="search"})
NXHub:CreateSection({name="GITHUB SEARCH"})

local NXQuery = ""
local NXSelectedRepo
local NXSelectedScript
local NXAutoExecute = true
local NXRepoMap = {}
local NXScriptMap = {}

NXHub:CreateInput({
    name="SEARCH QUERY",
    placeholder="Search Roblox Lua repositories",
    callback=function(value)
        NXQuery=value
    end
})

local NXRepoDropdown = NXHub:CreateDropdown({
    name="REPOSITORY",
    options={"Search first"},
    value="Search first",
    callback=function(value)
        NXSelectedRepo=NXRepoMap[value]
    end
})

local NXFileDropdown = NXHub:CreateDropdown({
    name="LUA FILE",
    options={"Load repository first"},
    value="Load repository first",
    callback=function(value)
        NXSelectedScript=NXScriptMap[value]
        if NXSelectedScript and NXAutoExecute then
            task.spawn(function()
                local ok,err=pcall(function()
                    local source=game:HttpGet(NXSelectedScript)
                    assert(#source>0,"Empty file")
                    local fn,compileError=loadstring(source)
                    assert(fn,compileError or "Compile failed")
                    fn()
                end)
                if not ok then
                    NXNotify("SCRIPT ERROR", tostring(err):sub(1,180))
                else
                    NXNotify("SCRIPT HUB","Executed")
                end
            end)
        end
    end
})

NXHub:CreateToggle({
    name="AUTO EXECUTE",
    value=true,
    callback=function(v) NXAutoExecute=v end
})

NXHub:CreateButton({
    name="SEARCH GITHUB",
    callback=function()
        if NXQuery:gsub("%s","")=="" then
            NXNotify("GITHUB","Enter a search query")
            return
        end

        local ok,result=pcall(function()
            local q=NXHttp:UrlEncode(NXQuery.." roblox lua")
            return NXHttp:JSONDecode(game:HttpGet(
                "https://api.github.com/search/repositories?q="..
                q.."&sort=stars&order=desc&per_page=10"
            ))
        end)

        if not ok or not result or not result.items then
            NXNotify("GITHUB","Search failed or API rate limit")
            return
        end

        local options={}
        NXRepoMap={}
        NXSelectedRepo=nil

        for _,repo in ipairs(result.items) do
            local label=repo.full_name.." | "..tostring(repo.stargazers_count).." stars"
            NXRepoMap[label]={
                owner=repo.owner.login,
                name=repo.name,
                branch=repo.default_branch
            }
            table.insert(options,label)
        end

        if #options==0 then options={"No repositories found"} end
        NXRepoDropdown:Refresh(options)
        NXNotify("GITHUB","Found "..#result.items.." repositories")
    end
})

NXHub:CreateButton({
    name="LOAD LUA FILES",
    callback=function()
        if not NXSelectedRepo then
            NXNotify("SCRIPT HUB","Select a repository")
            return
        end

        local repo=NXSelectedRepo
        local ok,result=pcall(function()
            local url="https://api.github.com/repos/"..
                repo.owner.."/"..repo.name..
                "/git/trees/"..repo.branch.."?recursive=1"
            return NXHttp:JSONDecode(game:HttpGet(url))
        end)

        if not ok or not result or not result.tree then
            NXNotify("GITHUB","Could not load files")
            return
        end

        local options={}
        NXScriptMap={}
        NXSelectedScript=nil

        for _,item in ipairs(result.tree) do
            if item.type=="blob" and item.path:lower():match("%.lua$")
                and #options<50 then
                local path=item.path
                local raw="https://raw.githubusercontent.com/"..
                    repo.owner.."/"..repo.name.."/"..repo.branch.."/"..path
                NXScriptMap[path]=raw
                table.insert(options,path)
            end
        end

        if #options==0 then options={"No Lua files found"} end
        NXFileDropdown:Refresh(options)
        NXNotify("SCRIPT HUB","Lua files: "..tostring(#NXScriptMap))
    end
})

NXHub:CreateButton({
    name="EXECUTE SELECTED",
    callback=function()
        if not NXSelectedScript then
            NXNotify("SCRIPT HUB","Select a Lua file")
            return
        end
        local ok,err=pcall(function()
            local source=game:HttpGet(NXSelectedScript)
            local fn,compileError=loadstring(source)
            assert(fn,compileError or "Compile failed")
            fn()
        end)
        if not ok then NXNotify("EXECUTION ERROR",tostring(err)) end
    end
})

NXHub:CreateText({
    name="WARNING",
    text="Third-party scripts are untrusted and can perform unwanted actions."
})

NXNotify("NEXBYTE ADMIN","Restored build loaded")
