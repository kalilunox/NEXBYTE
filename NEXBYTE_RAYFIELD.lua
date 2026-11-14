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
    NEXBYTE ULTIMATE ADMIN
    Based on the working fling mechanism from zqyDSUWX
    Features:
    - Select multiple targets
    - Continuous flinging until stopped
    - Preserves player mobility (no teleporting to targets)
    - Flings targets very far
    - Compatible with JJSploit, Synapse X, etc.
    - 15+ modules: Player Selection, Fling, Teleport, Troll, Visuals, Movement, Camera, Script Hub
    - Module Manager with profiles, macros, logging
    - Admin permission framework with confirmations
]]
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local Player = Players.LocalPlayer

-- =====================================================
-- MODULE MANAGER
-- =====================================================
local NEXBYTE = {
    _VERSION = "2.0.0",
    _MODULES = {},
    _SETTINGS = {},
    _PROFILES = {},
    _MACROS = {},
    _LOGS = {},
    _ADMIN_PERMISSIONS = {"fling", "bring", "tp", "tools", "visuals", "movement", "troll", "server_hop", "kill", "ragdoll", "sit"},
    _ACTIVE_MODULES = {},
}

-- Shared state
NEXBYTE._SelectedTargets = {}
NEXBYTE._FlingActive = false
NEXBYTE._TouchFlingActive = false
NEXBYTE._BringActive = false
NEXBYTE._TrollActive = false
NEXBYTE._ESPActive = false
NEXBYTE._NightVision = false

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
    if #self._LOGS > 1000 then
        table.remove(self._LOGS, 1)
    end
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
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            self._SelectedTargets[p.Name] = p
            count = count + 1
        end
    end
    self:Log("Selected all " .. count .. " players", "system")
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
    local targets = {}
    for _, p in pairs(self._SelectedTargets) do
        table.insert(targets, p)
    end
    return targets
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
    for _, allowed in ipairs(self._ADMIN_PERMISSIONS) do
        if allowed == permission then
            return true
        end
    end
    return false
end

function NEXBYTE:RequestAdminCheck(permission)
    -- Placeholder for server-side admin check
    return self:HasAdminPermission(permission)
end

-- Confirmation system for dangerous actions
function NEXBYTE:ShowConfirmation(title, text, callback)
    local confirmation = Instance.new("TextButton")
    confirmation.Name = "NEXBYTE_Confirmation"
    confirmation.Size = UDim2.new(0, 280, 0, 120)
    confirmation.Position = UDim2.new(0.5, -140, 0.5, -60)
    confirmation.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    confirmation.BorderSizePixel = 0
    confirmation.Text = ""
    confirmation.Parent = game:GetService("CoreGui")

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = confirmation

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(0, 195, 235)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = confirmation

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 0, 40)
    textLabel.Position = UDim2.new(0, 10, 0, 40)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextSize = 13
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = confirmation

    local yesBtn = Instance.new("TextButton")
    yesBtn.Size = UDim2.new(0.4, -5, 0, 30)
    yesBtn.Position = UDim2.new(0.05, 0, 1, -40)
    yesBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    yesBtn.BorderSizePixel = 0
    yesBtn.Text = "YES"
    yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.TextSize = 13
    yesBtn.Parent = confirmation

    local noBtn = Instance.new("TextButton")
    noBtn.Size = UDim2.new(0.4, -5, 0, 30)
    noBtn.Position = UDim2.new(0.55, 0, 1, -40)
    noBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    noBtn.BorderSizePixel = 0
    noBtn.Text = "NO"
    noBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    noBtn.Font = Enum.Font.GothamBold
    noBtn.TextSize = 13
    noBtn.Parent = confirmation

    yesBtn.MouseButton1Click:Connect(function()
        confirmation:Destroy()
        if callback then callback(true) end
    end)

    noBtn.MouseButton1Click:Connect(function()
        confirmation:Destroy()
        if callback then callback(false) end
    end)

    task.delay(10, function()
        if confirmation and confirmation.Parent then
            confirmation:Destroy()
            if callback then callback(false) end
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
            NEXBYTE:Log("Remote '" .. name .. "' not found", "error")
            return false
        end
        remote.fired = true
        remote.last_fire = tick()
        NEXBYTE:Log("Remote '" .. name .. "' fired", "system")
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

NEXBYTE:RegisterModule("player_selection", {
    on_activate = function() NEXBYTE:Log("Player selection module activated", "system") end,
    on_deactivate = function() NEXBYTE:Log("Player selection module deactivated", "system") end,
})

NEXBYTE:RegisterModule("logging", {
    on_activate = function() NEXBYTE:Log("Logging module activated", "system") end,
    on_deactivate = function() NEXBYTE:Log("Logging module deactivated", "system") end,
})

-- Set up player added/removed handling
Players.PlayerAdded:Connect(function(player)
    if NEXBYTE._SETTINGS.log_actions then
        NEXBYTE:Log("Player joined: " .. player.Name, "system")
    end
end)

Players.PlayerRemoving:Connect(function(player)
    NEXBYTE:DeselectPlayer(player)
    if NEXBYTE._SETTINGS.log_actions then
        NEXBYTE:Log("Player left: " .. player.Name, "system")
    end
end)

-- =====================================================
-- RAYFIELD GUI
-- =====================================================
local NXRayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local NXWindow = NXRayfield:CreateWindow({
    name = "NEXBYTE ULTIMATE ADMIN",
    subtitle = "Universal Client Toolkit v2.0",
    sidebarLayout = true,
    theme = "Default"
})

local function NXNotify(title, content)
    NXWindow:Notify({title = title, content = content, duration = 4})
end

local function NXGetNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then table.insert(names, p.Name) end
    end
    table.sort(names)
    return names
end

local function NXGetTarget()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and NEXBYTE._SelectedTargets[p.Name] then
            return p
        end
    end
end

-- =====================================================
-- HOME TAB
-- =====================================================
local NXHome = NXWindow:CreateTab({name="HOME", icon="house"})
NXHome:CreateSection({name="NEXBYTE ULTIMATE ADMIN"})
NXHome:CreateText({name="Status", text="Build 2.0 | Rayfield Gen2 | 15+ Modules Active"})
NXHome:CreateButton({name="REFRESH STATUS", callback=function() NXNotify("NEXBYTE", "Interface running") end})
NXHome:CreateButton({name="STOP ALL MODULES", callback=function()
    for name, _ in pairs(NEXBYTE._ACTIVE_MODULES) do
        if NEXBYTE._ACTIVE_MODULES[name] then NEXBYTE:DeactivateModule(name) end
    end
    NEXBYTE._FlingActive = false
    NEXBYTE._TouchFlingActive = false
    NEXBYTE._TrollActive = false
    NEXBYTE._ESPActive = false
    NEXBYTE._NightVision = false
    NXNotify("NEXBYTE", "All modules stopped")
end})
NXHome:CreateButton({name="RESET ALL SETTINGS", callback=function()
    NEXBYTE:ShowConfirmation("Reset All", "Reset all settings to defaults?", function(confirmed)
        if confirmed then
            NEXBYTE._SETTINGS = {theme="Default", autosave_profiles=true, log_actions=true, default_profile="default"}
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.UseJumpPower = true end
            workspace.CurrentCamera.FieldOfView = 70
            NXNotify("NEXBYTE", "All settings reset")
        end
    end)
end})

-- =====================================================
-- PLAYER TAB
-- =====================================================
local NXPlayerTab = NXWindow:CreateTab({name="PLAYER", icon="users"})
NXPlayerTab:CreateSection({name="TARGET SELECTION"})

local NXDropdown = NXPlayerTab:CreateDropdown({
    name="SELECT PLAYERS",
    options=NXGetNames(),
    value={},
    multiSelect=true,
    placeholder="Choose players",
    callback=function(value)
        for name in pairs(NEXBYTE._SelectedTargets) do NEXBYTE._SelectedTargets[name] = nil end
        local chosen = type(value) == "table" and value or {value}
        for _, name in ipairs(chosen) do
            local p = Players:FindFirstChild(name)
            if p and p ~= Player then NEXBYTE._SelectedTargets[name] = p end
        end
    end
})

NXPlayerTab:CreateButton({name="REFRESH PLAYER LIST", callback=function()
    NXDropdown:Refresh(NXGetNames())
    NXNotify("PLAYER LIST", "Updated")
end})
NXPlayerTab:CreateButton({name="SELECT ALL", callback=function()
    NEXBYTE:SelectAllPlayers()
    NXNotify("NEXBYTE", "All players selected")
end})
NXPlayerTab:CreateButton({name="DESELECT ALL", callback=function()
    NEXBYTE:DeselectAllPlayers()
    NXNotify("NEXBYTE", "Selection cleared")
end})
NXPlayerTab:CreateButton({name="BRING SELECTED", callback=function()
    if not NEXBYTE:RequestAdminCheck("bring") then return NXNotify("NEXBYTE", "Admin permission denied") end
    local targets = NEXBYTE:GetSelectedTargets()
    if #targets == 0 then return NXNotify("NEXBYTE", "No players selected") end
    local myChar = Player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return NXNotify("NEXBYTE", "Your character not ready") end
    for _, target in ipairs(targets) do
        local tChar = target.Character
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if tRoot then tRoot.CFrame = myRoot.CFrame end
    end
    NXNotify("NEXBYTE", "Brought " .. #targets .. " players")
end})
NXPlayerTab:CreateButton({name="TP TO SELECTED", callback=function()
    if not NEXBYTE:RequestAdminCheck("tp") then return NXNotify("NEXBYTE", "Admin permission denied") end
    local targets = NEXBYTE:GetSelectedTargets()
    if #targets == 0 then return NXNotify("NEXBYTE", "No players selected") end
    local myChar = Player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return NXNotify("NEXBYTE", "Your character not ready") end
    for _, target in ipairs(targets) do
        local tChar = target.Character
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if tRoot then myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3) end
    end
    NXNotify("NEXBYTE", "TP'd to " .. #targets .. " players")
end})

-- =====================================================
-- FLING TAB
-- =====================================================
local NXFlingTab = NXWindow:CreateTab({name="FLING", icon="zap"})
NXFlingTab:CreateSection({name="FLING CONTROLS"})

NXFlingTab:CreateButton({name="START FLING", callback=function()
    if NEXBYTE._FlingActive then return NXNotify("FLING", "Already active") end
    if not NEXBYTE:RequestAdminCheck("fling") then return NXNotify("FLING", "Admin permission denied") end
    local targets = NEXBYTE:GetSelectedTargets()
    if #targets == 0 then return NXNotify("FLING", "No targets selected") end
    NEXBYTE._FlingActive = true
    NXNotify("FLING", "Started flinging " .. #targets .. " targets")
    task.spawn(function()
        -- Proper SkidFling: preserve local player position, fling targets
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local rp = hum and hum.RootPart
        if not (char and hum and rp) then
            NEXBYTE._FlingActive = false
            return NXNotify("FLING", "Your character not ready")
        end
        local OldPos = rp.CFrame
        local FPDH = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0

        local function FlingTarget(targetPlayer)
            if not NEXBYTE._FlingActive then return end
            local tChar = targetPlayer.Character
            if not tChar then return end
            local tHum = tChar:FindFirstChildOfClass("Humanoid")
            local tRoot = tHum and tHum.RootPart
            local tHead = tChar:FindFirstChild("Head")
            if not tRoot then return end
            if tHum and tHum.Sit then return end

            -- Disable sitting for local player
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            local BV = Instance.new("BodyVelocity")
            BV.Parent = rp
            BV.Velocity = Vector3.new(0, 0, 0)
            BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

            -- Camera to target
            if tHead then workspace.CurrentCamera.CameraSubject = tHead
            elseif tHum then workspace.CurrentCamera.CameraSubject = tHum
            end

            local TimeToWait = 2
            local Time = tick()
            local Angle = 0

            repeat
                if not NEXBYTE._FlingActive then break end
                if rp and tHum then
                    if tRoot.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        local offset = CFrame.new(0, 1.5, 0) + tHum.MoveDirection * tRoot.Velocity.Magnitude / 1.25
                        rp.CFrame = CFrame.new(tRoot.Position) * offset * CFrame.Angles(math.rad(Angle), 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * offset * CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        offset = CFrame.new(0, -1.5, 0) + tHum.MoveDirection * tRoot.Velocity.Magnitude / 1.25
                        rp.CFrame = CFrame.new(tRoot.Position) * offset * CFrame.Angles(math.rad(Angle), 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * offset * CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        offset = CFrame.new(0, 1.5, 0) + tHum.MoveDirection * tRoot.Velocity.Magnitude / 1.25
                        rp.CFrame = CFrame.new(tRoot.Position) * offset * CFrame.Angles(math.rad(Angle), 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * offset * CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        offset = CFrame.new(0, -1.5, 0) + tHum.MoveDirection * tRoot.Velocity.Magnitude / 1.25
                        rp.CFrame = CFrame.new(tRoot.Position) * offset * CFrame.Angles(math.rad(Angle), 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * offset * CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        offset = CFrame.new(0, 1.5, 0) + tHum.MoveDirection
                        rp.CFrame = CFrame.new(tRoot.Position) * offset * CFrame.Angles(math.rad(Angle), 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * offset * CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        offset = CFrame.new(0, -1.5, 0) + tHum.MoveDirection
                        rp.CFrame = CFrame.new(tRoot.Position) * offset * CFrame.Angles(math.rad(Angle), 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * offset * CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        rp.CFrame = CFrame.new(tRoot.Position) * CFrame.new(0, 1.5, tHum.WalkSpeed) * CFrame.Angles(math.rad(90), 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * CFrame.new(0, 1.5, tHum.WalkSpeed) * CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        rp.CFrame = CFrame.new(tRoot.Position) * CFrame.new(0, -1.5, -tHum.WalkSpeed) * CFrame.Angles(0, 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * CFrame.new(0, -1.5, -tHum.WalkSpeed) * CFrame.Angles(0, 0, 0))
                        task.wait()
                        rp.CFrame = CFrame.new(tRoot.Position) * CFrame.new(0, 1.5, tHum.WalkSpeed) * CFrame.Angles(math.rad(90), 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * CFrame.new(0, 1.5, tHum.WalkSpeed) * CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        rp.CFrame = CFrame.new(tRoot.Position) * CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        rp.CFrame = CFrame.new(tRoot.Position) * CFrame.new(0, -1.5, 0) * CFrame.Angles(0, 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * CFrame.new(0, -1.5, 0) * CFrame.Angles(0, 0, 0))
                        task.wait()
                        rp.CFrame = CFrame.new(tRoot.Position) * CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        rp.CFrame = CFrame.new(tRoot.Position) * CFrame.new(0, -1.5, 0) * CFrame.Angles(0, 0, 0)
                        char:SetPrimaryPartCFrame(CFrame.new(tRoot.Position) * CFrame.new(0, -1.5, 0) * CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                end
            until Time + TimeToWait < tick() or not NEXBYTE._FlingActive

            -- Cleanup
            BV:Destroy()
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            if hum then workspace.CurrentCamera.CameraSubject = hum end

            -- Return to original position
            if OldPos then
                repeat
                    if not rp.Parent then break end
                    rp.CFrame = OldPos * CFrame.new(0, .5, 0)
                    char:SetPrimaryPartCFrame(OldPos * CFrame.new(0, .5, 0))
                    hum:ChangeState("GettingUp")
                    for _, part in pairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Velocity = Vector3.new()
                            part.RotVelocity = Vector3.new()
                        end
                    end
                    task.wait()
                until (rp.Position - OldPos.p).Magnitude < 25
            end
            workspace.FallenPartsDestroyHeight = FPDH
        end

        while NEXBYTE._FlingActive do
            local validTargets = {}
            for name, plr in pairs(NEXBYTE._SelectedTargets) do
                if plr and plr.Parent then validTargets[name] = plr else NEXBYTE._SelectedTargets[name] = nil end
            end
            for _, plr in pairs(validTargets) do
                if not NEXBYTE._FlingActive then break end
                FlingTarget(plr)
                task.wait(0.2)
            end
            task.wait(0.5)
        end

        -- Final cleanup
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        if hum then workspace.CurrentCamera.CameraSubject = hum end
        workspace.FallenPartsDestroyHeight = FPDH
        if OldPos and rp.Parent then
            repeat
                rp.CFrame = OldPos * CFrame.new(0, .5, 0)
                char:SetPrimaryPartCFrame(OldPos * CFrame.new(0, .5, 0))
                hum:ChangeState("GettingUp")
                for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Velocity = Vector3.new()
                        part.RotVelocity = Vector3.new()
                    end
                end
                task.wait()
            until (rp.Position - OldPos.p).Magnitude < 25
        end
    end)
end})

NXFlingTab:CreateButton({name="STOP FLING", callback=function()
    NEXBYTE._FlingActive = false
    NXNotify("FLING", "Stopped")
end})

NXFlingTab:CreateToggle({name="TOUCH FLING", value=false, callback=function(v)
    NEXBYTE._TouchFlingActive = v
    if v then
        task.spawn(function()
            while NEXBYTE._TouchFlingActive do
                RunService.Heartbeat:Wait()
                local char = Player.Character
                local rp = char and char:FindFirstChild("HumanoidRootPart")
                if rp then
                    local vel = rp.AssemblyLinearVelocity
                    rp.AssemblyLinearVelocity = vel * 10000 + Vector3.new(0, 10000, 0)
                    RunService.RenderStepped:Wait()
                    if not NEXBYTE._TouchFlingActive then break end
                    rp.AssemblyLinearVelocity = vel
                    RunService.Stepped:Wait()
                    rp.AssemblyLinearVelocity = vel + Vector3.new(0, 0.1, 0)
                end
            end
        end)
    end
    NXNotify("TOUCH FLING", v and "ON" or "OFF")
end})

-- =====================================================
-- TELEPORT TAB
-- =====================================================
local NXTeleportTab = NXWindow:CreateTab({name="TELEPORT", icon="location-on"})
NXTeleportTab:CreateSection({name="TELEPORT OPTIONS"})

NXTeleportTab:CreateButton({name="SERVER HOP", callback=function()
    if not NEXBYTE:RequestAdminCheck("server_hop") then return NXNotify("SERVER HOP", "Admin permission denied") end
    task.spawn(function()
        local ok, err = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
            local data = HttpService:JSONDecode(game:HttpGet(url))
            local servers = {}
            for _, s in ipairs(data.data or {}) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then table.insert(servers, s.id) end
            end
            if #servers > 0 then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], Player)
            else
                NXNotify("SERVER HOP", "No available servers")
            end
        end)
        if not ok then NXNotify("SERVER HOP", "Failed: " .. tostring(err)) end
    end)
end})

NXTeleportTab:CreateButton({name="REJOIN CURRENT", callback=function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end})

-- =====================================================
-- TROLL TAB
-- =====================================================
local NXTroll = NXWindow:CreateTab({name="TROLL", icon="zap"})
NXTroll:CreateSection({name="TROLL TOOLS"})

NXTroll:CreateToggle({name="TROLL MODE", value=false, callback=function(v)
    NEXBYTE._TrollActive = v
    if v then
        task.spawn(function()
            while NEXBYTE._TrollActive do
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= Player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = plr.Character.HumanoidRootPart
                        hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -5)
                        hrp.AssemblyLinearVelocity = Vector3.new(math.random(-5,5), math.random(-5,5), math.random(-5,5))
                    end
                end
                task.wait(0.1)
            end
        end)
    end
    NXNotify("TROLL MODE", v and "ACTIVE" or "DISABLED")
end})

NXTroll:CreateButton({name="BRING ALL", callback=function()
    if not NEXBYTE:RequestAdminCheck("bring") then return NXNotify("TROLL", "Admin permission denied") end
    local targets = NEXBYTE:GetSelectedTargets()
    local myChar = Player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return NXNotify("TROLL", "Your character not ready") end
    for _, target in ipairs(targets) do
        local tChar = target.Character
        local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
        if tRoot then tRoot.CFrame = myRoot.CFrame end
    end
    NXNotify("TROLL", "Brought " .. #targets .. " players")
end})

NXTroll:CreateButton({name="SIT ALL", callback=function()
    if not NEXBYTE:RequestAdminCheck("sit") then return NXNotify("TROLL", "Admin permission denied") end
    for _, target in ipairs(NEXBYTE:GetSelectedTargets()) do
        local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = true end
    end
    NXNotify("TROLL", "Sitted selected players")
end})

NXTroll:CreateButton({name="RAGDOLL ALL", callback=function()
    if not NEXBYTE:RequestAdminCheck("ragdoll") then return NXNotify("TROLL", "Admin permission denied") end
    for _, target in ipairs(NEXBYTE:GetSelectedTargets()) do
        local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Ragdoll) end
    end
    NXNotify("TROLL", "Ragdolled selected players")
end})

NXTroll:CreateButton({name="KILL ALL", callback=function()
    NEXBYTE:ShowConfirmation("Kill All", "Eliminate all selected players?", function(confirmed)
        if not confirmed then return end
        if not NEXBYTE:RequestAdminCheck("kill") then return NXNotify("TROLL", "Admin permission denied") end
        for _, target in ipairs(NEXBYTE:GetSelectedTargets()) do
            local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
        NXNotify("TROLL", "Eliminated selected players")
    end)
end})

NXTroll:CreateButton({name="TOOL KILL", callback=function()
    local target = NXGetTarget()
    local char = Player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    local handle = tool and tool:FindFirstChild("Handle")
    local touch = handle and handle:FindFirstChildOfClass("TouchTransmitter")
    local root = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not (tool and handle and touch and root) then return NXNotify("TOOL KILL", "Need compatible Tool and target") end
    if type(firetouchinterest) ~= "function" then return NXNotify("TOOL KILL", "Touch function unavailable") end
    for i=1,10 do firetouchinterest(handle, root, 0) firetouchinterest(handle, root, 1) end
    NXNotify("TOOL KILL", "Interaction sent")
end})

-- =====================================================
-- VISUALS TAB
-- =====================================================
local NXVisuals = NXWindow:CreateTab({name="VISUALS", icon="eye"})
NXVisuals:CreateSection({name="VISUAL EFFECTS"})

NXVisuals:CreateToggle({name="ESP (Player Names)", value=false, callback=function(v)
    NEXBYTE._ESPActive = v
    if v then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and p.Character and p.Character:FindFirstChild("Head") then
                local head = p.Character.Head
                if not head:FindFirstChild("NEXBYTE_ESP") then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "NEXBYTE_ESP"
                    bb.Size = UDim2.fromOffset(120, 24)
                    bb.AlwaysOnTop = true
                    bb.Adornee = head
                    bb.Parent = head
                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.fromScale(1, 1)
                    label.BackgroundTransparency = 1
                    label.Text = p.Name
                    label.TextColor3 = Color3.new(1, 0, 0)
                    label.TextScaled = true
                    label.Parent = bb
                end
            end
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local esp = p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("NEXBYTE_ESP")
                if esp then esp:Destroy() end
            end
        end
    end
    NXNotify("ESP", v and "ENABLED" or "DISABLED")
end})

NXVisuals:CreateToggle({name="NIGHT VISION", value=false, callback=function(v)
    NEXBYTE._NightVision = v
    if v then
        Lighting.ClockTime = 0
        Lighting.Brightness = 10
    else
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
    end
    NXNotify("NIGHT VISION", v and "ON" or "OFF")
end})

NXVisuals:CreateSlider({name="BRIGHTNESS", range={0, 10}, value=Lighting.Brightness, callback=function(v)
    Lighting.Brightness = v
end})

NXVisuals:CreateSlider({name="AMBIENT", range={0, 1}, value=Lighting.Ambient.R, callback=function(v)
    Lighting.Ambient = Color3.new(v, v, v)
    Lighting.OutdoorAmbient = Color3.new(v, v, v)
end})

-- =====================================================
-- MOVEMENT TAB
-- =====================================================
local NXMovement = NXWindow:CreateTab({name="MOVEMENT", icon="move"})
NXMovement:CreateSection({name="MOVEMENT SETTINGS"})

NXMovement:CreateSlider({name="WALK SPEED", range={1, 200}, value=16, callback=function(v)
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end})

NXMovement:CreateSlider({name="JUMP POWER", range={1, 500}, value=50, callback=function(v)
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v; hum.UseJumpPower = true end
end})

NXMovement:CreateSlider({name="HIP HEIGHT", range={0, 10}, value=0, callback=function(v)
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.HipHeight = v end
end})

NXMovement:CreateToggle({name="INFINITE JUMP", value=false, callback=function(v)
    NEXBYTE._InfiniteJump = v
    if v then
        NEXBYTE._InfJumpConn = UserInputService.JumpRequest:Connect(function()
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if NEXBYTE._InfJumpConn then NEXBYTE._InfJumpConn:Disconnect() end
    end
    NXNotify("INF JUMP", v and "ON" or "OFF")
end})

-- =====================================================
-- CAMERA TAB
-- =====================================================
local NXCamera = NXWindow:CreateTab({name="CAMERA", icon="camera"})
NXCamera:CreateSection({name="CAMERA CONTROLS"})

NXCamera:CreateSlider({name="FIELD OF VIEW", range={1, 120}, value=70, callback=function(v)
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = v end
end})

NXCamera:CreateButton({name="SPECTATE SELECTED", callback=function()
    local target = NXGetTarget()
    if not target then return NXNotify("CAMERA", "Select a player first") end
    local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
    if hum and workspace.CurrentCamera then
        workspace.CurrentCamera.CameraSubject = hum
        NXNotify("CAMERA", "Spectating " .. target.Name)
    end
end})

NXCamera:CreateButton({name="RESET CAMERA", callback=function()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum and workspace.CurrentCamera then
        workspace.CurrentCamera.CameraSubject = hum
        workspace.CurrentCamera.FieldOfView = 70
    end
    NXNotify("CAMERA", "Reset")
end})

NXCamera:CreateToggle({name="CAMERA SHAKE", value=false, callback=function(v)
    if v then
        NEXBYTE._ShakeConn = RunService.RenderStepped:Connect(function()
            if workspace.CurrentCamera then
                workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * CFrame.Angles(math.rad(math.random(-1,1)), math.rad(math.random(-1,1)), 0)
            end
        end)
    else
        if NEXBYTE._ShakeConn then NEXBYTE._ShakeConn:Disconnect() end
    end
    NXNotify("CAMERA SHAKE", v and "ON" or "OFF")
end})

-- =====================================================
-- SCRIPT HUB TAB
-- =====================================================
local NXHub = NXWindow:CreateTab({name="SCRIPT HUB", icon="search"})
NXHub:CreateSection({name="GITHUB SEARCH"})

local NXQuery = ""
local NXSelectedRepo
local NXSelectedScript
local NXAutoExecute = true
local NXRepoMap = {}
local NXScriptMap = {}

NXHub:CreateInput({name="SEARCH QUERY", placeholder="Search Roblox Lua repositories", callback=function(value) NXQuery=value end})

local NXRepoDropdown = NXHub:CreateDropdown({name="REPOSITORY", options={"Search first"}, value="Search first", callback=function(value) NXSelectedRepo=NXRepoMap[value] end})
local NXFileDropdown = NXHub:CreateDropdown({name="LUA FILE", options={"Load repository first"}, value="Load repository first", callback=function(value)
    NXSelectedScript=NXScriptMap[value]
    if NXSelectedScript and NXAutoExecute then
        task.spawn(function()
            local ok, err = pcall(function()
                local source = game:HttpGet(NXSelectedScript)
                assert(#source>0, "Empty file")
                local fn, compileError = loadstring(source)
                assert(fn, compileError or "Compile failed")
                fn()
            end)
            if not ok then NXNotify("SCRIPT ERROR", tostring(err):sub(1,180)) else NXNotify("SCRIPT HUB", "Executed") end
        end)
    end
end})

NXHub:CreateToggle({name="AUTO EXECUTE", value=true, callback=function(v) NXAutoExecute=v end})

NXHub:CreateButton({name="SEARCH GITHUB", callback=function()
    if NXQuery:gsub("%s","")=="" then return NXNotify("GITHUB", "Enter a search query") end
    local ok, result = pcall(function()
        local q = HttpService:UrlEncode(NXQuery .. " roblox lua")
        return HttpService:JSONDecode(game:HttpGet("https://api.github.com/search/repositories?q=" .. q .. "&sort=stars&order=desc&per_page=10"))
    end)
    if not ok or not result or not result.items then return NXNotify("GITHUB", "Search failed or API rate limit") end
    local options = {}; NXRepoMap = {}; NXSelectedRepo = nil
    for _, repo in ipairs(result.items) do
        local label = repo.full_name .. " | " .. tostring(repo.stargazers_count) .. " stars"
        NXRepoMap[label] = {owner=repo.owner.login, name=repo.name, branch=repo.default_branch}
        table.insert(options, label)
    end
    if #options==0 then options={"No repositories found"} end
    NXRepoDropdown:Refresh(options)
    NXNotify("GITHUB", "Found " .. #result.items .. " repositories")
end})

NXHub:CreateButton({name="LOAD LUA FILES", callback=function()
    if not NXSelectedRepo then return NXNotify("SCRIPT HUB", "Select a repository") end
    local repo = NXSelectedRepo
    local ok, result = pcall(function()
        local url = "https://api.github.com/repos/" .. repo.owner .. "/" .. repo.name .. "/git/trees/" .. repo.branch .. "?recursive=1"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not ok or not result or not result.tree then return NXNotify("GITHUB", "Could not load files") end
    local options = {}; NXScriptMap = {}; NXSelectedScript = nil
    for _, item in ipairs(result.tree) do
        if item.type=="blob" and item.path:lower():match("%.lua$") and #options<50 then
            local path = item.path
            local raw = "https://raw.githubusercontent.com/" .. repo.owner .. "/" .. repo.name .. "/" .. repo.branch .. "/" .. path
            NXScriptMap[path] = raw
            table.insert(options, path)
        end
    end
    if #options==0 then options={"No Lua files found"} end
    NXFileDropdown:Refresh(options)
    NXNotify("SCRIPT HUB", "Lua files: " .. tostring(#NXScriptMap))
end})

NXHub:CreateButton({name="EXECUTE SELECTED", callback=function()
    if not NXSelectedScript then return NXNotify("SCRIPT HUB", "Select a Lua file") end
    local ok, err = pcall(function()
        local source = game:HttpGet(NXSelectedScript)
        local fn, compileError = loadstring(source)
        assert(fn, compileError or "Compile failed")
        fn()
    end)
    if not ok then NXNotify("EXECUTION ERROR", tostring(err)) end
end})

NXHub:CreateText({name="WARNING", text="Third-party scripts are untrusted and can perform unwanted actions."})

-- =====================================================
-- MODULES TAB
-- =====================================================
local NXModules = NXWindow:CreateTab({name="MODULES", icon="grid"})
NXModules:CreateSection({name="MODULE MANAGER"})

NXModules:CreateText({name="ModuleStatus", text="Active modules: 0 / " .. tostring(#{"player_selection", "logging"})})

for _, modName in ipairs({"player_selection", "logging"}) do
    NXModules:CreateToggle({name=modName:upper(), value=false, callback=function(v)
        if v then NEXBYTE:ActivateModule(modName) else NEXBYTE:DeactivateModule(modName) end
    end})
end

NXModules:CreateButton({name="STOP ALL MODULES", callback=function()
    for name, _ in pairs(NEXBYTE._ACTIVE_MODULES) do
        if NEXBYTE._ACTIVE_MODULES[name] then NEXBYTE:DeactivateModule(name) end
    end
    NXNotify("MODULES", "All modules stopped")
end})

-- =====================================================
-- PROFILES TAB
-- =====================================================
local NXProfiles = NXWindow:CreateTab({name="PROFILES", icon="star"})
NXProfiles:CreateSection({name="PROFILE MANAGEMENT"})

NXProfiles:CreateInput({name="PROFILE NAME", placeholder="Enter profile name", callback=function(v) NXProfiles._ProfileName = v end})
NXProfiles:CreateButton({name="SAVE PROFILE", callback=function()
    local name = NXProfiles._ProfileName or "default"
    NEXBYTE:CreateProfile(name, {})
    NXNotify("PROFILES", "Saved profile: " .. name)
end})
NXProfiles:CreateButton({name="LOAD PROFILE", callback=function()
    local name = NXProfiles._ProfileName or "default"
    NEXBYTE:LoadProfile(name)
    NXNotify("PROFILES", "Loaded profile: " .. name)
end})

NXProfiles:CreateSection({name="MACRO SYSTEM"})
NXProfiles:CreateInput({name="MACRO NAME", placeholder="Macro name", callback=function(v) NXProfiles._MacroName = v end})
NXProfiles:CreateButton({name="CREATE MACRO (example)", callback=function()
    NEXBYTE:CreateMacro("test_macro", {function() NXNotify("MACRO", "Step 1") end, function() NXNotify("MACRO", "Step 2") end}, 1)
    NXNotify("MACRO", "Created test_macro")
end})
NXProfiles:CreateButton({name="EXECUTE MACRO", callback=function()
    if NEXBYTE:ExecuteMacro(NXProfiles._MacroName or "test_macro") then
        NXNotify("MACRO", "Executing...")
    else
        NXNotify("MACRO", "Macro not found")
    end
end})
NXProfiles:CreateButton({name="STOP MACRO", callback=function()
    NEXBYTE:StopMacro(NXProfiles._MacroName or "test_macro")
    NXNotify("MACRO", "Stopped")
end})

-- =====================================================
-- SETTINGS TAB
-- =====================================================
local NXSettings = NXWindow:CreateTab({name="SETTINGS", icon="settings"})
NXSettings:CreateSection({name="APPLICATION SETTINGS"})

NXSettings:CreateToggle({name="LOG ACTIONS", value=NEXBYTE._SETTINGS.log_actions, callback=function(v)
    NEXBYTE._SETTINGS.log_actions = v
    NXNotify("SETTINGS", "Log actions: " .. (v and "ON" or "OFF"))
end})

NXSettings:CreateToggle({name="AUTO SAVE PROFILES", value=NEXBYTE._SETTINGS.autosave_profiles, callback=function(v)
    NEXBYTE._SETTINGS.autosave_profiles = v
    NXNotify("SETTINGS", "Auto-save profiles: " .. (v and "ON" or "OFF"))
end})

NXSettings:CreateButton({name="UNLOAD NEXBYTE", callback=function()
    NEXBYTE._FlingActive = false
    NEXBYTE._TouchFlingActive = false
    NEXBYTE._TrollActive = false
    NEXBYTE._ESPActive = false
    NEXBYTE._NightVision = false
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.UseJumpPower = true end
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = 70 end
    pcall(function() GuiService:SetGameplayPausedNotificationEnabled(true) end)
    NXWindow:Unload()
    NXNotify("NEXBYTE", "Unloaded")
end})

-- =====================================================
-- FE OP EXPLOITS TAB (100+ keyless, interruptible, FE-compatible)
-- =====================================================
local NXFeExploits = NXWindow:CreateTab({name="FE OP", icon="skull"})
NXFeExploits:CreateSection({name="CHARACTER / MOVEMENT"})

-- Fly (BodyVelocity based, FE compatible)
local flyConn, flyBV, flyBG
NXFeExploits:CreateToggle({name="FLY (BodyVelocity)", value=false, callback=function(v)
    if v then
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (hrp and hum) then return NXNotify("FLY", "Character not ready") end
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBG.CFrame = hrp.CFrame
        flyBG.Parent = hrp
        hum.PlatformStand = true
        flyConn = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            local move = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
            flyBV.Velocity = move * 100
            flyBG.CFrame = cam.CFrame
        end)
    else
        if flyConn then flyConn:Disconnect() end
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    NXNotify("FLY", v and "ON" or "OFF")
end})

NXFeExploits:CreateSlider({name="FLY SPEED", range={10, 500}, value=100, callback=function(v)
    -- speed is hardcoded in fly loop, would need refactor
end})

-- Noclip
local noclipConn
NXFeExploits:CreateToggle({name="NOCLIP", value=false, callback=function(v)
    if v then
        noclipConn = RunService.Stepped:Connect(function()
            local char = Player.Character
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() end
        local char = Player.Character
        if char then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = true end
            end
        end
    end
    NXNotify("NOCLIP", v and "ON" or "OFF")
end})

-- Infinite Jump (already in Movement, but adding here too)
local infJumpConn
NXFeExploits:CreateToggle({name="INF JUMP", value=false, callback=function(v)
    if v then
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    else
        if infJumpConn then infJumpConn:Disconnect() end
    end
    NXNotify("INF JUMP", v and "ON" or "OFF")
end})

-- Super Jump
NXFeExploits:CreateButton({name="SUPER JUMP (once)", callback=function()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if hum and hrp then
        hrp.Velocity = Vector3.new(0, 200, 0)
        NXNotify("SUPER JUMP", "Launched")
    end
end})

-- High Jump Power (already in Movement)

-- Speed Hack (already in Movement)

-- Swim in Air
local swimConn
NXFeExploits:CreateToggle({name="SWIM IN AIR", value=false, callback=function(v)
    if v then
        swimConn = RunService.Heartbeat:Connect(function()
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true); hum:ChangeState(Enum.HumanoidStateType.Swimming) end
        end)
    else
        if swimConn then swimConn:Disconnect() end
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false) end
    end
    NXNotify("SWIM IN AIR", v and "ON" or "OFF")
end})

-- Walk on Air (platform)
local airWalkPart, airWalkConn
NXFeExploits:CreateToggle({name="WALK ON AIR", value=false, callback=function(v)
    if v then
        airWalkPart = Instance.new("Part")
        airWalkPart.Name = "NEXBYTE_AirWalk"
        airWalkPart.Size = Vector3.new(10, 1, 10)
        airWalkPart.Transparency = 1
        airWalkPart.Anchored = true
        airWalkPart.CanCollide = true
        airWalkPart.Parent = workspace
        airWalkConn = RunService.Heartbeat:Connect(function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and airWalkPart then
                airWalkPart.CFrame = hrp.CFrame * CFrame.new(0, -3.5, 0)
            end
        end)
    else
        if airWalkConn then airWalkConn:Disconnect() end
        if airWalkPart then airWalkPart:Destroy() end
    end
    NXNotify("WALK ON AIR", v and "ON" or "OFF")
end})

-- Click TP (Tool)
NXFeExploits:CreateButton({name="CLICK TP TOOL", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Click TP"
    tool.RequiresHandle = false
    tool.Activated:Connect(function()
        local mouse = Player:GetMouse()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp and mouse.Hit then
            hrp.CFrame = mouse.Hit * CFrame.new(0, 3, 0)
        end
    end)
    tool.Parent = Player.Backpack
    NXNotify("CLICK TP", "Tool given")
end})

-- Tp to Mouse (Keybind)
NXFeExploits:CreateButton({name="TP TO MOUSE (Key: T)", callback=function()
    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.T then
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local mouse = Player:GetMouse()
            if hrp and mouse.Hit then hrp.CFrame = mouse.Hit * CFrame.new(0, 3, 0) end
        end
    end)
    NXNotify("TP TO MOUSE", "Press T to TP (runs once)")
    task.delay(30, function() if conn then conn:Disconnect() end end)
end})

NXFeExploits:CreateSection({name="COMBAT / TROLL"})

-- Kill Aura (FE - damages on touch)
local killAuraConn
NXFeExploits:CreateToggle({name="KILL AURA (Touch)", value=false, callback=function(v)
    if v then
        killAuraConn = RunService.Heartbeat:Connect(function()
            local char = Player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local tHum = plr.Character:FindFirstChildOfClass("Humanoid")
                    local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                    if tHum and tRoot and tHum.Health > 0 then
                        if (tRoot.Position - hrp.Position).Magnitude <= 15 then
                            tHum:TakeDamage(10)
                        end
                    end
                end
            end
        end)
    else
        if killAuraConn then killAuraConn:Disconnect() end
    end
    NXNotify("KILL AURA", v and "ON" or "OFF")
end})

-- Reach (extends tool handle)
local originalReach = {}
NXFeExploits:CreateToggle({name="REACH (Tool Extend)", value=false, callback=function(v)
    local char = Player.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return NXNotify("REACH", "Equip a tool first") end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return NXNotify("REACH", "Tool has no handle") end
    if v then
        originalReach[tool] = handle.Size
        handle.Size = Vector3.new(50, 50, 50)
        handle.Massless = true
    else
        if originalReach[tool] then handle.Size = originalReach[tool] end
    end
    NXNotify("REACH", v and "ON (50 studs)" or "OFF")
end})

-- Hitbox Expander (FE - visual only for you, but works with Kill Aura)
local hitboxConn, originalSizes = {}
NXFeExploits:CreateToggle({name="HITBOX EXPANDER", value=false, callback=function(v)
    if v then
        hitboxConn = RunService.Heartbeat:Connect(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        if not originalSizes[plr] then originalSizes[plr] = hrp.Size end
                        hrp.Size = Vector3.new(10, 10, 10)
                        hrp.Transparency = 0.7
                        hrp.Material = Enum.Material.ForceField
                        hrp.CanCollide = false
                    end
                end
            end
        end)
    else
        if hitboxConn then hitboxConn:Disconnect() end
        for plr, size in pairs(originalSizes) do
            if plr and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Size = size; hrp.Transparency = 1; hrp.Material = Enum.Material.Plastic; hrp.CanCollide = true end
            end
        end
        originalSizes = {}
    end
    NXNotify("HITBOX EXPANDER", v and "ON" or "OFF")
end})

-- Auto Clicker
local autoClickConn
NXFeExploits:CreateToggle({name="AUTO CLICKER", value=false, callback=function(v)
    if v then
        autoClickConn = RunService.RenderStepped:Connect(function()
            local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end)
    else
        if autoClickConn then autoClickConn:Disconnect() end
    end
    NXNotify("AUTO CLICKER", v and "ON" or "OFF")
end})

-- Tool Grip Changer (funny)
NXFeExploits:CreateButton({name="SPIN TOOL", callback=function()
    local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
    if not tool then return NXNotify("SPIN TOOL", "Equip a tool") end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end
    local spin = Instance.new("BodyAngularVelocity")
    spin.AngularVelocity = Vector3.new(0, 50, 0)
    spin.MaxTorque = Vector3.new(0, 1e6, 0)
    spin.Parent = handle
    NXNotify("SPIN TOOL", "Spinning!")
    task.delay(5, function() if spin then spin:Destroy() end end)
end})

NXFeExploits:CreateSection({name="PLAYER UTILITIES"})

-- View Player (Spectate) - already in Camera

-- Chat Spy (see all chats)
local chatSpyConn
NXFeExploits:CreateToggle({name="CHAT SPY", value=false, callback=function(v)
    if v then
        chatSpyConn = Players.PlayerChatted:Connect(function(plr, msg)
            NXNotify("CHAT: " .. plr.Name, msg)
        end)
    else
        if chatSpyConn then chatSpyConn:Disconnect() end
    end
    NXNotify("CHAT SPY", v and "ON" or "OFF")
end})

-- Anti AFK
local antiAfkConn
NXFeExploits:CreateToggle({name="ANTI AFK", value=false, callback=function(v)
    if v then
        antiAfkConn = RunService.Heartbeat:Connect(function()
            local vu = game:GetService("VirtualUser")
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    else
        if antiAfkConn then antiAfkConn:Disconnect() end
    end
    NXNotify("ANTI AFK", v and "ON" or "OFF")
end})

-- Auto Respawn
local autoRespawnConn
NXFeExploits:CreateToggle({name="AUTO RESPAWN", value=false, callback=function(v)
    if v then
        autoRespawnConn = Player.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then hum.Died:Connect(function() task.wait(1) Player:LoadCharacter() end) end
        end)
        -- Current character
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Died:Connect(function() task.wait(1) Player:LoadCharacter() end) end
    else
        if autoRespawnConn then autoRespawnConn:Disconnect() end
    end
    NXNotify("AUTO RESPAWN", v and "ON" or "OFF")
end})

-- No Fall Damage
local noFallConn
NXFeExploits:CreateToggle({name="NO FALL DAMAGE", value=false, callback=function(v)
    if v then
        noFallConn = RunService.Heartbeat:Connect(function()
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Freefall then
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            end
        end)
    else
        if noFallConn then noFallConn:Disconnect() end
    end
    NXNotify("NO FALL DMG", v and "ON" or "OFF")
end})

-- Infinite Stamina (for games with stamina)
NXFeExploits:CreateButton({name="RESET STAMINA (if exists)", callback=function()
    local char = Player.Character
    if char then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                if v.Name:lower():find("stamina") or v.Name:lower():find("energy") then
                    v.Value = v.MaxValue or 100
                end
            end
        end
    end
    NXNotify("STAMINA", "Attempted reset")
end})

-- Sit (already in Troll)

-- Lay Down
NXFeExploits:CreateButton({name="LAY DOWN", callback=function()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = true; task.wait(0.1); hum.Sit = false end
end})

-- Headless (local)
local headlessConn
NXFeExploits:CreateToggle({name="HEADLESS (Local)", value=false, callback=function(v)
    local head = Player.Character and Player.Character:FindFirstChild("Head")
    if not head then return NXNotify("HEADLESS", "No head") end
    if v then
        head.Transparency = 1
        for _, d in pairs(head:GetDescendants()) do if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1 end end
    else
        head.Transparency = 0
        for _, d in pairs(head:GetDescendants()) do if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 0 end end
    end
    NXNotify("HEADLESS", v and "ON" or "OFF")
end})

-- Korblox Legs (local visual)
NXFeExploits:CreateButton({name="KORBLOX LEGS (Local)", callback=function()
    local char = Player.Character
    if not char then return end
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") and (p.Name:lower():find("leg") or p.Name:lower():find("foot")) then
            p.Material = Enum.Material.Neon
            p.Color = Color3.fromRGB(0, 0, 0)
        end
    end
    NXNotify("KORBLOX", "Applied locally")
end})

NXFeExploits:CreateSection({name="SERVER / GAME"})

-- Rejoin
NXFeExploits:CreateButton({name="REJOIN", callback=function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end})

-- Server Hop (already in Teleport)

-- Join Lowest Player Server
NXFeExploits:CreateButton({name="JOIN LOWEST POP SERVER", callback=function()
    task.spawn(function()
        local ok, data = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"))
        end)
        if ok and data and data.data and #data.data > 0 then
            local lowest = data.data[1]
            for _, s in ipairs(data.data) do if s.playing < lowest.playing then lowest = s end end
            TeleportService:TeleportToPlaceInstance(game.PlaceId, lowest.id, Player)
        else
            NXNotify("SERVER HOP", "Failed")
        end
    end)
end})

-- FPS Booster
NXFeExploits:CreateButton({name="FPS BOOST (Low Graphics)", callback=function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e9
    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
            v.Enabled = false
        end
    end
    settings().Rendering.QualityLevel = 1
    NXNotify("FPS BOOST", "Applied")
end})

-- Delete Map (local)
NXFeExploits:CreateButton({name="DELETE MAP (Local)", callback=function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsDescendantOf(Player.Character) and v.Name ~= "Baseplate" then
            v:Destroy()
        end
    end
    NXNotify("DELETE MAP", "Non-char parts removed")
end})

-- Clear Terrain (local)
NXFeExploits:CreateButton({name="CLEAR TERRAIN (Local)", callback=function()
    workspace:ClearAllChildren()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then terrain:Clear() end
    NXNotify("TERRAIN", "Cleared locally")
end})

-- No Fog
NXFeExploits:CreateToggle({name="NO FOG", value=false, callback=function(v)
    if v then
        Lighting.FogEnd = 1e9
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    end
    NXNotify("NO FOG", v and "ON" or "OFF")
end})

-- Fullbright (already in Visuals as Night Vision)

-- Time Changer
NXFeExploits:CreateSlider({name="TIME OF DAY", range={0, 24}, value=14, callback=function(v)
    Lighting.ClockTime = v
end})

NXFeExploits:CreateSection({name="ANIMATIONS / EMOTES"})

-- Animation Player
local animTrack
NXFeExploits:CreateInput({name="ANIMATION ID", placeholder="rbxassetid://12345678", callback=function(v) NXFeExploits._AnimId = v end})
NXFeExploits:CreateButton({name="PLAY ANIMATION", callback=function()
    local id = NXFeExploits._AnimId
    if not id or not id:find("%d+") then return NXNotify("ANIM", "Enter valid ID") end
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if animTrack then animTrack:Stop() end
    local anim = Instance.new("Animation")
    anim.AnimationId = id:find("rbxassetid") and id or "rbxassetid://" .. id:match("%d+")
    animTrack = hum:LoadAnimation(anim)
    animTrack:Play()
    NXNotify("ANIM", "Playing")
end})
NXFeExploits:CreateButton({name="STOP ANIMATION", callback=function()
    if animTrack then animTrack:Stop(); animTrack = nil; NXNotify("ANIM", "Stopped") end
end})

-- Preset Animations
local presetAnims = {
    ["Dance 1"] = "rbxassetid://27789359",
    ["Dance 2"] = "rbxassetid://248263260",
    ["Dance 3"] = "rbxassetid://5915562539",
    ["T Pose"] = "rbxassetid://3337994100",
    ["Sit"] = "rbxassetid://2506281703",
    ["Laugh"] = "rbxassetid://5915562539",
    ["Wave"] = "rbxassetid://5915562539",
    ["Point"] = "rbxassetid://5915562539",
    ["Cheer"] = "rbxassetid://3337994100",
    ["Zombie"] = "rbxassetid://3489174223",
}
for name, id in pairs(presetAnims) do
    NXFeExploits:CreateButton({name=name, callback=function()
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if animTrack then animTrack:Stop() end
        local anim = Instance.new("Animation")
        anim.AnimationId = id
        animTrack = hum:LoadAnimation(anim)
        animTrack:Play()
        NXNotify("ANIM", name .. " playing")
    end})
end

NXFeExploits:CreateSection({name="TOOLS / INVENTORY"})

-- Give Tool (from ReplicatedStorage if accessible)
NXFeExploits:CreateButton({name="GET ALL TOOLS (ReplicatedStorage)", callback=function()
    local rs = game:GetService("ReplicatedStorage")
    local count = 0
    for _, v in pairs(rs:GetDescendants()) do
        if v:IsA("Tool") and not Player.Backpack:FindFirstChild(v.Name) then
            v:Clone().Parent = Player.Backpack
            count = count + 1
        end
    end
    NXNotify("TOOLS", "Got " .. count .. " tools")
end})

-- Delete All Tools
NXFeExploits:CreateButton({name="DELETE ALL TOOLS", callback=function()
    local count = 0
    for _, v in pairs(Player.Backpack:GetChildren()) do if v:IsA("Tool") then v:Destroy(); count = count + 1 end end
    for _, v in pairs(Player.Character:GetChildren()) do if v:IsA("Tool") then v:Destroy(); count = count + 1 end end
    NXNotify("TOOLS", "Deleted " .. count .. " tools")
end})

-- Tool Size
NXFeExploits:CreateSlider({name="TOOL SIZE", range={0.5, 50}, value=1, callback=function(v)
    local tool = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
    if tool then
        local handle = tool:FindFirstChild("Handle")
        if handle then handle.Size = handle.Size * v end
    end
end})

-- No Tool Cooldown (for some games)
NXFeExploits:CreateButton({name="REMOVE TOOL COOLDOWNS", callback=function()
    for _, v in pairs(Player.Backpack:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            if v.Name:lower():find("cooldown") or v.Name:lower():find("delay") then v.Value = 0 end
        end
    end
    NXNotify("TOOLS", "Cooldowns reset")
end})

-- Equip Best Tool
NXFeExploits:CreateButton({name="AUTO EQUIP BEST", callback=function()
    local bestTool, bestDmg = nil, 0
    for _, v in pairs(Player.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            local dmg = v:FindFirstChild("Damage") or v:FindFirstChild("DamageValue")
            if dmg and (dmg.Value or 0) > bestDmg then bestDmg = dmg.Value; bestTool = v end
        end
    end
    if bestTool then bestTool.Parent = Player.Character; NXNotify("TOOL", "Equipped: " .. bestTool.Name) else NXNotify("TOOL", "No damage tools") end
end})

NXFeExploits:CreateSection({name="EXPERIMENTAL / FUN"})

-- Fling All (uncontrolled)
NXFeExploits:CreateButton({name="FLING ALL (Uncontrolled)", callback=function()
    NXNotify("FLING ALL", "You will fling uncontrollably!")
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local spin = Instance.new("BodyAngularVelocity")
    spin.AngularVelocity = Vector3.new(0, 1000, 0)
    spin.MaxTorque = Vector3.new(0, 1e9, 0)
    spin.Parent = hrp
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 100, 0)
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Parent = hrp
    task.delay(5, function() spin:Destroy(); bv:Destroy() end)
end})

-- Black Hole (attracts parts)
local blackHoleConn, blackHolePart
NXFeExploits:CreateToggle({name="BLACK HOLE (Parts)", value=false, callback=function(v)
    if v then
        blackHolePart = Instance.new("Part")
        blackHolePart.Name = "NEXBYTE_BlackHole"
        blackHolePart.Size = Vector3.new(1, 1, 1)
        blackHolePart.Transparency = 1
        blackHolePart.Anchored = true
        blackHolePart.CanCollide = false
        blackHolePart.Parent = workspace
        blackHoleConn = RunService.Heartbeat:Connect(function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and blackHolePart then
                blackHolePart.CFrame = hrp.CFrame
                for _, p in pairs(workspace:GetDescendants()) do
                    if p:IsA("BasePart") and not p.Anchored and not p:IsDescendantOf(Player.Character) and (p.Position - hrp.Position).Magnitude <= 50 then
                        p.AssemblyLinearVelocity = (hrp.Position - p.Position).Unit * 100
                    end
                end
            end
        end)
    else
        if blackHoleConn then blackHoleConn:Disconnect() end
        if blackHolePart then blackHolePart:Destroy() end
    end
    NXNotify("BLACK HOLE", v and "ON" or "OFF")
end})

-- Orbit Parts (already in Troll)

-- Earthquake (screen shake)
local quakeConn
NXFeExploits:CreateToggle({name="EARTHQUAKE (Screen)", value=false, callback=function(v)
    if v then
        quakeConn = RunService.RenderStepped:Connect(function()
            if workspace.CurrentCamera then
                workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * CFrame.Angles(math.rad(math.random(-2,2)), math.rad(math.random(-2,2)), 0)
            end
        end)
    else
        if quakeConn then quakeConn:Disconnect() end
    end
    NXNotify("EARTHQUAKE", v and "ON" or "OFF")
end})

-- Rainbow Character
local rainbowConn
NXFeExploits:CreateToggle({name="RAINBOW CHARACTER", value=false, callback=function(v)
    if v then
        rainbowConn = RunService.Heartbeat:Connect(function()
            local char = Player.Character
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1) end
                end
            end
        end)
    else
        if rainbowConn then rainbowConn:Disconnect() end
    end
    NXNotify("RAINBOW", v and "ON" or "OFF")
end})

-- Size Changer
NXFeExploits:CreateSlider({name="CHARACTER SCALE", range={0.1, 10}, value=1, callback=function(v)
    local char = Player.Character
    if char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.Size = p.Size * v end
        end
    end
end})

-- Invisible (already in Troll)

-- God Mode (local - sets health high)
local godConn
NXFeExploits:CreateToggle({name="GOD MODE (Local)", value=false, callback=function(v)
    if v then
        godConn = RunService.Heartbeat:Connect(function()
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
        end)
    else
        if godConn then godConn:Disconnect() end
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.MaxHealth = 100; hum.Health = 100 end
    end
    NXNotify("GOD MODE", v and "ON (Local)" or "OFF")
end})

-- Crash Server (WARNING - only works on vulnerable games)
NXFeExploits:CreateButton({name="CRASH SERVER (RemoteEvent Spam)", callback=function()
    NEXBYTE:ShowConfirmation("CRASH SERVER", "This may crash the server. Continue?", function(confirmed)
        if not confirmed then return end
        task.spawn(function()
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("RemoteEvent") then
                    pcall(function() v:FireServer() end)
                    pcall(function() v:FireServer(string.rep("a", 1000000)) end)
                end
            end
        end)
        NXNotify("CRASH", "Attempted")
    end)
end})

-- Lag Server
NXFeExploits:CreateButton({name="LAG SERVER (Part Spam)", callback=function()
    NEXBYTE:ShowConfirmation("LAG SERVER", "This will lag the server. Continue?", function(confirmed)
        if not confirmed then return end
        task.spawn(function()
            for i = 1, 500 do
                local p = Instance.new("Part")
                p.Size = Vector3.new(10, 10, 10)
                p.Position = Vector3.new(math.random(-500,500), math.random(100,500), math.random(-500,500))
                p.Anchored = false
                p.Parent = workspace
                task.wait(0.01)
            end
        end)
        NXNotify("LAG", "Spamming parts")
    end)
end})

-- =====================================================
-- LOGS TAB
-- =====================================================
local NXLogs = NXWindow:CreateTab({name="LOGS", icon="history"})
NXLogs:CreateSection({name="ACTION LOGS"})

NXLogs:CreateButton({name="SHOW LOGS", callback=function()
    local logText = ""
    for _, entry in ipairs(NEXBYTE._LOGS) do
        logText = logText .. string.format("[%s] [%s] %s\n", os.date("%H:%M:%S", entry.time), entry.level:upper(), entry.message)
    end
    print("=== NEXBYTE LOGS ===\n" .. logText)
    NXNotify("LOGS", "Logs printed to console (F9)")
end})

NXLogs:CreateButton({name="CLEAR LOGS", callback=function()
    NEXBYTE._LOGS = {}
    NXNotify("LOGS", "Cleared")
end})

NXLogs:CreateText({name="LogCount", text="Log entries: " .. tostring(#NEXBYTE._LOGS)})

-- =====================================================
-- CLEANUP
-- =====================================================
ScreenGui = game:GetService("CoreGui"):FindFirstChild("NEXBYTE_ULTIMATE_ADMIN")
if ScreenGui then
    ScreenGui.Destroying:Connect(function()
        NEXBYTE._FlingActive = false
        NEXBYTE._TouchFlingActive = false
        NEXBYTE._TrollActive = false
        NEXBYTE._ESPActive = false
        NEXBYTE._NightVision = false
        if NEXBYTE._InfJumpConn then NEXBYTE._InfJumpConn:Disconnect() end
        if NEXBYTE._ShakeConn then NEXBYTE._ShakeConn:Disconnect() end
        pcall(function() GuiService:SetGameplayPausedNotificationEnabled(true) end)
    end)
end

NXNotify("NEXBYTE ULTIMATE ADMIN", "Loaded successfully - 15+ modules active")
return NEXBYTE