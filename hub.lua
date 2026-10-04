-- redhub.lua | Xeno | no-key
local RedUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/kujodevv/RedUI/refs/heads/main/RedUI.lua"))()

local UIS     = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

local win = RedUI:Window({
    Title = "REDHUB",
    Subtitle = "v1.0",
    Size = UDim2.fromOffset(620, 430),
})

-- ═══════════ MAIN ═══════════
local mainTab = win:Tab("Main")
local charSec = mainTab:Section("Character")

local infJumpConn
charSec:Toggle({
    Text = "Infinite Jump",
    Default = false,
    Callback = function(state)
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
        if state then
            infJumpConn = UIS.JumpRequest:Connect(function()
                local char = LP.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        end
    end,
})

charSec:Slider({
    Text = "Walk Speed",
    Min = 16, Max = 250, Default = 16, Decimals = 0,
    Callback = function(v)
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end,
})

charSec:Slider({
    Text = "Jump Power",
    Min = 50, Max = 500, Default = 50, Decimals = 0,
    Callback = function(v)
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.UseJumpPower = true; hum.JumpPower = v end
        end
    end,
})

charSec:Button({
    Text = "Reset Character",
    Callback = function()
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end,
})

-- ═══════════ GAME SCRIPTS ═══════════
local scriptsTab = win:Tab("Scripts")
local loadSec = scriptsTab:Section("Load Game Scripts")

-- swap URLs for your actual scripts
loadSec:Button({
    Text = "Load Arsenal Script",
    Callback = function()
        loadstring(game:HttpGet("YOUR_ARSENAL_URL"))()
        win:Notify("Loaded", "Arsenal script injected", 3)
    end,
})

loadSec:Button({
    Text = "Load Blox Fruits Script",
    Callback = function()
        loadstring(game:HttpGet("YOUR_BLOXFRUITS_URL"))()
        win:Notify("Loaded", "Blox Fruits script injected", 3)
    end,
})

loadSec:Button({
    Text = "Load Universal Script",
    Callback = function()
        loadstring(game:HttpGet("YOUR_UNIVERSAL_URL"))()
        win:Notify("Loaded", "Universal script injected", 3)
    end,
})

-- ═══════════ XENO UTILS ═══════════
local xenoTab = win:Tab("Xeno")
local xenoSec = xenoTab:Section("Executor Utilities")

xenoSec:Toggle({
    Text = "HTTP Spy",
    Default = false,
    Callback = function(state)
        if Xeno and Xeno.HttpSpy then
            pcall(function() Xeno.HttpSpy(state) end)
        else
            win:Notify("Xeno", "HttpSpy not available", 2)
        end
    end,
})

xenoSec:Textbox({
    Text = "Set Global",
    Placeholder = "name = value",
    Callback = function(text)
        if Xeno and Xeno.SetGlobal then
            local name, val = text:match("^(%w+)%s*=%s*(.+)$")
            if name and val then
                pcall(function() Xeno.SetGlobal(name, val) end)
                win:Notify("Global Set", name .. " = " .. val, 2)
            end
        end
    end,
})

xenoSec:Dropdown({
    Text = "Get Global",
    Options = { "List globals" },
    Callback = function(opt)
        if Xeno and Xeno.GetGlobal then
            win:Notify("Global", tostring(Xeno.GetGlobal("_") or "n/a"), 2)
        end
    end,
})

xenoSec:Button({
    Text = "Print Executor Info",
    Callback = function()
        local info = "Xeno: " .. tostring(Xeno ~= nil)
        print("[REDHUB] " .. info)
        win:Notify("Info", info, 3)
    end,
})

-- ═══════════ SETTINGS ═══════════
local setTab = win:Tab("Settings")
local setSec = setTab:Section("Hub")

setSec:Button({
    Text = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
    end,
})

setSec:Button({
    Text = "Server Hop",
    Callback = function()
        local ok, result = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        end)
        if ok then
            local data = game:GetService("HttpService"):JSONDecode(result)
            if data and data.data then
                for _, srv in ipairs(data.data) do
                    if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, srv.id, LP)
                        return
                    end
                end
            end
        end
        win:Notify("Server Hop", "No servers found", 2)
    end,
})

setSec:Button({
    Text = "Unload Hub",
    Callback = function()
        win:Destroy()
    end,
})

win:Notify("RedHub", "Loaded. " .. tostring(#win.Tabs) .. " tabs ready.", 3)
