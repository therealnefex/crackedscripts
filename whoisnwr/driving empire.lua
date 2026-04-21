local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local completeRemote = Remotes:WaitForChild("AttemptCriminalJobComplete")
local lastSellTime = 0
local sellCooldown = 180 

local sellPart = workspace:FindFirstChild("CriminalHideout") and workspace.CriminalHideout:FindFirstChild("SellPart")

local Window = Fluent:CreateWindow({
    Title = "Driving Empire | NWR's Hub",
    SubTitle = "by whoisnwr",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl 
})

local Tabs = {
    Main = Window:AddTab({ Title = "Auto Drive", Icon = "car" }),
    ATM = Window:AddTab({ Title = "Auto Rob ATM (Money Farm)", Icon = "dollar-sign" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local settings = {
    Enabled = false,
    Speed = 400,      
    Height = 50,      
    TurnSpeed = 2,    
}

local speedIndex = 4 
local speedPresets = {
    {100, "Slow"},
    {200, "Average"},
    {300, "Fast"},
    {400, "Superspeed"},
    {500, "Supersonic"},
    {600, "Hyperspeed"},
    {700, "Godspeed"}
}

game:GetService("RunService").Stepped:Connect(function()
    if not settings.Enabled then return end
    
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local seat = humanoid.SeatPart
    
    if seat and seat:IsA("VehicleSeat") then
        local vehicle = seat.Parent 
        local root = (vehicle:IsA("Model") and vehicle.PrimaryPart) or seat
        
        local look = root.CFrame.LookVector
        root.AssemblyLinearVelocity = Vector3.new(look.X * settings.Speed, 0, look.Z * settings.Speed)
        
        local currentPos = root.Position
        if currentPos.Y < settings.Height then
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + Vector3.new(0, 50, 0)
        elseif currentPos.Y > settings.Height + 10 then
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity - Vector3.new(0, 10, 0)
        else
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
        end
        
        root.AssemblyAngularVelocity = Vector3.new(0, settings.TurnSpeed * 0.1, 0)
        seat.Throttle = 1
    end
end)

-- [[ UI ]] --
Tabs.Main:AddToggle("FarmToggle", {
    Title = "START FARM",
    Default = false,
    Callback = function(Value)
        settings.Enabled = Value
        if not Value then
            local char = game.Players.LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum and hum.SeatPart then
                    hum.SeatPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    hum.SeatPart.AssemblyAngularVelocity = Vector3.new(0,0,0)
                end
            end
        end
    end
})

Tabs.Main:AddButton({
    Title = "Cycle Speed Presets",
    Description = "Current: " .. settings.Speed,
    Callback = function()
        speedIndex = speedIndex + 1
        if speedIndex > #speedPresets then speedIndex = 1 end
        
        local preset = speedPresets[speedIndex]
        settings.Speed = preset[1]
        
        Fluent:Notify({
            Title = "Speed Updated",
            Content = "Set to: " .. preset[1] .. " (" .. preset[2] .. ")",
            Duration = 3
        })
    end
})

Tabs.Main:AddSlider("HeightSlider", {
    Title = "Height (Studs)",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        settings.Height = Value
    end
})


local plr = game.Players.LocalPlayer
local PlrGui = plr.PlayerGui
local char = plr.Character or plr.CharacterAdded:Wait()
local camera = workspace.CurrentCamera


local deb = false
local tracking = true
local finding = false


local function CompleteProximity(proximityPrompt:ProximityPrompt)
    if not proximityPrompt then return warn("No prompt found") end
    proximityPrompt:InputHoldBegin()
    task.wait(proximityPrompt.HoldDuration)
    proximityPrompt:InputHoldEnd()
end

function FindAtmSpawner()
    local spawnsTable = {}
    for _, v in workspace:GetDescendants() do
        if v:GetAttribute("ComponentServerId") and v.Name == "CriminalATMSpawner" then
            table.insert(spawnsTable, v)
        end
    end
    return spawnsTable
end

local function ChooseAtmSpawner()
    for _ , ATM:BasePart in workspace:GetDescendants() do
        if ATM:GetAttribute("ComponentServerId") and ATM.Name == "CriminalATMSpawner" then
            local CrimATM = ATM:FindFirstChild("CriminalATM")
            if CrimATM and CrimATM:GetAttribute("State") ~= "Busted" then
                return CrimATM
            end
        end
    end
end

function LoadAtm()
    if finding then
        local spawnsTable = FindAtmSpawner()
        if spawnsTable then
            local RandomSpawn = spawnsTable[math.random(1, #spawnsTable)]
            char:PivotTo(RandomSpawn.CFrame * CFrame.new(0,2,0))
            finding = false
            task.wait(4)
            tracking = true
        else
            finding = false
            tracking = true
        end
    end
end

function CameraFollow(Attachment)
    camera.CameraSubject = Attachment
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = Attachment.WorldCFrame * CFrame.new(0,4,-1) * CFrame.Angles(math.rad(-90),0,0)
end

function CameraReset()
    camera.CameraSubject = char:FindFirstChild("Humanoid")
    camera.CameraType = Enum.CameraType.Custom
end

function RobATM()
    if tracking then
        tracking = false
        local ATM = ChooseAtmSpawner()
        
        if ATM then
            local Attachment = ATM:FindFirstChild("Attachment")
            local Prompt = Attachment:FindFirstChild("ProximityPrompt")

           
            char:PivotTo(Attachment.WorldCFrame * CFrame.new(0, 2, 0))
            CameraFollow(Attachment)
            
            
            task.wait(0.3) 

           
            CompleteProximity(Prompt)
            
           
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.AttemptCriminalJobComplete:FireServer("ATM")
            end)
            
       
            task.wait(0.1)
            CameraReset()

         
            if (os.time() - lastSellTime) >= sellCooldown then
                task.wait(0.5) -- Slight pause before teleporting to sell
                char:PivotTo(CFrame.new(-2541.09961, 14.8917437, 4030.8147, 0.285834819, -1.93582732e-08, 0.958278894, 3.80772247e-10, 1, 2.00875085e-08, -0.958278894, -5.37682299e-09, 0.285834819))
                
                lastSellTime = os.time()
                task.wait(2) 
            end

            tracking = true
        elseif not ATM then
            finding = true
        end
    end
end

-- [[ Auto ATM Rob UI ]] --

Tabs.ATM:AddToggle("AtmToggle", {
    Title = "Start ATM Rob",
    Description = "Teleports to hideout every 3 Minutes.",
    Default = false,
    Callback = function(Value)
        deb = Value
        if not Value then
            CameraReset()
        end
    end
})

for _, v in workspace:GetDescendants() do
    if v.Name == "071_GARDEN_CENTER" and v:IsA("Model") then
        v:Destroy()
    end
end

task.spawn(function()
    while task.wait() do
        if deb then
            if tracking then
                RobATM()
            end
            if finding and not tracking then
                LoadAtm()
            end
        end
    end
end)

Tabs.ATM:AddButton({
    Title = "Manual Sell / Clear Wanted",
    Description = "Teleports to hideout instantly",
    Callback = function()
        
        char:PivotTo(CFrame.new(-2541.09961, 14.8917437, 4030.8147, 0.285834819, -1.93582732e-08, 0.958278894, 3.80772247e-10, 1, 2.00875085e-08, -0.958278894, -5.37682299e-09, 0.285834819))
        
     
        lastSellTime = os.time()
        
        Fluent:Notify({
            Title = "NWR Hub",
            Content = "Teleported to Hideout",
            Duration = 3
        })
    end
})

-- [[ Anti AFK ]] --
local VirtualUser = game:GetService("VirtualUser")
local antiAfkEnabled = false

game:GetService("Players").LocalPlayer.Idled:Connect(function()
    if antiAfkEnabled then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

Tabs.Settings:AddToggle("AntiAFK", {
    Title = "Anti-AFK",
    Description = "Prevents you from being kicked for idling.",
    Default = false,
    Callback = function(Value)
        antiAfkEnabled = Value
        if Value then
            Fluent:Notify({
                Title = "NWR Hub",
                Content = "Anti-AFK is now ACTIVE",
                Duration = 3
            })
        end
    end
})

-- [[ Server Hop ]] --
local function serverHop()
    local Http = game:GetService("HttpService")
    local TPS = game:GetService("TeleportService")
    local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    
    local function ListServers(cursor)
        local Raw = game:HttpGet(Api .. (cursor and "&cursor=" .. cursor or ""))
        return Http:JSONDecode(Raw)
    end

    local Server = ListServers()
    local BestServer = Server.data[1]

    
    for _, v in pairs(Server.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            BestServer = v
            break
        end
    end

    if BestServer then
        TPS:TeleportToPlaceInstance(game.PlaceId, BestServer.id, game.Players.LocalPlayer)
    else
        Fluent:Notify({Title = "NWR Hub", Content = "No other servers found.", Duration = 3})
    end
end

Tabs.Settings:AddButton({
    Title = "Server Hop",
    Description = "Hops to the smallest available server.",
    Callback = function()
        Window:Dialog({
            Title = "Server Hop",
            Content = "Are you sure you want to hop to a new server?",
            Buttons = {
                {
                    Title = "Confirm",
                    Callback = function()
                        serverHop()
                    end
                },
                {
                    Title = "Cancel"
                }
            }
        })
    end
})

Window:SelectTab(1)
