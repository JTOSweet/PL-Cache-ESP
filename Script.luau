local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui") 

local player = Players.LocalPlayer
local espEnabled = false
local activeESPs = {} 
local connections = {} 

local rarityFilters = {
    Common = true,
    Uncommon = true,
    Rare = true,
    Epic = true,
    Legendary = true,
    Undefined = true,
    Ultimate = true
} 

local function getRarity(color3)
    local r = math.round(color3.R * 255)
    local g = math.round(color3.G * 255)
    local b = math.round(color3.B * 255) 

    if r == 228 and g == 100 and b == 255 then
        return "Rare", "Rare", color3
    elseif r == 100 and g == 255 and b == 100 then
        return "Uncommon", "Uncommon", color3
    elseif r == 255 and g == 255 and b == 255 then
        return "Common", "Common", color3
    elseif r == 100 and g == 255 and b == 255 then
        return "Epic", "Epic", color3
    elseif r == 255 and g == 255 and b == 100 then
        return "Legendary", "Legendary", color3
    elseif r == 255 and g == 100 and b == 100 then
        return "Ultimate", "Ultimate", color3
    else
        return string.format("Undefined (%d, %d, %d)", r, g, b), "Undefined", color3
    end
end 

local function addESP(instance)
    if not (instance:IsA("BasePart")) then return end
    
    --silly thing to skip mag attach balls
    if instance.Name == "BALL" then return end

    local isCache = instance.Name:lower():find("cache") or (instance:IsA("Part") and instance.Shape == Enum.PartType.Ball)
    if not isCache or activeESPs[instance] then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CacheESP_" .. instance.Name
    billboard.Adornee = instance
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = math.huge
    billboard.Enabled = true

    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = billboard
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0 
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Text = "[ Loading... ]" 

    local success = pcall(function()
        billboard.Parent = CoreGui
    end)
    if not success then
        billboard.Parent = player:WaitForChild("PlayerGui")
    end 

    activeESPs[instance] = {
        billboard = billboard, 
        textLabel = textLabel,
        lastColor = nil
    }
end 

local function removeESP(instance)
    if activeESPs[instance] then
        if activeESPs[instance].billboard then
            activeESPs[instance].billboard:Destroy()
        end
        activeESPs[instance] = nil
    end
end 

local function clearAllESP()
    for instance, espData in pairs(activeESPs) do
        if espData.billboard then espData.billboard:Destroy() end
    end
    table.clear(activeESPs)
end 

local Window = Rayfield:CreateWindow({
    Name = "PL JTO Cache ESP Hub 1.1v",
    LoadingTitle = "Let's Larp",
    LoadingSubtitle = "Just This Once...",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false
}) 

local MainTab = Window:CreateTab("Main ESP", 79963251474338)
local FilterTab = Window:CreateTab("Filters", 79963251474338) 

MainTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "CacheESPToggle",
    Callback = function(state)
        espEnabled = state
        
        if state then
            for _, instance in pairs(workspace:GetDescendants()) do
                addESP(instance)
            end 

            connections.added = workspace.DescendantAdded:Connect(addESP)
            connections.removed = workspace.DescendantRemoving:Connect(removeESP) 

            connections.updater = RunService.RenderStepped:Connect(function()
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end 

                for cache, espData in pairs(activeESPs) do
                    if cache and cache.Parent then
                        local rName, rCat, rCol = getRarity(cache.Color)
                        
                        if espData.lastColor ~= cache.Color then
                            espData.textLabel.TextColor3 = rCol
                            espData.billboard.Enabled = rarityFilters[rCat]
                            espData.lastColor = cache.Color
                            espData.currentRarityName = rName
                            espData.currentCategory = rCat
                        end

                        if espData.billboard.Enabled then
                            local distance = math.floor((root.Position - cache.Position).Magnitude)
                            espData.textLabel.Text = string.format("%s\n[ %d studs ]", espData.currentRarityName, distance)
                        end
                    else
                        removeESP(cache)
                    end
                end
            end)

            Rayfield:Notify({Title = "ESP Enabled", Content = "Getting Caches", Duration = 2})
        else
            if connections.added then connections.added:Disconnect() end
            if connections.removed then connections.removed:Disconnect() end
            if connections.updater then connections.updater:Disconnect() end
            clearAllESP() 
        end
    end,
}) 

local categories = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Ultimate", "Undefined"} 

for _, category in ipairs(categories) do
    FilterTab:CreateToggle({
        Name = "Show " .. category,
        CurrentValue = true,
        Flag = category .. "FilterToggle",
        Callback = function(state)
            rarityFilters[category] = state
        end,
    })
end 

Rayfield:LoadConfiguration()
