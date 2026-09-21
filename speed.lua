--[[
    ═══════════════════════════════════════════
    SPEED PRO - Clean Edition
    ═══════════════════════════════════════════
    TikTok: strayshot3
    Telegram: BB12co
    ═══════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

-- ═══════════ CONFIG ═══════════
local targetSpeed = 49
local baseWalk = 49
local stepInterval = 0.06
local maxStepPerTick = 4
local jitterAmount = 0.2
local tiktokUser = "strayshot3"
local telegramUser = "BB12co"
local tiktokURL = "https://www.tiktok.com/@strayshot3"
local telegramURL = "https://t.me/BB12co"

-- ═══════════ STATE ═══════════
local enabled = false
local menuOpen = false
local stepConn = nil
local writeConn = nil
local killerConn = nil
local lastStep = 0
local scriptsKilled = 0

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
end

-- ═══════════ KILL RIGSYNC CONNECTIONS ═══════════
local function killRig()
    if not getconnections then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local ok, c = pcall(getconnections, hum:GetPropertyChangedSignal("WalkSpeed"))
        if ok and c then
            for _, x in pairs(c) do pcall(function() x:Disable() end) end
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
                    for _, x in pairs(c2) do pcall(function() x:Disable() end) end
                end
            end
        end
    end
end

-- ═══════════ CORE ═══════════
local function start()
    if enabled then return end
    enabled = true
    killRig()
    killHostile()
    lastStep = tick()

    writeConn = RunService.RenderStepped:Connect(function()
        if not enabled then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        hum.WalkSpeed = baseWalk
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
        if dt >= stepInterval then
            lastStep = now
            local dir = hum.MoveDirection
            if dir.Magnitude > 0.05 then
                local extra = (targetSpeed - baseWalk) * dt
                if extra > maxStepPerTick then extra = maxStepPerTick end
                local perp = Vector3.new(-dir.Z, 0, dir.X).Unit
                local jitter = perp * (math.random() - 0.5) * jitterAmount
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

-- ═══════════ GUI ═══════════
local sg = Instance.new("ScreenGui")
sg.Name = "SpeedProClean"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 999
pcall(function()
    if gethui then sg.Parent = gethui()
    else sg.Parent = game:GetService("CoreGui") end
end)
if not sg.Parent then
    sg.Parent = LP:WaitForChild("PlayerGui")
end

-- ═══════════ FLOATING BUTTON ═══════════
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 55, 0, 55)
FloatBtn.Position = UDim2.new(0, 15, 0.7, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(90, 60, 220)
FloatBtn.Text = "⚡"
FloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 24
FloatBtn.BorderSizePixel = 0
FloatBtn.Active = true
FloatBtn.Draggable = true
FloatBtn.Parent = sg

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(0, 28)
floatCorner.Parent = FloatBtn

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = Color3.fromRGB(140, 100, 255)
floatStroke.Thickness = 2
floatStroke.Parent = FloatBtn

local floatGrad = Instance.new("UIGradient")
floatGrad.Color = ColorSequence.new(Color3.fromRGB(90, 60, 220), Color3.fromRGB(140, 100, 255))
floatGrad.Rotation = 45
floatGrad.Parent = FloatBtn

-- ═══════════ MAIN MENU (small, 200x230) ═══════════
local Menu = Instance.new("Frame")
Menu.Size = UDim2.new(0, 200, 0, 230)
Menu.Position = UDim2.new(0, 15, 0.3, 0)
Menu.BackgroundColor3 = Color3.fromRGB(14, 12, 24)
Menu.BorderSizePixel = 0
Menu.Active = true
Menu.Draggable = true
Menu.Visible = false
Menu.Parent = sg

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 12)
menuCorner.Parent = Menu

local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(90, 60, 220)
menuStroke.Thickness = 1.5
menuStroke.Transparency = 0.2
menuStroke.Parent = Menu

-- header
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = Color3.fromRGB(22, 18, 38)
header.Text = "  SPEED PRO"
header.TextColor3 = Color3.fromRGB(240, 235, 255)
header.Font = Enum.Font.GothamBold
header.TextSize = 13
header.TextXAlignment = Enum.TextXAlignment.Left
header.BorderSizePixel = 0
header.Parent = Menu

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local headerGrad = Instance.new("UIGradient")
headerGrad.Color = ColorSequence.new(Color3.fromRGB(90, 60, 220), Color3.fromRGB(140, 100, 255))
headerGrad.Rotation = 90
headerGrad.Parent = header

-- lock badge
local lockBadge = Instance.new("TextLabel")
lockBadge.Size = UDim2.new(0, 48, 0, 18)
lockBadge.Position = UDim2.new(1, -54, 0, 7)
lockBadge.BackgroundColor3 = Color3.fromRGB(80, 220, 140)
lockBadge.Text = "49 LOCK"
lockBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
lockBadge.Font = Enum.Font.GothamBold
lockBadge.TextSize = 8
lockBadge.BorderSizePixel = 0
lockBadge.Parent = header

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 9)
badgeCorner.Parent = lockBadge

-- speed display
local speedBox = Instance.new("Frame")
speedBox.Size = UDim2.new(0.9, 0, 0, 56)
speedBox.Position = UDim2.new(0.05, 0, 0, 42)
speedBox.BackgroundColor3 = Color3.fromRGB(32, 26, 52)
speedBox.BorderSizePixel = 0
speedBox.Parent = Menu

local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(0, 10)
sbCorner.Parent = speedBox

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 16)
speedLabel.Position = UDim2.new(0, 0, 0, 6)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "SPEED"
speedLabel.TextColor3 = Color3.fromRGB(150, 145, 175)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 9
speedLabel.Parent = speedBox

local speedValue = Instance.new("TextLabel")
speedValue.Size = UDim2.new(1, 0, 0, 30)
speedValue.Position = UDim2.new(0, 0, 0, 22)
speedValue.BackgroundTransparency = 1
speedValue.Text = "49"
speedValue.TextColor3 = Color3.fromRGB(140, 100, 255)
speedValue.Font = Enum.Font.GothamBold
speedValue.TextSize = 26
speedValue.Parent = speedBox

-- locked bar
local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(0.9, 0, 0, 18)
barBg.Position = UDim2.new(0.05, 0, 0, 108)
barBg.BackgroundColor3 = Color3.fromRGB(32, 26, 52)
barBg.BorderSizePixel = 0
barBg.Parent = Menu

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 9)
barCorner.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(140, 100, 255)
barFill.BorderSizePixel = 0
barFill.Parent = barBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 9)
fillCorner.Parent = barFill

local fillGrad = Instance.new("UIGradient")
fillGrad.Color = ColorSequence.new(Color3.fromRGB(90, 60, 220), Color3.fromRGB(140, 100, 255))
fillGrad.Parent = barFill

local barKnob = Instance.new("TextButton")
barKnob.Size = UDim2.new(0, 24, 0, 24)
barKnob.Position = UDim2.new(1, -12, 0.5, -12)
barKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
barKnob.Text = "🔒"
barKnob.TextColor3 = Color3.fromRGB(90, 60, 220)
barKnob.Font = Enum.Font.GothamBold
barKnob.TextSize = 11
barKnob.BorderSizePixel = 0
barKnob.Parent = barBg

local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(0, 12)
knobCorner.Parent = barKnob

-- enable button
local enableBtn = Instance.new("TextButton")
enableBtn.Size = UDim2.new(0.9, 0, 0, 40)
enableBtn.Position = UDim2.new(0.05, 0, 0, 136)
enableBtn.BackgroundColor3 = Color3.fromRGB(80, 220, 140)
enableBtn.Text = "ENABLE"
enableBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
enableBtn.Font = Enum.Font.GothamBold
enableBtn.TextSize = 14
enableBtn.BorderSizePixel = 0
enableBtn.Parent = Menu

local ebCorner = Instance.new("UICorner")
ebCorner.CornerRadius = UDim.new(0, 9)
ebCorner.Parent = enableBtn

local ebGrad = Instance.new("UIGradient")
ebGrad.Color = ColorSequence.new(Color3.fromRGB(80, 220, 140), Color3.fromRGB(60, 170, 110))
ebGrad.Rotation = 90
ebGrad.Parent = enableBtn

enableBtn.MouseButton1Click:Connect(function()
    if enabled then
        stop()
        enableBtn.Text = "ENABLE"
        enableBtn.BackgroundColor3 = Color3.fromRGB(80, 220, 140)
    else
        start()
        enableBtn.Text = "DISABLE"
        enableBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 90)
    end
end)

-- credits footer
local footer = Instance.new("Frame")
footer.Size = UDim2.new(1, 0, 0, 46)
footer.Position = UDim2.new(0, 0, 1, -46)
footer.BackgroundColor3 = Color3.fromRGB(22, 18, 38)
footer.BorderSizePixel = 0
footer.Parent = Menu

local footerCorner = Instance.new("UICorner")
footerCorner.CornerRadius = UDim.new(0, 12)
footerCorner.Parent = footer

local creditTitle = Instance.new("TextLabel")
creditTitle.Size = UDim2.new(1, 0, 0, 14)
creditTitle.Position = UDim2.new(0, 0, 0, 4)
creditTitle.BackgroundTransparency = 1
creditTitle.Text = "© strayshot3"
creditTitle.TextColor3 = Color3.fromRGB(150, 145, 175)
creditTitle.Font = Enum.Font.GothamBold
creditTitle.TextSize = 9
creditTitle.Parent = footer

-- tiktok button
local tkBtn = Instance.new("TextButton")
tkBtn.Size = UDim2.new(0.45, 0, 0, 22)
tkBtn.Position = UDim2.new(0.03, 0, 0, 20)
tkBtn.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
tkBtn.Text = "♪ TikTok"
tkBtn.TextColor3 = Color3.fromRGB(255, 120, 160)
tkBtn.Font = Enum.Font.GothamBold
tkBtn.TextSize = 9
tkBtn.BorderSizePixel = 0
tkBtn.Parent = footer

local tkCorner = Instance.new("UICorner")
tkCorner.CornerRadius = UDim.new(0, 5)
tkCorner.Parent = tkBtn

tkBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        pcall(function() setclipboard(tiktokURL) end)
        tkBtn.Text = "Copied!"
        task.wait(1)
        tkBtn.Text = "♪ TikTok"
    end
end)

-- telegram button
local tgBtn = Instance.new("TextButton")
tgBtn.Size = UDim2.new(0.45, 0, 0, 22)
tgBtn.Position = UDim2.new(0.52, 0, 0, 20)
tgBtn.BackgroundColor3 = Color3.fromRGB(20, 28, 45)
tgBtn.Text = "✈ Telegram"
tgBtn.TextColor3 = Color3.fromRGB(100, 190, 255)
tgBtn.Font = Enum.Font.GothamBold
tgBtn.TextSize = 9
tgBtn.BorderSizePixel = 0
tgBtn.Parent = footer

local tgCorner = Instance.new("UICorner")
tgCorner.CornerRadius = UDim.new(0, 5)
tgCorner.Parent = footer

tgBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        pcall(function() setclipboard(telegramURL) end)
        tgBtn.Text = "Copied!"
        task.wait(1)
        tgBtn.Text = "✈ Telegram"
    end
end)

-- ═══════════ TOGGLE ═══════════
FloatBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    Menu.Visible = menuOpen
end)

-- ═══════════ STATUS UPDATER ═══════════
task.spawn(function()
    while true do
        task.wait(0.5)
        if enabled then
            speedValue.Text = "49 · ON"
            speedValue.TextColor3 = Color3.fromRGB(80, 220, 140)
        else
            speedValue.Text = "49"
            speedValue.TextColor3 = Color3.fromRGB(140, 100, 255)
        end
    end
end)

-- ═══════════ RESPAWN ═══════════
LP.CharacterAdded:Connect(function()
    task.wait(1)
    if enabled then stop(); task.wait(0.1); start() end
end)

print("[SPEED PRO] loaded | TikTok: strayshot3 | Telegram: BB12co")
