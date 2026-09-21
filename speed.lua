--[[
    ═══════════════════════════════════════════
    SPEED PRO - Locked Edition
    ═══════════════════════════════════════════
    TikTok: strayshot3
    Telegram: BB12co
    ═══════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- ═══════════ CONFIG (LOCKED) ═══════════
local CONFIG = {
    targetSpeed = 49,
    baseWalk = 49,
    stepInterval = 0.06,
    maxStepPerTick = 4,
    jitterAmount = 0.2,
    credits = {
        tiktok = "strayshot3",
        telegram = "BB12co",
        tiktokURL = "https://www.tiktok.com/@strayshot3",
        telegramURL = "https://t.me/BB12co",
    },
    colors = {
        primary = Color3.fromRGB(90, 60, 220),
        accent = Color3.fromRGB(140, 100, 255),
        success = Color3.fromRGB(80, 220, 140),
        danger = Color3.fromRGB(220, 70, 90),
        bg = Color3.fromRGB(14, 12, 24),
        bgPanel = Color3.fromRGB(22, 18, 38),
        bgInput = Color3.fromRGB(32, 26, 52),
        text = Color3.fromRGB(240, 235, 255),
        textMuted = Color3.fromRGB(150, 145, 175),
        border = Color3.fromRGB(60, 50, 100),
    }
}

local enabled = false
local stepConn = nil
local writeConn = nil
local killerConn = nil
local lastStep = 0
local killed = 0
local scriptsKilled = 0

-- ═══════════ FORWARD DECLARE ═══════════
local TB

-- ═══════════ KILL HOSTILE SCRIPTS ═══════════
local hostileNames = {
    "AntiCollisionHighSeedPushBack",
    "AntiCollision",
    "FixCollisions",
    "AntiTP",
}

local function killHostile()
    scriptsKilled = 0
    local char = LP.Character
    if char then
        local desc = char:GetDescendants()
        for i = 1, #desc do
            local o = desc[i]
            if o.ClassName == "LocalScript" or o.ClassName == "Script" then
                for j = 1, #hostileNames do
                    if o.Name:find(hostileNames[j], 1, true) then
                        pcall(function() o.Disabled = true end)
                        pcall(function() o:Destroy() end)
                        scriptsKilled = scriptsKilled + 1
                        break
                    end
                end
            end
        end
    end
    local ps = LP:FindFirstChild("PlayerScripts")
    if ps then
        local desc = ps:GetDescendants()
        for i = 1, #desc do
            local o = desc[i]
            if o.ClassName == "LocalScript" then
                for j = 1, #hostileNames do
                    if o.Name:find(hostileNames[j], 1, true) then
                        pcall(function() o.Disabled = true end)
                        scriptsKilled = scriptsKilled + 1
                        break
                    end
                end
            end
        end
    end
    return scriptsKilled
end

-- ═══════════ KILL RIGSYNC ═══════════
local function killRig()
    if not getconnections then return 0 end
    local n = 0
    local char = LP.Character
    if not char then return 0 end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local ok, c = pcall(getconnections, hum:GetPropertyChangedSignal("WalkSpeed"))
        if ok and c then
            for _, x in pairs(c) do pcall(function() x:Disable() end); n = n + 1 end
        end
    end
    local list = RS:GetDescendants()
    for i = 1, #list do
        local o = list[i]
        local cls = o.ClassName
        if cls == "RemoteEvent" or cls == "UnreliableRemoteEvent" then
            local nm = o.Name
            if nm:find("Correction") or nm:find("Reconcile") 
                or nm:find("Probe") or nm:find("RigSync") 
                or nm:find("Primed") or nm:find("Wipe") then
                local ok2, c2 = pcall(getconnections, o.OnClientEvent)
                if ok2 and c2 then
                    for _, x in pairs(c2) do pcall(function() x:Disable() end); n = n + 1 end
                end
            end
        end
    end
    return n
end

-- ═══════════ CORE ═══════════
local function start()
    if enabled then return end
    enabled = true
    killed = killRig()
    scriptsKilled = killHostile()
    lastStep = tick()

    writeConn = RunService.RenderStepped:Connect(function()
        if not enabled then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        hum.WalkSpeed = CONFIG.baseWalk
        if hum.JumpPower < 100 then hum.JumpPower = 100 end
    end)

    stepConn = RunService.Heartbeat:Connect(function()
        if not enabled then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        local now = tick()
        local dt = now - lastStep
        if dt >= CONFIG.stepInterval then
            lastStep = now
            local dir = hum.MoveDirection
            if dir.Magnitude > 0.05 then
                local extra = (CONFIG.targetSpeed - CONFIG.baseWalk) * dt
                if extra > CONFIG.maxStepPerTick then extra = CONFIG.maxStepPerTick end
                local perp = Vector3.new(-dir.Z, 0, dir.X).Unit
                local jitter = perp * (math.random() - 0.5) * CONFIG.jitterAmount
                pcall(function()
                    hrp.CFrame = hrp.CFrame + (dir.Unit * extra) + jitter
                end)
            end
        end
    end)

    killerConn = task.spawn(function()
        while enabled do
            task.wait(1)
            killHostile()
        end
    end)
end

local function stop()
    enabled = false
    if stepConn then stepConn:Disconnect(); stepConn = nil end
    if writeConn then writeConn:Disconnect(); writeConn = nil end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

-- ═══════════ UI UTILS ═══════════
local C = CONFIG.colors

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.border
    s.Thickness = thickness or 1.5
    s.Transparency = 0.3
    s.Parent = parent
    return s
end

local function addGradient(parent, color1, color2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(color1, color2)
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end

-- ═══════════ SCREEN GUI ═══════════
local sg = Instance.new("ScreenGui")
sg.Name = "SpeedProUI"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 999
local ok = pcall(function()
    if gethui then sg.Parent = gethui()
    else sg.Parent = game:GetService("CoreGui") end
end)
if not ok then sg.Parent = LP:WaitForChild("PlayerGui") end

-- ═══════════ WELCOME POPUP ═══════════
local popup = Instance.new("Frame")
popup.Size = UDim2.new(0, 320, 0, 380)
popup.Position = UDim2.new(0.5, -160, 0.5, -190)
popup.BackgroundColor3 = C.bg
popup.BorderSizePixel = 0
popup.Active = true
popup.Draggable = true
popup.ZIndex = 100
popup.Parent = sg
addCorner(popup, 16)
addStroke(popup, C.primary, 2)

-- popup title bar
local popupTitle = Instance.new("TextLabel")
popupTitle.Size = UDim2.new(1, 0, 0, 60)
popupTitle.BackgroundColor3 = C.bgPanel
popupTitle.Text = "  SPEED PRO"
popupTitle.TextColor3 = C.text
popupTitle.Font = Enum.Font.GothamBold
popupTitle.TextSize = 20
popupTitle.TextXAlignment = Enum.TextXAlignment.Left
popupTitle.BorderSizePixel = 0
popupTitle.Parent = popup
addCorner(popupTitle, 16)
addGradient(popupTitle, C.primary, C.accent, 90)

-- wave icon
local icon = Instance.new("TextLabel")
icon.Size = UDim2.new(0, 40, 0, 40)
icon.Position = UDim2.new(1, -50, 0, 10)
icon.BackgroundTransparency = 1
icon.Text = "⚡"
icon.TextColor3 = C.text
icon.Font = Enum.Font.GothamBold
icon.TextSize = 28
icon.Parent = popup

-- welcome text
local wl = Instance.new("TextLabel")
wl.Size = UDim2.new(0.9, 0, 0, 40)
wl.Position = UDim2.new(0.05, 0, 0, 70)
wl.BackgroundTransparency = 1
wl.Text = "Welcome to Speed Pro"
wl.TextColor3 = C.text
wl.Font = Enum.Font.GothamBold
wl.TextSize = 18
wl.TextXAlignment = Enum.TextXAlignment.Center
wl.Parent = popup

local wl2 = Instance.new("TextLabel")
wl2.Size = UDim2.new(0.9, 0, 0, 50)
wl2.Position = UDim2.new(0.05, 0, 0, 112)
wl2.BackgroundTransparency = 1
wl2.Text = "Please subscribe to our TikTok\nfor hack updates"
wl2.TextColor3 = C.textMuted
wl2.Font = Enum.Font.Gotham
wl2.TextSize = 13
wl2.TextXAlignment = Enum.TextXAlignment.Center
wl2.TextWrapped = true
wl2.Parent = popup

-- TikTok button
local tiktokBtn = Instance.new("TextButton")
tiktokBtn.Size = UDim2.new(0.9, 0, 0, 50)
tiktokBtn.Position = UDim2.new(0.05, 0, 0, 175)
tiktokBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
tiktokBtn.Text = ""
tiktokBtn.BorderSizePixel = 0
tiktokBtn.AutoButtonColor = false
tiktokBtn.Parent = popup
addCorner(tiktokBtn, 10)
addStroke(tiktokBtn, Color3.fromRGB(255, 80, 120), 1.5)

local tkIcon = Instance.new("TextLabel")
tkIcon.Size = UDim2.new(0, 50, 1, 0)
tkIcon.BackgroundTransparency = 1
tkIcon.Text = "♪"
tkIcon.TextColor3 = Color3.fromRGB(255, 80, 120)
tkIcon.Font = Enum.Font.GothamBold
tkIcon.TextSize = 26
tkIcon.Parent = tiktokBtn

local tkLabel = Instance.new("TextLabel")
tkLabel.Size = UDim2.new(1, -60, 1, 0)
tkLabel.Position = UDim2.new(0, 55, 0, 0)
tkLabel.BackgroundTransparency = 1
tkLabel.Text = "TikTok: @" .. CONFIG.credits.tiktok
tkLabel.TextColor3 = C.text
tkLabel.Font = Enum.Font.GothamBold
tkLabel.TextSize = 13
tkLabel.TextXAlignment = Enum.TextXAlignment.Left
tkLabel.Parent = tiktokBtn

tiktokBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        pcall(function() setclipboard(CONFIG.credits.tiktokURL) end)
    end
    tkLabel.Text = "Link copied!"
    task.wait(1.5)
    tkLabel.Text = "TikTok: @" .. CONFIG.credits.tiktok
end)

-- Telegram button
local tgBtn = Instance.new("TextButton")
tgBtn.Size = UDim2.new(0.9, 0, 0, 50)
tgBtn.Position = UDim2.new(0.05, 0, 0, 232)
tgBtn.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
tgBtn.Text = ""
tgBtn.BorderSizePixel = 0
tgBtn.AutoButtonColor = false
tgBtn.Parent = popup
addCorner(tgBtn, 10)
addStroke(tgBtn, Color3.fromRGB(80, 180, 255), 1.5)

local tgIcon = Instance.new("TextLabel")
tgIcon.Size = UDim2.new(0, 50, 1, 0)
tgIcon.BackgroundTransparency = 1
tgIcon.Text = "✈"
tgIcon.TextColor3 = Color3.fromRGB(80, 180, 255)
tgIcon.Font = Enum.Font.GothamBold
tgIcon.TextSize = 22
tgIcon.Parent = tgBtn

local tgLabel = Instance.new("TextLabel")
tgLabel.Size = UDim2.new(1, -60, 1, 0)
tgLabel.Position = UDim2.new(0, 55, 0, 0)
tgLabel.BackgroundTransparency = 1
tgLabel.Text = "Telegram: " .. CONFIG.credits.telegram
tgLabel.TextColor3 = C.text
tgLabel.Font = Enum.Font.GothamBold
tgLabel.TextSize = 13
tgLabel.TextXAlignment = Enum.TextXAlignment.Left
tgLabel.Parent = tgBtn

tgBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        pcall(function() setclipboard(CONFIG.credits.telegramURL) end)
    end
    tgLabel.Text = "Link copied!"
    task.wait(1.5)
    tgLabel.Text = "Telegram: " .. CONFIG.credits.telegram
end)

-- OK button
local okBtn = Instance.new("TextButton")
okBtn.Size = UDim2.new(0.9, 0, 0, 50)
okBtn.Position = UDim2.new(0.05, 0, 0, 300)
okBtn.BackgroundColor3 = C.success
okBtn.Text = "OK — LET'S GO"
okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
okBtn.Font = Enum.Font.GothamBold
okBtn.TextSize = 15
okBtn.BorderSizePixel = 0
okBtn.Parent = popup
addCorner(okBtn, 10)
addGradient(okBtn, C.success, Color3.fromRGB(60, 180, 120), 90)

okBtn.MouseButton1Click:Connect(function()
    TweenService:Create(popup, TweenInfo.new(0.25), {
        Size = UDim2.new(0, 320, 0, 0),
        Position = UDim2.new(0.5, -160, 0.5, 0),
    }):Play()
    task.wait(0.3)
    popup.Visible = false
    if TB then TB.Visible = true end
end)

-- popup entrance animation
popup.Size = UDim2.new(0, 0, 0, 0)
popup.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(popup, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 320, 0, 380),
    Position = UDim2.new(0.5, -160, 0.5, -190),
}):Play()

-- ═══════════ MAIN TOGGLE BUTTON ═══════════
TB = Instance.new("TextButton")
TB.Size = UDim2.new(0, 65, 0, 65)
TB.Position = UDim2.new(0, 15, 0.72, 0)
TB.BackgroundColor3 = C.primary
TB.Text = "⚡"
TB.TextColor3 = Color3.fromRGB(255, 255, 255)
TB.Font = Enum.Font.GothamBold
TB.TextSize = 26
TB.BorderSizePixel = 0
TB.Active = true
TB.Draggable = true
TB.Visible = false
TB.Parent = sg
addCorner(TB, 32)
addGradient(TB, C.primary, C.accent, 45)
addStroke(TB, C.accent, 2)

-- ═══════════ MAIN PANEL ═══════════
local M = Instance.new("Frame")
M.Size = UDim2.new(0, 260, 0, 340)
M.Position = UDim2.new(0, 15, 0.25, -170)
M.BackgroundColor3 = C.bg
M.BorderSizePixel = 0
M.Active = true
M.Draggable = true
M.Visible = false
M.Parent = sg
addCorner(M, 16)
addStroke(M, C.primary, 2)

-- header with gradient
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = C.bgPanel
header.Text = "  SPEED PRO"
header.TextColor3 = C.text
header.Font = Enum.Font.GothamBold
header.TextSize = 16
header.TextXAlignment = Enum.TextXAlignment.Left
header.BorderSizePixel = 0
header.Parent = M
addCorner(header, 16)
addGradient(header, C.primary, C.accent, 90)

-- lock badge
local lockBadge = Instance.new("TextLabel")
lockBadge.Size = UDim2.new(0, 55, 0, 26)
lockBadge.Position = UDim2.new(1, -65, 0, 12)
lockBadge.BackgroundColor3 = C.success
lockBadge.Text = "LOCKED"
lockBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
lockBadge.Font = Enum.Font.GothamBold
lockBadge.TextSize = 9
lockBadge.BorderSizePixel = 0
lockBadge.Parent = header
addCorner(lockBadge, 13)

TB.MouseButton1Click:Connect(function()
    M.Visible = not M.Visible
    if M.Visible then
        M.Size = UDim2.new(0, 0, 0, 0)
        M.Position = UDim2.new(0, 15, 0.25, 0)
        TweenService:Create(M, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 260, 0, 340),
            Position = UDim2.new(0, 15, 0.25, -170),
        }):Play()
    end
end)

-- speed display
local speedBox = Instance.new("Frame")
speedBox.Size = UDim2.new(0.9, 0, 0, 70)
speedBox.Position = UDim2.new(0.05, 0, 0, 62)
speedBox.BackgroundColor3 = C.bgInput
speedBox.BorderSizePixel = 0
speedBox.Parent = M
addCorner(speedBox, 12)
addStroke(speedBox, C.border, 1)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 24)
speedLabel.Position = UDim2.new(0, 0, 0, 8)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "TARGET SPEED"
speedLabel.TextColor3 = C.textMuted
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 10
speedLabel.Parent = speedBox

local speedValue = Instance.new("TextLabel")
speedValue.Size = UDim2.new(1, 0, 0, 36)
speedValue.Position = UDim2.new(0, 0, 0, 28)
speedValue.BackgroundTransparency = 1
speedValue.Text = "49"
speedValue.TextColor3 = C.accent
speedValue.Font = Enum.Font.GothamBold
speedValue.TextSize = 30
speedValue.Parent = speedBox

-- locked bar
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(0.9, 0, 0, 22)
barBg.Position = UDim2.new(0.05, 0, 0, 142)
barBg.BackgroundColor3 = C.bgInput
barBg.BorderSizePixel = 0
barBg.Parent = M
addCorner(barBg, 11)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.BackgroundColor3 = C.accent
barFill.BorderSizePixel = 0
barFill.Parent = barBg
addCorner(barFill, 11)
addGradient(barFill, C.primary, C.accent, 0)

local barKnob = Instance.new("TextButton")
barKnob.Size = UDim2.new(0, 30, 0, 30)
barKnob.Position = UDim2.new(1, -15, 0.5, -15)
barKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
barKnob.Text = "🔒"
barKnob.TextColor3 = C.primary
barKnob.Font = Enum.Font.GothamBold
barKnob.TextSize = 13
barKnob.BorderSizePixel = 0
barKnob.AutoButtonColor = false
barKnob.Parent = barBg
addCorner(barKnob, 15)

-- enable button
local enableBtn = Instance.new("TextButton")
enableBtn.Size = UDim2.new(0.9, 0, 0, 52)
enableBtn.Position = UDim2.new(0.05, 0, 0, 174)
enableBtn.BackgroundColor3 = C.success
enableBtn.Text = "ENABLE"
enableBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
enableBtn.Font = Enum.Font.GothamBold
enableBtn.TextSize = 16
enableBtn.BorderSizePixel = 0
enableBtn.AutoButtonColor = false
enableBtn.Parent = M
addCorner(enableBtn, 10)
addGradient(enableBtn, C.success, Color3.fromRGB(60, 170, 110), 90)

enableBtn.MouseButton1Click:Connect(function()
    if enabled then
        stop()
        enableBtn.Text = "ENABLE"
        TweenService:Create(enableBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = C.success,
        }):Play()
    else
        start()
        enableBtn.Text = "DISABLE"
        TweenService:Create(enableBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = C.danger,
        }):Play()
    end
end)

-- status panel
local statusBox = Instance.new("Frame")
statusBox.Size = UDim2.new(0.9, 0, 0, 48)
statusBox.Position = UDim2.new(0.05, 0, 0, 234)
statusBox.BackgroundColor3 = C.bgPanel
statusBox.BorderSizePixel = 0
statusBox.Parent = M
addCorner(statusBox, 8)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(0, 12, 0, 20)
statusDot.BackgroundColor3 = C.textMuted
statusDot.BorderSizePixel = 0
statusDot.Parent = statusBox
addCorner(statusDot, 4)

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -40, 1, 0)
statusText.Position = UDim2.new(0, 30, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "System ready"
statusText.TextColor3 = C.text
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 12
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusBox

task.spawn(function()
    while true do
        task.wait(0.5)
        if enabled then
            statusDot.BackgroundColor3 = C.success
            statusText.Text = "Active  ·  49  ·  killing: " .. scriptsKilled
        else
            statusDot.BackgroundColor3 = C.textMuted
            statusText.Text = "System ready"
        end
    end
end)

-- credits footer
local footer = Instance.new("Frame")
footer.Size = UDim2.new(1, 0, 0, 54)
footer.Position = UDim2.new(0, 0, 1, -54)
footer.BackgroundColor3 = C.bgPanel
footer.BorderSizePixel = 0
footer.Parent = M
addCorner(footer, 16)

local creditTitle = Instance.new("TextLabel")
creditTitle.Size = UDim2.new(1, 0, 0, 18)
creditTitle.Position = UDim2.new(0, 0, 0, 6)
creditTitle.BackgroundTransparency = 1
creditTitle.Text = "© SPEED PRO  ·  strayshot3"
creditTitle.TextColor3 = C.textMuted
creditTitle.Font = Enum.Font.GothamBold
creditTitle.TextSize = 10
creditTitle.Parent = footer

local creditRow = Instance.new("Frame")
creditRow.Size = UDim2.new(1, 0, 0, 20)
creditRow.Position = UDim2.new(0, 0, 0, 26)
creditRow.BackgroundTransparency = 1
creditRow.Parent = footer

local tkCredit = Instance.new("TextButton")
tkCredit.Size = UDim2.new(0.45, 0, 1, 0)
tkCredit.Position = UDim2.new(0.05, 0, 0, 0)
tkCredit.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
tkCredit.Text = "♪ TikTok"
tkCredit.TextColor3 = Color3.fromRGB(255, 120, 160)
tkCredit.Font = Enum.Font.GothamBold
tkCredit.TextSize = 10
tkCredit.BorderSizePixel = 0
tkCredit.Parent = creditRow
addCorner(tkCredit, 6)
tkCredit.MouseButton1Click:Connect(function()
    if setclipboard then
        pcall(function() setclipboard(CONFIG.credits.tiktokURL) end)
        tkCredit.Text = "Copied!"
        task.wait(1.2)
        tkCredit.Text = "♪ TikTok"
    end
end)

local tgCredit = Instance.new("TextButton")
tgCredit.Size = UDim2.new(0.45, 0, 1, 0)
tgCredit.Position = UDim2.new(0.5, 0, 0, 0)
tgCredit.BackgroundColor3 = Color3.fromRGB(20, 28, 45)
tgCredit.Text = "✈ Telegram"
tgCredit.TextColor3 = Color3.fromRGB(100, 190, 255)
tgCredit.Font = Enum.Font.GothamBold
tgCredit.TextSize = 10
tgCredit.BorderSizePixel = 0
tgCredit.Parent = creditRow
addCorner(tgCredit, 6)
tgCredit.MouseButton1Click:Connect(function()
    if setclipboard then
        pcall(function() setclipboard(CONFIG.credits.telegramURL) end)
        tgCredit.Text = "Copied!"
        task.wait(1.2)
        tgCredit.Text = "✈ Telegram"
    end
end)

-- respawn handling
LP.CharacterAdded:Connect(function()
    task.wait(1)
    if enabled then stop(); task.wait(0.1); start() end
end)

print("[SPEED PRO] loaded | TikTok: strayshot3 | Telegram: BB12co")
