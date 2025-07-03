local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/dirt", true))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Table = {}
local ESPObjects = {}
local FOVCircle
local IsAiming = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        IsAiming = false
    end
end)

local window = Lib:CreateWindow("deadsec")

window:Section("Aimbot")
window:Toggle("Enabled", {location = Table, flag = "AimbotEnabled"}, function() end)
window:Toggle("Wallcheck", {location = Table, flag = "WallcheckEnabled"}, function() end)
window:Toggle("Teamcheck", {location = Table, flag = "TeamcheckEnabled"}, function() end)

window:Slider("X Prediction", {
    location = Table,
    min = 0,
    max = 10,
    default = 5,
    precise = true,
    flag = "XPrediction"
}, function() end)

window:Slider("Y Prediction", {
    location = Table,
    min = 0,
    max = 10,
    default = 5,
    precise = true,
    flag = "YPrediction"
}, function() end)

window:Slider("Smoothness", {
    location = Table,
    min = 0,
    max = 10,
    default = 3,
    precise = true,
    flag = "Smoothness"
}, function() end)

window:Section("Visuals")
window:Toggle("Box ESP", {location = Table, flag = "ESP"}, function() end)

window:Slider("FOV Radius", {
    location = Table,
    min = 0,
    max = 1000,
    default = 250,
    precise = false,
    flag = "FOV"
}, function() end)

window:Toggle("Visualize FOV", {location = Table, flag = "FovVisibility"}, function() end)

window:Section("Players")
window:Dropdown("Player List", {
    location = Table,
    flag = "SelectedPlayer",
    search = true,
    PlayerList = true
}, function() end)

window:Button("Teleport to Player", function()
    local target = Players:FindFirstChild(Table.SelectedPlayer)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character:MoveTo(target.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
    end
end)

window:Toggle("Spectate Player", {location = Table, flag = "Spectate"}, function() end)
window:Search(Color3.fromRGB(255, 0, 255))

local function IsValidTarget(player)
    if player == LocalPlayer then return false end
    if Table.TeamcheckEnabled and player.Team == LocalPlayer.Team then return false end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") or (char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0) then
        return false
    end
    if Table.WallcheckEnabled then
        local ray = Ray.new(Camera.CFrame.Position, (char.Head.Position - Camera.CFrame.Position).Unit * 500)
        local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
        if hit and not char:IsAncestorOf(hit) then
            return false
        end
    end
    return true
end

local function GetClosestTarget()
    local closest, distance = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist < distance and dist <= Table.FOV then
                    distance = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

local function AimAt(target)
    local head = target.Character.Head
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")

    if not head or not hrp then return end

    local velocity = hrp.Velocity
    local predictionTime = math.clamp(Table.XPrediction / 25, 0, 0.4)

    local predictedPos = head.Position + (velocity * predictionTime)

    local direction = (predictedPos - Camera.CFrame.Position).Unit
    local targetCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + direction)

    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, math.clamp(Table.Smoothness / 10, 0.01, 1))
end


local function ClearESP()
    for _, drawing in pairs(ESPObjects) do
        if drawing.Remove then
            drawing:Remove()
        elseif drawing.Destroy then
            drawing:Destroy()
        end
    end
    ESPObjects = {}
end

local function DrawBox(player)
    local char = player.Character
    if not char or not char:FindFirstChild("Head") or not char:FindFirstChild("HumanoidRootPart") then return end

    local headPos, onScreen1 = Camera:WorldToViewportPoint(char.Head.Position)
    local rootPos, onScreen2 = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)

    if not (onScreen1 and onScreen2) then return end

    local height = math.abs(headPos.Y - rootPos.Y) * 2
    local width = height / 2
    local topLeft = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)

    local box = Drawing.new("Square")
    box.Position = topLeft
    box.Size = Vector2.new(width, height)
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Thickness = 1
    box.Transparency = 1
    box.Filled = false
    box.Visible = true

    table.insert(ESPObjects, box)
end

local function DrawFOV()
    if FOVCircle then FOVCircle:Remove() end
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Table.FOV or 250
    FOVCircle.Thickness = 1
    FOVCircle.Transparency = 1
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Filled = false
    FOVCircle.Visible = Table.FovVisibility
end

RunService.Heartbeat:Connect(function()
    if Table.AimbotEnabled and IsAiming then
      local target = GetClosestTarget()
      if target then
         AimAt(target)
      end
   end

   if Table.ESP then
      ClearESP()
      for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                DrawBox(player)
            end
        end
      end
   else
      ClearESP()
   end

    if Table.FovVisibility then
        DrawFOV()
    elseif FOVCircle then
        FOVCircle:Remove()
        FOVCircle = nil
    end

    if Table.Spectate and Table.SelectedPlayer then
        local target = Players:FindFirstChild(Table.SelectedPlayer)
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CameraSubject = target.Character.Head
        end
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end
end)
