-- ============================================================
-- OBSIDIAN WAR v1 | ARABIC EDITION
-- TikTok: strayshot3 | Telegram: BB12co
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

print("[WAR] loading...")

local Config = {
    ESP = false, Skeleton = true, Box = true, Name = true,
    Distance = true, Tracer = true, HeadDot = true, HealthBar = true,
    ESPColor = Color3.fromRGB(255, 60, 60),
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    MaxDistance = 1000, TeamCheck = true, FriendCheck = true, Visible = false,
    Aimbot = false, AimSmooth = 8, AimFOV = 150, AimPart = "Head",
    AimMaxDist = 800, AimVisibleCheck = true,
    Fly = false, FlySpeed = 55,
    SpeedOn = false, SpeedValue = 40,
    JumpOn = false, JumpValue = 90, InfJump = false,
}

local LockedTarget = nil
local FlyBV, FlyFG

-- Filters
local function isAlive(p)
    local c = p.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end
local function isTeammate(p)
    if not Config.TeamCheck then return false end
    if not LocalPlayer.Team then return false end
    return p.Team == LocalPlayer.Team
end
local function isFriend(p)
    if not Config.FriendCheck then return false end
    local ok, r = pcall(function() return LocalPlayer:IsFriendsWith(p.UserId) end)
    return ok and r
end
local function isEnemy(p)
    if p == LocalPlayer then return false end
    if not isAlive(p) then return false end
    if isTeammate(p) then return false end
    if isFriend(p) then return false end
    return true
end
local function isVisible(part)
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, part.Parent }
    local result = Workspace:Raycast(origin, dir, params)
    return result == nil or (result.Position - origin).Magnitude >= dir.Magnitude - 1
end

local Drawing = Drawing or (getgenv and getgenv().Drawing)
local espCache = {}

local function createESP(p)
    if espCache[p] or not Drawing then return end
    espCache[p] = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        dist = Drawing.new("Text"),
        tracer = Drawing.new("Line"),
        headDot = Drawing.new("Circle"),
        healthBg = Drawing.new("Line"),
        healthFill = Drawing.new("Line"),
        skeleton = {
            head = Drawing.new("Line"),
            upperTorso = Drawing.new("Line"),
            lowerTorso = Drawing.new("Line"),
            leftArm = Drawing.new("Line"),
            rightArm = Drawing.new("Line"),
            leftLeg = Drawing.new("Line"),
            rightLeg = Drawing.new("Line"),
        }
    }
    local e = espCache[p]
    e.box.Thickness = 1
    e.box.Filled = false
    e.box.Transparency = 1
    e.name.Size = 13
    e.name.Center = true
    e.name.Outline = true
    e.name.Font = 2
    e.dist.Size = 11
    e.dist.Center = true
    e.dist.Outline = true
    e.dist.Font = 2
    e.tracer.Thickness = 1
    e.tracer.Transparency = 1
    e.headDot.Radius = 3
    e.headDot.Filled = true
    e.headDot.Thickness = 1
    e.healthBg.Thickness = 3
    e.healthFill.Thickness = 3
    for _, line in pairs(e.skeleton) do
        line.Thickness = 1
        line.Transparency = 1
    end
end

local function removeESP(p)
    local e = espCache[p]
    if not e then return end
    for _, obj in pairs(e) do
        if type(obj) == "table" then
            for _, line in pairs(obj) do pcall(function() line:Remove() end) end
        else
            pcall(function() obj:Remove() end)
        end
    end
    espCache[p] = nil
end

local function hideESP(e)
    for _, obj in pairs(e) do
        if type(obj) == "table" then
            for _, line in pairs(obj) do line.Visible = false end
        else
            obj.Visible = false
        end
    end
end

local function renderESP(p)
    local e = espCache[p]
    if not e then return end
    local char = p.Character
    if not char then hideESP(e) return end
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not (head and hrp and humanoid) then hideESP(e) return end
    local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
    if distance > Config.MaxDistance then hideESP(e) return end
    if Config.Visible and not isVisible(head) then hideESP(e) return end

    local headPos, onHead = Camera:WorldToViewportPoint(head.Position)
    local hrpPos, onHrp = Camera:WorldToViewportPoint(hrp.Position)
    if not (onHead and onHrp and headPos.Z > 0 and hrpPos.Z > 0) then hideESP(e) return end

    local topPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local bottomPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
    local h = math.abs(topPos.Y - bottomPos.Y)
    local w = h * 0.55
    local topLeft = Vector2.new(topPos.X - w/2, topPos.Y)
    local bottomRight = Vector2.new(topPos.X + w/2, topPos.Y + h)

    if Config.Box then
        e.box.Size = Vector2.new(w, h)
        e.box.Position = topLeft
        e.box.Color = Config.ESPColor
        e.box.Visible = true
    else e.box.Visible = false end

    if Config.Name then
        e.name.Text = p.Name
        e.name.Position = Vector2.new(topPos.X, topPos.Y - 18)
        e.name.Color = Color3.fromRGB(255, 255, 255)
        e.name.Visible = true
    else e.name.Visible = false end

    if Config.Distance then
        e.dist.Text = string.format("[%d m]", math.floor(distance))
        e.dist.Position = Vector2.new(topPos.X, topPos.Y + h + 4)
        e.dist.Color = Color3.fromRGB(200, 255, 200)
        e.dist.Visible = true
    else e.dist.Visible = false end

    if Config.Tracer then
        e.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        e.tracer.To = Vector2.new(bottomPos.X, bottomPos.Y)
        e.tracer.Color = Config.ESPColor
        e.tracer.Visible = true
    else e.tracer.Visible = false end

    if Config.HeadDot then
        e.headDot.Position = Vector2.new(headPos.X, headPos.Y)
        e.headDot.Color = Color3.fromRGB(255, 100, 100)
        e.headDot.Visible = true
    else e.headDot.Visible = false end

    if Config.HealthBar then
        local healthPct = humanoid.Health / humanoid.MaxHealth
        local barX = bottomRight.X + 4
        e.healthBg.From = Vector2.new(barX, topPos.Y)
        e.healthBg.To = Vector2.new(barX, topPos.Y + h)
        e.healthBg.Color = Color3.fromRGB(40, 40, 40)
        e.healthBg.Visible = true
        local filledY = topPos.Y + h * (1 - healthPct)
        e.healthFill.From = Vector2.new(barX, filledY)
        e.healthFill.To = Vector2.new(barX, topPos.Y + h)
        e.healthFill.Color = Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 0, 0), 1 - healthPct)
        e.healthFill.Visible = true
    else
        e.healthBg.Visible = false
        e.healthFill.Visible = false
    end

    if Config.Skeleton then
        local function getPart(name) return char:FindFirstChild(name) end
        local function drawLine(part1, part2, lineObj)
            if part1 and part2 then
                local p1 = Camera:WorldToViewportPoint(part1.Position)
                local p2 = Camera:WorldToViewportPoint(part2.Position)
                if p1.Z > 0 and p2.Z > 0 then
                    lineObj.From = Vector2.new(p1.X, p1.Y)
                    lineObj.To = Vector2.new(p2.X, p2.Y)
                    lineObj.Color = Config.SkeletonColor
                    lineObj.Visible = true
                    return
                end
            end
            lineObj.Visible = false
        end
        local head2 = getPart("Head")
        local upperTorso = getPart("UpperTorso") or getPart("Torso")
        local lowerTorso = getPart("LowerTorso")
        local leftHand = getPart("LeftHand") or getPart("Left Arm")
        local rightHand = getPart("RightHand") or getPart("Right Arm")
        local leftFoot = getPart("LeftFoot") or getPart("Left Leg")
        local rightFoot = getPart("RightFoot") or getPart("Right Leg")
        drawLine(head2, upperTorso, e.skeleton.head)
        drawLine(upperTorso, lowerTorso, e.skeleton.upperTorso)
        drawLine(upperTorso, leftHand, e.skeleton.leftArm)
        drawLine(upperTorso, rightHand, e.skeleton.rightArm)
        drawLine(lowerTorso, leftFoot, e.skeleton.leftLeg)
        drawLine(lowerTorso, rightFoot, e.skeleton.rightLeg)
    else
        for _, line in pairs(e.skeleton) do line.Visible = false end
    end
end

local function findTarget()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best, bestDist, bestPart = nil, Config.AimFOV, nil
    if LockedTarget and isEnemy(LockedTarget) then
        local part = LockedTarget.Character and LockedTarget.Character:FindFirstChild(Config.AimPart)
        if part then
            local sp, on = Camera:WorldToViewportPoint(part.Position)
            if on and sp.Z > 0 then
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d < Config.AimFOV and isVisible(part) then return part end
            end
        end
        LockedTarget = nil
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) then
            local part = p.Character and p.Character:FindFirstChild(Config.AimPart)
            if part then
                local worldDist = (Camera.CFrame.Position - part.Position).Magnitude
                if worldDist <= Config.AimMaxDist then
                    local sp, on = Camera:WorldToViewportPoint(part.Position)
                    if on and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < bestDist and isVisible(part) then
                            bestDist = d
                            best = p
                            bestPart = part
                        end
                    end
                end
            end
        end
    end
    if best then
        LockedTarget = best
        return bestPart
    end
    return nil
end

-- ============================================================
-- GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OBS_WAR"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local vp = Camera.ViewportSize
local FW = math.clamp(vp.X * 0.92, 300, 400)
local FH = math.clamp(vp.Y * 0.78, 450, 600)

local Icon = Instance.new("ImageButton")
Icon.Size = UDim2.new(0, 50, 0, 50)
Icon.Position = UDim2.new(0, 15, 0, 100)
Icon.BackgroundColor3 = Color3.fromRGB(20, 15, 15)
Icon.BackgroundTransparency = 0.1
Icon.BorderSizePixel = 0
Icon.AutoButtonColor = false
Icon.Active = true
Icon.Parent = ScreenGui
local IC = Instance.new("UICorner") IC.CornerRadius = UDim.new(1, 0) IC.Parent = Icon
local IStr = Instance.new("UIStroke") IStr.Color = Color3.fromRGB(255, 60, 60) IStr.Thickness = 2 IStr.Parent = Icon
local ILbl = Instance.new("TextLabel")
ILbl.Size = UDim2.new(1, 0, 1, 0) ILbl.BackgroundTransparency = 1
ILbl.Text = "⚔" ILbl.TextColor3 = Color3.fromRGB(255, 255, 255)
ILbl.Font = Enum.Font.GothamBlack ILbl.TextSize = 24 ILbl.Parent = Icon

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

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 0, 0, FH)
Main.Position = UDim2.new(0.5, -FW/2, 0.5, -FH/2)
Main.BackgroundColor3 = Color3.fromRGB(14, 12, 18)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = ScreenGui
local MC = Instance.new("UICorner") MC.CornerRadius = UDim.new(0, 14) MC.Parent = Main
local MStr = Instance.new("UIStroke") MStr.Color = Color3.fromRGB(255, 60, 60) MStr.Thickness = 1.5 MStr.Transparency = 0.35 MStr.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = Color3.fromRGB(25, 18, 22)
Header.BackgroundTransparency = 0.05
Header.BorderSizePixel = 0
Header.Parent = Main
local HC = Instance.new("UICorner") HC.CornerRadius = UDim.new(0, 14) HC.Parent = Header

local HText = Instance.new("TextLabel")
HText.Size = UDim2.new(1, -80, 1, 0)
HText.Position = UDim2.new(0, 14, 0, 0)
HText.BackgroundTransparency = 1
HText.Text = "⚔  OBSIDIAN  WAR"
HText.TextColor3 = Color3.fromRGB(255, 180, 180)
HText.TextXAlignment = Enum.TextXAlignment.Left
HText.Font = Enum.Font.GothamBold
HText.TextSize = 13
HText.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header
local CBC = Instance.new("UICorner") CBC.CornerRadius = UDim.new(0, 7) CBC.Parent = CloseBtn

local TabBar = Instance.new("ScrollingFrame")
TabBar.Size = UDim2.new(1, -8, 0, 36)
TabBar.Position = UDim2.new(0, 4, 0, 46)
TabBar.BackgroundColor3 = Color3.fromRGB(20, 16, 22)
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

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -8, 1, -122)
ContentArea.Position = UDim2.new(0, 4, 0, 86)
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
            b.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            b.BackgroundColor3 = Color3.fromRGB(35, 25, 30)
            b.TextColor3 = Color3.fromRGB(200, 150, 150)
        end
    end
end

local function makeTab(label, pageName)
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(0, 74, 0, 26)
    B.BackgroundColor3 = Color3.fromRGB(35, 25, 30)
    B.Text = label
    B.TextColor3 = Color3.fromRGB(200, 150, 150)
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
    L.BackgroundColor3 = Color3.fromRGB(40, 22, 26)
    L.BackgroundTransparency = 0.2
    L.BorderSizePixel = 0
    L.Text = "  " .. text
    L.TextColor3 = Color3.fromRGB(255, 100, 100)
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

-- PAGES
makePage("esp")
makePage("aim")
makePage("move")
makePage("about")

-- ESP PAGE
local pESP = Pages["esp"]
makeHeader(pESP, "تفعيلات الكشف")
makeToggle(pESP, "تفعيل ESP", "ESP")
makeToggle(pESP, "الهيكل العظمي", "Skeleton")
makeToggle(pESP, "المربع", "Box")
makeToggle(pESP, "الاسم", "Name")
makeToggle(pESP, "المسافة", "Distance")
makeToggle(pESP, "خط التتبع", "Tracer")
makeToggle(pESP, "نقطة الرأس", "HeadDot")
makeToggle(pESP, "شريط الصحة", "HealthBar")

makeHeader(pESP, "الفلاتر")
makeToggle(pESP, "تجاهل الفريق", "TeamCheck")
makeToggle(pESP, "تجاهل الأصدقاء", "FriendCheck")
makeToggle(pESP, "المرئي فقط", "Visible")

makeHeader(pESP, "المدى")
makeSlider(pESP, "أقصى مسافة", "MaxDistance", 100, 3000, Config.MaxDistance)

-- AIM PAGE
local pAim = Pages["aim"]
makeHeader(pAim, "التصويب")
makeToggle(pAim, "تفعيل التصويب", "Aimbot")
makeToggle(pAim, "فحص الرؤية", "AimVisibleCheck")

makeHeader(pAim, "الإعدادات")
makeSlider(pAim, "نطاق التصويب", "AimFOV", 30, 400, Config.AimFOV)
makeSlider(pAim, "نعومة التصويب", "AimSmooth", 2, 30, Config.AimSmooth)
makeSlider(pAim, "أقصى مسافة", "AimMaxDist", 100, 2000, Config.AimMaxDist)

-- MOVE PAGE
local pMove = Pages["move"]
makeHeader(pMove, "الطيران")
makeToggle(pMove, "تفعيل الطيران", "Fly")
makeSlider(pMove, "سرعة الطيران", "FlySpeed", 20, 150, Config.FlySpeed)

makeHeader(pMove, "السرعة")
makeToggle(pMove, "تفعيل السرعة", "SpeedOn")
makeSlider(pMove, "قيمة السرعة", "SpeedValue", 16, 100, Config.SpeedValue)

makeHeader(pMove, "القفز")
makeToggle(pMove, "قفز عالي", "JumpOn")
makeSlider(pMove, "قوة القفز", "JumpValue", 50, 200, Config.JumpValue)
makeToggle(pMove, "قفز لا محدود", "InfJump")

-- ABOUT
local pAbout = Pages["about"]
makeHeader(pAbout, "الحقوق")

local creditFrame = Instance.new("Frame")
creditFrame.Size = UDim2.new(1, 0, 0, 130)
creditFrame.BackgroundColor3 = Color3.fromRGB(25, 18, 22)
creditFrame.BorderSizePixel = 0
creditFrame.Parent = pAbout
local CFC = Instance.new("UICorner") CFC.CornerRadius = UDim.new(0, 8) CFC.Parent = creditFrame

local credit1 = Instance.new("TextLabel")
credit1.Size = UDim2.new(1, -16, 0, 24)
credit1.Position = UDim2.new(0, 8, 0, 12)
credit1.BackgroundTransparency = 1
credit1.Text = "  تيك توك : strayshot3"
credit1.TextColor3 = Color3.fromRGB(255, 100, 100)
credit1.TextXAlignment = Enum.TextXAlignment.Left
credit1.Font = Enum.Font.GothamBold
credit1.TextSize = 13
credit1.Parent = creditFrame

local credit2 = Instance.new("TextLabel")
credit2.Size = UDim2.new(1, -16, 0, 24)
credit2.Position = UDim2.new(0, 8, 0, 44)
credit2.BackgroundTransparency = 1
credit2.Text = "  قناة تلجرام : BB12co"
credit2.TextColor3 = Color3.fromRGB(100, 180, 255)
credit2.TextXAlignment = Enum.TextXAlignment.Left
credit2.Font = Enum.Font.GothamBold
credit2.TextSize = 13
credit2.Parent = creditFrame

local credit3 = Instance.new("TextLabel")
credit3.Size = UDim2.new(1, -16, 0, 20)
credit3.Position = UDim2.new(0, 8, 0, 76)
credit3.BackgroundTransparency = 1
credit3.Text = "  التحديثات على تلجرام"
credit3.TextColor3 = Color3.fromRGB(180, 180, 180)
credit3.TextXAlignment = Enum.TextXAlignment.Left
credit3.Font = Enum.Font.Gotham
credit3.TextSize = 11
credit3.Parent = creditFrame

local credit4 = Instance.new("TextLabel")
credit4.Size = UDim2.new(1, -16, 0, 20)
credit4.Position = UDim2.new(0, 8, 0, 100)
credit4.BackgroundTransparency = 1
credit4.Text = "  الإصدار 1.0"
credit4.TextColor3 = Color3.fromRGB(140, 140, 140)
credit4.TextXAlignment = Enum.TextXAlignment.Left
credit4.Font = Enum.Font.Gotham
credit4.TextSize = 10
credit4.Parent = creditFrame

makeHeader(pAbout, "الاختصارات")
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 80)
info.BackgroundColor3 = Color3.fromRGB(25, 18, 22)
info.BackgroundTransparency = 0.2
info.BorderSizePixel = 0
info.Text = "  • الأيقونة : اضغط لفتح/إغلاق القائمة\n  • اسحب الأيقونة لتحريكها\n  • اسحب العنوان لتحريك النافذة\n  • التصويب يعمل تلقائياً أثناء تفعيله"
info.TextColor3 = Color3.fromRGB(200, 180, 180)
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.TextWrapped = true
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.Parent = pAbout
local iC = Instance.new("UICorner") iC.CornerRadius = UDim.new(0, 8) iC.Parent = info

-- Tabs
makeTab("الكشف", "esp")
makeTab("التصويب", "aim")
makeTab("الحركة", "move")
makeTab("الحقوق", "about")

showPage("esp")

-- MENU
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

-- MAIN LOOP
RunService.RenderStepped:Connect(function(dt)
    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) then
            if Config.ESP then
                if not espCache[p] then createESP(p) end
                renderESP(p)
            else
                if espCache[p] then hideESP(espCache[p]) end
            end
        else
            if espCache[p] then removeESP(p) end
        end
    end

    if Config.Aimbot then
        local target = findTarget()
        if target then
            local cur = Camera.CFrame
            local tgt = CFrame.new(cur.Position, target.Position)
            local maxAngle = math.rad(2.2)
            local dot = math.clamp(cur.LookVector:Dot(tgt.LookVector), -1, 1)
            local ang = math.acos(dot)
            if ang > maxAngle then
                local t = maxAngle / ang
                local newLook = cur.LookVector:Lerp(tgt.LookVector, t).Unit
                tgt = CFrame.new(cur.Position, cur.Position + newLook)
            end
            Camera.CFrame = cur:Lerp(tgt, Config.AimSmooth / 100)
        end
    else
        LockedTarget = nil
    end

    if Config.Fly then
        local c = LocalPlayer.Character
        if c then
            local hrp = c:FindFirstChild("HumanoidRootPart")
            local h = c:FindFirstChildOfClass("Humanoid")
            if hrp and h then
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
                FlyBV.Velocity = flat * md.Z * Config.FlySpeed + rt * md.X * Config.FlySpeed
                FlyFG.CFrame = Camera.CFrame
            end
        end
    else
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyFG then FlyFG:Destroy() FlyFG = nil end
    end

    local c = LocalPlayer.Character
    if c then
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then
            if Config.SpeedOn then
                h.WalkSpeed = Config.SpeedValue
            elseif h.WalkSpeed > 16 then
                h.WalkSpeed = 16
            end
            if Config.JumpOn then
                h.UseJumpPower = true
                h.JumpPower = Config.JumpValue
            end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if Config.InfJump then
        local c = LocalPlayer.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    LockedTarget = nil
    FlyBV = nil
    FlyFG = nil
end)
Players.PlayerRemoving:Connect(removeESP)

print("[WAR] loaded.")
print("TikTok: strayshot3 | Telegram: BB12co")
