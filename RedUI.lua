-- RedUI — custom hub UI framework
-- Xeno-compatible | no dependencies | no keys
-- v1.0

local RedUI = {}

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local LP               = Players.LocalPlayer

-- ═══════════ THEME ═══════════
local T = {
    bg        = Color3.fromRGB(12, 12, 14),
    panel     = Color3.fromRGB(18, 18, 21),
    panelAlt  = Color3.fromRGB(24, 24, 28),
    hover     = Color3.fromRGB(34, 34, 39),
    accent    = Color3.fromRGB(220, 30, 40),
    accentHov = Color3.fromRGB(240, 55, 65),
    text      = Color3.fromRGB(232, 232, 236),
    textDim   = Color3.fromRGB(125, 125, 132),
    textMuted = Color3.fromRGB(80, 80, 88),
    outline   = Color3.fromRGB(38, 38, 44),
    track     = Color3.fromRGB(40, 40, 46),
}
RedUI.Theme = T

local FONT      = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_SEMI = Enum.Font.GothamSemibold

local TWEEN      = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_FAST = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ═══════════ HELPERS ═══════════
local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(p, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 6)}, p) end

local function stroke(p, c, t, tr)
    return new("UIStroke", {
        Color = c or T.outline, Thickness = t or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, p)
end

local function padding(p, all)
    return new("UIPadding", {
        PaddingTop = UDim.new(0, all), PaddingBottom = UDim.new(0, all),
        PaddingLeft = UDim.new(0, all), PaddingRight = UDim.new(0, all),
    }, p)
end

local function listLayout(p, o)
    o = o or {}
    return new("UIListLayout", {
        FillDirection       = o.FillDirection or Enum.FillDirection.Vertical,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Padding             = o.Padding or UDim.new(0, 4),
        HorizontalAlignment = o.HorizontalAlignment or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = o.VerticalAlignment or Enum.VerticalAlignment.Top,
    }, p)
end

-- ═══════════ GUI ACQUISITION ═══════════
local function acquireGui()
    if getgenv and getgenv().RedUI_Gui then
        pcall(function() getgenv().RedUI_Gui:Destroy() end)
    end
    local gui = new("ScreenGui", {
        Name = "RedUI_" .. math.random(1, 1e6),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    local ok = pcall(function()
        if gethui then
            gui.Parent = gethui()
        elseif syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        else
            gui.Parent = CoreGui
        end
    end)
    if not ok or not gui.Parent then
        gui.Parent = LP:WaitForChild("PlayerGui")
    end
    if getgenv then getgenv().RedUI_Gui = gui end
    return gui
end

-- ═══════════ NOTIFICATIONS ═══════════
local notifyHolder
local notifyY = 0

local function notify(title, body, duration)
    if not notifyHolder then return end
    duration = duration or 4
    local card = new("Frame", {
        Parent = notifyHolder,
        BackgroundColor3 = T.panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 56),
        Position = UDim2.new(0, 0, 0, notifyY),
    })
    corner(card, 6)
    stroke(card, T.outline, 1, 0.3)
    new("Frame", {
        Parent = card, BackgroundColor3 = T.accent, BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -12), Position = UDim2.new(0, 6, 0, 6),
    })
    new("TextLabel", {
        Parent = card, BackgroundTransparency = 1, Text = title,
        Font = FONT_SEMI, TextSize = 12, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(1, -24, 0, 16),
    })
    new("TextLabel", {
        Parent = card, BackgroundTransparency = 1, Text = body or "",
        Font = FONT, TextSize = 11, TextColor3 = T.textDim,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
        Position = UDim2.new(0, 16, 0, 26), Size = UDim2.new(1, -24, 1, -32),
    })
    local scale = new("UIScale", {Scale = 0.85}, card)
    TweenService:Create(scale, TWEEN, {Scale = 1}):Play()

    notifyY = notifyY + 62
    task.delay(duration, function()
        local out = TweenService:Create(card, TWEEN, {BackgroundTransparency = 1})
        local ks  = TweenService:Create(scale, TWEEN, {Scale = 0.85})
        out:Play(); ks:Play()
        out.Completed:Connect(function()
            card:Destroy()
            notifyY = 0
            for _, c in ipairs(notifyHolder:GetChildren()) do
                if c:IsA("Frame") then
                    TweenService:Create(c, TWEEN, {Position = UDim2.new(0, 0, 0, notifyY)}):Play()
                    notifyY = notifyY + 62
                end
            end
        end)
    end)
end

RedUI.Notify = notify

-- ═══════════ COMPONENTS ═══════════
local openDropdown
local function closeOpenDropdown()
    if openDropdown then openDropdown.close(); openDropdown = nil end
end

local function makeLabel(parent, cfg)
    cfg = cfg or {}
    return new("TextLabel", {
        Parent = parent, BackgroundTransparency = 1,
        Text = cfg.Text or "Label", Font = FONT, TextSize = 12,
        TextColor3 = cfg.Color or T.textDim,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 18),
    })
end

local function makeDivider(parent)
    return new("Frame", {
        Parent = parent, BackgroundColor3 = T.outline,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1),
    })
end

local function makeButton(parent, cfg)
    cfg = cfg or {}
    local btn = new("TextButton", {
        Parent = parent, BackgroundColor3 = T.panelAlt,
        BorderSizePixel = 0, Text = "",
        Size = UDim2.new(1, 0, 0, 30), AutoButtonColor = false,
    })
    corner(btn, 5); stroke(btn, T.outline, 1, 0.4)
    new("TextLabel", {
        Parent = btn, BackgroundTransparency = 1,
        Text = cfg.Text or "Button", Font = FONT, TextSize = 12,
        TextColor3 = T.text, Size = UDim2.new(1, 0, 1, 0),
    })
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TWEEN_FAST, {BackgroundColor3 = T.hover}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TWEEN_FAST, {BackgroundColor3 = T.panelAlt}):Play() end)
    btn.MouseButton1Click:Connect(function()
        if cfg.Callback then
            local ok, err = pcall(cfg.Callback)
            if not ok then warn("[RedUI] " .. tostring(err)) end
        end
    end)
    local obj = {}
    function obj:SetText(t) btn:FindFirstChildOfClass("TextLabel").Text = t end
    return obj
end

local function makeToggle(parent, cfg)
    cfg = cfg or {}
    local state = cfg.Default == true
    local row = new("Frame", {
        Parent = parent, BackgroundColor3 = T.panelAlt,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 30),
    })
    corner(row, 5); stroke(row, T.outline, 1, 0.4)
    new("TextLabel", {
        Parent = row, BackgroundTransparency = 1,
        Text = cfg.Text or "Toggle", Font = FONT, TextSize = 12,
        TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.7, 0, 1, 0),
    })
    local switch = new("Frame", {
        Parent = row, BackgroundColor3 = state and T.accent or T.track,
        BorderSizePixel = 0, Size = UDim2.new(0, 32, 0, 16),
        Position = UDim2.new(1, -42, 0.5, -8),
    })
    corner(switch, 8)
    local knob = new("Frame", {
        Parent = switch, BackgroundColor3 = T.text, BorderSizePixel = 0,
        Size = UDim2.new(0, 12, 0, 12),
        Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),
    })
    corner(knob, 6)
    local function refresh()
        if state then
            TweenService:Create(switch, TWEEN_FAST, {BackgroundColor3 = T.accent}):Play()
            TweenService:Create(knob, TWEEN_FAST, {Position = UDim2.new(1, -14, 0.5, -6)}):Play()
        else
            TweenService:Create(switch, TWEEN_FAST, {BackgroundColor3 = T.track}):Play()
            TweenService:Create(knob, TWEEN_FAST, {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
        end
    end
    new("TextButton", {
        Parent = row, BackgroundTransparency = 1, Text = "",
        Size = UDim2.new(1, 0, 1, 0),
    }).MouseButton1Click:Connect(function()
        state = not state; refresh()
        if cfg.Callback then
            local ok, err = pcall(cfg.Callback, state)
            if not ok then warn("[RedUI] " .. tostring(err)) end
        end
    end)
    local obj = {}
    function obj:Set(v) state = v and true or false; refresh(); if cfg.Callback then pcall(cfg.Callback, state) end end
    function obj:Get() return state end
    return obj
end

local function makeSlider(parent, cfg)
    cfg = cfg or {}
    local min      = cfg.Min or 0
    local max      = cfg.Max or 100
    local decimals = cfg.Decimals or 0
    local value    = cfg.Default or min
    local row = new("Frame", {
        Parent = parent, BackgroundColor3 = T.panelAlt,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 46),
    })
    corner(row, 5); stroke(row, T.outline, 1, 0.4)
    new("TextLabel", {
        Parent = row, BackgroundTransparency = 1,
        Text = cfg.Text or "Slider", Font = FONT, TextSize = 12,
        TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(0.7, 0, 0, 18),
    })
    local valLbl = new("TextLabel", {
        Parent = row, BackgroundTransparency = 1, Text = tostring(value),
        Font = FONT_SEMI, TextSize = 12, TextColor3 = T.accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(0.7, 0, 0, 4), Size = UDim2.new(0.3, -10, 0, 18),
    })
    local track = new("Frame", {
        Parent = row, BackgroundColor3 = T.track, BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 1, -16), Size = UDim2.new(1, -20, 0, 5),
    })
    corner(track, 3)
    local fill = new("Frame", {
        Parent = track, BackgroundColor3 = T.accent, BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
    })
    corner(fill, 3)
    local knob = new("Frame", {
        Parent = track, BackgroundColor3 = T.text, BorderSizePixel = 0,
        Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0, 0, 0.5, -6),
    })
    corner(knob, 6)
    local hit = new("TextButton", {
        Parent = row, BackgroundTransparency = 1, Text = "",
        Position = UDim2.new(0, 10, 1, -22), Size = UDim2.new(1, -20, 0, 22),
    })
    local function setVal(v, fire)
        v = math.clamp(v, min, max)
        value = tonumber(string.format("%." .. decimals .. "f", v))
        valLbl.Text = tostring(value)
        local a = (value - min) / (max - min)
        TweenService:Create(fill, TWEEN_FAST, {Size = UDim2.new(a, 0, 1, 0)}):Play()
        knob.Position = UDim2.new(a, 0, 0.5, -6)
        if fire and cfg.Callback then pcall(cfg.Callback, value) end
    end
    local dragging = false
    local function fromInput(input)
        local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
        setVal(min + math.clamp(rel, 0, 1) * (max - min), true)
    end
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; fromInput(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            fromInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    setVal(value, false)
    local obj = {}
    function obj:Set(v) setVal(v, true) end
    function obj:Get() return value end
    return obj
end

local function makeDropdown(parent, cfg)
    cfg = cfg or {}
    local options = cfg.Options or {}
    local multi   = cfg.Multi or false
    local selected
    if multi then
        selected = {}
        if type(cfg.Default) == "table" then
            for _, v in ipairs(cfg.Default) do selected[v] = true end
        elseif cfg.Default then selected[cfg.Default] = true end
    else
        selected = cfg.Default or options[1]
    end
    local row = new("Frame", {
        Parent = parent, BackgroundColor3 = T.panelAlt,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 30),
    })
    corner(row, 5); stroke(row, T.outline, 1, 0.4)
    new("TextLabel", {
        Parent = row, BackgroundTransparency = 1,
        Text = cfg.Text or "Dropdown", Font = FONT, TextSize = 12,
        TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
    })
    local display = new("TextLabel", {
        Parent = row, BackgroundTransparency = 1, Text = "",
        Font = FONT, TextSize = 11, TextColor3 = T.textDim,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -10, 1, 0),
    })
    local optFrames = {}
    local listFrame, shield
    local function updateDisplay()
        if multi then
            local n = 0
            for _ in pairs(selected) do n = n + 1 end
            display.Text = n > 0 and (n .. " selected") or "None"
        else
            display.Text = tostring(selected or "Select...")
        end
    end
    local function refreshChecks()
        for opt, frame in pairs(optFrames) do
            local chk = frame:FindFirstChild("Check")
            if chk then
                chk.Visible = (multi and selected[opt] == true) or ((not multi) and selected == opt)
            end
        end
    end
    local function closeList()
        if listFrame then listFrame:Destroy(); listFrame = nil end
        if shield then shield:Destroy(); shield = nil end
        if openDropdown and openDropdown.owner == row then openDropdown = nil end
    end
    local function openList()
        closeOpenDropdown()
        local pGui = row:FindFirstAncestorWhichIsA("ScreenGui")
        shield = new("TextButton", {
            Parent = pGui, BackgroundTransparency = 1, Text = "",
            Size = UDim2.new(1, 0, 1, 0), ZIndex = 100,
        })
        shield.MouseButton1Click:Connect(closeList)
        local count = #options
        local h = math.min(count, 6) * 24 + 8
        listFrame = new("Frame", {
            Parent = pGui, BackgroundColor3 = T.panel, BorderSizePixel = 0,
            Position = UDim2.new(0, row.AbsolutePosition.X, 0, row.AbsolutePosition.Y + row.AbsoluteSize.Y + 4),
            Size = UDim2.new(0, row.AbsoluteSize.X, 0, h), ZIndex = 101,
        })
        corner(listFrame, 5); stroke(listFrame, T.outline, 1, 0)
        local sf = new("ScrollingFrame", {
            Parent = listFrame, BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, count * 24 + 8),
            ScrollBarThickness = 3, ScrollBarImageColor3 = T.outline,
            ScrollBarImageTransparency = 0.3,
        })
        padding(sf, 4); listLayout(sf, {Padding = UDim.new(0, 2)})
        for i, opt in ipairs(options) do
            local optBtn = new("TextButton", {
                Parent = sf, Name = "Opt" .. i,
                BackgroundColor3 = T.panelAlt, BorderSizePixel = 0,
                Text = "", Size = UDim2.new(1, -6, 0, 22),
                AutoButtonColor = false, ZIndex = 102,
            })
            corner(optBtn, 4)
            new("TextLabel", {
                Parent = optBtn, BackgroundTransparency = 1, Text = opt,
                Font = FONT, TextSize = 12, TextColor3 = T.text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -8, 1, 0), ZIndex = 103,
            })
            new("TextLabel", {
                Parent = optBtn, Name = "Check", BackgroundTransparency = 1,
                Text = "✓", Font = FONT_BOLD, TextSize = 12, TextColor3 = T.accent,
                TextXAlignment = Enum.TextXAlignment.Right,
                Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, -8, 1, 0),
                Visible = false, ZIndex = 103,
            })
            optFrames[opt] = optBtn
            optBtn.MouseEnter:Connect(function() TweenService:Create(optBtn, TWEEN_FAST, {BackgroundColor3 = T.hover}):Play() end)
            optBtn.MouseLeave:Connect(function() TweenService:Create(optBtn, TWEEN_FAST, {BackgroundColor3 = T.panelAlt}):Play() end)
            optBtn.MouseButton1Click:Connect(function()
                if multi then
                    selected[opt] = (not selected[opt]) or nil
                    updateDisplay(); refreshChecks()
                    if cfg.Callback then pcall(cfg.Callback, selected) end
                else
                    selected = opt
                    updateDisplay(); closeList()
                    if cfg.Callback then pcall(cfg.Callback, selected) end
                end
            end)
        end
        refreshChecks()
        openDropdown = {owner = row, close = closeList}
    end
    new("TextButton", {
        Parent = row, BackgroundTransparency = 1, Text = "",
        Size = UDim2.new(1, 0, 1, 0),
    }).MouseButton1Click:Connect(function()
        if listFrame then closeList() else openList() end
    end)
    updateDisplay()
    local obj = {}
    function obj:Set(v)
        if multi then
            selected = {}
            if type(v) == "table" then for _, x in ipairs(v) do selected[x] = true end end
        else selected = v end
        updateDisplay(); refreshChecks()
    end
    function obj:Get() return selected end
    return obj
end

local function makeTextbox(parent, cfg)
    cfg = cfg or {}
    local row = new("Frame", {
        Parent = parent, BackgroundColor3 = T.panelAlt,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 48),
    })
    corner(row, 5); stroke(row, T.outline, 1, 0.4)
    new("TextLabel", {
        Parent = row, BackgroundTransparency = 1,
        Text = cfg.Text or "Input", Font = FONT, TextSize = 12,
        TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -20, 0, 18),
    })
    local box = new("TextBox", {
        Parent = row, BackgroundColor3 = T.bg, BorderSizePixel = 0,
        Text = cfg.Default or "", PlaceholderText = cfg.Placeholder or "Type...",
        PlaceholderColor3 = T.textMuted, Font = FONT, TextSize = 12,
        TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Position = UDim2.new(0, 10, 0, 26), Size = UDim2.new(1, -20, 0, 18),
    })
    corner(box, 4)
    local boxStroke = stroke(box, T.outline, 1, 0.5)
    box.Focused:Connect(function()
        TweenService:Create(box, TWEEN_FAST, {BackgroundColor3 = T.panel}):Play()
        TweenService:Create(boxStroke, TWEEN_FAST, {Color = T.accent}):Play()
    end)
    box.FocusLost:Connect(function(enter)
        TweenService:Create(box, TWEEN_FAST, {BackgroundColor3 = T.bg}):Play()
        TweenService:Create(boxStroke, TWEEN_FAST, {Color = T.outline}):Play()
        if cfg.Callback then
            local ok, err = pcall(cfg.Callback, box.Text, enter)
            if not ok then warn("[RedUI] " .. tostring(err)) end
        end
    end)
    local obj = {}
    function obj:Set(v) box.Text = v end
    function obj:Get() return box.Text end
    return obj
end

-- ═══════════ SECTION / TAB / WINDOW ═══════════
local function makeSection(parent, name)
    local section = new("Frame", {
        Parent = parent, BackgroundColor3 = T.panel,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    corner(section, 6); stroke(section, T.outline, 1, 0.35)

    local header = new("Frame", {
        Parent = section, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
    })
    padding(header, 10)
    new("TextLabel", {
        Parent = header, BackgroundTransparency = 1, Text = name,
        Font = FONT_SEMI, TextSize = 12, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 1, 0),
    })
    new("Frame", {
        Parent = section, BackgroundColor3 = T.outline, BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, 1), Position = UDim2.new(0, 10, 0, 30),
    })
    local body = new("Frame", {
        Parent = section, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 31),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    padding(body, 8); listLayout(body, {Padding = UDim.new(0, 4)})

    local obj = {}
    function obj:Button(c)  return makeButton(body, c)   end
    function obj:Toggle(c)  return makeToggle(body, c)   end
    function obj:Slider(c)  return makeSlider(body, c)   end
    function obj:Dropdown(c) return makeDropdown(body, c) end
    function obj:Textbox(c) return makeTextbox(body, c)  end
    function obj:Label(c)   return makeLabel(body, c)    end
    function obj:Divider()  return makeDivider(body)     end
    return obj
end

function RedUI:Window(cfg)
    cfg = cfg or {}
    local title    = cfg.Title or "RedUI"
    local subtitle = cfg.Subtitle or "v1.0"
    local size     = cfg.Size or UDim2.fromOffset(600, 420)
    local gui      = acquireGui()

    notifyHolder = new("Frame", {
        Parent = gui, BackgroundTransparency = 1,
        Position = UDim2.new(1, -12, 0, 12),
        Size = UDim2.new(0, 280, 1, -24),
        AnchorPoint = Vector2.new(1, 0),
    })

    local win = new("Frame", {
        Parent = gui, BackgroundColor3 = T.bg, BorderSizePixel = 0,
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2),
        ClipsDescendants = true,
    })
    corner(win, 8); stroke(win, T.outline, 1, 0.1)

    -- title bar
    local titleBar = new("Frame", {
        Parent = win, BackgroundColor3 = T.panel, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
    })
    new("Frame", {
        Parent = titleBar, BackgroundColor3 = T.outline, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
    })
    local titleRow = new("Frame", {
        Parent = titleBar, BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(0.6, 0, 1, 0),
    })
    listLayout(titleRow, {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center})
    new("TextLabel", {
        Parent = titleRow, BackgroundTransparency = 1, Text = title,
        Font = FONT_BOLD, TextSize = 14, TextColor3 = T.text,
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
    })
    new("TextLabel", {
        Parent = titleRow, BackgroundTransparency = 1, Text = subtitle,
        Font = FONT, TextSize = 11, TextColor3 = T.textDim,
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
    })

    local closeBtn = new("TextButton", {
        Parent = titleBar, BackgroundTransparency = 1, Text = "×",
        Font = FONT_BOLD, TextSize = 18, TextColor3 = T.textDim,
        Position = UDim2.new(1, -32, 0, 0), Size = UDim2.new(0, 32, 1, 0),
        AutoButtonColor = false,
    })
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = T.accent end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = T.textDim end)
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

    local minBtn = new("TextButton", {
        Parent = titleBar, BackgroundTransparency = 1, Text = "—",
        Font = FONT_BOLD, TextSize = 16, TextColor3 = T.textDim,
        Position = UDim2.new(1, -64, 0, 0), Size = UDim2.new(0, 32, 1, 0),
        AutoButtonColor = false,
    })
    minBtn.MouseEnter:Connect(function() minBtn.TextColor3 = T.text end)
    minBtn.MouseLeave:Connect(function() minBtn.TextColor3 = T.textDim end)

    -- drag
    local dragging, dragInput, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local d = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    -- minimize
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        for _, c in ipairs(win:GetChildren()) do
            if c ~= titleBar then c.Visible = not minimized end
        end
        TweenService:Create(win, TWEEN, {
            Size = minimized and UDim2.new(size.X.Scale, size.X.Offset, 0, 36) or size,
        }):Play()
    end)

    -- sidebar + content
    local sidebar = new("Frame", {
        Parent = win, BackgroundColor3 = T.panel, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 36), Size = UDim2.new(0, 150, 1, -36),
    })
    new("Frame", {
        Parent = sidebar, BackgroundColor3 = T.outline, BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
    })
    local tabHolder = new("Frame", {
        Parent = sidebar, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 8), Size = UDim2.new(1, 0, 1, -16),
    })
    padding(tabHolder, 6); listLayout(tabHolder, {Padding = UDim.new(0, 2)})

    local content = new("Frame", {
        Parent = win, BackgroundColor3 = T.bg, BorderSizePixel = 0,
        Position = UDim2.new(0, 150, 0, 36), Size = UDim2.new(1, -150, 1, -36),
    })

    local tabs, activeTab = {}, nil
    local winObj = {Gui = gui, Frame = win, Tabs = tabs}

    function winObj:Tab(name)
        local btn = new("TextButton", {
            Parent = tabHolder, BackgroundColor3 = T.panel,
            BorderSizePixel = 0, Text = "", Size = UDim2.new(1, 0, 0, 30),
            AutoButtonColor = false,
        })
        corner(btn, 5)
        local indicator = new("Frame", {
            Parent = btn, BackgroundColor3 = T.accent, BorderSizePixel = 0,
            Size = UDim2.new(0, 3, 0.5, 0), Position = UDim2.new(0, 0, 0.25, 0),
            Visible = false,
        })
        corner(indicator, 2)
        local lbl = new("TextLabel", {
            Parent = btn, BackgroundTransparency = 1, Text = name,
            Font = FONT, TextSize = 12, TextColor3 = T.textDim,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -12, 1, 0),
        })
        local page = new("ScrollingFrame", {
            Parent = content, BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3, ScrollBarImageColor3 = T.outline,
            ScrollBarImageTransparency = 0.3, Visible = false,
        })
        padding(page, 12); listLayout(page, {Padding = UDim.new(0, 8)})

        local tabObj = {Button = btn, Page = page, Indicator = indicator, Label = lbl}
        local function activate()
            if activeTab then
                activeTab.Page.Visible = false
                activeTab.Indicator.Visible = false
                TweenService:Create(activeTab.Button, TWEEN, {BackgroundColor3 = T.panel}):Play()
                TweenService:Create(activeTab.Label, TWEEN, {TextColor3 = T.textDim}):Play()
            end
            activeTab = tabObj
            page.Visible = true
            indicator.Visible = true
            TweenService:Create(btn, TWEEN, {BackgroundColor3 = T.hover}):Play()
            TweenService:Create(lbl, TWEEN, {TextColor3 = T.text}):Play()
        end
        btn.MouseEnter:Connect(function()
            if activeTab ~= tabObj then TweenService:Create(btn, TWEEN_FAST, {BackgroundColor3 = T.panelAlt}):Play() end
        end)
        btn.MouseLeave:Connect(function()
            if activeTab ~= tabObj then TweenService:Create(btn, TWEEN_FAST, {BackgroundColor3 = T.panel}):Play() end
        end)
        btn.MouseButton1Click:Connect(activate)

        function tabObj:Section(n) return makeSection(page, n) end
        tabs[name] = tabObj
        if not activeTab then activate() end
        return tabObj
    end

    function winObj:Notify(t, b, d) return notify(t, b, d) end
    function winObj:Destroy() gui:Destroy() end
    return winObj
end

return RedUI
