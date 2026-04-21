local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // Variables //
local ESPEnabled = false
local AimEnabled = false
local FOVVisible = false
local FOVSize = 150
local Smoothing = 0.15 
local highlights = {}

-- // FOV Drawing //
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(0, 255, 255)
FOVCircle.Filled = false
FOVCircle.Visible = false

-- // UI SETUP //
local Library = loadstring(game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()

local Window = Library:Window({
    Title = "NWR's Hub | Blox Strike",
    SubTitle = "by whoisnwr",
    TabWidth = 160, 
    Size = UDim2.fromOffset(580, 520),
    Acrylic = true, 
    Theme = "Darker",
})

local Tabs = { 
    Main = Window:AddTab({ Title = "Main", Icon = "target" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- // CORE LOGIC //
local function updateHighlight(player)
    if player == LocalPlayer then return end
    if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end

    if ESPEnabled and player.Character and player.Character.Parent then
        local highlight = Instance.new("Highlight")
        highlight.Parent = player.Character
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        -- Team Detection logic
        local char = player.Character
        local isTeammate = (char.Parent.Name == (LocalPlayer.Character and LocalPlayer.Character.Parent.Name))
        highlight.FillColor = isTeammate and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        highlights[player] = highlight
    end
end

local function getClosestEnemy()
    local mousePos = UserInputService:GetMouseLocation()
    local target = nil
    local shortestDist = FOVSize
    local localTeam = (LocalPlayer.Character and LocalPlayer.Character.Parent) and LocalPlayer.Character.Parent.Name or ""

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if player.Character.Parent.Name ~= localTeam then
                local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        target = player.Character.Head
                    end
                end
            end
        end
    end
    return target
end

-- // ADDING UI ELEMENTS (Simplified for compatibility) //

Tabs.Main:AddToggle("ESPTog", {
    Title = "Player Highlights (ESP)",
    Default = false,
    Callback = function(v) 
        ESPEnabled = v 
        for _, p in ipairs(Players:GetPlayers()) do updateHighlight(p) end
    end
})

Tabs.Main:AddToggle("AimTog", {
    Title = "Enable Aim Assist",
    Default = false,
    Callback = function(v) AimEnabled = v end
})

Tabs.Main:AddToggle("FOVTog", {
    Title = "Show FOV Circle",
    Default = false,
    Callback = function(v) FOVVisible = v end
})

Tabs.Main:AddSlider("FOVSlider", {
    Title = "FOV Size",
    Default = 150,
    Min = 30,
    Max = 500,
    Rounding = 0,
    Callback = function(v) FOVSize = v end
})

Tabs.Main:AddSlider("SmoothSlider", {
    Title = "Smoothing Speed",
    Default = 0.15,
    Min = 0.05,
    Max = 1,
    Rounding = 2,
    Callback = function(v) Smoothing = v end
})

-- // THE "RECOIL-PROOF" LOCK LOGIC //

local function handleAimAssist()
    -- Update FOV Circle Position
    FOVCircle.Visible = FOVVisible
    FOVCircle.Radius = FOVSize
    FOVCircle.Position = UserInputService:GetMouseLocation()

    -- Check if we should be locking
    if AimEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosestEnemy()
        
        if target then
            -- Check if player is firing (MouseButton1)
            local isFiring = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            
            -- If firing, we use a much stronger pull to fight the recoil
            -- We increase the smoothing significantly during shots
            local currentSmoothing = isFiring and math.clamp(Smoothing * 2, 0, 1) or Smoothing
            
            local targetRotation = CFrame.lookAt(Camera.CFrame.Position, target.Position)
            
            -- We use a precise Lerp to "overpower" the recoil's camera movement
            Camera.CFrame = Camera.CFrame:Lerp(targetRotation, currentSmoothing)
        end
    end
end

-- We bind this to run AFTER the internal camera scripts
RunService:UnbindFromRenderStep("AssistLock") -- Clear previous just in case
RunService:BindToRenderStep("AssistLock", Enum.RenderPriority.Camera.Value + 1, handleAimAssist)

-- Initial Load / Respawn Listeners
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.5); updateHighlight(p) end) end)
for _, p in ipairs(Players:GetPlayers()) do 
    if p.Character then task.spawn(function() updateHighlight(p) end) end
    p.CharacterAdded:Connect(function() task.wait(0.5); updateHighlight(p) end) 
end

Library:Notify({Title = "NWR's Hub", Content = "Main Features Loaded Successfully", Duration = 5})
