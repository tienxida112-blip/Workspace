--// =========================
--// CONFIG
--// =========================
local TARGET = _G.Targetping or {0, 120}
local COUNTDOWN = 10
local CHECK_DELAY = 5

_G.STOP = false
_G.SKIP = false

--// =========================
--// SERVICES
--// =========================
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

--// =========================
--// CALLBACK
--// =========================
local function onButton(btn)
    if btn == "Skip" then
        _G.SKIP = true
    elseif btn == "Stop" then
        _G.STOP = true
    end
end

--// =========================
--// NOTIFY (FIX TRÙNG)
--// =========================
local function notify(text)
    if _G.STOP then return end

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Server Hop",
            Text = text,
            Duration = 1,
            Button1 = "Skip",
            Button2 = "Stop",
            Callback = onButton
        })
    end)
end

--// =========================
--// PING
--// =========================
local function getPing()
    local stats = game:GetService("Stats")
    local pingStat = stats.Network.ServerStatsItem["Data Ping"]
    return pingStat:GetValue()
end

--// =========================
--// SERVER LIST
--// =========================
local function getServers()
    local servers = {}
    local cursor = ""

    for i = 1, 3 do
        local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Desc&limit=100&cursor="..cursor
        local body = game:HttpGet(url)
        local data = HttpService:JSONDecode(body)

        for _, v in pairs(data.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                table.insert(servers, v)
            end
        end

        cursor = data.nextPageCursor
        if not cursor then break end
    end

    return servers
end

--// =========================
--// QUEUE TELEPORT
--// =========================
local function queueScript()
    if _G.STOP then return end

    local code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/tienxida112-blip/Workspace/refs/heads/main/sever_hop.luau"))()'

    if queue_on_teleport then
        queue_on_teleport(code)
    elseif syn and syn.queue_on_teleport then
        syn.queue_on_teleport(code)
    end
end

--// =========================
--// COUNTDOWN
--// =========================
local function countdown()
    for i = COUNTDOWN, 1, -1 do
        if _G.STOP then return false end

        if _G.SKIP then
            _G.SKIP = false
            return true
        end

        notify("You Have "..i.."s")
        task.wait(1)
    end
    return true
end

--// =========================
--// JOIN SERVER (FIX RETRY)
--// =========================
local function tryJoin()
    local servers = getServers()

    for _, server in pairs(servers) do
        if _G.STOP then return end

        print("Trying:", server.id)

        queueScript()
        TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)

        -- 🔴 CHỜ XEM CÓ TELEPORT KHÔNG
        local t = 0
        while t < 8 do
            if _G.STOP then return end
            task.wait(1)
            t += 1
        end

        warn("Teleport có thể fail -> thử server khác")
    end
end

--// =========================
--// MAIN LOOP (FIX TRÙNG)
--// =========================
task.spawn(function()
    local lastState = nil

    while true do
        if _G.STOP then break end

        task.wait(CHECK_DELAY)
        if _G.STOP then break end

        local ping = getPing()
        print("Ping:", ping)

        local state = (ping > TARGET[2]) and "BAD" or "GOOD"

        if state ~= lastState then
            lastState = state

            if state == "GOOD" then
                notify("Good Ping 😎")
            else
                notify("Ping High -> Hop Soon")
            end
        end

        if state == "BAD" then
            local go = countdown()
            if go and not _G.STOP then
                tryJoin()
                return
            end
        end
    end

    notify("Stopped.")
end)
