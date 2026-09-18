local URLS = {
    "https://raw.githubusercontent.com/rhhhhsj-lang/OBSIDIAN-OUT/refs/heads/main/main.lua",
    "https://cdn.jsdelivr.net/gh/rhhhhsj-lang/OBSIDIAN-OUT@main/main.lua",
    "https://rawcdn.githack.com/rhhhhsj-lang/OBSIDIAN-OUT/main/main.lua",
}

local function fetch(url)
    local ok, r = pcall(function() return game:HttpGet(url, true) end)
    if ok and r and #r > 200 then return r end
    if request then
        local ok2, r2 = pcall(function()
            local x = request({Url = url, Method = "GET"})
            return x and x.Body
        end)
        if ok2 and r2 and #r2 > 200 then return r2 end
    end
    return nil
end

local function boot()
    for _, url in ipairs(URLS) do
        print("[LOADER] Trying: " .. url)
        local src = fetch(url)
        if src then
            local fn, err = loadstring(src)
            if fn then
                local ok, runErr = pcall(fn)
                if ok then
                    print("[LOADER] Loaded OK")
                    return
                else
                    print("[LOADER] Runtime error: " .. tostring(runErr))
                end
            else
                print("[LOADER] Compile error: " .. tostring(err))
            end
        end
    end
    print("[LOADER] All sources failed")
end

boot()
