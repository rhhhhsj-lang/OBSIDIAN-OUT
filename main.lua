-- ============================================================
-- OBSIDIAN SAB v11 | LEARNER EDITION
-- Learns real remotes from your actions, then replays
-- TikTok: strayshot3 | Telegram: BB12co
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

print("[SAB v11] Learner loading...")

-- ============================================================
-- CAPABILITIES
-- ============================================================
local Cap = {
    getrawmetatable = type(rawget(_G, "getrawmetatable")) == "function",
    setreadonly = type(rawget(_G, "setreadonly")) == "function",
    newcclosure = type(rawget(_G, "newcclosure")) == "function",
    getnamecallmethod = type(rawget(_G, "getnamecallmethod")) == "function",
    checkcaller = type(rawget(_G, "checkcaller")) == "function",
    getconnections = type(rawget(_G, "getconnections")) == "function",
}

print("[SAB] hook available:", Cap.getrawmetatable and Cap.newcclosure)

-- ============================================================
-- STATE
-- ============================================================
local State = {
    -- Learned data
    Learned = {
        StealRemote = nil,
        StealArgs = nil,
        StealTargetIndex = nil,
        CollectRemotes = {},
        LockRemotes = {},
        LastStealTime = 0,
        LastCollectTime = 0,
        LastLockTime = 0,
    },
    -- Counters
    StealsFired = 0,
    CollectsFired = 0,
    LocksFired = 0,
    BlockedKicks = 0,
    BlockedPosWrites = 0,
    WarningLevel = 0,
    LastWarningTime = 0,
    -- Speed
    SpeedActive = false,
    SpeedBV = nil,
    LastGoodPos = nil,
    LastMoveDir = nil,
    -- Noclip
    NoclipActive = false,
    NoclipSaved = {},
    -- Recording
    Recording = false,
}

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    -- Auto Steal
    AutoSteal = false,
    StealDelay = 0.3,
    AutoLock = false,
    
    -- Auto Collect
    AutoCollect = false,
    CollectDelay = 0.15,
    
    -- Movement
    SpeedOn = false,
    SpeedValue = 50,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,
    InfJump = false,
    
    -- Protect
    AntiKick = true,
    AntiTeleport = true,
    AntiPosReset = true,
    ValueSpoof = true,
}

-- ============================================================
-- HELPERS
-- ============================================================
local function getChar() return LocalPlayer.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getGameMT()
    if not Cap.getrawmetatable then return nil end
    local ok, mt = pcall(getrawmetatable, game)
    if ok and mt then return mt end
    return nil
end

local function log(msg, color)
    print("[SAB] " .. msg)
end

-- ============================================================
-- THE LEARNER HOOK
-- Records every FireServer call. When user steals manually,
-- we capture the exact remote + payload structure
-- ============================================================
local function isStealLike(name)
    local n = name:lower()
    return n:find("steal") or n:find("grab") or n:find("take") or n:find("snatch") 
        or n:find("pick") or n:find("rob") or n:find("claim") or n:find("buy")
end

local function isCollectLike(name)
    local n = name:lower()
    return n:find("collect") or n:find("cash") or n:find("money") 
        or n:find("pickup") or n:find("claim")
end

local function isLockLike(name)
    local n = name:lower()
    return n:find("lock") or n:find("cage") or n:find("barrier") or n:find("shield")
end

local function isPositionReset(name)
    local n = name:lower()
    return n:find("reset") or n:find("teleport") or n:find("snap") or n:find("position")
end

local HookInstalled = false

local function installLearnerHook()
    if HookInstalled then return true end
    if not (Cap.getrawmetatable and Cap.setreadonly and Cap.newcclosure and Cap.getnamecallmethod) then
        log("Cannot install learner - missing capabilities")
        return false
    end
    local mt = getGameMT()
    if not mt then return false end
    
    local oldNC = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        -- Only intercept FireServer/InvokeServer
        if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
            local isServerCall = false
            if Cap.checkcaller then
                isServerCall = checkcaller()  -- our own calls
            end
            
            local args = {...}
            local name = self.Name
            
            -- Record user actions (not our own)
            if not isServerCall then
                -- Steal-like remote
                if isStealLike(name) then
                    State.Learned.StealRemote = self
                    State.Learned.StealArgs = args
                    -- Detect which argument is the target
                    for i, a in ipairs(args) do
                        if typeof(a) == "Instance" then
                            State.Learned.StealTargetIndex = i
                            break
                        end
                    end
                    State.Learned.LastStealTime = tick()
                    log("LEARNED steal: " .. self:GetFullName() .. " | args=" .. #args)
                end
                
                -- Collect-like remote
                if isCollectLike(name) then
                    table.insert(State.Learned.CollectRemotes, {remote = self, args = args})
                    State.Learned.LastCollectTime = tick()
                    log("LEARNED collect: " .. self:GetFullName())
                end
                
                -- Lock-like remote
                if isLockLike(name) then
                    table.insert(State.Learned.LockRemotes, {remote = self, args = args})
                    State.Learned.LastLockTime = tick()
                    log("LEARNED lock: " .. self:GetFullName())
                end
            end
        end
        
        -- Anti-Kick
        if method == "Kick" and Config.AntiKick then
            State.BlockedKicks = State.BlockedKicks + 1
            return nil
        end
        
        -- Anti-Teleport
        if method == "Teleport" or method == "TeleportToPlaceInstance" or method == "TeleportAsync" then
            return nil
        end
        
        return oldNC(self, ...)
    end)
    setreadonly(mt, true)
    HookInstalled = true
    log("Learner hook installed")
    return true
end

-- ============================================================
-- HOOK: BLOCK POSITION RESET (critical for speed)
-- ============================================================
local PositionHookInstalled = false

local function installPositionBlock()
    if PositionHookInstalled then return true end
    if not (Cap.getrawmetatable and Cap.setreadonly and Cap.newcclosure) then return false end
    local mt = getGameMT()
    if not mt then return false end
    
    local oldNI = mt.__newindex
    setreadonly(mt, false)
    mt.__newindex = newcclosure(function(self, key, value)
        if Config.AntiPosReset and State.SpeedActive then
            if typeof(self) == "Instance" and self:IsA("BasePart") then
                if self.Name == "HumanoidRootPart" and self.Parent == LocalPlayer.Character then
                    if key == "CFrame" or key == "Position" or key == "Velocity" 
                       or key == "AssemblyLinearVelocity" then
                        if Cap.checkcaller and not checkcaller() then
                            State.BlockedPosWrites = State.BlockedPosWrites + 1
                            return nil
                        end
                    end
                end
            end
        end
        return oldNI(self, key, value)
    end)
    setreadonly(mt, true)
    PositionHookInstalled = true
    log("Position block installed")
    return true
end

-- ============================================================
-- HOOK: VALUE SPOOF
-- ============================================================
local IndexHookInstalled = false

local function installIndexSpoof()
    if IndexHookInstalled then return true end
    if not (Cap.getrawmetatable and Cap.setreadonly and Cap.newcclosure) then return false end
    local mt = getGameMT()
    if not mt then return false end
    
    local oldIndex = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if Config.ValueSpoof then
            if typeof(self) == "Instance" and self:IsA("Humanoid") and self.Parent == LocalPlayer.Character then
                if key == "WalkSpeed" then return 16 end
                if key == "JumpPower" then return 50 end
            end
        end
        return oldIndex(self, key)
    end)
    setreadonly(mt, true)
    IndexHookInstalled = true
    log("Index spoof installed")
    return true
end

-- ============================================================
-- KILL MONITORS
-- ============================================================
local function killMonitors()
    if not Cap.getconnections then return 0 end
    local char = getChar()
    if not char then return 0 end
    local h = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local killed = 0
    
    if h then
        for _, prop in ipairs({"WalkSpeed", "JumpPower"}) do
            pcall(function()
                for _, conn in ipairs(getconnections(h:GetPropertyChangedSignal(prop))) do
                    if conn.Disable then conn:Disable() killed = killed + 1 end
                end
            end)
        end
    end
    if hrp then
        for _, prop in ipairs({"Position", "CFrame"}) do
            pcall(function()
                for _, conn in ipairs(getconnections(hrp:GetPropertyChangedSignal(prop))) do
                    if conn.Disable then conn:Disable() killed = killed + 1 end
                end
            end)
        end
    end
    log("Killed " .. killed .. " monitors")
    return killed
end

-- ============================================================
-- SPEED (Anti-Rubberband)
-- ============================================================
local function applySpeed()
    local char = getChar()
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not h or not hrp then return end
    
    State.SpeedActive = Config.SpeedOn
    
    if Config.SpeedOn then
        -- Server always sees 16
        if h.WalkSpeed ~= 16 then h.WalkSpeed = 16 end
        -- Own the physics
        pcall(function() hrp:SetNetworkOwner(LocalPlayer) end)
        
        -- Detect snap-back
        local curPos = hrp.Position
        if State.LastGoodPos and State.LastMoveDir then
            local diff = curPos - State.LastGoodPos
            if diff.Magnitude > 6 then
                local dir = diff.Unit
                -- If moving opposite to our direction, server snapped us
                if dir:Dot(State.LastMoveDir) < -0.3 then
                    hrp.CFrame = CFrame.new(State.LastGoodPos + State.LastMoveDir * 3)
                end
            end
        end
        State.LastGoodPos = hrp.Position
        
        -- Apply real speed
        local md = h.MoveDirection
        if md.Magnitude > 0.1 then
            if not State.SpeedBV or not State.SpeedBV.Parent then
                State.SpeedBV = Instance.new("BodyVelocity")
                State.SpeedBV.MaxForce = Vector3.new(1e6, 0, 1e6)
                State.SpeedBV.P = 1250
                State.SpeedBV.Parent = hrp
            end
            local desired = md.Unit * Config.SpeedValue
            State.SpeedBV.Velocity = Vector3.new(desired.X, 0, desired.Z)
            State.LastMoveDir = md.Unit
        else
            if State.SpeedBV then State.SpeedBV.Velocity = Vector3.zero end
            State.LastMoveDir = nil
        end
    else
        if State.SpeedBV then State.SpeedBV:Destroy() State.SpeedBV = nil end
        State.LastGoodPos = nil
        State.LastMoveDir = nil
    end
end

-- ============================================================
-- FLY
-- ============================================================
local FlyBV, FlyFG
local function applyFly()
    local char = getChar()
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not h or not hrp then return end
    
    if Config.Fly then
        if not FlyBV or not FlyBV.Parent then
            FlyBV = Instance.new("BodyVelocity")
            FlyBV.MaxForce = Vector3.new(4000, 4000, 4000)
            FlyBV.Parent = hrp
            FlyFG = Instance.new("BodyGyro")
            FlyFG.MaxTorque = Vector3.new(4000, 4000, 4000)
            FlyFG.P = 3000
            FlyFG.D = 500
            FlyFG.Parent = hrp
        end
        local md = h.MoveDirection
        local cl = Camera.CFrame.LookVector
        local flat = Vector3.new(cl.X, 0, cl.Z)
        if flat.Magnitude > 0.01 then flat = flat.Unit end
        local rt = flat:Cross(Vector3.new(0, 1, 0))
        FlyBV.Velocity = (flat * md.Z + rt * md.X) * Config.FlySpeed
        FlyFG.CFrame = Camera.CFrame
    else
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyFG then FlyFG:Destroy() FlyFG = nil end
    end
end

-- ============================================================
-- NOCLIP (pulse, safe)
-- ============================================================
local function applyNoclip()
    if not Config.Noclip then
        if next(State.NoclipSaved) then
            -- Restore
            local char = getChar()
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                        p.CanCollide = true
                    end
                end
            end
            State.NoclipSaved = {}
        end
        return
    end
    local char = getChar()
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if p.Name == "HumanoidRootPart" then
                p.CanCollide = false
            else
                p.CanCollide = false
            end
        end
    end
end

-- ============================================================
-- AUTO STEAL (Replay learned)
-- ============================================================
local function getBestBrainrot()
    -- Find highest-value brainrot outside our plot
    local best, bestVal = nil, 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("brainrot") or n:find("pet") or n:find("animal") then
                local val = 1
                for _, c in ipairs(obj:GetDescendants()) do
                    if c:IsA("IntValue") or c:IsA("NumberValue") then
                        local cn = c.Name:lower()
                        if cn:find("price") or cn:find("value") or cn:find("worth") then
                            val = tonumber(c.Value) or 1
                        end
                    end
                end
                if val > bestVal then
                    bestVal = val
                    best = obj
                end
            end
        end
    end
    return best
end

local function replaySteal()
    if not State.Learned.StealRemote then return false end
    if not State.Learned.StealRemote.Parent then return false end
    if not State.Learned.StealArgs then return false end
    
    -- Find best target
    local target = getBestBrainrot()
    
    -- Reconstruct args: replace Instance at target index
    local args = {}
    for i, a in ipairs(State.Learned.StealArgs) do
        if i == State.Learned.StealTargetIndex and target then
            args[i] = target
        else
            args[i] = a
        end
    end
    
    -- Fire
    local ok = pcall(function()
        State.Learned.StealRemote:FireServer(table.unpack(args))
    end)
    if ok then
        State.StealsFired = State.StealsFired + 1
    end
    return ok
end

local function replayCollect()
    if #State.Learned.CollectRemotes == 0 then return false end
    
    local fired = 0
    for _, entry in ipairs(State.Learned.CollectRemotes) do
        if entry.remote and entry.remote.Parent then
            pcall(function()
                entry.remote:FireServer(table.unpack(entry.args))
            end)
            fired = fired + 1
        end
    end
    State.CollectsFired = State.CollectsFired + fired
    return fired > 0
end

local function replayLock()
    if #State.Learned.LockRemotes == 0 then return false end
    
    local fired = 0
    for _, entry in ipairs(State.Learned.LockRemotes) do
        if entry.remote and entry.remote.Parent then
            pcall(function()
                entry.remote:FireServer(table.unpack(entry.args))
            end)
            fired = fired + 1
        end
    end
    State.LocksFired = State.LocksFired + fired
    return fired > 0
end

-- ============================================================
-- WARNING DETECTION
-- ============================================================
local function onWarning()
    local now = tick()
    if now - State.LastWarningTime < 3 then return end
    State.LastWarningTime = now
    State.WarningLevel = State.WarningLevel + 1
    log("WARNING detected - Level " .. State.WarningLevel .. "/3")
    
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "WARNING",
            Text = State.WarningLevel .. "/3",
            Duration = 5,
        })
    end)
    
    if State.WarningLevel >= 2 then
        log("Disabling all at warning level 2")
        Config.AutoSteal = false
        Config.AutoCollect = false
        Config.Fly = false
        Config.SpeedOn = false
        Config.Noclip = false
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        local containers = {game:GetService("CoreGui")}
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then table.insert(containers, pg) end
        for _, container in ipairs(containers) do
            for _, gui in ipairs(container:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    for _, txt in ipairs(gui:GetDescendants()) do
                        if txt:IsA("TextLabel") then
                            local t = txt.Text:lower()
                            if (t:find("warning") or t:find("تحذير")) and t:find("/3") then
                                onWarning()
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- MAIN LOOPS
-- ============================================================
RunService.RenderStepped:Connect(function()
    applySpeed()
    applyFly()
    applyNoclip()
end)

RunService.Heartbeat:Connect(function()
    if Config.SpeedOn or Config.Fly then
        local hrp = getHRP()
        if hrp then pcall(function() hrp:SetNetworkOwner(LocalPlayer) end) end
    end
end)

-- Auto Steal Loop
task.spawn(function()
    while true do
        task.wait(Config.StealDelay)
        if Config.AutoSteal then
            pcall(replaySteal)
        end
    end
end)

-- Auto Collect Loop
task.spawn(function()
    while true do
        task.wait(Config.CollectDelay)
        if Config.AutoCollect then
            pcall(replayCollect)
        end
    end
end)

-- Auto Lock Loop
task.spawn(function()
    while true do
        task.wait(2)
        if Config.AutoLock then
            pcall(replayLock)
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if Config.InfJump then
        local c = getChar()
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- ============================================================
-- GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OBS_SAB"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local vp = Camera.ViewportSize
local FW = math.clamp(vp.X * 0.92, 310, 420)
local FH = math.clamp(vp.Y * 0.8, 480, 620)

local Icon = Instance.new("ImageButton")
Icon.Size = UDim2.new(0, 52, 0, 52)
Icon.Position = UDim2.new(0, 15, 0, 100)
Icon.BackgroundColor3 = Color3.fromRGB(18, 22, 20)
Icon.BackgroundTransparency = 0.1
Icon.BorderSizePixel = 0
Icon.AutoButtonColor = false
Icon.Active = true
Icon.Parent = ScreenGui
local IC = Instance.new("UICorner") IC.CornerRadius = UDim.new(1, 0) IC.Parent = Icon
local IStr = Instance.new("UIStroke") IStr.Color = Color3.fromRGB(255, 200, 60) IStr.Thickness = 2 IStr.Parent = Icon
local ILbl = Instance.new("TextLabel")
ILbl.Size = UDim2.new(1, 0, 1, 0) ILbl.BackgroundTransparency = 1
ILbl.Text = "🧠" ILbl.TextColor3 = Color3.fromRGB(255, 255, 255)
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
Main.BackgroundColor3 = Color3.fromRGB(14, 16, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.ClipsDescendants = true
Main.Parent = ScreenGui
local MC = Instance.new("UICorner") MC.CornerRadius = UDim.new(0, 14) MC.Parent = Main
local MStr = Instance.new("UIStroke") MStr.Color = Color3.fromRGB(255, 200, 60) MStr.Thickness = 1.5 MStr.Transparency = 0.3 MStr.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundColor3 = Color3.fromRGB(28, 26, 20)
Header.BorderSizePixel = 0
Header.Parent = Main
local HC = Instance.new("UICorner") HC.CornerRadius = UDim.new(0, 14) HC.Parent = Header

local HText = Instance.new("TextLabel")
HText.Size = UDim2.new(1, -100, 1, 0)
HText.Position = UDim2.new(0, 14, 0, 0)
HText.BackgroundTransparency = 1
HText.Text = "🧠 OBSIDIAN LEARNER"
HText.TextColor3 = Color3.fromRGB(255, 220, 140)
HText.TextXAlignment = Enum.TextXAlignment.Left
HText.Font = Enum.Font.GothamBold
HText.TextSize = 13
HText.Parent = Header

local WarnLbl = Instance.new("TextLabel")
WarnLbl.Size = UDim2.new(0, 60, 0, 20)
WarnLbl.Position = UDim2.new(1, -95, 0, 12)
WarnLbl.BackgroundColor3 = Color3.fromRGB(40, 60, 45)
WarnLbl.BorderSizePixel = 0
WarnLbl.Text = "0/3"
WarnLbl.TextColor3 = Color3.fromRGB(150, 255, 180)
WarnLbl.Font = Enum.Font.GothamBold
WarnLbl.TextSize = 11
WarnLbl.Parent = Header
local WLC = Instance.new("UICorner") WLC.CornerRadius = UDim.new(0, 5) WLC.Parent = WarnLbl

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(210, 55, 55)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header
local CBC = Instance.new("UICorner") CBC.CornerRadius = UDim.new(0, 7) CBC.Parent = CloseBtn

local ContentArea = Instance.new("ScrollingFrame")
ContentArea.Size = UDim2.new(1, -8, 1, -54)
ContentArea.Position = UDim2.new(0, 4, 0, 50)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.ScrollBarThickness = 3
ContentArea.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 60)
ContentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentArea.Parent = Main
local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.Parent = ContentArea
local LP = Instance.new("UIPadding")
LP.PaddingRight = UDim.new(0, 6)
LP.PaddingBottom = UDim.new(0, 8)
LP.Parent = ContentArea

local function makeHeader(text)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, 0, 0, 22)
    L.BackgroundColor3 = Color3.fromRGB(45, 38, 25)
    L.BackgroundTransparency = 0.2
    L.BorderSizePixel = 0
    L.Text = "  " .. text
    L.TextColor3 = Color3.fromRGB(255, 200, 100)
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Font = Enum.Font.GothamBold
    L.TextSize = 10
    L.Parent = ContentArea
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = L
end

local function makeToggle(text, key, cb)
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(1, 0, 0, 32)
    B.BackgroundColor3 = Color3.fromRGB(30, 28, 22)
    B.BackgroundTransparency = 0.15
    B.TextColor3 = Color3.fromRGB(220, 220, 210)
    B.Text = "  " .. text .. "  |  " .. (Config[key] and "مفعل" or "معطل")
    B.TextXAlignment = Enum.TextXAlignment.Left
    B.Font = Enum.Font.Gotham
    B.TextSize = 11
    B.BorderSizePixel = 0
    B.AutoButtonColor = false
    B.Parent = ContentArea
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = B
    if Config[key] then
        B.BackgroundColor3 = Color3.fromRGB(60, 85, 45)
        B.TextColor3 = Color3.fromRGB(180, 255, 150)
    end
    B.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        B.Text = "  " .. text .. "  |  " .. (Config[key] and "مفعل" or "معطل")
        B.BackgroundColor3 = Config[key] and Color3.fromRGB(60, 85, 45) or Color3.fromRGB(30, 28, 22)
        B.TextColor3 = Config[key] and Color3.fromRGB(180, 255, 150) or Color3.fromRGB(220, 220, 210)
        if cb then pcall(cb, Config[key]) end
    end)
    return B
end

local function makeSlider(text, key, mn, mx, df, cb)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, 0, 0, 44)
    F.BackgroundColor3 = Color3.fromRGB(30, 28, 22)
    F.BackgroundTransparency = 0.15
    F.BorderSizePixel = 0
    F.Parent = ContentArea
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = F

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -14, 0, 16)
    L.Position = UDim2.new(0, 8, 0, 3)
    L.BackgroundTransparency = 1
    L.Text = text .. ": " .. df
    L.TextColor3 = Color3.fromRGB(220, 220, 210)
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Font = Enum.Font.Gotham
    L.TextSize = 11
    L.Parent = F

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -20, 0, 10)
    Bar.Position = UDim2.new(0, 10, 0, 26)
    Bar.BackgroundColor3 = Color3.fromRGB(55, 50, 40)
    Bar.BorderSizePixel = 0
    Bar.Active = true
    Bar.Parent = F
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(1, 0) bc.Parent = Bar

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((df - mn) / (mx - mn), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
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

local function makeButton(text, cb, col)
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(1, 0, 0, 34)
    B.BackgroundColor3 = col or Color3.fromRGB(70, 55, 30)
    B.Text = text
    B.TextColor3 = Color3.fromRGB(255, 255, 255)
    B.Font = Enum.Font.GothamBold
    B.TextSize = 11
    B.TextWrapped = true
    B.BorderSizePixel = 0
    B.AutoButtonColor = false
    B.Parent = ContentArea
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = B
    B.MouseButton1Click:Connect(function() pcall(cb) end)
    return B
end

-- ================ BUILD UI ================
makeHeader("📚 الخطوة 1: تعلّم السكربت")

local learnInfo = Instance.new("TextLabel")
learnInfo.Size = UDim2.new(1, 0, 0, 70)
learnInfo.BackgroundColor3 = Color3.fromRGB(22, 30, 26)
learnInfo.BackgroundTransparency = 0.2
learnInfo.BorderSizePixel = 0
learnInfo.Text = "  1. افتح لعبة البيض\n  2. اسرق أي غرض يدوياً مرة واحدة\n  3. استقبل أي نقود يدوياً\n  4. اقفل قاعدتك يدوياً"
learnInfo.TextColor3 = Color3.fromRGB(200, 240, 210)
learnInfo.TextXAlignment = Enum.TextXAlignment.Left
learnInfo.TextYAlignment = Enum.TextYAlignment.Top
learnInfo.TextWrapped = true
learnInfo.Font = Enum.Font.Gotham
learnInfo.TextSize = 10
learnInfo.Parent = ContentArea
local liC = Instance.new("UICorner") liC.CornerRadius = UDim.new(0, 6) liC.Parent = learnInfo

makeHeader("📊 ما تم تعلمه")

local learnStatus = Instance.new("TextLabel")
learnStatus.Size = UDim2.new(1, 0, 0, 100)
learnStatus.BackgroundColor3 = Color3.fromRGB(22, 26, 30)
learnStatus.BackgroundTransparency = 0.2
learnStatus.BorderSizePixel = 0
learnStatus.Text = "  Steal remote: NOT LEARNED\n  Collect remotes: 0\n  Lock remotes: 0"
learnStatus.TextColor3 = Color3.fromRGB(200, 220, 240)
learnStatus.TextXAlignment = Enum.TextXAlignment.Left
learnStatus.TextYAlignment = Enum.TextYAlignment.Top
learnStatus.Font = Enum.Font.Code
learnStatus.TextSize = 10
learnStatus.Parent = ContentArea
local lsC = Instance.new("UICorner") lsC.CornerRadius = UDim.new(0, 6) lsC.Parent = learnStatus

makeButton("🔄 مسح ما تم تعلمه", function()
    State.Learned.StealRemote = nil
    State.Learned.StealArgs = nil
    State.Learned.CollectRemotes = {}
    State.Learned.LockRemotes = {}
    log("Learned data cleared")
end, Color3.fromRGB(120, 60, 60))

makeHeader("💰 الخطوة 2: تشغيل السرقة")
makeToggle("تفعيل السرقة التلقائية", "AutoSteal")
makeSlider("تأخير السرقة", "StealDelay", 0.1, 2, Config.StealDelay)
makeToggle("قفل القاعدة تلقائياً", "AutoLock")

makeHeader("💵 الخطوة 3: الجمع")
makeToggle("تفعيل الجمع التلقائي", "AutoCollect")
makeSlider("تأخير الجمع", "CollectDelay", 0.05, 1, Config.CollectDelay)

makeHeader("🏃 الحركة")
makeToggle("تفعيل السرعة", "SpeedOn")
makeSlider("قيمة السرعة", "SpeedValue", 20, 100, Config.SpeedValue)
makeToggle("تفعيل الطيران", "Fly")
makeSlider("سرعة الطيران", "FlySpeed", 20, 80, Config.FlySpeed)
makeToggle("اختراق الجدران", "Noclip")
makeToggle("قفز لا محدود", "InfJump")

makeHeader("🛡 الحماية")
makeToggle("Anti-Kick", "AntiKick")
makeToggle("Anti-Teleport", "AntiTeleport")
makeToggle("Anti-Position Reset", "AntiPosReset")
makeToggle("Value Spoof", "ValueSpoof")

makeButton("🛑 إيقاف كل شي", function()
    Config.AutoSteal = false
    Config.AutoCollect = false
    Config.Fly = false
    Config.SpeedOn = false
    Config.Noclip = false
    log("All disabled")
end, Color3.fromRGB(120, 50, 50))

makeHeader("📊 الإحصائيات")
local statsLbl = Instance.new("TextLabel")
statsLbl.Size = UDim2.new(1, 0, 0, 100)
statsLbl.BackgroundColor3 = Color3.fromRGB(22, 26, 28)
statsLbl.BackgroundTransparency = 0.2
statsLbl.BorderSizePixel = 0
statsLbl.Text = "  Steals: 0\n  Collects: 0\n  Locks: 0\n  Kicks blocked: 0\n  Position blocked: 0"
statsLbl.TextColor3 = Color3.fromRGB(200, 220, 220)
statsLbl.TextXAlignment = Enum.TextXAlignment.Left
statsLbl.TextYAlignment = Enum.TextYAlignment.Top
statsLbl.Font = Enum.Font.Code
statsLbl.TextSize = 10
statsLbl.Parent = ContentArea
local ssC = Instance.new("UICorner") ssC.CornerRadius = UDim.new(0, 6) ssC.Parent = statsLbl

makeHeader("الحقوق")
local credit = Instance.new("TextLabel")
credit.Size = UDim2.new(1, 0, 0, 60)
credit.BackgroundColor3 = Color3.fromRGB(28, 24, 18)
credit.BackgroundTransparency = 0.2
credit.BorderSizePixel = 0
credit.Text = "  تيك توك: strayshot3\n  تلجرام: BB12co\n  v11 Learner"
credit.TextColor3 = Color3.fromRGB(200, 180, 150)
credit.TextXAlignment = Enum.TextXAlignment.Left
credit.TextYAlignment = Enum.TextYAlignment.Top
credit.TextWrapped = true
credit.Font = Enum.Font.Gotham
credit.TextSize = 11
credit.Parent = ContentArea
local crC = Instance.new("UICorner") crC.CornerRadius = UDim.new(0, 6) crC.Parent = credit

-- Menu control
local MenuOpen = false
local function openMenu()
    if MenuOpen then return end
    MenuOpen = true
    Main.Visible = true
    TweenService:Create(Main, TweenInfo.new(0.22), {Size = UDim2.new(0, FW, 0, FH)}):Play()
end
local function closeMenu()
    if not MenuOpen then return end
    MenuOpen = false
    local t = TweenService:Create(Main, TweenInfo.new(0.16), {Size = UDim2.new(0, 0, 0, FH)})
    t.Completed:Connect(function() Main.Visible = false end)
    t:Play()
end

Icon.MouseButton1Click:Connect(function()
    if iconDrag then return end
    if MenuOpen then closeMenu() else openMenu() end
end)
CloseBtn.MouseButton1Click:Connect(closeMenu)

-- Status updates
task.spawn(function()
    while true do
        task.wait(0.5)
        if WarnLbl and WarnLbl.Parent then
            WarnLbl.Text = State.WarningLevel .. "/3"
        end
        if learnStatus and learnStatus.Parent then
            local stealName = State.Learned.StealRemote and State.Learned.StealRemote.Name or "NOT LEARNED"
            learnStatus.Text = string.format(
                "  Steal remote: %s\n  Collect remotes: %d\n  Lock remotes: %d",
                stealName, #State.Learned.CollectRemotes, #State.Learned.LockRemotes
            )
        end
        if statsLbl and statsLbl.Parent then
            statsLbl.Text = string.format(
                "  Steals: %d\n  Collects: %d\n  Locks: %d\n  Kicks blocked: %d\n  Position blocked: %d",
                State.StealsFired, State.CollectsFired, State.LocksFired,
                State.BlockedKicks, State.BlockedPosWrites
            )
        end
    end
end)

-- Reinit on respawn
LocalPlayer.CharacterAdded:Connect(function()
    FlyBV = nil
    FlyFG = nil
    State.SpeedBV = nil
    State.LastGoodPos = nil
    State.LastMoveDir = nil
    task.wait(1)
    if Config.ValueSpoof then killMonitors() end
end)

-- Init
task.spawn(function()
    task.wait(0.5)
    installLearnerHook()
    task.wait(0.2)
    installPositionBlock()
    task.wait(0.2)
    installIndexSpoof()
    task.wait(0.3)
    killMonitors()
    log("v11 ready - learn remotes by playing")
end)

print("[SAB] v11 loaded. Play manually first to teach the script.")
