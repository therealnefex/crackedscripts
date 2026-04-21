local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Anime Eternal | NWR's Hub",
    SubTitle = "by whoisnwr",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, 
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Toggle = Tabs.Main:AddToggle("TurboClicker", {
    Title = "Turbo Auto-Click", 
    Default = false 
})

local RunService = game:GetService("RunService")
local Remote = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("To_Server")
local ActionPacket = {["Action"] = "_Mouse_Click"}
local fireServer = Remote.FireServer

local ClickLoop

Toggle:OnChanged(function()
    getgenv().TurboClick = Toggle.Value
    
    if getgenv().TurboClick then

        ClickLoop = RunService.Stepped:Connect(function()
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                fireServer(Remote, ActionPacket)
            end
        end)
    else
    
        if ClickLoop then
            ClickLoop:Disconnect()
        end
    end
end)

Tabs.Main:AddSlider("ClickSpeed", {
    Title = "Click Frequency Multiplier",
    Description = "Higher = More clicks per frame",
    Default = 1,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Callback = function(Value)
        print("Multiplier set to:", Value)
    end
})

local TestToggle = Tabs.Main:AddToggle("TestToggle", {
    Title = "Monster Farm",
    Description = "Finds and teleports to specific colored monsters",
    Default = false
})

local MonsterFarmLoop
local isLoopRunning = false

TestToggle:OnChanged(function()
    getgenv().TestToggleValue = TestToggle.Value
    
    if getgenv().TestToggleValue then
        isLoopRunning = true
        
        MonsterFarmLoop = task.spawn(function()
            local plr = game.Players.LocalPlayer
            local hrp = (plr.Character or plr.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
            local monsters = workspace.Debris.Monsters
            local color = Color3.fromRGB(17, 17, 17)
            
            while isLoopRunning do
                if not getgenv().TestToggleValue then break end
                
                for _, m in ipairs(monsters:GetChildren()) do
                    if not isLoopRunning or not getgenv().TestToggleValue then break end
                    
                    local h = m:FindFirstChild("Hair")
                    local handle = h and h:FindFirstChild("Handle")
                    
                    if handle and handle:IsA("BasePart") and handle.Color == color then
                        hrp.CFrame = m:GetPivot() * CFrame.new(0, 0, -5)
                        task.wait(3)
                        break
                    end
                end
                task.wait(0.2)
            end
        end)
    else
    
        isLoopRunning = false
        if MonsterFarmLoop then
            task.cancel(MonsterFarmLoop)
        end
    end
end)

local Tabs = { Main = Window:AddTab({ Title = "Auto Farm", Icon = "map-pin" }) }
local SavedSpawns = {}
local StayTime = 2 
getgenv().EnableAutoFarm = false

Tabs.Main:AddSlider("StayTime", {
    Title = "Stay Duration (Seconds)",
    Description = "How long to stay at each logged position",
    Default = 2,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Callback = function(Value)
        StayTime = Value
    end
})

Tabs.Main:AddButton({
    Title = "Save Current Position",
    Description = "Logs your current coordinates to the Auto Farm list",
    Callback = function()
        local lp = game.Players.LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(SavedSpawns, lp.Character.HumanoidRootPart.CFrame)
            Fluent:Notify({
                Title = "System",
                Content = "Position logged successfully",
                Duration = 2
            })
        end
    end
})

Tabs.Main:AddToggle("EnableAutoFarm", {
    Title = "Start Auto Farm",
    Default = false,
    Callback = function(Value)
        getgenv().EnableAutoFarm = Value
    end
})

Tabs.Main:AddButton({
    Title = "Clear All Positions",
    Callback = function()
        table.clear(SavedSpawns)
        Fluent:Notify({Title = "System", Content = "List cleared", Duration = 2})
    end
})

task.spawn(function()
    local lp = game.Players.LocalPlayer
    
    while true do
        task.wait(0.1)
        if getgenv().EnableAutoFarm and #SavedSpawns > 0 then
            for i, spawnCF in ipairs(SavedSpawns) do
                if not getgenv().EnableAutoFarm then break end
                
                local char = lp.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    hrp.CFrame = spawnCF                
             
                    local endTime = tick() + StayTime
                    repeat 
                    
                        hrp.CFrame = spawnCF 
                        task.wait() 
                    until tick() >= endTime or not getgenv().EnableAutoFarm
                end
            end
        end
    end
end)

Window:SelectTab(1)
Fluent:Notify({
    Title = "UI Loaded",
    Content = "NWR's Hub access granted.",
    Duration = 5
})
