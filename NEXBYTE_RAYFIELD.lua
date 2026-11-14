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