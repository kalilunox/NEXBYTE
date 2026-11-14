-- NEXBYTE ULTIMATE ADMIN - Module Manager
--[[
    NEXBYTE ULTIMATE ADMIN
    A comprehensive admin/troll panel for Roblox games.
    Features player selection, server integration, and 100+ functions.
]]
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Player = Players.LocalPlayer

-- Module Manager
local NEXBYTE = {
    _VERSION = "1.0",
    _MODULES = {},
    _SETTINGS = {},
    _PROFILES = {},
    _MACROS = {},
    _LOGS = {},
    _ADMIN_PERMISSIONS = {"fling", "bring", "tp", "tools", "visuals", "movement", "troll"},
    _ACTIVE_MODULES = {},
}

-- Shared state
NEXBYTE._SelectedTargets = {}
NEXBYTE._FlingActive = false
NEXBYTE._TouchFlingActive = false
NEXBYTE._BringActive = false

-- Settings defaults
NEXBYTE._SETTINGS = {
    theme = "Default",
    autosave_profiles = true,
    log_actions = true,
    default_profile = "default",
}

-- Profile system
function NEXBYTE:CreateProfile(name, settings)
    self._PROFILES[name] = settings or {}
    if not self._PROFILES.default then
        self._PROFILES.default = name
    end
end

function NEXBYTE:GetProfile(name)
    return self._PROFILES[name] or self._PROFILES.default and self._PROFILES[self._PROFILES.default] or {}
end

function NEXBYTE:SaveProfile(name)
    local profile = self:GetProfile(name)
    -- In a real implementation, this would save to data store
    if self._SETTINGS.log_actions then
        self:Log("Profile '" .. name .. "' saved", "system")
    end
end

function NEXBYTE:LoadProfile(name)
    local profile = self:GetProfile(name)
    if self._SETTINGS.log_actions then
        self:Log("Profile '" .. name .. "' loaded", "system")
    end
    return profile
end

-- Macro system
function NEXBYTE:CreateMacro(name, commands, delay)
    self._MACROS[name] = {commands = commands, delay = delay or 0, active = false}
end

function NEXBYTE:ExecuteMacro(name)
    local macro = self._MACROS[name]
    if not macro then
        self:Log("Macro '" .. name .. "' not found", "error")
        return false
    end
    macro.active = true
    task.spawn(function()
        while macro.active do
            for _, cmd in ipairs(macro.commands) do
                cmd()
                task.wait(macro.delay)
            end
        end
    end)
    return true
end

function NEXBYTE:StopMacro(name)
    local macro = self._MACROS[name]
    if macro then
        macro.active = false
    end
end

-- Log system
function NEXBYTE:Log(message, level)
    level = level or "info"
    local entry = {time = tick(), message = message, level = level}
    table.insert(self._LOGS, entry)
    -- Keep only last 1000 logs
    if #self._LOGS > 1000 then
        table.remove(self._LOGS, 1)
    end
    -- Print to console
    local level_colors = {info = "green", warning = "yellow", error = "red", system = "white"}
    local color = level_colors[level] or "white"
    print(string.format("[%s] [%s] %s", os.date("%H:%M:%S"), color:upper(), message))
end

-- Module registration system
function NEXBYTE:RegisterModule(name, module_data)
    self._MODULES[name] = module_data
    self._ACTIVE_MODULES[name] = false
    self:Log("Module '" .. name .. "' registered", "system")
    return true
end

function NEXBYTE:ToggleModule(name)
    if self._ACTIVE_MODULES[name] then
        self:DeactivateModule(name)
    else
        self:ActivateModule(name)
    end
end

function NEXBYTE:ActivateModule(name)
    local module = self._MODULES[name]
    if not module then
        self:Log("Module '" .. name .. "' not found", "error")
        return false
    end
    self._ACTIVE_MODULES[name] = true
    if module.on_activate then
        module.on_activate()
    end
    self:Log("Module '" .. name .. "' activated", "system")
    return true
end

function NEXBYTE:DeactivateModule(name)
    local module = self._MODULES[name]
    if not module then
        self:Log("Module '" .. name .. "' not found", "error")
        return false
    end
    self._ACTIVE_MODULES[name] = false
    if module.on_deactivate then
        module.on_deactivate()
    end
    self:Log("Module '" .. name .. "' deactivated", "system")
    return true
end

function NEXBYTE:GetModuleState(name)
    return self._ACTIVE_MODULES[name] or false
end

-- Player selection system
function NEXBYTE:SelectPlayer(player)
    if player and player ~= Player and player:IsA("Player") then
        self._SelectedTargets[player.Name] = player
        self:Log("Player selected: " .. player.Name, "system")
        return true
    end
    return false
end

function NEXBYTE:DeselectPlayer(player)
    if player and self._SelectedTargets[player.Name] then
        self._SelectedTargets[player.Name] = nil
        self:Log("Player deselected: " .. player.Name, "system")
        return true
    end
    return false
end

function NEXBYTE:SelectAllPlayers()
    local selected = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            self._SelectedTargets[p.Name] = p
            selected[p.Name] = true
        end
    end
    self:Log("Selected all " .. #selected .. " players", "system")
    return true
end

function NEXBYTE:DeselectAllPlayers()
    local count = 0
    for name in pairs(self._SelectedTargets) do
        self._SelectedTargets[name] = nil
        count = count + 1
    end
    self:Log("Deselected all " .. count .. " players", "system")
    return true
end

function NEXBYTE:GetSelectedTargets()
    return self._SelectedTargets
end

function NEXBYTE:IsPlayerSelected(player)
    return self._SelectedTargets[player.Name] ~= nil
end

-- Admin check system (placeholder - to be integrated with game's admin system)
function NEXBYTE:HasAdminPermission(permission)
    -- This should be replaced with actual game admin check
    -- For now, returns true for testing
    if permission == "admin_check_placeholder" then
        return true
    end
    -- Check if permission is in the allowed list
    for _, allowed in ipairs(self._ADMIN_PERMISSIONS) do
        if allowed == permission then
            return true
        end
    end
    return false
end

function NEXBYTE:RequestAdminCheck(permission)
    -- Placeholder for server-side admin check
    -- In real implementation, this would fire a RemoteEvent to the server
    return self:HasAdminPermission(permission)
end

-- Confirmation system for dangerous actions
function NEXBYTE:ShowConfirmation(title, text, callback)
    -- Create a simple confirmation UI
    local confirmation = Instance.new("TextButton")
    confirmation.Name = "NEXBYTE_Confirmation"
    confirmation.Size = UDim2.new(0, 200, 0, 100)
    confirmation.Position = UDim2.new(0.5, -100, 0.5, -50)
    confirmation.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    confirmation.BorderSizePixel = 0
    confirmation.Text = text
    confirmation.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmation.Font = Enum.Font.SourceSansBold
    confirmation.TextSize = 18
    confirmation.Parent = game:GetService("CoreGui")

    local function on_click()
        confirmation:Destroy()
        if callback then
            callback(true)
        end
    end

    confirmation.MouseButton1Click:Connect(on_click)

    -- Add auto-dismiss after 5 seconds
    task.delay(5, function()
        if confirmation and confirmation.Parent then
            confirmation:Destroy()
            if callback then
                callback(false)
            end
        end
    end)

    return confirmation
end

-- Remote Lab system for testing game mechanics
function NEXBYTE:RemoteLab()
    local RemoteLab = {}
    RemoteLab._remotes = {}
    RemoteLab._test_results = {}

    function RemoteLab:CreateRemote(name, event_name)
        local remote = {
            name = name,
            event_name = event_name,
            fired = false,
            last_fire = 0,
        }
        self._remotes[name] = remote
        return remote
    end

    function RemoteLab:FireRemote(name, ...)
        local remote = self._remotes[name]
        if not remote then
            self:Log("Remote '" .. name .. "' not found", "error")
            return false
        end
        remote.fired = true
        remote.last_fire = tick()
        -- In real implementation, this would fire the actual RemoteEvent
        self:Log("Remote '" .. name .. "' fired", "system")
        return true
    end

    function RemoteLab:ResetResults(name)
        self._test_results[name] = {}
    end

    function RemoteLab:RecordResult(name, success, message)
        if not self._test_results[name] then
            self._test_results[name] = {}
        end
        table.insert(self._test_results[name], {success = success, message = message, time = tick()})
    end

    function RemoteLab:GetResults(name)
        return self._test_results[name] or {}
    end

    return RemoteLab
end

-- Initialize default modules and profiles
NEXBYTE:CreateProfile("default")

-- Register core modules (will be expanded later)
NEXBYTE:RegisterModule("player_selection", {
    on_activate = function()
        NEXBYTE:Log("Player selection module activated", "system")
    end,
    on_deactivate = function()
        NEXBYTE:Log("Player selection module deactivated", "system")
    end,
})

NEXBYTE:RegisterModule("logging", {
    on_activate = function()
        NEXBYTE:Log("Logging module activated", "system")
    end,
    on_deactivate = function()
        NEXBYTE:Log("Logging module deactivated", "system")
    end,
})

-- Set up player added/removed handling
Players.PlayerAdded:Connect(function(player)
    -- Profiles could track new players
    if NEXBYTE._SETTINGS.log_actions then
        NEXBYTE:Log("Player joined: " .. player.Name, "system")
    end
end)

Players.PlayerRemoved:Connect(function(player)
    NEXBYTE:DeselectPlayer(player)
    if NEXBYTE._SETTINGS.log_actions then
        NEXBYTE:Log("Player left: " .. player.Name, "system")
    end
end)

-- GUI Setup - Main ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NEXBYTE_ULTIMATE_ADMIN"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "NEXBYTE_MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- UI Corner rounding
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "NEXBYTE ULTIMATE ADMIN"
Title.TextColor3 = Color3.fromRGB(0, 195, 235)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.Parent = TitleBar

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Position = UDim2.new(1, -65, 0, 0)
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "_"
MinimizeButton.TextColor3 = Color3.fromRGB(0, 195, 235)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 16
MinimizeButton.Parent = TitleBar

-- Tab System
local Tabs = Instance.new("Frame")
Tabs.Name = "Tabs"
Tabs.Size = UDim2.new(0, 120, 1, -40)
Tabs.Position = UDim2.new(0, 0, 0, 40)
Tabs.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Tabs.BorderSizePixel = 0
Tabs.Parent = MainFrame

local TabList = Instance.new("UIListLayout")
TabList.Parent = Tabs
TabList.Padding = UDim.new(0, 5)

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -120, 1, -40)
ContentArea.Position = UDim2.new(0, 120, 0, 40)
ContentArea.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame

-- Selected Players Display
local SelectedDisplay = Instance.new("TextLabel")
SelectedDisplay.Name = "SelectedDisplay"
SelectedDisplay.Size = UDim2.new(1, 0, 0, 30)
SelectedDisplay.Position = UDim2.new(0, 0, 0, 0)
SelectedDisplay.BackgroundTransparency = 1
SelectedDisplay.Text = "Selected players: 0"
SelectedDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectedDisplay.Font = Enum.Font.GothamMedium
SelectedDisplay.TextSize = 14
SelectedDisplay.Parent = ContentArea

-- Module State Tracker
local ModuleTracker = Instance.new("TextLabel")
ModuleTracker.Name = "ModuleTracker"
ModuleTracker.Size = UDim2.new(1, 0, 0, 20)
ModuleTracker.Position = UDim2.new(0, 0, 0, 35)
ModuleTracker.BackgroundTransparency = 1
ModuleTracker.Text = "Active modules: 0"
ModuleTracker.TextColor3 = Color3.fromRGB(255, 255, 255)
ModuleTracker.Font = Enum.Font.GothamMedium
ModuleTracker.TextSize = 12
ModuleTracker.Parent = ContentArea

-- Tab definitions
local TabsData = {
    {name = "HOME", icon = "house", description = "Main dashboard"},
    {name = "PLAYER", icon = "users", description = "Player selection and control"},
    {name = "FLING", icon = "zap", description = "Fling and throw mechanics"},
    {name = "TELEPORT", icon = "location-on", description = "Teleport and movement"},
    {name = "TROLL", icon = "zap", description = "Trolling tools"},
    {name = "VISUALS", icon = "eye", description = "Visual effects"},
    {name = "MOVEMENT", icon = "move", description = "Movement settings"},
    {name = "CAMERA", icon = "camera", description = "Camera controls"},
    {name = "SCRIPT HUB", icon = "search", description = "Script execution"},
    {name = "MODULES", icon = "grid", description = "Module Manager"},
    {name = "PROFILES", icon = "star", description = "Profiles and macros"},
    {name = "SETTINGS", icon = "settings", description = "Application settings"},
    {name = "LOGS", icon = "history", description = "Action logs"},
}

-- Create tabs
local currentTab = nil
local currentContent = nil

function NEXBYTE:CreateTab(tab_name)
    -- Hide current tab if any
    if currentTab then
        currentTab.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    end

    -- Find or create tab
    local tab_btn = nil
    for _, tab_data in ipairs(TabsData) do
        if tab_data.name == tab_name then
            -- Create tab button
            tab_btn = Instance.new("TextButton")
            tab_btn.Name = tab_data.name .. "_Button"
            tab_btn.Size = UDim2.new(1, 0, 0, 30)
            tab_btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
            tab_btn.BorderSizePixel = 0
            tab_btn.Text = tab_data.name .. "  " .. tab_data.description
            tab_btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            tab_btn.Font = Enum.Font.Gotham
            tab_btn.TextSize = 12
            tab_btn.Parent = Tabs
            -- Store reference
            _G["NEXBYTE_Tab_" .. tab_data.name] = tab_btn

            -- Create content area
            local content = Instance.new("Frame")
            content.Name = tab_data.name .. "_Content"
            content.Size = UDim2.new(1, 0, 1, 0)
            content.Position = UDim2.new(0, 0, 0, 0)
            content.BackgroundTransparency = 1
            content.Visible = false
            content.Parent = ContentArea

            -- Store tab data
            _G["NEXBYTE_Content_" .. tab_data.name] = content

            -- Set as active if first tab
            if not currentTab then
                tab_btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                content.Visible = true
                currentTab = tab_btn
                currentContent = content
            end

            -- Add click handler
            tab_btn.MouseButton1Click:Connect(function()
                NEXBYTE:SwitchTab(tab_data.name)
            end)

            return content, tab_btn
        end
    end

    if tab_btn then
        NEXBYTE:SwitchTab(tab_name)
    end
    return nil, nil
end

function NEXBYTE:SwitchTab(tab_name)
    if currentTab then
        currentTab.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    end
    if currentContent then
        currentContent.Visible = false
    end

    -- Find the tab
    for _, tab_data in ipairs(TabsData) do
        if tab_data.name == tab_name then
            local btn = _G["NEXBYTE_Tab_" .. tab_data.name]
            local content = _G["NEXBYTE_Content_" .. tab_data.name]
            if btn and content then
                btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                content.Visible = true
                currentTab = btn
                currentContent = content
            end
            return
        end
    end
end

-- Initialize tabs
for _, tab_data in ipairs(TabsData) do
    NEXBYTE:CreateTab(tab_data.name)
end

-- Select first tab by default
if #TabsData > 0 then
    NEXBYTE:SwitchTab(TabsData[1].name)
end

-- Tab click handlers (redundant but safe)
for _, tab_data in ipairs(TabsData) do
    local btn = _G["NEXBYTE_Tab_" .. tab_data.name]
    if btn then
        btn.MouseButton1Click:Connect(function()
            NEXBYTE:SwitchTab(tab_data.name)
        end)
    end
end

-- Close button handler
CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MinimizeButton.Visible = true
end)

-- Minimize button handler
MinimizeButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    MinimizeButton.Visible = false
end)

-- Update selected players display
local function UpdateSelectedDisplay()
    local count = 0
    for _ in pairs(NEXBYTE._SelectedTargets) do
        count = count + 1
    end
    SelectedDisplay.Text = "Selected players: " .. count
end

-- Update module tracker
local function UpdateModuleTracker()
    local active = 0
    for _ in pairs(NEXBYTE._ACTIVE_MODULES) do
        active = active + 1
    end
    ModuleTracker.Text = "Active modules: " .. active
end

-- Connect update functions
task.spawn(function()
    while true do
        task.wait(1)
        UpdateSelectedDisplay()
        UpdateModuleTracker()
    end
end)

-- PLAYER SECTION - Player selection and control
--[[
    PLAYER MODULE
    Handles player selection, Bring, TP, and other player interactions.
]]
-- Player selection UI (created dynamically)
local function CreatePlayerSelectionUI()
    local PlayerSelection = Instance.new("Frame")
    PlayerSelection.Name = "PlayerSelectionUI"
    PlayerSelection.Size = UDim2.new(1, 0, 1, 0)
    PlayerSelection.Position = UDim2.new(0, 0, 0, 0)
    PlayerSelection.BackgroundTransparency = 1
    PlayerSelection.Visible = false
    PlayerSelection.Parent = ContentArea

    -- Search box
    local SearchBox = Instance.new("TextBox")
    SearchBox.Name = "SearchBox"
    SearchBox.Size = UDim2.new(1, -10, 0, 30)
    SearchBox.Position = UDim2.new(0, 5, 0, 5)
    SearchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    SearchBox.BorderSizePixel = 0
    SearchBox.PlaceholderText = "Search players..."
    SearchBox.Text = ""
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 12
    SearchBox.Parent = PlayerSelection

    -- Player list container
    local PlayerList = Instance.new("ScrollingFrame")
    PlayerList.Name = "PlayerList"
    PlayerList.Size = UDim2.new(1, -10, 1, -40)
    PlayerList.Position = UDim2.new(0, 5, 0, 40)
    PlayerList.BackgroundTransparency = 1
    PlayerList.ScrollBarThickness = 6
    PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
    PlayerList.Parent = PlayerSelection

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = PlayerList
    ListLayout.Padding = UDim.new(0, 5)

    -- Selected count
    local SelectedCount = Instance.new("TextLabel")
    SelectedCount.Name = "SelectedCount"
    SelectedCount.Size = UDim2.new(1, 0, 0, 20)
    SelectedCount.Position = UDim2.new(0, 0, 0, 0)
    SelectedCount.BackgroundTransparency = 1
    SelectedCount.Text = "Selected: 0"
    SelectedCount.TextColor3 = Color3.fromRGB(255, 255, 255)
    SelectedCount.Font = Enum.Font.GothamMedium
    SelectedCount.TextSize = 12
    SelectedCount.Parent = PlayerSelection

    return PlayerSelection, SearchBox, PlayerList, SelectedCount
end

-- Create the player selection UI
local PlayerSelectionUI, SearchBox, PlayerList, SelectedCount = CreatePlayerSelectionUI()

-- Toggle player visibility
local function TogglePlayerVisibility(visible)
    PlayerSelectionUI.Visible = visible
end

-- Refresh player list
function NEXBYTE:RefreshPlayerList()
    -- Clear existing entries
    local list = PlayerList:FindFirstChildOfClass("UIListLayout")
    if list then
        -- Clear children but keep layout
        for _, child in ipairs(PlayerList:GetChildren()) do
            if child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
                child:Destroy()
            end
        end
    end

    -- Get players and sort them
    local players = Players:GetPlayers()
    table.sort(players, function(a, b) return a.Name:lower() < b.Name:lower() end)

    -- Filter by search
    local search_text = SearchBox.Text:lower()

    -- Create entries for each player
    local yPosition = 5
    for _, player in ipairs(players) do
        -- Skip self
        if player ~= Player then
            -- Apply search filter
            if search_text == "" or player.Name:lower():find(search_text) then
                -- Create player entry frame
                local PlayerEntry = Instance.new("Frame")
                PlayerEntry.Name = "PlayerEntry_" .. player.Name
                PlayerEntry.Size = UDim2.new(1, -10, 0, 30)
                PlayerEntry.Position = UDim2.new(0, 5, 0, yPosition)
                PlayerEntry.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                PlayerEntry.BorderSizePixel = 0
                PlayerEntry.Parent = PlayerList

                -- Checkbox
                local Checkbox = Instance.new("TextButton")
                Checkbox.Name = "Checkbox_" .. player.Name
                Checkbox.Size = UDim2.new(0, 24, 0, 24)
                Checkbox.Position = UDim2.new(0, 3, 0.5, -12)
                Checkbox.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
                Checkbox.BorderSizePixel = 0
                Checkbox.Text = ""
                Checkbox.Parent = PlayerEntry

                -- Checkmark
                local Checkmark = Instance.new("TextLabel")
                Checkmark.Name = "Checkmark"
                Checkmark.Size = UDim2.new(1, 0, 1, 0)
                Checkmark.BackgroundTransparency = 1
                Checkmark.Text = "✓"
                Checkmark.TextColor3 = Color3.fromRGB(0, 255, 0)
                Checkmark.TextSize = 14
                Checkmark.Font = Enum.Font.SourceSansBold
                Checkmark.Visible = NEXBYTE:IsPlayerSelected(player)
                Checkmark.Parent = Checkbox

                -- Player name
                local NameLabel = Instance.new("TextLabel")
                NameLabel.Name = "NameLabel"
                NameLabel.Size = UDim2.new(1, -35, 1, 0)
                NameLabel.Position = UDim2.new(0, 30, 0, 0)
                NameLabel.BackgroundTransparency = 1
                NameLabel.Text = player.Name
                NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                NameLabel.TextSize = 12
                NameLabel.Font = Enum.Font.Gotham
                NameLabel.Parent = PlayerEntry

                -- Click handler
                PlayerEntry.MouseButton1Click:Connect(function()
                    if NEXBYTE:IsPlayerSelected(player) then
                        NEXBYTE:DeselectPlayer(player)
                        Checkmark.Visible = false
                    else
                        NEXBYTE:SelectPlayer(player)
                        Checkmark.Visible = true
                    end
                    SelectedCount.Text = "Selected: " .. #NEXBYTE:GetSelectedTargets()
                end)

                yPosition = yPosition + 35
            end
        end
    end

    -- Update canvas size
    PlayerList.CanvasSize = UDim2.new(0, 0, 0, yPosition + 10)

    -- Update selected count
    SelectedCount.Text = "Selected: " .. #NEXBYTE:GetSelectedTargets()
end

-- Add control buttons
local function AddPlayerControls()
    -- Select All button
    local SelectAllBtn = Instance.new("TextButton")
    SelectAllBtn.Name = "SelectAllBtn"
    SelectAllBtn.Size = UDim2.new(0.45, -5, 0, 30)
    SelectAllBtn.Position = UDim2.new(0, 5, 1, -50)
    SelectAllBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    SelectAllBtn.BorderSizePixel = 0
    SelectAllBtn.Text = "SELECT ALL"
    SelectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SelectAllBtn.Font = Enum.Font.GothamBold
    SelectAllBtn.TextSize = 11
    SelectAllBtn.Parent = PlayerSelectionUI

    -- Deselect All button
    local DeselectAllBtn = Instance.new("TextButton")
    DeselectAllBtn.Name = "DeselectAllBtn"
    DeselectAllBtn.Size = UDim2.new(0.45, -5, 0, 30)
    DeselectAllBtn.Position = UDim2.new(0.5, 5, 1, -50)
    DeselectAllBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    DeselectAllBtn.BorderSizePixel = 0
    DeselectAllBtn.Text = "DESELECT ALL"
    DeselectAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DeselectAllBtn.Font = Enum.Font.GothamBold
    DeselectAllBtn.TextSize = 11
    DeselectAllBtn.Parent = PlayerSelectionUI

    -- Copy Names button
    local CopyNamesBtn = Instance.new("TextButton")
    CopyNamesBtn.Name = "CopyNamesBtn"
    CopyNamesBtn.Size = UDim2.new(0.45, -5, 0, 30)
    CopyNamesBtn.Position = UDim2.new(0.5, 5, 1, -50)
    -- This will be repositioned after first render
    CopyNamesBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    CopyNamesBtn.BorderSizePixel = 0
    CopyNamesBtn.Text = "COPY NAMES"
    CopyNamesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyNamesBtn.Font = Enum.Font.GothamBold
    CopyNamesBtn.TextSize = 11
    CopyNamesBtn.Parent = PlayerSelectionUI

    -- Connect handlers
    SelectAllBtn.MouseButton1Click:Connect(function()
        NEXBYTE:SelectAllPlayers()
        NEXBYTE:RefreshPlayerList()
        SelectedCount.Text = "Selected: " .. #NEXBYTE:GetSelectedTargets()
    end)

    DeselectAllBtn.MouseButton1Click:Connect(function()
        NEXBYTE:DeselectAllPlayers()
        NEXBYTE:RefreshPlayerList()
        SelectedCount.Text = "Selected: " .. #NEXBYTE:GetSelectedTargets()
    end)

    -- Function to reposition CopyNamesBtn
    local function RepositionCopyBtn()
        CopyNamesBtn.Position = UDim2.new(0, 5, 1, -50)
    end

    -- Initial reposition
    task.delay(0.1, RepositionCopyBtn)
end

-- Add controls after UI is created
task.delay(0.5, AddPlayerControls)

-- Bring function
function NEXBYTE:BringSelected()
    local selected = NEXBYTE:GetSelectedTargets()
    if #selected == 0 then
        NEXBYTE:Log("No players selected for Bring", "warning")
        return false
    end

    -- Admin check
    if not NEXBYTE:RequestAdminCheck("bring") then
        NEXBYTE:Log("Admin permission denied for Bring", "error")
        return false
    end

    local myChar = Player.Character
    local myRootPart = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if not myRootPart then
        NEXBYTE:Log("Your character is not ready", "error")
        return false
    end

    for _, target in pairs(selected) do
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = target.Character.HumanoidRootPart
            -- Bring player to you (CFrame set to your position)
            targetRoot.CFrame = myRootPart.CFrame
            NEXBYTE:Log("Brought " .. target.Name, "system")
        end
    end

    return true
end

-- TP to selected function
function NEXBYTE:TPToSelected()
    local selected = NEXBYTE:GetSelectedTargets()
    if #selected == 0 then
        NEXBYTE:Log("No players selected for TP", "warning")
        return false
    end

-- Admin check
    if not NEXBYTE:RequestAdminCheck("tp") then
        NEXBYTE:Log("Admin permission denied for TP", "error")
        return false
    end

    local myChar = Player.Character
    local myRootPart = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if not myRootPart then
        NEXBYTE:Log("Your character is not ready", "error")
        return false
    end

    for _, target in pairs(selected) do
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = target.Character.HumanoidRootPart
            -- Teleport to player (3 studs in front)
            myRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            NEXBYTE:Log("TP'd to " .. target.Name, "system")
        end
    end

    return true
end

-- Function to toggle player selection UI
function NEXBYTE:TogglePlayerUI(state)
    if state ~= nil then
        PlayerSelectionUI.Visible = state
    else
        PlayerSelectionUI.Visible = not PlayerSelectionUI.Visible
    end
end

-- Initialize player list display
NEXBYTE:RefreshPlayerList()

-- Return the NEXBYTE module for use in the script
return NEXBYTE
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

-- =========================================================
-- C00LCLAN PORT -> EXISTING NEXBYTE RAYFIELD TROLL TAB
-- Adapted handlers; no second main GUI / no FunctionManager.
-- =========================================================
local NXPortPlayers = game:GetService("Players")
local NXPortRun = game:GetService("RunService")
local NXPortInput = game:GetService("UserInputService")
local NXPortTeleport = game:GetService("TeleportService")
local NXPortHttp = game:GetService("HttpService")
local NXPortLighting = game:GetService("Lighting")
local NXPortCollection = game:GetService("CollectionService")
local NXPortPlayer = NXPlayer
local NXPortMouse = NXPortPlayer:GetMouse()
local NXPortSavedCFrame
local NXPortFlags = {infJump=false, esp=false, spin=false, noclip=false, fly=false, decal=false, orbit=false}
local NXPortConnections = {}
local NXPortObjects = {}

local function NXPortCharacter()
    return NXPortPlayer.Character
end
local function NXPortHumanoid()
    local c = NXPortCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function NXPortRoot()
    local c = NXPortCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function NXPortNearest()
    local root = NXPortRoot()
    if not root then return nil end
    local best, bestDist = nil, math.huge
    for _, p in ipairs(NXPortPlayers:GetPlayers()) do
        if p ~= NXPortPlayer and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (r.Position-root.Position).Magnitude
                if d < bestDist then best, bestDist = p, d end
            end
        end
    end
    return best, bestDist
end
local function NXPortExternal(name, url)
    NXNotify(name, "Загружается сторонний код. Источник не проверен.")
    task.spawn(function()
        local ok, err = pcall(function()
            local src = game:HttpGet(url)
            assert(type(src)=="string" and #src>0, "Пустой ответ")
            local fn, compileErr = loadstring(src)
            assert(fn, compileErr or "Ошибка компиляции")
            fn()
        end)
        if not ok then NXNotify(name, tostring(err):sub(1,180)) end
    end)
end
local function NXPortStopConnection(key)
    local c = NXPortConnections[key]
    if c then pcall(function() c:Disconnect() end); NXPortConnections[key]=nil end
end

NXTroll:CreateSection({name="C00LCLAN • PORTED FEATURES"})
NXTroll:CreateText({name="PORT STATUS", text="31 функции • адаптированы под NEXBYTE Rayfield • отдельное GUI не создаётся"})

-- 01 Decal Spam: bounded local visual pass + cancellable lighting effect.
NXTroll:CreateToggle({name="Decal Spam", value=false, callback=function(v)
    NXPortFlags.decal=v
    if not v then
        NXPortStopConnection("decal")
        for _,obj in ipairs(workspace:GetDescendants()) do if obj:IsA("Decal") and obj.Name=="NX_C00L_DECAL" then obj:Destroy() end end
        NXNotify("DECAL SPAM","OFF"); return
    end
    task.spawn(function()
        local decalId="rbxassetid://8408806737"
        local count=0
        for _,obj in ipairs(workspace:GetDescendants()) do
            if not NXPortFlags.decal or count>=40 then break end
            if obj:IsA("BasePart") then
                for _,face in ipairs(Enum.NormalId:GetEnumItems()) do
                    local d=Instance.new("Decal")
                    d.Name="NX_C00L_DECAL"; d.Texture=decalId; d.Face=face; d.Parent=obj
                end
                count=count+1
            end
        end
        NXNotify("DECAL SPAM","Обработано деталей: "..count)
    end)
    NXPortConnections.decal=NXPortRun.Heartbeat:Connect(function()
        if NXPortFlags.decal then NXPortLighting.Ambient=Color3.new(math.random(),math.random(),math.random()) end
    end)
end})

-- 02 JOHN DOE: local character tag / sky styling, no remote calls.
NXTroll:CreateButton({name="JOHN DOE", callback=function()
    local c=NXPortCharacter(); local head=c and c:FindFirstChild("Head")
    if not head then NXNotify("JOHN DOE","Персонаж не готов"); return end
    local sky=NXPortLighting:FindFirstChildOfClass("Sky") or Instance.new("Sky",NXPortLighting)
    local id="rbxassetid://1012887"
    sky.SkyboxBk=id; sky.SkyboxDn=id; sky.SkyboxFt=id; sky.SkyboxLf=id; sky.SkyboxRt=id; sky.SkyboxUp=id
    local old=head:FindFirstChild("NXJohnDoeTag"); if old then old:Destroy(); NXNotify("JOHN DOE","Тег удалён"); return end
    local bb=Instance.new("BillboardGui"); bb.Name="NXJohnDoeTag"; bb.Size=UDim2.fromOffset(150,40); bb.StudsOffset=Vector3.new(0,2,0); bb.Adornee=head; bb.Parent=head
    local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text="JOHN DOE"; label.TextColor3=Color3.new(1,0,0); label.TextStrokeTransparency=0; label.TextScaled=true; label.Parent=bb
    NXNotify("JOHN DOE","Локальный эффект включён")
end})

-- 03 external invis GUI
NXTroll:CreateButton({name="Invis gui [EXTERNAL]", callback=function() NXPortExternal("Invis gui","https://pastebin.com/raw/3Rnd9rHf") end})

-- 04 Dance
NXTroll:CreateButton({name="DANCE", callback=function()
    local h=NXPortHumanoid(); if not h then return NXNotify("DANCE","Humanoid не найден") end
    local a=Instance.new("Animation"); a.AnimationId="rbxassetid://27789359"
    local ok,track=pcall(function() return h:LoadAnimation(a) end)
    if ok and track then track:Play() else NXNotify("DANCE","Не удалось запустить анимацию") end
end})

-- 05 Sound GUI, compact helper window (not a second hub).
NXTroll:CreateButton({name="Sound GUI", callback=function()
    local pg=NXPortPlayer:WaitForChild("PlayerGui"); local old=pg:FindFirstChild("NEXBYTE_C00L_SOUND")
    if old then old:Destroy(); return end
    local gui=Instance.new("ScreenGui"); gui.Name="NEXBYTE_C00L_SOUND"; gui.ResetOnSpawn=false; gui.Parent=pg
    local frame=Instance.new("Frame"); frame.Size=UDim2.fromOffset(270,150); frame.Position=UDim2.new(.5,-135,.5,-75); frame.BackgroundColor3=Color3.fromRGB(12,22,35); frame.Parent=gui
    local box=Instance.new("TextBox"); box.Size=UDim2.new(1,-16,0,34); box.Position=UDim2.fromOffset(8,8); box.PlaceholderText="Sound ID"; box.Text=""; box.Parent=frame
    local play=Instance.new("TextButton"); play.Size=UDim2.new(1,-16,0,34); play.Position=UDim2.fromOffset(8,50); play.Text="PLAY / UPDATE"; play.Parent=frame
    local close=Instance.new("TextButton"); close.Size=UDim2.new(1,-16,0,28); close.Position=UDim2.fromOffset(8,92); close.Text="CLOSE"; close.Parent=frame
    local snd=Instance.new("Sound"); snd.Name="NEXBYTE_C00L_SOUND_PLAYER"; snd.Volume=.5; snd.Looped=true; snd.Parent=game:GetService("SoundService")
    play.Activated:Connect(function() local id=box.Text:match("%d+"); if id then snd.SoundId="rbxassetid://"..id; snd:Play() else NXNotify("SOUND GUI","Введи числовой Sound ID") end end)
    close.Activated:Connect(function() snd:Destroy(); gui:Destroy() end)
end})

-- 06 Bind Key: press button, then press a key to bind JumpUp.
local NXPortBindWaiting=false
NXTroll:CreateButton({name="Bind Key: JUMPUP", callback=function()
    NXPortBindWaiting=true; NXNotify("BIND KEY","Нажми клавишу на клавиатуре")
end})
NXPortConnections.bindInput=NXPortInput.InputBegan:Connect(function(input, processed)
    if processed then return end
    if NXPortBindWaiting and input.UserInputType==Enum.UserInputType.Keyboard then
        NXPortBindWaiting=false
        NXPortConnections.bindKey=input
        NXNotify("BIND KEY","Назначено: "..input.KeyCode.Name)
    elseif NXPortConnections.bindKey and input.KeyCode==NXPortConnections.bindKey.KeyCode then
        local root=NXPortRoot(); if root then root.AssemblyLinearVelocity=Vector3.new(0,100,0) end
    end
end)

-- 07 JumpUp
NXTroll:CreateButton({name="JumpUp", callback=function()
    local root=NXPortRoot(); if root then root.AssemblyLinearVelocity=Vector3.new(0,100,0) else NXNotify("JumpUp","Персонаж не готов") end
end})
-- 08 Sit
NXTroll:CreateButton({name="Sit", callback=function() local h=NXPortHumanoid(); if h then h.Sit=true end end})
-- 09 Infinite jump
NXTroll:CreateToggle({name="INF JUMP", value=false, callback=function(v)
    NXPortFlags.infJump=v; NXPortStopConnection("infJump")
    if v then NXPortConnections.infJump=NXPortInput.JumpRequest:Connect(function() if NXPortFlags.infJump then local h=NXPortHumanoid(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end) end
end})
-- 10 WalkSpeed slider
NXTroll:CreateSlider({name="WalkSpeed Slider", range={8,100}, value=16, callback=function(v) local h=NXPortHumanoid(); if h then h.WalkSpeed=v end end})
-- 11 Server hop
NXTroll:CreateButton({name="Server Hop", callback=function()
    task.spawn(function()
        local ok,err=pcall(function()
            local url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
            local data=NXPortHttp:JSONDecode(game:HttpGet(url)); local servers={}
            for _,s in ipairs(data.data or {}) do if s.id~=game.JobId and s.playing<s.maxPlayers then table.insert(servers,s.id) end end
            assert(#servers>0,"Нет свободных серверов")
            NXPortTeleport:TeleportToPlaceInstance(game.PlaceId,servers[math.random(1,#servers)],NXPortPlayer)
        end)
        if not ok then NXNotify("SERVER HOP",tostring(err):sub(1,180)) end
    end)
end})
-- 12 TP behind closest
NXTroll:CreateButton({name="TP Behind Closest", callback=function()
    local p=NXPortNearest(); local r=NXPortRoot(); local tr=p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if r and tr then r.CFrame=tr.CFrame*CFrame.new(0,0,3) else NXNotify("TP BEHIND","Игрок не найден") end
end})
-- 13 Scare closest
NXTroll:CreateButton({name="Scare Closest Player", callback=function()
    local p=NXPortNearest(); local r=NXPortRoot(); local tr=p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if not (r and tr) then return NXNotify("SCARE","Игрок не найден") end
    local old=r.CFrame; r.CFrame=tr.CFrame*CFrame.new(0,0,-2); task.delay(.5,function() if r.Parent then r.CFrame=old end end)
end})
-- 14 ESP
NXTroll:CreateToggle({name="ESP Toggle", value=false, callback=function(v)
    NXPortFlags.esp=v
    for _,p in ipairs(NXPortPlayers:GetPlayers()) do if p~=NXPortPlayer and p.Character then
        local head=p.Character:FindFirstChild("Head")
        if head then
            local bb=head:FindFirstChild("NX_C00L_ESP")
            if v then
                if not bb then bb=Instance.new("BillboardGui"); bb.Name="NX_C00L_ESP"; bb.Size=UDim2.fromOffset(120,24); bb.AlwaysOnTop=true; bb.Adornee=head; bb.Parent=head end
                local label=bb:FindFirstChildOfClass("TextLabel") or Instance.new("TextLabel")
                label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=p.Name; label.TextColor3=Color3.new(1,0,0); label.TextScaled=true; label.Parent=bb
            elseif bb then bb:Destroy() end
        end
    end end
end})
-- 15 JumpPower slider
NXTroll:CreateSlider({name="JumpPowerSlider", range={50,200}, value=50, callback=function(v) local h=NXPortHumanoid(); if h then h.UseJumpPower=true; h.JumpPower=v end end})
-- 16 Spin bot
NXTroll:CreateToggle({name="Spin Bot", value=false, callback=function(v)
    NXPortFlags.spin=v; local root=NXPortRoot()
    if not v then for _,k in ipairs({"spinGyro","spinPos"}) do local o=NXPortObjects[k]; if o then o:Destroy(); NXPortObjects[k]=nil end end; return end
    if not root then NXNotify("SPIN BOT","Персонаж не готов"); return end
    local av=Instance.new("BodyAngularVelocity"); av.Name="NX_C00L_SPIN"; av.AngularVelocity=Vector3.new(0,30,0); av.MaxTorque=Vector3.new(0,1e6,0); av.Parent=root; NXPortObjects.spinGyro=av
end})
-- 17 TP to mouse (updated hit position each click)
NXTroll:CreateButton({name="TP To Mouse", callback=function()
    local root=NXPortRoot(); local hit=NXPortMouse and NXPortMouse.Hit
    if root and hit then root.CFrame=CFrame.new(hit.Position+Vector3.new(0,3,0)) else NXNotify("TP TO MOUSE","Позиция мыши недоступна") end
end})
-- 18 Save position
NXTroll:CreateButton({name="Save Position", callback=function() local r=NXPortRoot(); if r then NXPortSavedCFrame=r.CFrame; NXNotify("POSITION","Сохранено") end end})
-- 19 Load position
NXTroll:CreateButton({name="Load Position", callback=function() local r=NXPortRoot(); if r and NXPortSavedCFrame then r.CFrame=NXPortSavedCFrame else NXNotify("POSITION","Нет сохранённой позиции") end end})
-- 20 No-Clip
NXTroll:CreateToggle({name="No-Clip", value=false, callback=function(v)
    NXPortFlags.noclip=v; NXPortStopConnection("noclip")
    if v then NXPortConnections.noclip=NXPortRun.Stepped:Connect(function()
        local c=NXPortCharacter(); if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
    end)
    else local c=NXPortCharacter(); if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=(p.Name~="HumanoidRootPart") end end end end
end})
-- 21 DarkDex external
NXTroll:CreateButton({name="DarkDex [EXTERNAL]", callback=function() NXPortExternal("DarkDex","https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua") end})
-- 22 SimpleSpy external
NXTroll:CreateButton({name="SimpleSpy [EXTERNAL]", callback=function() NXPortExternal("SimpleSpy","https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua") end})
-- 23 Orbit nearby unanchored parts
NXTroll:CreateToggle({name="Orbit All Nearby Parts", value=false, callback=function(v)
    NXPortFlags.orbit=v; NXPortStopConnection("orbit")
    if not v then for _,o in ipairs(NXPortObjects.orbit or {}) do pcall(function() o:Destroy() end) end; NXPortObjects.orbit={}; return end
    local root=NXPortRoot(); if not root then return NXNotify("ORBIT","Персонаж не готов") end
    local parts={}; for _,p in ipairs(workspace:GetDescendants()) do if p:IsA("BasePart") and not p.Anchored and (p.Position-root.Position).Magnitude<=20 and not p:IsDescendantOf(NXPortCharacter()) then table.insert(parts,p); if #parts>=12 then break end end end
    NXPortObjects.orbit={}
    if #parts==0 then NXPortFlags.orbit=false; NXNotify("ORBIT","Нет доступных деталей"); return end
    local t0=os.clock(); NXPortConnections.orbit=NXPortRun.Heartbeat:Connect(function()
        local r=NXPortRoot(); if not r or not NXPortFlags.orbit then return end
        for i,p in ipairs(parts) do if p.Parent then local a=(os.clock()-t0)*2+i*2*math.pi/#parts; p.AssemblyLinearVelocity=Vector3.new(-math.sin(a)*20,0,math.cos(a)*20); p.CFrame=CFrame.new(r.Position+Vector3.new(math.cos(a)*8,3,math.sin(a)*8)) end end
    end)
end})
-- 24 Invisible: reversible local character transparency toggle.
local NXPortInvisible=false
local NXPortTransparency={}
NXTroll:CreateToggle({name="Invisible", value=false, callback=function(v)
    NXPortInvisible=v
    local c=NXPortCharacter(); if not c then return NXNotify("INVISIBLE","Персонаж не готов") end
    if v then
        table.clear(NXPortTransparency)
        for _,obj in ipairs(c:GetDescendants()) do
            if obj:IsA("BasePart") then
                NXPortTransparency[obj]=obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier=1
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                NXPortTransparency[obj]=obj.Transparency
                obj.Transparency=1
            end
        end
        NXNotify("INVISIBLE","Локальная невидимость включена")
    else
        for obj,old in pairs(NXPortTransparency) do
            if obj and obj.Parent then
                pcall(function()
                    if obj:IsA("BasePart") then obj.LocalTransparencyModifier=old else obj.Transparency=old end
                end)
            end
        end
        table.clear(NXPortTransparency)
        NXNotify("INVISIBLE","Видимость восстановлена")
    end
end})
-- 25 Fly (mobile-friendly MoveDirection + jump input)
NXTroll:CreateToggle({name="Fly", value=false, callback=function(v)
    NXPortFlags.fly=v; NXPortStopConnection("fly")
    if v then NXPortConnections.fly=NXPortRun.Heartbeat:Connect(function()
        local h=NXPortHumanoid(); local r=NXPortRoot(); local cam=workspace.CurrentCamera
        if h and r and cam then
            local move=h.MoveDirection; local vertical=0
            if NXPortInput:IsKeyDown(Enum.KeyCode.Space) then vertical=35 end
            local velocity=move*45+Vector3.new(0,vertical,0)
            r.AssemblyLinearVelocity=velocity
        end
    end) end
end})
-- 26-31 external scripts, explicit user click required.
NXTroll:CreateButton({name="HatHub [EXTERNAL]", callback=function() NXPortExternal("HatHub","https://raw.githubusercontent.com/inkdupe/hat-scripts/refs/heads/main/updatedhathub.lua") end})
NXTroll:CreateButton({name="Part Grab [EXTERNAL]", callback=function() NXPortExternal("Part Grab","https://raw.githubusercontent.com/v0c0n1337/scripts/refs/heads/main/Unachored_parts_controller_v2.lua.txt") end})
NXTroll:CreateButton({name="Hat Script [EXTERNAL]", callback=function() NXPortExternal("Hat Script","https://raw.githubusercontent.com/ocfi/Scp-096-Obfuscated/refs/heads/main/obuf") end})
NXTroll:CreateButton({name="PART ORBIT [EXTERNAL]", callback=function() NXPortExternal("PART ORBIT","https://pastebin.com/raw/aZjaAr6F") end})
NXTroll:CreateButton({name="chat unbanner [EXTERNAL]", callback=function() NXPortExternal("chat unbanner","https://pastebin.com/raw/aDFhvMC4") end})
NXTroll:CreateButton({name="Fling GUI [EXTERNAL]", callback=function() NXPortExternal("Fling GUI","https://pastebin.com/raw/VynRhxJV") end})

-- Cleanup helper called by the existing NEXBYTE UNLOAD button.
local function NXPortCleanup()
    for key,conn in pairs(NXPortConnections) do
        if typeof(conn)=="RBXScriptConnection" then pcall(function() conn:Disconnect() end) end
        NXPortConnections[key]=nil
    end
    for _,obj in pairs(NXPortObjects) do
        if type(obj)=="table" then
            for _,child in ipairs(obj) do pcall(function() child:Destroy() end) end
        else pcall(function() obj:Destroy() end) end
    end
    NXPortObjects={}
    for obj,old in pairs(NXPortTransparency) do
        if obj and obj.Parent then pcall(function() if obj:IsA("BasePart") then obj.LocalTransparencyModifier=old else obj.Transparency=old end end) end
    end
    table.clear(NXPortTransparency)
    local c=NXPortCharacter()
    if c then
        for _,part in ipairs(c:GetDescendants()) do if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then part.CanCollide=true end end
    end
    for _,obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Decal") and obj.Name=="NX_C00L_DECAL") or obj.Name=="NX_C00L_ESP" then pcall(function() obj:Destroy() end) end
    end
    NXPortFlags.infJump=false; NXPortFlags.esp=false; NXPortFlags.spin=false
    NXPortFlags.noclip=false; NXPortFlags.fly=false; NXPortFlags.decal=false; NXPortFlags.orbit=false
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

-- FLING SECTION - Fling and throw mechanics
--[[
    FLING MODULE
    Provides fling functionality for selected targets.
    Uses the SkidFling mechanism adapted from zqyDSUWX.
]]
-- Fling status display
local FlingStatus = Instance.new("TextLabel")
FlingStatus.Name = "FlingStatus"
FlingStatus.Size = UDim2.new(1, 0, 0, 20)
FlingStatus.Position = UDim2.new(0, 0, 0, 25)
FlingStatus.BackgroundTransparency = 1
FlingStatus.Text = "Fling: Disabled"
FlingStatus.TextColor3 = Color3.fromRGB(180, 0, 0)
FlingStatus.Font = Enum.Font.GothamMedium
FlingStatus.TextSize = 12
FlingStatus.Parent = ContentArea

-- Fling toggles
local function CreateFlingControls()
    -- START FLING button
    local StartFlingBtn = Instance.new("TextButton")
    StartFlingBtn.Name = "StartFlingBtn"
    StartFlingBtn.Size = UDim2.new(0.45, -5, 0, 35)
    StartFlingBtn.Position = UDim2.new(0, 5, 1, -100)
    StartFlingBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    StartFlingBtn.BorderSizePixel = 0
    StartFlingBtn.Text = "START FLING"
    StartFlingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartFlingBtn.Font = Enum.Font.GothamBold
    StartFlingBtn.TextSize = 12
    StartFlingBtn.Parent = ContentArea

    -- STOP FLING button
    local StopFlingBtn = Instance.new("TextButton")
    StopFlingBtn.Name = "StopFlingBtn"
    StopFlingBtn.Size = UDim2.new(0.45, -5, 0, 35)
    StopFlingBtn.Position = UDim2.new(0.5, 5, 1, -100)
    StopFlingBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    StopFlingBtn.BorderSizePixel = 0
    StopFlingBtn.Text = "STOP FLING"
    StopFlingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StopFlingBtn.Font = Enum.Font.GothamBold
    StopFlingBtn.TextSize = 12
    StopFlingBtn.Parent = ContentArea

    -- Fling mode toggle
    local FlingModeToggle = Instance.new("TextButton")
    FlingModeToggle.Name = "FlingModeToggle"
    FlingModeToggle.Size = UDim2.new(0.9, 0, 0, 30)
    FlingModeToggle.Position = UDim2.new(0.05, 0, 1, -50)
    FlingModeToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    FlingModeToggle.BorderSizePixel = 0
    FlingModeToggle.Text = "Mode: Continuous"
    FlingModeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    FlingModeToggle.Font = Enum.Font.Gotham
    FlingModeToggle.TextSize = 11
    FlingModeToggle.Parent = ContentArea

    -- Connect START FLING handler
    StartFlingBtn.MouseButton1Click:Connect(function()
        if NEXBYTE._FlingActive then
            NEXBYTE:Log("Fling is already active", "warning")
            return
        end

        -- Admin check
        if not NEXBYTE:RequestAdminCheck("fling") then
            NEXBYTE:Log("Admin permission denied for Fling", "error")
            return
        end

        -- Get selected targets
        local selected = NEXBYTE:GetSelectedTargets()
        local target_count = 0
        for _ in pairs(selected) do
            target_count = target_count + 1
        end

        if target_count == 0 then
            NEXBYTE:Log("No targets selected for fling", "warning")
            NEXBYTE:ShowConfirmation("No Targets", "Select players to fling. Continue anyway?", function(confirmed)
                if confirmed then
                    NEXBYTE:StartFlingInternal()
                end
            end)
            return
        end

        -- Start fling
        NEXBYTE._FlingActive = true
        StartFlingBtn.Text = "STOP FLING"
        StartFlingBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        FlingStatus.Text = "Fling: Active (" .. target_count .. " targets)"
        FlingStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
        NEXBYTE:Log("Fling started with " .. target_count .. " targets", "system")
    end)

    -- Connect STOP FLING handler
    StopFlingBtn.MouseButton1Click:Connect(function()
        NEXBYTE._FlingActive = false
        StartFlingBtn.Text = "START FLING"
        StartFlingBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        FlingStatus.Text = "Fling: Disabled"
        FlingStatus.TextColor3 = Color3.fromRGB(180, 0, 0)
        NEXBYTE:Log("Fling stopped", "system")
    end)
end

-- Create fling controls after a short delay
task.delay(0.5, CreateFlingControls)

-- Internal fling function (adapted from original code)
function NEXBYTE:StartFlingInternal()
    if NEXBYTE._FlingActive then
        -- Get selected targets
        local selected = NEXBYTE:GetSelectedTargets()
        local validTargets = {}

        -- Process all targets first to determine which are valid
        for name, player in pairs(selected) do
            if player and player.Parent then
                validTargets[name] = player
            else
                -- Remove players who left
                selected[name] = nil
            end
        end

        -- Then attempt to fling each valid target
        for _, player in pairs(validTargets) do
            if NEXBYTE._FlingActive then
                -- Get character parts
                local character = Player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local rootPart = humanoid and humanoid.RootPart

                if rootPart then
                    -- Get target character parts
                    local target_char = player.Character
                    if target_char then
                        local target_root = target_char:FindFirstChild("HumanoidRootPart")
                        local target_head = target_char:FindFirstChild("Head")

                        if target_root then
                            -- Set camera subject to target head
                            if target_head then
                                workspace.CurrentCamera.CameraSubject = target_head
                            else
                                workspace.CurrentCamera.CameraSubject = target_root
                            end

                            -- Apply fling velocity
                            local velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
                            rootPart.Velocity = velocity
                            rootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)

                            -- Reset after short time
                            task.wait(0.5)
                            if rootPart.Parent then
                                rootPart.Velocity = Vector3.new()
                                rootPart.RotVelocity = Vector3.new()
                                workspace.CurrentCamera.CameraSubject = humanoid
                            end
                        end
                    end
                end
            else
                break
            end
        end
    end
end

-- Return the NEXBYTE module for use in the script
return NEXBYTE

-- TELEPORT SECTION - Teleport and movement
--[[
    TELEPORT MODULE
    Provides teleportation and movement capabilities.
]]
-- Teleport status display
local TPToggle = Instance.new("TextButton")
TPToggle.Name = "TPToggle"
TPToggle.Size = UDim2.new(0.4, 0, 0, 30)
TPToggle.Position = UDim2.new(0, 5, 1, -140)
TPToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
TPToggle.BorderSizePixel = 0
TPToggle.Text = "TP: Disabled"
TPToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
TPoggle.Font = Enum.Font.Gotham
TPoggle.TextSize = 11
TPoggle.Parent = ContentArea

-- TP to selected button
local TPToSelectedBtn = Instance.new("TextButton")
TPToSelectedBtn.Name = "TPToSelectedBtn"
TPToSelectedBtn.Size = UDim2.new(0.4, 0, 0, 30)
TPToSelectedBtn.Position = UDim2.new(0.5, 5, 1, -140)
TPToSelectedBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
TPToSelectedBtn.BorderSizePixel = 0
TPToSelectedBtn.Text = "TP TO SELECTED"
TPToSelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TPToSelectedBtn.Font = Enum.Font.GothamBold
TPToSelectedBtn.TextSize = 11
TPToSelectedBtn.Parent = ContentArea

-- Server hop button
local ServerHopBtn = Instance.new("TextButton")
ServerHopBtn.Name = "ServerHopBtn"
ServerHopBtn.Size = UDim2.new(0.4, 0, 0, 30)
ServerHopBtn.Position = UDim2.new(0, 5, 1, -100)
ServerHopBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
ServerHopBtn.BorderSizePixel = 0
ServerHopBtn.Text = "SERVER HOP"
ServerHopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ServerHopBtn.Font = Enum.Font.Gotham
ServerHopBtn.TextSize = 11
ServerHopBtn.Parent = ContentArea

-- Teleport to waypoint
local function CreateWaypointSystem()
    local WaypointFrame = Instance.new("Frame")
    WaypointFrame.Name = "WaypointSystem"
    WaypointFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
    WaypointFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
    WaypointFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    WaypointFrame.BorderSizePixel = 0
    WaypointFrame.Visible = false
    WaypointFrame.Parent = ContentArea

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = WaypointFrame

    local WaypointList = Instance.new("ScrollingFrame")
    WaypointList.Name = "WaypointList"
    WaypointList.Size = UDim2.new(1, -10, 1, -10)
    WaypointList.Position = UDim2.new(0, 5, 0, 5)
    WaypointList.BackgroundTransparency = 1
    WaypointList.ScrollBarThickness = 4
    WaypointList.Parent = WaypointFrame

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Parent = WaypointList
    ListLayout.Padding = UDim.new(0, 5)

    local CloseWaypoints = Instance.new("TextButton")
    CloseWaypoints.Name = "CloseWaypoints"
    CloseWaypoints.Size = UDim2.new(1, 0, 0, 30)
    CloseWaypoints.Position = UDim2.new(0, 0, 1, -35)
    CloseWaypoints.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    CloseWaypoints.BorderSizePixel = 0
    CloseWaypoints.Text = "CLOSE"
    CloseWaypoints.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseWaypoints.Font = Enum.Font.GothamBold
    CloseWaypoints.TextSize = 12
    CloseWaypoints.Parent = WaypointFrame

    return WaypointFrame, WaypointList, CloseWaypoints
end

local WaypointFrame, WaypointList, CloseWaypoints = CreateWaypointSystem()

-- Waypoint close handler
CloseWaypoints.MouseButton1Click:Connect(function()
    WaypointFrame.Visible = false
end)

-- TP to selected handler
TPToSelectedBtn.MouseButton1Click:Connect(function()
    -- Admin check
    if not NEXBYTE:RequestAdminCheck("tp") then
        NEXBYTE:Log("Admin permission denied for TP to Selected", "error")
        return
    end

    local selected = NEXBYTE:GetSelectedTargets()
    if #selected == 0 then
        NEXBYTE:Log("No players selected for TP to Selected", "warning")
        return
    end

    local myChar = Player.Character
    local myRootPart = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if not myRootPart then
        NEXBYTE:Log("Your character is not ready", "error")
        return
    end

    for _, target in pairs(selected) do
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = target.Character.HumanoidRootPart
            myRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            NEXBYTE:Log("TP'd to " .. target.Name, "system")
        end
    end
end

-- Server hop handler
ServerHopBtn.MouseButton1Click:Connect(function()
    -- Admin check
    if not NEXBYTE:RequestAdminCheck("server_hop") then
        NEXBYTE:Log("Admin permission denied for Server Hop", "error")
        return
    end

    task.spawn(function()
        local ok, err = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
            local data = HttpService:JSONDecode(game:HttpGet(url))

            if not data or not data.data then
                NEXBYTE:Log("Failed to get server list", "error")
                return
            end

            local servers = {}
            for _, s in ipairs(data.data or {}) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    table.insert(servers, s.id)
                end
            end

            if #servers > 0 then
                local randomServer = servers[math.random(1, #servers)]
                NEXBYTE:Log("Hopping to server " .. randomServer, "system")
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, randomServer, Player)
            else
                NEXBYTE:Log("No available servers found", "warning")
            end
        end)

        if not ok then
            NEXBYTE:Log("Server hop failed: " .. tostring(err), "error")
        end
    end)
end)

-- Return the NEXBYTE module for use in the script
return NEXBYTE

-- TROLL SECTION - Trolling tools and effects
--[[
    TROLL MODULE
    Provides various trolling and disruption tools.
]]
-- Troll status display
local TrollStatus = Instance.new("TextLabel")
TrollStatus.Name = "TrollStatus"
TrollStatus.Size = UDim2.new(1, 0, 0, 20)
TrollStatus.Position = UDim2.new(0, 0, 0, 50)
TrollStatus.BackgroundTransparency = 1
TrollStatus.Text = "Troll Mode: Disabled"
TrollStatus.TextColor3 = Color3.fromRGB(180, 0, 0)
TrollStatus.Font = Enum.Font.GothamMedium
TrollStatus.TextSize = 12
TrollStatus.Parent = ContentArea

-- Troll toggle
local function CreateTrollControls()
    -- Troll mode toggle
    local TrollToggle = Instance.new("TextButton")
    TrollToggle.Name = "TrollToggle"
    TrollToggle.Size = UDim2.new(0.45, -5, 0, 35)
    TrollToggle.Position = UDim2.new(0, 5, 1, -160)
    TrollToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    TrollToggle.BorderSizePixel = 0
    TrollToggle.Text = "TROLL: Disabled"
    TrollToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    TrollToggle.Font = Enum.Font.GothamBold
    TrollToggle.TextSize = 12
    TrollToggle.Parent = ContentArea

    -- Bring all button
    local BringAllBtn = Instance.new("TextButton")
    BringAllBtn.Name = "BringAllBtn"
    BringAllBtn.Size = UDim2.new(0.45, -5, 0, 35)
    BringAllBtn.Position = UDim2.new(0.5, 5, 1, -160)
    BringAllBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    BringAllBtn.BorderSizePixel = 0
    BringAllBtn.Text = "BRING ALL"
    BringAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    BringAllBtn.Font = Enum.Font.GothamBold
    BringAllBtn.TextSize = 12
    BringAllBtn.Parent = ContentArea

    -- Sit all button
    local SitAllBtn = Instance.new("TextButton")
    SitAllBtn.Name = "SitAllBtn"
    SitAllBtn.Size = UDim2.new(0.45, -5, 0, 35)
    SitAllBtn.Position = UDim2.new(0, 5, 1, -120)
    SitAllBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    SitAllBtn.BorderSizePixel = 0
    SitAllBtn.Text = "SIT ALL"
    SitAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SitAllBtn.Font = Enum.Font.GothamBold
    SitAllBtn.TextSize = 12
    SitAllBtn.Parent = ContentArea

    -- Ragdoll all button
    local RagdollAllBtn = Instance.new("TextButton")
    RagdollAllBtn.Name = "RagdollAllBtn"
    RagdollAllBtn.Size = UDim2.new(0.45, -5, 0, 35)
    RagdollAllBtn.Position = UDim2.new(0.5, 5, 1, -120)
    RagdollAllBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    RagdollAllBtn.BorderSizePixel = 0
    RagdollAllBtn.Text = "RAGDOLL ALL"
    RagdollAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RagdollAllBtn.Font = Enum.Font.GothamBold
    RagdollAllBtn.TextSize = 12
    RagdollAllBtn.Parent = ContentArea

    -- Kill all button (with confirmation)
    local KillAllBtn = Instance.new("TextButton")
    KillAllBtn.Name = "KillAllBtn"
    KillAllBtn.Size = UDim2.new(0.45, -5, 0, 35)
    KillAllBtn.Position = UDim2.new(0, 5, 1, -80)
    KillAllBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    KillAllBtn.BorderSizePixel = 0
    KillAllBtn.Text = "KILL ALL"
    KillAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    KillAllBtn.Font = Enum.Font.GothamBold
    KillAllBtn.TextSize = 12
    KillAllBtn.Parent = ContentArea

    -- Toggle handler
    local troll_active = false
    TrollToggle.MouseButton1Click:Connect(function()
        troll_active = not troll_active
        TrollToggle.Text = troll_active and "TROLL: Active" or "TROLL: Disabled"
        TrollToggle.BackgroundColor3 = troll_active and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 70)

        if troll_active then
            NEXBYTE:Log("Troll mode activated", "system")
            -- Start troll loop
            task.spawn(function()
                while troll_active do
                    -- Get all players
                    local players = Players:GetPlayers()
                    for _, player in ipairs(players) do
                        if player ~= Player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            -- Bring player slightly closer
                            local hrp = player.Character.HumanoidRootPart
                            hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -5)
                            
                            -- Small velocity
                            hrp.AssemblyLinearVelocity = Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else
            NEXBYTE:Log("Troll mode deactivated", "system")
        end
    end)

    -- Bring all handler
    BringAllBtn.MouseButton1Click:Connect(function()
        -- Admin check
        if not NEXBYTE:RequestAdminCheck("bring") then
            NEXBYTE:Log("Admin permission denied for Bring All", "error")
            return
        end

        local selected = NEXBYTE:GetSelectedTargets()
        local myChar = Player.Character
        local myRootPart = myChar and myChar:FindFirstChild("HumanoidRootPart")

        if not myRootPart then
            NEXBYTE:Log("Your character is not ready", "error")
            return
        end

        for _, target in pairs(selected) do
            if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local targetRoot = target.Character.HumanoidRootPart
                targetRoot.CFrame = myRootPart.CFrame
                NEXBYTE:Log("Brought " .. target.Name, "system")
            end
        end
    end)

    -- Sit all handler
    SitAllBtn.MouseButton1Click:Connect(function()
        -- Admin check
        if not NEXBYTE:RequestAdminCheck("sit") then
            NEXBYTE:Log("Admin permission denied for Sit All", "error")
            return
        end

        local selected = NEXBYTE:GetSelectedTargets()
        for _, target in pairs(selected) do
            if target.Character and target.Character:FindFirstChildOfClass("Humanoid") then
                target.Character.Humanoid.Sit = true
                NEXBYTE:Log("Sitted " .. target.Name, "system")
            end
        end
    end)

    -- Ragdoll all handler
    RagdollAllBtn.MouseButton1Click:Connect(function()
        -- Admin check
        if not NEXBYTE:RequestAdminCheck("ragdoll") then
            NEXBYTE:Log("Admin permission denied for Ragdoll All", "error")
            return
        end

        local selected = NEXBYTE:GetSelectedTargets()
        for _, target in pairs(selected) do
            if target.Character and target.Character:FindFirstChildOfClass("Humanoid") then
                local humanoid = target.Character.Humanoid
                humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
                NEXBYTE:Log("Ragdolled " .. target.Name, "system")
            end
        end
    end)

    -- Kill all handler (with confirmation)
    KillAllBtn.MouseButton1Click:Connect(function()
        NEXBYTE:ShowConfirmation("Kill All Players", 
            "This will attempt to eliminate all selected players. Are you sure?", 
            function(confirmed)
                if confirmed then
                    -- Admin check
                    if not NEXBYTE:RequestAdminCheck("kill") then
                        NEXBYTE:Log("Admin permission denied for Kill All", "error")
                        return
                    end

                    local selected = NEXBYTE:GetSelectedTargets()
                    for _, target in pairs(selected) do
                        if target.Character and target.Character:FindFirstChildOfClass("Humanoid") then
                            target.Character.Humanoid.Health = 0
                            NEXBYTE:Log("Eliminated " .. target.Name, "system")
                        end
                    end
                end
            end)
    end)
end

-- Create troll controls after a short delay
task.delay(0.5, CreateTrollControls)

-- Return the NEXBYTE module for use in the script
return NEXBYTE

-- VISUALS SECTION - Visual effects and settings
--[[
    VISUALS MODULE
    Provides visual effects and customization.
]]
-- Visuals status display
local VisualsStatus = Instance.new("TextLabel")
VisualsStatus.Name = "VisualsStatus"
VisualsStatus.Size = UDim2.new(1, 0, 0, 20)
VisualsStatus.Position = UDim2.new(0, 0, 0, 70)
VisualsStatus.BackgroundTransparency = 1
VisualsStatus.Text = "Visuals: Disabled"
VisualsStatus.TextColor3 = Color3.fromRGB(180, 0, 0)
VisualsStatus.Font = Enum.Font.GothamMedium
VisualsStatus.TextSize = 12
VisualsStatus.Parent = ContentArea

-- Visuals toggles
local function CreateVisualsControls()
    -- ESP toggle
    local ESPToggle = Instance.new("TextButton")
    ESPToggle.Name = "ESPToggle"
    ESPToggle.Size = UDim2.new(0.45, -5, 0, 35)
    ESPToggle.Position = UDim2.new(0, 5, 1, -190)
    ESPToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    ESPToggle.BorderSizePixel = 0
    ESPToggle.Text = "ESP: Disabled"
    ESPToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    ESPToggle.Font = Enum.Font.GothamBold
    ESPToggle.TextSize = 12
    ESPToggle.Parent = ContentArea

    -- Night vision toggle
    local NightVisionToggle = Instance.new("TextButton")
    NightVisionToggle.Name = "NightVisionToggle"
    NightVisionToggle.Size = UDim2.new(0.45, -5, 0, 35)
    NightVisionToggle.Position = UDim2.new(0.5, 5, 1, -190)
    NightVisionToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    NightVisionToggle.BorderSizePixel = 0
    NightVisionToggle.Text = "Night Vision: Off"
    NightVisionToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    NightVisionToggle.Font = Enum.Font.GothamBold
    NightVisionToggle.TextSize = 12
    NightVisionToggle.Parent = ContentArea

    -- Brightness slider display
    local BrightnessValue = Instance.new("TextLabel")
    BrightnessValue.Name = "BrightnessValue"
    BrightnessValue.Size = UDim2.new(0.9, 0, 0, 20)
    BrightnessValue.Position = UDim2.new(0.05, 0, 1, -150)
    BrightnessValue.BackgroundTransparency = 1
    BrightnessValue.Text = "Brightness: " .. tostring(Lighting.Brightness)
    BrightnessValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    BrightnessValue.Font = Enum.Font.Gotham
    BrightnessValue.TextSize = 11
    BrightnessValue.Parent = ContentArea

    -- Brightness increase button
    local BrightnessUp = Instance.new("TextButton")
    BrightnessUp.Name = "BrightnessUp"
    BrightnessUp.Size = UDim2.new(0.2, 0, 0, 25)
    BrightnessUp.Position = UDim2.new(0.8, 0, 1, -150)
    BrightnessUp.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    BrightnessUp.BorderSizePixel = 0
    BrightnessUp.Text = "+"
    BrightnessUp.TextColor3 = Color3.fromRGB(255, 255, 255)
    BrightnessUp.Font = Enum.Font.GothamBold
    BrightnessUp.TextSize = 14
    BrightnessUp.Parent = ContentArea

    -- Brightness decrease button
    local BrightnessDown = Instance.new("TextButton")
    BrightnessDown.Name = "BrightnessDown"
    BrightnessDown.Size = UDim2.new(0.2, 0, 0, 25)
    BrightnessDown.Position = UDim2.new(0.85, 0, 1, -150)
    BrightnessDown.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    BrightnessDown.BorderSizePixel = 0
    BrightnessDown.Text = "-"
    BrightnessDown.TextColor3 = Color3.fromRGB(255, 255, 255)
    BrightnessDown.Font = Enum.Font.GothamBold
    BrightnessDown.TextSize = 14
    BrightnessDown.Parent = ContentArea

    -- ESP toggle handler
    local esp_active = false
    ESPToggle.MouseButton1Click:Connect(function()
        esp_active = not esp_active
        ESPToggle.Text = esp_active and "ESP: Enabled" or "ESP: Disabled"
        ESPToggle.BackgroundColor3 = esp_active and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 70)

        if esp_active then
            NEXBYTE:Log("ESP enabled - player names will be displayed", "system")
            -- ESP implementation would go here
        else
            NEXBYTE:Log("ESP disabled", "system")
        end
    end)

    -- Night vision toggle handler
    local night_vision = false
    NightVisionToggle.MouseButton1Click:Connect(function()
        night_vision = not night_vision
        NightVisionToggle.Text = night_vision and "Night Vision: On" or "Night Vision: Off"
        NightVisionToggle.BackgroundColor3 = night_vision and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 70)

        -- Apply night vision effect
        if night_vision then
            Lighting.ClockTime = 12  -- Make it seem like night
            Lighting.Brightness = 10  -- Increase brightness
            NEXBYTE:Log("Night vision activated", "system")
        else
            Lighting.ClockTime = 14  -- Reset to day
            Lighting.Brightness = 2  -- Reset brightness
            NEXBYTE:Log("Night vision deactivated", "system")
        end
    end)

    -- Brightness adjustment
    local current_brightness = Lighting.Brightness
    BrightnessUp.MouseButton1Click:Connect(function()
        current_brightness = math.min(current_brightness + 1, 10)
        Lighting.Brightness = current_brightness
        BrightnessValue.Text = "Brightness: " .. tostring(current_brightness)
    end)

    BrightnessDown.MouseButton1Click:Connect(function()
        current_brightness = math.max(current_brightness - 1, 0)
        Lighting.Brightness = current_brightness
        BrightnessValue.Text = "Brightness: " .. tostring(current_brightness)
    end)
end

-- Create visuals controls after a short delay
task.delay(0.5, CreateVisualsControls)

-- Return the NEXBYTE module for use in the script
return NEXBYTE

-- MOVEMENT SECTION - Movement settings and modifications
--[[
    MOVEMENT MODULE
    Provides movement speed, jump power, and other movement modifications.
]]
-- Movement status display
local MovementStatus = Instance.new("TextLabel")
MovementStatus.Name = "MovementStatus"
MovementStatus.Size = UDim2.new(1, 0, 0, 20)
MovementStatus.Position = UDim2.new(0, 0, 0, 90)
MovementStatus.BackgroundTransparency = 1
MovementStatus.Text = "Movement: Normal"
MovementStatus.TextColor3 = Color3.fromRGB(180, 0, 0)
MovementStatus.Font = Enum.Font.GothamMedium
MovementStatus.TextSize = 12
MovementStatus.Parent = ContentArea

-- Movement toggles
local function CreateMovementControls()
    -- WalkSpeed slider display
    local WalkSpeedValue = Instance.new("TextLabel")
    WalkSpeedValue.Name = "WalkSpeedValue"
    WalkSpeedValue.Size = UDim2.new(0.4, 0, 0, 25)
    WalkSpeedValue.Position = UDim2.new(0, 5, 1, -220)
    WalkSpeedValue.BackgroundTransparency = 1
    WalkSpeedValue.Text = "WalkSpeed: " .. tostring(16)
    WalkSpeedValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    WalkSpeedValue.Font = Enum.Font.Gotham
    WalkSpeedValue.TextSize = 11
    WalkSpeedValue.Parent = ContentArea

    -- WalkSpeed increase button
    local WSUp = Instance.new("TextButton")
    WSUp.Name = "WSUp"
    WSUp.Size = UDim2.new(0.15, 0, 0, 25)
    WSUp.Position = UDim2.new(0.48, 0, 1, -220)
    WSUp.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    WSUp.BorderSizePixel = 0
    WSUp.Text = "+"
    WSUp.TextColor3 = Color3.fromRGB(255, 255, 255)
    WSUp.Font = Enum.Font.GothamBold
    WSUp.TextSize = 12
    WSUp.Parent = ContentArea

    -- WalkSpeed decrease button
    local WSDown = Instance.new("TextButton")
    WSDown.Name = "WSDown"
    WSDown.Size = UDim2.new(0.15, 0, 0, 25)
    WSDown.Position = UDim2.new(0.53, 0, 1, -220)
    WSDown.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    WSDown.BorderSizePixel = 0
    WSDown.Text = "-"
    WSDown.TextColor3 = Color3.fromRGB(255, 255, 255)
    WSDown.Font = Enum.Font.GothamBold
    WSDown.TextSize = 12
    WSDown.Parent = ContentArea

    -- JumpPower display
    local JumpPowerValue = Instance.new("TextLabel")
    JumpPowerValue.Name = "JumpPowerValue"
    JumpPowerValue.Size = UDim2.new(0.4, 0, 0, 25)
    JumpPowerValue.Position = UDim2.new(0.7, 5, 1, -220)
    JumpPowerValue.BackgroundTransparency = 1
    JumpPowerValue.Text = "JumpPower: " .. tostring(50)
    JumpPowerValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    JumpPowerValue.Font = Enum.Font.Gotham
    JumpPowerValue.TextSize = 11
    JumpPowerValue.Parent = ContentArea

    -- JumpPower increase button
    local JPUp = Instance.new("TextButton")
    JPUp.Name = "JPUp"
    JPUp.Size = UDim2.new(0.15, 0, 0, 25)
    JPUp.Position = UDim2.new(0.93, 0, 1, -220)
    JPUp.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    JPUp.BorderSizePixel = 0
    JPUp.Text = "+"
    JPUp.TextColor3 = Color3.fromRGB(255, 255, 255)
    JPUp.Font = Enum.Font.GothamBold
    JPUp.TextSize = 12
    JPUp.Parent = ContentArea

    -- JumpPower decrease button
    local JPDown = Instance.new("TextButton")
    JPDown.Name = "JPDown"
    JPDown.Size = UDim2.new(0.15, 0, 0, 25)
    JPDown.Position = UDim2.new(0.98, 0, 1, -220)
    JPDown.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    JPDown.BorderSizePixel = 0
    JPDown.Text = "-"
    JPDown.TextColor3 = Color3.fromRGB(255, 255, 255)
    JPDown.Font = Enum.Font.GothamBold
    JPDown.TextSize = 12
    JPDown.Parent = ContentArea

    -- WalkSpeed adjustment
    local current_walkspeed = 16
    WSUp.MouseButton1Click:Connect(function()
        current_walkspeed = math.min(current_walkspeed + 1, 200)
        WalkSpeedValue.Text = "WalkSpeed: " .. tostring(current_walkspeed)
        -- Apply to player
        local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = current_walkspeed
        end
    end)

    WSDown.MouseButton1Click:Connect(function()
        current_walkspeed = math.max(current_walkspeed - 1, 1)
        WalkSpeedValue.Text = "WalkSpeed: " .. tostring(current_walkspeed)
        -- Apply to player
        local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = current_walkspeed
        end
    end)

    -- JumpPower adjustment
    local current_jumppower = 50
    JPUp.MouseButton1Click:Connect(function()
        current_jumppower = math.min(current_jumppower + 1, 500)
        JumpPowerValue.Text = "JumpPower: " .. tostring(current_jumppower)
        -- Apply to player
        local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = current_jumppower
            humanoid.UseJumpPower = true
        end
    end)

    JPDown.MouseButton1Click:Connect(function()
        current_jumppower = math.max(current_jumppower - 1, 1)
        JumpPowerValue.Text = "JumpPower: " .. tostring(current_jumppower)
        -- Apply to player
        local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = current_jumppower
            humanoid.UseJumpPower = true
        end
    end)
end

-- Create movement controls after a short delay
task.delay(0.5, CreateMovementControls)

-- Return the NEXBYTE module for use in the script
return NEXBYTE

-- CAMERA SECTION - Camera controls and settings
--[[
    CAMERA MODULE
    Provides camera field of view, spectate, and camera modifications.
]]
-- Camera status display
local CameraStatus = Instance.new("TextLabel")
CameraStatus.Name = "CameraStatus"
CameraStatus.Size = UDim2.new(1, 0, 0, 20)
CameraStatus.Position = UDim2.new(0, 0, 0, 110)
CameraStatus.BackgroundTransparency = 1
CameraStatus.Text = "Camera: Normal"
CameraStatus.TextColor3 = Color3.fromRGB(180, 0, 0)
CameraStatus.Font = Enum.Font.GothamMedium
CameraStatus.TextSize = 12
CameraStatus.Parent = ContentArea

-- Camera toggles
local function CreateCameraControls()
    -- FOV slider display
    local FOVValue = Instance.new("TextLabel")
    FOVValue.Name = "FOVValue"
    FOVValue.Size = UDim2.new(0.4, 0, 0, 25)
    FOVValue.Position = UDim2.new(0, 5, 1, -250)
    FOVValue.BackgroundTransparency = 1
    FOVValue.Text = "FOV: " .. tostring(workspace.CurrentCamera.FieldOfView)
    FOVValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    FOVValue.Font = Enum.Font.Gotham
    FOVValue.TextSize = 11
    FOVValue.Parent = ContentArea

    -- FOV increase button
    local FOVUp = Instance.new("TextButton")
    FOVUp.Name = "FOVUp"
    FOVUp.Size = UDim2.new(0.15, 0, 0, 25)
    FOVUp.Position = UDim2.new(0.48, 0, 1, -250)
    FOVUp.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    FOVUp.BorderSizePixel = 0
    FOVUp.Text = "+"
    FOVUp.TextColor3 = Color3.fromRGB(255, 255, 255)
    FOVUp.Font = Enum.Font.GothamBold
    FOVUp.TextSize = 12
    FOVUp.Parent = ContentArea

    -- FOV decrease button
    local FOVDown = Instance.new("TextButton")
    FOVDown.Name = "FOVDown"
    FOVDown.Size = UDim2.new(0.15, 0, 0, 25)
    FOVDown.Position = UDim2.new(0.53, 0, 1, -250)
    FOVDown.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    FOVDown.BorderSizePixel = 0
    FOVDown.Text = "-"
    FOVDown.TextColor3 = Color3.fromRGB(255, 255, 255)
    FOVDown.Font = Enum.Font.GothamBold
    FOVDown.TextSize = 12
    FOVDown.Parent = ContentArea

    -- Spectate toggle
    local SpectateToggle = Instance.new("TextButton")
    SpectateToggle.Name = "SpectateToggle"
    SpectateToggle.Size = UDim2.new(0.45, -5, 0, 35)
    SpectateToggle.Position = UDim2.new(0, 5, 1, -190)
    SpectateToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    SpectateToggle.BorderSizePixel = 0
    SpectateToggle.Text = "Spectate: Disabled"
    SpectateToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    SpectateToggle.Font = Enum.Font.GothamBold
    SpectateToggle.TextSize = 12
    SpectateToggle.Parent = ContentArea

    -- Current camera target display
    local CameraTarget = Instance.new("TextLabel")
    CameraTarget.Name = "CameraTarget"
    CameraTarget.Size = UDim2.new(0.9, 0, 0, 20)
    CameraTarget.Position = UDim2.new(0.05, 0, 1, -150)
    CameraTarget.BackgroundTransparency = 1
    CameraTarget.Text = "Target: Player"
    CameraTarget.TextColor3 = Color3.fromRGB(255, 255, 255)
    CameraTarget.Font = Enum.Font.Gotham
    CameraTarget.TextSize = 11
    CameraTarget.Parent = ContentArea

    -- WalkSpeed adjustment
    local current_fov = workspace.CurrentCamera.FieldOfView
    FOVUp.MouseButton1Click:Connect(function()
        current_fov = math.min(current_fov + 10, 120)
        workspace.CurrentCamera.FieldOfView = current_fov
        FOVValue.Text = "FOV: " .. tostring(math.floor(current_fov))
    end)

    FOVDown.MouseButton1Click:Connect(function()
        current_fov = math.max(current_fov - 10, 1)
        workspace.CurrentCamera.FieldOfView = current_fov
        FOVValue.Text = "FOV: " .. tostring(math.floor(current_fov))
    end)

    -- Spectate handler
    local spectating = false
    local target_player = nil
    SpectateToggle.MouseButton1Click:Connect(function()
        spectating = not spectating
        SpectateToggle.Text = spectating and "Spectate: Enabled" or "Spectate: Disabled"
        SpectateToggle.BackgroundColor3 = spectating and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(60, 60, 70)

        if spectating then
            -- Get first selected target or cycle through players
            local selected = NEXBYTE:GetSelectedTargets()
            local players = Players:GetPlayers()
            
            if #selected > 0 then
                for _, p in ipairs(players) do
                    if selected[p.Name] then
                        target_player = p
                        break
                    end
                end
            end
            
            if not target_player then
                -- Just select first available player
                for _, p in ipairs(players) do
                    if p ~= Player and p.Character then
                        target_player = p
                        break
                    end
                end
            end
            
            if target_player and target_player.Character then
                local humanoid = target_player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    workspace.CurrentCamera.CameraSubject = humanoid
                    NEXBYTE:Log("Now spectating " .. target_player.Name, "system")
                end
            end
        else
            -- Reset to player
            local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                workspace.CurrentCamera.CameraSubject = humanoid
                NEXBYTE:Log("Spectate disabled, camera reset", "system")
            end
        end
    end)
end

-- Create camera controls after a short delay
task.delay(0.5, CreateCameraControls)

-- Return the NEXBYTE module for use in the script
return NEXBYTE

-- SCRIPT HUB SECTION - Script execution and management
--[[
    SCRIPT HUB MODULE
    Provides script execution, GitHub search, and file management.
]]
-- Script Hub status display
local ScriptHubStatus = Instance.new("TextLabel")
ScriptHubStatus.Name = "ScriptHubStatus"
ScriptHubStatus.Size = UDim2.new(1, 0, 0, 20)
ScriptHubStatus.Position = UDim2.new(0, 0, 0, 130)
ScriptHubStatus.BackgroundTransparency = 1
ScriptHubStatus.Text = "Script Hub: Ready"
ScriptHubStatus.TextColor3 = Color3.fromRGB(180, 0, 0)
ScriptHubStatus.Font = Enum.Font.GothamMedium
ScriptHubStatus.TextSize = 12
ScriptHubStatus.Parent = ContentArea

-- Search query box
local SearchQuery = Instance.new("TextBox")
SearchQuery.Name = "SearchQuery"
SearchQuery.Size = UDim2.new(0.8, 0, 0, 30)
SearchQuery.Position = UDim2.new(0.1, 0, 1, -220)
SearchQuery.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
SearchQuery.BorderSizePixel = 0
SearchQuery.PlaceholderText = "Search GitHub for scripts..."
SearchQuery.Text = ""
SearchQuery.Font = Enum.Font.Gotham
SearchQuery.TextSize = 12
SearchQuery.Parent = ContentArea

-- Repository dropdown
local RepoDropdown = Instance.new("TextButton")
RepoDropdown.Name = "RepoDropdown"
RepoDropdown.Size = UDim2.new(0.4, 0, 0, 30)
RepoDropdown.Position = UDim2.new(0.1, 0, 1, -180)
RepoDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
RepoDropdown.BorderSizePixel = 0
RepoDropdown.Text = "Repository: Select first"
RepoDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
RepoDropdown.Font = Enum.Font.Gotham
RepoDropdown.TextSize = 11
RepoDropdown.Parent = ContentArea

-- Lua file dropdown
local FileDropdown = Instance.new("TextButton")
FileDropdown.Name = "FileDropdown"
FileDropdown.Size = UDim2.new(0.4, 0, 0, 30)
FileDropdown.Position = UDim2.new(0.55, 0, 1, -180)
FileDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
FileDropdown.BorderSizePixel = 0
FileDropdown.Text = "File: Load repository first"
FileDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
FileDropdown.Font = Enum.Font.Gotham
FileDropdown.TextSize = 11
FileDropdown.Parent = ContentArea

-- Load repositories button
local LoadReposBtn = Instance.new("TextButton")
LoadReposBtn.Name = "LoadReposBtn"
LoadReposBtn.Size = UDim2.new(0.2, 0, 0, 30)
LoadReposBtn.Position = UDim2.new(0.1, 0, 1, -140)
LoadReposBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
LoadReposBtn.BorderSizePixel = 0
LoadReposBtn.Text = "LOAD REPOS"
LoadReposBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadReposBtn.Font = Enum.Font.GothamBold
LoadReposBtn.TextSize = 11
LoadReposBtn.Parent = ContentArea

-- Execute selected button
local ExecuteBtn = Instance.new("TextButton")
ExecuteBtn.Name = "ExecuteBtn"
ExecuteBtn.Size = UDim2.new(0.3, 0, 0, 35)
ExecuteBtn.Position = UDim2.new(0.35, 0, 1, -80)
ExecuteBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
ExecuteBtn.BorderSizePixel = 0
ExecuteBtn.Text = "EXECUTE SELECTED"
ExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecuteBtn.Font = Enum.Font.GothamBold
ExecuteBtn.TextSize = 12
ExecuteBtn.Parent = ContentArea

-- Execute input
local ExecuteInput = Instance.new("TextBox")
ExecuteInput.Name = "ExecuteInput"
ExecuteInput.Size = UDim2.new(0.6, 0, 0, 30)
ExecuteInput.Position = UDim2.new(0.2, 0, 1, -40)
ExecuteInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
ExecuteInput.BorderSizePixel = 0
ExecuteInput.PlaceholderText = "Or execute Lua source below..."
ExecuteInput.Text = ""
ExecuteInput.Font = Enum.Font.Gotham
ExecuteInput.TextSize = 12
ExecuteInput.Parent = ContentArea

-- Function to search GitHub repositories
local function SearchGitHubRepositories()
    local query = SearchQuery.Text:gsub("%s+", "+")
    if query == "+" or query == "" then
        NEXBYTE:Log("Please enter a search query", "warning")
        return
    end

    NEXBYTE:Log("Searching GitHub for: " .. query, "system")

    task.spawn(function()
        local ok, result = pcall(function()
            local encoded_query = game:GetService("HttpService"):UrlEncode(query .. " roblox lua")
            return game:GetService("HttpService"):JSONDecode(game:HttpGet(
                "https://api.github.com/search/repositories?q=" .. encoded_query .. "&sort=stars&order=desc&per_page=5"
            ))
        end)

        if ok and result and result.items then
            local options = {}
            local repo_map = {}

            for _, item in ipairs(result.items) do
                local label = item.full_name .. " | " .. tostring(item.stargazers_count) .. " stars"
                repo_map[label] = {
                    owner = item.owner.login,
                    name = item.name,
                    branch = item.default_branch
                }
                table.insert(options, label)
            end

            if #options > 0 then
                -- Update dropdown
                RepoDropdown.Text = "Repository: " .. options[1]
                _G["NEXBYTE_Selected_Repo"] = repo_map[options[1]]

                -- Refresh file dropdown when repository is selected
                -- (Would need additional UI updates)
                NEXBYTE:Log("Found " .. #result.items .. " repositories", "system")
            else
                NEXBYTE:Log("No repositories found", "warning")
            end
        else
            NEXBYTE:Log("GitHub search failed or rate limited", "error")
        end
    end)
end

LoadReposBtn.MouseButton1Click:Connect(SearchGitHubRepositories)

-- Function to load Lua files from selected repository
local function LoadSelectedRepository()
    local selected_repo = _G["NEXBYTE_Selected_Repo"]
    if not selected_repo then
        NEXBYTE:Log("Please select a repository first", "warning")
        return
    end

    NEXBYTE:Log("Loading files from " .. selected_repo.owner .. "/" .. selected_repo.name, "system")

    task.spawn(function()
        local ok, result = pcall(function()
            local url = "https://api.github.com/repos/" .. selected_repo.owner .. "/" .. selected_repo.name ..
                "/git/trees/" .. selected_repo.branch .. "?recursive=1"
            return game:GetService("HttpService"):JSONDecode(game:HttpGet(url))
        end)

        if ok and result and result.tree then
            local options = {}
            local script_map = {}

            for _, item in ipairs(result.tree) do
                if item.type == "blob" and item.path:lower():match("%.lua$") then
                    local path = item.path
                    local raw = "https://raw.githubusercontent.com/" .. selected_repo.owner .. "/" .. selected_repo.name .. "/" .. selected_repo.branch .. "/" .. path
                    script_map[path] = raw
                    table.insert(options, path)
                end
            end

            if #options > 0 then
                FileDropdown.Text = "File: " .. options[1]
                _G["NEXBYTE_Selected_File"] = script_map[options[1]]
                NEXBYTE:Log("Found " .. #options .. " Lua files", "system")
            else
                NEXBYTE:Log("No Lua files found in repository", "warning")
            end
        else
            NEXBYTE:Log("Failed to load repository files", "error")
        end
    end)
end

LoadReposBtn.MouseButton1Click:Connect(LoadSelectedRepository)

-- Execute selected handler
ExecuteBtn.MouseButton1Click:Connect(function()
    -- Try to execute from file dropdown first
    local file_path = FileDropdown.Text:gsub("File: ", "")
    local script_path = _G["NEXBYTE_Selected_File"]

    if script_path then
        -- Execute from repository
        task.spawn(function()
            local ok, err = pcall(function()
                local source = game:GetService("HttpService"):GetAsync(script_path)
                assert(#source > 0, "Empty file")
                local fn, compile_error = loadstring(source)
                assert(fn, compile_error or "Compile failed")
                fn()
            end)

            if not ok then
                NEXBYTE:Log("Execution error: " .. tostring(err), "error")
            else
                NEXBYTE:Log("Script executed successfully", "system")
            end
        end)
    elseif SearchQuery.Text ~= "" and SearchQuery.Text ~= "Search GitHub for scripts..." then
        -- Execute from search query (last result)
        NEXBYTE:Log("Executing from search results", "system")
    else
        -- Execute from input box
        local source = ExecuteInput.Text
        if source ~= "" then
            task.spawn(function()
                local ok, err = pcall(function()
                    local fn, compile_error = loadstring(source)
                    assert(fn, compile_error or "Compile failed")
                    fn()
                end)

                if not ok then
                    NEXBYTE:Log("Execution error: " .. tostring(err), "error")
                else
                    NEXBYTE:Log("Script executed from input", "system")
                end
            end)
        else
            NEXBYTE:Log("No script to execute", "warning")
        end
    end
end)

-- Return the NEXBYTE module for use in the script
return NEXBYTE
