-- NEXBYTE TROLL v4.0
-- Reuses the original NEXBYTE ADMIN handlers from the public repository.
-- Floating dark mobile UI wrapper. No fake SERVER REQUIRED buttons.

local SOURCE_URL = "https://raw.githubusercontent.com/kalilunox/NEXBYTE/master/NEXBYTE.lua"

local ok, source = pcall(function()
    return game:HttpGet(SOURCE_URL)
end)

if not ok or type(source) ~= "string" or #source < 1000 then
    warn("NEXBYTE TROLL: couldn't download the original NEXBYTE.lua")
    return
end

if not source:find("SkidFling", 1, true) or not source:find("TrollToolKill", 1, true) then
    warn("NEXBYTE TROLL: repository source doesn't match the expected NEXBYTE ADMIN version")
    return
end

local UI_PATCH = [==[
-- =====================================================
-- NEXBYTE TROLL v4.0 - FLOATING UI PATCH
-- Appended to the original NEXBYTE.lua so its local
-- functions and event handlers remain in the same scope.
-- =====================================================

local NXGui = ScreenGui
NXGui.Name = "NEXBYTE_TROLL"
NXGui.ResetOnSpawn = false
NXGui.IgnoreGuiInset = true
NXGui.DisplayOrder = 10000

-- Hide the old layout, but keep its function closures alive.
if MainFrame then MainFrame.Visible = false end
if MiniButton then MiniButton.Visible = false end

local NXTheme = {
    BG = Color3.fromRGB(5, 7, 10),
    PANEL = Color3.fromRGB(13, 16, 22),
    ROW = Color3.fromRGB(21, 25, 33),
    ACCENT = Color3.fromRGB(0, 195, 235),
    ACCENT_DARK = Color3.fromRGB(0, 87, 112),
    TEXT = Color3.fromRGB(232, 240, 247),
    MUTED = Color3.fromRGB(120, 135, 150),
    RED = Color3.fromRGB(165, 43, 55),
    GREEN = Color3.fromRGB(0, 125, 100)
}

local function NXCorner(obj, radius)
    if not obj:FindFirstChildOfClass("UICorner") then
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 8)
        c.Parent = obj
    end
end

local function NXStroke(obj, color, transparency)
    local s = obj:FindFirstChildOfClass("UIStroke")
    if not s then
        s = Instance.new("UIStroke")
        s.Parent = obj
    end
    s.Color = color or NXTheme.ACCENT
    s.Transparency = transparency or 0.72
    s.Thickness = 1
end

local Window = Instance.new("Frame")
Window.Name = "NEXBYTE_FLOATING_WINDOW"
Window.Size = UDim2.fromOffset(340, 530)
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.Position = UDim2.fromScale(0.5, 0.5)
Window.BackgroundColor3 = NXTheme.BG
Window.BackgroundTransparency = 0.12
Window.BorderSizePixel = 0
Window.Active = true
Window.ClipsDescendants = true
Window.Parent = NXGui
NXCorner(Window, 13)
NXStroke(Window, NXTheme.ACCENT, 0.35)

local scale = Instance.new("UIScale")
scale.Scale = UIS.TouchEnabled and 0.88 or 1
scale.Parent = Window

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = NXTheme.PANEL
Header.BackgroundTransparency = 0.08
Header.BorderSizePixel = 0
Header.Parent = Window
NXCorner(Header, 13)

local Brand = Instance.new("TextLabel")
Brand.Size = UDim2.new(1, -100, 1, 0)
Brand.Position = UDim2.fromOffset(13, 0)
Brand.BackgroundTransparency = 1
Brand.Text = "NEXBYTE  /  TROLL"
Brand.TextColor3 = NXTheme.ACCENT
Brand.Font = Enum.Font.GothamBold
Brand.TextSize = 15
Brand.TextXAlignment = Enum.TextXAlignment.Left
Brand.Parent = Header

local function NXHeaderButton(name, label, x, color)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.fromOffset(30, 28)
    b.Position = UDim2.new(1, x, 0, 7)
    b.BackgroundColor3 = color
    b.BackgroundTransparency = 0.05
    b.Text = label
    b.TextColor3 = NXTheme.TEXT
    b.Font = Enum.Font.GothamBold
    b.TextSize = 16
    b.Parent = Header
    NXCorner(b, 6)
    return b
end

local Minimize = NXHeaderButton("Minimize", "—", -70, NXTheme.ROW)
local Close = NXHeaderButton("Close", "×", -35, NXTheme.RED)

-- Drag from the header; works with mouse and touch.
local UIS = game:GetService("UserInputService")
local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position.X >= Header.AbsolutePosition.X + Header.AbsoluteSize.X - 78 then
            return
        end
        dragging = true
        dragStart = input.Position
        startPosition = Window.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Window.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -16, 0, 34)
TabBar.Position = UDim2.fromOffset(8, 50)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Window

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 5)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabBar

local Pages = {}
for _, name in ipairs({"TARGETS", "TROLL", "TOOLS"}) do
    local page = Instance.new("Frame")
    page.Name = name .. "_PAGE"
    page.Size = UDim2.new(1, -16, 1, -100)
    page.Position = UDim2.fromOffset(8, 92)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = Window
    Pages[name] = page

    local tab = Instance.new("TextButton")
    tab.Name = name .. "_TAB"
    tab.Size = UDim2.fromOffset(101, 30)
    tab.BackgroundColor3 = NXTheme.ROW
    tab.BackgroundTransparency = 0.08
    tab.Text = name
    tab.TextColor3 = NXTheme.TEXT
    tab.Font = Enum.Font.GothamBold
    tab.TextSize = 10
    tab.LayoutOrder = #TabBar:GetChildren()
    tab.Parent = TabBar
    NXCorner(tab, 7)
    NXStroke(tab, NXTheme.ACCENT, 0.85)
    tab.MouseButton1Click:Connect(function()
        for pageName, pageObject in pairs(Pages) do
            pageObject.Visible = pageName == name
        end
        for _, other in ipairs(TabBar:GetChildren()) do
            if other:IsA("TextButton") then
                other.BackgroundColor3 = other == tab and NXTheme.ACCENT_DARK or NXTheme.ROW
                other.TextColor3 = other == tab and NXTheme.ACCENT or NXTheme.TEXT
            end
        end
    end)
end

local function NXStyleExisting(button, parent, text, y, height, color)
    button.Parent = parent
    button.Position = UDim2.fromOffset(0, y)
    button.Size = UDim2.new(1, 0, 0, height)
    button.BackgroundColor3 = color or NXTheme.ROW
    button.BackgroundTransparency = 0.12
    button.Text = text
    button.TextColor3 = NXTheme.TEXT
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.Visible = true
    button.AutoButtonColor = true
    NXCorner(button, 8)
    NXStroke(button, NXTheme.ACCENT, 0.8)
end

-- TARGETS PAGE: reuse the original multi-select player list + Fling handlers.
local TargetsPage = Pages.TARGETS
local Search = Instance.new("TextBox")
Search.Name = "PlayerSearch"
Search.Size = UDim2.new(1, 0, 0, 32)
Search.Position = UDim2.fromOffset(0, 0)
Search.BackgroundColor3 = NXTheme.ROW
Search.BackgroundTransparency = 0.08
Search.PlaceholderText = "Search player..."
Search.PlaceholderColor3 = NXTheme.MUTED
Search.Text = ""
Search.TextColor3 = NXTheme.TEXT
Search.Font = Enum.Font.Gotham
Search.TextSize = 12
Search.ClearTextOnFocus = false
Search.Parent = TargetsPage
NXCorner(Search, 7)
NXStroke(Search, NXTheme.ACCENT, 0.87)

SelectionFrame.Parent = TargetsPage
SelectionFrame.Position = UDim2.fromOffset(0, 39)
SelectionFrame.Size = UDim2.new(1, 0, 0, 242)
SelectionFrame.BackgroundColor3 = NXTheme.PANEL
SelectionFrame.BackgroundTransparency = 0.16
SelectionFrame.BorderSizePixel = 0
NXCorner(SelectionFrame, 8)
NXStroke(SelectionFrame, NXTheme.ACCENT, 0.84)

PlayerScrollFrame.Position = UDim2.fromOffset(6, 6)
PlayerScrollFrame.Size = UDim2.new(1, -12, 1, -12)
PlayerScrollFrame.BackgroundTransparency = 1
PlayerScrollFrame.ScrollBarThickness = 3
PlayerScrollFrame.ScrollBarImageColor3 = NXTheme.ACCENT

StatusLabel.Parent = TargetsPage
StatusLabel.Position = UDim2.fromOffset(0, 286)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = NXTheme.ACCENT
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

NXStyleExisting(StartButton, TargetsPage, "START FLING", 314, 39, NXTheme.GREEN)
StartButton.Size = UDim2.new(0.5, -4, 0, 39)
NXStyleExisting(StopButton, TargetsPage, "STOP FLING", 314, 39, NXTheme.RED)
StopButton.Position = UDim2.new(0.5, 4, 0, 314)
StopButton.Size = UDim2.new(0.5, -4, 0, 39)
NXStyleExisting(SelectAllButton, TargetsPage, "SELECT ALL", 361, 34, NXTheme.ROW)
SelectAllButton.Size = UDim2.new(0.5, -4, 0, 34)
NXStyleExisting(DeselectAllButton, TargetsPage, "CLEAR SELECT", 361, 34, NXTheme.ROW)
DeselectAllButton.Position = UDim2.new(0.5, 4, 0, 361)
DeselectAllButton.Size = UDim2.new(0.5, -4, 0, 34)

-- Search filters the original player rows, keeping the original selection state.
local function NXApplyPlayerFilter()
    local term = Search.Text:lower()
    local visibleCount = 0
    for _, entry in ipairs(PlayerScrollFrame:GetChildren()) do
        if entry:IsA("Frame") then
            local playerName = ""
            for _, child in ipairs(entry:GetChildren()) do
                if child:IsA("TextLabel") and child.Text ~= "✓" then
                    playerName = child.Text
                    break
                end
            end
            local show = term == "" or playerName:lower():find(term, 1, true) ~= nil
            entry.Visible = show
            if show then
                entry.Position = UDim2.fromOffset(5, 5 + visibleCount * 35)
                visibleCount += 1
            end
        end
    end
    PlayerScrollFrame.CanvasSize = UDim2.fromOffset(0, visibleCount * 35 + 8)
end

Search:GetPropertyChangedSignal("Text"):Connect(NXApplyPlayerFilter)
RefreshButton.MouseButton1Click:Connect(function()
    task.delay(0.2, NXApplyPlayerFilter)
end)
Players.PlayerAdded:Connect(function()
    task.delay(0.35, NXApplyPlayerFilter)
end)
Players.PlayerRemoving:Connect(function()
    task.delay(0.2, NXApplyPlayerFilter)
end)
task.delay(0.2, NXApplyPlayerFilter)

-- TROLL PAGE: move the original buttons; their original callbacks remain connected.
local TrollPage = Pages.TROLL
NXStyleExisting(TrollBring, TrollPage, "BRING", 8, 42, NXTheme.ACCENT_DARK)
NXStyleExisting(TrollToolKill, TrollPage, "TOOL KILL", 60, 42, NXTheme.ACCENT_DARK)
NXStyleExisting(TrollTouchFling, TrollPage, "TOUCH FLING: OFF", 112, 42, NXTheme.ACCENT_DARK)

local TrollNote = Instance.new("TextLabel")
TrollNote.Size = UDim2.new(1, -8, 0, 54)
TrollNote.Position = UDim2.fromOffset(4, 170)
TrollNote.BackgroundTransparency = 1
TrollNote.Text = "BRING uses the original movement routine. TOOL KILL needs an equipped compatible Tool. TOUCH FLING uses the original physics routine."
TrollNote.TextColor3 = NXTheme.MUTED
TrollNote.Font = Enum.Font.Gotham
TrollNote.TextSize = 10
TrollNote.TextWrapped = true
TrollNote.TextXAlignment = Enum.TextXAlignment.Left
TrollNote.TextYAlignment = Enum.TextYAlignment.Top
TrollNote.Parent = TrollPage

-- TOOLS PAGE: original TP / spectate / refresh / pause-notification controls.
local ToolsPage = Pages.TOOLS
NXStyleExisting(TPButton, ToolsPage, "TP TO", 8, 42, NXTheme.ACCENT_DARK)
NXStyleExisting(EyeButton, ToolsPage, "EYE", 60, 42, NXTheme.ROW)
NXStyleExisting(RefreshButton, ToolsPage, "REFRESH PLAYERS", 112, 42, NXTheme.ROW)
NXStyleExisting(PauseButton, ToolsPage, "PAUSE NOTIFICATION", 164, 42, NXTheme.ROW)

local ToolsNote = Instance.new("TextLabel")
ToolsNote.Size = UDim2.new(1, -8, 0, 42)
ToolsNote.Position = UDim2.fromOffset(4, 222)
ToolsNote.BackgroundTransparency = 1
ToolsNote.Text = "EYE toggles camera spectating. PAUSE changes the built-in paused notification only."
ToolsNote.TextColor3 = NXTheme.MUTED
ToolsNote.Font = Enum.Font.Gotham
ToolsNote.TextSize = 10
ToolsNote.TextWrapped = true
ToolsNote.TextXAlignment = Enum.TextXAlignment.Left
ToolsNote.TextYAlignment = Enum.TextYAlignment.Top
ToolsNote.Parent = ToolsPage

-- Floating restore chip.
local Restore = Instance.new("TextButton")
Restore.Name = "NEXBYTE_FLOATING_RESTORE"
Restore.Size = UDim2.fromOffset(132, 38)
Restore.Position = UDim2.new(0, 12, 0.55, 0)
Restore.BackgroundColor3 = NXTheme.BG
Restore.BackgroundTransparency = 0.08
Restore.Text = "NEXBYTE  +"
Restore.TextColor3 = NXTheme.ACCENT
Restore.Font = Enum.Font.GothamBold
Restore.TextSize = 12
Restore.Visible = false
Restore.Parent = NXGui
NXCorner(Restore, 9)
NXStroke(Restore, NXTheme.ACCENT, 0.25)

Minimize.MouseButton1Click:Connect(function()
    Window.Visible = false
    Restore.Visible = true
end)

Restore.MouseButton1Click:Connect(function()
    Window.Visible = true
    Restore.Visible = false
end)

Close.MouseButton1Click:Connect(function()
    -- Stop active loops before removing the interface.
    pcall(function()
        if BringActive then BringActive = false end
        if TouchFlingActive then TouchFlingActive = false end
        StopFling()
        RestoreCamera()
        GuiService:SetGameplayPausedNotificationEnabled(OriginalPauseState)
    end)
    NXGui:Destroy()
end)

-- Remove the previous layout after all working controls have been reparented.
if MiniButton then
    pcall(function() MiniButton:Destroy() end)
end
if MainFrame then
    pcall(function() MainFrame:Destroy() end)
end

-- Start on the target selector tab.
Pages.TARGETS.Visible = true
for _, tab in ipairs(TabBar:GetChildren()) do
    if tab:IsA("TextButton") then
        tab.BackgroundColor3 = tab.Name == "TARGETS_TAB" and NXTheme.ACCENT_DARK or NXTheme.ROW
        tab.TextColor3 = tab.Name == "TARGETS_TAB" and NXTheme.ACCENT or NXTheme.TEXT
    end
end

UpdateStatus()
Message("NEXBYTE", "TROLL v4.0 loaded - original handlers preserved", 3)
]==]

local okRun, err = pcall(function()
    local chunk, compileError = loadstring(source .. "\n" .. UI_PATCH)
    if not chunk then error(compileError) end
    chunk()
end)

if not okRun then
    warn("NEXBYTE TROLL v4.0 error: " .. tostring(err))
end
