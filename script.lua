local HS = {}


local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

local Env = (getgenv and getgenv()) or _G
if Env.HyperSunUnload then
pcall(Env.HyperSunUnload)
end
pcall(function() RunService:UnbindFromRenderStep("HyperSunAim") end)

local function GetRoot()
if gethui then
local ok, r = pcall(gethui)
if ok and r then return r end
end
local ok = pcall(function()
local g = Instance.new("ScreenGui")
g.Parent = CoreGui
g:Destroy()
end)
if ok then return CoreGui end
return LocalPlayer:WaitForChild("PlayerGui")
end

local Root = GetRoot()
local function ClearTableCompat(t)
for k in pairs(t) do
t[k] = nil
end
end

for _, name in ipairs({ "HyperSunUI", "HyperSunNotify" }) do
pcall(function()
local o = Root:FindFirstChild(name)
if o then o:Destroy() end
end)
end

local HasDrawing = false
pcall(function()
local t = Drawing.new("Line")
t:Remove()
HasDrawing = true
end)

local C = {
Panel = Color3.fromRGB(8, 8, 10),
Item = Color3.fromRGB(24, 15, 17),
Tab = Color3.fromRGB(30, 13, 16),
Accent = Color3.fromRGB(255, 45, 65),
Text = Color3.fromRGB(245, 242, 243),
Sub = Color3.fromRGB(177, 155, 160),
Off = Color3.fromRGB(55, 35, 39),
Knob = Color3.fromRGB(255, 255, 255)
}
local FONT_B = Enum.Font.GothamBlack
local FONT_N = Enum.Font.GothamSemibold
local FONT_TITLE = Enum.Font.GothamBlack
local TI = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local WIN_W, WIN_H = 470, 370
local TITLE_RICH = '<font color="#FF334D">✦ HyperSun</font> <font color="#FFFFFF">2.4 Elite Beta</font>'

local State = {
Features = { Apply = false, Aimbot = false, ESP = false, Bypass = false, TeamCheck = false, WallCheck = false },
ESP = { Skeleton = false, Box = false, Count = false, Line = false, Name = false, Health = false, MaxDist = 2000 },
Aimbot = { FOV = 120, Lock = false, Smooth = 100, Head = true, ShowFOV = true },
Memory = {
FlyHeight = 5, FlySpeed = 50, TeleSkyHeight = 100,
InSky = false, OldPos = nil, FlyEnabled = false, Up = false, Down = false, SpeedTime = false, TeleWallBusy = false, FlyUpX2 = false,
LockNV = false, LockNVData = nil, FastTalk = false, FastAttack = false, TeleSky2 = false, TeleSky2Data = nil
},
Under = { Enabled = false, Depth = 30, Speed = 40, Hide = true, Duration = 0, RunToken = 0, Y = nil, GroundY = nil, OverPos = nil },
Player = {
Speed = 16, Jump = 50, SpeedOn = false, JumpOn = false,
InfJump = false, Noclip = false, AntiAFK = false,
DefSpeed = 16, DefJump = 50
},
Chams = { Mode = "None" },
Settings = { Sound = true, Volume = 80 }
}

local Connections = {}
local Drawings = {}
local ESPObjects = {}
HS.ChamObjs = {}
HS.UnderHidden = {}
HS.LightOrig = nil
local Unloaded = false

local function Create(class, props, parent)
local inst = Instance.new(class)
for k, v in pairs(props) do inst[k] = v end
inst.Parent = parent
return inst
end

local function GetHRP()
local c = LocalPlayer.Character
return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
end

local function Alive(plr)
local c = plr.Character
if not c then return false end
local h = c:FindFirstChildOfClass("Humanoid")
return c:FindFirstChild("HumanoidRootPart") ~= nil and h ~= nil and h.Health > 0
end

local function IsEnemy(plr)
if not State.Features.TeamCheck then return true end
if plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return false end
return true
end

HS.ClickSound = Instance.new("Sound")
HS.ClickSound.Name = "HyperSunClick"
HS.ClickSound.Volume = 0.95
HS.ClickSound.PlaybackSpeed = 0.72
HS.ClickSound.SoundId = "rbxasset://sounds/button.wav"
HS.ClickSound.Parent = SoundService
HS.ClickEcho = Instance.new("EchoSoundEffect")
HS.ClickEcho.Delay = 0.12
HS.ClickEcho.Feedback = 0.22
HS.ClickEcho.WetLevel = -10
HS.ClickEcho.DryLevel = 0
HS.ClickEcho.Parent = HS.ClickSound

task.spawn(function()
local candidates = {
"rbxasset://sounds/button.wav",
"rbxasset://sounds/switch.wav",
"rbxasset://sounds/clickfast.wav"
}
for _, id in ipairs(candidates) do
if Unloaded then return end
HS.ClickSound.SoundId = id
pcall(function() ContentProvider:PreloadAsync({ HS.ClickSound }) end)
if HS.ClickSound.TimeLength > 0 then return end
end
HS.ClickSound.SoundId = candidates[1]
end)

local function Click()
if not State.Settings.Sound or Unloaded then return end
pcall(function()
HS.ClickSound.Volume = math.clamp(State.Settings.Volume / 100 * 1.12, 0, 1)
HS.ClickSound.PlaybackSpeed = 0.72
HS.ClickSound.TimePosition = 0
HS.ClickSound:Play()
end)
end

HS.NotifyGui = Create("ScreenGui", { Name = "HyperSunNotify", ResetOnSpawn = false, IgnoreGuiInset = true }, Root)
HS.NotifyContainer = Create("Frame", {
BackgroundTransparency = 1, Position = UDim2.new(1, -20, 0, 42),
AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0, 260, 1, -62)
}, HS.NotifyGui)
Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }, HS.NotifyContainer)

local function Notify(title, text, duration)
duration = duration or 5
if Unloaded then return end
local frame = Create("Frame", {
Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.Panel,
BackgroundTransparency = 0.04, BorderSizePixel = 0, Position = UDim2.new(0, 24, 0, 0)
}, HS.NotifyContainer)
Create("UICorner", { CornerRadius = UDim.new(0, 11) }, frame)
Create("UIStroke", { Color = C.Accent, Thickness = 1.35, Transparency = 0.12 }, frame)
Create("UIGradient", { Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(33, 28, 62)), ColorSequenceKeypoint.new(1, C.Panel)}), Rotation = 15 }, frame)
TweenService:Create(frame, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
Create("TextLabel", {
BackgroundTransparency = 1, Size = UDim2.new(1, -18, 0, 21), Position = UDim2.new(0, 12, 0, 5),
Font = FONT_B, TextColor3 = C.Text, TextSize = 14,
TextXAlignment = Enum.TextXAlignment.Left, Text = title
}, frame)
Create("TextLabel", {
BackgroundTransparency = 1, Size = UDim2.new(1, -18, 0, 16), Position = UDim2.new(0, 12, 0, 27),
Font = FONT_N, TextColor3 = C.Sub, TextSize = 12,
TextXAlignment = Enum.TextXAlignment.Left, Text = text
}, frame)
local barBg = Create("Frame", {
Size = UDim2.new(1, -20, 0, 2), Position = UDim2.new(0, 10, 1, -8),
BackgroundColor3 = Color3.fromRGB(50, 50, 50), BorderSizePixel = 0
}, frame)
local barFill = Create("Frame", {
Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.Accent, BorderSizePixel = 0
}, barBg)
TweenService:Create(barFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) }):Play()
task.delay(duration, function()
if frame and frame.Parent then
TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1, Position = UDim2.new(0, 30, 0, 0) }):Play()
task.wait(0.24)
pcall(function() frame:Destroy() end)
end
end)
end

HS.Invis = { Enabled = false, Saved = {}, AddedConn = nil, NameMode = nil }
HS.InvisToggle = nil
HS.InvisFloat = nil

function HS.InvisSave(inst, property)
if HS.Invis.Saved[inst] == nil then
local ok, value = pcall(function() return inst[property] end)
if ok then HS.Invis.Saved[inst] = { property = property, value = value } end
end
end

function HS.InvisHide(inst)
if inst:IsA("BasePart") then
HS.InvisSave(inst, "LocalTransparencyModifier")
pcall(function() inst.LocalTransparencyModifier = 1 end)
elseif inst:IsA("Decal") or inst:IsA("Texture") then
HS.InvisSave(inst, "Transparency")
pcall(function() inst.Transparency = 1 end)
elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
HS.InvisSave(inst, "Enabled")
pcall(function() inst.Enabled = false end)
end
end

function HS.InvisApplyCharacter(char)
if not char or not HS.Invis.Enabled then return end
for _, inst in ipairs(char:GetDescendants()) do
HS.InvisHide(inst)
end
if HS.Invis.AddedConn then
pcall(function() HS.Invis.AddedConn:Disconnect() end)
HS.Invis.AddedConn = nil
end
HS.Invis.AddedConn = char.DescendantAdded:Connect(function(inst)
if HS.Invis.Enabled then task.defer(function() if HS.Invis.Enabled and inst.Parent then HS.InvisHide(inst) end end) end
end)
local hum = char:FindFirstChildOfClass("Humanoid")
if hum then
pcall(function()
HS.Invis.NameMode = hum.DisplayDistanceType
hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
end)
end
end

function HS.InvisRestore()
if HS.Invis.AddedConn then pcall(function() HS.Invis.AddedConn:Disconnect() end); HS.Invis.AddedConn = nil end
for inst, rec in pairs(HS.Invis.Saved) do
if inst and inst.Parent then pcall(function() inst[rec.property] = rec.value end) end
end
ClearTableCompat(HS.Invis.Saved)
local char = LocalPlayer.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
if hum and HS.Invis.NameMode ~= nil then pcall(function() hum.DisplayDistanceType = HS.Invis.NameMode end) end
HS.Invis.NameMode = nil
end

function HS.Invis.Set(on)
on = on and true or false
if on == HS.Invis.Enabled then
if HS.InvisToggle then HS.InvisToggle.Set(on, false) end
if HS.InvisFloat then HS.InvisFloat.SetOn(on) end
return
end
HS.Invis.Enabled = on
if on then
local char = LocalPlayer.Character
if not char then
HS.Invis.Enabled = false
Notify("Invisibility", "Nhân vật chưa sẵn sàng", 4)
else
HS.InvisApplyCharacter(char)
Notify("Invisibility", "Đã ẩn nhân vật trên màn hình của bạn", 4)
end
else
HS.InvisRestore()
Notify("Invisibility", "Đã khôi phục hiển thị nhân vật", 3)
end
if HS.InvisToggle then HS.InvisToggle.Set(HS.Invis.Enabled, false) end
if HS.InvisFloat then HS.InvisFloat.SetOn(HS.Invis.Enabled) end
end

Connections[#Connections + 1] = LocalPlayer.CharacterAdded:Connect(function(char)
task.wait(0.5)
if HS.Invis.Enabled then
ClearTableCompat(HS.Invis.Saved)
HS.InvisApplyCharacter(char)
end
end)

HS.Banner = Create("Frame", {
Size = UDim2.new(0, 178, 0, 26), Position = UDim2.new(1, -10, 0, 8), AnchorPoint = Vector2.new(1, 0),
BackgroundColor3 = C.Panel, BackgroundTransparency = 0.2, BorderSizePixel = 0, Visible = false
}, HS.NotifyGui)
Create("UICorner", { CornerRadius = UDim.new(0, 8) }, HS.Banner)
Create("UIStroke", { Color = Color3.fromRGB(255, 213, 0), Thickness = 1, Transparency = 0.5 }, HS.Banner)
HS.BannerText = Create("TextLabel", {
Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, RichText = true, Text = TITLE_RICH,
TextColor3 = Color3.new(1, 1, 1), Font = FONT_B, TextSize = 14
}, HS.Banner)

HS.BannerActive = false
HS.BannerRunning = false
function HS.SetBanner(on)
HS.BannerActive = on and true or false
HS.Banner.Visible = HS.BannerActive
HS.BannerText.TextTransparency = 0
if HS.BannerActive and not HS.BannerRunning then
HS.BannerRunning = true
task.spawn(function()
while HS.BannerActive and not Unloaded do
task.wait(1.7)
if not HS.BannerActive or Unloaded then break end
TweenService:Create(HS.BannerText, TweenInfo.new(0.1), { TextTransparency = 1 }):Play()
task.wait(0.12)
TweenService:Create(HS.BannerText, TweenInfo.new(0.1), { TextTransparency = 0 }):Play()
task.wait(0.1)
end
HS.BannerRunning = false
end)
end
end

task.spawn(function()
task.wait(4)
if Unloaded then return end
Notify("HyperSun loaded", "HyperSun 2.4 Beta", 5)
task.wait(5)
if Unloaded then return end
Notify("Lib loading", "HyperSun 2.4 Beta", 5)
task.wait(5)
if Unloaded then return end
Notify("64bit", "HyperSun 2.4 Beta", 5)
if not HasDrawing then
task.wait(5)
Notify("Cảnh báo", "Executor không có Drawing: ESP/FOV tắt", 5)
end
end)

local function MakeDraggable(frame, dragFrame)
local dragging, dragInput, dragStart, startPos
dragFrame.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragStart = input.Position
startPos = frame.Position
input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then dragging = false end
end)
end
end)
dragFrame.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
dragInput = input
end
end)
Connections[#Connections + 1] = UserInputService.InputChanged:Connect(function(input)
if input == dragInput and dragging then
local d = input.Position - dragStart
frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
end
end)
end

local function OnTap(btn, fn)
local startPos
btn.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
startPos = i.Position
end
end)
btn.InputEnded:Connect(function(i)
if (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) and startPos then
if (i.Position - startPos).Magnitude < 12 then
Click()
task.spawn(fn)
end
startPos = nil
end
end)
end

local ScreenGui = Create("ScreenGui", { Name = "HyperSunUI", ResetOnSpawn = false, IgnoreGuiInset = true }, Root)

local Main = Create("Frame", {
Size = UDim2.new(0, WIN_W, 0, WIN_H), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.06, BorderSizePixel = 0, ClipsDescendants = true
}, ScreenGui)
Create("UICorner", { CornerRadius = UDim.new(0, 12) }, Main)
Create("UIStroke", { Color = Color3.fromRGB(255, 45, 65), Thickness = 1.8, Transparency = 0.08 }, Main)
Create("UIGradient", {
Color = ColorSequence.new(Color3.fromRGB(48, 9, 16), Color3.fromRGB(7, 7, 9)),
Rotation = 90
}, Main)

local vp = Camera.ViewportSize
HS.startScale = math.clamp((vp.Y - 24) / WIN_H, 0.5, 1.2)
HS.MainScale = Create("UIScale", { Scale = HS.startScale }, Main)

HS.TopBar = Create("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 }, Main)
HS.CollapseBtn = Create("TextButton", {
Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(0, 2, 0, 0), BackgroundTransparency = 1,
Text = "▼", TextColor3 = C.Text, Font = FONT_B, TextSize = 15, ZIndex = 3
}, HS.TopBar)
Create("TextLabel", {
Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 38, 0, 0), BackgroundTransparency = 1,
RichText = true, Text = TITLE_RICH, TextColor3 = C.Text, Font = FONT_B, TextSize = 15,
TextXAlignment = Enum.TextXAlignment.Left
}, HS.TopBar)
HS.CloseBtn = Create("TextButton", {
Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(1, -36, 0, 0), BackgroundTransparency = 1,
Text = "X", TextColor3 = C.Sub, Font = FONT_B, TextSize = 15, ZIndex = 3
}, HS.TopBar)
Create("Frame", {
Size = UDim2.new(1, -16, 0, 1), Position = UDim2.new(0, 8, 1, -1),
BackgroundColor3 = Color3.fromRGB(255, 45, 65), BackgroundTransparency = 0.28, BorderSizePixel = 0
}, HS.TopBar)

MakeDraggable(Main, HS.TopBar)

HS.Body = Create("Frame", {
Size = UDim2.new(1, 0, 1, -36), Position = UDim2.new(0, 0, 0, 36), BackgroundTransparency = 1
}, Main)

HS.Sidebar = Create("ScrollingFrame", {
Size = UDim2.new(0, 114, 1, -38), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1,
BorderSizePixel = 0, ScrollBarThickness = 0,
CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
}, HS.Body)
Create("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, HS.Sidebar)

local Content = Create("ScrollingFrame", {
Size = UDim2.new(1, -136, 1, -38), Position = UDim2.new(0, 128, 0, 0),
BackgroundColor3 = Color3.fromRGB(10, 7, 8), BackgroundTransparency = 0.18,
BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Accent,
CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
}, HS.Body)
Create("UICorner", { CornerRadius = UDim.new(0, 9) }, Content)
Create("UIPadding", {
PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 10)
}, Content)

HS.Footer = Create("Frame", {
Size = UDim2.new(1, -16, 0, 24), Position = UDim2.new(0, 8, 1, -28),
BackgroundColor3 = C.Panel, BackgroundTransparency = 0.3, BorderSizePixel = 0
}, HS.Body)
Create("UICorner", { CornerRadius = UDim.new(0, 7) }, HS.Footer)
HS.FooterStats = Create("TextLabel", {
Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1,
Text = "FPS --  |  Ping -- ms  |  Players --", TextColor3 = C.Sub, Font = FONT_N, TextSize = 12,
TextXAlignment = Enum.TextXAlignment.Left
}, HS.Footer)
Create("TextLabel", {
Size = UDim2.new(0.4, -10, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), BackgroundTransparency = 1,
RichText = true, Text = TITLE_RICH, TextColor3 = C.Text, Font = FONT_B, TextSize = 12,
TextXAlignment = Enum.TextXAlignment.Right
}, HS.Footer)

HS.MenuIcon = Create("TextButton", {
Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(0, 14, 0.5, -24), BackgroundColor3 = C.Panel,
Text = "✦", TextColor3 = Color3.fromRGB(255, 255, 255), Font = FONT_B, TextSize = 27, Visible = false
}, ScreenGui)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, HS.MenuIcon)
Create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 35, 58), Color3.fromRGB(105, 5, 18)), Rotation = 35 }, HS.MenuIcon)
Create("UIStroke", { Color = Color3.fromRGB(255, 65, 82), Thickness = 2 }, HS.MenuIcon)
MakeDraggable(HS.MenuIcon, HS.MenuIcon)

-- Animated startup title: letter-by-letter reveal with a red glow.
task.spawn(function()
    if Unloaded or not ScreenGui.Parent then return end
    local splash = Create("Frame", {
        Name = "HyperSunIntro", Size = UDim2.new(0, 300, 0, 76),
        Position = UDim2.new(0.5, 0, 0.38, 0), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(8, 6, 8), BackgroundTransparency = 0.08,
        BorderSizePixel = 0, ZIndex = 80
    }, ScreenGui)
    Create("UICorner", { CornerRadius = UDim.new(0, 14) }, splash)
    Create("UIStroke", { Color = Color3.fromRGB(255, 45, 65), Thickness = 2, Transparency = 0.12 }, splash)
    local glow = Create("UIGradient", {
        Color = ColorSequence.new(Color3.fromRGB(48, 8, 16), Color3.fromRGB(8, 8, 10)), Rotation = 15
    }, splash)
    local title = Create("TextLabel", {
        Size = UDim2.new(1, -18, 1, -8), Position = UDim2.new(0, 9, 0, 4),
        BackgroundTransparency = 1, Text = "", RichText = true, TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.GothamBlack, TextSize = 22, TextWrapped = true, ZIndex = 81
    }, splash)
    local full = "Hyper Sun 2.3 ELITE"
    for i = 1, #full do
        if Unloaded or not splash.Parent then break end
        local part = string.sub(full, 1, i)
        local splitAt = math.min(#part, 10)
        local brand = string.sub(part, 1, splitAt)
        local edition = string.sub(part, splitAt + 1)
        title.Text = '<font color="#FF263F">' .. brand .. '</font><font color="#FFFFFF">' .. edition .. '</font>'
        title.TextStrokeColor3 = Color3.fromRGB(255, 30, 55)
        title.TextStrokeTransparency = 0.45
        task.wait(0.065)
    end
    if splash.Parent then
        task.wait(1.1)
        TweenService:Create(splash, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        TweenService:Create(title, TweenInfo.new(0.45), {TextTransparency = 1}):Play()
        task.wait(0.5)
        if splash.Parent then splash:Destroy() end
    end
end)

local Collapsed = false
HS.CollapseBtn.MouseButton1Click:Connect(function()
Click()
Collapsed = not Collapsed
HS.Body.Visible = not Collapsed
HS.CollapseBtn.Text = Collapsed and "▶" or "▼"
Main.Size = Collapsed and UDim2.new(0, WIN_W, 0, 36) or UDim2.new(0, WIN_W, 0, WIN_H)
end)

HS.CloseBtn.MouseButton1Click:Connect(function()
Click()
Main.Visible = false
HS.MenuIcon.Visible = true
end)
OnTap(HS.MenuIcon, function()
HS.MenuIcon.Visible = false
Main.Visible = true
end)

Connections[#Connections + 1] = UserInputService.InputBegan:Connect(function(input, gpe)
if gpe then return end
if input.KeyCode == Enum.KeyCode.RightShift then
local show = not Main.Visible
Main.Visible = show
HS.MenuIcon.Visible = not show
end
end)

local Tabs = {}
local function SelectTab(name)
for n, t in pairs(Tabs) do
local on = (n == name)
t.Frame.Visible = on
t.Btn.BackgroundColor3 = on and C.Accent or C.Tab
t.Btn.TextColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(200, 200, 200)
end
Content.CanvasPosition = Vector2.new(0, 0)
end

local function CreateTab(name)
local btn = Create("TextButton", {
Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.Tab, BackgroundTransparency = 0.1, Text = name,
TextColor3 = Color3.fromRGB(200, 200, 200), Font = FONT_B, TextSize = 14, AutoButtonColor = false
}, HS.Sidebar)
Create("UICorner", { CornerRadius = UDim.new(0, 7) }, btn)
local frame = Create("Frame", {
Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false
}, Content)
Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
Tabs[name] = { Btn = btn, Frame = frame }
btn.MouseEnter:Connect(function()
if Tabs[name] and Tabs[name].Frame.Visible then return end
TweenService:Create(btn, TI, {BackgroundTransparency = 0}):Play()
end)
btn.MouseLeave:Connect(function()
TweenService:Create(btn, TI, {BackgroundTransparency = 0.1}):Play()
end)
btn.MouseButton1Click:Connect(function()
Click()
SelectTab(name)
end)
return frame
end

local function CreateHeader(parent, text)
local h = Create("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1 }, parent)
Create("Frame", {
Size = UDim2.new(0, 3, 0, 12), Position = UDim2.new(0, 2, 0.5, -6),
BackgroundColor3 = C.Accent, BorderSizePixel = 0
}, h)
Create("TextLabel", {
Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1,
Text = text, TextColor3 = C.Accent, Font = FONT_B, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
}, h)
return h
end

local function CreateLabel(parent, text, color)
return Create("TextLabel", {
Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = text,
TextColor3 = color or C.Sub, Font = FONT_N, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
RichText = true
}, parent)
end

function HS.BuildSwitch(parent, pos, on)
local track = Create("Frame", {
Size = UDim2.new(0, 46, 0, 24), Position = pos, AnchorPoint = Vector2.new(1, 0.5),
BackgroundColor3 = on and C.Accent or C.Off, BorderSizePixel = 0
}, parent)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
Create("UIGradient", {
Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(185, 185, 185)), Rotation = 90
}, track)
local knob = Create("Frame", {
Size = UDim2.new(0, 20, 0, 20),
Position = on and UDim2.new(0, 24, 0.5, -10) or UDim2.new(0, 2, 0.5, -10),
BackgroundColor3 = C.Knob, BorderSizePixel = 0
}, track)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
local sw = {}
function sw.Set(v)
TweenService:Create(track, TI, { BackgroundColor3 = v and C.Accent or C.Off }):Play()
TweenService:Create(knob, TI, { Position = v and UDim2.new(0, 24, 0.5, -10) or UDim2.new(0, 2, 0.5, -10) }):Play()
end
return sw
end

local function CreateToggle(parent, text, default, callback)
local row = Create("TextButton", {
Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.Item, BackgroundTransparency = 0.2,
Text = "", AutoButtonColor = false
}, parent)
Create("UICorner", { CornerRadius = UDim.new(0, 7) }, row)
Create("TextLabel", {
Size = UDim2.new(1, -68, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
Text = text, TextColor3 = C.Text, Font = FONT_N, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd
}, row)
local sw = HS.BuildSwitch(row, UDim2.new(1, -10, 0.5, 0), default)
local state = default
local obj = {}
function obj.Set(v, fire)
state = v and true or false
sw.Set(state)
if fire and callback then task.spawn(callback, state) end
end
function obj.Get() return state end
row.MouseEnter:Connect(function()
TweenService:Create(row, TI, {BackgroundTransparency = 0.04}):Play()
end)
row.MouseLeave:Connect(function()
TweenService:Create(row, TI, {BackgroundTransparency = 0.2}):Play()
end)
row.MouseButton1Click:Connect(function()
Click()
obj.Set(not state, true)
end)
return obj
end

local function CreateSlider(parent, text, min, max, default, callback)
local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = C.Item, BackgroundTransparency = 0.2 }, parent)
Create("UICorner", { CornerRadius = UDim.new(0, 7) }, frame)
Create("TextLabel", {
Size = UDim2.new(1, -76, 0, 22), Position = UDim2.new(0, 12, 0, 5), BackgroundTransparency = 1,
Text = text, TextColor3 = C.Text, Font = FONT_N, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd
}, frame)
local valLbl = Create("TextLabel", {
Size = UDim2.new(0, 60, 0, 22), Position = UDim2.new(1, -70, 0, 5), BackgroundTransparency = 1,
Text = tostring(default), TextColor3 = C.Accent, Font = FONT_B, TextSize = 14,
TextXAlignment = Enum.TextXAlignment.Right
}, frame)
local bar = Create("TextButton", {
Size = UDim2.new(1, -24, 0, 7), Position = UDim2.new(0, 12, 1, -16), BackgroundColor3 = C.Off,
Text = "", AutoButtonColor = false
}, frame)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
local fill = Create("Frame", {
Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = C.Accent, BorderSizePixel = 0
}, bar)
Create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

local dragging = false
local function update(input)
local w = math.max(bar.AbsoluteSize.X, 1)
local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / w, 0, 1)
local val = math.floor(min + (max - min) * pos + 0.5)
fill.Size = UDim2.new(pos, 0, 1, 0)
valLbl.Text = tostring(val)
if callback then task.spawn(callback, val) end
end
bar.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
Content.ScrollingEnabled = false
Click()
update(input)
end
end)
Connections[#Connections + 1] = UserInputService.InputChanged:Connect(function(input)
if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
update(input)
end
end)
Connections[#Connections + 1] = UserInputService.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
if dragging then
dragging = false
Content.ScrollingEnabled = true
end
end
end)
end

local function CreateButton(parent, text, callback)
local b = Create("TextButton", {
Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.Item, BackgroundTransparency = 0.2, Text = text,
TextColor3 = C.Text, Font = FONT_N, TextSize = 14, AutoButtonColor = false
}, parent)
Create("UICorner", { CornerRadius = UDim.new(0, 7) }, b)
b.MouseButton1Click:Connect(function()
Click()
if callback then task.spawn(callback) end
end)
return b
end

HS.FloatingFrames = {}
function HS.RefreshFloatPositions()
local visible = {}
for _, frame in ipairs(HS.FloatingFrames) do
if frame and frame.Parent and frame.Visible then table.insert(visible, frame) end
end
local step = 44
for i, frame in ipairs(visible) do
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, (i - (#visible + 1) / 2) * step)
frame.ZIndex = 50 + i
end
end
function HS.CreateFloat(label, y)
local f = Create("Frame", {
Size = UDim2.new(0, 150, 0, 36), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.Panel,
BackgroundTransparency = 0.1, Visible = false, ZIndex = 50
}, ScreenGui)
table.insert(HS.FloatingFrames, f)
Create("UICorner", { CornerRadius = UDim.new(0, 9) }, f)
Create("UIStroke", { Color = C.Accent, Thickness = 1, Transparency = 0.4 }, f)
Create("TextLabel", {
Size = UDim2.new(1, -66, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
Text = label, TextColor3 = C.Text, Font = FONT_B, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd
}, f)
local sw = HS.BuildSwitch(f, UDim2.new(1, -10, 0.5, 0), false)
MakeDraggable(f, f)
local obj = { Frame = f }
function obj.Show(v)
f.Visible = v and true or false
HS.RefreshFloatPositions()
end
function obj.SetOn(v) sw.Set(v) end
function obj.OnTap(fn) OnTap(f, fn) end
function obj.Hold(key)
f.InputBegan:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
State.Memory[key] = true
sw.Set(true)
Click()
end
end)
f.InputEnded:Connect(function(i)
if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
State.Memory[key] = false
sw.Set(false)
end
end)
end
function obj.Flash()
sw.Set(true)
task.delay(0.35, function() sw.Set(false) end)
end
return obj
end

HS.TabFunc = CreateTab("Function")
CreateHeader(HS.TabFunc, "CHỨC NĂNG CHÍNH")
CreateLabel(HS.TabFunc, "Bản Fix: nếu module lỗi, thông báo sẽ hiển thị chi tiết thay vì bị ẩn.", C.Sub)
CreateToggle(HS.TabFunc, "Áp dụng Các chức năng", false, function(s) State.Features.Apply = s end)
CreateToggle(HS.TabFunc, "Áp dụng Aimbot", false, function(s) State.Features.Aimbot = s end)
CreateToggle(HS.TabFunc, "Áp dụng ESP", false, function(s) State.Features.ESP = s end)
CreateToggle(HS.TabFunc, "Bypass", false, function(s)
State.Features.Bypass = s
HS.SetBanner(s)
Notify(s and "Bypass UI đã bật" or "Bypass UI đã tắt", s and "Hiệu ứng giao diện được kích hoạt" or "Đã dừng hiệu ứng giao diện", 4)
end)
CreateToggle(HS.TabFunc, "Patched AntiBan (UI only)", false, function(s)
State.Features.AntiBanUI = s
if s then
Notify("Patched AntiBan 2.4 Beta", "Trạng thái giao diện; không bảo đảm chống ban", 5)
else
Notify("AntiBan UI đã tắt", "Không có bảo vệ chống ban thực sự", 4)
end
end)

CreateHeader(HS.TabFunc, "THÔNG TIN SCRIPT")
HS.activationTime = os.date("%Y-%m-%d %H:%M:%S")
CreateLabel(HS.TabFunc, "Username Roblox: " .. tostring(LocalPlayer.Name), C.Text)
CreateLabel(HS.TabFunc, "Giờ kích hoạt: " .. HS.activationTime, C.Sub)
CreateLabel(HS.TabFunc, "Thời hạn key: N/A", C.Sub)
CreateLabel(HS.TabFunc, "AntiBan: Active (trạng thái hiển thị)", C.Sub)
CreateLabel(HS.TabFunc, "Anti Kick: N/A", C.Sub)
CreateLabel(HS.TabFunc, "Ghi chú: ESP/Aim có thể vi phạm quy tắc game; không có tính năng bất tử được bảo đảm.", C.Sub)
CreateLabel(HS.TabFunc, "Memory/Tele không có bảo đảm Anti 50%.", C.Sub)
CreateLabel(HS.TabFunc, "By: HyperSun 2.4 Beta", C.Text)

CreateHeader(HS.TabFunc, "BỘ LỌC MỤC TIÊU")
CreateToggle(HS.TabFunc, "Team Check", false, function(s) State.Features.TeamCheck = s end)
CreateToggle(HS.TabFunc, "Wall Check", false, function(s) State.Features.WallCheck = s end)


HS.TabAdmin = CreateTab("Admin")
CreateHeader(HS.TabAdmin, "ADMIN")
CreateButton(HS.TabAdmin, "Anti Report", function()
Notify("Anti Report ON!", "", 3)
end)
CreateLabel(HS.TabAdmin, "Anti Report chỉ hiển thị thông báo; không chặn báo cáo thật.", C.Sub)

HS.TabAimbot = CreateTab("AimBot")
CreateSlider(HS.TabAimbot, "Chỉnh FOV định vị", 1, 360, 120, function(v) State.Aimbot.FOV = v end)
CreateSlider(HS.TabAimbot, "Độ gắt (100 = khóa cứng)", 1, 100, 100, function(v) State.Aimbot.Smooth = v end)
CreateToggle(HS.TabAimbot, "Aim Lock", false, function(s) State.Aimbot.Lock = s end)
CreateToggle(HS.TabAimbot, "Nhắm vào Đầu", true, function(s) State.Aimbot.Head = s end)
CreateToggle(HS.TabAimbot, "Hiện vòng FOV", true, function(s) State.Aimbot.ShowFOV = s end)

HS.FOVCircle = nil
if HasDrawing then
HS.FOVCircle = Drawing.new("Circle")
HS.FOVCircle.Thickness = 1
HS.FOVCircle.Color = C.Accent
HS.FOVCircle.Filled = false
HS.FOVCircle.NumSides = 64
HS.FOVCircle.Visible = false
Drawings.FOV = HS.FOVCircle
end

function HS.IsVisible(part, char)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { LocalPlayer.Character, char }
local origin = Camera.CFrame.Position
local res = Workspace:Raycast(origin, part.Position - origin, params)
return res == nil
end

function HS.GetTarget()
local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
local best, shortest = nil, State.Aimbot.FOV
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer and Alive(plr) and IsEnemy(plr) then
local char = plr.Character
local part = (State.Aimbot.Head and char:FindFirstChild("Head")) or char:FindFirstChild("HumanoidRootPart")
if part then
local sp, on = Camera:WorldToViewportPoint(part.Position)
if on then
local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
if d < shortest and (not State.Features.WallCheck or HS.IsVisible(part, char)) then
shortest = d
best = part
end
end
end
end
end
return best
end

function HS.UpdateAimbot()
local active = State.Features.Apply and State.Features.Aimbot
if HS.FOVCircle then
HS.FOVCircle.Radius = State.Aimbot.FOV
HS.FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
HS.FOVCircle.Visible = active and State.Aimbot.ShowFOV
end
if not active or not State.Aimbot.Lock then return end

local target = HS.GetTarget()
if target then
local goal = CFrame.new(Camera.CFrame.Position, target.Position)
Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(State.Aimbot.Smooth / 100, 0.01, 1))
end
end

RunService:BindToRenderStep("HyperSunAim", Enum.RenderPriority.Camera.Value + 1, function()
if Unloaded then return end
Camera = Workspace.CurrentCamera or Camera
pcall(HS.UpdateAimbot)
end)

HS.TabESP = CreateTab("Esp")
CreateToggle(HS.TabESP, "ESP Skeleton", false, function(s) State.ESP.Skeleton = s end)
CreateToggle(HS.TabESP, "ESP Box", false, function(s) State.ESP.Box = s end)
CreateToggle(HS.TabESP, "ESP Count", false, function(s) State.ESP.Count = s end)
CreateToggle(HS.TabESP, "ESP Line", false, function(s) State.ESP.Line = s end)
CreateToggle(HS.TabESP, "ESP Name", false, function(s) State.ESP.Name = s end)
CreateToggle(HS.TabESP, "ESP Health", false, function(s) State.ESP.Health = s end)
CreateSlider(HS.TabESP, "Khoảng cách tối đa", 50, 5000, 2000, function(v) State.ESP.MaxDist = v end)

HS.R15 = {
{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
HS.R6 = {
{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

function HS.NewESP()
local o = {
Box = Drawing.new("Square"), Name = Drawing.new("Text"), Line = Drawing.new("Line"),
Health = Drawing.new("Line"), SkeletonLines = {}
}
o.Box.Thickness = 1; o.Box.Color = Color3.new(1, 1, 1); o.Box.Filled = false
o.Name.Size = 14; o.Name.Center = true; o.Name.Outline = true; o.Name.Color = Color3.new(1, 1, 1)
o.Line.Thickness = 1; o.Line.Color = Color3.new(1, 1, 1)
o.Health.Thickness = 3
return o
end

function HS.HideESP(o)
o.Box.Visible = false
o.Name.Visible = false
o.Line.Visible = false
o.Health.Visible = false
for _, l in pairs(o.SkeletonLines) do l.Visible = false end
end

function HS.RemoveESP(plr)
local o = ESPObjects[plr]
if not o then return end
pcall(function() o.Box:Remove() end)
pcall(function() o.Name:Remove() end)
pcall(function() o.Line:Remove() end)
pcall(function() o.Health:Remove() end)
for _, l in pairs(o.SkeletonLines) do pcall(function() l:Remove() end) end
ESPObjects[plr] = nil
end

function HS.UpdateESP()
if not HasDrawing then return end
if not State.Features.Apply or not State.Features.ESP then
for _, o in pairs(ESPObjects) do HS.HideESP(o) end
if Drawings.PlayerCount then Drawings.PlayerCount.Visible = false end
return
end

local count = 0
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer then
if Alive(plr) and IsEnemy(plr) then
count = count + 1
local char = plr.Character
local hrp = char.HumanoidRootPart
local hum = char:FindFirstChildOfClass("Humanoid")
if not ESPObjects[plr] then ESPObjects[plr] = HS.NewESP() end
local esp = ESPObjects[plr]
local sp, on = Camera:WorldToViewportPoint(hrp.Position)
local dist = (Camera.CFrame.Position - hrp.Position).Magnitude

if on and dist < State.ESP.MaxDist then
local top = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
local bot = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
local h = math.max(math.abs(top.Y - bot.Y), 4)
local boxSize = Vector2.new(h * 0.6, h)
local boxPos = Vector2.new(sp.X - boxSize.X / 2, sp.Y - boxSize.Y / 2)

esp.Box.Size = boxSize
esp.Box.Position = boxPos
esp.Box.Visible = State.ESP.Box

esp.Name.Text = plr.Name .. " [" .. math.floor(dist) .. "m]"
esp.Name.Position = Vector2.new(sp.X, boxPos.Y - 18)
esp.Name.Visible = State.ESP.Name

esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
esp.Line.To = Vector2.new(sp.X, sp.Y)
esp.Line.Visible = State.ESP.Line

local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
local hx = boxPos.X - 5
local hb = boxPos.Y + boxSize.Y
esp.Health.From = Vector2.new(hx, hb)
esp.Health.To = Vector2.new(hx, hb - boxSize.Y * pct)
esp.Health.Color = Color3.new(1 - pct, pct, 0)
esp.Health.Visible = State.ESP.Health

local list = char:FindFirstChild("UpperTorso") and HS.R15 or HS.R6
for i, pr in ipairs(list) do
local p1, p2 = char:FindFirstChild(pr[1]), char:FindFirstChild(pr[2])
local l = esp.SkeletonLines[i]
if not l then
l = Drawing.new("Line")
l.Thickness = 1
l.Color = Color3.new(1, 1, 1)
esp.SkeletonLines[i] = l
end
if p1 and p2 and State.ESP.Skeleton then
local s1, o1 = Camera:WorldToViewportPoint(p1.Position)
local s2, o2 = Camera:WorldToViewportPoint(p2.Position)
l.From = Vector2.new(s1.X, s1.Y)
l.To = Vector2.new(s2.X, s2.Y)
l.Visible = o1 and o2
else
l.Visible = false
end
end
else
HS.HideESP(esp)
end
elseif ESPObjects[plr] then
HS.HideESP(ESPObjects[plr])
end
end
end

if State.ESP.Count then
if not Drawings.PlayerCount then
local t = Drawing.new("Text")
t.Size = 16
t.Color = Color3.new(1, 1, 1)
t.Outline = true
Drawings.PlayerCount = t
end
Drawings.PlayerCount.Text = "Players: " .. count
Drawings.PlayerCount.Position = Vector2.new(20, 20)
Drawings.PlayerCount.Visible = true
elseif Drawings.PlayerCount then
Drawings.PlayerCount.Visible = false
end
end

HS.TabFly = CreateTab("Fly/Tele")

HS.FlyFloat = HS.CreateFloat("Fly", 20)
HS.UpFloat = HS.CreateFloat("Fly ▲", 62)
HS.DownFloat = HS.CreateFloat("Fly ▼", 104)
HS.TeleFloat = HS.CreateFloat("Tele Player", 146)
HS.MarkFloat = HS.CreateFloat("Tele Mark", 188)
HS.SkyFloat = HS.CreateFloat("Tele Sky", 230)
HS.UnderFloat = HS.CreateFloat("Under Plan", 272)
HS.InvisFloat = HS.CreateFloat("Invisibility", 314)
HS.TeleWallFloat = HS.CreateFloat("Tele Wall", 356)
HS.TeleWall2Float = HS.CreateFloat("Tele Wall 2", 378)
HS.LockNVFloat = HS.CreateFloat("LockNV", 400)
HS.TeleSky2Float = HS.CreateFloat("TeleSky2", 420)
HS.GhostFloat = HS.CreateFloat("Ghost", 462)
HS.TeleBack1Float = HS.CreateFloat("TeleBack1", 504)
HS.TeleBack2Float = HS.CreateFloat("TeleBack2", 546)
HS.SpeedTimeFloat = HS.CreateFloat("Speed Time", 398)
HS.FlyUpX2Float = HS.CreateFloat("Fly X2", 440)
HS.AutoHealFloat = HS.CreateFloat("Auto Heal", 588)
HS.FreezeFloat = HS.CreateFloat("Freeze", 630)
HS.UpFloat.Hold("Up")
HS.DownFloat.Hold("Down")

HS.FlyBV, HS.FlyBG = nil, nil
HS.FlyVel = Vector3.zero

function HS.DestroyFlyBodies()
if HS.FlyBV then pcall(function() HS.FlyBV:Destroy() end) end
if HS.FlyBG then pcall(function() HS.FlyBG:Destroy() end) end
HS.FlyBV, HS.FlyBG = nil, nil
HS.FlyVel = Vector3.zero
end

function HS.EnsureFlyBodies(hrp)
if HS.FlyBV and HS.FlyBG and HS.FlyBV.Parent == hrp and HS.FlyBG.Parent == hrp then return true end
HS.DestroyFlyBodies()
local ok = pcall(function()
HS.FlyBV = Instance.new("BodyVelocity")
HS.FlyBV.Name = "HSFlyBV"
HS.FlyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
HS.FlyBV.P = 1e4
HS.FlyBV.Velocity = Vector3.zero
HS.FlyBV.Parent = hrp
HS.FlyBG = Instance.new("BodyGyro")
HS.FlyBG.Name = "HSFlyBG"
HS.FlyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
HS.FlyBG.P = 9e4
HS.FlyBG.D = 500
HS.FlyBG.CFrame = hrp.CFrame
HS.FlyBG.Parent = hrp
end)
if not ok then
HS.DestroyFlyBodies()
return false
end
return true
end

;

function HS.SetFly(on)
if on and State.Under.Enabled then
Notify("Fly", "Hãy tắt Under Plan trước khi bay", 5)
HS.FlyFloat.SetOn(false)
if HS.FlyToggle then HS.FlyToggle.Set(false, false) end
return
end
State.Memory.FlyEnabled = on and true or false
HS.FlyFloat.SetOn(State.Memory.FlyEnabled)
if HS.FlyToggle then HS.FlyToggle.Set(State.Memory.FlyEnabled, false) end
local hrp, hum = GetHRP()
if on then
local lift = math.max(State.Memory.FlyHeight, 0)
if hrp and lift > 0 then
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { LocalPlayer.Character }
local res = Workspace:Raycast(hrp.Position, Vector3.new(0, lift + 4, 0), params)
if res then lift = math.max(res.Distance - 4, 0) end
hrp.CFrame = hrp.CFrame + Vector3.new(0, lift, 0)
end
else
State.Memory.Up = false
State.Memory.Down = false
HS.DestroyFlyBodies()
if hrp then pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end) end
if hum then hum.PlatformStand = false end
end
end

function HS.UpdateFly(dt, hrp, hum)
if not State.Memory.FlyEnabled then
if HS.FlyBV or HS.FlyBG then HS.DestroyFlyBodies() end
return
end
if not hrp or not hum or hum.Health <= 0 then return end

hum.PlatformStand = true
local usedBodies = HS.EnsureFlyBodies(hrp)

local cam = Camera.CFrame
local look = cam.LookVector
local flatLook = Vector3.new(look.X, 0, look.Z)
if flatLook.Magnitude < 0.05 then
flatLook = Vector3.new(cam.UpVector.X, 0, cam.UpVector.Z)
end
if flatLook.Magnitude < 0.001 then
flatLook = Vector3.new(0, 0, -1)
else
flatLook = flatLook.Unit
end
local flatRight = flatLook:Cross(Vector3.new(0, 1, 0))

local move = hum.MoveDirection
local fwd = move:Dot(flatLook)
local rgt = move:Dot(flatRight)
local dir = cam.LookVector * fwd + cam.RightVector * rgt

local vert = 0
if State.Memory.Up or UserInputService:IsKeyDown(Enum.KeyCode.Space) then vert = vert + 1 end
if State.Memory.Down or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vert = vert - 1 end
dir = dir + Vector3.new(0, vert, 0)
if dir.Magnitude > 1 then dir = dir.Unit end

local target = dir * State.Memory.FlySpeed
HS.FlyVel = HS.FlyVel:Lerp(target, 1 - math.exp(-dt * 10))

if usedBodies then
HS.FlyBV.Velocity = HS.FlyVel
HS.FlyBG.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatLook)
else
hrp.AssemblyLinearVelocity = HS.FlyVel
hrp.AssemblyAngularVelocity = Vector3.zero
end
end

CreateHeader(HS.TabFly, "FLY")
HS.FlyToggle = CreateToggle(HS.TabFly, "Fly Normal", false, function(s) HS.SetFly(s) end)
CreateToggle(HS.TabFly, "Hiện nút nổi Fly", false, function(s)
HS.FlyFloat.Show(s)
HS.UpFloat.Show(s)
HS.DownFloat.Show(s)
end)
CreateSlider(HS.TabFly, "Nhấc lên khi bật Fly (0 = tắt)", 0, 300, 5, function(v) State.Memory.FlyHeight = v end)
CreateSlider(HS.TabFly, "Tốc độ Fly", 1, 500, 50, function(v) State.Memory.FlySpeed = v end)
HS.FlyFloat.OnTap(function() HS.SetFly(not State.Memory.FlyEnabled) end)

CreateHeader(HS.TabFly, "TELE PLAYER")
HS.TeleTarget = nil
HS.DropdownBtn = CreateButton(HS.TabFly, "Chọn Player")
HS.dropFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 110), BackgroundColor3 = C.Item, BackgroundTransparency = 0.2, Visible = false }, HS.TabFly)
Create("UICorner", { CornerRadius = UDim.new(0, 7) }, HS.dropFrame)
HS.dropScroll = Create("ScrollingFrame", {
Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
}, HS.dropFrame)
Create("UIListLayout", { Padding = UDim.new(0, 2) }, HS.dropScroll)
HS.DropdownBtn.MouseButton1Click:Connect(function() HS.dropFrame.Visible = not HS.dropFrame.Visible end)

function HS.refreshPlayers()
if Unloaded then return end
for _, v in ipairs(HS.dropScroll:GetChildren()) do
if v:IsA("TextButton") then v:Destroy() end
end
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LocalPlayer then
local pBtn = Create("TextButton", {
Size = UDim2.new(1, -4, 0, 28), BackgroundColor3 = C.Panel, Text = p.Name,
TextColor3 = C.Text, Font = FONT_N, TextSize = 13, AutoButtonColor = false
}, HS.dropScroll)
Create("UICorner", { CornerRadius = UDim.new(0, 5) }, pBtn)
pBtn.MouseButton1Click:Connect(function()
Click()
HS.TeleTarget = p
HS.DropdownBtn.Text = "Target: " .. p.Name
HS.dropFrame.Visible = false
HS.TeleFloat.Show(true)
end)
end
end
end
HS.refreshPlayers()
Connections[#Connections + 1] = Players.PlayerAdded:Connect(HS.refreshPlayers)
Connections[#Connections + 1] = Players.PlayerRemoving:Connect(function(p)
if HS.TeleTarget == p then
HS.TeleTarget = nil
HS.DropdownBtn.Text = "Chọn Player"
HS.TeleFloat.Show(false)
end
task.defer(HS.refreshPlayers)
end)

HS.TeleFloat.OnTap(function()
HS.TeleFloat.Flash()
local hrp = GetHRP()
if HS.TeleTarget and hrp and HS.TeleTarget.Character and HS.TeleTarget.Character:FindFirstChild("HumanoidRootPart") then
hrp.CFrame = HS.TeleTarget.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
else
Notify("Tele Player", "Không tìm thấy mục tiêu", 5)
end
end)

CreateHeader(HS.TabFly, "TELE MARK")
HS.MarkedPos = nil
HS.MapGui = Create("Frame", {
Size = UDim2.new(0, 360, 0, 270), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
BackgroundColor3 = C.Panel, Visible = false, ZIndex = 10
}, ScreenGui)
Create("UICorner", { CornerRadius = UDim.new(0, 10) }, HS.MapGui)
Create("UIStroke", { Color = C.Accent }, HS.MapGui)
Create("TextLabel", {
Size = UDim2.new(1, -40, 0, 30), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1,
Text = "Chạm để đánh dấu (vùng 1000 stud quanh bạn)", TextColor3 = C.Text, Font = FONT_N, TextSize = 12,
TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10
}, HS.MapGui)
HS.MapClose = Create("TextButton", {
Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -30, 0, 0), Text = "X",
TextColor3 = C.Accent, Font = FONT_B, TextSize = 14, BackgroundTransparency = 1, ZIndex = 11
}, HS.MapGui)
HS.MapClose.MouseButton1Click:Connect(function()
Click()
HS.MapGui.Visible = false
end)
HS.MapArea = Create("TextButton", {
Size = UDim2.new(1, -20, 1, -40), Position = UDim2.new(0, 10, 0, 32),
BackgroundColor3 = Color3.fromRGB(30, 30, 30), Text = "", AutoButtonColor = false, ZIndex = 10
}, HS.MapGui)
Create("UICorner", { CornerRadius = UDim.new(0, 6) }, HS.MapArea)
HS.MapArea.InputBegan:Connect(function(input)
if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
local hrp = GetHRP()
if not hrp then return end
Click()
local relX = (input.Position.X - HS.MapArea.AbsolutePosition.X) / math.max(HS.MapArea.AbsoluteSize.X, 1)
local relY = (input.Position.Y - HS.MapArea.AbsolutePosition.Y) / math.max(HS.MapArea.AbsoluteSize.Y, 1)
local o = hrp.Position
HS.MarkedPos = Vector3.new(o.X + (relX - 0.5) * 1000, o.Y, o.Z + (relY - 0.5) * 1000)
Notify("Tele Mark", "Đã đánh dấu vị trí!", 5)
HS.MapGui.Visible = false
HS.MarkFloat.Show(true)
end)
CreateButton(HS.TabFly, "Mở Bản Đồ (Tele Mark)", function() HS.MapGui.Visible = true end)

HS.MarkFloat.OnTap(function()
HS.MarkFloat.Flash()
local hrp = GetHRP()
if HS.MarkedPos and hrp then
hrp.CFrame = CFrame.new(HS.MarkedPos + Vector3.new(0, 3, 0))
end
end)

CreateHeader(HS.TabFly, "TELE SKY")
CreateSlider(HS.TabFly, "Độ cao Tele Sky", 1, 1000, 100, function(v) State.Memory.TeleSkyHeight = v end)
CreateToggle(HS.TabFly, "Bật Tele Sky", false, function(s) HS.SkyFloat.Show(s) end)

HS.SkyFloat.OnTap(function()
local hrp = GetHRP()
if not hrp then return end
State.Memory.InSky = not State.Memory.InSky
HS.SkyFloat.SetOn(State.Memory.InSky)
if State.Memory.InSky then
State.Memory.OldPos = hrp.Position
hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + State.Memory.TeleSkyHeight, hrp.Position.Z)
else
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { LocalPlayer.Character }
local res = Workspace:Raycast(hrp.Position, Vector3.new(0, -3000, 0), params)
local dest = (res and (res.Position + Vector3.new(0, 3, 0))) or State.Memory.OldPos
if dest then hrp.CFrame = CFrame.new(dest) end
end
end)

HS.TabChams = CreateTab("Chams")

function HS.RemoveCham(plr)
local h = HS.ChamObjs[plr]
if h then pcall(function() h:Destroy() end) end
HS.ChamObjs[plr] = nil
end

function HS.ClearChams()
for plr in pairs(HS.ChamObjs) do HS.RemoveCham(plr) end
end

function HS.UpdateChams()
local mode = State.Chams.Mode
if mode == "None" then
if next(HS.ChamObjs) then HS.ClearChams() end
return
end
local col
if mode == "Red" then
col = Color3.fromRGB(255, 0, 0)
elseif mode == "Blue" then
col = Color3.fromRGB(0, 80, 255)
else
col = Color3.fromHSV(tick() % 1, 1, 1)
end
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer then
local char = plr.Character
local h = HS.ChamObjs[plr]
if char and char:FindFirstChild("HumanoidRootPart") then
if not h or not h.Parent then
h = Instance.new("Highlight")
h.Name = "HSCham"
h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
h.FillTransparency = 0.4
h.OutlineColor = Color3.new(1, 1, 1)
h.OutlineTransparency = 0
h.Parent = Root
HS.ChamObjs[plr] = h
end
if h.Adornee ~= char then h.Adornee = char end
h.FillColor = col
elseif h then
HS.RemoveCham(plr)
end
end
end
end

Connections[#Connections + 1] = Players.PlayerRemoving:Connect(function(p)
HS.RemoveESP(p)
HS.RemoveCham(p)
end)

HS.ChamToggles = {}
function HS.ChamSwitch(name)
return function(s)
if s then
for n, t in pairs(HS.ChamToggles) do
if n ~= name then t.Set(false, false) end
end
State.Chams.Mode = name
elseif State.Chams.Mode == name then
State.Chams.Mode = "None"
end
end
end
HS.ChamToggles.Red = CreateToggle(HS.TabChams, "Red Chams", false, HS.ChamSwitch("Red"))
HS.ChamToggles.Blue = CreateToggle(HS.TabChams, "Blue Chams", false, HS.ChamSwitch("Blue"))
HS.ChamToggles.Rainbow = CreateToggle(HS.TabChams, "Rainbow Chams", false, HS.ChamSwitch("Rainbow"))

HS.SpinPlayer = { Enabled = false, Speed = 5, BaseRotation = nil, Angle = 0 }
function HS.SetSpinPlayer(on)
    local hrp = GetHRP()
    if on then
        if not hrp then
            Notify("-180° Player", "Không tìm thấy nhân vật", 3)
            HS.SpinPlayer.Enabled = false
            return
        end
        HS.SpinPlayer.BaseRotation = hrp.CFrame.Rotation
        local _, yaw = hrp.CFrame:ToEulerAnglesYXZ()
        HS.SpinPlayer.Angle = yaw
        HS.SpinPlayer.Enabled = true
        Notify("-180° Player", "Đã bật xoay nhân vật", 3)
    else
        HS.SpinPlayer.Enabled = false
        if hrp and HS.SpinPlayer.BaseRotation then
            pcall(function()
                hrp.CFrame = CFrame.new(hrp.Position) * HS.SpinPlayer.BaseRotation
            end)
        end
        HS.SpinPlayer.BaseRotation = nil
        Notify("-180° Player", "Đã tắt; khôi phục hướng ban đầu", 3)
    end
end

HS.TabLoc = CreateTab("Location")
CreateHeader(HS.TabLoc, "INVISIBILITY")
HS.InvisToggle = CreateToggle(HS.TabLoc, "Invisibility · Ẩn nhân vật (cục bộ)", false, function(on)
HS.Invis.Set(on)
end)
CreateToggle(HS.TabLoc, "Hiện nút nổi Invisibility", false, function(on)
if HS.InvisFloat then HS.InvisFloat.Show(on) end
end)
CreateLabel(HS.TabLoc, "Chỉ ẩn trên màn hình của bạn; không làm nhân vật vô hình với người chơi khác trên máy chủ.")
CreateHeader(HS.TabLoc, "-180° PLAYER · XOAY NHÂN VẬT")
CreateLabel(HS.TabLoc, "Xoay liên tục quanh trục đứng. Tắt để khôi phục hướng lúc bật.", C.Sub)
CreateSlider(HS.TabLoc, "Tốc độ xoay (1–20)", 1, 20, 5, function(v)
    HS.SpinPlayer.Speed = math.clamp(v, 1, 20)
end)
CreateToggle(HS.TabLoc, "Bật -180° Player", false, function(on)
    HS.SetSpinPlayer(on)
end)
HS.InvisFloat.OnTap(function()
HS.Invis.Set(not HS.Invis.Enabled)
end)

HS.TabMem = CreateTab("Memory")
CreateHeader(HS.TabMem, "DI CHUYỂN")

-- Auto Heal: local health restoration loop. Server-authoritative games may overwrite it.
HS.AutoHealEnabled = false
HS.AutoHealConnection = nil
function HS.SetAutoHeal(on)
    HS.AutoHealEnabled = on and true or false
    HS.AutoHealFloat.SetOn(HS.AutoHealEnabled)
    if HS.AutoHealConnection then
        pcall(function() HS.AutoHealConnection:Disconnect() end)
        HS.AutoHealConnection = nil
    end
    if HS.AutoHealEnabled then
        HS.AutoHealConnection = RunService.Heartbeat:Connect(function()
            if not HS.AutoHealEnabled or Unloaded then return end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
                pcall(function() hum.Health = hum.MaxHealth end)
            end
        end)
        Notify("Auto Heal", "Đã bật hồi máu cục bộ", 3)
    else
        Notify("Auto Heal", "Đã tắt", 3)
    end
end
HS.AutoHealFloat.OnTap(function() HS.SetAutoHeal(not HS.AutoHealEnabled) end)
CreateToggle(HS.TabMem, "Hiện nút nổi Auto Heal", false, function(on) HS.AutoHealFloat.Show(on) end)
CreateLabel(HS.TabMem, "Auto Heal chỉ thử đặt máu tối đa ở phía client; máy chủ có thể ghi đè.", C.Sub)

-- Freeze marker: highlights the player nearest the screen center locally. It does not immobilize other players.
HS.FreezeEnabled = false
HS.FreezeHighlight = nil
HS.FreezeTarget = nil
HS.FreezeConnection = nil
function HS.ClearFreezeMarker()
    if HS.FreezeHighlight then pcall(function() HS.FreezeHighlight:Destroy() end) end
    HS.FreezeHighlight = nil
    HS.FreezeTarget = nil
end
function HS.SetFreezeMarker(on)
    HS.FreezeEnabled = on and true or false
    HS.FreezeFloat.SetOn(HS.FreezeEnabled)
    if HS.FreezeConnection then pcall(function() HS.FreezeConnection:Disconnect() end); HS.FreezeConnection = nil end
    HS.ClearFreezeMarker()
    if HS.FreezeEnabled then
        HS.FreezeConnection = RunService.RenderStepped:Connect(function()
            if not HS.FreezeEnabled or Unloaded then return end
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local vp = cam.ViewportSize
            local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
            local best, bestDist = nil, math.huge
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hum and hum.Health > 0 and root then
                        local pos, visible = cam:WorldToViewportPoint(root.Position)
                        if visible then
                            local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                            if dist < bestDist then best, bestDist = plr, dist end
                        end
                    end
                end
            end
            if best ~= HS.FreezeTarget then
                HS.ClearFreezeMarker()
                HS.FreezeTarget = best
                if best and best.Character then
                    local ok, h = pcall(function()
                        local hl = Instance.new("Highlight")
                        hl.Name = "HyperSun_FreezeMarker"
                        hl.Adornee = best.Character
                        hl.FillColor = C.Accent
                        hl.OutlineColor = Color3.new(1, 1, 1)
                        hl.FillTransparency = 0.65
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = ScreenGui
                        return hl
                    end)
                    if ok then HS.FreezeHighlight = h end
                end
            end
        end)
        Notify("Freeze", "Đã bật đánh dấu mục tiêu giữa tâm ngắm; không đóng băng người chơi thật", 4)
    else
        Notify("Freeze", "Đã tắt đánh dấu mục tiêu", 3)
    end
end
HS.FreezeFloat.OnTap(function() HS.SetFreezeMarker(not HS.FreezeEnabled) end)
CreateToggle(HS.TabMem, "Hiện nút nổi Freeze", false, function(on) HS.FreezeFloat.Show(on) end)
CreateLabel(HS.TabMem, "Freeze chỉ đánh dấu mục tiêu cục bộ. Đóng băng người chơi khác cần quyền xử lý phía máy chủ của game.", C.Sub)

-- TeleBack: save a location, then return to it with a separate floating button.
HS.TeleBackSavedCFrame = nil
function HS.SaveTeleBack()
    local hrp = GetHRP()
    if not hrp then Notify("TeleBack1", "Không tìm thấy nhân vật", 3); return end
    HS.TeleBackSavedCFrame = hrp.CFrame
    Notify("TeleBack1", "Đã lưu vị trí hiện tại", 3)
    HS.TeleBack1Float.Flash()
end
function HS.ReturnTeleBack()
    local hrp = GetHRP()
    if not hrp then Notify("TeleBack2", "Không tìm thấy nhân vật", 3); return end
    if not HS.TeleBackSavedCFrame then Notify("TeleBack2", "Hãy lưu vị trí bằng TeleBack1 trước", 4); return end
    hrp.CFrame = HS.TeleBackSavedCFrame
    hrp.AssemblyLinearVelocity = Vector3.zero
    Notify("TeleBack2", "Đã trở về vị trí đã lưu", 3)
    HS.TeleBack2Float.Flash()
end

-- Ghost clone mode: client-side clone is controllable locally; server-side invisibility is not guaranteed.
HS.GhostEnabled = false
;
;
;
;
;
HS.GhostSavedParts = {}
HS.GhostSavedDecals = {}

function HS.GhostRestoreRealVisuals()
    for inst, saved in pairs(HS.GhostSavedParts) do
        if inst and inst.Parent then
            pcall(function()
                inst.LocalTransparencyModifier = saved.LocalTransparencyModifier or 0
                inst.Transparency = saved.Transparency
            end)
        end
    end
    for inst, transparency in pairs(HS.GhostSavedDecals) do
        if inst and inst.Parent then pcall(function() inst.Transparency = transparency end) end
    end
    ClearTableCompat(HS.GhostSavedParts)
    ClearTableCompat(HS.GhostSavedDecals)
end

function HS.SetGhost(on)
    on = on and true or false
    if on == HS.GhostEnabled then return end
    if on then
        local real = LocalPlayer.Character
        local realRoot = real and real:FindFirstChild("HumanoidRootPart")
        local realHum = real and real:FindFirstChildOfClass("Humanoid")
        if not real or not realRoot or not realHum then
            Notify("Ghost", "Không tìm thấy nhân vật hợp lệ", 4)
            HS.GhostFloat.SetOn(false)
            return
        end
        local oldArchivable = real.Archivable
        local ok, clone = pcall(function()
            real.Archivable = true
            local copy = real:Clone()
            real.Archivable = oldArchivable
            return copy
        end)
        real.Archivable = oldArchivable
        if not ok or not clone then
            Notify("Ghost", "Không thể tạo bản sao nhân vật", 5)
            HS.GhostFloat.SetOn(false)
            return
        end
        clone.Name = "HyperSun_GhostClone"
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") then
                pcall(function() d:Destroy() end)
            elseif d:IsA("Tool") then
                pcall(function() d:Destroy() end)
            elseif d:IsA("BasePart") then
                d.Anchored = false
                d.CanCollide = false
            end
        end
        local cloneRoot = clone:FindFirstChild("HumanoidRootPart")
        local cloneHum = clone:FindFirstChildOfClass("Humanoid")
        if not cloneRoot or not cloneHum then
            clone:Destroy()
            Notify("Ghost", "Bản sao thiếu Humanoid hoặc HumanoidRootPart", 4)
            HS.GhostFloat.SetOn(false)
            return
        end
        HS.GhostRealCharacter = real
        HS.GhostClone = clone
        HS.GhostRoot = realRoot
        HS.GhostHumanoid = realHum
        HS.GhostRealRootCFrame = realRoot.CFrame
        HS.GhostRealAnchored = realRoot.Anchored
        HS.GhostRealAutoRotate = realHum.AutoRotate
        local camera = Workspace.CurrentCamera
        HS.GhostCameraSubject = camera and camera.CameraSubject
        HS.GhostCameraType = camera and camera.CameraType
        for _, inst in ipairs(real:GetDescendants()) do
            if inst:IsA("BasePart") then
                HS.GhostSavedParts[inst] = {Transparency = inst.Transparency, LocalTransparencyModifier = inst.LocalTransparencyModifier}
                inst.LocalTransparencyModifier = 1
            elseif inst:IsA("Decal") or inst:IsA("Texture") then
                HS.GhostSavedDecals[inst] = inst.Transparency
                inst.Transparency = 1
            end
        end
        realRoot.Anchored = true
        realHum.AutoRotate = false
        clone:PivotTo(realRoot.CFrame)
        clone.Parent = Workspace
        HS.GhostClone = clone
        HS.GhostRoot = cloneRoot
        HS.GhostHumanoid = cloneHum
        cloneHum.WalkSpeed = realHum.WalkSpeed
        cloneHum.JumpPower = 0
        cloneHum.JumpHeight = 0
        cloneHum.AutoRotate = true
        pcall(function() cloneHum:UnequipTools() end)
        HS.GhostEnabled = true
        -- Read Roblox's existing touch joystick/keyboard movement vector and drive only the clone.
        pcall(function()
            local ps = LocalPlayer:WaitForChild("PlayerScripts", 3)
            local pm = ps and require(ps:WaitForChild("PlayerModule", 3))
            HS.GhostControls = pm and pm:GetControls()
        end)
        HS.GhostMoveConnection = RunService.RenderStepped:Connect(function()
            if not HS.GhostEnabled or not HS.GhostClone or not HS.GhostClone.Parent or not HS.GhostHumanoid then return end
            local move = Vector3.zero
            pcall(function()
                if HS.GhostControls then move = HS.GhostControls:GetMoveVector() end
            end)
            local cameraNow = Workspace.CurrentCamera
            if cameraNow then
                local look = cameraNow.CFrame.LookVector
                local right = cameraNow.CFrame.RightVector
                local forwardFlat = Vector3.new(look.X, 0, look.Z)
                local rightFlat = Vector3.new(right.X, 0, right.Z)
                if forwardFlat.Magnitude > 0 then forwardFlat = forwardFlat.Unit end
                if rightFlat.Magnitude > 0 then rightFlat = rightFlat.Unit end
                local worldMove = rightFlat * move.X + forwardFlat * -move.Z
                HS.GhostHumanoid:Move(worldMove, false)
            end
            HS.GhostHumanoid.Jump = false
        end)
        if camera then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = cloneHum
        end
        HS.GhostFloat.SetOn(true)
        Notify("Ghost", "Ghost phân thân đã bật; chỉ di chuyển bản sao ở phía client", 5)
    else
        HS.GhostEnabled = false
        if HS.GhostMoveConnection then pcall(function() HS.GhostMoveConnection:Disconnect() end); HS.GhostMoveConnection = nil end
        local clonePos = HS.GhostRoot and HS.GhostRoot.Parent and HS.GhostRoot.CFrame or HS.GhostRealRootCFrame
        if HS.GhostRealCharacter and HS.GhostRealCharacter.Parent then
            local realRoot = HS.GhostRealCharacter:FindFirstChild("HumanoidRootPart")
            local realHum = HS.GhostRealCharacter:FindFirstChildOfClass("Humanoid")
            if realRoot then
                realRoot.Anchored = HS.GhostRealAnchored or false
                if clonePos then realRoot.CFrame = clonePos end
                pcall(function() realRoot.AssemblyLinearVelocity = Vector3.zero end)
            end
            if realHum and HS.GhostRealAutoRotate ~= nil then realHum.AutoRotate = HS.GhostRealAutoRotate end
        end
        HS.GhostRestoreRealVisuals()
        local camera = Workspace.CurrentCamera
        if camera then
            camera.CameraType = HS.GhostCameraType or Enum.CameraType.Custom
            local hum = HS.GhostRealCharacter and HS.GhostRealCharacter:FindFirstChildOfClass("Humanoid")
            camera.CameraSubject = hum or HS.GhostCameraSubject
        end
        if HS.GhostClone then pcall(function() HS.GhostClone:Destroy() end) end
        HS.GhostRealCharacter, HS.GhostClone, HS.GhostRoot, HS.GhostHumanoid = nil, nil, nil, nil
        HS.GhostControls, HS.GhostRealRootCFrame, HS.GhostRealAnchored, HS.GhostRealAutoRotate = nil, nil, nil, nil
        HS.GhostCameraSubject, HS.GhostCameraType = nil, nil
        HS.GhostFloat.SetOn(false)
        Notify("Ghost", "Ghost đã tắt; đã khôi phục nhân vật thật", 4)
    end
end
HS.GhostFloat.OnTap(function() HS.SetGhost(not HS.GhostEnabled) end)
HS.TeleBack1Float.OnTap(HS.SaveTeleBack)
HS.TeleBack2Float.OnTap(HS.ReturnTeleBack)
CreateToggle(HS.TabMem, "Ghost · Phân thân điều khiển (Beta)", false, HS.SetGhost)
CreateLabel(HS.TabMem, "Bản sao được điều khiển cục bộ; không đảm bảo ẩn nhân vật thật khỏi máy chủ hoặc người chơi khác.", C.Sub)
CreateToggle(HS.TabMem, "Hiện nút nổi Ghost", false, function(on) HS.GhostFloat.Show(on) end)
CreateToggle(HS.TabMem, "Hiện nút nổi TeleBack1 (lưu vị trí)", false, function(on) HS.TeleBack1Float.Show(on) end)
CreateToggle(HS.TabMem, "Hiện nút nổi TeleBack2 (quay lại)", false, function(on) HS.TeleBack2Float.Show(on) end)
CreateButton(HS.TabMem, "TeleBack1 · Lưu vị trí", HS.SaveTeleBack)
CreateButton(HS.TabMem, "TeleBack2 · Quay về vị trí đã lưu", HS.ReturnTeleBack)


-- Fast Talk: reduce local ProximityPrompt hold time; server-side cooldowns remain controlled by the game.
HS.FastTalkSaved = {}
HS.FastTalkAddedConn = nil
function HS.ApplyFastTalkPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    if HS.FastTalkSaved[prompt] == nil then
        HS.FastTalkSaved[prompt] = { HoldDuration = prompt.HoldDuration, RequiresLineOfSight = prompt.RequiresLineOfSight }
    end
    pcall(function()
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
    end)
end
function HS.SetFastTalk(on)
    State.Memory.FastTalk = on and true or false
    if State.Memory.FastTalk then
        for _, inst in ipairs(Workspace:GetDescendants()) do
            if inst:IsA("ProximityPrompt") then HS.ApplyFastTalkPrompt(inst) end
        end
        if HS.FastTalkAddedConn then HS.FastTalkAddedConn:Disconnect() end
        HS.FastTalkAddedConn = Workspace.DescendantAdded:Connect(function(inst)
            if State.Memory.FastTalk and inst:IsA("ProximityPrompt") then
                task.defer(function() HS.ApplyFastTalkPrompt(inst) end)
            end
        end)
        Notify("Fast Talk", "Đã giảm thời gian giữ prompt ở phía client", 4)
    else
        if HS.FastTalkAddedConn then HS.FastTalkAddedConn:Disconnect(); HS.FastTalkAddedConn = nil end
        for prompt, saved in pairs(HS.FastTalkSaved) do
            if prompt and prompt.Parent then
                pcall(function()
                    prompt.HoldDuration = saved.HoldDuration
                    prompt.RequiresLineOfSight = saved.RequiresLineOfSight
                end)
            end
        end
        ClearTableCompat(HS.FastTalkSaved)
        Notify("Fast Talk", "Đã khôi phục thiết lập prompt", 3)
    end
end
CreateToggle(HS.TabMem, "Fast Talk · Tương tác nhanh", false, HS.SetFastTalk)
CreateLabel(HS.TabMem, "Chỉ giảm thời gian giữ ProximityPrompt trên client; cooldown do máy chủ game quản lý vẫn có thể áp dụng.", C.Sub)

-- Fast Attack (Beta): repeatedly activates the currently equipped Tool locally and speeds up local attack animations.
-- The game server may still enforce its own attack cooldown and damage rules.
HS.FastAttackAnimSpeeds = {}
HS.FastAttackAnimatorConn = nil
function HS.BoostAttackAnimation(track)
    if not track then return end
    if HS.FastAttackAnimSpeeds[track] == nil then
        local originalSpeed = 1
        pcall(function() originalSpeed = track.Speed end)
        HS.FastAttackAnimSpeeds[track] = originalSpeed
    end
    pcall(function() track:AdjustSpeed(10) end) -- 10x local animation speed
end
function HS.SetFastAttack(on)
    State.Memory.FastAttack = on and true or false
    if State.Memory.FastAttack then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 2))
        if animator then
            if HS.FastAttackAnimatorConn then HS.FastAttackAnimatorConn:Disconnect() end
            HS.FastAttackAnimatorConn = animator.AnimationPlayed:Connect(function(track)
                if State.Memory.FastAttack then HS.BoostAttackAnimation(track) end
            end)
            pcall(function()
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do HS.BoostAttackAnimation(track) end
            end)
        end
        task.spawn(function()
            while State.Memory.FastAttack and not Unloaded do
                local currentChar = LocalPlayer.Character
                local tool = currentChar and currentChar:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function() tool:Activate() end)
                end
                task.wait(0.1)
            end
        end)
        Notify("Fast Attack (Beta)", "Đã bật nhịp kích hoạt 0,1 giây ở client", 4)
    else
        if HS.FastAttackAnimatorConn then HS.FastAttackAnimatorConn:Disconnect(); HS.FastAttackAnimatorConn = nil end
        for track, speed in pairs(HS.FastAttackAnimSpeeds) do
            pcall(function()
                if track and track.IsPlaying then track:AdjustSpeed(speed) end
            end)
        end
        ClearTableCompat(HS.FastAttackAnimSpeeds)
        Notify("Fast Attack (Beta)", "Đã tắt", 3)
    end
end
CreateToggle(HS.TabMem, "Fast Attack (Beta) · 0,1s", false, HS.SetFastAttack)
CreateLabel(HS.TabMem, "Thử kích hoạt Tool mỗi 0,1 giây và tăng tốc animation cục bộ. Máy chủ game vẫn có thể giới hạn tốc độ đánh/sát thương.", C.Sub)

-- TeleSky2: hover at a fixed altitude and move horizontally using the normal movement controls.
;
;
function HS.SetTeleSky2(on)
    local hrp, hum = GetHRP()
    if on then
        if State.Memory.TeleSky2 then return end
        if not hrp or not hum or hum.Health <= 0 then
            Notify("TeleSky2", "Không tìm thấy nhân vật", 3)
            HS.TeleSky2Float.SetOn(false)
            if HS.TeleSky2Toggle then HS.TeleSky2Toggle.Set(false, false) end
            return
        end
        if State.Memory.LockNV then HS.SetLockNV(false) end
        local startPos = hrp.Position
        local groundPos = nil
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        local hit = Workspace:Raycast(startPos, Vector3.new(0, -3000, 0), params)
        if hit then groundPos = hit.Position + Vector3.new(0, 3, 0) end
        local targetY = math.max(startPos.Y + 90, (groundPos and groundPos.Y + 90) or startPos.Y + 90)
        local bv = Instance.new("BodyVelocity")
        bv.Name = "HyperSunTeleSky2Velocity"
        bv.MaxForce = Vector3.new(1e7, 1e7, 1e7)
        bv.P = 25000
        bv.Velocity = Vector3.zero
        bv.Parent = hrp
        local bg = Instance.new("BodyGyro")
        bg.Name = "HyperSunTeleSky2Gyro"
        bg.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
        bg.P = 18000
        bg.D = 700
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
        State.Memory.TeleSky2Data = {Root = hrp, Humanoid = hum, StartPos = startPos, GroundPos = groundPos, TargetY = targetY, Velocity = bv, Gyro = bg, AutoRotate = hum.AutoRotate}
        State.Memory.TeleSky2 = true
        hum.AutoRotate = false
        hrp.CFrame = CFrame.new(startPos.X, targetY, startPos.Z)
        HS.TeleSky2Float.SetOn(true)
        if HS.TeleSky2Toggle then HS.TeleSky2Toggle.Set(true, false) end
        Notify("TeleSky2", "Đã bật chế độ lơ lửng; dùng cần di chuyển để tiến/lùi", 4)
    else
        if not State.Memory.TeleSky2 then return end
        local data = State.Memory.TeleSky2Data
        State.Memory.TeleSky2 = false
        if data then
            pcall(function() if data.Velocity then data.Velocity:Destroy() end end)
            pcall(function() if data.Gyro then data.Gyro:Destroy() end end)
            if data.Humanoid and data.Humanoid.Parent then pcall(function() data.Humanoid.AutoRotate = data.AutoRotate end) end
            local root = data.Root
            if root and root.Parent then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {LocalPlayer.Character}
                local hit = Workspace:Raycast(root.Position, Vector3.new(0, -5000, 0), params)
                local dest = (hit and hit.Position + Vector3.new(0, 3, 0)) or data.GroundPos or data.StartPos
                if dest then root.CFrame = CFrame.new(dest) end
                root.AssemblyLinearVelocity = Vector3.zero
            end
        end
        State.Memory.TeleSky2Data = nil
        HS.TeleSky2Float.SetOn(false)
        if HS.TeleSky2Toggle then HS.TeleSky2Toggle.Set(false, false) end
        Notify("TeleSky2", "Đã tắt và đưa nhân vật xuống gần mặt đất", 3)
    end
end
HS.TeleSky2Toggle = CreateToggle(HS.TabMem, "TeleSky2 · Lơ lửng trên trời", false, HS.SetTeleSky2)
CreateToggle(HS.TabMem, "TeleSky2 (hiện nút nổi)", false, function(on) HS.TeleSky2Float.Show(on) end)
HS.TeleSky2Float.OnTap(function() HS.SetTeleSky2(not State.Memory.TeleSky2) end)
Connections[#Connections + 1] = RunService.Heartbeat:Connect(function()
    if not State.Memory.TeleSky2 then return end
    local data = State.Memory.TeleSky2Data
    if not data or not data.Root or not data.Root.Parent or not data.Humanoid or data.Humanoid.Health <= 0 then
        HS.SetTeleSky2(false)
        return
    end
    local cam = Workspace.CurrentCamera
    local move = data.Humanoid.MoveDirection
    local horizontal = Vector3.zero
    if cam and move.Magnitude > 0.01 then
        horizontal = Vector3.new(move.X, 0, move.Z).Unit * 48
    end
    local vertical = math.clamp((data.TargetY - data.Root.Position.Y) * 4, -65, 65)
    data.Velocity.Velocity = Vector3.new(horizontal.X, vertical, horizontal.Z)
    if cam then
        local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
        if look.Magnitude > 0.01 then data.Gyro.CFrame = CFrame.lookAt(data.Root.Position, data.Root.Position + look.Unit) end
    end
end)

HS.TeleWallSaved = nil
function HS.ActivateTeleWall()
if State.Memory.TeleWallBusy then return end
local cam = Workspace.CurrentCamera
if not cam then Notify("Tele Wall", "Không tìm thấy camera", 4); return end
State.Memory.TeleWallBusy = true
HS.TeleWallFloat.Flash()
HS.TeleWallSaved = { Type = cam.CameraType, Subject = cam.CameraSubject, CFrame = cam.CFrame, Focus = cam.Focus }
cam.CameraType = Enum.CameraType.Scriptable
cam.CFrame = HS.TeleWallSaved.CFrame + HS.TeleWallSaved.CFrame.LookVector * 16
cam.Focus = HS.TeleWallSaved.Focus + HS.TeleWallSaved.CFrame.LookVector * 16
Notify("Tele Wall", "Đã dịch chuyển camera", 4)
task.delay(7, function()
if HS.TeleWallSaved then
local current = Workspace.CurrentCamera
if current then
current.CameraType = HS.TeleWallSaved.Type
current.CameraSubject = HS.TeleWallSaved.Subject
current.CFrame = HS.TeleWallSaved.CFrame
current.Focus = HS.TeleWallSaved.Focus
end
HS.TeleWallSaved = nil
end
State.Memory.TeleWallBusy = false
Notify("Tele Wall", "Camera đã trở về vị trí ban đầu", 3)
end)
end
HS.TeleWallFloat.OnTap(HS.ActivateTeleWall)
CreateToggle(HS.TabMem, "Tele Wall (hiện nút nổi camera)", false, function(on)
HS.TeleWallFloat.Show(on)
end)

-- Tele Wall 2: dịch chuyển nhân vật theo hướng nhìn; camera Roblox sẽ theo nhân vật.
function HS.ActivateTeleWall2()
local hrp, hum = GetHRP()
if not hrp or not hum or hum.Health <= 0 then
Notify("Tele Wall 2", "Không tìm thấy nhân vật đang hoạt động", 3)
return
end
local direction = hrp.CFrame.LookVector
local target = hrp.Position + direction * 16
local savedVelocity = hrp.AssemblyLinearVelocity
local ok = pcall(function()
hrp.CFrame = CFrame.new(target, target + direction)
hrp.AssemblyLinearVelocity = Vector3.zero
end)
if ok then
HS.TeleWall2Float.Flash()
Notify("Tele Wall 2", "Đã thử dịch chuyển khoảng 5 m theo hướng nhìn", 3)
else
Notify("Tele Wall 2", "Không thể dịch chuyển trong môi trường này", 3)
end
end
HS.TeleWall2Float.OnTap(HS.ActivateTeleWall2)
CreateToggle(HS.TabMem, "Tele Wall 2 (hiện nút nổi)", false, function(on)
HS.TeleWall2Float.Show(on)
end)

-- LockNV: giữ root tại chỗ, kể cả khi đang ở trên không; khôi phục trạng thái Anchored khi tắt.
;
HS.SetLockNV = function(on)
local hrp, hum = GetHRP()
if on then
if State.Memory.LockNV then return end
if not hrp or not hum or hum.Health <= 0 then
Notify("LockNV", "Không tìm thấy nhân vật", 3)
HS.LockNVFloat.SetOn(false)
return
end
State.Memory.LockNVData = {
Root = hrp, CFrame = hrp.CFrame, Anchored = hrp.Anchored,
LinearVelocity = hrp.AssemblyLinearVelocity, AngularVelocity = hrp.AssemblyAngularVelocity,
AutoRotate = hum.AutoRotate, Humanoid = hum
}
State.Memory.LockNV = true
pcall(function()
hum.AutoRotate = false
hrp.AssemblyLinearVelocity = Vector3.zero
hrp.AssemblyAngularVelocity = Vector3.zero
hrp.Anchored = true
end)
else
if not State.Memory.LockNV then return end
local data = State.Memory.LockNVData
State.Memory.LockNV = false
if data and data.Root and data.Root.Parent then
pcall(function()
data.Root.CFrame = data.CFrame
 data.Root.Anchored = data.Anchored
 data.Root.AssemblyLinearVelocity = data.LinearVelocity or Vector3.zero
 data.Root.AssemblyAngularVelocity = data.AngularVelocity or Vector3.zero
end)
end
if data and data.Humanoid and data.Humanoid.Parent then
pcall(function() data.Humanoid.AutoRotate = data.AutoRotate end)
end
State.Memory.LockNVData = nil
end
HS.LockNVFloat.SetOn(State.Memory.LockNV)
if HS.LockNVToggle then HS.LockNVToggle.Set(State.Memory.LockNV, false) end
Notify("LockNV", State.Memory.LockNV and "Đã khóa vị trí hiện tại" or "Đã khôi phục trạng thái", 3)
end
HS.LockNVToggle = CreateToggle(HS.TabMem, "LockNV · Đứng yên trên không", false, HS.SetLockNV)
CreateToggle(HS.TabMem, "LockNV (hiện nút nổi)", false, function(on)
HS.LockNVFloat.Show(on)
end)
HS.LockNVFloat.OnTap(function() HS.SetLockNV(not State.Memory.LockNV) end)

HS.SpeedTimeSaved = 16
function HS.SetSpeedTime(on)
State.Memory.SpeedTime = on
HS.SpeedTimeFloat.SetOn(on)
local _, hum = GetHRP()
if on then
if hum then HS.SpeedTimeSaved = hum.WalkSpeed; hum.WalkSpeed = 40 end
Notify("Speed Time", "Đã bật tốc độ di chuyển tăng cường", 4)
else
if hum then hum.WalkSpeed = State.Player.SpeedOn and State.Player.Speed or HS.SpeedTimeSaved end
Notify("Speed Time", "Đã khôi phục tốc độ di chuyển", 3)
end
end
HS.SpeedTimeFloat.OnTap(function() HS.SetSpeedTime(not State.Memory.SpeedTime) end)
CreateToggle(HS.TabMem, "Speed Time (hiện nút nổi)", false, function(on)
HS.SpeedTimeFloat.Show(on)
end)

;
function HS.SetFlyUpX2(on)
if on and (State.Memory.FlyEnabled or State.Under.Enabled) then
Notify("Fly X2", "Hãy tắt Fly và Under Plan trước", 4)
State.Memory.FlyUpX2 = false
HS.FlyUpX2Float.SetOn(false)
if HS.FlyUpX2Toggle then HS.FlyUpX2Toggle.Set(false, false) end
return
end
State.Memory.FlyUpX2 = on and true or false
HS.FlyUpX2Float.SetOn(State.Memory.FlyUpX2)
if HS.FlyUpX2Toggle then HS.FlyUpX2Toggle.Set(State.Memory.FlyUpX2, false) end
Notify("Fly X2", State.Memory.FlyUpX2 and "Đã bật chuyển động lên/xuống mượt" or "Đã tắt Fly X2", 3)
end
HS.FlyUpX2Toggle = CreateToggle(HS.TabMem, "Fly UpX2", false, HS.SetFlyUpX2)
CreateToggle(HS.TabMem, "Hiện nút nổi Fly X2", false, function(on) HS.FlyUpX2Float.Show(on) end)
HS.FlyUpX2Float.OnTap(function() HS.SetFlyUpX2(not State.Memory.FlyUpX2) end)

CreateSlider(HS.TabMem, "WalkSpeed", 1, 300, 16, function(v) State.Player.Speed = v end)
CreateToggle(HS.TabMem, "Bật WalkSpeed", false, function(s)
local _, hum = GetHRP()
if s then
if hum then State.Player.DefSpeed = hum.WalkSpeed end
State.Player.SpeedOn = true
else
State.Player.SpeedOn = false
if hum then hum.WalkSpeed = State.Player.DefSpeed end
end
end)
CreateSlider(HS.TabMem, "JumpPower", 1, 500, 50, function(v) State.Player.Jump = v end)
CreateToggle(HS.TabMem, "Bật JumpPower", false, function(s)
local _, hum = GetHRP()
if s then
if hum then pcall(function() State.Player.DefJump = hum.JumpPower end) end
State.Player.JumpOn = true
else
State.Player.JumpOn = false
if hum then pcall(function() hum.JumpPower = State.Player.DefJump end) end
end
end)
CreateToggle(HS.TabMem, "Infinite Jump", false, function(s) State.Player.InfJump = s end)
CreateToggle(HS.TabMem, "Noclip", false, function(s) State.Player.Noclip = s end)

function HS.IsCharacterPart(part)
local cur = part.Parent
while cur and cur ~= Workspace do
if cur:IsA("Model") and cur:FindFirstChildOfClass("Humanoid") then return true end
cur = cur.Parent
end
return false
end

function HS.HidePart(part)
if HS.UnderHidden[part] then return end
if not part:IsA("BasePart") then return end
if HS.IsCharacterPart(part) then return end
HS.UnderHidden[part] = true
pcall(function() part.LocalTransparencyModifier = 1 end)
end

function HS.HideAllTerrainParts()
task.spawn(function()
local n = 0
for _, d in ipairs(Workspace:GetDescendants()) do
if not State.Under.Enabled or not State.Under.Hide or Unloaded then return end
HS.HidePart(d)
n = n + 1
if n % 400 == 0 then task.wait() end
end
end)
end

function HS.RestoreHidden()
for part in pairs(HS.UnderHidden) do
if part and part.Parent then
pcall(function() part.LocalTransparencyModifier = 0 end)
end
end
ClearTableCompat(HS.UnderHidden)
end

Connections[#Connections + 1] = Workspace.DescendantAdded:Connect(function(d)
if State.Under.Enabled and State.Under.Hide and not Unloaded then
task.defer(HS.HidePart, d)
end
end)

function HS.FixCharacters()
for _, plr in ipairs(Players:GetPlayers()) do
local char = plr.Character
if char then
for _, p in ipairs(char:GetDescendants()) do
if p:IsA("BasePart") and HS.UnderHidden[p] then
HS.UnderHidden[p] = nil
pcall(function() p.LocalTransparencyModifier = 0 end)
end
end
end
end
end

function HS.SetUnder(on)
local U = State.Under
if on == U.Enabled then return end
U.RunToken = U.RunToken + 1
local runToken = U.RunToken
local hrp, hum = GetHRP()
if on then
if not hrp or not hum then
Notify("Under Plan", "Chưa có nhân vật", 5)
HS.UnderFloat.SetOn(false)
return
end
if State.Memory.FlyEnabled then HS.SetFly(false) end
pcall(function() HS.Invis.Set(true) end)
Notify("Under Plan+Invisibility", "Đang bật Under và tàng hình cục bộ", 3)
if Unloaded then return end
hrp, hum = GetHRP()
if not hrp or not hum then
U.Enabled = false
HS.UnderFloat.SetOn(false)
return
end
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { LocalPlayer.Character }
params.IgnoreWater = true
local res = Workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), params)
U.OverPos = hrp.Position
U.GroundY = res and res.Position.Y or (hrp.Position.Y - 3)
U.Y = U.GroundY - U.Depth
U.Enabled = true
hrp.CFrame = CFrame.new(hrp.Position.X, U.Y, hrp.Position.Z)
pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
HS.UnderFloat.SetOn(true)
if U.Hide then HS.HideAllTerrainParts() end
if U.Duration > 0 then
    task.delay(U.Duration, function()
        if not Unloaded and U.Enabled and U.RunToken == runToken then
            HS.SetUnder(false)
            Notify("Under Plan+Invisibility", "Hết thời gian; đã khôi phục", 3)
        end
    end)
end
else
U.Enabled = false
HS.RestoreHidden()
HS.UnderFloat.SetOn(false)
pcall(function() HS.Invis.Set(false) end)
pcall(function() if HS.GhostEnabled then HS.SetGhost(false) end end)
if hrp then
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { LocalPlayer.Character }
params.IgnoreWater = true
local baseY = (U.OverPos and U.OverPos.Y) or (U.GroundY or hrp.Position.Y) + 5
local origin = Vector3.new(hrp.Position.X, baseY + 150, hrp.Position.Z)
local res = Workspace:Raycast(origin, Vector3.new(0, -1000, 0), params)
local dest
if res then
dest = res.Position + Vector3.new(0, 4, 0)
elseif U.OverPos then
dest = U.OverPos + Vector3.new(0, 3, 0)
else
dest = hrp.Position + Vector3.new(0, 50, 0)
end
hrp.CFrame = CFrame.new(dest)
pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
end
if hum then hum.PlatformStand = false end
end
end

function HS.ForceUnderOff()
State.Under.Enabled = false
HS.RestoreHidden()
HS.UnderFloat.SetOn(false)
end

function HS.UpdateUnder(dt, hrp, hum)
local U = State.Under
if not U.Enabled or not hrp or not hum then return end
hum.PlatformStand = true
local move = hum.MoveDirection
local vy = math.clamp((U.Y - hrp.Position.Y) * 8, -80, 80)
hrp.AssemblyLinearVelocity = Vector3.new(move.X * U.Speed, vy, move.Z * U.Speed)
hrp.AssemblyAngularVelocity = Vector3.zero
local _, yaw = hrp.CFrame:ToEulerAnglesYXZ()
hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0)
end

CreateHeader(HS.TabMem, "UNDER PLAN + INVISIBILITY")
CreateLabel(HS.TabMem, "Bật Under sẽ bật tàng hình cục bộ; thời gian tự tắt có thể chỉnh bên dưới.", C.Sub)
CreateSlider(HS.TabMem, "Thời gian Under + Invisibility (0 = thủ công, 1–5s tự tắt)", 0, 5, 0, function(v)
    State.Under.Duration = math.clamp(v, 0, 5)
end)
CreateToggle(HS.TabMem, "Under Plan + Invisibility (hiện nút nổi)", false, function(s)
HS.UnderFloat.Show(s)
if not s and State.Under.Enabled then HS.SetUnder(false) end
end)
CreateSlider(HS.TabMem, "Độ sâu dưới mặt đất", 5, 300, 30, function(v)
State.Under.Depth = v
if State.Under.Enabled and State.Under.GroundY then
State.Under.Y = State.Under.GroundY - v
end
end)
CreateSlider(HS.TabMem, "Tốc độ di chuyển Under", 1, 200, 40, function(v) State.Under.Speed = v end)
CreateToggle(HS.TabMem, "Ẩn địa hình khi Under", true, function(s)
State.Under.Hide = s
if State.Under.Enabled then
if s then HS.HideAllTerrainParts() else HS.RestoreHidden() end
end
end)
HS.UnderFloat.OnTap(function() HS.SetUnder(not State.Under.Enabled) end)

CreateHeader(HS.TabMem, "TIỆN ÍCH")
function HS.SetFullbright(on)
if on then
if not HS.LightOrig then
HS.LightOrig = {
Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient
}
end
Lighting.Brightness = 2
Lighting.ClockTime = 14
Lighting.FogEnd = 100000
Lighting.GlobalShadows = false
Lighting.Ambient = Color3.fromRGB(200, 200, 200)
Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
elseif HS.LightOrig then
for k, v in pairs(HS.LightOrig) do
pcall(function() Lighting[k] = v end)
end
HS.LightOrig = nil
end
end
CreateToggle(HS.TabMem, "Fullbright", false, HS.SetFullbright)
CreateToggle(HS.TabMem, "Anti-AFK", false, function(s) State.Player.AntiAFK = s end)

Connections[#Connections + 1] = LocalPlayer.Idled:Connect(function()
if State.Player.AntiAFK then
pcall(function()
local vu = game:GetService("VirtualUser")
vu:CaptureController()
vu:ClickButton2(Vector2.new())
end)
end
end)

Connections[#Connections + 1] = UserInputService.JumpRequest:Connect(function()
if State.Player.InfJump then
local _, hum = GetHRP()
if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end
end)

Connections[#Connections + 1] = RunService.Stepped:Connect(function()
if (State.Player.Noclip or State.Under.Enabled) and LocalPlayer.Character then
for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
if part:IsA("BasePart") then part.CanCollide = false end
end
end
end)

function HS.RestorePlayer()
local _, hum = GetHRP()
if hum then
pcall(function() hum.WalkSpeed = State.Player.DefSpeed end)
pcall(function() hum.JumpPower = State.Player.DefJump end)
end
end

Connections[#Connections + 1] = LocalPlayer.CharacterAdded:Connect(function()
State.Memory.InSky = false
if State.Memory.TeleSky2 then pcall(function() HS.SetTeleSky2(false) end) end
if State.Memory.FastTalk then pcall(function() HS.SetFastTalk(false) end) end
if State.Memory.FastAttack then pcall(function() HS.SetFastAttack(false) end) end
State.Memory.LockNV = false
State.Memory.LockNVData = nil
HS.LockNVFloat.SetOn(false)
HS.SkyFloat.SetOn(false)
if State.Under.Enabled then HS.ForceUnderOff() end
HS.DestroyFlyBodies()
end)

HS.TabSet = CreateTab("Setting")
CreateHeader(HS.TabSet, "ÂM THANH")
CreateToggle(HS.TabSet, "Âm thanh nút bấm (tíc)", true, function(s) State.Settings.Sound = s end)
CreateSlider(HS.TabSet, "Âm lượng (%)", 0, 100, 80, function(v) State.Settings.Volume = v end)

CreateHeader(HS.TabSet, "GIAO DIỆN")
CreateSlider(HS.TabSet, "Cỡ menu (%)", 50, 160, math.floor(HS.startScale * 100), function(v) HS.MainScale.Scale = v / 100 end)
CreateButton(HS.TabSet, "Đưa menu về giữa màn hình", function()
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
end)
CreateLabel(HS.TabSet, "Phiên bản: " .. TITLE_RICH)

CreateHeader(HS.TabSet, "HỆ THỐNG")

function HS.Unload()
if Unloaded then return end
Unloaded = true
HS.BannerActive = false
pcall(function() HS.SetFly(false) end)
State.Memory.FlyUpX2 = false
pcall(function() local r = GetHRP(); if r then local v = r.AssemblyLinearVelocity; r.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z) end end)
pcall(HS.DestroyFlyBodies)
pcall(function()
State.Under.Enabled = false
HS.RestoreHidden()
end)
pcall(HS.ClearChams)
pcall(function() HS.Invis.Set(false) end)
pcall(function() if HS.GhostEnabled then HS.SetGhost(false) end end)
pcall(function() HS.SetSpinPlayer(false) end)
pcall(function() if State.Memory.LockNV then HS.SetLockNV(false) end end)
pcall(function() if State.Memory.SpeedTime then HS.SetSpeedTime(false) end end)
pcall(function()
if HS.TeleWallSaved and Workspace.CurrentCamera then
Workspace.CurrentCamera.CameraType = HS.TeleWallSaved.Type
Workspace.CurrentCamera.CameraSubject = HS.TeleWallSaved.Subject
Workspace.CurrentCamera.CFrame = HS.TeleWallSaved.CFrame
Workspace.CurrentCamera.Focus = HS.TeleWallSaved.Focus
HS.TeleWallSaved = nil
end
end)
pcall(HS.RestorePlayer)
pcall(function() HS.SetFullbright(false) end)
pcall(function() if State.Memory.TeleSky2 then HS.SetTeleSky2(false) end end)
pcall(function() if State.Memory.FastTalk then HS.SetFastTalk(false) end end)
pcall(function() if State.Memory.FastAttack then HS.SetFastAttack(false) end end)
pcall(function() HS.SetAutoHeal(false) end)
pcall(function() HS.SetFreezeMarker(false) end)
pcall(function() RunService:UnbindFromRenderStep("HyperSunAim") end)
for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
ClearTableCompat(Connections)
for plr in pairs(ESPObjects) do HS.RemoveESP(plr) end
for _, d in pairs(Drawings) do pcall(function() d:Remove() end) end
ClearTableCompat(Drawings)
pcall(function() HS.ClickSound:Destroy() end)
pcall(function() ScreenGui:Destroy() end)
pcall(function() HS.NotifyGui:Destroy() end)
end
Env.HyperSunUnload = HS.Unload

CreateButton(HS.TabSet, "Gỡ script (Unload)", HS.Unload)

SelectTab("Function")

HS.fpsTimer, HS.fpsFrames = 0, 0
HS.fixTimer = 0
HS.FeatureErrorShown = {}
function HS.SafeFeatureCall(featureName, fn, ...)
    local args = {...}
    local ok, err = pcall(function() fn(table.unpack(args)) end)
    if not ok then
        warn("[HyperSun 2.4 Beta] " .. tostring(featureName) .. ": " .. tostring(err))
        if not HS.FeatureErrorShown[featureName] then
            HS.FeatureErrorShown[featureName] = true
            pcall(function()
                Notify("HyperSun · Lỗi chức năng", tostring(featureName) .. ": " .. tostring(err), 8)
            end)
        end
    end
    return ok
end

function HS.GetPing()
local ok, v = pcall(function()
return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
end)
if ok and v then return math.floor(v) end
return 0
end

Connections[#Connections + 1] = RunService.RenderStepped:Connect(function(dt)
if Unloaded then return end
Camera = Workspace.CurrentCamera or Camera

HS.fpsTimer = HS.fpsTimer + dt
HS.fpsFrames = HS.fpsFrames + 1
if HS.fpsTimer >= 0.5 then
HS.FooterStats.Text = "FPS " .. math.floor(HS.fpsFrames / HS.fpsTimer + 0.5)
.. "  |  Ping " .. HS.GetPing() .. " ms  |  Players " .. #Players:GetPlayers()
HS.fpsTimer, HS.fpsFrames = 0, 0
end

if State.Under.Enabled then
HS.fixTimer = HS.fixTimer + dt
if HS.fixTimer >= 1 then
HS.fixTimer = 0
HS.SafeFeatureCall("FixCharacters", HS.FixCharacters)
end
end

HS.SafeFeatureCall("UpdateESP", HS.UpdateESP)
HS.SafeFeatureCall("UpdateChams", HS.UpdateChams)

local hrp, hum = GetHRP()

if HS.SpinPlayer.Enabled and hrp and hum and hum.Health > 0 then
    HS.SpinPlayer.Angle = HS.SpinPlayer.Angle + math.rad(90 * HS.SpinPlayer.Speed) * dt
    pcall(function()
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, HS.SpinPlayer.Angle, 0)
    end)
end

if State.Memory.FlyUpX2 and hrp and hum and hum.Health > 0 and not State.Memory.FlyEnabled and not State.Under.Enabled then
local phase = os.clock() * 2.4
local verticalVelocity = math.sin(phase) * 10
pcall(function()
local velocity = hrp.AssemblyLinearVelocity
hrp.AssemblyLinearVelocity = Vector3.new(velocity.X, verticalVelocity, velocity.Z)
end)
end

if hum then
if State.Memory.SpeedTime then hum.WalkSpeed = 40
elseif State.Player.SpeedOn then hum.WalkSpeed = State.Player.Speed end
if State.Player.JumpOn then
pcall(function()
hum.UseJumpPower = true
hum.JumpPower = State.Player.Jump
end)
end
end

HS.SafeFeatureCall("UpdateFly", HS.UpdateFly, dt, hrp, hum)
HS.SafeFeatureCall("UpdateUnder", HS.UpdateUnder, dt, hrp, hum)
end)

Connections[#Connections + 1] = LocalPlayer.OnTeleport:Connect(function()
pcall(HS.Unload)
end)
