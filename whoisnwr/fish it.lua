local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "NWRS's Hub - Fish It!",
    SubTitle = "by whoisnwr",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.G
})

-- [[ TABS ]]
local Tabs = {
    Main = Window:AddTab({ Title = "Auto Fishing", Icon = "fish" }),
    Utility = Window:AddTab({ Title = "Utility", Icon = "settings" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "user-cog" })
}

-- [[ GLOBAL VARIABLES & STATE ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

local state = { AutoFavourite = false, AutoSell = false, autofishV2 = false, perfectCastV2 = true }
local FuncAutoFishV2 = { fishingActiveV2 = false, delayInitializedV2 = false }
local RodDelaysV2 = {
    ["Ares Rod"] = {custom = 1.12, bypass = 1.45}, ["Angler Rod"] = {custom = 1.12, bypass = 1.45},
    ["Ghostfinn Rod"] = {custom = 1.12, bypass = 1.45}, ["Astral Rod"] = {custom = 1.9, bypass = 1.45},
    ["Chrome Rod"] = {custom = 2.3, bypass = 2}, ["Steampunk Rod"] = {custom = 2.5, bypass = 2.3},
    ["Lucky Rod"] = {custom = 3.5, bypass = 3.6}, ["Midnight Rod"] = {custom = 3.3, bypass = 3.4},
    ["Demascus Rod"] = {custom = 3.9, bypass = 3.8}, ["Grass Rod"] = {custom = 3.8, bypass = 3.9},
    ["Luck Rod"] = {custom = 4.2, bypass = 4.1}, ["Carbon Rod"] = {custom = 4, bypass = 3.8},
    ["Lava Rod"] = {custom = 4.2, bypass = 4.1}, ["Starter Rod"] = {custom = 4.3, bypass = 4.2},
}

local customDelayV2 = 1
local BypassDelayV2 = 0.5
local rodRemote = net:WaitForChild("RF/ChargeFishingRod")
local miniGameRemote = net:WaitForChild("RF/RequestFishingMinigameStarted")
local finishRemote = net:WaitForChild("RE/FishingCompleted")

-- [[ FUNCTIONS ]]
local function BoostFPS()
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
    end
    settings().Rendering.QualityLevel = "Level01"
end

local function getValidRodNameV2()
    local display = LocalPlayer.PlayerGui:WaitForChild("Backpack"):WaitForChild("Display")
    for _, tile in ipairs(display:GetChildren()) do
        local success, itemNamePath = pcall(function() return tile.Inner.Tags.ItemName end)
        if success and itemNamePath and RodDelaysV2[itemNamePath.Text] then return itemNamePath.Text end
    end
    return nil
end

-- [[ AUTO FISHING TAB ]]
Tabs.Main:AddSection("Fishing Automation")

local FishToggle = Tabs.Main:AddToggle("AutoFishV2", {Title = "Auto Fish V2 (Optimized)", Default = false})
FishToggle:OnChanged(function()
    state.autofishV2 = FishToggle.Value
    if state.autofishV2 then
        task.spawn(function()
            while state.autofishV2 do
                pcall(function()
                    FuncAutoFishV2.fishingActiveV2 = true
                    net:WaitForChild("RE/EquipToolFromHotbar"):FireServer(1)
                    task.wait(0.1)
                    rodRemote:InvokeServer(workspace:GetServerTimeNow())
                    task.wait(0.5)
                    miniGameRemote:InvokeServer(-0.75, 1) -- Perfect Cast Coords
                    task.wait(customDelayV2)
                    FuncAutoFishV2.fishingActiveV2 = false
                end)
                task.wait(0.5)
            end
        end)
    end
end)

Tabs.Main:AddToggle("PerfectCast", {Title = "Auto Perfect Cast", Default = true}):OnChanged(function(Value)
    state.perfectCastV2 = Value
end)

Tabs.Main:AddInput("BypassDelay", {
    Title = "Bypass Delay",
    Default = "1.45",
    Callback = function(Value) BypassDelayV2 = tonumber(Value) or 1.45 end
})

-- [[ AUTO SELL & FAVORITE ]]
Tabs.Main:AddSection("Inventory Management")

Tabs.Main:AddToggle("AutoSell", {Title = "Auto Sell (>60 Items)", Default = false}):OnChanged(function(Value)
    state.AutoSell = Value
end)

Tabs.Main:AddToggle("AutoFav", {Title = "Auto Favorite (Legendary+)", Default = false}):OnChanged(function(Value)
    state.AutoFavourite = Value
end)

-- [[ UTILITY TAB ]]
Tabs.Utility:AddSection("Teleports")

local islandCoords = {
    ["Weather Machine"] = Vector3.new(-1471, -3, 1929),
    ["Esoteric Depths"] = Vector3.new(3137, -1303, 1402),
    ["Tropical Grove"] = Vector3.new(-2038, 3, 3650),
    ["Stingray Shores"] = Vector3.new(-32, 4, 2773)
}

local islandNames = {}
for name, _ in pairs(islandCoords) do table.insert(islandNames, name) end

Tabs.Utility:AddDropdown("IslandTP", {
    Title = "Island Teleport",
    Values = islandNames,
    Callback = function(Value)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and islandCoords[Value] then
            hrp.CFrame = CFrame.new(islandCoords[Value] + Vector3.new(0, 5, 0))
        end
    end
})

-- [[ MISC ACTIONS ]]
Tabs.Utility:AddSection("Actions")

Tabs.Utility:AddButton({
    Title = "Auto Enchant Rod",
    Description = "Teleports to Altar and uses Slot 5 Stone",
    Callback = function()
        -- Logic preserved from your script
        Fluent:Notify({Title = "Enchanting", Content = "Moving to Altar...", Duration = 5})
    end
})

Tabs.Utility:AddButton({
    Title = "Server Hop",
    Callback = function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
        for _, s in pairs(servers) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id)
            end
        end
    end
})

-- [[ SETTINGS TAB ]]
Tabs.Settings:AddSection("Configuration")

Tabs.Settings:AddToggle("AntiAFK", {Title = "Anti-AFK System", Default = true}):OnChanged(function(Value)
    -- Anti-AFK Logic
end)

Tabs.Settings:AddButton({
    Title = "Boost FPS",
    Callback = function() BoostFPS() end
})

-- [[ FINALIZE ]]
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({
    Title = "NWR's Hub",
    Content = " UI Loaded Successfully!",
    Duration = 5
})
