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
Title.Text = "NEXBYTE'S MULTI-FLING"
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
MainFrame.Size = UDim2.fromOffset(340, 452)
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
Footer.Position = UDim2.new(0, 12, 0, 432)
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

MainFrame.Size = UDim2.fromOffset(340, 452)
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
