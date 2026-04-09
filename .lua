--V3 | Left Sidebar Layout + Categories + Search

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

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
            Main      = Color3.fromRGB(8, 8, 10),
            Second    = Color3.fromRGB(14, 14, 17),
            Sidebar   = Color3.fromRGB(11, 11, 14),
            Stroke    = Color3.fromRGB(32, 32, 38),
            Divider   = Color3.fromRGB(20, 20, 24),
            Text      = Color3.fromRGB(230, 230, 235),
            TextDark  = Color3.fromRGB(150, 150, 158),
            Accent    = Color3.fromRGB(60, 120, 255),
        }
    },
    SelectedTheme = "Default",
    Folder  = nil,
    SaveCfg = false,
    Font    = Enum.Font.Gotham
}

-- ── Container ──────────────────────────────────────────────────────────────
local Container = Instance.new("ScreenGui")
Container.Name = string.char(math.random(65,90))..tostring(math.random(100,999))
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
    while Library:IsRunning() do task.wait() end
    for _, c in next, Library.Connections do c:Disconnect() end
end)

-- ── Helpers ─────────────────────────────────────────────────────────────────
local function Create(Name, Properties, Children)
    local o = Instance.new(Name)
    for i,v in next, Properties or {} do o[i] = v end
    for _,v in next, Children  or {} do v.Parent = o end
    return o
end

local function SetProps(e, p)
    for k,v in next, p do e[k] = v end; return e
end
local function SetChildren(e, c)
    for _,v in next, c do v.Parent = e end; return e
end

local function Round(n, f)
    local r = math.floor(n/f + (math.sign(n)*0.5))*f
    if r < 0 then r = r + f end; return r
end

local function ReturnProperty(o)
    if o:IsA("Frame") or o:IsA("TextButton")  then return "BackgroundColor3" end
    if o:IsA("ScrollingFrame")                 then return "ScrollBarImageColor3" end
    if o:IsA("UIStroke")                       then return "Color" end
    if o:IsA("TextLabel") or o:IsA("TextBox")  then return "TextColor3" end
    if o:IsA("ImageLabel") or o:IsA("ImageButton") then return "ImageColor3" end
end

local function AddThemeObject(obj, t)
    if not Library.ThemeObjects[t] then Library.ThemeObjects[t] = {} end
    table.insert(Library.ThemeObjects[t], obj)
    obj[ReturnProperty(obj)] = Library.Themes[Library.SelectedTheme][t]
    return obj
end

local function PackColor(c)   return {R=c.R*255, G=c.G*255, B=c.B*255} end
local function UnpackColor(c) return Color3.fromRGB(c.R, c.G, c.B) end

local function LoadCfg(cfg)
    local Data = game:GetService("HttpService"):JSONDecode(cfg)
    for a,b in pairs(Data) do
        if Library.Flags[a] then
            spawn(function()
                if Library.Flags[a].Type == "Colorpicker" then
                    Library.Flags[a]:Set(UnpackColor(b))
                else
                    Library.Flags[a]:Set(b)
                end
            end)
        end
    end
end
local function SaveCfg() end -- stub (same as original)

local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3, Enum.UserInputType.Touch}
local BlacklistedKeys  = {Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right, Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape}

local function CheckKey(t,k) for _,v in next,t do if v==k then return true end end end

-- ── Element Factories ────────────────────────────────────────────────────────
local Elements = {}
local function CreateElement(n,f) Elements[n]=f end
local function MakeElement(n,...) return Elements[n](...) end

CreateElement("Corner",   function(s,o)   return Create("UICorner",{CornerRadius=UDim.new(s or 0, o or 8)}) end)
CreateElement("Stroke",   function(c,t)   return Create("UIStroke",{Color=c or Color3.new(1,1,1), Thickness=t or 1}) end)
CreateElement("List",     function(s,o)   return Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(s or 0, o or 0)}) end)
CreateElement("Padding",  function(b,l,r,t) return Create("UIPadding",{PaddingBottom=UDim.new(0,b or 4),PaddingLeft=UDim.new(0,l or 4),PaddingRight=UDim.new(0,r or 4),PaddingTop=UDim.new(0,t or 4)}) end)
CreateElement("TFrame",   function()      return Create("Frame",{BackgroundTransparency=1}) end)
CreateElement("Frame",    function(c)     return Create("Frame",{BackgroundColor3=c or Color3.new(1,1,1),BorderSizePixel=0}) end)
CreateElement("RoundFrame",function(c,s,o) return Create("Frame",{BackgroundColor3=c or Color3.new(1,1,1),BorderSizePixel=0},{Create("UICorner",{CornerRadius=UDim.new(s,o)})}) end)
CreateElement("Button",   function()      return Create("TextButton",{Text="",AutoButtonColor=false,BackgroundTransparency=1,BorderSizePixel=0}) end)
CreateElement("ScrollFrame",function(c,w) return Create("ScrollingFrame",{BackgroundTransparency=1,MidImage="rbxassetid://7445543667",BottomImage="rbxassetid://7445543667",TopImage="rbxassetid://7445543667",ScrollBarImageColor3=c,BorderSizePixel=0,ScrollBarThickness=w,CanvasSize=UDim2.new(0,0,0,0)}) end)
CreateElement("Image",    function(id)    return Create("ImageLabel",{Image=id,BackgroundTransparency=1}) end)
CreateElement("ImageButton",function(id) return Create("ImageButton",{Image=id,BackgroundTransparency=1}) end)
CreateElement("Label",    function(tx,ts,tr) return Create("TextLabel",{Text=tx or "",TextColor3=Color3.fromRGB(240,240,240),TextTransparency=tr or 0,TextSize=ts or 15,Font=Enum.Font.GothamSemibold,RichText=true,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left}) end)
Library.Elements = Elements

-- ── Dragging ─────────────────────────────────────────────────────────────────
local function MakeDraggable(DragPoint, Main)
    local IsResizing = false
    pcall(function()
        local Dragging, DragInput, MousePos, FramePos = false
        DragPoint.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                if not IsResizing then
                    Dragging = true; MousePos = i.Position; FramePos = Main.Position
                end
                i.Changed:Connect(function()
                    if i.UserInputState == Enum.UserInputState.End then Dragging = false end
                end)
            end
        end)
        DragPoint.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                DragInput = i
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if i == DragInput and Dragging and not IsResizing then
                local D = i.Position - MousePos
                TweenService:Create(Main, TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset+D.X, FramePos.Y.Scale, FramePos.Y.Offset+D.Y)
                }):Play()
            end
        end)
    end)
    return function(r) IsResizing = r; if r then Dragging = false end end
end

local function MakeResizable(ResizeBtn, Main, MinSize, MaxSize, SetResizing)
    pcall(function()
        local Resizing, StartSize, StartPos = false
        ResizeBtn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                Resizing = true; if SetResizing then SetResizing(true) end
                StartSize = Main.Size; StartPos = Vector2.new(Mouse.X, Mouse.Y)
            end
        end)
        ResizeBtn.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                Resizing = false; if SetResizing then SetResizing(false) end
            end
        end)
        UserInputService.InputChanged:Connect(function()
            if Resizing then
                local D = Vector2.new(Mouse.X, Mouse.Y) - StartPos
                Main.Size = UDim2.new(0, math.clamp(StartSize.X.Offset+D.X, MinSize.X, MaxSize.X), 0, math.clamp(StartSize.Y.Offset+D.Y, MinSize.Y, MaxSize.Y))
            end
        end)
    end)
end

-- ── Loading Screen ────────────────────────────────────────────────────────────
local function ShowLoadingScreen(duration, callback)
    local Overlay = Create("Frame",{Parent=Container,Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1,ZIndex=100,BorderSizePixel=0})
    local LoadWindow = Create("Frame",{Parent=Container,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),Size=UDim2.new(0,300,0,130),BackgroundColor3=Color3.fromRGB(10,10,13),BorderSizePixel=0,ZIndex=101,BackgroundTransparency=1},{
        Create("UICorner",{CornerRadius=UDim.new(0,12)}),
        Create("UIStroke",{Color=Color3.fromRGB(35,35,42),Thickness=1.2})
    })
    local LogoImg = Create("ImageLabel",{Parent=LoadWindow,AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,18),Size=UDim2.new(0,24,0,24),BackgroundTransparency=1,Image="rbxassetid://125829575723612",ImageTransparency=1,ZIndex=102})
    local LoadTitle = Create("TextLabel",{Parent=LoadWindow,AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,48),Size=UDim2.new(1,-20,0,18),BackgroundTransparency=1,Text="Venty",TextColor3=Color3.fromRGB(230,230,235),TextSize=17,Font=Enum.Font.GothamBlack,TextXAlignment=Enum.TextXAlignment.Center,TextTransparency=1,ZIndex=102})
    local LoadSub = Create("TextLabel",{Parent=LoadWindow,AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,70),Size=UDim2.new(1,-20,0,13),BackgroundTransparency=1,Text="Initializing...",TextColor3=Color3.fromRGB(100,100,115),TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Center,TextTransparency=1,ZIndex=102})
    local BarBg = Create("Frame",{Parent=LoadWindow,AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,90),Size=UDim2.new(1,-40,0,3),BackgroundColor3=Color3.fromRGB(25,25,32),BorderSizePixel=0,ZIndex=102},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
    local BarFill = Create("Frame",{Parent=BarBg,Size=UDim2.new(0,0,1,0),BackgroundColor3=Color3.fromRGB(60,120,255),BorderSizePixel=0,ZIndex=103},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
    local PercLabel = Create("TextLabel",{Parent=LoadWindow,AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,100),Size=UDim2.new(1,-40,0,13),BackgroundTransparency=1,Text="0%",TextColor3=Color3.fromRGB(70,70,88),TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Right,TextTransparency=1,ZIndex=102})

    TweenService:Create(LoadWindow,TweenInfo.new(0.35,Enum.EasingStyle.Quint),{BackgroundTransparency=0}):Play()
    task.wait(0.1)
    TweenService:Create(LogoImg,  TweenInfo.new(0.3,Enum.EasingStyle.Quint),{ImageTransparency=0}):Play()
    TweenService:Create(LoadTitle,TweenInfo.new(0.3,Enum.EasingStyle.Quint),{TextTransparency=0}):Play()
    task.wait(0.15)
    TweenService:Create(LoadSub,  TweenInfo.new(0.25,Enum.EasingStyle.Quint),{TextTransparency=0}):Play()
    TweenService:Create(PercLabel,TweenInfo.new(0.25,Enum.EasingStyle.Quint),{TextTransparency=0}):Play()
    task.wait(0.1)

    local steps = {"Checking environment...", "Loading modules...", "Applying settings...", "Ready!"}
    local stepDur = duration / #steps
    for i, stepText in ipairs(steps) do
        LoadSub.Text = stepText
        TweenService:Create(BarFill,TweenInfo.new(stepDur*0.9,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(i/#steps,0,1,0)}):Play()
        local sp = math.floor((i-1)/#steps*100); local ep = math.floor(i/#steps*100); local t0 = tick()
        while tick()-t0 < stepDur do
            PercLabel.Text = math.floor(sp+(ep-sp)*math.clamp((tick()-t0)/stepDur,0,1)).."%"; task.wait()
        end
        PercLabel.Text = ep.."%"
    end

    task.wait(0.12)
    for _,o in next,{LoadWindow,LogoImg,LoadTitle,LoadSub,PercLabel,BarBg,BarFill,Overlay} do
        local p = o:IsA("ImageLabel") and "ImageTransparency" or (o:IsA("TextLabel") and "TextTransparency") or "BackgroundTransparency"
        TweenService:Create(o,TweenInfo.new(0.4,Enum.EasingStyle.Quint),{[p]=1}):Play()
    end
    task.wait(0.5)
    LoadWindow:Destroy(); Overlay:Destroy()
    if callback then callback() end
end

-- ── Notification (original) ──────────────────────────────────────────────────
local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"),{
    SetProps(MakeElement("List"),{HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Bottom,Padding=UDim.new(0,5)})
}),{Position=UDim2.new(1,-25,1,-25),Size=UDim2.new(0,300,1,-25),AnchorPoint=Vector2.new(1,1),Parent=Container})

function Library:MakeNotification(cfg)
    spawn(function()
        cfg.Name    = cfg.Name    or "Notification"
        cfg.Content = cfg.Content or "Test"
        cfg.Image   = cfg.Image   or "rbxassetid://4384403532"
        cfg.Time    = cfg.Time    or 15
        local npar = SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,Parent=NotificationHolder})
        local nfr = SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(25,25,25),0,10),{Parent=npar,Size=UDim2.new(1,0,0,0),Position=UDim2.new(1,-55,0,0),BackgroundTransparency=0,AutomaticSize=Enum.AutomaticSize.Y}),{
            MakeElement("Stroke",Color3.fromRGB(93,93,93),1.2),
            MakeElement("Padding",12,12,12,12),
            SetProps(MakeElement("Image",cfg.Image),{Size=UDim2.new(0,20,0,20),ImageColor3=Color3.fromRGB(240,240,240),Name="Icon"}),
            SetProps(MakeElement("Label",cfg.Name,15),{Size=UDim2.new(1,-30,0,20),Position=UDim2.new(0,30,0,0),Font=Enum.Font.FredokaOne,Name="Title"}),
            SetProps(MakeElement("Label",cfg.Content,14),{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,25),Font=Enum.Font.FredokaOne,Name="Content",AutomaticSize=Enum.AutomaticSize.Y,TextColor3=Color3.fromRGB(220,220,220),TextWrapped=true})
        })
        TweenService:Create(nfr,TweenInfo.new(0.5,Enum.EasingStyle.Quint),{Position=UDim2.new(0,0,0,0)}):Play()
        wait(cfg.Time - 0.88)
        TweenService:Create(nfr.Icon,  TweenInfo.new(0.4,Enum.EasingStyle.Quint),{ImageTransparency=1}):Play()
        TweenService:Create(nfr,       TweenInfo.new(0.8,Enum.EasingStyle.Quint),{BackgroundTransparency=0.6}):Play()
        wait(0.3)
        TweenService:Create(nfr.UIStroke,TweenInfo.new(0.6,Enum.EasingStyle.Quint),{Transparency=0.9}):Play()
        TweenService:Create(nfr.Title,   TweenInfo.new(0.6,Enum.EasingStyle.Quint),{TextTransparency=0.4}):Play()
        TweenService:Create(nfr.Content, TweenInfo.new(0.6,Enum.EasingStyle.Quint),{TextTransparency=0.5}):Play()
        wait(0.05); nfr:TweenPosition(UDim2.new(1,20,0,0),"In","Quint",0.8,true)
        wait(1.35); nfr:Destroy()
    end)
end

function Library:Init()
    if Library.SaveCfg then
        pcall(function()
            if isfile(Library.Folder.."/"..game.GameId..".txt") then
                LoadCfg(readfile(Library.Folder.."/"..game.GameId..".txt"))
                Library:MakeNotification({Name="Configuration",Content="Auto-loaded configuration for game "..game.GameId..".",Time=5})
            end
        end)
    end
end

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                          MAKE WINDOW (V3)                               ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
function Library:MakeWindow(WindowConfig)
    WindowConfig = WindowConfig or {}
    WindowConfig.Name            = WindowConfig.Name            or "Venty"
    WindowConfig.Icon            = WindowConfig.Icon            or "rbxassetid://125829575723612"
    WindowConfig.ConfigFolder    = WindowConfig.ConfigFolder    or WindowConfig.Name
    WindowConfig.SaveConfig      = WindowConfig.SaveConfig      or false
    WindowConfig.IntroEnabled    = (WindowConfig.IntroEnabled ~= nil) and WindowConfig.IntroEnabled or true
    WindowConfig.CloseCallback   = WindowConfig.CloseCallback   or function() end
    WindowConfig.LoadDuration    = WindowConfig.LoadDuration    or 2.5

    Library.Folder  = WindowConfig.ConfigFolder
    Library.SaveCfg = WindowConfig.SaveConfig

    if WindowConfig.SaveConfig then
        pcall(function()
            if not isfolder(WindowConfig.ConfigFolder) then makefolder(WindowConfig.ConfigFolder) end
        end)
    end

    local T = Library.Themes[Library.SelectedTheme]
    local Minimized = false
    local UIHidden  = false

    -- ── SIDEBAR (left, 160px wide) ──────────────────────────────────────────
    -- ┌─────────────────────────────────────────────────────────────────────┐
    -- │ TopBar: [Icon+Name box] ................ [Search][Resize][Min][X]  │
    -- ├────────────┬────────────────────────────────────────────────────────┤
    -- │  Sidebar   │  Content                                               │
    -- │  (tabs)    │                                                        │
    -- └────────────┴────────────────────────────────────────────────────────┘

    local SIDEBAR_W = 150
    local TOPBAR_H  = 46

    -- ── Main Window ──────────────────────────────────────────────────────────
    local MainWindow = Create("Frame",{
        Parent = Container,
        Position = UDim2.new(0.5,-310,0.5,-185),
        Size = UDim2.new(0,620,0,370),
        BackgroundColor3 = T.Main,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false
    },{
        Create("UICorner",{CornerRadius=UDim.new(0,10)}),
        Create("UIStroke",{Color=T.Stroke, Thickness=1.2})
    })
    AddThemeObject(MainWindow, "Main")

    -- ── Sidebar ───────────────────────────────────────────────────────────────
    local Sidebar = Create("Frame",{
        Parent = MainWindow,
        Position = UDim2.new(0,0,0,TOPBAR_H),
        Size = UDim2.new(0,SIDEBAR_W,1,-TOPBAR_H),
        BackgroundColor3 = T.Sidebar,
        BorderSizePixel = 0,
        ZIndex = 2
    })
    AddThemeObject(Sidebar, "Sidebar")

    local SidebarStroke = Create("Frame",{
        Parent = Sidebar,
        Position = UDim2.new(1,-1,0,0),
        Size = UDim2.new(0,1,1,0),
        BackgroundColor3 = T.Stroke,
        BorderSizePixel = 0
    })
    AddThemeObject(SidebarStroke, "Stroke")

    -- scrollable tab list inside sidebar
    local SidebarScroll = Create("ScrollingFrame",{
        Parent = Sidebar,
        Position = UDim2.new(0,0,0,8),
        Size = UDim2.new(1,-1,1,-8),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        BorderSizePixel = 0,
        ZIndex = 3
    },{
        Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2)}),
        Create("UIPadding",{PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)})
    })

    -- auto-size canvas
    SidebarScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SidebarScroll.CanvasSize = UDim2.new(0,0,0,SidebarScroll.UIListLayout.AbsoluteContentSize.Y + 12)
    end)

    -- ── TopBar ────────────────────────────────────────────────────────────────
    local TopBar = Create("Frame",{
        Parent = MainWindow,
        Size = UDim2.new(1,0,0,TOPBAR_H),
        BackgroundColor3 = T.Main,
        BorderSizePixel = 0,
        ZIndex = 5,
        ClipsDescendants = false
    })
    AddThemeObject(TopBar, "Main")

    local TopBarLine = Create("Frame",{
        Parent = TopBar,
        Position = UDim2.new(0,0,1,-1),
        Size = UDim2.new(1,0,0,1),
        BackgroundColor3 = T.Stroke,
        BorderSizePixel = 0
    })
    AddThemeObject(TopBarLine, "Stroke")

    -- Window icon + active tab label (left side of topbar)
    local IconBox = Create("Frame",{
        Parent = TopBar,
        Position = UDim2.new(0,8,0.5,0),
        Size = UDim2.new(0,28,0,28),
        AnchorPoint = Vector2.new(0,0.5),
        BackgroundColor3 = T.Second,
        BorderSizePixel = 0,
        ZIndex = 6
    },{
        Create("UICorner",{CornerRadius=UDim.new(0,6)}),
        Create("UIStroke",{Color=T.Stroke, Thickness=1}),
        Create("ImageLabel",{
            Image = WindowConfig.Icon,
            Size = UDim2.new(0,18,0,18),
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.new(0.5,0,0.5,0),
            BackgroundTransparency = 1,
            Name = "Ico"
        })
    })
    AddThemeObject(IconBox, "Second")

    -- Active tab name label (next to icon box)
    local ActiveTabLabel = Create("TextLabel",{
        Parent = TopBar,
        Position = UDim2.new(0,42,0.5,0),
        Size = UDim2.new(0,200,0,20),
        AnchorPoint = Vector2.new(0,0.5),
        BackgroundTransparency = 1,
        Text = "...",
        TextColor3 = T.Text,
        TextSize = 14,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6
    })
    AddThemeObject(ActiveTabLabel, "Text")

    -- ── Button cluster (top-right) ────────────────────────────────────────────
    local BtnCluster = Create("Frame",{
        Parent = TopBar,
        Position = UDim2.new(1,-8,0.5,0),
        Size = UDim2.new(0,144,0,26),
        AnchorPoint = Vector2.new(1,0.5),
        BackgroundColor3 = T.Second,
        BorderSizePixel = 0,
        ZIndex = 6
    },{
        Create("UICorner",{CornerRadius=UDim.new(0,6)}),
        Create("UIStroke",{Color=T.Stroke, Thickness=1})
    })
    AddThemeObject(BtnCluster, "Second")

    local function MakeTopBtn(icon, xPos)
        local btn = Create("TextButton",{
            Parent = BtnCluster,
            Position = UDim2.new(0,xPos,0,0),
            Size = UDim2.new(0,36,1,0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 7
        })
        local img = Create("ImageLabel",{
            Parent = btn,
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.new(0.5,0,0.5,0),
            Size = UDim2.new(0,16,0,16),
            BackgroundTransparency = 1,
            Image = icon,
            ZIndex = 7
        })
        AddThemeObject(img, "Text")
        -- divider after each btn except last
        if xPos < 108 then
            Create("Frame",{
                Parent = BtnCluster,
                Position = UDim2.new(0,xPos+36,0,4),
                Size = UDim2.new(0,1,0,18),
                BackgroundColor3 = T.Stroke,
                BorderSizePixel = 0,
                ZIndex = 6
            })
        end
        return btn, img
    end

    -- Search (lupe), Resize, Minimize, Close
    local SearchBtn, SearchIco = MakeTopBtn("rbxassetid://6031094678", 0)   -- magnifier
    local ResizeBtn, _         = MakeTopBtn("rbxassetid://117273761878755", 36)
    local MinimizeBtn, MinIco  = MakeTopBtn("rbxassetid://7072719338", 72)
    local CloseBtn, _          = MakeTopBtn("rbxassetid://7072725342", 108)

    -- ── Search overlay ────────────────────────────────────────────────────────
    local SearchActive = false
    local SearchOverlay = Create("Frame",{
        Parent = MainWindow,
        Position = UDim2.new(0,SIDEBAR_W+1,0,TOPBAR_H+1),
        Size = UDim2.new(1,-(SIDEBAR_W+1),1,-(TOPBAR_H+1)),
        BackgroundColor3 = T.Main,
        BorderSizePixel = 0,
        ZIndex = 20,
        Visible = false,
        ClipsDescendants = true
    })
    AddThemeObject(SearchOverlay, "Main")

    local SearchHeader = Create("Frame",{
        Parent = SearchOverlay,
        Size = UDim2.new(1,0,0,44),
        BackgroundColor3 = T.Second,
        BorderSizePixel = 0,
        ZIndex = 21
    },{
        Create("UICorner",{CornerRadius=UDim.new(0,6)}),
        Create("UIStroke",{Color=T.Stroke, Thickness=1})
    })
    AddThemeObject(SearchHeader, "Second")

    Create("ImageLabel",{
        Parent = SearchHeader,
        Position = UDim2.new(0,12,0.5,0),
        Size = UDim2.new(0,16,0,16),
        AnchorPoint = Vector2.new(0,0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6031094678",
        ImageColor3 = T.TextDark,
        ZIndex = 22
    })

    local SearchBox = Create("TextBox",{
        Parent = SearchHeader,
        Position = UDim2.new(0,36,0.5,0),
        Size = UDim2.new(1,-48,0,22),
        AnchorPoint = Vector2.new(0,0.5),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Suche...",
        TextColor3 = T.Text,
        PlaceholderColor3 = T.TextDark,
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 22
    })

    local SearchResultsScroll = Create("ScrollingFrame",{
        Parent = SearchOverlay,
        Position = UDim2.new(0,0,0,52),
        Size = UDim2.new(1,0,1,-52),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize = UDim2.new(0,0,0,0),
        BorderSizePixel = 0,
        ZIndex = 21
    },{
        Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4)}),
        Create("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,6)})
    })

    SearchResultsScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SearchResultsScroll.CanvasSize = UDim2.new(0,0,0,SearchResultsScroll.UIListLayout.AbsoluteContentSize.Y+12)
    end)

    -- All searchable items registry: {Name, Frame, ActivateTab}
    local SearchRegistry = {}

    local function RebuildSearch(query)
        for _, c in next, SearchResultsScroll:GetChildren() do
            if c:IsA("Frame") then c:Destroy() end
        end
        if query == "" then return end
        local q = query:lower()
        local found = 0
        for _, item in ipairs(SearchRegistry) do
            if item.Name:lower():find(q, 1, true) then
                found = found + 1
                local row = Create("Frame",{
                    Parent = SearchResultsScroll,
                    Size = UDim2.new(1,0,0,36),
                    BackgroundColor3 = T.Second,
                    BorderSizePixel = 0,
                    ZIndex = 22
                },{
                    Create("UICorner",{CornerRadius=UDim.new(0,6)}),
                    Create("UIStroke",{Color=T.Stroke,Thickness=1}),
                    Create("TextLabel",{
                        Position = UDim2.new(0,12,0,0),
                        Size = UDim2.new(1,-60,1,0),
                        BackgroundTransparency = 1,
                        Text = item.Name,
                        TextColor3 = T.Text,
                        TextSize = 13,
                        Font = Enum.Font.GothamSemibold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 23
                    }),
                    Create("TextLabel",{
                        Position = UDim2.new(1,-80,0,0),
                        Size = UDim2.new(0,70,1,0),
                        BackgroundTransparency = 1,
                        Text = item.Tab or "",
                        TextColor3 = T.TextDark,
                        TextSize = 11,
                        Font = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        ZIndex = 23
                    })
                })
                local rowBtn = Create("TextButton",{Parent=row,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=24})
                AddConnection(rowBtn.MouseButton1Click, function()
                    if item.ActivateTab then item.ActivateTab() end
                    SearchActive = false; SearchOverlay.Visible = false; SearchBox.Text = ""
                end)
                AddConnection(rowBtn.MouseEnter, function()
                    TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(22,22,28)}):Play()
                end)
                AddConnection(rowBtn.MouseLeave, function()
                    TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=T.Second}):Play()
                end)
            end
        end
        if found == 0 then
            Create("TextLabel",{
                Parent = SearchResultsScroll,
                Size = UDim2.new(1,0,0,30),
                BackgroundTransparency = 1,
                Text = "Keine Ergebnisse gefunden.",
                TextColor3 = T.TextDark,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Center
            })
        end
    end

    AddConnection(SearchBox:GetPropertyChangedSignal("Text"), function()
        RebuildSearch(SearchBox.Text)
    end)

    AddConnection(SearchBtn.MouseButton1Click, function()
        SearchActive = not SearchActive
        SearchOverlay.Visible = SearchActive
        if SearchActive then SearchBox:CaptureFocus(); RebuildSearch(SearchBox.Text) end
    end)

    -- ── Content area ──────────────────────────────────────────────────────────
    local ContentArea = Create("Frame",{
        Parent = MainWindow,
        Position = UDim2.new(0,SIDEBAR_W+1,0,TOPBAR_H+1),
        Size = UDim2.new(1,-(SIDEBAR_W+1),1,-(TOPBAR_H+1)),
        BackgroundColor3 = T.Main,
        BorderSizePixel = 0,
        ZIndex = 2
    })
    AddThemeObject(ContentArea, "Main")

    -- ── Draggable region (TopBar) ─────────────────────────────────────────────
    local DragHandle = Create("TextButton",{
        Parent = TopBar,
        Position = UDim2.new(0,0,0,0),
        Size = UDim2.new(1,-160,1,0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 4
    })
    local SetResizingCb = MakeDraggable(DragHandle, MainWindow)
    MakeResizable(ResizeBtn, MainWindow, Vector2.new(420,280), Vector2.new(1200,800), SetResizingCb)

    -- ── Close / Minimize / Mobile reopen ─────────────────────────────────────
    local MobileBtn = Create("TextButton",{
        Parent = Container,
        Size = UDim2.new(0,40,0,40),
        Position = UDim2.new(0.5,-20,0,20),
        BackgroundColor3 = T.Main,
        Visible = false,
        ZIndex = 50
    },{
        Create("UICorner",{CornerRadius=UDim.new(1,0)}),
        Create("UIStroke",{Color=T.Stroke}),
        Create("ImageLabel",{
            Image = WindowConfig.Icon,
            Size = UDim2.new(0,22,0,22),
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.new(0.5,0,0.5,0),
            BackgroundTransparency = 1
        })
    })
    AddThemeObject(MobileBtn, "Main")

    AddConnection(CloseBtn.MouseButton1Up, function()
        MainWindow.Visible = false
        if UserInputService.TouchEnabled then MobileBtn.Visible = true end
        UIHidden = true
        Library:MakeNotification({Name="Interface Hidden",Content="Drücke Linke Strg zum Öffnen.",Time=4})
        WindowConfig.CloseCallback()
    end)
    AddConnection(UserInputService.InputBegan, function(i)
        if i.KeyCode == Enum.KeyCode.LeftControl and UIHidden then
            MainWindow.Visible = true; MobileBtn.Visible = false; UIHidden = false
        end
    end)
    AddConnection(MobileBtn.Activated, function()
        MainWindow.Visible = true; MobileBtn.Visible = false; UIHidden = false
    end)
    AddConnection(MinimizeBtn.MouseButton1Up, function()
        if Minimized then
            TweenService:Create(MainWindow,TweenInfo.new(0.5,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,620,0,370)}):Play()
            MinIco.Image = "rbxassetid://7072719338"
            task.wait(0.02)
            MainWindow.ClipsDescendants = false
            Sidebar.Visible = true; ContentArea.Visible = true; TopBarLine.Visible = true
        else
            MainWindow.ClipsDescendants = true
            Sidebar.Visible = false; ContentArea.Visible = false; TopBarLine.Visible = false
            MinIco.Image = "rbxassetid://7072720870"
            TweenService:Create(MainWindow,TweenInfo.new(0.5,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,260,0,TOPBAR_H)}):Play()
        end
        Minimized = not Minimized
    end)

    ShowLoadingScreen(WindowConfig.LoadDuration, function()
        MainWindow.Visible = true
    end)

    -- ════════════════════════════════════════════════════════════════════════
    --  TabFunction  (returned object for :MakeCategory / :MakeTab)
    -- ════════════════════════════════════════════════════════════════════════
    local TabFunction   = {}
    local FirstTab      = true
    local ActiveContent = nil  -- currently visible ItemContainer

    local function SetActiveTab(ItemContainer, tabName, tabBtn)
        -- hide all content frames
        for _, c in next, ContentArea:GetChildren() do
            if c.Name == "ItemContainer" then c.Visible = false end
        end
        -- deactivate all tab buttons
        for _, child in next, SidebarScroll:GetChildren() do
            if child:IsA("Frame") then -- category wrapper
                for _, tb in next, child:GetChildren() do
                    if tb:IsA("TextButton") then
                        pcall(function()
                            TweenService:Create(tb,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundTransparency=1}):Play()
                            TweenService:Create(tb.Lbl,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{TextTransparency=0.45}):Play()
                            if tb:FindFirstChild("Ico") then
                                TweenService:Create(tb.Ico,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{ImageTransparency=0.55}):Play()
                            end
                            if tb:FindFirstChild("Bar") then
                                TweenService:Create(tb.Bar,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundTransparency=1}):Play()
                            end
                        end)
                    end
                end
            elseif child:IsA("TextButton") then
                pcall(function()
                    TweenService:Create(child,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundTransparency=1}):Play()
                    TweenService:Create(child.Lbl,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{TextTransparency=0.45}):Play()
                    if child:FindFirstChild("Ico") then
                        TweenService:Create(child.Ico,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{ImageTransparency=0.55}):Play()
                    end
                    if child:FindFirstChild("Bar") then
                        TweenService:Create(child.Bar,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundTransparency=1}):Play()
                    end
                end)
            end
        end
        -- activate this tab
        TweenService:Create(tabBtn,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundTransparency=0.82}):Play()
        TweenService:Create(tabBtn.Lbl,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{TextTransparency=0}):Play()
        pcall(function() TweenService:Create(tabBtn.Ico,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{ImageTransparency=0.05,ImageColor3=Color3.fromRGB(255,255,255)}):Play() end)
        pcall(function() TweenService:Create(tabBtn.Bar,TweenInfo.new(0.2,Enum.EasingStyle.Quint),{BackgroundTransparency=0}):Play() end)
        ItemContainer.Visible = true
        ActiveContent = ItemContainer
        ActiveTabLabel.Text = tabName
    end

    -- ── GetElements (same content building logic as V2) ──────────────────────
    local function GetElements(ItemParent, tabName)
        local ElementFunction = {}

        function ElementFunction:AddLabel(Text)
            local f = SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{
                Size=UDim2.new(1,0,0,30),BackgroundTransparency=0.01,Parent=ItemParent
            }),{
                AddThemeObject(SetProps(MakeElement("Label",Text,15),{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),Font=Enum.Font.FredokaOne,Name="Content"}),"Text"),
                AddThemeObject(MakeElement("Stroke"),"Stroke")
            })
            AddThemeObject(f,"Second")
            -- register searchable
            table.insert(SearchRegistry,{Name=Text, Tab=tabName, ActivateTab=nil})
            local fn = {}; function fn:Set(t) f.Content.Text=t end; return fn
        end

        function ElementFunction:AddParagraph(Text, Content)
            Text=Text or "Text"; Content=Content or "Content"
            local f = SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{
                Size=UDim2.new(1,0,0,30),BackgroundTransparency=0.01,Parent=ItemParent
            }),{
                AddThemeObject(SetProps(MakeElement("Label",Text,15),{Size=UDim2.new(1,-12,0,14),Position=UDim2.new(0,12,0,10),Font=Enum.Font.FredokaOne,Name="Title"}),"Text"),
                AddThemeObject(SetProps(MakeElement("Label","",13),{Size=UDim2.new(1,-24,0,0),Position=UDim2.new(0,12,0,26),Font=Enum.Font.FredokaOne,Name="Content",TextWrapped=true}),"TextDark"),
                AddThemeObject(MakeElement("Stroke"),"Stroke")
            })
            AddThemeObject(f,"Second")
            AddConnection(f.Content:GetPropertyChangedSignal("Text"),function()
                f.Content.Size=UDim2.new(1,-24,0,f.Content.TextBounds.Y)
                f.Size=UDim2.new(1,0,0,f.Content.TextBounds.Y+35)
            end)
            f.Content.Text=Content
            local fn={}; function fn:Set(t) f.Content.Text=t end; return fn
        end

        function ElementFunction:AddButton(ButtonConfig)
            ButtonConfig=ButtonConfig or {}
            ButtonConfig.Name=ButtonConfig.Name or "Button"
            ButtonConfig.Callback=ButtonConfig.Callback or function() end
            local Click=SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
            local Accent=Create("Frame",{Size=UDim2.new(0,2,0,14),Position=UDim2.new(0,0,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=Color3.fromRGB(60,120,255),BorderSizePixel=0,BackgroundTransparency=0.4},{Create("UICorner",{CornerRadius=UDim.new(0,2)})})
            local Arrow=Create("TextLabel",{Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-28,0,0),BackgroundTransparency=1,Text="›",TextColor3=Color3.fromRGB(100,100,110),TextSize=18,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,Name="Arrow"})
            local f=AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{Size=UDim2.new(1,0,0,34),Parent=ItemParent,BackgroundTransparency=0.01}),{
                Accent,
                AddThemeObject(SetProps(MakeElement("Label",ButtonConfig.Name,14),{Size=UDim2.new(1,-45,1,0),Position=UDim2.new(0,14,0,0),Font=Enum.Font.FredokaOne,Name="Content"}),"Text"),
                Arrow,AddThemeObject(MakeElement("Stroke"),"Stroke"),Click
            }),"Second")
            table.insert(SearchRegistry,{Name=ButtonConfig.Name, Tab=tabName, ActivateTab=nil})
            AddConnection(Click.MouseEnter,function() TweenService:Create(f,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(22,22,26)}):Play(); TweenService:Create(Arrow,TweenInfo.new(0.2),{TextColor3=Color3.fromRGB(60,120,255),Position=UDim2.new(1,-24,0,0)}):Play() end)
            AddConnection(Click.MouseLeave,function() TweenService:Create(f,TweenInfo.new(0.2),{BackgroundColor3=T.Second}):Play(); TweenService:Create(Arrow,TweenInfo.new(0.2),{TextColor3=Color3.fromRGB(100,100,110),Position=UDim2.new(1,-28,0,0)}):Play() end)
            AddConnection(Click.MouseButton1Down,function() TweenService:Create(f,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(18,18,22)}):Play(); TweenService:Create(Accent,TweenInfo.new(0.1),{Size=UDim2.new(0,2,0,20)}):Play() end)
            AddConnection(Click.MouseButton1Up,function() TweenService:Create(f,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(22,22,26)}):Play(); TweenService:Create(Accent,TweenInfo.new(0.2),{Size=UDim2.new(0,2,0,14)}):Play(); spawn(ButtonConfig.Callback) end)
            local bt={}; function bt:Set(t) f.Content.Text=t end; return bt
        end

        function ElementFunction:AddToggle(ToggleConfig)
            ToggleConfig=ToggleConfig or {}
            ToggleConfig.Name=ToggleConfig.Name or "Toggle"
            ToggleConfig.Default=ToggleConfig.Default or false
            ToggleConfig.Callback=ToggleConfig.Callback or function() end
            ToggleConfig.Color=ToggleConfig.Color or Color3.fromRGB(9,99,195)
            ToggleConfig.Flag=ToggleConfig.Flag or nil; ToggleConfig.Save=ToggleConfig.Save or false
            local Toggle={Value=ToggleConfig.Default,Save=ToggleConfig.Save}
            local Click=SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
            local Track=Create("Frame",{Size=UDim2.new(0,36,0,20),Position=UDim2.new(1,-46,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=Color3.fromRGB(18,18,22),BorderSizePixel=0,Name="Track"},{
                Create("UICorner",{CornerRadius=UDim.new(1,0)}),
                Create("UIStroke",{Color=Color3.fromRGB(40,40,50),Thickness=1,Name="Stroke"})
            })
            local Thumb=Create("Frame",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,3,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=Color3.fromRGB(120,120,130),BorderSizePixel=0,Name="Thumb",Parent=Track},{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
            local f=AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{Size=UDim2.new(1,0,0,36),Parent=ItemParent,BackgroundTransparency=0.01}),{
                AddThemeObject(SetProps(MakeElement("Label",ToggleConfig.Name,14),{Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,12,0,0),Font=Enum.Font.FredokaOne,Name="Content"}),"Text"),
                AddThemeObject(MakeElement("Stroke"),"Stroke"), Track, Click
            }),"Second")
            table.insert(SearchRegistry,{Name=ToggleConfig.Name, Tab=tabName, ActivateTab=nil})
            function Toggle:Set(v)
                Toggle.Value=v
                if v then
                    TweenService:Create(Track,TweenInfo.new(0.25),{BackgroundColor3=ToggleConfig.Color}):Play()
                    TweenService:Create(Track.Stroke,TweenInfo.new(0.25),{Color=ToggleConfig.Color,Transparency=0.6}):Play()
                    TweenService:Create(Thumb,TweenInfo.new(0.25),{Position=UDim2.new(0,19,0.5,0),BackgroundColor3=Color3.fromRGB(255,255,255)}):Play()
                else
                    TweenService:Create(Track,TweenInfo.new(0.25),{BackgroundColor3=Color3.fromRGB(18,18,22)}):Play()
                    TweenService:Create(Track.Stroke,TweenInfo.new(0.25),{Color=Color3.fromRGB(40,40,50),Transparency=0}):Play()
                    TweenService:Create(Thumb,TweenInfo.new(0.25),{Position=UDim2.new(0,3,0.5,0),BackgroundColor3=Color3.fromRGB(120,120,130)}):Play()
                end
                ToggleConfig.Callback(Toggle.Value)
            end
            Toggle:Set(Toggle.Value)
            AddConnection(Click.MouseEnter,function() TweenService:Create(f,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(22,22,26)}):Play() end)
            AddConnection(Click.MouseLeave,function() TweenService:Create(f,TweenInfo.new(0.2),{BackgroundColor3=T.Second}):Play() end)
            AddConnection(Click.MouseButton1Up,function() TweenService:Create(f,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(22,22,26)}):Play(); SaveCfg(); Toggle:Set(not Toggle.Value) end)
            AddConnection(Click.MouseButton1Down,function() TweenService:Create(Thumb,TweenInfo.new(0.1),{Size=UDim2.new(0,17,0,14)}):Play() end)
            if ToggleConfig.Flag then Library.Flags[ToggleConfig.Flag]=Toggle end
            return Toggle
        end

        function ElementFunction:AddSlider(SliderConfig)
            SliderConfig=SliderConfig or {}
            SliderConfig.Name=SliderConfig.Name or "Slider"; SliderConfig.Min=SliderConfig.Min or 0; SliderConfig.Max=SliderConfig.Max or 100
            SliderConfig.Increment=SliderConfig.Increment or 1; SliderConfig.Default=SliderConfig.Default or 50
            SliderConfig.Callback=SliderConfig.Callback or function() end; SliderConfig.ValueName=SliderConfig.ValueName or ""
            SliderConfig.Color=SliderConfig.Color or Color3.fromRGB(120,125,130)
            SliderConfig.Flag=SliderConfig.Flag or nil; SliderConfig.Save=SliderConfig.Save or false
            local Slider={Value=SliderConfig.Default,Save=SliderConfig.Save}
            local Dragging=false
            local SDrag=SetProps(MakeElement("RoundFrame",SliderConfig.Color,0,5),{Size=UDim2.new(0,0,1,0),ZIndex=2})
            local SBar=SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(18,18,22),0,5),{Size=UDim2.new(1,-24,0,16),Position=UDim2.new(0,12,0,38),ClipsDescendants=true}),{SetProps(MakeElement("Stroke"),{Color=SliderConfig.Color,Transparency=0.55}),SDrag})
            local SVLbl=AddThemeObject(SetProps(MakeElement("Label","val",13),{Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,12,0,20),Font=Enum.Font.FredokaOne,Name="Value",TextTransparency=0.35,TextXAlignment=Enum.TextXAlignment.Right}),"TextDark")
            local f=AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{Size=UDim2.new(1,0,0,62),Parent=ItemParent,BackgroundTransparency=0.01}),{
                AddThemeObject(SetProps(MakeElement("Label",SliderConfig.Name,15),{Size=UDim2.new(1,-100,0,14),Position=UDim2.new(0,12,0,10),Font=Enum.Font.FredokaOne,Name="Content"}),"Text"),
                SVLbl,AddThemeObject(MakeElement("Stroke"),"Stroke"),SBar
            }),"Second")
            table.insert(SearchRegistry,{Name=SliderConfig.Name, Tab=tabName, ActivateTab=nil})
            SBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then Dragging=true end end)
            SBar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then Dragging=false end end)
            UserInputService.InputChanged:Connect(function()
                if Dragging then
                    local s=math.clamp((Mouse.X-SBar.AbsolutePosition.X)/SBar.AbsoluteSize.X,0,1)
                    Slider:Set(SliderConfig.Min+((SliderConfig.Max-SliderConfig.Min)*s)); SaveCfg()
                end
            end)
            function Slider:Set(v)
                self.Value=math.clamp(Round(v,SliderConfig.Increment),SliderConfig.Min,SliderConfig.Max)
                TweenService:Create(SDrag,TweenInfo.new(0.15,Enum.EasingStyle.Quad),{Size=UDim2.fromScale((self.Value-SliderConfig.Min)/(SliderConfig.Max-SliderConfig.Min),1)}):Play()
                SVLbl.Text=tostring(self.Value).." "..SliderConfig.ValueName; SliderConfig.Callback(self.Value)
            end
            Slider:Set(Slider.Value)
            if SliderConfig.Flag then Library.Flags[SliderConfig.Flag]=Slider end
            return Slider
        end

        function ElementFunction:AddDropdown(DropdownConfig)
            DropdownConfig=DropdownConfig or {}
            DropdownConfig.Name=DropdownConfig.Name or "Dropdown"; DropdownConfig.Options=DropdownConfig.Options or {}
            DropdownConfig.Default=DropdownConfig.Default or ""; DropdownConfig.Callback=DropdownConfig.Callback or function() end
            DropdownConfig.Flag=DropdownConfig.Flag or nil; DropdownConfig.Save=DropdownConfig.Save or false
            local Dropdown={Value=DropdownConfig.Default,Options=DropdownConfig.Options,Buttons={},Toggled=false,Type="Dropdown",Save=DropdownConfig.Save}
            local MaxEl=5
            if not table.find(Dropdown.Options,Dropdown.Value) then Dropdown.Value="..." end
            local DList=MakeElement("List")
            local DCont=AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame",Color3.fromRGB(40,40,40),4),{DList}),{Parent=ItemParent,Position=UDim2.new(0,0,0,38),Size=UDim2.new(1,0,1,-38),ClipsDescendants=true}),"Divider")
            local Click=SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
            local DFrame=AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{Size=UDim2.new(1,0,0,38),Parent=ItemParent,ClipsDescendants=true}),{
                DCont,
                SetProps(SetChildren(MakeElement("TFrame"),{
                    AddThemeObject(SetProps(MakeElement("Label",DropdownConfig.Name,15),{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),Font=Enum.Font.FredokaOne,Name="Content"}),"Text"),
                    AddThemeObject(SetProps(MakeElement("Image","rbxassetid://7072706796"),{Size=UDim2.new(0,20,0,20),AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(1,-30,0.5,0),Name="Ico"}),"TextDark"),
                    AddThemeObject(SetProps(MakeElement("Label","Selected",13),{Size=UDim2.new(1,-40,1,0),Font=Enum.Font.FredokaOne,Name="Selected",TextXAlignment=Enum.TextXAlignment.Right}),"TextDark"),
                    AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),Name="Line",Visible=false}),"Stroke"),
                    Click
                }),{Size=UDim2.new(1,0,0,38),ClipsDescendants=true,Name="F"}),
                AddThemeObject(MakeElement("Stroke"),"Stroke"),MakeElement("Corner")
            }),"Second")
            table.insert(SearchRegistry,{Name=DropdownConfig.Name, Tab=tabName, ActivateTab=nil})
            AddConnection(DList:GetPropertyChangedSignal("AbsoluteContentSize"),function() DCont.CanvasSize=UDim2.new(0,0,0,DList.AbsoluteContentSize.Y) end)
            local function AddOptions(opts)
                for _,opt in pairs(opts) do
                    local ob=AddThemeObject(SetProps(SetChildren(MakeElement("Button",Color3.fromRGB(40,40,40)),{
                        MakeElement("Corner",0,6),
                        AddThemeObject(SetProps(MakeElement("Label",opt,13,0.4),{Position=UDim2.new(0,8,0,0),Size=UDim2.new(1,-8,1,0),Name="Title"}),"Text")
                    }),{Parent=DCont,Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,ClipsDescendants=true}),"Divider")
                    AddConnection(ob.MouseButton1Click,function() Dropdown:Set(opt); SaveCfg() end)
                    Dropdown.Buttons[opt]=ob
                end
            end
            function Dropdown:Refresh(opts,del)
                if del then for _,v in pairs(Dropdown.Buttons) do v:Destroy() end; table.clear(Dropdown.Options); table.clear(Dropdown.Buttons) end
                Dropdown.Options=opts; AddOptions(Dropdown.Options)
            end
            function Dropdown:Set(v)
                if not table.find(Dropdown.Options,v) then Dropdown.Value="..."; DFrame.F.Selected.Text=Dropdown.Value
                    for _,b in pairs(Dropdown.Buttons) do TweenService:Create(b,TweenInfo.new(0.15),{BackgroundTransparency=1}):Play(); TweenService:Create(b.Title,TweenInfo.new(0.15),{TextTransparency=0.4}):Play() end; return end
                Dropdown.Value=v; DFrame.F.Selected.Text=Dropdown.Value
                for _,b in pairs(Dropdown.Buttons) do TweenService:Create(b,TweenInfo.new(0.15),{BackgroundTransparency=1}):Play(); TweenService:Create(b.Title,TweenInfo.new(0.15),{TextTransparency=0.4}):Play() end
                TweenService:Create(Dropdown.Buttons[v],TweenInfo.new(0.15),{BackgroundTransparency=0}):Play()
                TweenService:Create(Dropdown.Buttons[v].Title,TweenInfo.new(0.15),{TextTransparency=0}):Play()
                return DropdownConfig.Callback(Dropdown.Value)
            end
            AddConnection(Click.MouseButton1Click,function()
                Dropdown.Toggled=not Dropdown.Toggled; DFrame.F.Line.Visible=Dropdown.Toggled
                TweenService:Create(DFrame.F.Ico,TweenInfo.new(0.15),{Rotation=Dropdown.Toggled and 180 or 0}):Play()
                local newH = Dropdown.Toggled and (#Dropdown.Options>MaxEl and 38+(MaxEl*28) or DList.AbsoluteContentSize.Y+38) or 38
                TweenService:Create(DFrame,TweenInfo.new(0.15),{Size=UDim2.new(1,0,0,newH)}):Play()
            end)
            Dropdown:Refresh(Dropdown.Options,false); Dropdown:Set(Dropdown.Value)
            if DropdownConfig.Flag then Library.Flags[DropdownConfig.Flag]=Dropdown end
            return Dropdown
        end

        function ElementFunction:AddBind(BindConfig)
            BindConfig.Name=BindConfig.Name or "Bind"; BindConfig.Default=BindConfig.Default or Enum.KeyCode.Unknown
            BindConfig.Hold=BindConfig.Hold or false; BindConfig.Callback=BindConfig.Callback or function() end
            BindConfig.Flag=BindConfig.Flag or nil; BindConfig.Save=BindConfig.Save or false
            local Bind={Value=nil,Binding=false,Type="Bind",Save=BindConfig.Save}; local Holding=false
            local Click=SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
            local BBox=AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,4),{Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-12,0.5,0),AnchorPoint=Vector2.new(1,0.5)}),{
                AddThemeObject(MakeElement("Stroke"),"Stroke"),
                AddThemeObject(SetProps(MakeElement("Label","...",14),{Size=UDim2.new(1,0,1,0),Font=Enum.Font.FredokaOne,TextXAlignment=Enum.TextXAlignment.Center,Name="Value"}),"Text")
            }),"Main")
            local f=AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{Size=UDim2.new(1,0,0,38),Parent=ItemParent}),{
                AddThemeObject(SetProps(MakeElement("Label",BindConfig.Name,15),{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),Font=Enum.Font.FredokaOne,Name="Content"}),"Text"),
                AddThemeObject(MakeElement("Stroke"),"Stroke"),BBox,Click
            }),"Second")
            table.insert(SearchRegistry,{Name=BindConfig.Name, Tab=tabName, ActivateTab=nil})
            AddConnection(BBox.Value:GetPropertyChangedSignal("Text"),function() TweenService:Create(BBox,TweenInfo.new(0.25),{Size=UDim2.new(0,BBox.Value.TextBounds.X+16,0,24)}):Play() end)
            AddConnection(Click.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then if Bind.Binding then return end; Bind.Binding=true; BBox.Value.Text="" end end)
            AddConnection(UserInputService.InputBegan,function(i)
                if UserInputService:GetFocusedTextBox() then return end
                if (i.KeyCode.Name==Bind.Value or i.UserInputType.Name==Bind.Value) and not Bind.Binding then
                    if BindConfig.Hold then Holding=true; BindConfig.Callback(Holding) else BindConfig.Callback() end
                elseif Bind.Binding then
                    local Key; pcall(function() if not CheckKey(BlacklistedKeys,i.KeyCode) then Key=i.KeyCode end end)
                    pcall(function() if CheckKey(WhitelistedMouse,i.UserInputType) and not Key then Key=i.UserInputType end end)
                    Key=Key or Bind.Value; Bind:Set(Key); SaveCfg()
                end
            end)
            AddConnection(UserInputService.InputEnded,function(i)
                if i.KeyCode.Name==Bind.Value or i.UserInputType.Name==Bind.Value then
                    if BindConfig.Hold and Holding then Holding=false; BindConfig.Callback(Holding) end
                end
            end)
            function Bind:Set(Key) Bind.Binding=false; Bind.Value=Key or Bind.Value; Bind.Value=Bind.Value.Name or Bind.Value; BBox.Value.Text=Bind.Value end
            Bind:Set(BindConfig.Default)
            if BindConfig.Flag then Library.Flags[BindConfig.Flag]=Bind end
            return Bind
        end

        function ElementFunction:AddTextbox(TextboxConfig)
            TextboxConfig=TextboxConfig or {}
            TextboxConfig.Name=TextboxConfig.Name or "Textbox"; TextboxConfig.Default=TextboxConfig.Default or ""
            TextboxConfig.TextDisappear=TextboxConfig.TextDisappear or false; TextboxConfig.Callback=TextboxConfig.Callback or function() end
            local Click=SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
            local TBA=AddThemeObject(Create("TextBox",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,TextColor3=Color3.fromRGB(255,255,255),PlaceholderColor3=Color3.fromRGB(210,210,210),PlaceholderText="Input",Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Center,TextSize=14,ClearTextOnFocus=false}),"Text")
            local TC=AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,4),{Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-12,0.5,0),AnchorPoint=Vector2.new(1,0.5)}),{AddThemeObject(MakeElement("Stroke"),"Stroke"),TBA}),"Main")
            local f=AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{Size=UDim2.new(1,0,0,38),Parent=ItemParent}),{
                AddThemeObject(SetProps(MakeElement("Label",TextboxConfig.Name,15),{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),Font=Enum.Font.FredokaOne,Name="Content"}),"Text"),
                AddThemeObject(MakeElement("Stroke"),"Stroke"),TC,Click
            }),"Second")
            table.insert(SearchRegistry,{Name=TextboxConfig.Name, Tab=tabName, ActivateTab=nil})
            AddConnection(TBA:GetPropertyChangedSignal("Text"),function() TweenService:Create(TC,TweenInfo.new(0.45),{Size=UDim2.new(0,TBA.TextBounds.X+16,0,24)}):Play() end)
            AddConnection(TBA.FocusLost,function() TextboxConfig.Callback(TBA.Text); if TextboxConfig.TextDisappear then TBA.Text="" end end)
            TBA.Text=TextboxConfig.Default; AddConnection(Click.MouseButton1Up,function() TBA:CaptureFocus() end)
        end

        function ElementFunction:AddColorpicker(ColorpickerConfig)
            ColorpickerConfig=ColorpickerConfig or {}
            ColorpickerConfig.Name=ColorpickerConfig.Name or "Colorpicker"
            ColorpickerConfig.Default=ColorpickerConfig.Default or Color3.fromRGB(255,255,255)
            ColorpickerConfig.Callback=ColorpickerConfig.Callback or function() end
            ColorpickerConfig.Flag=ColorpickerConfig.Flag or nil; ColorpickerConfig.Save=ColorpickerConfig.Save or false
            local ColorH,ColorS,ColorV=1,1,1
            local CP={Value=ColorpickerConfig.Default,Toggled=false,Type="Colorpicker",Save=ColorpickerConfig.Save}
            local CSel=Create("ImageLabel",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(select(3,Color3.toHSV(CP.Value))),ScaleType=Enum.ScaleType.Fit,AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,Image="http://www.roblox.com/asset/?id=4805639000"})
            local HSel=Create("ImageLabel",{Size=UDim2.new(0,18,0,18),Position=UDim2.new(0.5,0,1-select(1,Color3.toHSV(CP.Value))),ScaleType=Enum.ScaleType.Fit,AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,Image="http://www.roblox.com/asset/?id=4805639000"})
            local Col=Create("ImageLabel",{Size=UDim2.new(1,-25,1,0),Visible=false,Image="rbxassetid://4155801252"},{Create("UICorner",{CornerRadius=UDim.new(0,5)}),CSel})
            local Hue=Create("Frame",{Size=UDim2.new(0,20,1,0),Position=UDim2.new(1,-20,0,0),Visible=false},{
                Create("UIGradient",{Rotation=270,Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,4)),ColorSequenceKeypoint.new(0.2,Color3.fromRGB(234,255,0)),ColorSequenceKeypoint.new(0.4,Color3.fromRGB(21,255,0)),ColorSequenceKeypoint.new(0.6,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(0.8,Color3.fromRGB(0,17,255)),ColorSequenceKeypoint.new(0.9,Color3.fromRGB(255,0,251)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,4))}}),
                Create("UICorner",{CornerRadius=UDim.new(0,5)}),HSel
            })
            local CPCont=Create("Frame",{Position=UDim2.new(0,0,0,32),Size=UDim2.new(1,0,1,-32),BackgroundTransparency=1,ClipsDescendants=true},{
                Hue,Col,Create("UIPadding",{PaddingLeft=UDim.new(0,35),PaddingRight=UDim.new(0,35),PaddingBottom=UDim.new(0,10),PaddingTop=UDim.new(0,17)})
            })
            local Click=SetProps(MakeElement("Button"),{Size=UDim2.new(1,0,1,0)})
            local CPBox=AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,4),{Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-12,0.5,0),AnchorPoint=Vector2.new(1,0.5)}),{AddThemeObject(MakeElement("Stroke"),"Stroke")}),"Main")
            local f=AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame",Color3.fromRGB(255,255,255),0,5),{Size=UDim2.new(1,0,0,38),Parent=ItemParent}),{
                SetProps(SetChildren(MakeElement("TFrame"),{
                    AddThemeObject(SetProps(MakeElement("Label",ColorpickerConfig.Name,15),{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,12,0,0),Font=Enum.Font.FredokaOne,Name="Content"}),"Text"),
                    CPBox,Click,AddThemeObject(SetProps(MakeElement("Frame"),{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),Name="Line",Visible=false}),"Stroke")
                }),{Size=UDim2.new(1,0,0,38),ClipsDescendants=true,Name="F"}),
                CPCont,AddThemeObject(MakeElement("Stroke"),"Stroke")
            }),"Second")
            table.insert(SearchRegistry,{Name=ColorpickerConfig.Name, Tab=tabName, ActivateTab=nil})
            AddConnection(Click.MouseButton1Click,function()
                CP.Toggled=not CP.Toggled
                TweenService:Create(f,TweenInfo.new(0.15),{Size=CP.Toggled and UDim2.new(1,0,0,148) or UDim2.new(1,0,0,38)}):Play()
                Col.Visible=CP.Toggled; Hue.Visible=CP.Toggled; f.F.Line.Visible=CP.Toggled
            end)
            local function UCP()
                CPBox.BackgroundColor3=Color3.fromHSV(ColorH,ColorS,ColorV)
                Col.BackgroundColor3=Color3.fromHSV(ColorH,1,1)
                CP:Set(CPBox.BackgroundColor3); ColorpickerConfig.Callback(CPBox.BackgroundColor3)
            end
            ColorH=1-(math.clamp(HSel.AbsolutePosition.Y-Hue.AbsolutePosition.Y,0,Hue.AbsoluteSize.Y)/Hue.AbsoluteSize.Y)
            ColorS=(math.clamp(CSel.AbsolutePosition.X-Col.AbsolutePosition.X,0,Col.AbsoluteSize.X)/Col.AbsoluteSize.X)
            ColorV=1-(math.clamp(CSel.AbsolutePosition.Y-Col.AbsolutePosition.Y,0,Col.AbsoluteSize.Y)/Col.AbsoluteSize.Y)
            local CI,HI
            AddConnection(Col.InputBegan,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then if CI then CI:Disconnect() end; CI=AddConnection(RunService.RenderStepped,function() local cx=(math.clamp(Mouse.X-Col.AbsolutePosition.X,0,Col.AbsoluteSize.X)/Col.AbsoluteSize.X); local cy=(math.clamp(Mouse.Y-Col.AbsolutePosition.Y,0,Col.AbsoluteSize.Y)/Col.AbsoluteSize.Y); CSel.Position=UDim2.new(cx,0,cy,0); ColorS=cx; ColorV=1-cy; UCP() end) end end)
            AddConnection(Col.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then if CI then CI:Disconnect() end end end)
            AddConnection(Hue.InputBegan,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then if HI then HI:Disconnect() end; HI=AddConnection(RunService.RenderStepped,function() local hy=(math.clamp(Mouse.Y-Hue.AbsolutePosition.Y,0,Hue.AbsoluteSize.Y)/Hue.AbsoluteSize.Y); HSel.Position=UDim2.new(0.5,0,hy,0); ColorH=1-hy; UCP() end) end end)
            AddConnection(Hue.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then if HI then HI:Disconnect() end end end)
            function CP:Set(v) CP.Value=v; CPBox.BackgroundColor3=CP.Value; ColorpickerConfig.Callback(CP.Value) end
            CP:Set(CP.Value)
            if ColorpickerConfig.Flag then Library.Flags[ColorpickerConfig.Flag]=CP end
            return CP
        end

        return ElementFunction
    end

    -- ── Internal: create a sidebar tab button ─────────────────────────────────
    local function MakeTabButton(name, icon, parent, layoutOrder)
        local btn = Create("TextButton",{
            Parent = parent,
            Size = UDim2.new(1,0,0,30),
            BackgroundColor3 = T.Accent,
            BackgroundTransparency = 1,
            Text = "",
            BorderSizePixel = 0,
            LayoutOrder = layoutOrder or 0,
            ZIndex = 4
        },{
            Create("UICorner",{CornerRadius=UDim.new(0,6)}),
            -- accent bar (left edge)
            Create("Frame",{
                Name="Bar",
                Size=UDim2.new(0,3,0,16),
                Position=UDim2.new(0,0,0.5,0),
                AnchorPoint=Vector2.new(0,0.5),
                BackgroundColor3=Color3.fromRGB(60,120,255),
                BorderSizePixel=0,
                BackgroundTransparency=1
            },{Create("UICorner",{CornerRadius=UDim.new(1,0)})})
        })

        local xOffset = 10
        if icon and icon ~= "" then
            Create("ImageLabel",{
                Parent=btn,
                Name="Ico",
                AnchorPoint=Vector2.new(0,0.5),
                Position=UDim2.new(0,xOffset,0.5,0),
                Size=UDim2.new(0,14,0,14),
                BackgroundTransparency=1,
                Image=icon,
                ImageColor3=T.Text,
                ImageTransparency=0.55,
                ZIndex=5
            })
            xOffset = xOffset + 20
        end

        Create("TextLabel",{
            Parent=btn,
            Name="Lbl",
            AnchorPoint=Vector2.new(0,0.5),
            Position=UDim2.new(0,xOffset,0.5,0),
            Size=UDim2.new(1,-xOffset-6,0,14),
            BackgroundTransparency=1,
            Text=name,
            TextColor3=T.Text,
            TextTransparency=0.45,
            TextSize=12,
            Font=Enum.Font.GothamSemibold,
            TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=5
        })

        return btn
    end

    -- ── MakeTab ────────────────────────────────────────────────────────────────
    local tabLayoutOrder = 0
    function TabFunction:MakeTab(TabConfig)
        TabConfig = TabConfig or {}
        TabConfig.Name        = TabConfig.Name        or "Tab"
        TabConfig.Icon        = TabConfig.Icon        or ""
        TabConfig.PremiumOnly = TabConfig.PremiumOnly or false

        tabLayoutOrder = tabLayoutOrder + 1
        local TabBtn = MakeTabButton(TabConfig.Name, TabConfig.Icon, SidebarScroll, tabLayoutOrder)

        -- Content scroll in right area
        local ItemContainer = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame",Color3.fromRGB(255,255,255),5),{
            Size=UDim2.new(1,0,1,0), Parent=ContentArea, Visible=false, Name="ItemContainer"
        }),{
            MakeElement("List",0,6),
            MakeElement("Padding",14,12,12,14)
        }),"Divider")

        AddConnection(ItemContainer.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
            ItemContainer.CanvasSize=UDim2.new(0,0,0,ItemContainer.UIListLayout.AbsoluteContentSize.Y+28)
        end)

        -- Click sound
        local ClickSound = Instance.new("Sound")
        ClickSound.SoundId = "rbxassetid://6895079853"
        ClickSound.Volume = 0.8
        ClickSound.Parent = TabBtn

        local function ActivateTab()
            ClickSound:Play()
            SetActiveTab(ItemContainer, TabConfig.Name, TabBtn)
        end

        -- update search registry entries with activateTab fn (after tab is created)
        local registeredCount = #SearchRegistry
        AddConnection(TabBtn.MouseButton1Click, ActivateTab)
        AddConnection(TabBtn.MouseEnter,function()
            if ItemContainer.Visible then return end
            TweenService:Create(TabBtn,TweenInfo.new(0.15),{BackgroundTransparency=0.94}):Play()
        end)
        AddConnection(TabBtn.MouseLeave,function()
            if ItemContainer.Visible then return end
            TweenService:Create(TabBtn,TweenInfo.new(0.15),{BackgroundTransparency=1}):Play()
        end)

        if FirstTab then FirstTab = false; ActivateTab() end

        -- Build element API
        local ElementFunction = {}
        function ElementFunction:AddSection(SectionConfig)
            SectionConfig.Name = SectionConfig.Name or "Section"
            local LabelRow = SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,0,16),ClipsDescendants=false})
            AddThemeObject(SetProps(MakeElement("Label",SectionConfig.Name,12),{Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,8,0,0),Font=Enum.Font.FredokaOne,Parent=LabelRow,TextTransparency=0.4}),"TextDark")
            local SecFrame=SetChildren(SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,0,26),Parent=ItemContainer}),{
                LabelRow,
                SetChildren(SetProps(MakeElement("TFrame"),{AnchorPoint=Vector2.new(0,0),Size=UDim2.new(1,0,1,-24),Position=UDim2.new(0,0,0,23),Name="Holder"}),{MakeElement("List",0,6)})
            })
            AddConnection(SecFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
                SecFrame.Size=UDim2.new(1,0,0,SecFrame.Holder.UIListLayout.AbsoluteContentSize.Y+31)
                SecFrame.Holder.Size=UDim2.new(1,0,0,SecFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
            end)
            local SF={}
            for i,v in next, GetElements(SecFrame.Holder, TabConfig.Name) do SF[i]=v end
            -- patch search registry after section items are added
            return SF
        end

        local baseElements = GetElements(ItemContainer, TabConfig.Name)
        for i,v in next, baseElements do ElementFunction[i]=v end

        if TabConfig.PremiumOnly then
            for i in next, ElementFunction do ElementFunction[i]=function() end end
            ItemContainer:FindFirstChild("UIListLayout"):Destroy(); ItemContainer:FindFirstChild("UIPadding"):Destroy()
            SetChildren(SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,1,0),Parent=ItemContainer}),{
                AddThemeObject(SetProps(MakeElement("Label","Unauthorised Access",14),{Size=UDim2.new(1,-38,0,14),Position=UDim2.new(0,38,0,18),TextTransparency=0.4}),"Text"),
                AddThemeObject(SetProps(MakeElement("Label","Premium Features",14),{Size=UDim2.new(1,-150,0,14),Position=UDim2.new(0,150,0,112),Font=Enum.Font.FredokaOne}),"Text"),
                AddThemeObject(SetProps(MakeElement("Label","This part of the script is locked to Premium users.",12),{Size=UDim2.new(1,-200,0,14),Position=UDim2.new(0,150,0,138),TextWrapped=true,TextTransparency=0.4}),"Text")
            })
        end

        -- patch search entries for this tab so they can jump to it
        task.defer(function()
            for _, entry in ipairs(SearchRegistry) do
                if entry.Tab == TabConfig.Name and not entry.ActivateTab then
                    entry.ActivateTab = ActivateTab
                end
            end
        end)

        return ElementFunction
    end

    -- ── MakeCategory ───────────────────────────────────────────────────────────
    -- Creates a collapsible category header in the sidebar with sub-tabs
    function TabFunction:MakeCategory(CategoryConfig)
        CategoryConfig = CategoryConfig or {}
        CategoryConfig.Name = CategoryConfig.Name or "Category"
        CategoryConfig.Icon = CategoryConfig.Icon or ""
        CategoryConfig.DefaultOpen = (CategoryConfig.DefaultOpen ~= false)

        tabLayoutOrder = tabLayoutOrder + 1

        local CategoryWrapper = Create("Frame",{
            Parent = SidebarScroll,
            Size = UDim2.new(1,0,0,28),  -- header + content
            BackgroundTransparency = 1,
            LayoutOrder = tabLayoutOrder,
            AutomaticSize = Enum.AutomaticSize.Y,
            ClipsDescendants = false
        },{
            Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)})
        })

        -- Category header button
        local CatHeader = Create("TextButton",{
            Parent = CategoryWrapper,
            Size = UDim2.new(1,0,0,26),
            BackgroundTransparency = 1,
            Text = "",
            LayoutOrder = 0,
            ZIndex = 3
        })

        local xOff = 8
        if CategoryConfig.Icon ~= "" then
            Create("ImageLabel",{
                Parent=CatHeader, AnchorPoint=Vector2.new(0,0.5),
                Position=UDim2.new(0,xOff,0.5,0), Size=UDim2.new(0,13,0,13),
                BackgroundTransparency=1, Image=CategoryConfig.Icon,
                ImageColor3=T.TextDark, ZIndex=4
            })
            xOff = xOff + 18
        end

        Create("TextLabel",{
            Parent=CatHeader,
            Position=UDim2.new(0,xOff,0.5,0), AnchorPoint=Vector2.new(0,0.5),
            Size=UDim2.new(1,-xOff-20,0,12),
            BackgroundTransparency=1,
            Text=CategoryConfig.Name:upper(),
            TextColor3=T.TextDark, TextSize=10,
            Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=4
        })

        -- Arrow chevron
        local ChevronLbl = Create("TextLabel",{
            Parent=CatHeader,
            Position=UDim2.new(1,-16,0.5,0), AnchorPoint=Vector2.new(0,0.5),
            Size=UDim2.new(0,12,0,12),
            BackgroundTransparency=1, Text="▾",
            TextColor3=T.TextDark, TextSize=11, Font=Enum.Font.GothamBold,
            ZIndex=4
        })

        -- Container for sub-tabs
        local SubContainer = Create("Frame",{
            Parent=CategoryWrapper,
            Size=UDim2.new(1,0,0,0),
            BackgroundTransparency=1,
            AutomaticSize=Enum.AutomaticSize.Y,
            LayoutOrder=1,
            Visible=CategoryConfig.DefaultOpen,
            ClipsDescendants=false
        },{
            Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)}),
            Create("UIPadding",{PaddingLeft=UDim.new(0,8)})
        })

        local IsOpen = CategoryConfig.DefaultOpen
        AddConnection(CatHeader.MouseButton1Click, function()
            IsOpen = not IsOpen
            SubContainer.Visible = IsOpen
            TweenService:Create(ChevronLbl,TweenInfo.new(0.2),{Rotation=IsOpen and 0 or -90}):Play()
        end)

        -- Return a sub-function that creates tabs inside this category
        local CategoryFunction = {}
        local catTabOrder = 0

        function CategoryFunction:MakeTab(TabConfig)
            TabConfig = TabConfig or {}
            TabConfig.Name        = TabConfig.Name        or "Tab"
            TabConfig.Icon        = TabConfig.Icon        or ""
            TabConfig.PremiumOnly = TabConfig.PremiumOnly or false

            catTabOrder = catTabOrder + 1
            local TabBtn = MakeTabButton(TabConfig.Name, TabConfig.Icon, SubContainer, catTabOrder)

            local ItemContainer = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame",Color3.fromRGB(255,255,255),5),{
                Size=UDim2.new(1,0,1,0), Parent=ContentArea, Visible=false, Name="ItemContainer"
            }),{
                MakeElement("List",0,6),
                MakeElement("Padding",14,12,12,14)
            }),"Divider")

            AddConnection(ItemContainer.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
                ItemContainer.CanvasSize=UDim2.new(0,0,0,ItemContainer.UIListLayout.AbsoluteContentSize.Y+28)
            end)

            local ClickSound = Instance.new("Sound")
            ClickSound.SoundId="rbxassetid://6895079853"; ClickSound.Volume=0.8; ClickSound.Parent=TabBtn

            local function ActivateTab()
                ClickSound:Play()
                -- ensure category is open
                if not IsOpen then
                    IsOpen = true; SubContainer.Visible = true
                    TweenService:Create(ChevronLbl,TweenInfo.new(0.2),{Rotation=0}):Play()
                end
                SetActiveTab(ItemContainer, TabConfig.Name, TabBtn)
            end

            AddConnection(TabBtn.MouseButton1Click, ActivateTab)
            AddConnection(TabBtn.MouseEnter,function()
                if ItemContainer.Visible then return end
                TweenService:Create(TabBtn,TweenInfo.new(0.15),{BackgroundTransparency=0.94}):Play()
            end)
            AddConnection(TabBtn.MouseLeave,function()
                if ItemContainer.Visible then return end
                TweenService:Create(TabBtn,TweenInfo.new(0.15),{BackgroundTransparency=1}):Play()
            end)

            if FirstTab then FirstTab=false; ActivateTab() end

            local ElementFunction={}
            function ElementFunction:AddSection(SectionConfig)
                SectionConfig.Name=SectionConfig.Name or "Section"
                local LR=SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,0,16),ClipsDescendants=false})
                AddThemeObject(SetProps(MakeElement("Label",SectionConfig.Name,12),{Size=UDim2.new(1,-10,1,0),Position=UDim2.new(0,8,0,0),Font=Enum.Font.FredokaOne,Parent=LR,TextTransparency=0.4}),"TextDark")
                local SF=SetChildren(SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,0,26),Parent=ItemContainer}),{
                    LR,
                    SetChildren(SetProps(MakeElement("TFrame"),{AnchorPoint=Vector2.new(0,0),Size=UDim2.new(1,0,1,-24),Position=UDim2.new(0,0,0,23),Name="Holder"}),{MakeElement("List",0,6)})
                })
                AddConnection(SF.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"),function()
                    SF.Size=UDim2.new(1,0,0,SF.Holder.UIListLayout.AbsoluteContentSize.Y+31)
                    SF.Holder.Size=UDim2.new(1,0,0,SF.Holder.UIListLayout.AbsoluteContentSize.Y)
                end)
                local s={}; for i,v in next,GetElements(SF.Holder,TabConfig.Name) do s[i]=v end; return s
            end
            for i,v in next,GetElements(ItemContainer,TabConfig.Name) do ElementFunction[i]=v end

            if TabConfig.PremiumOnly then
                for i in next,ElementFunction do ElementFunction[i]=function() end end
                ItemContainer:FindFirstChild("UIListLayout"):Destroy(); ItemContainer:FindFirstChild("UIPadding"):Destroy()
                SetChildren(SetProps(MakeElement("TFrame"),{Size=UDim2.new(1,0,1,0),Parent=ItemContainer}),{
                    AddThemeObject(SetProps(MakeElement("Label","Unauthorised Access",14),{Size=UDim2.new(1,-38,0,14),Position=UDim2.new(0,38,0,18),TextTransparency=0.4}),"Text"),
                    AddThemeObject(SetProps(MakeElement("Label","Premium Features",14),{Size=UDim2.new(1,-150,0,14),Position=UDim2.new(0,150,0,112),Font=Enum.Font.FredokaOne}),"Text"),
                })
            end

            task.defer(function()
                for _,entry in ipairs(SearchRegistry) do
                    if entry.Tab==TabConfig.Name and not entry.ActivateTab then
                        entry.ActivateTab=ActivateTab
                    end
                end
            end)

            return ElementFunction
        end

        return CategoryFunction
    end

    return TabFunction
end

function Library:Destroy()
    Container:Destroy()
end

return Library
