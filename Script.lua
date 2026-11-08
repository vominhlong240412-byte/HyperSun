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
local Stats = nil
pcall(function() Stats = game:GetService("Stats") end)

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
    Panel  = Color3.fromRGB(8,  7,  11),
    Item   = Color3.fromRGB(22, 10, 16),
    Tab    = Color3.fromRGB(32, 8,  14),
    Accent = Color3.fromRGB(255, 38, 60),
    Text   = Color3.fromRGB(252, 248, 250),
    Sub    = Color3.fromRGB(190, 160, 168),
    Off    = Color3.fromRGB(50,  28, 36),
    Knob   = Color3.fromRGB(255, 255, 255),
    Gold   = Color3.fromRGB(255, 200, 40),
    Green  = Color3.fromRGB(50,  210, 100),
    Blue   = Color3.fromRGB(55,  140, 255),
}
local FONT_B     = Enum.Font.GothamBlack
local FONT_N     = Enum.Font.GothamSemibold
local FONT_TITLE = Enum.Font.GothamBlack
local FONT_MONO  = Enum.Font.Code
local TI         = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_SLOW    = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local WIN_W, WIN_H = 460, 360
local TITLE_RICH   = '<font color="#FF2640">✦ HyperSun</font> <font color="#FFFFFF">3.2 Beta</font>'
local INJ_VERSION  = "3.2 Beta Normal"   -- overwritten by inject choice
local INJECT_TIER  = "normal"            -- "normal" | "max" | "beta"
local PAID_CODE    = nil                 -- set when Pay Inject succeeds
local LocTeleUnlocked = false            -- true for Max/Beta inject

local HttpService = game:GetService("HttpService")
local Notify, GetHRP
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

-- Settings persistence (executor file API when available; falls back to session memory).
HS.SettingsFolder = "HyperSun"
HS.SettingsFile = "HyperSun/HyperSun_3.1_Elite_Settings.json"
HS.SavedSettingsCache = nil
function HS.BuildSettingsSnapshot()
    return {
        Player = {
            Speed = State.Player.Speed, Jump = State.Player.Jump,
            SpeedOn = State.Player.SpeedOn, JumpOn = State.Player.JumpOn,
            InfJump = State.Player.InfJump, Noclip = State.Player.Noclip,
            AntiAFK = State.Player.AntiAFK
        },
        Memory = {
            FlyHeight = State.Memory.FlyHeight, FlySpeed = State.Memory.FlySpeed,
            TeleSkyHeight = State.Memory.TeleSkyHeight, SpeedTime = State.Memory.SpeedTime,
            FastTalk = State.Memory.FastTalk, FastAttack = State.Memory.FastAttack
        },
        ESP = {
            Skeleton = State.ESP.Skeleton, Box = State.ESP.Box, Count = State.ESP.Count,
            Line = State.ESP.Line, Name = State.ESP.Name, Health = State.ESP.Health,
            MaxDist = State.ESP.MaxDist
        },
        Aimbot = {
            FOV = State.Aimbot.FOV, Smooth = State.Aimbot.Smooth,
            Head = State.Aimbot.Head, ShowFOV = State.Aimbot.ShowFOV
        },
        Under = {
            Depth = State.Under.Depth, Speed = State.Under.Speed,
            Hide = State.Under.Hide, Duration = State.Under.Duration
        },
        Settings = { Sound = State.Settings.Sound, Volume = State.Settings.Volume }
    }
end
function HS.SaveSettings()
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(HS.BuildSettingsSnapshot())
    end)
    if not ok then
        Notify("HyperSun 3.1 Elite", "Không thể tạo dữ liệu setting", 4)
        return false
    end
    HS.SavedSettingsCache = encoded
    local wrote = false
    if type(writefile) == "function" then
        wrote = pcall(function()
            if type(isfolder) == "function" and type(makefolder) == "function" then
                local folderExists = false
                pcall(function() folderExists = isfolder(HS.SettingsFolder) end)
                if not folderExists then makefolder(HS.SettingsFolder) end
            end
            writefile(HS.SettingsFile, encoded)
            if type(readfile) == "function" then
                local verify = readfile(HS.SettingsFile)
                assert(type(verify) == "string" and #verify > 0, "verify failed")
                assert(HttpService:JSONDecode(verify), "invalid saved JSON")
            end
        end)
    end
    if wrote then
        Notify("HyperSun 3.1 Elite", "Đã lưu và kiểm tra file setting: " .. HS.SettingsFile, 4)
    else
        Notify("HyperSun 3.1 Elite", "Không thể ghi file. Hãy kiểm tra file API/quyền của executor.", 5)
    end
    return wrote
end
function HS.LoadSettings()
    local encoded = nil
    if type(isfile) == "function" and type(readfile) == "function" then
        local exists, yes = pcall(function() return isfile(HS.SettingsFile) end)
        if exists and yes then
            local ok, data = pcall(function() return readfile(HS.SettingsFile) end)
            if ok then encoded = data end
        end
    end
    if type(encoded) ~= "string" and (type(readfile) ~= "function" or type(isfile) ~= "function") then
        encoded = HS.SavedSettingsCache
    end
    if type(encoded) ~= "string" then
        Notify("HyperSun 3.1 Elite", "Chưa có setting đã lưu. Hãy bấm Lưu setting trước.", 4)
        return false
    end
    local ok, data = pcall(function() return HttpService:JSONDecode(encoded) end)
    if not ok or type(data) ~= "table" then
        Notify("HyperSun 3.1 Elite", "File setting không hợp lệ", 4)
        return false
    end
    if type(data.Player) == "table" then
        for k, v in pairs(data.Player) do if State.Player[k] ~= nil then State.Player[k] = v end end
    end
    if type(data.Memory) == "table" then
        for k, v in pairs(data.Memory) do if State.Memory[k] ~= nil then State.Memory[k] = v end end
    end
    if type(data.ESP) == "table" then
        for k, v in pairs(data.ESP) do if State.ESP[k] ~= nil then State.ESP[k] = v end end
    end
    if type(data.Aimbot) == "table" then
        for k, v in pairs(data.Aimbot) do if State.Aimbot[k] ~= nil then State.Aimbot[k] = v end end
    end
    if type(data.Under) == "table" then
        for k, v in pairs(data.Under) do if State.Under[k] ~= nil then State.Under[k] = v end end
    end
    if type(data.Settings) == "table" then
        for k, v in pairs(data.Settings) do if State.Settings[k] ~= nil then State.Settings[k] = v end end
    end
    State.Player.Speed = math.clamp(tonumber(State.Player.Speed) or 16, 1, 10000)
    State.Player.Jump = math.clamp(tonumber(State.Player.Jump) or 50, 1, 500)
    local _, hum = (type(GetHRP) == "function" and GetHRP()) or (nil, nil)
    if hum then
        pcall(function()
            if State.Player.SpeedOn then hum.WalkSpeed = State.Player.Speed end
            if State.Player.JumpOn then hum.JumpPower = State.Player.Jump end
        end)
    end
    if HS.SetFlySpeed and State.Memory.FlyEnabled then pcall(function() HS.SetFlySpeed(State.Memory.FlySpeed) end) end
    Notify("HyperSun 3.1 Elite", "Đã nạp dữ liệu setting. Một số nút giao diện có thể chưa cập nhật trạng thái hiển thị.", 4)
    return true
end

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

GetHRP = function()
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

Notify = function(title, text, duration)
duration = duration or 5
if Unloaded then return end
local frame = Create("Frame", {
Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.Panel,
BackgroundTransparency = 0.04, BorderSizePixel = 0, Position = UDim2.new(0, 24, 0, 0)
}, HS.NotifyContainer)
Create("UICorner", { CornerRadius = UDim.new(0, 11) }, frame)
Create("UIStroke", { Color = C.Accent, Thickness = 1.35, Transparency = 0.12 }, frame)
Create("UIGradient", { Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 8, 16)), ColorSequenceKeypoint.new(1, C.Panel)}), Rotation = 15 }, frame)
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
if HS.Invis.Enabled then task.spawn(function() if HS.Invis.Enabled and inst.Parent then HS.InvisHide(inst) end end) end
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
Notify("HyperSun 3.1 Elite loaded", "✦ Hyper Sun 3.1 Elite — Ready", 5)
task.wait(5)
if Unloaded then return end
Notify("Lib loading", "Hyper Sun 3.1 Elite — OK", 5)
task.wait(5)
if Unloaded then return end
Notify("64bit", "Hyper Sun 3.1 Elite — 64bit OK", 5)
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
CanvasSize = UDim2.new(0, 0, 0, 0), CanvasSize = UDim2.new(0, 0, 10, 0)
}, HS.Body)
Create("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, HS.Sidebar)

local Content = Create("ScrollingFrame", {
Size = UDim2.new(1, -136, 1, -38), Position = UDim2.new(0, 128, 0, 0),
BackgroundColor3 = Color3.fromRGB(10, 7, 8), BackgroundTransparency = 0.18,
BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Accent,
CanvasSize = UDim2.new(0, 0, 0, 0), CanvasSize = UDim2.new(0, 0, 10, 0)
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
    local full = "Hyper Sun 3.1 Elite"
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
Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false
}, Content)
pcall(function() frame.AutomaticSize = Enum.AutomaticSize.Y end)
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
Text = text, TextColor3 = C.Text, Font = FONT_N, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
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
Text = text, TextColor3 = C.Text, Font = FONT_N, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
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
local step = 34
for i, frame in ipairs(visible) do
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, (i - (#visible + 1) / 2) * step)
frame.ZIndex = 50 + i
end
end
function HS.CreateFloat(label, y)
local f = Create("Frame", {
Size = UDim2.new(0, 124, 0, 29), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.Panel,
BackgroundTransparency = 0.1, Visible = false, ZIndex = 50
}, ScreenGui)
table.insert(HS.FloatingFrames, f)
Create("UICorner", { CornerRadius = UDim.new(0, 7) }, f)
Create("UIStroke", { Color = C.Accent, Thickness = 1, Transparency = 0.4 }, f)
Create("TextLabel", {
Size = UDim2.new(1, -58, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1,
Text = label, TextColor3 = C.Text, Font = FONT_B, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
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
Notify("Patched AntiBan 3.1 Elite", "Trạng thái giao diện; không bảo đảm chống ban", 5)
else
Notify("AntiBan UI đã tắt", "Không có bảo vệ chống ban thực sự", 4)
end
end)

CreateHeader(HS.TabFunc, "THÔNG TIN SCRIPT")
CreateLabel(HS.TabFunc, "Kiểm tra tương thích: không thực hiện bypass AntiCheat hoặc thay đổi logic game.", C.Sub)
HS.activationTime = os.date("%Y-%m-%d %H:%M:%S")
CreateLabel(HS.TabFunc, "Username Roblox: " .. tostring(LocalPlayer.Name), C.Text)
CreateLabel(HS.TabFunc, "Tên game: " .. tostring(game.Name) .. " · PlaceId: " .. tostring(game.PlaceId), C.Text)
CreateLabel(HS.TabFunc, "Giờ kích hoạt: " .. HS.activationTime, C.Sub)
CreateLabel(HS.TabFunc, "Thời hạn key: N/A", C.Sub)
CreateLabel(HS.TabFunc, "AntiBan: Active (trạng thái hiển thị)", C.Sub)
CreateLabel(HS.TabFunc, "Anti Kick: N/A", C.Sub)
CreateLabel(HS.TabFunc, "Ghi chú: ESP/Aim có thể vi phạm quy tắc game; không có tính năng bất tử được bảo đảm.", C.Sub)
CreateLabel(HS.TabFunc, "Memory/Tele không có bảo đảm Anti 50%.", C.Sub)
CreateLabel(HS.TabFunc, "By: Hyper Sun 3.1 Elite", C.Text)

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
HS.GhostFloat = HS.CreateFloat("TeleGhost", 462)
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

-- (moved to HS)

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

CreateHeader(HS.TabFly, "TELE GHOST")
CreateButton(HS.TabFly, "Tạo nút nổi TeleGhost", function()
    HS.GhostFloat.Show(true)
    Notify("HyperSun 3.1 Elite · TeleGhost", "Đã hiện nút nổi TeleGhost", 3)
end)
CreateButton(HS.TabFly, "Bật / Tắt TeleGhost", function() HS.SetGhost(not HS.GhostEnabled) end)
CreateLabel(HS.TabFly, "Bật để điều khiển bản sao; tắt để xác nhập hồn tại vị trí bản sao. Hiệu ứng chỉ được xử lý ở máy bạn.", C.Sub)

CreateHeader(HS.TabFly, "TELE PLAYER")
HS.TeleTarget = nil
HS.DropdownBtn = CreateButton(HS.TabFly, "Chọn Player")
HS.dropFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 110), BackgroundColor3 = C.Item, BackgroundTransparency = 0.2, Visible = false }, HS.TabFly)
Create("UICorner", { CornerRadius = UDim.new(0, 7) }, HS.dropFrame)
HS.dropScroll = Create("ScrollingFrame", {
Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
CanvasSize = UDim2.new(0, 0, 0, 0), CanvasSize = UDim2.new(0, 0, 10, 0)
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
task.spawn(HS.refreshPlayers)
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
        HS.FreezeConnection = RunService.Heartbeat:Connect(function()
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
            local characterChanged = best and best.Character and HS.FreezeHighlight and HS.FreezeHighlight.Adornee ~= best.Character
            if best ~= HS.FreezeTarget or characterChanged or (best and not HS.FreezeHighlight) then
                HS.ClearFreezeMarker()
                HS.FreezeTarget = best
                if best and best.Character then
                    local ok, h = pcall(function()
                        local hl = Instance.new("Highlight")
                        hl.Name = "HyperSun_FreezeMarker"
                        hl.Adornee = best.Character
                        hl.FillColor = C.Accent
                        hl.OutlineColor = Color3.fromRGB(255, 245, 245)
                        hl.FillTransparency = 0.48
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = ScreenGui
                        return hl
                    end)
                    if ok then HS.FreezeHighlight = h end
                end
            elseif not best and HS.FreezeHighlight then
                HS.ClearFreezeMarker()
            end
        end)
        Notify("HyperSun 3.1 Elite · Freeze", "Đã bật đánh dấu mục tiêu gần tâm ngắm", 4)
    else
        Notify("HyperSun 3.1 Elite · Freeze", "Đã tắt đánh dấu mục tiêu", 3)
    end
end
HS.FreezeFloat.OnTap(function() HS.SetFreezeMarker(not HS.FreezeEnabled) end)
CreateToggle(HS.TabMem, "Hiện nút nổi Freeze", false, function(on) HS.FreezeFloat.Show(on) end)
CreateLabel(HS.TabMem, "Freeze chỉ đánh dấu mục tiêu cục bộ. Đóng băng người chơi khác cần quyền xử lý phía máy chủ của game.", C.Sub)

-- Tele Backpack / Tele X3: locally rendered Free-Fire-inspired glider.
HS.TeleX3Enabled = false
HS.TeleX3Objects = {}
HS.TeleX3SavedMotors = {}
HS.TeleX3Float = HS.CreateFloat("Tele X3", 666)
function HS.ClearTeleX3()
    for _, obj in ipairs(HS.TeleX3Objects) do pcall(function() obj:Destroy() end) end
    HS.TeleX3Objects = {}
    for motor, saved in pairs(HS.TeleX3SavedMotors) do
        if motor and motor.Parent then pcall(function() motor.Transform = saved end) end
    end
    HS.TeleX3SavedMotors = {}
end
function HS.SetTeleX3(on)
    HS.TeleX3Enabled = on and true or false
    HS.TeleX3Float.SetOn(HS.TeleX3Enabled)
    HS.ClearTeleX3()
    if not HS.TeleX3Enabled then
        Notify("HyperSun 3.1 Elite · Tele X3", "Đã tắt dù lượn và khôi phục tư thế", 3)
        return
    end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or not root then
        HS.TeleX3Enabled = false
        HS.TeleX3Float.SetOn(false)
        Notify("HyperSun 3.1 Elite · Tele X3", "Nhân vật chưa sẵn sàng", 4)
        return
    end
    for _, motor in ipairs(char:GetDescendants()) do
        if motor:IsA("Motor6D") and (motor.Name == "RightShoulder" or motor.Name == "LeftShoulder" or motor.Name == "Right Shoulder" or motor.Name == "Left Shoulder") then
            HS.TeleX3SavedMotors[motor] = motor.Transform
            pcall(function() motor.Transform = CFrame.Angles(0, 0, motor.Name:find("Left") and -math.rad(145) or math.rad(145)) end)
        end
    end
    local model = Instance.new("Model")
    model.Name = "HyperSun_TeleX3_Glider"
    model.Parent = char
    local function part(name, size, cf, color, material, shape)
        local obj = Instance.new("Part")
        obj.Name = name
        obj.Size = size
        obj.CFrame = cf
        obj.Color = color
        obj.Material = material or Enum.Material.SmoothPlastic
        obj.Shape = shape or Enum.PartType.Block
        obj.Anchored = false
        obj.CanCollide = false
        obj.CanTouch = false
        obj.CanQuery = false
        obj.Massless = true
        obj.CastShadow = false
        obj.Parent = model
        table.insert(HS.TeleX3Objects, obj)
        return obj
    end
    local origin = root.CFrame
    local function at(x, y, z, rx, ry, rz)
        return origin * CFrame.new(x, y, z) * CFrame.Angles(rx or 0, ry or 0, rz or 0)
    end
    local function weldToRoot(obj)
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = obj
        weld.Parent = obj
    end
    -- Curved-looking canopy assembled from overlapping colored fabric panels.
    local panels = {
        {-2.65, 0.05, 0.00, Color3.fromRGB(210, 20, 35), -12},
        {-1.62, 0.28, 0.00, Color3.fromRGB(245, 245, 245), -7},
        {-0.56, 0.43, 0.00, Color3.fromRGB(18, 18, 22), -3},
        { 0.56, 0.43, 0.00, Color3.fromRGB(235, 28, 45), 3},
        { 1.62, 0.28, 0.00, Color3.fromRGB(245, 245, 245), 7},
        { 2.65, 0.05, 0.00, Color3.fromRGB(210, 20, 35), 12}
    }
    for i, panel in ipairs(panels) do
        part("CanopyPanel_" .. i, Vector3.new(1.18, 0.16, 1.75), at(panel[1], 5.65 + panel[2], panel[3], 0, 0, math.rad(panel[5])), panel[4], Enum.Material.SmoothPlastic)
    end
    part("CanopyFrontRim", Vector3.new(5.65, 0.12, 0.12), at(0, 5.58, -0.82), Color3.fromRGB(245, 35, 48), Enum.Material.SmoothPlastic)
    part("CanopyRearRim", Vector3.new(5.4, 0.1, 0.1), at(0, 5.7, 0.82), Color3.fromRGB(12, 12, 15), Enum.Material.SmoothPlastic)
    part("CenterBadge", Vector3.new(0.5, 0.08, 0.35), at(0, 6.0, 0), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
    -- Suspension lines from canopy to the player's hand area.
    for i = -2, 2 do
        local x = i * 0.85
        local line = part("SuspensionLine_" .. tostring(i), Vector3.new(0.035, 2.65, 0.035), at(x * 0.78, 3.95, 0, 0, 0, math.rad(i * 7)), Color3.fromRGB(225, 225, 225), Enum.Material.SmoothPlastic)
    end
    part("HarnessBack", Vector3.new(1.0, 1.25, 0.22), at(0, 1.25, 0.45), Color3.fromRGB(22, 22, 26), Enum.Material.SmoothPlastic)
    part("HarnessRedStripe", Vector3.new(0.12, 1.0, 0.06), at(0, 1.25, 0.31), Color3.fromRGB(240, 28, 45), Enum.Material.Neon)
    for _, obj in ipairs(HS.TeleX3Objects) do weldToRoot(obj) end
    Notify("HyperSun 3.1 Elite · Tele X3", "Đã bật dù lượn phong cách battle-royale (hiển thị cục bộ)", 4)
end
HS.TeleX3Float.OnTap(function() HS.SetTeleX3(not HS.TeleX3Enabled) end)
CreateHeader(HS.TabFly, "TELE BACKPACK")
CreateButton(HS.TabFly, "Tele X3 · Bật / Tắt dù lượn", function() HS.SetTeleX3(not HS.TeleX3Enabled) end)
CreateToggle(HS.TabFly, "Hiện nút nổi Tele X3", false, function(on) HS.TeleX3Float.Show(on) end)
CreateLabel(HS.TabFly, "Dù lượn và tư thế tay chỉ hiển thị cục bộ trên thiết bị của bạn.", C.Sub)

-- Tele Board: rainbow skateboard, rendered locally on this client.
HS.TeleBoardEnabled = false
HS.TeleBoardAll = false
HS.TeleBoardModels = {}
HS.TeleBoardConnection = nil
function HS.ClearTeleBoards()
    if HS.TeleBoardConnection then pcall(function() HS.TeleBoardConnection:Disconnect() end); HS.TeleBoardConnection = nil end
    for _, model in pairs(HS.TeleBoardModels) do pcall(function() model:Destroy() end) end
    HS.TeleBoardModels = {}
end
function HS.MakeTeleBoard(plr)
    if not plr or not plr.Character or HS.TeleBoardModels[plr] then return end
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end
    local model = Instance.new("Model")
    model.Name = "HyperSun_RainbowBoard"
    model.Parent = Workspace
    local colors = {
        Color3.fromRGB(255, 35, 55), Color3.fromRGB(255, 130, 25),
        Color3.fromRGB(255, 225, 35), Color3.fromRGB(40, 220, 100),
        Color3.fromRGB(30, 180, 255), Color3.fromRGB(90, 80, 255),
        Color3.fromRGB(205, 55, 255)
    }
    local boardParts = {}
    for i, color in ipairs(colors) do
        local seg = Instance.new("Part")
        seg.Name = "RainbowDeck_" .. i
        seg.Size = Vector3.new(0.34, 0.12, 1.65)
        seg.Color = color
        seg.Material = Enum.Material.Neon
        seg.Anchored = false
        seg.CanCollide = false
        seg.CanTouch = false
        seg.CanQuery = false
        seg.Massless = true
        seg.CastShadow = false
        seg.CFrame = root.CFrame * CFrame.new((i - 4) * 0.34, -3.0, 0)
        seg.Parent = model
        table.insert(boardParts, seg)
    end
    for _, x in ipairs({-0.85, 0.85}) do
        local axle = Instance.new("Part")
        axle.Name = "BoardAxle"
        axle.Size = Vector3.new(0.12, 0.12, 0.7)
        axle.Color = Color3.fromRGB(20, 20, 23)
        axle.Material = Enum.Material.Metal
        axle.Anchored = false
        axle.CanCollide = false
        axle.CanTouch = false
        axle.CanQuery = false
        axle.Massless = true
        axle.CFrame = root.CFrame * CFrame.new(x, -3.1, 0)
        axle.Parent = model
        table.insert(boardParts, axle)
    end
    for _, obj in ipairs(boardParts) do
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = obj
        weld.Parent = obj
    end
    HS.TeleBoardModels[plr] = model
end
function HS.SetTeleBoard(on, allPlayers)
    HS.TeleBoardEnabled = on and true or false
    if allPlayers ~= nil then HS.TeleBoardAll = allPlayers and true or false end
    HS.ClearTeleBoards()
    if not HS.TeleBoardEnabled then
        Notify("HyperSun 3.1 Elite · Tele Board", "Đã tắt ván trượt cầu vồng", 3)
        return
    end
    local function refresh()
        if not HS.TeleBoardEnabled or Unloaded then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            local shouldShow = (plr == LocalPlayer) or HS.TeleBoardAll
            if shouldShow then
                if not HS.TeleBoardModels[plr] or not HS.TeleBoardModels[plr].Parent then
                    HS.TeleBoardModels[plr] = nil
                    HS.MakeTeleBoard(plr)
                end
            elseif HS.TeleBoardModels[plr] then
                pcall(function() HS.TeleBoardModels[plr]:Destroy() end)
                HS.TeleBoardModels[plr] = nil
            end
        end
        for plr, model in pairs(HS.TeleBoardModels) do
            if not plr.Parent or not plr.Character or not model.Parent then
                pcall(function() model:Destroy() end)
                HS.TeleBoardModels[plr] = nil
            end
        end
    end
    refresh()
    HS.TeleBoardConnection = RunService.Heartbeat:Connect(refresh)
    Notify("HyperSun 3.1 Elite · Tele Board", HS.TeleBoardAll and "Ván trượt hiển thị dưới mọi người chơi trên máy bạn" or "Ván trượt chỉ hiển thị dưới chân bạn", 4)
end
CreateHeader(HS.TabFly, "TELE BOARD")
CreateButton(HS.TabFly, "Tele Board · Chỉ riêng tôi", function() HS.SetTeleBoard(not HS.TeleBoardEnabled, false) end)
CreateButton(HS.TabFly, "Tele Board · Tất cả người chơi", function() HS.SetTeleBoard(not HS.TeleBoardEnabled, true) end)
CreateLabel(HS.TabFly, "Tùy chọn tất cả chỉ là hiệu ứng cục bộ trên máy bạn, không thay đổi game/server hay màn hình người khác.", C.Sub)

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
-- (moved to HS)
-- (moved to HS)
-- (moved to HS)
-- (moved to HS)
-- (moved to HS)
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
            Notify("HyperSun 3.1 Elite · TeleGhost", "Không tìm thấy nhân vật hợp lệ", 4)
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
            Notify("HyperSun 3.1 Elite · TeleGhost", "Không thể tạo bản sao nhân vật", 5)
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
            Notify("HyperSun 3.1 Elite · TeleGhost", "Bản sao thiếu Humanoid hoặc HumanoidRootPart", 4)
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
        cloneHum.JumpPower = realHum.JumpPower
        cloneHum.JumpHeight = realHum.JumpHeight
        cloneHum.AutoRotate = true
        pcall(function() cloneHum:UnequipTools() end)
        HS.GhostEnabled = true
        -- Read Roblox's existing touch joystick/keyboard movement vector and drive only the clone.
        pcall(function()
            local ps = LocalPlayer:WaitForChild("PlayerScripts", 3)
            local pm = ps and require(ps:WaitForChild("PlayerModule", 3))
            HS.GhostControls = pm and pm:GetControls()
        end)
        HS.GhostMoveConnection = RunService.Heartbeat:Connect(function()
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
            -- Transfer jump input from the anchored original body to the controllable ghost clone.
            local originalHum = HS.GhostRealCharacter and HS.GhostRealCharacter:FindFirstChildOfClass("Humanoid")
            if originalHum and originalHum.Jump then
                HS.GhostHumanoid.Jump = true
                originalHum.Jump = false
            end
        end)
        if camera then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = cloneHum
        end
        HS.GhostFloat.SetOn(true)
        Notify("HyperSun 3.1 Elite · TeleGhost", "Đã tách hồn khỏi xác; di chuyển bản sao cục bộ", 5)
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
        Notify("HyperSun 3.1 Elite · TeleGhost", "Đã nhập hồn; xác đứng tại vị trí hồn kết thúc", 4)
    end
end
HS.GhostFloat.OnTap(function() HS.SetGhost(not HS.GhostEnabled) end)
HS.TeleBack1Float.OnTap(HS.SaveTeleBack)
HS.TeleBack2Float.OnTap(HS.ReturnTeleBack)
CreateToggle(HS.TabMem, "TeleGhost · Phân thân điều khiển (Beta)", false, HS.SetGhost)
CreateLabel(HS.TabMem, "Bản sao được điều khiển cục bộ; không đảm bảo ẩn nhân vật thật khỏi máy chủ hoặc người chơi khác.", C.Sub)
CreateToggle(HS.TabMem, "Hiện nút nổi TeleGhost", false, function(on) HS.GhostFloat.Show(on) end)
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
                task.spawn(function() HS.ApplyFastTalkPrompt(inst) end)
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
-- (moved to HS)
-- (moved to HS)
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
        local bv, bg
        pcall(function()
            bv = Instance.new("BodyVelocity")
            bv.Name = "HyperSunTeleSky2Velocity"
            bv.MaxForce = Vector3.new(1e7, 1e7, 1e7)
            bv.P = 25000
            bv.Velocity = Vector3.zero
            bv.Parent = hrp
        end)
        pcall(function()
            bg = Instance.new("BodyGyro")
            bg.Name = "HyperSunTeleSky2Gyro"
            bg.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
            bg.P = 18000
            bg.D = 700
            bg.CFrame = hrp.CFrame
            bg.Parent = hrp
        end)
        if not bv or not bg then
            Notify("TeleSky2", "BodyVelocity/BodyGyro không khả dụng trên executor này", 4)
            HS.TeleSky2Float.SetOn(false)
            if HS.TeleSky2Toggle then HS.TeleSky2Toggle.Set(false, false) end
            return
        end
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
-- (moved to HS)
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

-- (moved to HS)
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

CreateSlider(HS.TabMem, "WalkSpeed (tối đa 10000)", 1, 10000, 16, function(v)
State.Player.Speed = math.clamp(tonumber(v) or 16, 1, 10000)
if State.Player.SpeedOn then
local _, speedHum = GetHRP()
if speedHum then pcall(function() speedHum.WalkSpeed = State.Player.Speed end) end
end
end)
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
CreateHeader(HS.TabMem, "LƯU CẤU HÌNH")
CreateLabel(HS.TabMem, "Lưu setting để dùng lại lần chạy sau (nếu Delta hỗ trợ file API).", C.Sub)
CreateButton(HS.TabMem, "Lưu setting hiện tại", function() HS.SaveSettings() end)
CreateButton(HS.TabMem, "Nạp setting đã lưu", function() HS.LoadSettings() end)
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
task.spawn(HS.HidePart, d)
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
CreateLabel(HS.TabSet, 'Phiên bản: <font color="#FF334D">✦ HyperSun</font> <font color="#FFFFFF">3.1 Elite</font>')

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
pcall(function() HS.SetTeleX3(false) end)
pcall(function() HS.SetTeleBoard(false) end)
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
        warn("[Hyper Sun 3.1 Elite] " .. tostring(featureName) .. ": " .. tostring(err))
        if not HS.FeatureErrorShown[featureName] then
            HS.FeatureErrorShown[featureName] = true
            pcall(function()
                Notify("HyperSun 3.0 · Lỗi chức năng", tostring(featureName) .. ": " .. tostring(err), 8)
            end)
        end
    end
    return ok
end

function HS.GetPing()
local ok, v = pcall(function()
return (Stats and pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end) and Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) or 0
end)
if ok and v then return math.floor(v) end
return 0
end

Connections[#Connections + 1] = RunService.Heartbeat:Connect(function(dt)
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

-- ════════════════════════════════════════════════════════════════
--  HYPER SUN 3.0 ELITE — PATCH BLOCK
--  Thêm trực tiếp vào file gốc (không xóa 1 dòng nào ở trên)
--  1. Injector 1.0 panel
--  2. HitFly (tab AimBot)
--  3. Chỉnh màu giao diện (tab Setting)
-- ════════════════════════════════════════════════════════════════

-- ── Màu themes ──────────────────────────────────────────────────
local HS_THEMES = {
    ["Đen-Đỏ"] = {
        Panel   = Color3.fromRGB(10,  10,  13),
        Item    = Color3.fromRGB(28,  12,  16),
        Tab     = Color3.fromRGB(38,  10,  15),
        Accent  = Color3.fromRGB(255, 35,  55),
        Off     = Color3.fromRGB(55,  35,  39),
        Grad0   = Color3.fromRGB(50,  8,   16),
        Grad1   = Color3.fromRGB(7,   7,   10),
        Stroke  = Color3.fromRGB(255, 45,  65),
        TitleA  = "#FF334D",
        TitleB  = "#FFFFFF",
    },
    ["Trắng-Xanh"] = {
        Panel   = Color3.fromRGB(230, 240, 255),
        Item    = Color3.fromRGB(200, 220, 255),
        Tab     = Color3.fromRGB(180, 210, 255),
        Accent  = Color3.fromRGB(30,  100, 255),
        Off     = Color3.fromRGB(160, 185, 220),
        Grad0   = Color3.fromRGB(210, 230, 255),
        Grad1   = Color3.fromRGB(240, 245, 255),
        Stroke  = Color3.fromRGB(50,  120, 255),
        TitleA  = "#1A6AFF",
        TitleB  = "#003399",
    },
    ["Tím-Hồng"] = {
        Panel   = Color3.fromRGB(18,  10,  28),
        Item    = Color3.fromRGB(40,  18,  55),
        Tab     = Color3.fromRGB(55,  18,  70),
        Accent  = Color3.fromRGB(220, 60,  220),
        Off     = Color3.fromRGB(80,  35,  90),
        Grad0   = Color3.fromRGB(55,  10,  70),
        Grad1   = Color3.fromRGB(10,  6,   18),
        Stroke  = Color3.fromRGB(230, 80,  230),
        TitleA  = "#DD3DDD",
        TitleB  = "#FF9EFF",
    },
}

-- Áp dụng theme lên toàn bộ giao diện
local function ApplyTheme(name)
    local t = HS_THEMES[name]
    if not t then return end

    -- Cập nhật bảng màu C (dùng lại biến C từ script gốc)
    C.Panel  = t.Panel
    C.Item   = t.Item
    C.Tab    = t.Tab
    C.Accent = t.Accent
    C.Off    = t.Off

    -- Cập nhật tất cả Frame/Button theo màu theme mới
    local gui = Root:FindFirstChild("HyperSunUI")
    if not gui then return end

    -- Hàm đệ quy quét toàn bộ con
    local function Scan(inst)
        for _, child in ipairs(inst:GetDescendants()) do
            pcall(function()
                -- Buttons/Frames có màu Panel
                if child:IsA("Frame") or child:IsA("TextButton") then
                    local bg = child.BackgroundColor3
                    -- So khớp theo độ sáng/nhóm màu (gần đúng) rồi gán
                    local r, g, b = bg.R, bg.G, bg.B
                    -- Panel group (tối)
                    if r < 0.18 and g < 0.1 and b < 0.1 then
                        child.BackgroundColor3 = t.Panel
                    -- Item group
                    elseif r < 0.14 and g < 0.07 and b < 0.08 then
                        child.BackgroundColor3 = t.Item
                    -- Tab group
                    elseif r < 0.16 and g < 0.05 then
                        child.BackgroundColor3 = t.Tab
                    -- Accent group
                    elseif r > 0.9 and g < 0.2 and b < 0.25 then
                        child.BackgroundColor3 = t.Accent
                    -- Off group
                    elseif r < 0.25 and g < 0.15 then
                        child.BackgroundColor3 = t.Off
                    end
                end
                -- UIStroke accent
                if child:IsA("UIStroke") then
                    local sc = child.Color
                    if sc.R > 0.85 and sc.G < 0.3 then
                        child.Color = t.Stroke
                    end
                end
                -- UIGradient main panel
                if child:IsA("UIGradient") then
                    child.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, t.Grad0),
                        ColorSequenceKeypoint.new(1, t.Grad1),
                    })
                end
                -- TextLabel Accent color
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    local tc = child.TextColor3
                    if tc.R > 0.85 and tc.G < 0.25 then
                        child.TextColor3 = t.Accent
                    end
                end
            end)
        end
    end
    Scan(gui)

    -- Cập nhật tiêu đề
    pcall(function()
        for _, v in ipairs(gui:GetDescendants()) do
            if v:IsA("TextLabel") and v.RichText and v.Text:find("HyperSun") then
                v.Text = '<font color="' .. t.TitleA .. '">✦ HyperSun</font> <font color="' .. t.TitleB .. '">3.1 Elite</font>'
            end
        end
    end)

    Notify("HyperSun 3.1 Elite · Màu", "Đã áp dụng giao diện: " .. name, 4)
end

-- Thêm section Chỉnh Màu vào tab Setting
do
    CreateHeader(HS.TabSet, "CHỈNH MÀU GIAO DIỆN")
    CreateLabel(HS.TabSet, "Chọn bộ màu ưa thích. Áp dụng ngay lập tức.", C.Sub)

    local themeNames = { "Đen-Đỏ", "Trắng-Xanh", "Tím-Hồng" }
    local themeToggles = {}

    for _, name in ipairs(themeNames) do
        local t = HS_THEMES[name]
        -- Nút màu đặc biệt: có viền màu accent của theme đó
        local row = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 44),
            BackgroundColor3 = t.Panel,
            BackgroundTransparency = 0.1,
            Text = "",
            AutoButtonColor = false,
        }, HS.TabSet)
        Create("UICorner", { CornerRadius = UDim.new(0, 10) }, row)
        Create("UIStroke", { Color = t.Stroke, Thickness = 2, Transparency = 0.15 }, row)
        Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, t.Grad0),
                ColorSequenceKeypoint.new(1, t.Panel),
            }),
            Rotation = 20,
        }, row)

        -- Icon màu nhỏ bên trái
        local dot = Create("Frame", {
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0, 14, 0.5, -7),
            BackgroundColor3 = t.Accent,
            BorderSizePixel = 0,
        }, row)
        Create("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)

        -- Tên theme
        Create("TextLabel", {
            Size = UDim2.new(1, -80, 1, 0),
            Position = UDim2.new(0, 36, 0, 0),
            BackgroundTransparency = 1,
            Text = "🎨  " .. name,
            TextColor3 = t.Accent,
            Font = FONT_B, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)

        -- Switch dùng lại BuildSwitch gốc
        local sw = HS.BuildSwitch(row, UDim2.new(1, -10, 0.5, 0), false)
        themeToggles[name] = sw

        row.MouseEnter:Connect(function()
            TweenService:Create(row, TI, { BackgroundTransparency = 0 }):Play()
        end)
        row.MouseLeave:Connect(function()
            TweenService:Create(row, TI, { BackgroundTransparency = 0.1 }):Play()
        end)
        row.MouseButton1Click:Connect(function()
            Click()
            -- Tắt các theme khác
            for n, s in pairs(themeToggles) do
                s.Set(n == name)
            end
            ApplyTheme(name)
        end)
    end
end

-- ══════════════════════════════════════════════════════════════
--  INJECTOR 1.1 — HyperSun 3.2
--  Ẩn MainUI khi hiện, hiện lại sau inject
-- ══════════════════════════════════════════════════════════════

-- Ẩn menu chính ngay lập tức
local MainUI = Root:FindFirstChild("HyperSunUI")
if MainUI then MainUI.Enabled = false end

local InjGui = Create("ScreenGui", {
    Name = "HyperSunInjector11", ResetOnSpawn = false, IgnoreGuiInset = true,
}, Root)

local Overlay = Create("Frame", {
    Size = UDim2.new(1,0,1,0),
    BackgroundColor3 = Color3.fromRGB(0,0,0),
    BackgroundTransparency = 0.38,
    BorderSizePixel = 0, ZIndex = 100,
}, InjGui)

-- Main injector panel 360x560
local InjPanel = Create("Frame", {
    Size = UDim2.new(0, 360, 0, 560),
    Position = UDim2.new(0.5,0,0.5,0),
    AnchorPoint = Vector2.new(0.5,0.5),
    BackgroundColor3 = Color3.fromRGB(7,6,10),
    BackgroundTransparency = 0.02,
    BorderSizePixel = 0, ZIndex = 101,
}, InjGui)
Create("UICorner",  { CornerRadius = UDim.new(0,18) }, InjPanel)
Create("UIStroke",  { Color = Color3.fromRGB(255,38,60), Thickness = 2.5, Transparency = 0.04 }, InjPanel)
Create("UIGradient",{
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(60, 7, 18)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(18, 8, 24)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(6,  6, 10)),
    }), Rotation = 120,
}, InjPanel)

-- Drag
local _iDrag, _iS, _iFS = false, nil, nil
InjPanel.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        _iDrag=true; _iS=i.Position; _iFS=InjPanel.Position
    end
end)
InjPanel.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        _iDrag=false
    end
end)
Connections[#Connections+1] = UserInputService.InputChanged:Connect(function(i)
    if _iDrag and _iS and _iFS and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d = i.Position - _iS
        InjPanel.Position = UDim2.new(_iFS.X.Scale, _iFS.X.Offset+d.X, _iFS.Y.Scale, _iFS.Y.Offset+d.Y)
    end
end)

-- ── Title bar ───────────────────────────────────────────────
Create("TextLabel", {
    Size = UDim2.new(1,-20,0,32), Position = UDim2.new(0,14,0,12),
    BackgroundTransparency=1, RichText=true,
    Text = '<font color="#FF2640">✦ HyperSun</font>  <font color="#FFFFFF" size="18">Injector 1.1</font>',
    TextColor3=Color3.new(1,1,1), Font=FONT_B, TextSize=22,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=102,
}, InjPanel)
Create("TextLabel", {
    Size=UDim2.new(1,-20,0,18), Position=UDim2.new(0,14,0,44),
    BackgroundTransparency=1,
    Text="Chọn gói inject phù hợp với bạn",
    TextColor3=C.Sub, Font=FONT_N, TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=102,
}, InjPanel)
Create("Frame", {
    Size=UDim2.new(1,-20,0,2), Position=UDim2.new(0,10,0,64),
    BackgroundColor3=Color3.fromRGB(255,38,60), BackgroundTransparency=0.25, BorderSizePixel=0, ZIndex=102,
}, InjPanel)
Create("UICorner", {CornerRadius=UDim.new(1,0)}, InjPanel:FindFirstChildWhichIsA("Frame"))

-- Status label
local InjStatus = Create("TextLabel", {
    Size=UDim2.new(1,-20,0,20), Position=UDim2.new(0,10,1,-30),
    BackgroundTransparency=1, Text="", Font=FONT_MONO, TextSize=12,
    TextColor3=C.Gold, TextXAlignment=Enum.TextXAlignment.Center, ZIndex=102,
}, InjPanel)

-- ── Btn factory ─────────────────────────────────────────────
local function InjBtn(parent, label, subLabel, yOff, h, bg, stroke, zi)
    zi = zi or 102
    local btn = Create("TextButton", {
        Size=UDim2.new(1,-24,0,h), Position=UDim2.new(0,12,0,yOff),
        BackgroundColor3=bg, BackgroundTransparency=0.1,
        Text="", AutoButtonColor=false, ZIndex=zi,
    }, parent)
    Create("UICorner",{CornerRadius=UDim.new(0,12)}, btn)
    Create("UIStroke",{Color=stroke, Thickness=1.5, Transparency=0.3}, btn)
    Create("UIGradient",{
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0, bg),
            ColorSequenceKeypoint.new(1, Color3.new(bg.R*0.55, bg.G*0.55, bg.B*0.55)),
        }), Rotation=90,
    }, btn)
    Create("TextLabel", {
        Size=UDim2.new(1,-16,0,h*0.55), Position=UDim2.new(0,14,0,4),
        BackgroundTransparency=1, Text=label,
        TextColor3=Color3.fromRGB(252,248,250), Font=FONT_B, TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=zi+1,
    }, btn)
    if subLabel and subLabel ~= "" then
        Create("TextLabel", {
            Size=UDim2.new(1,-16,0,h*0.38), Position=UDim2.new(0,14,0,h*0.52),
            BackgroundTransparency=1, Text=subLabel,
            TextColor3=Color3.fromRGB(190,160,168), Font=FONT_N, TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=zi+1,
        }, btn)
    end
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TI,{BackgroundTransparency=0}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TI,{BackgroundTransparency=0.1}):Play() end)
    return btn
end

-- ── 5 nút inject ────────────────────────────────────────────
local BtnNormal = InjBtn(InjPanel, "⚡  Inject Normal",    "3.2 Beta Normal · Cơ bản", 72,  62, Color3.fromRGB(160,20,38),  Color3.fromRGB(255,60,80))
local BtnMax    = InjBtn(InjPanel, "🔥  Inject Max",        "3.2 Max Elite · Mở khóa toàn bộ", 142, 62, Color3.fromRGB(180,100,10), Color3.fromRGB(255,180,30))
local BtnBeta   = InjBtn(InjPanel, "🧪  Inject Beta",       "3.2 Beta Fix · Đầy đủ chức năng", 212, 62, Color3.fromRGB(20,80,180),  Color3.fromRGB(50,140,255))
local BtnFix    = InjBtn(InjPanel, "🔧  Fix Bug Game",      "Quét & vá lỗi script 10s",         282, 62, Color3.fromRGB(30,110,55),  Color3.fromRGB(55,200,90))
local BtnPay    = InjBtn(InjPanel, "💳  Pay Inject",        "Mua mã Inject Max",                 352, 62, Color3.fromRGB(80,20,120),  Color3.fromRGB(180,60,255))

-- ── Helper: animation inject ────────────────────────────────
local injBusy = false
local function RunInjectAnim(steps, doneCb)
    if injBusy then return end
    injBusy = true
    InjStatus.TextColor3 = C.Gold
    task.spawn(function()
        for _, msg in ipairs(steps) do
            InjStatus.Text = "⏳  " .. msg
            task.wait(0.9)
        end
        InjStatus.Text = "✅  Injector!! Success!!"
        InjStatus.TextColor3 = C.Green
        task.wait(0.8)
        injBusy = false
        if doneCb then doneCb() end
    end)
end

-- Hiện menu chính + đóng injector
local function FinishInject(versionStr, tier)
    INJECT_TIER = tier
    LocTeleUnlocked = (tier == "max" or tier == "beta")
    -- Cập nhật title menu chính
    local titleColor = tier == "max" and "#FFB800" or (tier == "beta" and "#3A8CFF" or "#FF2640")
    local titleSuffix = tier == "max" and "3.2 Max Elite" or (tier == "beta" and "3.2 Beta Fix" or "3.2 Beta Normal")
    TITLE_RICH = '<font color="'..titleColor..'">✦ HyperSun</font> <font color="#FFFFFF">'..titleSuffix..'</font>'
    -- Áp dụng lên mọi label tiêu đề
    if MainUI then
        for _, v in ipairs(MainUI:GetDescendants()) do
            pcall(function()
                if v:IsA("TextLabel") and v.RichText and v.Text:find("HyperSun") and v.Text:find("font") then
                    v.Text = TITLE_RICH
                end
            end)
        end
    end
    -- Khóa / mở Location + Tele tabs
    local function SetTabLock(locked)
        if not HS.TabLoc or not HS.TabFly then return end
        local msg = "🔒  Inject Max hoặc Inject Beta để mở khóa!"
        for _, tab in ipairs({HS.TabLoc, HS.TabFly}) do
            local lockLabel = tab:FindFirstChild("HSLockLabel")
            if locked then
                if not lockLabel then
                    lockLabel = Create("TextLabel", {
                        Name = "HSLockLabel",
                        Size = UDim2.new(1,0,0,36),
                        BackgroundColor3 = Color3.fromRGB(40,10,10),
                        BackgroundTransparency = 0.1,
                        Text = msg,
                        TextColor3 = Color3.fromRGB(255,80,80),
                        Font = FONT_B, TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 50,
                    }, tab)
                    Create("UICorner",{CornerRadius=UDim.new(0,8)}, lockLabel)
                end
                for _, child in ipairs(tab:GetChildren()) do
                    if child ~= lockLabel and (child:IsA("TextButton") or child:IsA("Frame")) then
                        pcall(function() child.Visible = false end)
                    end
                end
            else
                if lockLabel then lockLabel:Destroy() end
                for _, child in ipairs(tab:GetChildren()) do
                    pcall(function() child.Visible = true end)
                end
            end
        end
    end
    SetTabLock(not LocTeleUnlocked)
    -- Hiện menu chính
    TweenService:Create(InjPanel, TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),
        {Size=UDim2.new(0,0,0,0), Position=UDim2.new(0.5,0,0.5,0)}):Play()
    TweenService:Create(Overlay, TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
        {BackgroundTransparency=1}):Play()
    task.wait(0.35)
    pcall(function() InjGui:Destroy() end)
    if MainUI then MainUI.Enabled = true end
    Notify("HyperSun " .. titleSuffix, "✦ Inject thành công!", 5)
end

-- ── 1. Inject Normal ────────────────────────────────────────
BtnNormal.MouseButton1Click:Connect(function()
    RunInjectAnim({
        "Checking Grant",
        "Download Library",
        "Checking API",
        "Inject 3.2 Beta Normal",
        "Extract File",
    }, function() FinishInject("3.2 Beta Normal", "normal") end)
end)

-- ── 2. Inject Max — cần mã từ Pay Inject ───────────────────
local function ShowMaxCodeInput()
    -- Bảng nhập mã (sub-panel trên InjPanel)
    local codePanel = Create("Frame", {
        Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=Color3.fromRGB(7,6,10), BackgroundTransparency=0.0,
        BorderSizePixel=0, ZIndex=103,
    }, InjPanel)
    Create("UICorner",{CornerRadius=UDim.new(0,18)}, codePanel)
    Create("TextLabel",{
        Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,16),
        BackgroundTransparency=1,
        Text="🔥  Nhập mã Inject Max",
        TextColor3=C.Gold, Font=FONT_B, TextSize=18,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=104,
    }, codePanel)
    Create("TextLabel",{
        Size=UDim2.new(1,-20,0,20), Position=UDim2.new(0,10,0,48),
        BackgroundTransparency=1,
        Text="Mã giao dịch nhận được từ Pay Inject:",
        TextColor3=C.Sub, Font=FONT_N, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=104,
    }, codePanel)
    local codeBox = Create("TextBox", {
        Size=UDim2.new(1,-20,0,44), Position=UDim2.new(0,10,0,74),
        BackgroundColor3=Color3.fromRGB(18,10,18),
        BackgroundTransparency=0.05,
        Text="", PlaceholderText="Nhập mã CODE ở đây...",
        TextColor3=Color3.fromRGB(255,200,40),
        PlaceholderColor3=Color3.fromRGB(120,90,100),
        Font=FONT_MONO, TextSize=15, ClearTextOnFocus=false,
        ZIndex=104,
    }, codePanel)
    Create("UICorner",{CornerRadius=UDim.new(0,10)}, codeBox)
    Create("UIStroke",{Color=C.Gold, Thickness=1.5, Transparency=0.3}, codeBox)
    local errLbl = Create("TextLabel",{
        Size=UDim2.new(1,-20,0,20), Position=UDim2.new(0,10,0,122),
        BackgroundTransparency=1, Text="",
        TextColor3=Color3.fromRGB(255,60,60), Font=FONT_N, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=104,
    }, codePanel)
    local confirmBtn = InjBtn(codePanel,"✅  Xác nhận","",148,52,Color3.fromRGB(180,100,10),Color3.fromRGB(255,180,30),104)
    local backBtn = InjBtn(codePanel,"← Quay lại","",208,46,Color3.fromRGB(40,20,50),Color3.fromRGB(120,60,160),104)
    confirmBtn.MouseButton1Click:Connect(function()
        local entered = codeBox.Text:gsub("%s",""):upper()
        if PAID_CODE and entered == PAID_CODE:upper() then
            codePanel:Destroy()
            RunInjectAnim({
                "Checking Grant",
                "Checking Pay Pass",
                "Download Library",
                "Checking API",
                "Accept API",
                "Inject 3.2 Max Elite",
                "Extract File",
            }, function() FinishInject("3.2 Max Elite","max") end)
        else
            errLbl.Text = "❌  Mã không hợp lệ hoặc chưa mua!"
            TweenService:Create(codeBox,TI,{BackgroundColor3=Color3.fromRGB(50,10,10)}):Play()
            task.wait(1)
            TweenService:Create(codeBox,TI,{BackgroundColor3=Color3.fromRGB(18,10,18)}):Play()
        end
    end)
    backBtn.MouseButton1Click:Connect(function() codePanel:Destroy() end)
end

BtnMax.MouseButton1Click:Connect(function()
    ShowMaxCodeInput()
end)

-- ── 3. Inject Beta ──────────────────────────────────────────
BtnBeta.MouseButton1Click:Connect(function()
    RunInjectAnim({
        "Checking Grant",
        "Download Source 3.2",
        "Download Library",
        "Checking API",
        "Inject 3.2 Beta Normal",
        "Extract File",
    }, function() FinishInject("3.2 Beta Fix","beta") end)
end)

-- ── 4. Fix Bug Game — quét 10s ──────────────────────────────
BtnFix.MouseButton1Click:Connect(function()
    if injBusy then return end
    injBusy = true
    InjStatus.TextColor3 = C.Green
    -- Nút quay lại
    local backBtn2 = InjBtn(InjPanel,"← Dừng & Quay lại","",490,36,Color3.fromRGB(40,20,50),Color3.fromRGB(120,60,160),103)
    local stopped = false
    backBtn2.MouseButton1Click:Connect(function()
        stopped = true; backBtn2:Destroy(); injBusy=false; InjStatus.Text=""
    end)
    task.spawn(function()
        local fixSteps = {
            "Quét chức năng Aimbot...",
            "Quét chức năng ESP...",
            "Quét HitFly & Dash...",
            "Quét AimKill...",
            "Quét Freeze client...",
            "Quét Fly/Tele module...",
            "Vá lỗi callback nil...",
            "Vá lỗi Connections leak...",
            "Vá lỗi CharacterAdded...",
            "Hoàn tất kiểm tra!",
        }
        for i, msg in ipairs(fixSteps) do
            if stopped then return end
            InjStatus.Text = "🔧  ["..i.."/10]  "..msg
            task.wait(1)
        end
        if not stopped then
            InjStatus.Text = "✅  Đã vá "..tostring(math.random(2,5)).." lỗi thành công!"
            InjStatus.TextColor3 = C.Green
            pcall(function() backBtn2:Destroy() end)
            task.wait(2)
            InjStatus.Text = ""
            injBusy = false
        end
    end)
end)

-- ── 5. Pay Inject ───────────────────────────────────────────
local function ShowPayPanel()
    local payPanel = Create("Frame", {
        Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=Color3.fromRGB(7,6,10), BackgroundTransparency=0.0,
        BorderSizePixel=0, ZIndex=103,
    }, InjPanel)
    Create("UICorner",{CornerRadius=UDim.new(0,18)}, payPanel)
    Create("TextLabel",{
        Size=UDim2.new(1,-20,0,28), Position=UDim2.new(0,10,0,14),
        BackgroundTransparency=1, Text="💳  PayLoad · Buy Injector Max 3.2",
        TextColor3=Color3.fromRGB(180,60,255), Font=FONT_B, TextSize=17,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=104,
    }, payPanel)
    -- Fake QR code (grid pattern drawn with frames)
    local qrHolder = Create("Frame",{
        Size=UDim2.new(0,120,0,120), Position=UDim2.new(0.5,-60,0,50),
        BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=104,
    }, payPanel)
    Create("UICorner",{CornerRadius=UDim.new(0,6)}, qrHolder)
    -- Draw QR pixel grid 10x10 deterministic pattern
    local QR_PATTERN = {
        {1,1,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1},
        {1,0,0,0,0,0,1,0,0,1,1,0,0,0,0,0,1},
        {1,0,1,1,1,0,1,0,1,0,1,0,1,1,1,0,1},
        {1,0,1,1,1,0,1,0,0,0,1,0,1,1,1,0,1},
        {1,0,0,0,0,0,1,0,1,1,1,0,0,0,0,0,1},
        {1,1,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1},
        {0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0},
        {1,0,1,1,0,1,0,1,0,1,1,0,1,1,0,1,0},
        {0,1,1,0,1,0,1,0,1,0,0,1,0,0,1,0,1},
        {1,0,0,1,0,1,0,1,0,1,1,0,1,1,0,1,0},
        {1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1},
        {1,0,0,0,0,0,1,0,1,1,0,0,0,0,0,0,1},
        {1,0,1,1,1,0,1,0,0,1,1,0,1,1,0,0,1},
        {1,0,1,1,1,0,1,0,1,0,0,1,0,0,1,0,1},
        {1,0,0,0,0,0,1,0,0,1,1,0,1,1,0,1,0},
        {1,1,1,1,1,1,1,0,1,0,0,1,0,0,1,0,1},
    }
    local cell = 7
    for row = 1, #QR_PATTERN do
        for col = 1, #QR_PATTERN[row] do
            if QR_PATTERN[row][col] == 1 then
                Create("Frame",{
                    Size=UDim2.new(0,cell-1,0,cell-1),
                    Position=UDim2.new(0,(col-1)*cell,(0,(row-1)*cell)),
                    BackgroundColor3=Color3.fromRGB(0,0,0),
                    BorderSizePixel=0, ZIndex=105,
                }, qrHolder)
            end
        end
    end
    Create("TextLabel",{
        Size=UDim2.new(1,-20,0,20), Position=UDim2.new(0,10,0,178),
        BackgroundTransparency=1, Text="Giá: 20,000đ · Scan QR để thanh toán",
        TextColor3=C.Sub, Font=FONT_N, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=104,
    }, payPanel)
    -- Checking Pay button
    local checkPayStatus = Create("TextLabel",{
        Size=UDim2.new(1,-20,0,22), Position=UDim2.new(0,10,0,200),
        BackgroundTransparency=1, Text="",
        TextColor3=C.Green, Font=FONT_B, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=104,
    }, payPanel)
    local checkBtn = InjBtn(payPanel,"💳  Checking Pay","Xác nhận đã thanh toán",228,54,Color3.fromRGB(80,20,120),Color3.fromRGB(180,60,255),104)
    local checkBusy = false
    -- Success panel (hidden initially)
    local successPanel = Create("Frame",{
        Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=Color3.fromRGB(5,14,8),
        BackgroundTransparency=0.0, BorderSizePixel=0, ZIndex=105, Visible=false,
    }, payPanel)
    Create("UICorner",{CornerRadius=UDim.new(0,18)}, successPanel)
    local function GenCode()
        local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ"
        local digits = "0123456789"
        local pool = {}
        -- 5 chữ hoa, 5 số, xáo trộn
        for i=1,5 do pool[#pool+1]={chars:sub(math.random(1,#chars),math.random(1,#chars)), false} end
        for i=1,5 do pool[#pool+1]={digits:sub(math.random(1,#digits),math.random(1,#digits)), true} end
        -- shuffle
        for i=#pool,2,-1 do
            local j=math.random(1,i); pool[i],pool[j]=pool[j],pool[i]
        end
        local s=""
        for _,v in ipairs(pool) do s=s..v[1] end
        return s
    end
    checkBtn.MouseButton1Click:Connect(function()
        if checkBusy then return end
        checkBusy = true
        checkPayStatus.Text = "⏳  Đang kiểm tra giao dịch..."
        checkPayStatus.TextColor3 = C.Gold
        task.wait(1.5)
        local roll = math.random(1,100)
        if roll <= 10 then
            -- Thành công
            local code = GenCode()
            PAID_CODE = code
            successPanel.Visible = true
            -- Nội dung thành công
            Create("TextLabel",{
                Size=UDim2.new(1,-20,0,32),Position=UDim2.new(0,10,0,24),
                BackgroundTransparency=1,
                Text="✅  Pay Inject Max Done!!",
                TextColor3=C.Green,Font=FONT_B,TextSize=20,
                TextXAlignment=Enum.TextXAlignment.Center,ZIndex=106,
            }, successPanel)
            Create("TextLabel",{
                Size=UDim2.new(1,-20,0,22),Position=UDim2.new(0,10,0,62),
                BackgroundTransparency=1,
                Text="Time Key: N/A",
                TextColor3=C.Sub,Font=FONT_N,TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Center,ZIndex=106,
            }, successPanel)
            Create("TextLabel",{
                Size=UDim2.new(1,-20,0,22),Position=UDim2.new(0,10,0,86),
                BackgroundTransparency=1,
                Text="Code:",
                TextColor3=C.Sub,Font=FONT_B,TextSize=13,
                TextXAlignment=Enum.TextXAlignment.Center,ZIndex=106,
            }, successPanel)
            local codeLbl = Create("TextLabel",{
                Size=UDim2.new(1,-20,0,40),Position=UDim2.new(0,10,0,106),
                BackgroundColor3=Color3.fromRGB(14,30,14),
                BackgroundTransparency=0.05,
                Text=code,
                TextColor3=C.Gold,Font=FONT_MONO,TextSize=22,
                TextXAlignment=Enum.TextXAlignment.Center,ZIndex=106,
            }, successPanel)
            Create("UICorner",{CornerRadius=UDim.new(0,8)}, codeLbl)
            local copied = false
            local copyBtn = InjBtn(successPanel,"📋  Sao chép mã","",154,46,Color3.fromRGB(14,80,30),Color3.fromRGB(50,200,90),106)
            copyBtn.MouseButton1Click:Connect(function()
                if copied then return end
                copied = true
                pcall(function() setclipboard(code) end)
                copyBtn:FindFirstChildOfClass("TextLabel").Text = "✅  Đã sao chép!"
                task.wait(1.5)
                -- nút quay về Inject Max
                local goBtn = InjBtn(successPanel,"⚡  Vào Inject Max","Nhập mã vừa nhận",206,52,Color3.fromRGB(180,100,10),Color3.fromRGB(255,180,30),106)
                goBtn.MouseButton1Click:Connect(function()
                    payPanel:Destroy()
                    ShowMaxCodeInput()
                end)
            end)
        else
            checkPayStatus.Text = "❌  Chưa nhận được phí thanh toán!"
            checkPayStatus.TextColor3 = Color3.fromRGB(255,60,60)
            checkBusy = false
        end
    end)
    local backBtn3 = InjBtn(payPanel,"← Quay lại","",490,36,Color3.fromRGB(40,20,50),Color3.fromRGB(120,60,160),104)
    backBtn3.MouseButton1Click:Connect(function() payPanel:Destroy() end)
end

BtnPay.MouseButton1Click:Connect(function()
    ShowPayPanel()
end)

-- ══════════════════════════════════════════════════════════════
--  HITFLY — thêm vào tab AimBot
-- ══════════════════════════════════════════════════════════════
local HF = {
    Enabled = false,
    Height  = 12,
    Speed   = 55,
    Float   = nil,
    Conn    = nil,
    Busy    = false,
}

local function HF_GetHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart"),
           c and c:FindFirstChildOfClass("Humanoid")
end

local function DoHitFly()
    if HF.Busy then return end
    HF.Busy = true
    local hrp, hum = HF_GetHRP()
    if not hrp or not hum or hum.Health <= 0 then HF.Busy = false; return end

    -- giả lập nhận đòn: lực nhỏ xuống
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.new(
            hrp.AssemblyLinearVelocity.X, -6,
            hrp.AssemblyLinearVelocity.Z
        )
    end)
    task.wait(0.04)

    local targetY = hrp.Position.Y + HF.Height
    local elapsed = 0
    local maxTime = HF.Height / math.max(HF.Speed, 1) + 0.65
    local c2
    c2 = RunService.Heartbeat:Connect(function(dt)
        if not HF.Enabled or Unloaded then c2:Disconnect(); HF.Busy=false; return end
        local h = HF_GetHRP()
        if not h then c2:Disconnect(); HF.Busy=false; return end
        elapsed = elapsed + dt
        local rem = targetY - h.Position.Y
        if rem > 0.4 and elapsed < maxTime then
            pcall(function()
                h.AssemblyLinearVelocity = Vector3.new(
                    h.AssemblyLinearVelocity.X,
                    math.min(HF.Speed, rem / math.max(dt, 0.001) * 0.88),
                    h.AssemblyLinearVelocity.Z
                )
            end)
        else
            c2:Disconnect(); HF.Busy = false
        end
    end)
end

local function HitFly_Loop()
    if HF.Conn then pcall(function() HF.Conn:Disconnect() end); HF.Conn = nil end
    if not HF.Enabled then return end
    local timer = 0
    HF.Conn = RunService.Heartbeat:Connect(function(dt)
        if not HF.Enabled or Unloaded then
            pcall(function() HF.Conn:Disconnect() end); HF.Conn=nil; return
        end
        timer = timer + dt
        if timer >= 0.9 then timer=0; task.spawn(DoHitFly) end
    end)
end

local function SetHitFly(on)
    HF.Enabled = on and true or false
    if HF.Float then HF.Float.SetOn(HF.Enabled) end
    if HF.Enabled then
        Notify("HitFly 3.1 Elite", "Bật — Cao: "..HF.Height.." | Tốc: "..HF.Speed, 4)
        HitFly_Loop()
    else
        HF.Busy = false
        if HF.Conn then pcall(function() HF.Conn:Disconnect() end); HF.Conn=nil end
        Notify("HitFly 3.1 Elite", "Đã tắt HitFly", 3)
    end
end

-- Nút nổi HitFly
HF.Float = HS.CreateFloat("HitFly", 999)
HF.Float.OnTap(function() SetHitFly(not HF.Enabled) end)

-- Thêm UI vào cuối tab AimBot
CreateHeader(HS.TabAimbot, "HITFLY · 3.1 ELITE")

local hfToggle = CreateToggle(HS.TabAimbot, "HitFly · Bật / Tắt", false, function(s)
    SetHitFly(s)
end)
CreateSlider(HS.TabAimbot, "Độ cao HitFly (studs)", 2, 80, 12, function(v)
    HF.Height = v
    if HF.Enabled then Notify("HitFly", "Độ cao → "..v.." studs", 2) end
end)
CreateSlider(HS.TabAimbot, "Tốc độ HitFly (studs/s)", 5, 200, 55, function(v)
    HF.Speed = v
    if HF.Enabled then Notify("HitFly", "Tốc độ → "..v, 2) end
end)
CreateToggle(HS.TabAimbot, "Hiện nút nổi HitFly", false, function(on)
    HF.Float.Show(on)
end)
CreateLabel(HS.TabAimbot, "HitFly giả lập đòn đánh lên nhân vật rồi phóng lên theo độ cao/tốc độ chỉnh.", C.Sub)
CreateLabel(HS.TabAimbot, "Chỉ ảnh hưởng phía client. Tự dừng khi respawn.", C.Sub)

-- Hook unload để dọn HitFly
local _origUnload = Env.HyperSunUnload
Env.HyperSunUnload = function()
    HF.Enabled = false
    HF.Busy    = false
    if HF.Conn then pcall(function() HF.Conn:Disconnect() end); HF.Conn = nil end
    pcall(function() InjGui:Destroy() end)
    if _origUnload then pcall(_origUnload) end
end

-- ════════════════════════════════════════════════════════════════
--  DASH · 3.1 Elite
--  Thêm vào tab AimBot, nút nổi "Dash" riêng
-- ════════════════════════════════════════════════════════════════

local DS = {
    Enabled  = false,
    Dist     = 60,      -- studs mỗi lần dash
    Cooldown = 0.18,    -- giây giữa 2 lần dash (spam được)
    Float    = nil,
    LastDash = 0,
    Busy     = false,
    Conn     = nil,     -- heartbeat connection (re-init sau respawn)
}

local function DashExec()
    local now = tick()
    if DS.Busy or (now - DS.LastDash) < DS.Cooldown then return end
    DS.Busy = true
    DS.LastDash = now

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then DS.Busy = false; return end

    -- Hướng dash: nếu đang di chuyển thì theo hướng di chuyển,
    -- nếu đứng yên thì theo hướng nhìn của camera
    local cam = Workspace.CurrentCamera
    local moveDir = hum.MoveDirection
    local dir
    if moveDir.Magnitude > 0.1 then
        dir = moveDir.Unit
    else
        dir = (cam and cam.CFrame.LookVector or hrp.CFrame.LookVector)
        dir = Vector3.new(dir.X, 0, dir.Z).Unit
    end
    if dir.Magnitude < 0.01 then dir = hrp.CFrame.LookVector end
    dir = Vector3.new(dir.X, 0, dir.Z).Unit

    local steps   = 8
    local stepDist = DS.Dist / steps
    local stepWait = 0.016

    -- Dash bằng cách teleport từng bước nhỏ trong 1 frame loop ngắn
    local conn
    local step = 0
    conn = RunService.Heartbeat:Connect(function()
        if step >= steps or not DS.Enabled or Unloaded then
            conn:Disconnect()
            DS.Busy = false
            return
        end
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not h then conn:Disconnect(); DS.Busy = false; return end
        pcall(function()
            h.CFrame = h.CFrame + dir * stepDist
        end)
        step = step + 1
    end)

    -- Fallback: giải phóng Busy sau maxTime dù conn còn hay không
    task.delay(steps * stepWait + 0.1, function()
        DS.Busy = false
    end)
end

local function SetDash(on)
    DS.Enabled = on and true or false
    if DS.Float then DS.Float.SetOn(DS.Enabled) end
    if DS.Enabled then
        Notify("Dash 3.1 Elite", "Bật — Quãng đường: " .. DS.Dist .. " studs", 3)
    else
        Notify("Dash 3.1 Elite", "Đã tắt Dash", 3)
    end
end

-- Nút nổi Dash (nhỏ, riêng biệt)
DS.Float = HS.CreateFloat("Dash", 1050)
DS.Float.OnTap(function()
    if not DS.Enabled then return end
    task.spawn(DashExec)
end)

-- Kết nối input: giữ nút nổi để spam dash khi bật
Connections[#Connections + 1] = UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    -- Phím E trên PC để dash (tùy chọn)
    if DS.Enabled and inp.KeyCode == Enum.KeyCode.E then
        task.spawn(DashExec)
    end
end)

-- ── UI Dash trong tab AimBot ─────────────────────────────────
CreateHeader(HS.TabAimbot, "DASH · 3.1 ELITE")

CreateToggle(HS.TabAimbot, "Dash · Bật / Tắt", false, function(s)
    SetDash(s)
end)

CreateSlider(HS.TabAimbot, "Quãng đường Dash (studs)", 10, 200, 60, function(v)
    DS.Dist = v
    if DS.Enabled then Notify("Dash", "Quãng đường → " .. v .. " studs", 2) end
end)

CreateSlider(HS.TabAimbot, "Cooldown Dash (ms)", 50, 800, 180, function(v)
    DS.Cooldown = v / 1000
    if DS.Enabled then Notify("Dash", "Cooldown → " .. v .. "ms", 2) end
end)

CreateToggle(HS.TabAimbot, "Hiện nút nổi Dash", false, function(on)
    DS.Float.Show(on)
end)

CreateLabel(HS.TabAimbot, "Ấn nút nổi Dash để lướt. Trên PC bấm [E] để dash. Có thể spam theo cooldown.", C.Sub)
CreateLabel(HS.TabAimbot, "Hướng dash theo di chuyển hoặc hướng nhìn camera nếu đứng yên.", C.Sub)

-- Hook unload: dọn Dash
local _dashOldUnload = Env.HyperSunUnload
Env.HyperSunUnload = function()
    DS.Enabled = false
    DS.Busy    = false
    if _dashOldUnload then pcall(_dashOldUnload) end
end

-- ════════════════════════════════════════════════════════════════
--  HYPER SUN 3.1 ELITE — PATCH BLOCK 2
--  1. Cải thiện giao diện (UI polish toàn diện)
--  2. AimKill — tự động kill trong phạm vi với nút nổi riêng
-- ════════════════════════════════════════════════════════════════

-- ── 1. UI POLISH ─────────────────────────────────────────────────
-- Áp dụng ngay sau khi GUI tồn tại (defer để đảm bảo mọi widget đã render)
task.spawn(function()
    if Unloaded then return end
    local gui = Root:FindFirstChild("HyperSunUI")
    if not gui then return end

    -- Thêm drop shadow nhẹ cho MainFrame nếu chưa có
    local mainFrame = gui:FindFirstChild("MainFrame")
    if mainFrame and not mainFrame:FindFirstChild("HSShadow") then
        local shadow = Instance.new("ImageLabel")
        shadow.Name = "HSShadow"
        shadow.AnchorPoint = Vector2.new(0.5, 0.5)
        shadow.BackgroundTransparency = 1
        shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
        shadow.Size = UDim2.new(1, 36, 1, 36)
        shadow.ZIndex = mainFrame.ZIndex - 1
        shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        shadow.ImageTransparency = 0.65
        shadow.ScaleType = Enum.ScaleType.Slice
        shadow.SliceCenter = Rect.new(10, 10, 118, 118)
        shadow.Parent = mainFrame.Parent
    end

    -- Neon accent line dưới header
    for _, child in ipairs(gui:GetDescendants()) do
        pcall(function()
            if child.Name == "HSTitleBar" then
                if not child:FindFirstChild("HSNeonLine") then
                    local line = Instance.new("Frame")
                    line.Name = "HSNeonLine"
                    line.Size = UDim2.new(1, 0, 0, 2)
                    line.Position = UDim2.new(0, 0, 1, -2)
                    line.BackgroundColor3 = C.Accent
                    line.BorderSizePixel = 0
                    line.ZIndex = child.ZIndex + 1
                    line.Parent = child
                    -- Pulse glow
                    task.spawn(function()
                        while not Unloaded and line.Parent do
                            TweenService:Create(line, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.55}):Play()
                            task.wait(2.2)
                        end
                    end)
                    local c2 = Instance.new("UICorner")
                    c2.CornerRadius = UDim.new(1, 0)
                    c2.Parent = line
                end
            end
        end)
    end

    -- Upgrade UIStroke thickness trên mọi toggle row (giao diện sắc nét hơn)
    for _, v in ipairs(gui:GetDescendants()) do
        pcall(function()
            if v:IsA("UIStroke") and v.Color == C.Accent and v.Thickness < 1.8 then
                v.Thickness = 1.8
                v.Transparency = 0.08
            end
        end)
    end

    -- Gradient tinh tế hơn trên mọi row Item (không ảnh hưởng tab chính)
    for _, v in ipairs(gui:GetDescendants()) do
        pcall(function()
            if v:IsA("Frame") and v.BackgroundColor3 == C.Item and not v:FindFirstChildOfClass("UIGradient") then
                local g = Instance.new("UIGradient")
                g.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 16, 22)),
                    ColorSequenceKeypoint.new(1, C.Item),
                })
                g.Rotation = 90
                g.Parent = v
            end
        end)
    end
end)

-- ── 2. AIMKILL ───────────────────────────────────────────────────
local AK = {
    Enabled  = false,
    Range    = 60,       -- studs — phạm vi tính từ HRP của mình
    Rate     = 0.08,     -- giây giữa mỗi lần thử (không spam quá mức)
    Float    = nil,
    Toggle   = nil,
    Conn     = nil,
    LastHit  = {},       -- [player] = tick() — tránh double-hit liên tiếp
    CoolPer  = 0.25,     -- giây cooldown mỗi target riêng
}

-- Lấy danh sách mục tiêu hợp lệ trong phạm vi, có kiểm tra team + alive
local function AK_GetTargets()
    local myHRP, myHum = GetHRP()
    if not myHRP or not myHum or myHum.Health <= 0 then return {} end
    local myPos = myHRP.Position
    local targets = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and Alive(plr) and IsEnemy(plr) then
            local c = plr.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - myPos).Magnitude
                if dist <= AK.Range then
                    table.insert(targets, { plr = plr, hrp = hrp, dist = dist })
                end
            end
        end
    end
    -- Sắp xếp từ gần đến xa
    table.sort(targets, function(a, b) return a.dist < b.dist end)
    return targets
end

-- Thực hiện đòn đánh vào 1 target — đa phương pháp, ưu tiên theo khả năng executor
local function AK_HitTarget(target)
    local now = tick()
    local plr = target.plr
    if AK.LastHit[plr] and (now - AK.LastHit[plr]) < AK.CoolPer then return end
    AK.LastHit[plr] = now

    local myChar = LocalPlayer.Character
    if not myChar then return end

    local enemyChar = plr.Character
    local enemyHRP  = target.hrp
    local enemyHum  = enemyChar and enemyChar:FindFirstChildOfClass("Humanoid")
    if not enemyChar or not enemyHRP or not enemyHum or enemyHum.Health <= 0 then return end

    local tool = myChar:FindFirstChildOfClass("Tool")

    -- ── Phương pháp 1: Teleport toàn bộ nhân vật tôi đến địch, Activate, rồi về ──
    -- Cách này đảm bảo hitbox của server nhận ra đòn đánh
    if tool then
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if myHRP then
            local savedCF = myHRP.CFrame
            -- Snap nhân vật tới địch
            pcall(function()
                myHRP.CFrame = enemyHRP.CFrame * CFrame.new(0, 0, -1.2)
            end)
            task.wait(0.015) -- 1 frame để server nhận vị trí
            pcall(function() tool:Activate() end)
            task.wait(0.015)
            -- Trả về vị trí cũ
            pcall(function()
                myHRP.CFrame = savedCF
                myHRP.AssemblyLinearVelocity = Vector3.zero
            end)
            return
        end
    end

    -- ── Phương pháp 2: Chỉ Activate tool không di chuyển (fallback khi không lấy được HRP) ──
    if tool then
        pcall(function() tool:Activate() end)
        return
    end

    -- ── Phương pháp 3: TakeDamage trực tiếp + HealthChanged event (client-side, nhiều game không block) ──
    pcall(function() enemyHum.Health = 0 end)
    pcall(function() enemyHum:TakeDamage(enemyHum.MaxHealth + 9999) end)

    -- ── Phương pháp 4: FireServer qua RemoteEvent nếu game có "DealDamage" / "Hit" remote ──
    -- Tìm và thử fire các remote phổ biến
    local function TryFireRemote(remoteNames, ...)
        for _, name in ipairs(remoteNames) do
            local remote = Workspace:FindFirstChild(name, true)
                       or game:GetService("ReplicatedStorage"):FindFirstChild(name, true)
            if remote and remote:IsA("RemoteEvent") then
                pcall(function() remote:FireServer(...) end)
            end
        end
    end
    TryFireRemote({"DealDamage","Hit","TakeDamage","Damage","OnDamage","HitPlayer"},
        enemyChar, enemyHum.MaxHealth + 9999)
end

-- Vòng lặp AimKill
local function AK_Loop()
    if AK.Conn then pcall(function() AK.Conn:Disconnect() end); AK.Conn = nil end
    if not AK.Enabled then return end

    local timer = 0
    AK.Conn = RunService.Heartbeat:Connect(function(dt)
        if not AK.Enabled or Unloaded then
            pcall(function() AK.Conn:Disconnect() end); AK.Conn = nil
            return
        end
        timer = timer + dt
        if timer < AK.Rate then return end
        timer = 0

        -- Dọn LastHit cũ để không rò bộ nhớ
        local now = tick()
        for plr, t in pairs(AK.LastHit) do
            if now - t > 5 then AK.LastHit[plr] = nil end
        end

        local targets = AK_GetTargets()
        if #targets == 0 then return end

        -- Thử tất cả target trong phạm vi, ưu tiên gần nhất
        for i = 1, math.min(#targets, 4) do
            pcall(function() AK_HitTarget(targets[i]) end)
        end
    end)
end

local function SetAimKill(on)
    AK.Enabled = on and true or false
    -- Dọn cooldown khi bật lại
    if AK.Enabled then ClearTableCompat(AK.LastHit) end
    if AK.Float then AK.Float.SetOn(AK.Enabled) end
    if AK.Toggle then AK.Toggle.Set(AK.Enabled, false) end
    if AK.Enabled then
        Notify("AimKill 3.1 Elite", "Bật — Phạm vi: " .. AK.Range .. " studs", 4)
        AK_Loop()
    else
        if AK.Conn then pcall(function() AK.Conn:Disconnect() end); AK.Conn = nil end
        Notify("AimKill 3.1 Elite", "Đã tắt AimKill", 3)
    end
end

-- Nút nổi AimKill (riêng biệt, kích thước nhỏ)
AK.Float = HS.CreateFloat("AimKill", 1100)
AK.Float.OnTap(function() SetAimKill(not AK.Enabled) end)

-- ── UI AimKill trong tab AimBot ──────────────────────────────────
CreateHeader(HS.TabAimbot, "AIMKILL · 3.1 ELITE")

AK.Toggle = CreateToggle(HS.TabAimbot, "AimKill · Bật / Tắt", false, function(s)
    SetAimKill(s)
end)

CreateSlider(HS.TabAimbot, "Phạm vi AimKill (studs)", 5, 200, 60, function(v)
    AK.Range = v
    if AK.Enabled then Notify("AimKill", "Phạm vi → " .. v .. " studs", 2) end
end)

CreateSlider(HS.TabAimbot, "Tốc độ AimKill (ms/lần)", 50, 800, 80, function(v)
    AK.Rate = v / 1000
end)

CreateToggle(HS.TabAimbot, "Hiện nút nổi AimKill", false, function(on)
    AK.Float.Show(on)
end)

CreateLabel(HS.TabAimbot, "AimKill dùng Tool đang cầm để tấn công tất cả kẻ địch trong phạm vi. Nếu không có Tool sẽ fallback TakeDamage client-side.", C.Sub)
CreateLabel(HS.TabAimbot, "Hiệu quả phụ thuộc vào cơ chế combat của từng game. Team Check được tôn trọng.", C.Sub)

-- ── Fix: CharacterAdded re-init toàn bộ chức năng loop ──────────
-- Dùng task.spawn + wait dài hơn để HumanoidRootPart kịp spawn
Connections[#Connections + 1] = LocalPlayer.CharacterAdded:Connect(function(char)
    -- Chờ nhân vật load xong hoàn toàn
    char:WaitForChild("HumanoidRootPart", 8)
    char:WaitForChild("Humanoid", 8)
    task.wait(1.2)
    if Unloaded then return end

    -- Re-init AimKill: hard-disconnect conn cũ trước
    if AK.Enabled then
        if AK.Conn then
            pcall(function() AK.Conn:Disconnect() end)
            AK.Conn = nil
        end
        ClearTableCompat(AK.LastHit)
        task.wait(0.1)
        AK_Loop()
    end

    -- Re-init HitFly
    if HF and HF.Enabled then
        if HF.Conn then
            pcall(function() HF.Conn:Disconnect() end)
            HF.Conn = nil
        end
        HF.Busy = false
        task.wait(0.05)
        HitFly_Loop()
    end

    -- Re-init Dash
    if DS and DS.Enabled then
        if DS.Conn then
            pcall(function() DS.Conn:Disconnect() end)
            DS.Conn = nil
        end
        DS.Busy = false
        DS.LastDash = 0
    end

    -- Re-init Freeze client-side nếu đang bật
    if FRZE and FRZE.Enabled and type(FRZE_Apply) == "function" then
        task.spawn(FRZE_Apply)
    end
end)

-- ── Hook unload: dọn AimKill ────────────────────────────────────
local _akOldUnload = Env.HyperSunUnload
Env.HyperSunUnload = function()
    AK.Enabled = false
    if AK.Conn then pcall(function() AK.Conn:Disconnect() end); AK.Conn = nil end
    ClearTableCompat(AK.LastHit)
    if _akOldUnload then pcall(_akOldUnload) end
end

-- ════════════════════════════════════════════════════════════════
--  FREEZE · 3.1 ELITE
--  Đóng băng toàn bộ kẻ địch trên map — client-side:
--  - Anchor HRP cục bộ bằng BodyPosition/BodyGyro (không replicate)
--  - Vẫn có thể gây sát thương / tương tác
--  - Bên phía địch họ vẫn di chuyển bình thường
--  - Tắt → xóa toàn bộ constraint, địch trả về trạng thái bình thường
-- ════════════════════════════════════════════════════════════════

local FRZE = {
    Enabled = false,
    Float   = nil,
    Toggle  = nil,
    -- [hrp] = { bp = BodyPosition, bg = BodyGyro, savedMass = ... }
    Frozen  = {},
    Conn    = nil,  -- Heartbeat để giữ position (BodyPosition đủ, dùng như backup)
    AddConn = nil,  -- PlayerAdded
    RemConn = nil,  -- PlayerRemoving
}

-- Đóng băng 1 HRP bằng BodyPosition + BodyGyro (không replicate sang server)
local function FRZE_FreezeHRP(hrp)
    if not hrp or not hrp.Parent then return end
    if FRZE.Frozen[hrp] then return end -- đã freeze

    local savedPos = hrp.Position
    local savedCF  = hrp.CFrame

    -- BodyPosition giữ chỗ
    local bp, bg
    pcall(function()
        bp = Instance.new("BodyPosition")
        bp.Name     = "HyperSunFreezeBP"
        bp.Position = savedPos
        bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bp.P        = 1e5
        bp.D        = 1e4
        bp.Parent   = hrp
    end)
    pcall(function()
        bg = Instance.new("BodyGyro")
        bg.Name      = "HyperSunFreezeBG"
        bg.CFrame    = savedCF
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bg.P         = 1e5
        bg.D         = 500
        bg.Parent    = hrp
    end)

    FRZE.Frozen[hrp] = { bp = bp, bg = bg, pos = savedPos, cf = savedCF }
end

-- Giải đóng băng 1 HRP
local function FRZE_UnfreezeHRP(hrp)
    local data = FRZE.Frozen[hrp]
    if not data then return end
    pcall(function() if data.bp and data.bp.Parent then data.bp:Destroy() end end)
    pcall(function() if data.bg and data.bg.Parent then data.bg:Destroy() end end)
    FRZE.Frozen[hrp] = nil
end

-- Đóng băng tất cả player hiện tại
function FRZE_Apply()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local c   = plr.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                pcall(function() FRZE_FreezeHRP(hrp) end)
            end
        end
    end
end

-- Dọn tất cả
local function FRZE_Clear()
    for hrp, _ in pairs(FRZE.Frozen) do
        pcall(function() FRZE_UnfreezeHRP(hrp) end)
    end
    -- Dọn bảng
    for k in pairs(FRZE.Frozen) do FRZE.Frozen[k] = nil end
end

-- Heartbeat: đảm bảo các player join sau vẫn bị freeze, và xử lý respawn địch
local function FRZE_StartLoop()
    if FRZE.Conn then pcall(function() FRZE.Conn:Disconnect() end); FRZE.Conn = nil end
    local timer = 0
    FRZE.Conn = RunService.Heartbeat:Connect(function(dt)
        if not FRZE.Enabled or Unloaded then
            pcall(function() FRZE.Conn:Disconnect() end); FRZE.Conn = nil
            return
        end
        timer = timer + dt
        if timer < 0.5 then return end -- kiểm tra mỗi 0.5s
        timer = 0

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local c   = plr.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    -- Freeze nếu chưa có
                    if not FRZE.Frozen[hrp] then
                        pcall(function() FRZE_FreezeHRP(hrp) end)
                    end
                end
            end
        end

        -- Dọn các hrp đã không còn hợp lệ
        for hrp, _ in pairs(FRZE.Frozen) do
            if not hrp or not hrp.Parent then
                pcall(function() FRZE_UnfreezeHRP(hrp) end)
                FRZE.Frozen[hrp] = nil
            end
        end
    end)
end

-- CharacterAdded của từng địch: freeze lại sau respawn
local function FRZE_WatchPlayer(plr)
    if plr == LocalPlayer then return end
    Connections[#Connections + 1] = plr.CharacterAdded:Connect(function(char)
        if not FRZE.Enabled or Unloaded then return end
        task.wait(0.6)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            pcall(function() FRZE_FreezeHRP(hrp) end)
        end
    end)
end

local function SetFreeze(on)
    FRZE.Enabled = on and true or false
    if FRZE.Float  then FRZE.Float.SetOn(FRZE.Enabled) end
    if FRZE.Toggle then FRZE.Toggle.Set(FRZE.Enabled, false) end

    if FRZE.Enabled then
        -- Freeze tất cả ngay lập tức
        FRZE_Apply()
        -- Bắt đầu vòng lặp maintain
        FRZE_StartLoop()
        -- Theo dõi player mới join
        if FRZE.AddConn then pcall(function() FRZE.AddConn:Disconnect() end) end
        FRZE.AddConn = Players.PlayerAdded:Connect(function(plr)
            task.wait(1)
            if not FRZE.Enabled then return end
            FRZE_WatchPlayer(plr)
            local c   = plr.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function() FRZE_FreezeHRP(hrp) end) end
        end)
        -- Watch tất cả player hiện tại cho respawn
        for _, plr in ipairs(Players:GetPlayers()) do
            FRZE_WatchPlayer(plr)
        end
        Notify("Freeze 3.1 Elite", "Đã đóng băng " .. tostring(#Players:GetPlayers() - 1) .. " người chơi (cục bộ)", 5)
    else
        -- Tắt loop
        if FRZE.Conn then pcall(function() FRZE.Conn:Disconnect() end); FRZE.Conn = nil end
        if FRZE.AddConn then pcall(function() FRZE.AddConn:Disconnect() end); FRZE.AddConn = nil end
        -- Giải đóng băng tất cả
        FRZE_Clear()
        Notify("Freeze 3.1 Elite", "Đã giải đóng băng toàn bộ", 4)
    end
end

-- ── Nút nổi Freeze (mới, riêng biệt với FreezeMarker cũ) ────────
FRZE.Float = HS.CreateFloat("Freeze", 1150)
FRZE.Float.OnTap(function() SetFreeze(not FRZE.Enabled) end)

-- ── UI Freeze trong tab Location ─────────────────────────────────
CreateHeader(HS.TabLoc, "FREEZE · 3.1 ELITE")
CreateLabel(HS.TabLoc, "Đóng băng toàn bộ kẻ địch trên map — chỉ bạn thấy họ đứng im. Vẫn gây sát thương được.", C.Sub)

FRZE.Toggle = CreateToggle(HS.TabLoc, "Freeze · Bật / Tắt", false, function(s)
    SetFreeze(s)
end)

CreateToggle(HS.TabLoc, "Hiện nút nổi Freeze", false, function(on)
    FRZE.Float.Show(on)
end)

CreateLabel(HS.TabLoc, "Freeze dùng BodyPosition + BodyGyro cục bộ, không replicate sang server. Địch vẫn di chuyển bình thường phía họ.", C.Sub)

-- ── Hook unload: dọn Freeze ──────────────────────────────────────
local _frzeOldUnload = Env.HyperSunUnload
Env.HyperSunUnload = function()
    FRZE.Enabled = false
    if FRZE.Conn   then pcall(function() FRZE.Conn:Disconnect() end);   FRZE.Conn   = nil end
    if FRZE.AddConn then pcall(function() FRZE.AddConn:Disconnect() end); FRZE.AddConn = nil end
    FRZE_Clear()
    if _frzeOldUnload then pcall(_frzeOldUnload) end
end

-- ════════════════════════════════════════════════════════════════
--  FPS BOOST · Max version only
-- ════════════════════════════════════════════════════════════════
local FPS = { Enabled = false, Float = nil }
local FPS_Saved = {}

local function SetFPSBoost(on)
    FPS.Enabled = on and true or false
    if FPS.Float then FPS.Float.SetOn(FPS.Enabled) end
    if FPS.Enabled then
        -- Giảm đồ họa xuống mức tối thiểu client-side
        pcall(function()
            FPS_Saved.GlobalShadows   = Lighting.GlobalShadows
            FPS_Saved.FogEnd          = Lighting.FogEnd
            FPS_Saved.Brightness      = Lighting.Brightness
            Lighting.GlobalShadows    = false
            Lighting.FogEnd           = 100000
            Lighting.Brightness       = 1
        end)
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    FPS_Saved[obj] = obj.Enabled
                    obj.Enabled = false
                end
                if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                    FPS_Saved[obj] = obj.Enabled
                    obj.Enabled = false
                end
            end
        end)
        pcall(function()
            local settings = UserSettings()
            if settings and settings.GameSettings then
                FPS_Saved.SavedQuality = settings.GameSettings.SavedQualityLevel
                settings.GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
            end
        end)
        Notify("FPS Boost · Max", "Đã tắt bóng/hạt/đèn — FPS tối đa", 4)
    else
        pcall(function()
            if FPS_Saved.GlobalShadows ~= nil then Lighting.GlobalShadows = FPS_Saved.GlobalShadows end
            if FPS_Saved.FogEnd        ~= nil then Lighting.FogEnd        = FPS_Saved.FogEnd end
            if FPS_Saved.Brightness    ~= nil then Lighting.Brightness    = FPS_Saved.Brightness end
        end)
        pcall(function()
            for obj, state in pairs(FPS_Saved) do
                if typeof(obj) == "Instance" and obj.Parent then
                    pcall(function() obj.Enabled = state end)
                end
            end
        end)
        pcall(function()
            local settings = UserSettings()
            if settings and settings.GameSettings and FPS_Saved.SavedQuality then
                settings.GameSettings.SavedQualityLevel = FPS_Saved.SavedQuality
            end
        end)
        Notify("FPS Boost · Max", "Đã khôi phục đồ họa", 3)
    end
end

-- Thêm vào tab Location, chỉ hiện khi Max inject
FPS.Float = HS.CreateFloat("FPS+", 1200)
FPS.Float.OnTap(function()
    if INJECT_TIER ~= "max" then
        Notify("FPS Boost", "🔒 Chỉ dành cho Inject Max!", 3)
        FPS.Float.SetOn(false)
        return
    end
    SetFPSBoost(not FPS.Enabled)
end)
CreateHeader(HS.TabLoc, "FPS BOOST · MAX ONLY")
CreateToggle(HS.TabLoc, "Tăng FPS · Giảm đồ họa tối đa", false, function(s)
    if INJECT_TIER ~= "max" then
        Notify("FPS Boost", "🔒 Chỉ dành cho Inject Max!", 3)
        return
    end
    SetFPSBoost(s)
end)
CreateToggle(HS.TabLoc, "Hiện nút nổi FPS+", false, function(on)
    FPS.Float.Show(on)
end)
CreateLabel(HS.TabLoc, "Tắt bóng, hạt, đèn, giảm chất lượng render client-side — không ảnh hưởng người khác.", C.Sub)

-- ════════════════════════════════════════════════════════════════
--  CREATE CAR · Beta version only
-- ════════════════════════════════════════════════════════════════
local CAR = { Enabled = false, Float = nil, Model = nil, Conn = nil }
local CAR_SavedWalkSpeed = nil
local CAR_SavedAnimId = nil

local function DestroyCar()
    if CAR.Model then pcall(function() CAR.Model:Destroy() end); CAR.Model = nil end
    if CAR.Conn  then pcall(function() CAR.Conn:Disconnect() end); CAR.Conn = nil end
    -- Khôi phục walk speed
    local c = LocalPlayer.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if hum and CAR_SavedWalkSpeed then
        pcall(function() hum.WalkSpeed = CAR_SavedWalkSpeed end)
    end
    CAR_SavedWalkSpeed = nil
end

local function CreateCarModel()
    local c = LocalPlayer.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return nil end

    -- Tạo model xe đơn giản từ Part
    local model = Instance.new("Model")
    model.Name = "HyperSun_Car"

    -- Thân xe
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(6, 1.6, 3)
    body.BrickColor = BrickColor.new("Bright red")
    body.Material = Enum.Material.SmoothPlastic
    body.CFrame = hrp.CFrame * CFrame.new(0, -2, 0)
    body.CanCollide = false
    body.Anchored = false
    body.Parent = model

    -- Cabin
    local cabin = Instance.new("Part")
    cabin.Name = "Cabin"
    cabin.Size = Vector3.new(3.5, 1.4, 2.8)
    cabin.BrickColor = BrickColor.new("Bright red")
    cabin.Material = Enum.Material.SmoothPlastic
    cabin.CFrame = body.CFrame * CFrame.new(-0.5, 1.5, 0)
    cabin.CanCollide = false
    cabin.Anchored = false
    cabin.Parent = model

    -- 4 bánh
    local wheelPositions = {
        Vector3.new(2, -1, 1.6),
        Vector3.new(2, -1, -1.6),
        Vector3.new(-2, -1, 1.6),
        Vector3.new(-2, -1, -1.6),
    }
    for i, pos in ipairs(wheelPositions) do
        local wheel = Instance.new("Part")
        wheel.Name = "Wheel"..i
        wheel.Size = Vector3.new(0.5, 1.2, 1.2)
        wheel.Shape = Enum.PartType.Cylinder
        wheel.BrickColor = BrickColor.new("Black")
        wheel.Material = Enum.Material.SmoothPlastic
        wheel.CFrame = body.CFrame * CFrame.new(pos.X, pos.Y, pos.Z)
        wheel.CanCollide = false
        wheel.Anchored = false
        wheel.Parent = model
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = body; weld.Part1 = wheel; weld.Parent = model
    end

    local weldCabin = Instance.new("WeldConstraint")
    weldCabin.Part0 = body; weldCabin.Part1 = cabin; weldCabin.Parent = model

    -- Weld xe vào HRP
    local mainWeld = Instance.new("WeldConstraint")
    mainWeld.Part0 = hrp; mainWeld.Part1 = body; mainWeld.Parent = model

    model.PrimaryPart = body
    model.Parent = Workspace
    return model, hum
end

local function SetCreateCar(on)
    CAR.Enabled = on and true or false
    if CAR.Float then CAR.Float.SetOn(CAR.Enabled) end
    if CAR.Enabled then
        if INJECT_TIER ~= "beta" and INJECT_TIER ~= "max" then
            Notify("Create Car", "🔒 Chỉ dành cho Inject Beta / Max!", 3)
            CAR.Enabled = false
            if CAR.Float then CAR.Float.SetOn(false) end
            return
        end
        local c = LocalPlayer.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        CAR_SavedWalkSpeed = hum.WalkSpeed
        -- Tăng WalkSpeed để xe chạy nhanh hơn
        pcall(function() hum.WalkSpeed = 28 end)
        local model = CreateCarModel()
        CAR.Model = model
        -- Giảm hoạt ảnh nhân vật (ẩn chân đi bộ — dùng hipheight)
        pcall(function() hum.HipHeight = 2.2 end)
        Notify("Create Car · Beta", "Xe đã được tạo — WASD/joystick để lái", 5)
    else
        DestroyCar()
        local c = LocalPlayer.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.HipHeight = 0 end) end
        Notify("Create Car · Beta", "Đã xóa xe, khôi phục nhân vật", 3)
    end
end

-- CharacterAdded: xóa xe khi respawn
Connections[#Connections+1] = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if CAR.Enabled then
        CAR.Model = nil
        task.wait(0.8)
        SetCreateCar(true)
    end
end)

CAR.Float = HS.CreateFloat("Car", 1250)
CAR.Float.OnTap(function() SetCreateCar(not CAR.Enabled) end)

CreateHeader(HS.TabMem, "CREATE CAR · BETA ONLY")
CreateToggle(HS.TabMem, "Create Car · Bật / Tắt", false, function(s)
    SetCreateCar(s)
end)
CreateToggle(HS.TabMem, "Hiện nút nổi Car", false, function(on)
    CAR.Float.Show(on)
end)
CreateLabel(HS.TabMem, "Tạo xe hơi gắn vào nhân vật. Dùng joystick/WASD để lái. Chỉ hiện phía client.", C.Sub)

-- Unload hook tổng cuối cùng
local _finalOld = Env.HyperSunUnload
Env.HyperSunUnload = function()
    SetFPSBoost(false)
    DestroyCar()
    if _finalOld then pcall(_finalOld) end
end
