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
--// CALLBACK BUTTON
--// =========================
local function onButton(btn)
    if btn == "Skip" then
        _G.SKIP = true
    elseif btn == "Stop" then
        _G.STOP = true
    end
end

--// =========================
--// NOTIFY
--// =========================
local function notify(text)
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
--// SERVER LIST (ƯU TIÊN ĐÔNG)
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
local SCRIPT_URL = "https://pastebin.com/raw/your_script_here"

local function queueScript()
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
local function countdown(label)
    for i = COUNTDOWN, 1, -1 do
        if _G.STOP then return false end

        if _G.SKIP then
            _G.SKIP = false
            return true
        end

        notify(label.." - You Have "..i.."s")
        task.wait(1)
    end
    return true
end

--// =========================
--// JOIN SERVER
--// =========================
local function tryJoin()
    local servers = getServers()

    for _, server in pairs(servers) do
        if _G.STOP then return end

        print("Trying:", server.id, "Players:", server.playing)

        local success = pcall(function()
            queueScript()
            TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
        end)

        if success then
            return
        else
            warn("Fail -> next")
            task.wait(2)
        end
    end
end

--// =========================
--// MAIN LOOP
--// =========================
task.spawn(function()
    while not _G.STOP do
        task.wait(CHECK_DELAY)

        local ping = getPing()
        print("Ping:", ping)

        if ping > TARGET[2] then
            notify("Ping High -> Preparing Hop")

            local go = countdown("Hop")
            if go then
                tryJoin()
                return
            end
        else
            notify("Good Ping 😎")
        end
    end

    notify("Stopped.")
end)

--// =========================
--// SAU KHI JOIN (AUTO LOOP TIẾP)
--// =========================
task.spawn(function()
    task.wait(3)

    if not _G.STOP then
        countdown("Next Check")
    end
end)
