-- ============================================================
-- OBSIDIAN SAB v8 | FIXED EDITION
-- Smart Speed + Auto Steal + Magnet Collect
-- TikTok: strayshot3 | Telegram: BB12co
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

print("[SAB v8] loading...")

-- ============================================================
-- CAPABILITY DETECTION
-- ============================================================
local Cap = {
    getrawmetatable = type(rawget(_G, "getrawmetatable")) == "function",
    setreadonly = type(rawget(_G, "setreadonly")) == "function",
    getconnections = type(rawget(_G, "getconnections")) == "function",
    newcclosure = type(rawget(_G, "newcclosure")) == "function",
    checkcaller = type(rawget(_G, "checkcaller")) == "function",
    getnamecallmethod = type(rawget(_G, "getnamecallmethod")) == "function",
}

-- ============================================================
-- STATE
-- ============================================================
local State = {
    BlockedKicks = 0,
    BlockedTeleports = 0,
    BlockedRemotes = 0,
    HookInstalled = false,
    WarningLevel = 0,
    LastWarningTime = 0,
    NoclipActive = false,
    NoclipStartTime = 0,
    AutoStopTriggered = false,
    StealRemote = nil,
    StealRemotes = {},
    Plots = {},
    StealsFired = 0,
    CashCollected = 0,
}

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    -- Auto Steal
    AutoSteal = false,
    StealBest = false,
    StealDelay = 0.1,
    AutoLock = false,

    -- Auto Collect / Farm
    AutoCollect = false,
    CollectRange = 50,
    AutoFarm = false,
    FarmRange = 100,

    -- Movement
    SpeedOn = false,
    SpeedValue = 40,
    Fly = false,
    FlySpeed = 45,
    JumpOn = false,
    JumpValue = 65,
    InfJump = false,

    -- Noclip
    Noclip = false,
    NoclipPulseRate = 0.08,
    NoclipRaycastDist = 2.5,
    NoclipAutoStop = true,
    NoclipMaxDuration = 3,
    NoclipPositionSpoof = true,

    -- Protection
    AntiKick = true,
    AntiTeleport = true,
    AntiRemoteBlock = true,
    KillMonitors = true,
    ValueSpoof = true,
    Humanize = true,

    -- Warning
    WarningDetect = true,
    AutoDisableOnWarning = true,
    PlaySoundOnWarning = true,
}

-- ============================================================
-- CHARACTER HELPERS
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

local FlyBV, FlyFG
local SpeedBV = nil
local NoclipSaved = {}
local NoclipFakePos = nil

-- ============================================================
-- LAYER 1: NAMECALL HOOK
-- ============================================================
local function getGameMT()
    if not Cap.getrawmetatable then return nil end
    local ok, mt = pcall(getrawmetatable, game)
    if ok and mt then return mt end
    return nil
end

local function installNamecallHook()
    if State.HookInstalled then return true end
    if not (Cap.getrawmetatable and Cap.setreadonly and Cap.newcclosure and Cap.getnamecallmethod) then
        print("[SAB] Cannot hook - missing capabilities")
        return false
    end
    local mt = getGameMT()
    if not mt then return false end

    local oldNC = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if method == "Kick" and Config.AntiKick then
            State.BlockedKicks = State.BlockedKicks + 1
            print("[SAB] Kick blocked #" .. State.BlockedKicks)
            return nil
        end

        if Config.AntiTeleport then
            if method == "Teleport" or method == "TeleportToPlaceInstance" or method == "TeleportAsync" then
                State.BlockedTeleports = State.BlockedTeleports + 1
                print("[SAB] Teleport blocked")
                return nil
            end
        end

        if method == "FireServer" and typeof(self) == "Instance" and Config.AntiRemoteBlock then
            local n = self.Name:lower()
            if n:find("detect") or n:find("cheat") or n:find("report")
               or n:find("flag") or n:find("ban") or n:find("warn")
               or n:find("punish") or n:find("violation") then
                State.BlockedRemotes = State.BlockedRemotes + 1
                return nil
            end
        end

        return oldNC(self, ...)
    end)
    setreadonly(mt, true)
    State.HookInstalled = true
    print("[SAB] Namecall hook installed")
    return true
end

-- ============================================================
-- LAYER 2: INDEX HOOK (Value Spoof)
-- ============================================================
local OriginalIndex
local function installIndexHook()
    if not (Cap.getrawmetatable and Cap.setreadonly and Cap.newcclosure) then return false end
    if OriginalIndex then return true end
    local mt = getGameMT()
    if not mt then return false end

    OriginalIndex = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if Config.ValueSpoof then
            if typeof(self) == "Instance" and self:IsA("Humanoid") then
                if self.Parent == LocalPlayer.Character then
                    if key == "WalkSpeed" then return 16 end
                    if key == "JumpPower" then return 50 end
                end
            end
            if State.NoclipActive and Config.NoclipPositionSpoof and NoclipFakePos then
                if typeof(self) == "Instance" and self:IsA("BasePart") then
                    if self.Name == "HumanoidRootPart" and self.Parent == LocalPlayer.Character then
                        if key == "Position" then return NoclipFakePos end
                        if key == "CFrame" then return CFrame.new(NoclipFakePos) end
                    end
                end
            end
        end
        return OriginalIndex(self, key)
    end)
    setreadonly(mt, true)
    print("[SAB] Index hook installed")
    return true
end

-- ============================================================
-- LAYER 3: NEWINDEX HOOK
-- ============================================================
local function installNewIndexHook()
    if not (Cap.getrawmetatable and Cap.setreadonly and Cap.newcclosure) then return false end
    local mt = getGameMT()
    if not mt then return false end
    local oldNI = mt.__newindex
    if not oldNI then return false end

    setreadonly(mt, false)
    mt.__newindex = newcclosure(function(self, key, value)
        if Config.ValueSpoof then
            if typeof(self) == "Instance" and self:IsA("Humanoid") then
                if self.Parent == LocalPlayer.Character then
                    if (key == "WalkSpeed" or key == "JumpPower") then
                        if Cap.checkcaller and not checkcaller() then return nil end
                    end
                end
            end
        end
        return oldNI(self, key, value)
    end)
    setreadonly(mt, true)
    print("[SAB] NewIndex hook installed")
    return true
end

-- ============================================================
-- LAYER 4: MONITOR KILLER
-- ============================================================
local function killMonitors()
    if not Cap.getconnections then return 0 end
    local char = getChar()
    if not char then return 0 end
    local h = char:FindFirstChildOfClass("Humanoid")
    if not h then return 0 end
    local killed = 0
    for _, prop in ipairs({"WalkSpeed", "JumpPower", "Health"}) do
        pcall(function()
            for _, conn in ipairs(getconnections(h:GetPropertyChangedSignal(prop))) do
                if conn.Disable then conn:Disable() killed = killed + 1 end
            end
        end)
    end
    print("[SAB] Killed " .. killed .. " monitors")
    return killed
end

-- ============================================================
-- LAYER 5: WARNING DETECTION
-- ============================================================
local WarningMonitor = { Running = false }

local function onWarningDetected(text)
    if not Config.WarningDetect then return end
    local now = tick()
    if now - State.LastWarningTime < 3 then return end
    State.LastWarningTime = now
    State.WarningLevel = State.WarningLevel + 1
    print("[WARNING] Level: " .. State.WarningLevel .. "/3 | " .. tostring(text))

    if Config.PlaySoundOnWarning then
        pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = "rbxassetid://4745652884"
            s.Volume = 0.5
            s.Parent = game:GetService("SoundService")
            s:Play()
            game:GetService("Debris"):AddItem(s, 3)
        end)
    end

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "WARNING DETECTED",
            Text = "Level: " .. State.WarningLevel .. "/3",
            Duration = 5,
        })
    end)

    if Config.AutoDisableOnWarning then
        print("[SAB] AUTO-DISABLING")
        Config.AutoSteal = false
        Config.AutoFarm = false
        Config.AutoCollect = false
        Config.Fly = false
        Config.SpeedOn = false
        Config.Noclip = false
        State.NoclipActive = false
    end
end

local function startWarningMonitor()
    if WarningMonitor.Running then return end
    WarningMonitor.Running = true

    task.spawn(function()
        while WarningMonitor.Running do
            task.wait(0.5)
            if not Config.WarningDetect then continue end
            local containers = {game:GetService("CoreGui")}
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then table.insert(containers, pg) end
            for _, container in ipairs(containers) do
                for _, gui in ipairs(container:GetChildren()) do
                    if gui:IsA("ScreenGui") or gui:IsA("GuiObject") then
                        for _, txt in ipairs(gui:GetDescendants()) do
                            if txt:IsA("TextLabel") then
                                local t = txt.Text:lower()
                                if (t:find("warning") or t:find("exploit") or t:find("cheat")
                                   or t:find("تحذير") or t:find("اختراق"))
                                   and (t:find("/3") or t:find("1/") or t:find("2/") or t:find("3/")) then
                                    onWarningDetected(txt.Text)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    print("[SAB] Warning monitor active")
end

-- ============================================================
-- SMART NOCLIP
-- ============================================================
local function isBlockedByWall()
    local hrp = getHRP()
    local h = getHumanoid()
    if not hrp or not h then return false end
    local md = h.MoveDirection
    if md.Magnitude < 0.1 then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { getChar(), Camera }
    params.IgnoreWater = true
    local result = Workspace:Raycast(hrp.Position, md.Unit * Config.NoclipRaycastDist, params)
    if result and math.abs(result.Normal.Y) < 0.5 then return true end
    return false
end

local function saveCollides()
    local char = getChar()
    if not char then return end
    NoclipSaved = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then NoclipSaved[part] = part.CanCollide end
    end
end

local function disableCollides()
    local char = getChar()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end

local function restoreCollides()
    local char = getChar()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Name == "HumanoidRootPart" then part.CanCollide = false
            else part.CanCollide = true end
        end
    end
end

local LastPulse = 0
local NoclipSpoofUpdate = 0

RunService.Stepped:Connect(function()
    local now = tick()
    if State.NoclipActive and Config.NoclipPositionSpoof then
        if now - NoclipSpoofUpdate > 0.5 then
            NoclipSpoofUpdate = now
            local hrp = getHRP()
            local h = getHumanoid()
            if hrp and h then
                NoclipFakePos = hrp.Position - h.MoveDirection.Unit * 1
            end
        end
    end

    if State.NoclipActive and Config.NoclipAutoStop then
        if now - State.NoclipStartTime > Config.NoclipMaxDuration then
            State.NoclipActive = false
            Config.Noclip = false
            restoreCollides()
            State.AutoStopTriggered = true
            return
        end
    end

    if not Config.Noclip then
        if next(NoclipSaved) then restoreCollides() NoclipSaved = {} end
        return
    end

    if not State.NoclipActive then
        State.NoclipActive = true
        State.NoclipStartTime = now
        State.AutoStopTriggered = false
    end

    if isBlockedByWall() and now - LastPulse > Config.NoclipPulseRate then
        LastPulse = now
        if not next(NoclipSaved) then saveCollides() end
        disableCollides()
        task.spawn(function()
            task.wait(math.random(40, 80) / 1000)
            if Config.Noclip then restoreCollides() end
        end)
    end
end)

local function smartDash(distance)
    distance = distance or 8
    local hrp = getHRP()
    local h = getHumanoid()
    if not hrp or not h then return false end
    local dir = h.MoveDirection
    if dir.Magnitude < 0.1 then dir = Camera.CFrame.LookVector end
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude < 0.01 then return false end
    dir = dir.Unit
    local steps = 4
    local perStep = distance / steps
    for i = 1, steps do
        if not hrp or not hrp.Parent then break end
        hrp.CFrame = hrp.CFrame + dir * perStep
        task.wait(0.03)
    end
    return true
end

-- ============================================================
-- SMART SPEED (Anti Rubber-Band)
-- ============================================================
local function applySmartSpeed()
    local char = getChar()
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not h or not hrp then return end

    if Config.SpeedOn then
        -- Keep WalkSpeed at 16 (server-safe)
        if h.WalkSpeed ~= 16 then h.WalkSpeed = 16 end

        -- Apply real speed via BodyVelocity
        local md = h.MoveDirection
        if md.Magnitude > 0.1 then
            if not SpeedBV or not SpeedBV.Parent then
                SpeedBV = Instance.new("BodyVelocity")
                SpeedBV.MaxForce = Vector3.new(50000, 0, 50000)
                SpeedBV.Parent = hrp
            end
            local desired = md.Unit * Config.SpeedValue
            desired = Vector3.new(desired.X, 0, desired.Z)
            SpeedBV.Velocity = desired
        else
            if SpeedBV then SpeedBV.Velocity = Vector3.zero end
        end
    else
        if SpeedBV then SpeedBV:Destroy() SpeedBV = nil end
    end
end

-- Anti-rubberband: grab network ownership
RunService.Heartbeat:Connect(function()
    if not Config.SpeedOn then return end
    local hrp = getHRP()
    if not hrp then return end
    pcall(function() hrp:SetNetworkOwner(LocalPlayer) end)
end)

-- ============================================================
-- MOVEMENT LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    local char = getChar()
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if not h then return end

    applySmartSpeed()

    if Config.JumpOn then
        h.UseJumpPower = true
        h.JumpPower = math.min(Config.JumpValue, 80)
    end

    -- Fly
    if Config.Fly then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if not FlyBV or not FlyBV.Parent then
                FlyBV = Instance.new("BodyVelocity")
                FlyBV.MaxForce = Vector3.new(4000, 4000, 4000)
                FlyBV.Parent = hrp
                FlyFG = Instance.new("BodyGyro")
                FlyFG.MaxTorque = Vector3.new(4000, 4000, 4000)
                FlyFG.P = 3000 FlyFG.D = 500
                FlyFG.Parent = hrp
            end
            local md = h.MoveDirection
            local cl = Camera.CFrame.LookVector
            local flat = Vector3.new(cl.X, 0, cl.Z)
            if flat.Magnitude > 0.01 then flat = flat.Unit end
            local rt = flat:Cross(Vector3.new(0, 1, 0))
            local speed = math.min(Config.FlySpeed, 60)
            FlyBV.Velocity = (flat * md.Z + rt * md.X) * speed
            FlyFG.CFrame = Camera.CFrame
        end
    else
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyFG then FlyFG:Destroy() FlyFG = nil end
    end
end)

-- ============================================================
-- AUTO STEAL ENGINE v2
-- ============================================================
local function scanStealRemotes()
    State.StealRemotes = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:find("steal") or n:find("grab") or n:find("take")
               or n:find("snatch") or n:find("pick") or n == "the_real_steal_remote" then
                table.insert(State.StealRemotes, obj)
                print("[STEAL] Found: " .. obj:GetFullName())
            end
        end
    end
    return #State.StealRemotes
end

local function refreshPlots()
    State.Plots = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        local n = obj.Name:lower()
        if n:find("plot") or n:find("base") or n:find("house") then
            table.insert(State.Plots, obj)
        end
    end
    print("[STEAL] Found " .. #State.Plots .. " plots")
end

local function isMyPlot(plot)
    for _, v in ipairs(plot:GetChildren()) do
        if v:IsA("StringValue") or v:IsA("ObjectValue") then
            local n = v.Name:lower()
            if (n:find("owner") or n:find("player")) and
               (v.Value == LocalPlayer or tostring(v.Value) == LocalPlayer.Name) then
                return true
            end
        end
    end
    return false
end

local function findBestBrainrot()
    local best, bestValue = nil, 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("brainrot") or n:find("pet") or n:find("animal")
               or n:find("character") or n:find("collectible") then
                -- Skip if in our own plot
                local inMyPlot = false
                local parent = obj.Parent
                local depth = 0
                while parent and parent ~= workspace and depth < 10 do
                    if isMyPlot(parent) then inMyPlot = true break end
                    parent = parent.Parent
                    depth = depth + 1
                end
                if not inMyPlot then
                    local val = 1
                    for _, child in ipairs(obj:GetChildren()) do
                        if child:IsA("IntValue") or child:IsA("NumberValue") then
                            local cn = child.Name:lower()
                            if cn:find("price") or cn:find("value") or cn:find("cost") or cn:find("worth") then
                                val = tonumber(child.Value) or 1
                            end
                        end
                    end
                    if val > bestValue then
                        bestValue = val
                        best = obj
                    end
                end
            end
        end
    end
    return best
end

local function trySteal(target)
    if #State.StealRemotes == 0 then scanStealRemotes() end
    if #State.StealRemotes == 0 then return false end

    local fired = 0
    for _, remote in ipairs(State.StealRemotes) do
        if remote.Parent then
            pcall(function() remote:FireServer(target) end)
            pcall(function() remote:FireServer(target, "Steal") end)
            pcall(function() remote:FireServer("Steal", target) end)
            if target then
                pcall(function() remote:FireServer(target.Name) end)
                if target.Parent then
                    pcall(function() remote:FireServer(target.Parent) end)
                end
            end
            pcall(function() remote:FireServer() end)
            fired = fired + 1
        end
    end
    return fired > 0
end

local function autoLockBase()
    for _, plot in ipairs(State.Plots) do
        if isMyPlot(plot) then
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
            return
        end
    end
end

-- ============================================================
-- SMART COLLECT (Magnet Effect)
-- ============================================================
local function getNearbyItems(range)
    local hrp = getHRP()
    if not hrp then return {} end
    local myPos = hrp.Position
    local items = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            if n:find("cash") or n:find("coin") or n:find("money")
               or n:find("drop") or n:find("bill") or n:find("dollar")
               or n:find("banknote") or n:find("loot") then
                local pos
                if obj:IsA("BasePart") then
                    pos = obj.Position
                else
                    local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    if pp then pos = pp.Position end
                end
                if pos then
                    local d = (pos - myPos).Magnitude
                    if d <= range then
                        table.insert(items, {obj = obj, dist = d, pos = pos})
                    end
                end
            end
        end
    end
    table.sort(items, function(a, b) return a.dist < b.dist end)
    return items
end

local function magnetCollect(range)
    local hrp = getHRP()
    if not hrp then return false end
    local items = getNearbyItems(range)
    if #items == 0 then return false end

    local item = items[1]
    local target = item.obj
    pcall(function()
        if target:IsA("BasePart") then
            target:SetNetworkOwner(LocalPlayer)
            target.CFrame = hrp.CFrame * CFrame.new(0, 0, -2)
        elseif target:IsA("Model") and target.PrimaryPart then
            target.PrimaryPart:SetNetworkOwner(LocalPlayer)
            target:PivotTo(hrp.CFrame * CFrame.new(0, 0, -2))
        end
    end)

    for _, remote in ipairs(workspace:GetDescendants()) do
        if remote:IsA("RemoteEvent") and remote.Name:lower():find("pick") then
            pcall(function() remote:FireServer(target) end)
        end
    end

    State.CashCollected = State.CashCollected + 1
    return true
end

local function walkToItem(range)
    local hrp = getHRP()
    if not hrp then return false end
    local items = getNearbyItems(range)
    if #items == 0 then return false end
    local item = items[1]
    -- Only teleport if very close (safe)
    if item.dist < 15 then
        pcall(function()
            hrp.CFrame = CFrame.new(item.pos + Vector3.new(0, 3, 0))
        end)
        State.CashCollected = State.CashCollected + 1
    end
    return true
end

-- ============================================================
-- LOOPS
-- ============================================================
task.spawn(function()
    task.wait(2)
    scanStealRemotes()
    refreshPlots()
    task.wait(5)
    refreshPlots()
end)

-- Auto Steal Loop
task.spawn(function()
    while true do
        task.wait(Config.StealDelay)
        if Config.AutoSteal then
            local target = Config.StealBest and findBestBrainrot() or nil
            local ok = trySteal(target)
            if ok then State.StealsFired = State.StealsFired + 1 end
        end
    end
end)

-- Auto Collect / Farm / Lock
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoCollect then
            pcall(function()
                if not magnetCollect(Config.CollectRange) then
                    walkToItem(Config.CollectRange)
                end
            end)
        end
        if Config.AutoFarm then
            pcall(function()
                if not magnetCollect(Config.FarmRange) then
                    walkToItem(Config.FarmRange)
                end
            end)
        end
        if Config.AutoLock then pcall(autoLockBase) end
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
ILbl.Text = "🥚" ILbl.TextColor3 = Color3.fromRGB(255, 255, 255)
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
HText.Text = "🥚 OBSIDIAN SAB v8"
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

local TabBar = Instance.new("ScrollingFrame")
TabBar.Size = UDim2.new(1, -8, 0, 38)
TabBar.Position = UDim2.new(0, 4, 0, 48)
TabBar.BackgroundColor3 = Color3.fromRGB(24, 22, 18)
TabBar.BackgroundTransparency = 0.2
TabBar.BorderSizePixel = 0
TabBar.ScrollBarThickness = 2
TabBar.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 60)
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
    p.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 60)
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
            b.BackgroundColor3 = Color3.fromRGB(120, 85, 30)
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            b.BackgroundColor3 = Color3.fromRGB(38, 34, 26)
            b.TextColor3 = Color3.fromRGB(220, 200, 160)
        end
    end
end

local function makeTab(label, pageName)
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(0, 78, 0, 28)
    B.BackgroundColor3 = Color3.fromRGB(38, 34, 26)
    B.Text = label
    B.TextColor3 = Color3.fromRGB(220, 200, 160)
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
    L.BackgroundColor3 = Color3.fromRGB(45, 38, 25)
    L.BackgroundTransparency = 0.2
    L.BorderSizePixel = 0
    L.Text = "  " .. text
    L.TextColor3 = Color3.fromRGB(255, 200, 100)
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Font = Enum.Font.GothamBold
    L.TextSize = 10
    L.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = L
end

local function makeToggle(parent, text, key, cb)
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
    B.Parent = parent
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

local function makeSlider(parent, text, key, mn, mx, df, cb)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1, 0, 0, 44)
    F.BackgroundColor3 = Color3.fromRGB(30, 28, 22)
    F.BackgroundTransparency = 0.15
    F.BorderSizePixel = 0
    F.Parent = parent
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

local function makeButton(parent, text, cb, col)
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
    B.Parent = parent
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = B
    B.MouseButton1Click:Connect(function() pcall(cb) end)
    return B
end

-- Pages
makePage("steal")
makePage("collect")
makePage("move")
makePage("noclip")
makePage("protect")
makePage("about")

-- STEAL
local pSteal = Pages["steal"]
makeHeader(pSteal, "💰 السرقة التلقائية")
makeToggle(pSteal, "تفعيل السرقة", "AutoSteal")
makeToggle(pSteal, "استهداف الأفضل", "StealBest")
makeSlider(pSteal, "سرعة السرقة", "StealDelay", 0.05, 1, Config.StealDelay)
makeToggle(pSteal, "قفل القاعدة", "AutoLock")

makeHeader(pSteal, "📊 الحالة")
local stealStatus = Instance.new("TextLabel")
stealStatus.Size = UDim2.new(1, 0, 0, 60)
stealStatus.BackgroundColor3 = Color3.fromRGB(22, 26, 30)
stealStatus.BackgroundTransparency = 0.2
stealStatus.BorderSizePixel = 0
stealStatus.Text = "  Remotes: 0\n  Plots: 0\n  Steals fired: 0"
stealStatus.TextColor3 = Color3.fromRGB(200, 220, 240)
stealStatus.TextXAlignment = Enum.TextXAlignment.Left
stealStatus.TextYAlignment = Enum.TextYAlignment.Top
stealStatus.Font = Enum.Font.Code
stealStatus.TextSize = 10
stealStatus.Parent = pSteal
local stC = Instance.new("UICorner") stC.CornerRadius = UDim.new(0, 6) stC.Parent = stealStatus

makeButton(pSteal, "🔄 إعادة فحص Remotes", function()
    scanStealRemotes()
    refreshPlots()
end, Color3.fromRGB(60, 90, 120))

-- COLLECT
local pCollect = Pages["collect"]
makeHeader(pCollect, "💵 جمع النقود")
makeToggle(pCollect, "تفعيل الجمع", "AutoCollect")
makeSlider(pCollect, "نطاق الجمع", "CollectRange", 10, 200, Config.CollectRange)
makeToggle(pCollect, "Farm تلقائي", "AutoFarm")
makeSlider(pCollect, "نطاق Farm", "FarmRange", 20, 300, Config.FarmRange)

local collectStatus = Instance.new("TextLabel")
collectStatus.Size = UDim2.new(1, 0, 0, 40)
collectStatus.BackgroundColor3 = Color3.fromRGB(22, 26, 30)
collectStatus.BackgroundTransparency = 0.2
collectStatus.BorderSizePixel = 0
collectStatus.Text = "  Collected: 0"
collectStatus.TextColor3 = Color3.fromRGB(200, 220, 240)
collectStatus.TextXAlignment = Enum.TextXAlignment.Left
collectStatus.TextYAlignment = Enum.TextYAlignment.Top
collectStatus.Font = Enum.Font.Code
collectStatus.TextSize = 10
collectStatus.Parent = pCollect
local cS = Instance.new("UICorner") cS.CornerRadius = UDim.new(0, 6) cS.Parent = collectStatus

-- MOVE
local pMove = Pages["move"]
makeHeader(pMove, "🏃 السرعة")
makeToggle(pMove, "تفعيل السرعة", "SpeedOn")
makeSlider(pMove, "قيمة السرعة", "SpeedValue", 16, 60, Config.SpeedValue)

makeHeader(pMove, "✈ الطيران")
makeToggle(pMove, "تفعيل الطيران", "Fly")
makeSlider(pMove, "سرعة الطيران", "FlySpeed", 20, 60, Config.FlySpeed)

makeHeader(pMove, "🦘 القفز")
makeToggle(pMove, "قفز عالي", "JumpOn")
makeSlider(pMove, "قوة القفز", "JumpValue", 50, 80, Config.JumpValue)
makeToggle(pMove, "قفز لا محدود", "InfJump")

-- NOCLIP
local pNC = Pages["noclip"]
makeHeader(pNC, "🧱 Noclip ذكي")
makeToggle(pNC, "تفعيل Noclip", "Noclip")
makeToggle(pNC, "Auto-Stop", "NoclipAutoStop")
makeToggle(pNC, "Position Spoof", "NoclipPositionSpoof")
makeSlider(pNC, "Pulse Rate", "NoclipPulseRate", 0.03, 0.3, Config.NoclipPulseRate)
makeSlider(pNC, "Max Duration", "NoclipMaxDuration", 1, 10, Config.NoclipMaxDuration)

makeHeader(pNC, "🚀 Dash آمن")
makeButton(pNC, "Dash قصير (8 studs)", function() smartDash(8) end, Color3.fromRGB(50, 90, 120))
makeButton(pNC, "Dash متوسط (15 studs)", function() smartDash(15) end, Color3.fromRGB(50, 90, 120))
makeButton(pNC, "Dash طويل (25 studs)", function() smartDash(25) end, Color3.fromRGB(70, 60, 110))

-- PROTECT
local pProtect = Pages["protect"]
makeHeader(pProtect, "🛡 الحماية")
makeToggle(pProtect, "Anti-Kick", "AntiKick")
makeToggle(pProtect, "Anti-Teleport", "AntiTeleport")
makeToggle(pProtect, "Anti-Remote Block", "AntiRemoteBlock")
makeToggle(pProtect, "Value Spoof", "ValueSpoof")
makeToggle(pProtect, "Kill Monitors", "KillMonitors")

makeHeader(pProtect, "⚠ كشف التحذيرات")
makeToggle(pProtect, "مراقبة Warning", "WarningDetect")
makeToggle(pProtect, "إيقاف تلقائي", "AutoDisableOnWarning")
makeToggle(pProtect, "تنبيه صوتي", "PlaySoundOnWarning")

local protectStatus = Instance.new("TextLabel")
protectStatus.Size = UDim2.new(1, 0, 0, 100)
protectStatus.BackgroundColor3 = Color3.fromRGB(22, 26, 28)
protectStatus.BackgroundTransparency = 0.2
protectStatus.BorderSizePixel = 0
protectStatus.Text = "  Blocked Kicks: 0\n  Blocked Teleports: 0\n  Blocked Remotes: 0\n  Warning Level: 0/3\n  Hooks: Active"
protectStatus.TextColor3 = Color3.fromRGB(200, 220, 220)
protectStatus.TextXAlignment = Enum.TextXAlignment.Left
protectStatus.TextYAlignment = Enum.TextYAlignment.Top
protectStatus.Font = Enum.Font.Code
protectStatus.TextSize = 10
protectStatus.Parent = pProtect
local psSC = Instance.new("UICorner") psSC.CornerRadius = UDim.new(0, 6) psSC.Parent = protectStatus

makeButton(pProtect, "🔄 إعادة تفعيل الحماية", function()
    State.HookInstalled = false
    installNamecallHook()
    installIndexHook()
    installNewIndexHook()
    if Config.KillMonitors then killMonitors() end
end, Color3.fromRGB(50, 100, 75))

makeButton(pProtect, "🛑 إيقاف كل الميزات", function()
    Config.AutoSteal = false
    Config.AutoFarm = false
    Config.AutoCollect = false
    Config.Fly = false
    Config.SpeedOn = false
    Config.JumpOn = false
    Config.InfJump = false
    Config.Noclip = false
    State.NoclipActive = false
    restoreCollides()
end, Color3.fromRGB(120, 50, 50))

-- ABOUT
local pAbout = Pages["about"]
makeHeader(pAbout, "الحقوق")
local creditFrame = Instance.new("Frame")
creditFrame.Size = UDim2.new(1, 0, 0, 130)
creditFrame.BackgroundColor3 = Color3.fromRGB(28, 24, 18)
creditFrame.BorderSizePixel = 0
creditFrame.Parent = pAbout
local CFC = Instance.new("UICorner") CFC.CornerRadius = UDim.new(0, 8) CFC.Parent = creditFrame

local c1 = Instance.new("TextLabel")
c1.Size = UDim2.new(1, -16, 0, 24)
c1.Position = UDim2.new(0, 8, 0, 12)
c1.BackgroundTransparency = 1
c1.Text = "  تيك توك : strayshot3"
c1.TextColor3 = Color3.fromRGB(255, 150, 100)
c1.TextXAlignment = Enum.TextXAlignment.Left
c1.Font = Enum.Font.GothamBold
c1.TextSize = 13
c1.Parent = creditFrame

local c2 = Instance.new("TextLabel")
c2.Size = UDim2.new(1, -16, 0, 24)
c2.Position = UDim2.new(0, 8, 0, 44)
c2.BackgroundTransparency = 1
c2.Text = "  قناة تلجرام : BB12co"
c2.TextColor3 = Color3.fromRGB(100, 180, 255)
c2.TextXAlignment = Enum.TextXAlignment.Left
c2.Font = Enum.Font.GothamBold
c2.TextSize = 13
c2.Parent = creditFrame

local c3 = Instance.new("TextLabel")
c3.Size = UDim2.new(1, -16, 0, 20)
c3.Position = UDim2.new(0, 8, 0, 76)
c3.BackgroundTransparency = 1
c3.Text = "  v8 FIXED | Anti-Rubberband Speed"
c3.TextColor3 = Color3.fromRGB(180, 180, 180)
c3.TextXAlignment = Enum.TextXAlignment.Left
c3.Font = Enum.Font.Gotham
c3.TextSize = 10
c3.Parent = creditFrame

local c4 = Instance.new("TextLabel")
c4.Size = UDim2.new(1, -16, 0, 20)
c4.Position = UDim2.new(0, 8, 0, 100)
c4.BackgroundTransparency = 1
c4.Text = "  الإصدار 8.0"
c4.TextColor3 = Color3.fromRGB(140, 140, 140)
c4.TextXAlignment = Enum.TextXAlignment.Left
c4.Font = Enum.Font.Gotham
c4.TextSize = 10
c4.Parent = creditFrame

-- Tabs
makeTab("السرقة", "steal")
makeTab("الجمع", "collect")
makeTab("الحركة", "move")
makeTab("Noclip", "noclip")
makeTab("الحماية", "protect")
makeTab("الحقوق", "about")

showPage("steal")

-- Menu
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

-- Status updates
task.spawn(function()
    while true do
        task.wait(0.5)
        if WarnLbl and WarnLbl.Parent then
            WarnLbl.Text = State.WarningLevel .. "/3"
            if State.WarningLevel == 0 then
                WarnLbl.BackgroundColor3 = Color3.fromRGB(40, 60, 45)
                WarnLbl.TextColor3 = Color3.fromRGB(150, 255, 180)
            elseif State.WarningLevel == 1 then
                WarnLbl.BackgroundColor3 = Color3.fromRGB(70, 60, 30)
                WarnLbl.TextColor3 = Color3.fromRGB(255, 220, 100)
            else
                WarnLbl.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
                WarnLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
            end
        end
        if protectStatus and protectStatus.Parent then
            protectStatus.Text = string.format(
                "  Blocked Kicks: %d\n  Blocked Teleports: %d\n  Blocked Remotes: %d\n  Warning Level: %d/3\n  Hooks: %s",
                State.BlockedKicks, State.BlockedTeleports, State.BlockedRemotes,
                State.WarningLevel, State.HookInstalled and "Active" or "Inactive"
            )
        end
        if stealStatus and stealStatus.Parent then
            stealStatus.Text = string.format(
                "  Remotes: %d\n  Plots: %d\n  Steals fired: %d",
                #State.StealRemotes, #State.Plots, State.StealsFired
            )
        end
        if collectStatus and collectStatus.Parent then
            collectStatus.Text = string.format("  Collected: %d", State.CashCollected)
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    FlyBV = nil
    FlyFG = nil
    SpeedBV = nil
    NoclipSaved = {}
    State.NoclipActive = false
    task.wait(1)
    if Config.KillMonitors then killMonitors() end
end)

-- Init
task.spawn(function()
    task.wait(0.5)
    installNamecallHook()
    installIndexHook()
    installNewIndexHook()
    task.wait(0.5)
    if Config.KillMonitors then killMonitors() end
    startWarningMonitor()
    print("[SAB] v8 initialized")
end)

print("[SAB] v8 loaded. TikTok: strayshot3 | Telegram: BB12co")
