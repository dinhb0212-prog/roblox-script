local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "SCRIPT GIẢI TRÍ",
    LoadingTitle = "SCRIPT GIẢI TRÍ",
    LoadingSubtitle = "POV CENTER FIX",
    ConfigurationSaving = {Enabled = false}
})

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

-- ===== VAR =====
local AimEnabled = false
local ShowFOV = false
local Radius = 220
local Smooth = 0.25

-- ===== COLOR VAR =====
local POVColor = Color3.fromRGB(255,255,255)
local ESPColor = Color3.fromRGB(0,255,0)

-- ===== RAINBOW VAR =====
local RainbowPOV = false
local RainbowESP = false
local Hue = 0

-- ===== ESP VAR =====
local ESPEnabled = false
local ESPObjects = {}

-- ===== FOV =====
local FOV = Drawing.new("Circle")
FOV.Thickness = 2
FOV.Filled = false
FOV.Radius = Radius
FOV.Visible = false

-- ===== FORCE CAMERA CENTER =====
local function FixCamera()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    Camera.CameraSubject = hum
    Camera.CameraType = Enum.CameraType.Custom
    hum.CameraOffset = Vector3.zero
end

LP.CharacterAdded:Connect(function()
    task.wait(0.2)
    FixCamera()
end)

FixCamera()

-- ===== GET TARGET =====
local function GetTarget()
    local closest, dist = nil, Radius
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("Head") then
            local pos, onscreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if onscreen then
                local mag = (Vector2.new(pos.X,pos.Y) - center).Magnitude
                if mag < dist then
                    dist = mag
                    closest = plr.Character.Head
                end
            end
        end
    end
    return closest
end

-- ===== ESP =====
local function CreateESP(plr)
    if plr == LP then return end

    local box = Drawing.new("Square")
    box.Thickness = 1.5
    box.Filled = false
    box.Visible = false

    local name = Drawing.new("Text")
    name.Size = 14
    name.Center = true
    name.Outline = true
    name.Visible = false

    ESPObjects[plr] = {Box = box, Name = name}
end

local function RemoveESP(plr)
    if ESPObjects[plr] then
        ESPObjects[plr].Box:Remove()
        ESPObjects[plr].Name:Remove()
        ESPObjects[plr] = nil
    end
end

for _,plr in ipairs(Players:GetPlayers()) do
    CreateESP(plr)
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- ===== MAIN LOOP =====
RunService:BindToRenderStep("SCRIPT_GIAI_TRI", Enum.RenderPriority.Camera.Value + 5, function()
    FixCamera()

    -- Rainbow update
    Hue = (Hue + 0.002) % 1
    local RainbowColor = Color3.fromHSV(Hue,1,1)

    -- FOV
    FOV.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOV.Color = RainbowPOV and RainbowColor or POVColor
    FOV.Visible = ShowFOV

    -- AIM
    if AimEnabled then
        local target = GetTarget()
        if target then
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.lookAt(Camera.CFrame.Position, target.Position),
                Smooth
            )
        end
    end

    -- ESP
    for plr,esp in pairs(ESPObjects) do
        local char = plr.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        local color = RainbowESP and RainbowColor or ESPColor
        esp.Box.Color = color
        esp.Name.Color = color

        if ESPEnabled and char and hum and hum.Health > 0 and hrp then
            local pos, onscreen = Camera:WorldToViewportPoint(hrp.Position)
            if onscreen then
                local scale = 1 / (pos.Z * 0.01)
                local w = math.clamp(35 * scale, 20, 100)
                local h = math.clamp(50 * scale, 30, 150)

                esp.Box.Size = Vector2.new(w,h)
                esp.Box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                esp.Box.Visible = true

                esp.Name.Text = plr.Name.." ["..math.floor((Camera.CFrame.Position - hrp.Position).Magnitude).."m]"
                esp.Name.Position = Vector2.new(pos.X, pos.Y - h/2 - 14)
                esp.Name.Visible = true
            else
                esp.Box.Visible = false
                esp.Name.Visible = false
            end
        else
            esp.Box.Visible = false
            esp.Name.Visible = false
        end
    end
end)

-- ===== UI =====
local AimTab = Window:CreateTab("Aimbot")
local ColorTab = Window:CreateTab("Colors 🌈")

AimTab:CreateToggle({
    Name = "Aim POV (CENTER)",
    Callback = function(v) AimEnabled = v end
})

AimTab:CreateToggle({
    Name = "Show FOV (Center)",
    Callback = function(v) ShowFOV = v end
})

AimTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50,500},
    Increment = 10,
    CurrentValue = Radius,
    Callback = function(v)
        Radius = v
        FOV.Radius = v
    end
})

AimTab:CreateSlider({
    Name = "Smooth",
    Range = {0.05,0.5},
    Increment = 0.01,
    CurrentValue = Smooth,
    Callback = function(v) Smooth = v end
})

AimTab:CreateToggle({
    Name = "ESP Player",
    Callback = function(v) ESPEnabled = v end
})

-- ===== COLOR =====
ColorTab:CreateToggle({
    Name = "Rainbow POV / FOV",
    Callback = function(v) RainbowPOV = v end
})

ColorTab:CreateToggle({
    Name = "Rainbow ESP",
    Callback = function(v) RainbowESP = v end
})

ColorTab:CreateColorPicker({
    Name = "POV / FOV Color",
    Color = POVColor,
    Callback = function(v) POVColor = v end
})

ColorTab:CreateColorPicker({
    Name = "ESP Color",
    Color = ESPColor,
    Callback = function(v) ESPColor = v end
})
