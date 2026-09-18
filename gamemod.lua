-- ============================================================
-- OBSIDIAN SAB GOD MODE | Strongest Cheat for Steal a Brainrot
-- TikTok: strayshot3 | Telegram: BB12co
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

print("[GOD MODE] loading strongest version...")

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    -- Steal
    AutoSteal = false, StealDelay = 0.1,
    SilentSteal = true, InstantSteal = true,
    StealAnyDistance = true, BringToBase = false,
    AutoLock = false, LockRange = 15,
    
    -- Farm
    AutoFarm = false, FarmRange = 100,
    AutoBuyEgg = false, EggPrice = 0,
    AutoSell = false,
    
    -- ESP
    PlotESP = true, BrainrotESP = true, PlayerESP = false,
    EggESP = true, BaseESP = true,
    ESPColor = Color3.fromRGB(255, 60, 60),
    MaxDistance = 500,
    
    -- Movement
    Fly = false, FlySpeed = 100,
    SpeedOn = false, SpeedValue = 100,
    Noclip = false, InfJump = false,
    TPToBase = false,
    
    -- Protection
    AntiFling = true, AntiKick = true,
    AntiRagdoll = true, AntiStun = true,
    GodMode = false,
    
    -- Utility
    AutoRejoin = false, ServerHop = false,
}

local LockedTarget = nil
local FlyBV, FlyFG
local GodModeConn = nil

-- ============================================================
-- FILTERS
-- ============================================================
local function isAlive(p)
    local c = p.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function isLocalPlayerPlot(plot)
    if not plot then return false end
    local ownerName = nil
    pcall(function()
        for _, v in ipairs(plot:GetChildren()) do
            if v:IsA("ObjectValue") or v:IsA("StringValue") then
                if v.Name:lower():find("owner") or v.Name:lower():find("player") then
                    ownerName = v.Value
                end
            end
        end
    end)
    return ownerName == LocalPlayer or tostring(ownerName) == LocalPlayer.Name
end

-- ============================================================
-- FIND PLOTS & BRAINROTS
-- ============================================================
local function getAllPlots()
    local plots = {}
    for _, obj in ipairs(Workspace:GetChildren()) do
        local n = obj.Name:lower()
        if n:find("plot") or n:find("base") or n:find("home") then
            table.insert(plots, obj)
        end
    end
    return plots
end

local function findBrainrotInPlot(plot)
    local best, bestValue = nil, 0
    for _, obj in ipairs(plot:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("brainrot") or n:find("pet") or n:find("egg") or n:find("animal") or n:find("character") then
            if obj:IsA("Model") or obj:IsA("Folder") then
                local priceVal = obj:FindFirstChild("Price") or obj:FindFirstChild("Value") or obj:FindFirstChild("Cost")
                local val = 0
                if priceVal then val = tonumber(priceVal.Value) or 0 end
                if val == 0 then
                    val = tonumber(n:match("%d+")) or 1
                end
                if val > bestValue then
                    bestValue = val
                    best = obj
                end
            end
        end
    end
    return best
end

local function findBestBrainrot()
    local best, bestScore = nil, 0
    for _, plot in ipairs(getAllPlots()) do
        if not isLocalPlayerPlot(plot) then
            local b = findBrainrotInPlot(plot)
            if b then
                local priceVal = b:FindFirstChild("Price") or b:FindFirstChild("Value") or b:FindFirstChild("Cost")
                local score = 1
                if priceVal then score = tonumber(priceVal.Value) or 1 end
                if score > bestScore then
                    bestScore = score
                    best = b
                end
            end
        end
    end
    return best
end

-- ============================================================
-- FIND STEAL REMOTE
-- ============================================================
local StealRemotes = {}
local function findStealRemotes()
    StealRemotes = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:find("steal") or n:find("grab") or n:find("take") or n:find("pickup")
               or n:find("collect") or n:find("transfer") or n:find("claim")
               or n:find("withdraw") or n:find("obtain") then
                table.insert(StealRemotes, obj)
            end
        end
    end
    print("[GOD MODE] Found " .. #StealRemotes .. " steal remotes")
    return #StealRemotes
end

-- ============================================================
-- STEAL FUNCTIONS
-- ============================================================
local function teleportToBrainrot(brainrot)
    if not brainrot or not brainrot.Parent then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local pos = nil
    if brainrot:IsA("Model") then
        local primary = brainrot.PrimaryPart or brainrot:FindFirstChildWhichIsA("BasePart")
        if primary then pos = primary.Position end
    elseif brainrot:IsA("BasePart") then
        pos = brainrot.Position
    end
    
    if pos then
        pcall(function()
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
        end)
    end
end

local function fireSteal(brainrot)
    if #StealRemotes == 0 then findStealRemotes() end
    if #StealRemotes == 0 then return end
    
    for _, remote in ipairs(StealRemotes) do
        if remote.Parent then
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(brainrot)
                    remote:FireServer()
                    if brainrot then
                        remote:FireServer(brainrot.Parent)
                    end
                else
                    remote:InvokeServer(brainrot)
                end
            end)
        end
    end
end

local function stealBest()
    local target = findBestBrainrot()
    if not target then return end
    
    if Config.StealAnyDistance then
        teleportToBrainrot(target)
        task.wait(0.05)
    end
    
    fireSteal(target)
end

-- ============================================================
-- AUTO LOCK
-- ============================================================
local function autoLockPlot()
    local plots = getAllPlots()
    for _, plot in ipairs(plots) do
        if isLocalPlayerPlot(plot) then
            -- إيجاد زر القفل
            for _, obj in ipairs(plot:GetDescendants()) do
                local n = obj.Name:lower()
                if n:find("lock") or n:find("cage") or n:find("barrier") then
                    if obj:IsA("ClickDetector") then
                        pcall(function() fireclickdetector(obj) end)
                    elseif obj:IsA("ProximityPrompt") then
                        pcall(function() fireproximityprompt(obj) end)
                    elseif obj:IsA("RemoteEvent") then
                        pcall(function() obj:FireServer() end)
                    end
                end
            end
        end
    end
end

-- ============================================================
-- ESP
-- ============================================================
local Drawing = Drawing or (getgenv and getgenv().Drawing)
local espCache = {}

local function createESP(obj, label)
    if espCache[obj] or not Drawing then return end
    espCache[obj] = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
    }
    local e = espCache[obj]
    e.box.Thickness = 1
    e.box.Filled = false
    e.box.Transparency = 1
    e.name.Size = 12
    e.name.Center = true
    e.name.Outline = true
    e.name.Font = 2
end

local function removeESP(obj)
    local e = espCache[obj]
    if not e then return end
    pcall(function() e.box:Remove() end)
    pcall(function() e.name:Remove() end)
    espCache[obj] = nil
end

local function renderObjectESP(obj, label, color)
    local e = espCache[obj]
    if not e then return end
    
    local pos = nil
    if obj:IsA("Model") then
        local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if pp then pos = pp.Position end
    elseif obj:IsA("BasePart") then
        pos = obj.Position
    end
    
    if not pos then
        e.box.Visible = false
        e.name.Visible = false
        return
    end
    
    local dist = (Camera.CFrame.Position - pos).Magnitude
    if dist > Config.MaxDistance then
        e.box.Visible = false
        e.name.Visible = false
        return
    end
    
    local sp, on = Camera:WorldToViewportPoint(pos)
    if not on or sp.Z <= 0 then
        e.box.Visible = false
        e.name.Visible = false
        return
    end
    
    local size = math.clamp(1000 / dist, 20, 100)
    e.box.Size = Vector2.new(size, size)
    e.box.Position = Vector2.new(sp.X - size/2, sp.Y - size/2)
    e.box.Color = color
    e.box.Visible = true
    
    e.name.Text = label .. " [" .. math.floor(dist) .. "m]"
    e.name.Position = Vector2.new(sp.X, sp.Y - size/2 - 15)
    e.name.Color = color
    e.name.Visible = true
end

-- ============================================================
-- ANTI-EXPLOIT PROTECTION
-- ============================================================
if getrawmetatable and setreadonly and newcclosure and getnamecallmethod then
    local mt = getrawmetatable(game)
    local oldNC = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" and Config.AntiKick then
            print("[GOD MODE] Kick blocked")
            return nil
        end
        if method == "FireServer" and Config.AntiFling then
            if typeof(self) == "Instance" then
                local n = self.Name:lower()
                if n:find("fling") or n:find("velocity") or n:find("ragdoll") or n:find("push") then
                    -- block outgoing
                end
            end
        end
        return oldNC(self, ...)
    end)
    setreadonly(mt, true)
    print("[GOD MODE] Hook installed")
end

-- ============================================================
-- GOD MODE
-- ============================================================
local function enableGodMode()
    if GodModeConn then return end
    GodModeConn = RunService.Heartbeat:Connect(function()
        if not Config.GodMode then return end
        local char = LocalPlayer.Character
        if not char then return end
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then
            h.Health = h.MaxHealth
        end
    end)
end

local function disableGodMode()
    if GodModeConn then
        GodModeConn:Disconnect()
        GodModeConn = nil
    end
end

-- ============================================================
-- NOCLIP
-- ============================================================
RunService.Stepped:Connect(function()
    if not Config.Noclip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end)

-- ============================================================
-- SPEED HACK
-- ============================================================
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if not h then return end
    
    if Config.SpeedOn then
        h.WalkSpeed = Config.SpeedValue
    elseif Config.Fly then
        h.WalkSpeed = 16
    end
    
    if Config.InfJump then
        pcall(function()
            if h:GetState() == Enum.HumanoidStateType.Freefall then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

-- ============================================================
-- FLY
-- ============================================================
RunService.RenderStepped:Connect(function()
    if not Config.Fly then
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyFG then FlyFG:Destroy() FlyFG = nil end
        return
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local h = char:FindFirstChildOfClass("Humanoid")
    if not (hrp and h) then return end
    
    if not FlyBV or not FlyBV.Parent then
        FlyBV = Instance.new("BodyVelocity")
        FlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        FlyBV.Parent = hrp
        FlyFG = Instance.new("BodyGyro")
        FlyFG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        FlyFG.P = 3000
        FlyFG.D = 500
        FlyFG.Parent = hrp
    end
    
    local md = h.MoveDirection
    local cl = Camera.CFrame.LookVector
    local flat = Vector3.new(cl.X, 0, cl.Z)
    if flat.Magnitude > 0.01 then flat = flat.Unit end
    local rt = flat:Cross(Vector3.new(0, 1, 0))
    
    local vertical = 0
    if UIS:IsKeyDown(Enum.KeyCode.Space) then vertical = 1 end
    
    FlyBV.Velocity = (flat * md.Z + rt * md.X) * Config.FlySpeed + Vector3.new(0, vertical * Config.FlySpeed, 0)
    FlyFG.CFrame = Camera.CFrame
end)

-- ============================================================
-- MAIN STEAL LOOP
-- ============================================================
task.spawn(function()
    while task.wait(Config.StealDelay) do
        if Config.AutoSteal then
            pcall(stealBest)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Config.AutoLock then
            pcall(autoLockPlot)
        end
    end
end)

-- ============================================================
-- GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OBS_GODMODE"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local vp = Camera.ViewportSize
local FW = math.clamp(vp.X * 0.95, 320, 420)
local FH = math.clamp(vp.Y * 0.8, 480, 620)

-- Icon
local Icon = Instance.new("ImageButton")
Icon.Size = UDim2.new(0, 54, 0, 54)
Icon.Position = UDim2.new(0, 15, 0, 100)
Icon.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
Icon.BackgroundTransparency = 0.1
Icon.BorderSizePixel = 0
Icon.AutoButtonColor = false
Icon.Active = true
Icon.Parent = ScreenGui
local IC = Instance.new("UICorner") IC.CornerRadius = UDim.new(1, 0) IC.Parent = Icon
local IStr = Instance.new("UIStroke") IStr.Color = Color3.fromRGB(255, 40, 40) IStr.Thickness = 2.5 IStr.Parent = Icon
local ILbl = Instance.new("TextLabel")
ILbl.Size = UDim2.new(1, 0, 1, 0) ILbl.BackgroundTransparency = 1
ILbl.Text = "👑" ILbl.TextColor3 = Color3.fromRGB(255, 215, 0)
ILbl.Font = Enum.Font.GothamBlack ILbl.TextSize = 28 ILbl.Parent = Icon

local iconDrag = false
local iconStart, iconPos
Icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        iconDrag = false iconStart = input.Position iconPos = Icon.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if iconStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - iconStart
        if d.Magnitude > 8 then
            iconDrag = true
            Icon.Position = UDim2.new(0, iconPos.X.Offset + d.X, 0, iconPos.Y.Offset + d.Y)
        end
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then iconStart = nil end
end)

-- Main
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 0, 0, FH)
Main.Position = UDim2.new(0.5, -FW/2, 0.5, -FH/2)
Main.BackgroundColor3 = Color3.fromRGB(12, 10, 16)
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = ScreenGui
local MC = Instance.new("UICorner") MC.CornerRadius = UDim.new(0, 14) MC.Parent = Main
local MStr = Instance.new("UIStroke") MStr.Color = Color3.fromRGB(255, 40, 40) MStr.Thickness = 1.5 MStr.Transparency = 0.3 MStr.Parent = Main

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundColor3 = Color3.fromRGB(30, 15, 18)
Header.BorderSizePixel = 0
Header.Parent = Main
local HC = Instance.new("UICorner") HC.CornerRadius = UDim.new(0, 14) HC.Parent = Header

local HText = Instance.new("TextLabel")
HText.Size = UDim2.new(1, -80, 1, 0)
HText.Position = UDim2.new(0, 14, 0, 0)
HText.BackgroundTransparency = 1
HText.Text = "👑  OBSIDIAN  GOD MODE"
HText.TextColor3 = Color3.fromRGB(255, 220, 100)
HText.TextXAlignment = Enum.TextXAlignment.Left
HText.Font = Enum.Font.GothamBold
HText.TextSize = 13
HText.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header
local CBC = Instance.new("UICorner") CBC.CornerRadius = UDim.new(0, 7) CBC.Parent = CloseBtn

-- TabBar
local TabBar = Instance.new("ScrollingFrame")
TabBar.Size = UDim2.new(1, -8, 0, 38)
TabBar.Position = UDim2.new(0, 4, 0, 48)
TabBar.BackgroundColor3 = Color3.fromRGB(22, 16, 20)
TabBar.BackgroundTransparency = 0.2
TabBar.BorderSizePixel = 0
TabBar.ScrollBarThickness = 2
TabBar.ScrollBarImageColor3 = Color3.fromRGB(255, 60, 60)
TabBar.ScrollingDirection = Enum.ScrollingDirection.X
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
TabBar.Parent = Main
local TBC = Instance.new("UICorner") TBC.CornerRadius = UDim.new(0, 8) TBC.Parent = TabBar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 4)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Parent = TabBar
local TabPad = Instance.new("UIPadding")
TabPad.PaddingTop = UDim.new(0, 4)
TabPad.PaddingBottom = UDim.new(0, 4)
TabPad.PaddingLeft = UDim.new(0, 6)
TabPad.PaddingRight = UDim.new(0, 6)
TabPad.Parent = TabBar

-- Content
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -8, 1, -128)
ContentArea.Position = UDim2.new(0, 4, 0, 92)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = Main

local Pages = {}
local function makePage(name)
    local p = Instance.new("ScrollingFrame")
    p.Name = name
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 3
    p.ScrollBarImageColor3 = Color3.fromRGB(255, 60, 60)
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Visible = false
    p.Parent = ContentArea
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 5)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = p
    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = p
    Pages[name] = p
    return p
end

local TabButtons = {}
local function showPage(name)
    for n, p in pairs(Pages) do p.Visible = (n == name) end
    for n, b in pairs(TabButtons) do
        if n == name then
            b.BackgroundColor3 = Color3.fromRGB(140, 30, 30)
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            b.BackgroundColor3 = Color3.fromRGB(38, 25, 28)
            b.TextColor3 = Color3.fromRGB(220, 160, 160)
        end
    end
end

local function makeTab(label, pageName)
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(0, 76, 0, 28)
    B.BackgroundColor3 = Color3.fromRGB(38, 25, 28)
    B.Text = label
    B.TextColor3 = Color3.fromRGB(220, 160, 160)
    B.Font = Enum.Font.GothamBold
    B.TextSize = 10
    B.BorderSizePixel = 0
    B.AutoButtonColor = false
    B.Parent = TabBar
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = B
    B.MouseButton1Click:Connect(function() showPage(pageName) end)
    TabButtons[pageName] = B
    return B
end

local function makeHeader(parent, text)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, 0, 0, 22)
    L.BackgroundColor3 = Color3.fromRGB(48, 20, 24)
    L.BackgroundTransparency = 0.2
    L.BorderSizePixel = 0
    L.Text = "  " .. text
    L.TextColor3 = Color3.fromRGB(255, 120, 120)
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Font = Enum.Font.GothamBold
    L.TextSize = 10
    L.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = L
end

local function makeToggle(parent, text, key, cb)
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(1, 0, 0, 32)
    B.BackgroundColor3 = Color3.fromRGB(30, 22, 26)
    B.BackgroundTransparency = 0.15
    B.TextColor3 = Color3.fromRGB(220, 200, 200)
    B.Text = "  " .. text .. "  |  " .. (Config[key] and "مفعل" or "معطل")
    B.TextXAlignment = Enum.TextXAlignment.Left
    B.Font = Enum.Font.Gotham
    B.TextSize = 11
    B.BorderSizePixel = 0
    B.AutoButtonColor = false
    B.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = B
    if Config[key] then
        B.BackgroundColor3 = Color3.fromRGB(45, 75, 50)
        B.TextColor3 = Color3.fromRGB(150, 255, 180)
    end
    B.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        B.Text = "  " .. text .. "  |  " .. (Config[key] and "مفعل" or "معطل")
        B.BackgroundColor3 = Config[key] and Color3.fromRGB(45, 75, 50) or Color3.fromRGB(30, 22, 26)
        B.TextColor3 = Config[key] and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(220, 200, 200)
        if cb then pcall(cb, Config[key]) end
    end)
    return B
end

local function makeSlider(parent, text, key, mn, mx, df, cb)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, 0, 0, 44)
    F.BackgroundColor3 = Color3.fromRGB(30, 22, 26)
    F.BackgroundTransparency = 0.15
    F.BorderSizePixel = 0
    F.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = F

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -14, 0, 16)
    L.Position = UDim2.new(0, 8, 0, 3)
    L.BackgroundTransparency = 1
    L.Text = text .. ": " .. df
    L.TextColor3 = Color3.fromRGB(220, 200, 200)
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Font = Enum.Font.Gotham
    L.TextSize = 11
    L.Parent = F

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -20, 0, 10)
    Bar.Position = UDim2.new(0, 10, 0, 26)
    Bar.BackgroundColor3 = Color3.fromRGB(55, 40, 45)
    Bar.BorderSizePixel = 0
    Bar.Active = true
    Bar.Parent = F
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(1, 0) bc.Parent = Bar

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((df - mn) / (mx - mn), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar
    local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(1, 0) fc.Parent = Fill

    local dragging = false
    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            Fill.Size = UDim2.new(rel, 0, 1, 0)
            local v = mn + (mx - mn) * rel
            if mx - mn < 5 then v = math.floor(v * 100) / 100 else v = math.floor(v) end
            L.Text = text .. ": " .. v
            Config[key] = v
            if cb then pcall(cb, v) end
        end
    end)
end

local function makeButton(parent, text, cb, col)
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(1, 0, 0, 34)
    B.BackgroundColor3 = col or Color3.fromRGB(70, 40, 45)
    B.BackgroundTransparency = 0.1
    B.TextColor3 = Color3.fromRGB(255, 255, 255)
    B.Text = text
    B.Font = Enum.Font.GothamBold
    B.TextSize = 11
    B.TextWrapped = true
    B.BorderSizePixel = 0
    B.AutoButtonColor = false
    B.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = B
    B.MouseButton1Click:Connect(function()
        local ok, err = pcall(cb)
        if not ok then print("[ERR] " .. tostring(err)) end
    end)
    return B
end

-- Pages
makePage("steal")
makePage("esp")
makePage("move")
makePage("protect")
makePage("about")

-- STEAL PAGE
local pSteal = Pages["steal"]
makeHeader(pSteal, "🔥 السرقة القوية")
makeToggle(pSteal, "السرقة التلقائية", "AutoSteal")
makeToggle(pSteal, "سرقة صامتة", "SilentSteal")
makeToggle(pSteal, "سرقة فورية (بدون cooldown)", "InstantSteal")
makeToggle(pSteal, "سرقة من أي مسافة", "StealAnyDistance")
makeSlider(pSteal, "تأخير السرقة", "StealDelay", 0.05, 1, 0.1)

makeHeader(pSteal, "🔒 حماية القاعدة")
makeToggle(pSteal, "قفل تلقائي للقاعدة", "AutoLock")
makeSlider(pSteal, "نطاق القفل", "LockRange", 5, 50, 15)

makeHeader(pSteal, "💰 أوامر سريعة")
makeButton(pSteal, "🚀 اسرق أفضل Brainrot الآن", function()
    pcall(stealBest)
end, Color3.fromRGB(140, 40, 40))

makeButton(pSteal, "🔍 فحص Steal Remotes", function()
    findStealRemotes()
end, Color3.fromRGB(80, 60, 100))

makeButton(pSteal, "🎯 اسرق من موقع محدد", function()
    local target = findBestBrainrot()
    if target then
        teleportToBrainrot(target)
        task.wait(0.3)
        fireSteal(target)
    end
end, Color3.fromRGB(100, 50, 50))

-- ESP PAGE
local pESP = Pages["esp"]
makeHeader(pESP, "🎯 كشف")
makeToggle(pESP, "كشف Brainrots", "BrainrotESP")
makeToggle(pESP, "كشف القواعد", "PlotESP")
makeToggle(pESP, "كشف اللاعبين", "PlayerESP")
makeToggle(pESP, "كشف البيض", "EggESP")
makeSlider(pESP, "أقصى مسافة", "MaxDistance", 50, 2000, 500)

-- MOVE PAGE
local pMove = Pages["move"]
makeHeader(pMove, "✈ الطيران")
makeToggle(pMove, "تفعيل الطيران", "Fly")
makeSlider(pMove, "سرعة الطيران", "FlySpeed", 30, 300, 100)
makeHeader(pMove, "🏃 السرعة")
makeToggle(pMove, "تفعيل السرعة", "SpeedOn")
makeSlider(pMove, "قيمة السرعة", "SpeedValue", 16, 300, 100)
makeHeader(pMove, "🧱 أدوات")
makeToggle(pMove, "اختراق الجدران", "Noclip")
makeToggle(pMove, "قفز لا محدود", "InfJump")

-- PROTECT PAGE
local pProtect = Pages["protect"]
makeHeader(pProtect, "🛡 الحماية")
makeToggle(pProtect, "منع الطرد (Kick)", "AntiKick")
makeToggle(pProtect, "منع الرمي (Fling)", "AntiFling")
makeToggle(pProtect, "منع الرجم (Ragdoll)", "AntiRagdoll")
makeToggle(pProtect, "منع التجمد (Stun)", "AntiStun")
makeToggle(pProtect, "وضع الله (صحة كاملة)", "GodMode", function(v)
    if v then enableGodMode() else disableGodMode() end
end)

-- ABOUT
local pAbout = Pages["about"]
makeHeader(pAbout, "الحقوق")
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 120)
info.BackgroundColor3 = Color3.fromRGB(25, 18, 22)
info.BackgroundTransparency = 0.2
info.BorderSizePixel = 0
info.Text = "  تيك توك : strayshot3\n  قناة تلجرام : BB12co\n\n  الإصدار : 3.0 GOD MODE\n  أقوى سكربت في ماب البيض"
info.TextColor3 = Color3.fromRGB(220, 180, 180)
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.TextWrapped = true
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.Parent = pAbout
local iC = Instance.new("UICorner") iC.CornerRadius = UDim.new(0, 8) iC.Parent = info

-- Tabs
makeTab("السرقة", "steal")
makeTab("الكشف", "esp")
makeTab("الحركة", "move")
makeTab("الحماية", "protect")
makeTab("الحقوق", "about")

showPage("steal")

-- Menu Control
local MenuOpen = false
local function openMenu()
    if MenuOpen then return end
    MenuOpen = true
    Main.Visible = true
    TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, FW, 0, FH)
    }):Play()
end
local function closeMenu()
    if not MenuOpen then return end
    MenuOpen = false
    local t = TweenService:Create(Main, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, FH)
    })
    t.Completed:Connect(function() Main.Visible = false end)
    t:Play()
end

Icon.MouseButton1Click:Connect(function()
    if iconDrag then return end
    if MenuOpen then closeMenu() else openMenu() end
end)
CloseBtn.MouseButton1Click:Connect(closeMenu)

-- ESP Loop
task.spawn(function()
    while task.wait(0.1) do
        if Config.BrainrotESP or Config.PlotESP or Config.EggESP or Config.PlayerESP then
            for _, plot in ipairs(getAllPlots()) do
                if Config.PlotESP and not isLocalPlayerPlot(plot) then
                    if not espCache[plot] then createESP(plot, "Plot") end
                    renderObjectESP(plot, "قاعدة", Color3.fromRGB(255, 60, 60))
                end
                for _, obj in ipairs(plot:GetDescendants()) do
                    local n = obj.Name:lower()
                    if Config.BrainrotESP and (n:find("brainrot") or n:find("pet")) and (obj:IsA("Model") or obj:IsA("BasePart")) then
                        if not espCache[obj] then createESP(obj, "Brainrot") end
                        renderObjectESP(obj, "🥚 Brainrot", Color3.fromRGB(255, 200, 50))
                    end
                    if Config.EggESP and n:find("egg") and (obj:IsA("Model") or obj:IsA("BasePart")) then
                        if not espCache[obj] then createESP(obj, "Egg") end
                        renderObjectESP(obj, "🥚 Egg", Color3.fromRGB(150, 255, 150))
                    end
                end
            end
        end
    end
end)

-- Auto find steal remotes on load
task.spawn(function()
    task.wait(2)
    findStealRemotes()
end)

LocalPlayer.CharacterAdded:Connect(function()
    LockedTarget = nil
    FlyBV = nil
    FlyFG = nil
end)

print("[GOD MODE] Loaded!")
print("TikTok: strayshot3 | Telegram: BB12co")
