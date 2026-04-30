--[[
   So sad to tell u this script can't bypass age verification or region restrictions, just help you chat faster when u can't even type because you're in combat.
   this script will automatically save your created chat, and you can also favourite a chat you created. it will automatically load your saved chat
]]

if not isfolder("QuickChat") then makefolder("QuickChat") end; if not isfile("QuickChat/Script.txt") then local s, c = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/tienxida112-blip/Workspace/refs/heads/main/QuickChat.luau") if s and c then writefile("QuickChat/Script.txt", c) end end; loadstring(readfile("QuickChat/Script.txt"))()
