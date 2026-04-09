local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- =========================================================
-- MULTI-EXECUTE SCHUTZ
-- =========================================================
local LOCK_KEY = "VentyLibrary_Active"

for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
    if gui:IsA("ScreenGui") and gui:FindFirstChild("__VentyLock") then
        gui:Destroy()
        task.wait(0.05)
    end
end

local Library = {
    Elements = {},
    ThemeObjects = {},
    Connections = {},
    Flags = {},
    Themes = {
        Default = {
            Main = Color3.fromRGB(8, 8, 10),
            Second = Color3.fromRGB(14, 14, 16),
            Stroke = Color3.fromRGB(30, 30, 35),
            Divider = Color3.fromRGB(20, 20, 22),
            Text = Color3.fromRGB(230, 230, 235),
            TextDark = Color3.fromRGB(160, 160, 165)
        }
    },
    SelectedTheme = "Default",
    Folder = nil,
    SaveCfg = false,
    Font = Enum.Font.Gotham
}

local TAB_HEIGHT = 36
local TAB_PADDING = 14

-- =========================================================
-- ScreenGui erstellen + Lock-Marker
-- =========================================================
local Container = Instance.new("ScreenGui")
Container.Name = string.char(math.random(65, 90))..tostring(math.random(100, 999))
Container.DisplayOrder = 2147483647
Container.ResetOnSpawn = false
Container.Parent = game:GetService("CoreGui")

local LockMarker = Instance.new("StringValue")
LockMarker.Name = "__VentyLock"
LockMarker.Value = "1"
LockMarker.Parent = Container

function Library:IsRunning()
    return Container and Container.Parent == game:GetService("CoreGui")
end

local function AddConnection(Signal, Function)
    if not Library:IsRunning() then return end
    local conn = Signal:Connect(Function)
    table.insert(Library.Connections, conn)
    return conn
end

task.spawn(function()
    while Library:IsRunning() do
        task.wait()
    end
    for _, c in next, Library.Connections do
        c:Disconnect()
    end
end)

-- =========================================================
-- Draggable / Resizable
-- =========================================================
local function MakeDraggable(DragPoint, Main)
    local IsResizing = false
    pcall(function()
        local Dragging, DragInput, MousePos, FramePos = false
        DragPoint.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                if not IsResizing then
                    Dragging = true
                    MousePos = Input.Position
                    FramePos = Main.Position
                end
                Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)
        DragPoint.InputChanged:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                DragInput = Input
            end
        end)
        UserInputService.InputChanged:Connect(function(Input)
            if Input == DragInput and Dragging and not IsResizing then
                local Delta = Input.Position - MousePos
                TweenService:Create(Main, TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
                }):Play()
            end
        end)
    end)
    return function(resizing)
        IsResizing = resizing
        if resizing then Dragging = false end
    end
end

local function MakeResizable(ResizeButton, Main, MinSize, MaxSize, SetResizingCallback)
    pcall(function()
        local Resizing = false
        local StartSize, StartPos
        ResizeButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Resizing = true
                if SetResizingCallback then SetResizingCallback(true) end
                StartSize = Main.Size
                StartPos = Vector2.new(Mouse.X, Mouse.Y)
            end
        end)
        ResizeButton.InputEnded:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Resizing = false
                if SetResizingCallback then SetResizingCallback(false) end
            end
        end)
        UserInputService.InputChanged:Connect(function()
            if Resizing then
                local CurrentPos = Vector2.new(Mouse.X, Mouse.Y)
                local Delta = CurrentPos - StartPos
                local NewWidth = math.clamp(StartSize.X.Offset + Delta.X, MinSize.X, MaxSize.X)
                local NewHeight = math.clamp(StartSize.Y.Offset + Delta.Y, MinSize.Y, MaxSize.Y)
                Main.Size = UDim2.new(0, NewWidth, 0, NewHeight)
            end
        end)
    end)
end

-- =========================================================
-- Element-Factory
-- =========================================================
local function Create(Name, Properties, Children)
    local Object = Instance.new(Name)
    for i, v in next, Properties or {} do Object[i] = v end
    for i, v in next, Children or {} do v.Parent = Object end
    return Object
end

local function CreateElement(ElementName, ElementFunction)
    Library.Elements[ElementName] = function(...) return ElementFunction(...) end
end

local function MakeElement(ElementName, ...)
    return Library.Elements[ElementName](...)
end

local function SetProps(Element, Props)
    table.foreach(Props, function(Property, Value) Element[Property] = Value end)
    return Element
end

local function SetChildren(Element, Children)
    table.foreach(Children, function(_, Child) Child.Parent = Element end)
    return Element
end

local function Round(Number, Factor)
    local Result = math.floor(Number/Factor + (math.sign(Number) * 0.5)) * Factor
    if Result < 0 then Result = Result + Factor end
    return Result
end

local function ReturnProperty(Object)
    if Object:IsA("Frame") or Object:IsA("TextButton") then return "BackgroundColor3" end
    if Object:IsA("ScrollingFrame") then return "ScrollBarImageColor3" end
    if Object:IsA("UIStroke") then return "Color" end
    if Object:IsA("TextLabel") or Object:IsA("TextBox") then return "TextColor3" end
    if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then return "ImageColor3" end
end

local function AddThemeObject(Object, Type)
    if not Library.ThemeObjects[Type] then Library.ThemeObjects[Type] = {} end
    table.insert(Library.ThemeObjects[Type], Object)
    Object[ReturnProperty(Object)] = Library.Themes[Library.SelectedTheme][Type]
    return Object
end

local function SetTheme()
    for Name, Type in pairs(Library.ThemeObjects) do
        for _, Object in pairs(Type) do
            Object[ReturnProperty(Object)] = Library.Themes[Library.SelectedTheme][Name]
        end
    end
end

local function PackColor(Color)
    return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end

local function UnpackColor(Color)
    return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadCfg(Config)
    local Data = game:GetService("HttpService"):JSONDecode(Config)
    table.foreach(Data, function(a, b)
        if Library.Flags[a] then
            spawn(function()
                if Library.Flags[a].Type == "Colorpicker" then
                    Library.Flags[a]:Set(UnpackColor(b))
                else
                    Library.Flags[a]:Set(b)
                end
            end)
        end
    end)
end

local function SaveCfg(Name)
    local Data = {}
    for i, v in pairs(Library.Flags) do
        if v.Save then
            if v.Type == "Colorpicker" then Data[i] = PackColor(v.Value)
            else Data[i] = v.Value end
        end
    end
end

local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3, Enum.UserInputType.Touch}
local BlacklistedKeys = {Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right, Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape}

local function CheckKey(Table, Key)
    for _, v in next, Table do if v == Key then return true end end
end

-- =========================================================
-- Element-Definitionen
-- =========================================================
CreateElement("Corner", function(Scale, Offset)
    return Create("UICorner", {CornerRadius = UDim.new(Scale or 0, Offset or 8)})
end)
CreateElement("Stroke", function(Color, Thickness)
    return Create("UIStroke", {Color = Color or Color3.fromRGB(255,255,255), Thickness = Thickness or 1})
end)
CreateElement("List", function(Scale, Offset)
    return Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(Scale or 0, Offset or 0)})
end)
CreateElement("Padding", function(Bottom, Left, Right, Top)
    return Create("UIPadding", {
        PaddingBottom = UDim.new(0, Bottom or 4),
        PaddingLeft   = UDim.new(0, Left or 4),
        PaddingRight  = UDim.new(0, Right or 4),
        PaddingTop    = UDim.new(0, Top or 4)
    })
end)
CreateElement("TFrame", function()
    return Create("Frame", {BackgroundTransparency = 1})
end)
CreateElement("Frame", function(Color)
    return Create("Frame", {BackgroundColor3 = Color or Color3.fromRGB(255,255,255), BorderSizePixel = 0})
end)
CreateElement("RoundFrame", function(Color, Scale, Offset)
    return Create("Frame", {BackgroundColor3 = Color or Color3.fromRGB(255,255,255), BorderSizePixel = 0}, {
        Create("UICorner", {CornerRadius = UDim.new(Scale, Offset)})
    })
end)
CreateElement("Button", function()
    return Create("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0})
end)
CreateElement("ScrollFrame", function(Color, Width)
    return Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        MidImage = "rbxassetid://7445543667",
        BottomImage = "rbxassetid://7445543667",
        TopImage = "rbxassetid://7445543667",
        ScrollBarImageColor3 = Color,
        BorderSizePixel = 0,
        ScrollBarThickness = Width,
        CanvasSize = UDim2.new(0,0,0,0)
    })
end)
CreateElement("Image", function(ImageID)
    return Create("ImageLabel", {Image = ImageID, BackgroundTransparency = 1})
end)
CreateElement("ImageButton", function(ImageID)
    return Create("ImageButton", {Image = ImageID, BackgroundTransparency = 1})
end)
CreateElement("Label", function(Text, TextSize, Transparency)
    return Create("TextLabel", {
        Text = Text or "",
        TextColor3 = Color3.fromRGB(240,240,240),
        TextTransparency = Transparency or 0,
        TextSize = TextSize or 15,
        Font = Enum.Font.GothamSemibold,
        RichText = true,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end)

-- =========================================================
-- Notification-System
-- =========================================================
local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
    SetProps(MakeElement("List"), {
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0,5)
    })
}), {
    Position = UDim2.new(1,-25,1,-25),
    Size = UDim2.new(0,300,1,-25),
    AnchorPoint = Vector2.new(1,1),
    Parent = Container
})

function Library:MakeNotification(NotificationConfig)
    spawn(function()
        NotificationConfig.Name    = NotificationConfig.Name    or "Notification"
        NotificationConfig.Content = NotificationConfig.Content or "Test"
        NotificationConfig.Image   = NotificationConfig.Image   or "rbxassetid://4384403532"
        NotificationConfig.Time    = NotificationConfig.Time    or 15

        local NotificationParent = SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y,
            Parent = NotificationHolder
        })
        local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(25,25,25),0,10), {
            Parent = NotificationParent, Size = UDim2.new(1,0,0,0),
            Position = UDim2.new(1,-55,0,0), BackgroundTransparency = 0, AutomaticSize = Enum.AutomaticSize.Y
        }), {
            MakeElement("Stroke", Color3.fromRGB(93,93,93), 1.2),
            MakeElement("Padding", 12,12,12,12),
            SetProps(MakeElement("Image", NotificationConfig.Image), {Size=UDim2.new(0,20,0,20), ImageColor3=Color3.fromRGB(240,240,240), Name="Icon"}),
            SetProps(MakeElement("Label", NotificationConfig.Name, 15), {Size=UDim2.new(1,-30,0,20), Position=UDim2.new(0,30,0,0), Font=Enum.Font.FredokaOne, Name="Title"}),
            SetProps(MakeElement("Label", NotificationConfig.Content, 14), {Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,25), Font=Enum.Font.FredokaOne, Name="Content", AutomaticSize=Enum.AutomaticSize.Y, TextColor3=Color3.fromRGB(220,220,220), TextWrapped=true})
        })
        TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position=UDim2.new(0,0,0,0)}):Play()
        wait(NotificationConfig.Time - 0.88)
        TweenService:Create(NotificationFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency=1}):Play()
        TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency=0.6}):Play()
        wait(0.3)
        TweenService:Create(NotificationFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency=0.9}):Play()
        TweenService:Create(NotificationFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency=0.4}):Play()
        TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency=0.5}):Play()
        wait(0.05)
        NotificationFrame:TweenPosition(UDim2.new(1,20,0,0),'In','Quint',0.8,true)
        wait(1.35)
        NotificationFrame:Destroy()
    end)
end

function Library:Init()
    if Library.SaveCfg then
        pcall(function()
            if isfile(Library.Folder.."/"..game.GameId..".txt") then
                LoadCfg(readfile(Library.Folder.."/"..game.GameId..".txt"))
                Library:MakeNotification({Name="Configuration", Content="Auto-loaded configuration for the game "..game.GameId..".", Time=5})
            end
        end)
    end
end

-- =========================================================
-- LADEBALKEN – KLEINES FENSTER (zentriert, kompakt)
-- =========================================================
local function ShowLoadingScreen(duration, callback)
    local Overlay = Create("Frame", {
        Parent = Container,
        Size = UDim2.new(1,0,1,0),
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        BackgroundTransparency = 0.45,
        ZIndex = 100,
        BorderSizePixel = 0
    })

    local LoadWindow = Create("Frame", {
        Parent = Container,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 300, 0, 130),
        BackgroundColor3 = Color3.fromRGB(10, 10, 13),
        BorderSizePixel = 0,
        ZIndex = 101,
        BackgroundTransparency = 1
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 12)}),
        Create("UIStroke", {Color = Color3.fromRGB(35, 35, 42), Thickness = 1.2})
    })

    local LogoImg = Create("ImageLabel", {
        Parent = LoadWindow,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 18),
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundTransparency = 1,
        Image = "rbxassetid://125829575723612",
        ImageTransparency = 1,
        ZIndex = 102
    })

    local LoadTitle = Create("TextLabel", {
        Parent = LoadWindow,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 48),
        Size = UDim2.new(1, -20, 0, 18),
        BackgroundTransparency = 1,
        Text = "Venty",
        TextColor3 = Color3.fromRGB(230, 230, 235),
        TextSize = 17,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTransparency = 1,
        ZIndex = 102
    })

    local LoadSub = Create("TextLabel", {
        Parent = LoadWindow,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 70),
        Size = UDim2.new(1, -20, 0, 13),
        BackgroundTransparency = 1,
        Text = "Initializing...",
        TextColor3 = Color3.fromRGB(100, 100, 115),
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTransparency = 1,
        ZIndex = 102
    })

    local BarBg = Create("Frame", {
        Parent = LoadWindow,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 90),
        Size = UDim2.new(1, -40, 0, 3),
        BackgroundColor3 = Color3.fromRGB(25, 25, 32),
        BorderSizePixel = 0,
        ZIndex = 102
    }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})

    local BarFill = Create("Frame", {
        Parent = BarBg,
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(60, 120, 255),
        BorderSizePixel = 0,
        ZIndex = 103
    }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})

    local PercLabel = Create("TextLabel", {
        Parent = LoadWindow,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 100),
        Size = UDim2.new(1, -40, 0, 13),
        BackgroundTransparency = 1,
        Text = "0%",
        TextColor3 = Color3.fromRGB(70, 70, 88),
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTransparency = 1,
        ZIndex = 102
    })

    TweenService:Create(LoadWindow, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
    task.wait(0.1)
    TweenService:Create(LogoImg,   TweenInfo.new(0.3, Enum.EasingStyle.Quint), {ImageTransparency = 0}):Play()
    TweenService:Create(LoadTitle, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
    task.wait(0.15)
    TweenService:Create(LoadSub,   TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
    TweenService:Create(PercLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
    task.wait(0.1)

    local steps = {"Checking environment...", "Loading modules...", "Applying settings...", "Ready!"}
    local stepDur = duration / #steps

    for i, stepText in ipairs(steps) do
        LoadSub.Text = stepText
        local targetScale = i / #steps
        TweenService:Create(BarFill, TweenInfo.new(stepDur * 0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(targetScale, 0, 1, 0)
        }):Play()
        local startPct = math.floor((i-1)/#steps * 100)
        local endPct   = math.floor(i/#steps * 100)
        local t0 = tick()
        while tick() - t0 < stepDur do
            local progress = math.clamp((tick()-t0)/stepDur, 0, 1)
            PercLabel.Text = math.floor(startPct + (endPct-startPct)*progress).."%"
            task.wait()
        end
        PercLabel.Text = endPct.."%"
    end

    task.wait(0.12)
    TweenService:Create(LoadWindow, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
    TweenService:Create(LogoImg,   TweenInfo.new(0.3, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
    TweenService:Create(LoadTitle, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
    TweenService:Create(LoadSub,   TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
    TweenService:Create(PercLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()
    TweenService:Create(BarBg,     TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
    TweenService:Create(BarFill,   TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
    TweenService:Create(Overlay,   TweenInfo.new(0.45, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
    task.wait(0.5)
    LoadWindow:Destroy()
    Overlay:Destroy()
    if callback then callback() end
end

-- =========================================================
-- MakeWindow
-- =========================================================
function Library:MakeWindow(WindowConfig)
    local FirstTab = true
    local Minimized = false
    local UIHidden = false

    WindowConfig = WindowConfig or {}
    WindowConfig.Name           = WindowConfig.Name           or "Venty"
    WindowConfig.ConfigFolder   = WindowConfig.ConfigFolder   or WindowConfig.Name
    WindowConfig.SaveConfig     = WindowConfig.SaveConfig     or false
    WindowConfig.HidePremium    = WindowConfig.HidePremium    or false
    WindowConfig.IntroEnabled   = (WindowConfig.IntroEnabled ~= nil) and WindowConfig.IntroEnabled or true
    WindowConfig.IntroToggleIcon= WindowConfig.IntroToggleIcon or "rbxassetid://125829575723612"
    WindowConfig.IntroText      = WindowConfig.IntroText      or "Launching Venty"
    WindowConfig.CloseCallback  = WindowConfig.CloseCallback  or function() end
    WindowConfig.LoadDuration   = WindowConfig.LoadDuration   or 2.5
    WindowConfig.BannerIcon     = WindowConfig.BannerIcon     or nil

    Library.Folder  = WindowConfig.ConfigFolder
    Library.SaveCfg = WindowConfig.SaveConfig

    if WindowConfig.SaveConfig then
        pcall(function()
            if not isfolder(WindowConfig.ConfigFolder) then makefolder(WindowConfig.ConfigFolder) end
        end)
    end

    -- -------------------------------------------------------
    -- TopBar-Elemente
    -- -------------------------------------------------------
    local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
        Size = UDim2.new(1,0,0,1),
        Position = UDim2.new(0,0,1,-1)
    }), "Stroke")

    -- Fenster-Name ZENTRIERT
    local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 16), {
        Size = UDim2.new(0,0,1,0),
        Position = UDim2.new(0.5,0,0,0),
        AnchorPoint = Vector2.new(0.5,0),
        Font = Enum.Font.GothamBlack,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Center,
        AutomaticSize = Enum.AutomaticSize.X
    }), "Text")

    -- Banner-Icon OBEN LINKS (nur wenn gesetzt)
    local BannerIconLabel = nil
    if WindowConfig.BannerIcon then
        BannerIconLabel = SetProps(MakeElement("Image", WindowConfig.BannerIcon), {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 12, 0.5, 0),
            Size = UDim2.new(0, 26, 0, 26),
            Name = "BannerIcon"
        })
    end

    -- -------------------------------------------------------
    -- Buttons: Resize | Minimize | Close  --> GANZ RECHTS
    -- -------------------------------------------------------
    local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0,32,1,0),
        Position = UDim2.new(0,76,0,0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.new(0.5,0,0.5,0),
            Size = UDim2.new(0,16,0,16)
        }), "Text")
    })

    local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0,32,1,0),
        Position = UDim2.new(0,38,0,0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.new(0.5,0,0.5,0),
            Size = UDim2.new(0,16,0,16),
            Name = "Ico"
        }), "Text")
    })

    local ResizeBtn = SetChildren(SetProps(MakeElement("Button"), {
        Size = UDim2.new(0,32,1,0),
        Position = UDim2.new(0,0,0,0),
        BackgroundTransparency = 1
    }), {
        AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://117273761878755"), {
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.new(0.5,0,0.5,0),
            Size = UDim2.new(0,16,0,16)
        }), "Text")
    })

    -- Container für alle 3 Buttons – GANZ RECHTS mit AnchorPoint (1, 0.5)
    local ButtonContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,6), {
        Size = UDim2.new(0,108,0,26),
        Position = UDim2.new(1,-8,0.5,0),
        AnchorPoint = Vector2.new(1,0.5)
    }), {
        AddThemeObject(MakeElement("Stroke"), "Stroke"),
        AddThemeObject(SetProps(MakeElement("Frame"), {Size=UDim2.new(0,1,1,0),Position=UDim2.new(0,36,0,0)}), "Stroke"),
        AddThemeObject(SetProps(MakeElement("Frame"), {Size=UDim2.new(0,1,1,0),Position=UDim2.new(0,72,0,0)}), "Stroke"),
        ResizeBtn,
        MinimizeBtn,
        CloseBtn
    }), "Second")

    local DragPoint = SetProps(MakeElement("TFrame"), {
        Size = UDim2.new(1,0,0,46)
    })

    -- -------------------------------------------------------
    -- TAB-LEISTE
    -- -------------------------------------------------------
    local TabBar = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255,255,255), 0), {
        Size = UDim2.new(1,0,0,TAB_HEIGHT),
        Position = UDim2.new(0,0,0,46),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.X,
        CanvasSize = UDim2.new(0,0,0,0),
        ElasticBehavior = Enum.ElasticBehavior.Never
    }), {
        SetProps(Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0,0),
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center
        }), {}),
        MakeElement("Padding", 0, 8, 8, 0)
    }), "Second")

    TabBar.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseWheel then
            local newPos = TabBar.CanvasPosition.X - (Input.Position.Z * 40)
            TabBar.CanvasPosition = Vector2.new(math.max(0, newPos), 0)
        end
    end)

    local TabBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
        Size = UDim2.new(1,0,0,1),
        Position = UDim2.new(0,0,0,46+TAB_HEIGHT)
    }), "Stroke")

    local ContentArea = AddThemeObject(SetProps(MakeElement("TFrame"), {
        Size = UDim2.new(1,0,1,-(46+TAB_HEIGHT+1)),
        Position = UDim2.new(0,0,0,46+TAB_HEIGHT+1)
    }), "Main")

    -- -------------------------------------------------------
    -- TopBar zusammenstellen
    -- -------------------------------------------------------
    local TopBarChildren = {
        WindowName,
        WindowTopBarLine,
        ButtonContainer,
    }

    if BannerIconLabel then
        table.insert(TopBarChildren, BannerIconLabel)
    end

    local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,255,255),0,10), {
        Parent = Container,
        Position = UDim2.new(0.5,-307,0.5,-172),
        Size = UDim2.new(0,615,0,344),
        ClipsDescendants = true,
        BackgroundTransparency = 0,
        Visible = false
    }), {
        SetChildren(SetProps(MakeElement("TFrame"), {
            Size = UDim2.new(1,0,0,46),
            Name = "TopBar",
            ClipsDescendants = false
        }), TopBarChildren),
        DragPoint,
        TabBar,
        TabBarLine,
        ContentArea
    }), "Main")

    local SetResizingCallback = MakeDraggable(DragPoint, MainWindow)
    MakeResizable(ResizeBtn, MainWindow, Vector2.new(400,260), Vector2.new(1200,800), SetResizingCallback)

    local MobileReopenButton = SetChildren(SetProps(MakeElement("Button"), {
        Parent = Container, Size = UDim2.new(0,40,0,40),
        Position = UDim2.new(0.5,-20,0,20),
        BackgroundColor3 = Library.Themes[Library.SelectedTheme].Main,
        Visible = false
    }), {
        AddThemeObject(SetProps(MakeElement("Image", WindowConfig.IntroToggleIcon), {
            AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0.5,0), Size = UDim2.new(0.7,0,0.7,0)
        }), "Text"),
        MakeElement("Corner", 1)
    })

    AddConnection(CloseBtn.MouseButton1Up, function()
        MainWindow.Visible = false
        if UserInputService.TouchEnabled then MobileReopenButton.Visible = true end
        UIHidden = true
        Library:MakeNotification({Name="Interface Hidden", Content="Press Left Control to reopen.", Time=4})
        WindowConfig.CloseCallback()
    end)
    AddConnection(UserInputService.InputBegan, function(Input)
        if Input.KeyCode == Enum.KeyCode.LeftControl and UIHidden then
            MainWindow.Visible = true
            MobileReopenButton.Visible = false
            UIHidden = false
        end
    end)
    AddConnection(MobileReopenButton.Activated, function()
        MainWindow.Visible = true
        MobileReopenButton.Visible = false
        UIHidden = false
    end)
    AddConnection(MinimizeBtn.MouseButton1Up, function()
        if Minimized then
            TweenService:Create(MainWindow, TweenInfo.new(0.5,Enum.EasingStyle.Quint,Enum.EasingDirection.Out), {Size=UDim2.new(0,615,0,344)}):Play()
            MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
            task.wait(0.02)
            MainWindow.ClipsDescendants = false
            TabBar.Visible = true
            TabBarLine.Visible = true
            ContentArea.Visible = true
            WindowTopBarLine.Visible = true
        else
            MainWindow.ClipsDescendants = true
            TabBar.Visible = false
            TabBarLine.Visible = false
            ContentArea.Visible = false
            WindowTopBarLine.Visible = false
            MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
            TweenService:Create(MainWindow, TweenInfo.new(0.5,Enum.EasingStyle.Quint,Enum.EasingDirection.Out), {Size=UDim2.new(0,WindowName.TextBounds.X+180,0,46)}):Play()
        end
        Minimized = not Minimized
    end)

    ShowLoadingScreen(WindowConfig.LoadDuration, function()
        MainWindow.Visible = true
    end)

    -- =========================================================
    -- TabFunction
    -- =========================================================
    local TabFunction = {}

    function TabFunction:MakeTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig.Name        = TabConfig.Name        or "Tab"
        TabConfig.Icon        = TabConfig.Icon        or ""
        TabConfig.PremiumOnly = TabConfig.PremiumOnly or false

        local TabBtn = AddThemeObject(SetChildren(SetProps(MakeElement("Button"), {
            Size = UDim2.new(0,100,1,0),
            AutomaticSize = Enum.AutomaticSize.X,
            Parent = TabBar,
            BackgroundTransparency = 1,
            ClipsDescendants = false
        }), {
            Create("Frame", {
                Name = "ActiveBar",
                Size = UDim2.new(1,-16,0,2),
                Position = UDim2.new(0,8,1,-2),
                AnchorPoint = Vector2.new(0,0),
                BackgroundColor3 = Color3.fromRGB(60,120,255),
                BorderSizePixel = 0,
                BackgroundTransparency = 1
            }, {Create("UICorner",{CornerRadius=UDim.new(1,0)})}),
            AddThemeObject(SetProps(MakeElement("Image", TabConfig.Icon), {
                AnchorPoint = Vector2.new(0,0.5),
                Size = UDim2.new(0,15,0,15),
                Position = UDim2.new(0,TAB_PADDING,0.5,0),
                ImageTransparency = 0.55,
                Name = "Ico"
            }), "Text"),
            AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 13), {
                AnchorPoint = Vector2.new(0,0.5),
                Size = UDim2.new(0,0,0,14),
                AutomaticSize = Enum.AutomaticSize.X,
                Position = UDim2.new(0, TAB_PADDING + (TabConfig.Icon ~= "" and 20 or 0), 0.5, 0),
                Font = Enum.Font.GothamSemibold,
                Name = "TabName",
                TextTransparency = 0.5
            }), "Text"),
            Create("UIPadding", {
                PaddingRight = UDim.new(0, TAB_PADDING)
            })
        }), "Second")

        task.defer(function()
            local layout = TabBar:FindFirstChildOfClass("UIListLayout")
            if layout then
                TabBar.CanvasSize = UDim2.new(0, layout.AbsoluteContentSize.X + 16, 0, 0)
                layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    TabBar.CanvasSize = UDim2.new(0, layout.AbsoluteContentSize.X + 16, 0, 0)
                end)
            end
        end)

        if TabConfig.Icon == "" then
            TabBtn.Ico.Size = UDim2.new(0,0,0,0)
            TabBtn.Ico.Visible = false
        end

        local ItemContainer = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255,255,255), 5), {
            Size = UDim2.new(1,0,1,0),
            Parent = ContentArea,
            Visible = false,
            Name = "ItemContainer"
        }), {
            MakeElement("List", 0, 6),
            MakeElement("Padding", 14, 12, 12, 14)
        }), "Divider")

        AddConnection(ItemContainer.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            ItemContainer.CanvasSize = UDim2.new(0,0,0, ItemContainer.UIListLayout.AbsoluteContentSize.Y + 28)
        end)

        local ClickSound = Instance.new("Sound")
        ClickSound.SoundId = "rbxassetid://6895079853"
        ClickSound.Volume = 0.8
        ClickSound.Parent = TabBtn

        local function ActivateTab()
            for _, tb in next, TabBar:GetChildren() do
                if tb:IsA("TextButton") then
                    pcall(function()
                        TweenService:Create(tb.Ico,     TweenInfo.new(0.22,Enum.EasingStyle.Quint), {ImageTransparency=0.55, ImageColor3=Library.Themes[Library.SelectedTheme].Text}):Play()
                        TweenService:Create(tb.TabName, TweenInfo.new(0.22,Enum.EasingStyle.Quint), {TextTransparency=0.5}):Play()
                        TweenService:Create(tb.ActiveBar, TweenInfo.new(0.22,Enum.EasingStyle.Quint), {BackgroundTransparency=1}):Play()
                        TweenService:Create(tb, TweenInfo.new(0.22,Enum.EasingStyle.Quint), {BackgroundTransparency=1}):Play()
                    end)
                end
            end
            for _, Cont in next, ContentArea:GetChildren() do
                if Cont.Name == "ItemContainer" then Cont.Visible = false end
            end
            TweenService:Create(TabBtn.Ico,     TweenInfo.new(0.22,Enum.EasingStyle.Quint), {ImageTransparency=0.05, ImageColor3=Color3.fromRGB(255,255,255)}):Play()
            TweenService:Create(TabBtn.TabName, TweenInfo.new(0.22,Enum.EasingStyle.Quint), {TextTransparency=0}):Play()
            TweenService:Create(TabBtn.ActiveBar, TweenInfo.new(0.22,Enum.EasingStyle.Quint), {BackgroundTransparency=0}):Play()
            TweenService:Create(TabBtn, TweenInfo.new(0.22,Enum.EasingStyle.Quint), {BackgroundTransparency=0.88}):Play()
            ItemContainer.Visible = true

            task.defer(function()
                local tabPos = TabBtn.AbsolutePosition.X - TabBar.AbsolutePosition.X
                local tabEnd = tabPos + TabBtn.AbsoluteSize.X
                local barWidth = TabBar.AbsoluteSize.X
                local canvas = TabBar.CanvasPosition.X
                if tabPos < canvas then
                    TabBar.CanvasPosition = Vector2.new(math.max(0, tabPos - 8), 0)
                elseif tabEnd > canvas + barWidth then
                    TabBar.CanvasPosition = Vector2.new(tabEnd - barWidth + 8, 0)
                end
            end)
        end

        if FirstTab then
            FirstTab = false
            ActivateTab()
        end

        AddConnection(TabBtn.MouseButton1Click, function()
            ClickSound:Play()
            ActivateTab()
        end)

        AddConnection(TabBtn.MouseEnter, function()
            if ItemContainer.Visible then return end
            TweenService:Create(TabBtn, TweenInfo.new(0.18,Enum.EasingStyle.Quint), {BackgroundTransparency=0.94}):Play()
        end)
        AddConnection(TabBtn.MouseLeave, function()
            if ItemContainer.Visible then return end
            TweenService:Create(TabBtn, TweenInfo.new(0.18,Enum.EasingStyle.Quint), {BackgroundTransparency=1}):Play()
        end)

        -- -------------------------------------------------------
        -- Element-Funktionen
        -- -------------------------------------------------------
        local function GetElements(ItemParent)
            local ElementFunction = {}

            function ElementFunction:AddLabel(Text)
                local LabelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5), {
                    Size=UDim2.new(1,0,0,30), BackgroundTransparency=0.01, Parent=ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label",Text,15), {Size=UDim2.new(1,-12,1,0), Position=UDim2.new(0,12,0,0), Font=Enum.Font.FredokaOne, Name="Content"}), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke")
                }), "Second")
                local LabelFunction = {}
                function LabelFunction:Set(ToChange) LabelFrame.Content.Text = ToChange end
                return LabelFunction
            end

            function ElementFunction:AddParagraph(Text, Content)
                Text = Text or "Text"; Content = Content or "Content"
                local ParagraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5), {
                    Size=UDim2.new(1,0,0,30), BackgroundTransparency=0.01, Parent=ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label",Text,15), {Size=UDim2.new(1,-12,0,14), Position=UDim2.new(0,12,0,10), Font=Enum.Font.FredokaOne, Name="Title"}), "Text"),
                    AddThemeObject(SetProps(MakeElement("Label","",13), {Size=UDim2.new(1,-24,0,0), Position=UDim2.new(0,12,0,26), Font=Enum.Font.FredokaOne, Name="Content", TextWrapped=true}), "TextDark"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke")
                }), "Second")
                AddConnection(ParagraphFrame.Content:GetPropertyChangedSignal("Text"), function()
                    ParagraphFrame.Content.Size = UDim2.new(1,-24,0,ParagraphFrame.Content.TextBounds.Y)
                    ParagraphFrame.Size = UDim2.new(1,0,0,ParagraphFrame.Content.TextBounds.Y+35)
                end)
                ParagraphFrame.Content.Text = Content
                local ParagraphFunction = {}
                function ParagraphFunction:Set(ToChange) ParagraphFrame.Content.Text = ToChange end
                return ParagraphFunction
            end

            function ElementFunction:AddButton(ButtonConfig)
                ButtonConfig = ButtonConfig or {}
                ButtonConfig.Name = ButtonConfig.Name or "Button"
                ButtonConfig.Callback = ButtonConfig.Callback or function() end

                local Button = {}
                local Click = SetProps(MakeElement("Button"), {Size=UDim2.new(1,0,1,0)})

                local ButtonAccentLine = Create("Frame", {
                    Size=UDim2.new(0,2,0,14), Position=UDim2.new(0,0,0.5,0), AnchorPoint=Vector2.new(0,0.5),
                    BackgroundColor3=Color3.fromRGB(60,120,255), BorderSizePixel=0, BackgroundTransparency=0.4
                }, {Create("UICorner",{CornerRadius=UDim.new(0,2)})})

                local ButtonArrow = Create("TextLabel", {
                    Size=UDim2.new(0,20,1,0), Position=UDim2.new(1,-28,0,0), BackgroundTransparency=1,
                    Text="›", TextColor3=Color3.fromRGB(100,100,110), TextSize=18, Font=Enum.Font.GothamBold,
                    TextXAlignment=Enum.TextXAlignment.Center, Name="Arrow"
                })

                local ButtonFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5), {
                    Size=UDim2.new(1,0,0,34), Parent=ItemParent, BackgroundTransparency=0.01
                }), {
                    ButtonAccentLine,
                    AddThemeObject(SetProps(MakeElement("Label",ButtonConfig.Name,14), {Size=UDim2.new(1,-45,1,0), Position=UDim2.new(0,14,0,0), Font=Enum.Font.FredokaOne, Name="Content"}), "Text"),
                    ButtonArrow,
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    Click
                }), "Second")

                AddConnection(Click.MouseEnter, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.2,Enum.EasingStyle.Quint), {BackgroundColor3=Color3.fromRGB(22,22,26)}):Play()
                    TweenService:Create(ButtonArrow, TweenInfo.new(0.2,Enum.EasingStyle.Quint), {TextColor3=Color3.fromRGB(60,120,255), Position=UDim2.new(1,-24,0,0)}):Play()
                end)
                AddConnection(Click.MouseLeave, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.2,Enum.EasingStyle.Quint), {BackgroundColor3=Library.Themes[Library.SelectedTheme].Second}):Play()
                    TweenService:Create(ButtonArrow, TweenInfo.new(0.2,Enum.EasingStyle.Quint), {TextColor3=Color3.fromRGB(100,100,110), Position=UDim2.new(1,-28,0,0)}):Play()
                end)
                AddConnection(Click.MouseButton1Down, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.1,Enum.EasingStyle.Quad), {BackgroundColor3=Color3.fromRGB(18,18,22)}):Play()
                    TweenService:Create(ButtonAccentLine, TweenInfo.new(0.1,Enum.EasingStyle.Quad), {Size=UDim2.new(0,2,0,20)}):Play()
                end)
                AddConnection(Click.MouseButton1Up, function()
                    TweenService:Create(ButtonFrame, TweenInfo.new(0.2,Enum.EasingStyle.Quint), {BackgroundColor3=Color3.fromRGB(22,22,26)}):Play()
                    TweenService:Create(ButtonAccentLine, TweenInfo.new(0.2,Enum.EasingStyle.Quint), {Size=UDim2.new(0,2,0,14)}):Play()
                    spawn(function() ButtonConfig.Callback() end)
                end)
                function Button:Set(ButtonText) ButtonFrame.Content.Text = ButtonText end
                return Button
            end

            function ElementFunction:AddToggle(ToggleConfig)
                ToggleConfig = ToggleConfig or {}
                ToggleConfig.Name = ToggleConfig.Name or "Toggle"
                ToggleConfig.Default = ToggleConfig.Default or false
                ToggleConfig.Callback = ToggleConfig.Callback or function() end
                ToggleConfig.Color = ToggleConfig.Color or Color3.fromRGB(9,99,195)
                ToggleConfig.Flag = ToggleConfig.Flag or nil
                ToggleConfig.Save = ToggleConfig.Save or false

                local Toggle = {Value=ToggleConfig.Default, Save=ToggleConfig.Save}
                local Click = SetProps(MakeElement("Button"), {Size=UDim2.new(1,0,1,0)})

                local ToggleTrack = Create("Frame", {
                    Size=UDim2.new(0,36,0,20), Position=UDim2.new(1,-46,0.5,0), AnchorPoint=Vector2.new(0,0.5),
                    BackgroundColor3=Color3.fromRGB(18,18,22), BorderSizePixel=0, Name="Track"
                }, {
                    Create("UICorner",{CornerRadius=UDim.new(1,0)}),
                    Create("UIStroke",{Color=Color3.fromRGB(40,40,50), Thickness=1, Name="Stroke"})
                })
                local ToggleThumb = Create("Frame", {
                    Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,3,0.5,0), AnchorPoint=Vector2.new(0,0.5),
                    BackgroundColor3=Color3.fromRGB(120,120,130), BorderSizePixel=0, Name="Thumb", Parent=ToggleTrack
                }, {Create("UICorner",{CornerRadius=UDim.new(1,0)})})

                local ToggleFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5), {
                    Size=UDim2.new(1,0,0,36), Parent=ItemParent, BackgroundTransparency=0.01
                }), {
                    AddThemeObject(SetProps(MakeElement("Label",ToggleConfig.Name,14), {Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,12,0,0), Font=Enum.Font.FredokaOne, Name="Content"}), "Text"),
                    AddThemeObject(MakeElement("Stroke"), "Stroke"),
                    ToggleTrack, Click
                }), "Second")

                function Toggle:Set(Value)
                    Toggle.Value = Value
                    if Toggle.Value then
                        TweenService:Create(ToggleTrack,       TweenInfo.new(0.25,Enum.EasingStyle.Quint), {BackgroundColor3=ToggleConfig.Color}):Play()
                        TweenService:Create(ToggleTrack.Stroke,TweenInfo.new(0.25,Enum.EasingStyle.Quint), {Color=ToggleConfig.Color, Transparency=0.6}):Play()
                        TweenService:Create(ToggleThumb,       TweenInfo.new(0.25,Enum.EasingStyle.Quint), {Position=UDim2.new(0,19,0.5,0), BackgroundColor3=Color3.fromRGB(255,255,255)}):Play()
                    else
                        TweenService:Create(ToggleTrack,       TweenInfo.new(0.25,Enum.EasingStyle.Quint), {BackgroundColor3=Color3.fromRGB(18,18,22)}):Play()
                        TweenService:Create(ToggleTrack.Stroke,TweenInfo.new(0.25,Enum.EasingStyle.Quint), {Color=Color3.fromRGB(40,40,50), Transparency=0}):Play()
                        TweenService:Create(ToggleThumb,       TweenInfo.new(0.25,Enum.EasingStyle.Quint), {Position=UDim2.new(0,3,0.5,0), BackgroundColor3=Color3.fromRGB(120,120,130)}):Play()
                    end
                    ToggleConfig.Callback(Toggle.Value)
                end
                Toggle:Set(Toggle.Value)

                AddConnection(Click.MouseEnter,    function() TweenService:Create(ToggleFrame,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=Color3.fromRGB(22,22,26)}):Play() end)
                AddConnection(Click.MouseLeave,    function() TweenService:Create(ToggleFrame,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=Library.Themes[Library.SelectedTheme].Second}):Play() end)
                AddConnection(Click.MouseButton1Up,function()
                    TweenService:Create(ToggleFrame,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundColor3=Color3.fromRGB(22,22,26)}):Play()
                    SaveCfg(game.GameId); Toggle:Set(not Toggle.Value)
                end)
                AddConnection(Click.MouseButton1Down,function()
                    TweenService:Create(ToggleThumb,TweenInfo.new(0.1,Enum.EasingStyle.Quad),{Size=UDim2.new(0,17,0,14)}):Play()
                end)
                if ToggleConfig.Flag then Library.Flags[ToggleConfig.Flag] = Toggle end
                return Toggle
            end

            function ElementFunction:AddSlider(SliderConfig)
                SliderConfig = SliderConfig or {}
                SliderConfig.Name = SliderConfig.Name or "Slider"
                SliderConfig.Min = SliderConfig.Min or 0; SliderConfig.Max = SliderConfig.Max or 100
                SliderConfig.Increment = SliderConfig.Increment or 1; SliderConfig.Default = SliderConfig.Default or 50
                SliderConfig.Callback = SliderConfig.Callback or function() end
                SliderConfig.ValueName = SliderConfig.ValueName or ""
                SliderConfig.Color = SliderConfig.Color or Color3.fromRGB(120,125,130)
                SliderConfig.Flag = SliderConfig.Flag or nil; SliderConfig.Save = SliderConfig.Save or false

                local Slider = {Value=SliderConfig.Default, Save=SliderConfig.Save}
                local Dragging = false

                local SliderDrag = SetProps(MakeElement("RoundFrame",SliderConfig.Color,0,5), {Size=UDim2.new(0,0,1,0), ZIndex=2})
                local SliderBar = SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(18,18,22),0,5), {
                    Size=UDim2.new(1,-24,0,16), Position=UDim2.new(0,12,0,38), ClipsDescendants=true
                }), {SetProps(MakeElement("Stroke"),{Color=SliderConfig.Color,Transparency=0.55}), SliderDrag})

                local SliderValueLabel = AddThemeObject(SetProps(MakeElement("Label","value",13), {
                    Size=UDim2.new(1,-24,0,14), Position=UDim2.new(0,12,0,20), Font=Enum.Font.FredokaOne,
                    Name="Value", TextTransparency=0.35, TextXAlignment=Enum.TextXAlignment.Right
                }), "TextDark")

                local SliderFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5), {
                    Size=UDim2.new(1,0,0,62), Parent=ItemParent, BackgroundTransparency=0.01
                }), {
                    AddThemeObject(SetProps(MakeElement("Label",SliderConfig.Name,15), {Size=UDim2.new(1,-100,0,14), Position=UDim2.new(0,12,0,10), Font=Enum.Font.FredokaOne, Name="Content"}), "Text"),
                    SliderValueLabel, AddThemeObject(MakeElement("Stroke"),"Stroke"), SliderBar
                }), "Second")

                SliderBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then Dragging=true end end)
                SliderBar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then Dragging=false end end)
                UserInputService.InputChanged:Connect(function(i)
                    if Dragging then
                        local s = math.clamp((Mouse.X-SliderBar.AbsolutePosition.X)/SliderBar.AbsoluteSize.X,0,1)
                        Slider:Set(SliderConfig.Min+((SliderConfig.Max-SliderConfig.Min)*s)); SaveCfg(game.GameId)
                    end
                end)
                function Slider:Set(Value)
                    self.Value = math.clamp(Round(Value,SliderConfig.Increment),SliderConfig.Min,SliderConfig.Max)
                    TweenService:Create(SliderDrag,TweenInfo.new(.15,Enum.EasingStyle.Quad),{Size=UDim2.fromScale((self.Value-SliderConfig.Min)/(SliderConfig.Max-SliderConfig.Min),1)}):Play()
                    SliderValueLabel.Text = tostring(self.Value).." "..SliderConfig.ValueName
                    SliderConfig.Callback(self.Value)
                end
                Slider:Set(Slider.Value)
                if SliderConfig.Flag then Library.Flags[SliderConfig.Flag] = Slider end
                return Slider
            end

            function ElementFunction:AddDropdown(DropdownConfig)
                DropdownConfig = DropdownConfig or {}
                DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
                DropdownConfig.Options = DropdownConfig.Options or {}
                DropdownConfig.Default = DropdownConfig.Default or ""
                DropdownConfig.Callback = DropdownConfig.Callback or function() end
                DropdownConfig.Flag = DropdownConfig.Flag or nil; DropdownConfig.Save = DropdownConfig.Save or false

                local Dropdown = {Value=DropdownConfig.Default, Options=DropdownConfig.Options, Buttons={}, Toggled=false, Type="Dropdown", Save=DropdownConfig.Save}
                local MaxElements = 5
                if not table.find(Dropdown.Options,Dropdown.Value) then Dropdown.Value = "..." end

                local DropdownList = MakeElement("List")
                local DropdownContainer = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame",Color3.fromRGB(40,40,40),4),{DropdownList}),{
                    Parent=ItemParent, Position=UDim2.new(0,0,0,38), Size=UDim2.new(1,0,1,-38), ClipsDescendants=true
                }), "Divider")

                local Click = SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
                local DropdownFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{
                    Size=UDim2.new(1,0,0,38), Parent=ItemParent, ClipsDescendants=true
                }), {
                    DropdownContainer,
                    SetProps(SetChildren(MakeElement("TFrame"),{
                        AddThemeObject(SetProps(MakeElement("Label",DropdownConfig.Name,15),{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),Font=Enum.Font.FredokaOne,Name="Content"}),"Text"),
                        AddThemeObject(SetProps(MakeElement("Image","rbxassetid://7072706796"),{Size=UDim2.new(0,20,0,20),AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(1,-30,0.5,0),Name="Ico"}),"TextDark"),
                        AddThemeObject(SetProps(MakeElement("Label","Selected",13),{Size=UDim2.new(1,-40,1,0),Font=Enum.Font.FredokaOne,Name="Selected",TextXAlignment=Enum.TextXAlignment.Right}),"TextDark"),
                        AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),Name="Line",Visible=false}),"Stroke"),
                        Click
                    }),{Size=UDim2.new(1,0,0,38),ClipsDescendants=true,Name="F"}),
                    AddThemeObject(MakeElement("Stroke"),"Stroke"), MakeElement("Corner")
                }), "Second")

                AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"),function()
                    DropdownContainer.CanvasSize=UDim2.new(0,0,0,DropdownList.AbsoluteContentSize.Y)
                end)

                local function AddOptions(Options)
                    for _,Option in pairs(Options) do
                        local OptionBtn = AddThemeObject(SetProps(SetChildren(MakeElement("Button",Color3.fromRGB(40,40,40)),{
                            MakeElement("Corner",0,6),
                            AddThemeObject(SetProps(MakeElement("Label",Option,13,0.4),{Position=UDim2.new(0,8,0,0),Size=UDim2.new(1,-8,1,0),Name="Title"}),"Text")
                        }),{Parent=DropdownContainer,Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,ClipsDescendants=true}),"Divider")
                        AddConnection(OptionBtn.MouseButton1Click,function() Dropdown:Set(Option); SaveCfg(game.GameId) end)
                        Dropdown.Buttons[Option] = OptionBtn
                    end
                end

                function Dropdown:Refresh(Options,Delete)
                    if Delete then for _,v in pairs(Dropdown.Buttons) do v:Destroy() end; table.clear(Dropdown.Options); table.clear(Dropdown.Buttons) end
                    Dropdown.Options=Options; AddOptions(Dropdown.Options)
                end
                function Dropdown:Set(Value)
                    if not table.find(Dropdown.Options,Value) then
                        Dropdown.Value="..."; DropdownFrame.F.Selected.Text=Dropdown.Value
                        for _,v in pairs(Dropdown.Buttons) do TweenService:Create(v,TweenInfo.new(.15,Enum.EasingStyle.Quad),{BackgroundTransparency=1}):Play(); TweenService:Create(v.Title,TweenInfo.new(.15,Enum.EasingStyle.Quad),{TextTransparency=0.4}):Play() end; return
                    end
                    Dropdown.Value=Value; DropdownFrame.F.Selected.Text=Dropdown.Value
                    for _,v in pairs(Dropdown.Buttons) do TweenService:Create(v,TweenInfo.new(.15,Enum.EasingStyle.Quad),{BackgroundTransparency=1}):Play(); TweenService:Create(v.Title,TweenInfo.new(.15,Enum.EasingStyle.Quad),{TextTransparency=0.4}):Play() end
                    TweenService:Create(Dropdown.Buttons[Value],TweenInfo.new(.15,Enum.EasingStyle.Quad),{BackgroundTransparency=0}):Play()
                    TweenService:Create(Dropdown.Buttons[Value].Title,TweenInfo.new(.15,Enum.EasingStyle.Quad),{TextTransparency=0}):Play()
                    return DropdownConfig.Callback(Dropdown.Value)
                end

                AddConnection(Click.MouseButton1Click,function()
                    Dropdown.Toggled=not Dropdown.Toggled
                    DropdownFrame.F.Line.Visible=Dropdown.Toggled
                    TweenService:Create(DropdownFrame.F.Ico,TweenInfo.new(.15,Enum.EasingStyle.Quad),{Rotation=Dropdown.Toggled and 180 or 0}):Play()
                    if #Dropdown.Options>MaxElements then
                        TweenService:Create(DropdownFrame,TweenInfo.new(.15,Enum.EasingStyle.Quad),{Size=Dropdown.Toggled and UDim2.new(1,0,0,38+(MaxElements*28)) or UDim2.new(1,0,0,38)}):Play()
                    else
                        TweenService:Create(DropdownFrame,TweenInfo.new(.15,Enum.EasingStyle.Quad),{Size=Dropdown.Toggled and UDim2.new(1,0,0,DropdownList.AbsoluteContentSize.Y+38) or UDim2.new(1,0,0,38)}):Play()
                    end
                end)
                Dropdown:Refresh(Dropdown.Options,false); Dropdown:Set(Dropdown.Value)
                if DropdownConfig.Flag then Library.Flags[DropdownConfig.Flag]=Dropdown end
                return Dropdown
            end

            function ElementFunction:AddBind(BindConfig)
                BindConfig.Name = BindConfig.Name or "Bind"
                BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
                BindConfig.Hold = BindConfig.Hold or false
                BindConfig.Callback = BindConfig.Callback or function() end
                BindConfig.Flag = BindConfig.Flag or nil; BindConfig.Save = BindConfig.Save or false

                local Bind = {Value=nil, Binding=false, Type="Bind", Save=BindConfig.Save}
                local Holding = false
                local Click = SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})

                local BindBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,4),{
                    Size=UDim2.new(0,24,0,24), Position=UDim2.new(1,-12,0.5,0), AnchorPoint=Vector2.new(1,0.5)
                }), {
                    AddThemeObject(MakeElement("Stroke"),"Stroke"),
                    AddThemeObject(SetProps(MakeElement("Label",BindConfig.Name,14),{Size=UDim2.new(1,0,1,0),Font=Enum.Font.FredokaOne,TextXAlignment=Enum.TextXAlignment.Center,Name="Value"}),"Text")
                }), "Main")

                local BindFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{
                    Size=UDim2.new(1,0,0,38), Parent=ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label",BindConfig.Name,15),{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),Font=Enum.Font.FredokaOne,Name="Content"}),"Text"),
                    AddThemeObject(MakeElement("Stroke"),"Stroke"), BindBox, Click
                }), "Second")

                AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"),function()
                    TweenService:Create(BindBox,TweenInfo.new(0.25,Enum.EasingStyle.Quint),{Size=UDim2.new(0,BindBox.Value.TextBounds.X+16,0,24)}):Play()
                end)
                AddConnection(Click.InputEnded,function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                        if Bind.Binding then return end; Bind.Binding=true; BindBox.Value.Text=""
                    end
                end)
                AddConnection(UserInputService.InputBegan,function(i)
                    if UserInputService:GetFocusedTextBox() then return end
                    if (i.KeyCode.Name==Bind.Value or i.UserInputType.Name==Bind.Value) and not Bind.Binding then
                        if BindConfig.Hold then Holding=true; BindConfig.Callback(Holding) else BindConfig.Callback() end
                    elseif Bind.Binding then
                        local Key; pcall(function() if not CheckKey(BlacklistedKeys,i.KeyCode) then Key=i.KeyCode end end)
                        pcall(function() if CheckKey(WhitelistedMouse,i.UserInputType) and not Key then Key=i.UserInputType end end)
                        Key=Key or Bind.Value; Bind:Set(Key); SaveCfg(game.GameId)
                    end
                end)
                AddConnection(UserInputService.InputEnded,function(i)
                    if i.KeyCode.Name==Bind.Value or i.UserInputType.Name==Bind.Value then
                        if BindConfig.Hold and Holding then Holding=false; BindConfig.Callback(Holding) end
                    end
                end)
                function Bind:Set(Key) Bind.Binding=false; Bind.Value=Key or Bind.Value; Bind.Value=Bind.Value.Name or Bind.Value; BindBox.Value.Text=Bind.Value end
                Bind:Set(BindConfig.Default)
                if BindConfig.Flag then Library.Flags[BindConfig.Flag]=Bind end
                return Bind
            end

            function ElementFunction:AddTextbox(TextboxConfig)
                TextboxConfig = TextboxConfig or {}
                TextboxConfig.Name = TextboxConfig.Name or "Textbox"
                TextboxConfig.Default = TextboxConfig.Default or ""
                TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
                TextboxConfig.Callback = TextboxConfig.Callback or function() end

                local Click = SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
                local TextboxActual = AddThemeObject(Create("TextBox",{
                    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, TextColor3=Color3.fromRGB(255,255,255),
                    PlaceholderColor3=Color3.fromRGB(210,210,210), PlaceholderText="Input",
                    Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Center, TextSize=14, ClearTextOnFocus=false
                }), "Text")
                local TextContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,4),{
                    Size=UDim2.new(0,24,0,24), Position=UDim2.new(1,-12,0.5,0), AnchorPoint=Vector2.new(1,0.5)
                }), {AddThemeObject(MakeElement("Stroke"),"Stroke"), TextboxActual}), "Main")
                local TextboxFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{
                    Size=UDim2.new(1,0,0,38), Parent=ItemParent
                }), {
                    AddThemeObject(SetProps(MakeElement("Label",TextboxConfig.Name,15),{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),Font=Enum.Font.FredokaOne,Name="Content"}),"Text"),
                    AddThemeObject(MakeElement("Stroke"),"Stroke"), TextContainer, Click
                }), "Second")

                AddConnection(TextboxActual:GetPropertyChangedSignal("Text"),function()
                    TweenService:Create(TextContainer,TweenInfo.new(0.45,Enum.EasingStyle.Quint),{Size=UDim2.new(0,TextboxActual.TextBounds.X+16,0,24)}):Play()
                end)
                AddConnection(TextboxActual.FocusLost,function() TextboxConfig.Callback(TextboxActual.Text); if TextboxConfig.TextDisappear then TextboxActual.Text="" end end)
                TextboxActual.Text=TextboxConfig.Default
                AddConnection(Click.MouseButton1Up,function() TextboxActual:CaptureFocus() end)
            end

            function ElementFunction:AddColorpicker(ColorpickerConfig)
                ColorpickerConfig = ColorpickerConfig or {}
                ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
                ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255,255,255)
                ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
                ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil; ColorpickerConfig.Save = ColorpickerConfig.Save or false

                local ColorH, ColorS, ColorV = 1, 1, 1
                local Colorpicker = {Value=ColorpickerConfig.Default, Toggled=false, Type="Colorpicker", Save=ColorpickerConfig.Save}
                local ColorSelection = Create("ImageLabel",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(select(3,Color3.toHSV(Colorpicker.Value))),ScaleType=Enum.ScaleType.Fit,AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,Image="http://www.roblox.com/asset/?id=4805639000"})
                local HueSelection = Create("ImageLabel",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0.5,0,1-select(1,Color3.toHSV(Colorpicker.Value))),ScaleType=Enum.ScaleType.Fit,AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,Image="http://www.roblox.com/asset/?id=4805639000"})
                local Color = Create("ImageLabel",{Size=UDim2.new(1,-25,1,0),Visible=false,Image="rbxassetid://4155801252"},{Create("UICorner",{CornerRadius=UDim.new(0,5)}),ColorSelection})
                local Hue = Create("Frame",{Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-20,0,0),Visible=false},{
                    Create("UIGradient",{Rotation=270,Color=ColorSequence.new{ColorSequenceKeypoint.new(0.00,Color3.fromRGB(255,0,4)),ColorSequenceKeypoint.new(0.20,Color3.fromRGB(234,255,0)),ColorSequenceKeypoint.new(0.40,Color3.fromRGB(21,255,0)),ColorSequenceKeypoint.new(0.60,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(0.80,Color3.fromRGB(0,17,255)),ColorSequenceKeypoint.new(0.90,Color3.fromRGB(255,0,251)),ColorSequenceKeypoint.new(1.00,Color3.fromRGB(255,0,4))}}),
                    Create("UICorner",{CornerRadius=UDim.new(0,5)}), HueSelection
                })
                local ColorpickerContainer = Create("Frame",{Position=UDim2.new(0,0,0,32),Size=UDim2.new(1,0,1,-32),BackgroundTransparency=1,ClipsDescendants=true},{
                    Hue, Color, Create("UIPadding",{PaddingLeft=UDim.new(0,35),PaddingRight=UDim.new(0,35),PaddingBottom=UDim.new(0,10),PaddingTop=UDim.new(0,17)})
                })
                local Click = SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
                local ColorpickerBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,4),{Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-12,0.5,0),AnchorPoint=Vector2.new(1,0.5)}),{AddThemeObject(MakeElement("Stroke"),"Stroke")}),"Main")
                local ColorpickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{Size=UDim2.new(1,0,0,38),Parent=ItemParent}),{
                    SetProps(SetChildren(MakeElement("TFrame"),{
                        AddThemeObject(SetProps(MakeElement("Label",ColorpickerConfig.Name,15),{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),Font=Enum.Font.FredokaOne,Name="Content"}),"Text"),
                        ColorpickerBox, Click,
                        AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),Name="Line",Visible=false}),"Stroke")
                    }),{Size=UDim2.new(1,0,0,38),ClipsDescendants=true,Name="F"}),
                    ColorpickerContainer, AddThemeObject(MakeElement("Stroke"),"Stroke")
                }),"Second")

                AddConnection(Click.MouseButton1Click,function()
                    Colorpicker.Toggled=not Colorpicker.Toggled
                    TweenService:Create(ColorpickerFrame,TweenInfo.new(.15,Enum.EasingStyle.Quad),{Size=Colorpicker.Toggled and UDim2.new(1,0,0,148) or UDim2.new(1,0,0,38)}):Play()
                    Color.Visible=Colorpicker.Toggled; Hue.Visible=Colorpicker.Toggled; ColorpickerFrame.F.Line.Visible=Colorpicker.Toggled
                end)

                local function UpdateColorPicker()
                    ColorpickerBox.BackgroundColor3=Color3.fromHSV(ColorH,ColorS,ColorV)
                    Color.BackgroundColor3=Color3.fromHSV(ColorH,1,1)
                    Colorpicker:Set(ColorpickerBox.BackgroundColor3); ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3); SaveCfg(game.GameId)
                end

                ColorH=1-(math.clamp(HueSelection.AbsolutePosition.Y-Hue.AbsolutePosition.Y,0,Hue.AbsoluteSize.Y)/Hue.AbsoluteSize.Y)
                ColorS=(math.clamp(ColorSelection.AbsolutePosition.X-Color.AbsolutePosition.X,0,Color.AbsoluteSize.X)/Color.AbsoluteSize.X)
                ColorV=1-(math.clamp(ColorSelection.AbsolutePosition.Y-Color.AbsolutePosition.Y,0,Color.AbsoluteSize.Y)/Color.AbsoluteSize.Y)

                local ColorInput, HueInput
                AddConnection(Color.InputBegan,function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                        if ColorInput then ColorInput:Disconnect() end
                        ColorInput=AddConnection(RunService.RenderStepped,function()
                            local cx=(math.clamp(Mouse.X-Color.AbsolutePosition.X,0,Color.AbsoluteSize.X)/Color.AbsoluteSize.X)
                            local cy=(math.clamp(Mouse.Y-Color.AbsolutePosition.Y,0,Color.AbsoluteSize.Y)/Color.AbsoluteSize.Y)
                            ColorSelection.Position=UDim2.new(cx,0,cy,0); ColorS=cx; ColorV=1-cy; UpdateColorPicker()
                        end)
                    end
                end)
                AddConnection(Color.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then if ColorInput then ColorInput:Disconnect() end end end)
                AddConnection(Hue.InputBegan,function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                        if HueInput then HueInput:Disconnect() end
                        HueInput=AddConnection(RunService.RenderStepped,function()
                            local hy=(math.clamp(Mouse.Y-Hue.AbsolutePosition.Y,0,Hue.AbsoluteSize.Y)/Hue.AbsoluteSize.Y)
                            HueSelection.Position=UDim2.new(0.5,0,hy,0); ColorH=1-hy; UpdateColorPicker()
                        end)
                    end
                end)
                AddConnection(Hue.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then if HueInput then HueInput:Disconnect() end end end)

                function Colorpicker:Set(Value) Colorpicker.Value=Value; ColorpickerBox.BackgroundColor3=Colorpicker.Value; ColorpickerConfig.Callback(Colorpicker.Value) end
                Colorpicker:Set(Colorpicker.Value)
                if ColorpickerConfig.Flag then Library.Flags[ColorpickerConfig.Flag]=Colorpicker end
                return Colorpicker
            end

            return ElementFunction
        end

        local ElementFunction = {}
        function ElementFunction:AddSection(SectionConfig)
            SectionConfig.Name = SectionConfig.Name or "Section"
            local SectionLabelRow = SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,0,16),ClipsDescendants=false})
            AddThemeObject(SetProps(MakeElement("Label",SectionConfig.Name,14),{Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,8,0,0),Font=Enum.Font.FredokaOne,Parent=SectionLabelRow}),"TextDark")
            local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,0,26),Parent=ItemContainer}),{
                SectionLabelRow,
                SetChildren(SetProps(MakeElement("TFrame"),{AnchorPoint=Vector2.new(0,0),Size=UDim2.new(1,0,1,-24),Position=UDim2.new(0,0,0,23),Name="Holder"}),{MakeElement("List",0,6)})
            })
            AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
                SectionFrame.Size=UDim2.new(1,0,0,SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y+31)
                SectionFrame.Holder.Size=UDim2.new(1,0,0,SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
            end)
            local SectionFunction = {}
            for i,v in next, GetElements(SectionFrame.Holder) do SectionFunction[i]=v end
            return SectionFunction
        end

        for i,v in next, GetElements(ItemContainer) do ElementFunction[i]=v end

        if TabConfig.PremiumOnly then
            for i,_ in next, ElementFunction do ElementFunction[i]=function() end end
            ItemContainer:FindFirstChild("UIListLayout"):Destroy()
            ItemContainer:FindFirstChild("UIPadding"):Destroy()
            SetChildren(SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,1,0),Parent=ItemContainer}),{
                AddThemeObject(SetProps(MakeElement("Label","Unauthorised Access",14),{Size=UDim2.new(1,-38,0,14),Position=UDim2.new(0,38,0,18),TextTransparency=0.4}),"Text"),
                AddThemeObject(SetProps(MakeElement("Label","Premium Features",14),{Size=UDim2.new(1,-150,0,14),Position=UDim2.new(0,150,0,112),Font=Enum.Font.FredokaOne}),"Text"),
                AddThemeObject(SetProps(MakeElement("Label","This part of the script is locked to Premium users.",12),{Size=UDim2.new(1,-200,0,14),Position=UDim2.new(0,150,0,138),TextWrapped=true,TextTransparency=0.4}),"Text")
            })
        end

        return ElementFunction
    end

    return TabFunction
end

-- =========================================================
-- Zweites Notification-System
-- =========================================================
local Configs_HUB = {
    Cor_Hub=Color3.fromRGB(15,15,15), Cor_Options=Color3.fromRGB(15,15,15),
    Cor_Stroke=Color3.fromRGB(60,60,60), Cor_Text=Color3.fromRGB(240,240,240),
    Cor_DarkText=Color3.fromRGB(160,160,165), Corner_Radius=UDim.new(0,4),
    Text_Font=Library.Font
}
local function CreateNotifElement(instance,parent,props)
    local new=Instance.new(instance,parent)
    if props then table.foreach(props,function(p,v) new[p]=v end) end
    return new
end
local function CreateTween(instance,prop,value,time,tweenWait)
    local tween=TweenService:Create(instance,TweenInfo.new(time,Enum.EasingStyle.Linear),{[prop]=value}); tween:Play()
    if tweenWait then tween.Completed:Wait() end
end
local function CornerNotif(parent,props)
    local new=CreateNotifElement("UICorner",parent); new.CornerRadius=Configs_HUB.Corner_Radius
    if props then table.foreach(props,function(p,v) new[p]=v end) end
    return new
end
local ScreenGui2=CreateNotifElement("ScreenGui",Container)
local Menu_Notifi=CreateNotifElement("Frame",ScreenGui2,{Size=UDim2.new(0,300,1,0),Position=UDim2.new(1,0,0,0),AnchorPoint=Vector2.new(1,0),BackgroundTransparency=1})
CreateNotifElement("UIPadding",Menu_Notifi,{PaddingLeft=UDim.new(0,25),PaddingTop=UDim.new(0,25),PaddingBottom=UDim.new(0,50)})
CreateNotifElement("UIListLayout",Menu_Notifi,{Padding=UDim.new(0,15),VerticalAlignment="Bottom"})

function Library:MakeNotifi(Configs)
    local Title=Configs.Title or "Title!"; local text=Configs.Text or "Notification content..."; local timewait=Configs.Time or 5
    local Frame1=CreateNotifElement("Frame",Menu_Notifi,{Size=UDim2.new(2,0,0,0),BackgroundTransparency=1,AutomaticSize="Y",Name="Title"})
    local Frame2=CreateNotifElement("Frame",Frame1,{Size=UDim2.new(0,Menu_Notifi.Size.X.Offset-50,0,0),BackgroundColor3=Configs_HUB.Cor_Hub,Position=UDim2.new(0,Menu_Notifi.Size.X.Offset,0,0),AutomaticSize="Y"})
    CornerNotif(Frame2)
    CreateNotifElement("TextLabel",Frame2,{Size=UDim2.new(1,0,0,25),Font=Configs_HUB.Text_Font,BackgroundTransparency=1,Text=Title,TextSize=20,Position=UDim2.new(0,20,0,5),TextXAlignment="Left",TextColor3=Configs_HUB.Cor_Text})
    local TextButton=CreateNotifElement("TextButton",Frame2,{Text="X",Font=Configs_HUB.Text_Font,TextSize=20,BackgroundTransparency=1,TextColor3=Color3.fromRGB(220,220,220),Position=UDim2.new(1,-5,0,5),AnchorPoint=Vector2.new(1,0),Size=UDim2.new(0,25,0,25)})
    CreateNotifElement("TextLabel",Frame2,{Size=UDim2.new(1,-30,0,0),Position=UDim2.new(0,20,0,TextButton.Size.Y.Offset+10),TextSize=15,TextColor3=Configs_HUB.Cor_DarkText,TextXAlignment="Left",TextYAlignment="Top",AutomaticSize="Y",Text=text,Font=Configs_HUB.Text_Font,BackgroundTransparency=1,TextWrapped=true})
    local FrameSize=CreateNotifElement("Frame",Frame2,{Size=UDim2.new(1,0,0,2),BackgroundColor3=Configs_HUB.Cor_Stroke,Position=UDim2.new(0,2,0,30),BorderSizePixel=0})
    CornerNotif(FrameSize)
    CreateNotifElement("Frame",Frame2,{Size=UDim2.new(0,0,0,5),Position=UDim2.new(0,0,1,5),BackgroundTransparency=1})
    task.spawn(function() CreateTween(FrameSize,"Size",UDim2.new(0,0,0,2),timewait,true) end)
    TextButton.MouseButton1Click:Connect(function()
        CreateTween(Frame2,"Position",UDim2.new(0,-20,0,0),0.1,true)
        CreateTween(Frame2,"Position",UDim2.new(0,Menu_Notifi.Size.X.Offset,0,0),0.5,true)
        Frame1:Destroy()
    end)
    task.spawn(function()
        CreateTween(Frame2,"Position",UDim2.new(0,-20,0,0),0.5,true)
        CreateTween(Frame2,"Position",UDim2.new(),0.1,true)
        task.wait(timewait)
        if Frame2 then
            CreateTween(Frame2,"Position",UDim2.new(0,-20,0,0),0.1,true)
            CreateTween(Frame2,"Position",UDim2.new(0,Menu_Notifi.Size.X.Offset,0,0),0.5,true)
            Frame1:Destroy()
        end
    end)
end

function Library:Destroy()
    Container:Destroy()
end

return Library

--[[
==========================================================
  VERWENDUNGSBEISPIEL / USAGE EXAMPLE
==========================================================

local Library = loadstring(game:HttpGet("..."))()

local Window = Library:MakeWindow({
    Name         = "Mein Script",
    BannerIcon   = "rbxassetid://DEINE_ICON_ID",  -- optional
    LoadDuration = 3,
    SaveConfig   = false,
})

local CombatTab = Window:MakeTab({
    Name = "Combat",
    Icon = "rbxassetid://XXXXXXX",
})

CombatTab:AddToggle({
    Name     = "Enable Aimbot",
    Default  = false,
    Callback = function(v) print(v) end,
})

local VisualsTab = Window:MakeTab({
    Name = "Visuals",
    Icon = "rbxassetid://XXXXXXX",
})

VisualsTab:AddToggle({
    Name     = "Enable ESP",
    Default  = false,
    Callback = function(v) print(v) end,
})

Library:Init()
==========================================================

  ÄNDERUNGEN:
  ✓ Fenstername ist jetzt ZENTRIERT in der TopBar
  ✓ Button-Container (Resize | Minimize | Close) ist
    ganz RECHTS in der TopBar
  ✓ Icons sind perfekt zentriert in ihren Boxen
  ✓ Alle anderen Features bleiben unverändert
==========================================================
]]
