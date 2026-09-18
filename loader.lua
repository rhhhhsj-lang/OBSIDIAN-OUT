-- ============================================================
-- OBSIDIAN GOD LOADER | ULTIMATE ROUTE v4
-- 15 sources x 8 methods x auto-cache
-- ============================================================

local USER = "rhhhhsj-lang"
local REPO = "OBSIDIAN-OUT"
local BRANCH = "main"
local FILE = "godmode.lua"

-- ============================================================
-- SOURCES (15)
-- ============================================================
local SOURCES = {
    "https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/refs/heads/" .. BRANCH .. "/" .. FILE,
    "https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE,
    "https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/refs/heads/master/" .. FILE,
    "https://cdn.jsdelivr.net/gh/" .. USER .. "/" .. REPO .. "@" .. BRANCH .. "/" .. FILE,
    "https://cdn.jsdelivr.net/gh/" .. USER .. "/" .. REPO .. "/" .. FILE,
    "https://cdn.statically.io/gh/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE,
    "https://rawcdn.githack.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE,
    "https://raw.githack.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE,
    "https://gitcdn.link/repo/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE,
    "https://gitcdn.xyz/repo/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE,
    "https://ghproxy.com/https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE,
    "https://gh-proxy.com/https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE,
    "https://mirror.ghproxy.com/https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE,
    "https://raw.gitmirror.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE,
    "https://ghps.cc/https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/" .. FILE,
}

-- ============================================================
-- FETCH METHODS (8)
-- ============================================================
local METHODS = {
    { name = "game:HttpGet", fn = function(url)
        local ok, r = pcall(function() return game:HttpGet(url, true) end)
        if ok and type(r) == "string" and #r > 200 then return r end
    end },
    { name = "request", fn = function(url)
        if not request then return nil end
        local ok, r = pcall(function()
            local x = request({ Url = url, Method = "GET", Headers = { ["User-Agent"] = "Roblox/WinInet" } })
            return x and x.Body
        end)
        if ok and type(r) == "string" and #r > 200 then return r end
    end },
    { name = "http_request", fn = function(url)
        if not http_request then return nil end
        local ok, r = pcall(function()
            local x = http_request({ Url = url, Method = "GET" })
            return x and x.Body
        end)
        if ok and type(r) == "string" and #r > 200 then return r end
    end },
    { name = "syn.request", fn = function(url)
        if not (syn and syn.request) then return nil end
        local ok, r = pcall(function()
            local x = syn.request({ Url = url, Method = "GET" })
            return x and x.Body
        end)
        if ok and type(r) == "string" and #r > 200 then return r end
    end },
    { name = "http.get", fn = function(url)
        if not (http and http.get) then return nil end
        local ok, r = pcall(function()
            local x = http.get(url)
            return x and (x.body or x.Body)
        end)
        if ok and type(r) == "string" and #r > 200 then return r end
    end },
    { name = "httpget", fn = function(url)
        if not httpget then return nil end
        local ok, r = pcall(httpget, url)
        if ok and type(r) == "string" and #r > 200 then return r end
    end },
    { name = "fluxus.request", fn = function(url)
        if not (fluxus and fluxus.request) then return nil end
        local ok, r = pcall(function()
            local x = fluxus.request({ Url = url, Method = "GET" })
            return x and x.Body
        end)
        if ok and type(r) == "string" and #r > 200 then return r end
    end },
    { name = "getcustomasset", fn = function(url)
        if not (getsynasset or getcustomasset) then return nil end
        -- skip, not for HTTP
        return nil
    end },
}

-- ============================================================
-- UI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OBS_GOD_LOADER"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if pg then ScreenGui.Parent = pg end
end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 130)
Frame.Position = UDim2.new(0.5, -150, 0.5, -65)
Frame.BackgroundColor3 = Color3.fromRGB(12, 10, 16)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
local FC = Instance.new("UICorner") FC.CornerRadius = UDim.new(0, 14) FC.Parent = Frame
local FS = Instance.new("UIStroke") FS.Color = Color3.fromRGB(255, 60, 60) FS.Thickness = 1.5 FS.Transparency = 0.3 FS.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 32)
Title.Position = UDim2.new(0, 0, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "👑 OBSIDIAN GOD LOADER"
Title.TextColor3 = Color3.fromRGB(255, 220, 100)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 16)
Status.Position = UDim2.new(0, 10, 0, 48)
Status.BackgroundTransparency = 1
Status.Text = "Starting..."
Status.TextColor3 = Color3.fromRGB(200, 200, 220)
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Frame

local Detail = Instance.new("TextLabel")
Detail.Size = UDim2.new(1, -20, 0, 14)
Detail.Position = UDim2.new(0, 10, 0, 66)
Detail.BackgroundTransparency = 1
Detail.Text = ""
Detail.TextColor3 = Color3.fromRGB(130, 130, 150)
Detail.Font = Enum.Font.Gotham
Detail.TextSize = 10
Detail.TextXAlignment = Enum.TextXAlignment.Left
Detail.Parent = Frame

local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(1, -20, 0, 6)
BarBg.Position = UDim2.new(0, 10, 0, 90)
BarBg.BackgroundColor3 = Color3.fromRGB(40, 30, 40)
BarBg.BorderSizePixel = 0
BarBg.Parent = Frame
local BBC = Instance.new("UICorner") BBC.CornerRadius = UDim.new(1, 0) BBC.Parent = BarBg

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBg
local BFC = Instance.new("UICorner") BFC.CornerRadius = UDim.new(1, 0) BFC.Parent = BarFill

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, 0, 0, 14)
Info.Position = UDim2.new(0, 0, 0, 108)
Info.BackgroundTransparency = 1
Info.Text = "TikTok: strayshot3 | Telegram: BB12co"
Info.TextColor3 = Color3.fromRGB(100, 100, 120)
Info.Font = Enum.Font.Gotham
Info.TextSize = 9
Info.Parent = Frame

local TweenService = game:GetService("TweenService")

local function setStatus(text, color)
    pcall(function()
        Status.Text = text
        Status.TextColor3 = color or Color3.fromRGB(200, 200, 220)
    end)
end

local function setDetail(text)
    pcall(function() Detail.Text = text end)
end

local function setProgress(pct)
    pcall(function()
        TweenService:Create(BarFill, TweenInfo.new(0.12), {
            Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
        }):Play()
    end)
end

local function destroyUI()
    pcall(function() ScreenGui:Destroy() end)
end

-- ============================================================
-- CACHE
-- ============================================================
local CACHE_FILE = "obs_godmode_cache.lua"
local CACHE_META = "obs_godmode_meta.json"

local function saveCache(src)
    if not writefile then return end
    pcall(function()
        writefile(CACHE_FILE, src)
        if writefile then
            writefile(CACHE_META, tostring(os.time()))
        end
    end)
end

local function loadCache()
    if not readfile or not isfile then return nil end
    local ok, src = pcall(function()
        if isfile(CACHE_FILE) then return readfile(CACHE_FILE) end
    end)
    if ok and src and #src > 200 then return src end
    return nil
end

-- ============================================================
-- LOADER CORE
-- ============================================================
local function tryAllSources()
    local total = #SOURCES * #METHODS
    local tried = 0

    for si, url in ipairs(SOURCES) do
        setStatus("Source " .. si .. "/" .. #SOURCES)
        setDetail(url:sub(1, 70) .. "...")

        for mi, method in ipairs(METHODS) do
            tried = tried + 1
            setProgress(tried / total * 0.85)

            local ok, src = pcall(method.fn, url)
            if ok and src then
                setStatus("Compiling (" .. method.name .. ")...")
                setDetail("Success via " .. method.name)
                setProgress(0.92)

                local fn, err = loadstring(src)
                if fn then
                    saveCache(src)
                    setProgress(1)
                    setStatus("Loaded!", Color3.fromRGB(100, 255, 150))
                    task.wait(0.35)
                    destroyUI()
                    local success, runErr = pcall(fn)
                    if not success then
                        warn("[LOADER] Runtime: " .. tostring(runErr))
                    end
                    return true
                else
                    setDetail("Compile error: " .. tostring(err):sub(1, 40))
                end
            end

            task.wait(0.02)
        end
    end
    return false
end

-- ============================================================
-- RUN
-- ============================================================
task.spawn(function()
    task.wait(0.3)

    if not loadstring then
        setStatus("No loadstring!", Color3.fromRGB(255, 100, 100))
        task.wait(3)
        destroyUI()
        return
    end

    -- Try cache first
    setStatus("Checking cache...")
    setProgress(0.05)
    local cached = loadCache()
    if cached then
        setStatus("Using cache...")
        setProgress(0.95)
        local fn = loadstring(cached)
        if fn then
            setProgress(1)
            setStatus("Loaded (cached)", Color3.fromRGB(100, 255, 150))
            task.wait(0.3)
            destroyUI()
            local ok, err = pcall(fn)
            if not ok then
                warn("[LOADER] Cache runtime error: " .. tostring(err))
                -- Cache broken, delete and fetch fresh
                pcall(function() if delfile then delfile(CACHE_FILE) end end)
            else
                return
            end
        end
    end

    -- Fetch fresh
    setStatus("Fetching fresh...")
    local ok = tryAllSources()

    if not ok then
        setStatus("All " .. (#SOURCES * #METHODS) .. " attempts failed", Color3.fromRGB(255, 100, 100))
        setDetail("Check internet / repo URL")
        setProgress(1)
        task.wait(5)
        destroyUI()
    end
end)
