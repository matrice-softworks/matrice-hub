--// Matrice – SCP: Roleplay
local UI = Matrice.UI
local Visuals = Matrice.Visuals
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ===== Configuration =====
local Config = {
    -- ESP
    ESPEnabled = false,
    HighlightEnabled = false,
    BoxEnabled = false,
    SkeletonEnabled = false,
    ChamsEnabled = false,
    TracerEnabled = false,
    HealthBarEnabled = false,
    ESPRange = 600,
    -- Silent Aim
    SilentAimEnabled = false,
    SilentAimWallCheck = true,
    SilentAimHitPart = "Head",
    SilentAimHitChance = 100,
    FOVCircleEnabled = false,
    FOVRadius = 150,
    FOVColor = Color3.fromRGB(255, 255, 255),
    -- Moderator
    ModeratorDetector = false,
    -- UI
    UIToggleKey = "RightControl",
}

local CONFIG_FILE = "SCP-RP-Config.json"
local SilentAimWarningShown = false

-- Use Matrice global helpers
local function SaveConfig()
    local ok, err = Matrice.SaveConfiguration(Config, CONFIG_FILE)
    if not ok then
        warn("Failed to save config:", err)
    end
end

local function LoadConfig()
    local data, err = Matrice.LoadConfiguration(CONFIG_FILE)
    if data then
        for k, v in pairs(data) do
            Config[k] = v
        end
        return true
    else
        if err and err ~= "Config file not found" then
            warn("Failed to load config:", err)
        end
        return false
    end
end

local function ResetConfig()
    Config = {
        ESPEnabled = false,
        HighlightEnabled = false,
        BoxEnabled = false,
        SkeletonEnabled = false,
        ChamsEnabled = false,
        TracerEnabled = false,
        HealthBarEnabled = false,
        ESPRange = 600,
        SilentAimEnabled = false,
        SilentAimWallCheck = true,
        SilentAimHitPart = "Head",
        SilentAimHitChance = 100,
        FOVCircleEnabled = false,
        FOVRadius = 150,
        FOVColor = Color3.fromRGB(255, 255, 255),
        ModeratorDetector = false,
        UIToggleKey = "RightControl",
    }
    local ok, err = Matrice.ResetConfiguration(CONFIG_FILE)
    if not ok then
        warn("Failed to reset config:", err)
    end
    SaveConfig()
    UI:Notify("Warning", {
        Title = "Config Reset",
        Content = "Settings reset to defaults. Please reload the script.",
        Duration = 5,
        Image = "rbxassetid://4483362458",
    })
end

-- Apply config to globals
getgenv().ESPEnabled = Config.ESPEnabled
getgenv().HighlightEnabled = Config.HighlightEnabled
getgenv().BoxEnabled = Config.BoxEnabled
getgenv().SkeletonEnabled = Config.SkeletonEnabled
getgenv().ChamsEnabled = Config.ChamsEnabled
getgenv().TracerEnabled = Config.TracerEnabled
getgenv().HealthBarEnabled = Config.HealthBarEnabled
getgenv().ESPRange = Config.ESPRange
getgenv().SilentAimEnabled = Config.SilentAimEnabled
getgenv().SilentAimWallCheck = Config.SilentAimWallCheck
getgenv().SilentAimHitPart = Config.SilentAimHitPart
getgenv().SilentAimHitChance = Config.SilentAimHitChance
getgenv().FOVCircleEnabled = Config.FOVCircleEnabled
getgenv().FOVRadius = Config.FOVRadius
getgenv().FOVColor = Config.FOVColor
getgenv().ModeratorDetector = Config.ModeratorDetector

LoadConfig()

-- ===== UI Library =====
local Library = UI:CreateLibrary({
    Name = "Matrice v" .. Matrice.Version .. " - " .. Matrice.Game.Info.Name,
    Icon = "rbxassetid://12974454446"
})

-- ===== Tabs =====
local HomeTab = Library:CreateTab("Home", "rbxassetid://12974454446")
local CombatTab = Library:CreateTab("Combat", "rbxassetid://12974454446")
local VisualsTab = Library:CreateTab("Visuals", "rbxassetid://12974454446")
local MiscTab = Library:CreateTab("Miscellaneous", "rbxassetid://12974454446")
local SettingsTab = Library:CreateTab("Settings", "rbxassetid://12974454446")

-- ===== Home Tab =====
local HomeSection = HomeTab:CreateSection("Welcome", "Normal")

HomeSection:CreateCard({
    Title = "Matrice Hub",
    Description = "Matrice is a premium Roblox script hub delivering optimized, undetected, and high-quality scripts.",
    SecondaryTitle = "Version v" .. Matrice.Version,
    Image = Matrice.Asset("Matrice"),
    Buttons = {
        Button1  = {
            Name = "Join Discord",
            Callback = function()
                setclipboard("https://discord.gg/tester")
                UI:Notify("Normal", {
                    Title = "Copied",
                    Content = "Discord invite copied to clipboard.",
                    Duration = 3,
                    Image = "rbxassetid://4483362458",
                })
            end
        },
        Button2 = {
            Name = "Visit GitHub",
            Callback = function()
                setclipboard("https://github.com/matrice-softworks/matrice-hub")
                UI:Notify("Normal", {
                    Title = "Copied",
                    Content = "GitHub link copied to clipboard.",
                    Duration = 3,
                    Image = "rbxassetid://4483362458",
                })
            end
        }
    }
})

HomeSection:CreateDivider()

local InfoSection = HomeTab:CreateSection("Script Information", "Foldable")
InfoSection:CreateParagraph({
    Title = "About",
    Description = "This script provides ESP, Silent Aim, and Moderator Detection for SCP: Roleplay.\n\n<b>Features:</b>\n• Full ESP system with multiple visual options\n• Silent Aim with adjustable FOV\n• Moderator/Staff detection\n• Configuration save/load/reset\n• Customizable keybinds"
})

-- ===== Combat Tab =====
local SilentAimSection = CombatTab:CreateSection("Silent Aim", "Normal")

-- Internal silent aim state
local SilentAimHookInstalled = false
local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Visible = false
local SilentAimRaycastParams = RaycastParams.new()
SilentAimRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
SilentAimRaycastParams.IgnoreWater = true

local HostileTeams = {
    ["Administrative Department"] = 1,
    ["Chaos Insurgency"] = 0,
    ["Class - D"] = 0,
    ["Intelligence Agency"] = 1,
    ["Internal Security Department"] = 1,
    ["Medical Department"] = 1,
    ["Mobile Task Force"] = 1,
    ["Rapid Response Team"] = 1,
    ["Scientific Department"] = 1,
    ["Security Department"] = 1,
}

local function IsEnemy(player)
    local localTeam = LocalPlayer.Team and HostileTeams[LocalPlayer.Team.Name]
    local targetTeam = player.Team and HostileTeams[player.Team.Name]
    return localTeam == nil or targetTeam == nil or localTeam ~= targetTeam
end

local function GetSilentAimTarget()
    if not getgenv().SilentAimEnabled then return nil end
    local camera = workspace.CurrentCamera
    local cursor = UserInputService:GetMouseLocation()
    local closestPart, closestDistance = nil, getgenv().FOVRadius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsEnemy(player) then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local hitPartName = getgenv().SilentAimHitPart
            if hitPartName == "Randomized" then
                local hitParts = {"Head", "UpperTorso", "HumanoidRootPart"}
                hitPartName = hitParts[math.random(1, #hitParts)]
            end
            local targetPart = character and (character:FindFirstChild(hitPartName) or character:FindFirstChild("HumanoidRootPart"))

            if humanoid and humanoid.Health > 0 and targetPart then
                local screenPosition, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                local visible = true
                if getgenv().SilentAimWallCheck then
                    local localCharacter = LocalPlayer.Character
                    if localCharacter then
                        SilentAimRaycastParams.FilterDescendantsInstances = {localCharacter}
                        local result = workspace:Raycast(camera.CFrame.Position, targetPart.Position - camera.CFrame.Position, SilentAimRaycastParams)
                        visible = not result or result.Instance:IsDescendantOf(character)
                    end
                end
                if onScreen and visible then
                    local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - cursor).Magnitude
                    if distance < closestDistance then
                        closestPart = targetPart
                        closestDistance = distance
                    end
                end
            end
        end
    end
    return closestPart
end

local function FindBulletFunction()
    local controller = LocalPlayer.PlayerScripts:FindFirstChild("Controller")
    if not controller then return nil end
    local function MatchesController(candidate)
        if not debug or not debug.getinfo then return false end
        local success, info = pcall(debug.getinfo, candidate)
        return success and info and info.source == "=" .. controller:GetFullName()
    end
    if filtergc then
        local result = filtergc("function", {
            Constants = {"Bullet", "EasterEggThing", "SCP-066"},
            IgnoreExecutor = true,
        })
        if type(result) == "function" and MatchesController(result) then return result end
        if type(result) == "table" then
            for _, candidate in ipairs(result) do
                if type(candidate) == "function" and MatchesController(candidate) then return candidate end
            end
        end
    end
    if getgc and debug and debug.getconstants then
        for _, candidate in ipairs(getgc()) do
            if type(candidate) == "function" then
                local success, constants = pcall(debug.getconstants, candidate)
                if success and constants and MatchesController(candidate) and table.find(constants, "Bullet") and table.find(constants, "EasterEggThing") and table.find(constants, "SCP-066") then
                    return candidate
                end
            end
        end
    end
end

local function InstallSilentAimHook()
    if SilentAimHookInstalled then return true end
    local bulletFunction = FindBulletFunction()
    if not bulletFunction then
        warn("Silent Aim: Could not find bullet function.")
        return false
    end
    local original
    original = hookfunction(bulletFunction, function(_, hitResult, ...)
        local target = GetSilentAimTarget()
        if target and math.random(1, 100) <= getgenv().SilentAimHitChance then
            return original(_, {
                Instance = target,
                Position = target.Position,
                Normal = Vector3.new(0, 1, 0),
                Material = target.Material,
            }, ...)
        end
        return original(_, hitResult, ...)
    end)
    SilentAimHookInstalled = true
    return true
end

-- Function to show Silent Aim warning
local function ShowSilentAimWarning(Callback)
    Library:Notify({
        Title = "Warning",
        Content = "While Matrice bypasses anti-cheat detections, using certain features such as Silent Aim in public servers increases your risk of being reported by players and manually banned by game moderators. We are not responsible if your account gets banned.\n\nYou must wait 67 seconds before enabling this feature.",
        Duration = 67,
        Image = "rbxassetid://4483362458",
        Actions = {
            Understand = {
                Name = "I Understand",
                Callback = function()
                    SilentAimWarningShown = true
                    if Callback then Callback(true) end
                end
            },
            Cancel = {
                Name = "Cancel",
                Callback = function()
                    SilentAimWarningShown = false
                    if Callback then Callback(false) end
                end
            }
        }
    })
end

-- Silent Aim UI
SilentAimSection:CreateToggle("Normal", {
    Name = "Enable Silent Aim",
    Flag = "SilentAimEnabled",
    CurrentValue = getgenv().SilentAimEnabled,
    Callback = function(Value)
        if Value and not SilentAimWarningShown then
            -- Show warning, temporarily disable the toggle
            getgenv().SilentAimEnabled = false
            Config.SilentAimEnabled = false
            
            ShowSilentAimWarning(function(Confirmed)
                if Confirmed then
                    getgenv().SilentAimEnabled = true
                    Config.SilentAimEnabled = true
                    if not InstallSilentAimHook() then
                        getgenv().SilentAimEnabled = false
                        Config.SilentAimEnabled = false
                    end
                    SaveConfig()
                else
                    getgenv().SilentAimEnabled = false
                    Config.SilentAimEnabled = false
                    SaveConfig()
                end
                -- Update the toggle UI to reflect the actual state
                -- The toggle will need to be updated via its internal state
            end)
            return
        end
        
        getgenv().SilentAimEnabled = Value
        Config.SilentAimEnabled = Value
        if Value and not InstallSilentAimHook() then
            getgenv().SilentAimEnabled = false
            Config.SilentAimEnabled = false
        end
        SaveConfig()
    end,
})

SilentAimSection:CreateToggle("Normal", {
    Name = "Wall Check",
    Flag = "SilentAimWallCheck",
    CurrentValue = getgenv().SilentAimWallCheck,
    Callback = function(Value)
        getgenv().SilentAimWallCheck = Value
        Config.SilentAimWallCheck = Value
        SaveConfig()
    end,
})

SilentAimSection:CreateToggle("Normal", {
    Name = "Show FOV Circle",
    Flag = "FOVCircleEnabled",
    CurrentValue = getgenv().FOVCircleEnabled,
    Callback = function(Value)
        getgenv().FOVCircleEnabled = Value
        Config.FOVCircleEnabled = Value
        if not Value then FOVCircle.Visible = false end
        SaveConfig()
    end,
})

SilentAimSection:CreateSlider({
    Name = "FOV Radius",
    Value = {25, 500},
    Increment = 5,
    Suffix = "px",
    Flag = "FOVRadius",
    CurrentValue = getgenv().FOVRadius,
    Callback = function(Value)
        getgenv().FOVRadius = Value
        Config.FOVRadius = Value
        SaveConfig()
    end,
})

SilentAimSection:CreateColorPicker({
    Name = "FOV Color",
    Callback = function(Color)
        getgenv().FOVColor = Color
        Config.FOVColor = Color
        SaveConfig()
    end,
})

SilentAimSection:CreateDropdown({
    Name = "Hit Part",
    Options = {"Head", "UpperTorso", "HumanoidRootPart", "Randomized"},
    Flag = "SilentAimHitPart",
    CurrentOption = {getgenv().SilentAimHitPart},
    MultipleOptions = false,
    Callback = function(Option)
        local val = typeof(Option) == "table" and Option[1] or Option
        getgenv().SilentAimHitPart = val
        Config.SilentAimHitPart = val
        SaveConfig()
    end,
})

SilentAimSection:CreateSlider({
    Name = "Hit Chance",
    Value = {0, 100},
    Increment = 1,
    Suffix = "%",
    Flag = "SilentAimHitChance",
    CurrentValue = getgenv().SilentAimHitChance,
    Callback = function(Value)
        getgenv().SilentAimHitChance = Value
        Config.SilentAimHitChance = Value
        SaveConfig()
    end,
})

SilentAimSection:CreateLabel({
    Description = "FOV settings control target selection area."
})

-- ===== Visuals Tab =====
local ESPSection = VisualsTab:CreateSection("ESP Settings", "Normal")
local MiscVizSection = VisualsTab:CreateSection("Miscellaneous Visuals", "Normal")

-- ESP state
local PlayerESPs = {}
local Connections = {}

local function ClearPlayerESP(player)
    if PlayerESPs[player] then
        if PlayerESPs[player].Skeleton then PlayerESPs[player].Skeleton:Remove() end
        if PlayerESPs[player].Box then PlayerESPs[player].Box:Remove() end
        if PlayerESPs[player].Tracer then PlayerESPs[player].Tracer:Remove() end
        if PlayerESPs[player].HealthBarOutline then PlayerESPs[player].HealthBarOutline:Remove() end
        if PlayerESPs[player].HealthBarFill then PlayerESPs[player].HealthBarFill:Remove() end
        if PlayerESPs[player].HealthBarTicks then
            for _, tick in ipairs(PlayerESPs[player].HealthBarTicks) do tick:Remove() end
        end
        if PlayerESPs[player].Highlight then PlayerESPs[player].Highlight:Remove() end
        if PlayerESPs[player].Chams then
            for part, originalMaterial in pairs(PlayerESPs[player].Chams) do
                if part and part.Parent then
                    part.Material = originalMaterial
                end
            end
        end
        PlayerESPs[player] = nil
    end
    if Connections[player.Name .. "_TeamColor"] then
        Connections[player.Name .. "_TeamColor"]:Disconnect()
        Connections[player.Name .. "_TeamColor"] = nil
    end
end

local function ClearESPs()
    for player, _ in pairs(PlayerESPs) do
        ClearPlayerESP(player)
    end
end

local function CreatePlayerESP(player)
    if player == LocalPlayer or not player.Character then return end
    local teamColor = player.TeamColor and player.TeamColor.Color or Color3.new(1, 1, 1)

    local box = nil
    if getgenv().BoxEnabled then
        box = Drawing.new("Square")
        box.Thickness = 1
        box.Color = teamColor
        box.Filled = false
        box.Transparency = 1
        box.Visible = false
    end

    local highlight = nil
    if getgenv().HighlightEnabled then
        highlight = Visuals:CreateVisual("Highlight", {
            Target = player.Character,
            Color = teamColor,
            Transparency = 0.5,
            StrokeColor = Color3.new(1, 1, 1),
            OutlineTransparency = 0,
        })
    end

    local skeleton = nil
    if getgenv().SkeletonEnabled then
        skeleton = Visuals:CreateVisual("Drawing", {
            Type = "Skeleton",
            Player = player,
            Color = teamColor,
            Thickness = 1
        })
    end

    local tracer = nil
    if getgenv().TracerEnabled then
        tracer = Drawing.new("Line")
        tracer.Thickness = 1
        tracer.Color = teamColor
        tracer.Transparency = 1
        tracer.Visible = false
    end

    local healthBarOutline, healthBarFill, healthBarTicks = nil, nil, nil
    if getgenv().HealthBarEnabled then
        healthBarOutline = Drawing.new("Square")
        healthBarOutline.Color = Color3.fromRGB(18, 20, 28)
        healthBarOutline.Filled = true
        healthBarOutline.Transparency = 1
        healthBarOutline.Visible = false

        healthBarFill = Drawing.new("Square")
        healthBarFill.Filled = true
        healthBarFill.Transparency = 1
        healthBarFill.Visible = false

        healthBarTicks = {}
        for _ = 1, 4 do
            local tick = Drawing.new("Line")
            tick.Color = Color3.fromRGB(90, 96, 112)
            tick.Thickness = 1
            tick.Transparency = 0.9
            tick.Visible = false
            table.insert(healthBarTicks, tick)
        end
    end

    local chams = nil
    if getgenv().ChamsEnabled and player.Character then
        chams = {}
        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                chams[v] = v.Material
                v.Material = Enum.Material.ForceField
            end
        end
    end

    PlayerESPs[player] = {
        Skeleton = skeleton,
        Box = box,
        Tracer = tracer,
        HealthBarOutline = healthBarOutline,
        HealthBarFill = healthBarFill,
        HealthBarTicks = healthBarTicks,
        Highlight = highlight,
        Chams = chams,
        Character = player.Character
    }

    Connections[player.Name .. "_TeamColor"] = player:GetPropertyChangedSignal("TeamColor"):Connect(function()
        if PlayerESPs[player] then
            local newColor = player.TeamColor and player.TeamColor.Color or Color3.new(1, 1, 1)
            if PlayerESPs[player].Box then PlayerESPs[player].Box.Color = newColor end
            if PlayerESPs[player].Tracer then PlayerESPs[player].Tracer.Color = newColor end
            if PlayerESPs[player].Highlight and PlayerESPs[player].Highlight.Object then
                PlayerESPs[player].Highlight.Object.FillColor = newColor
            end
            if PlayerESPs[player].Skeleton and PlayerESPs[player].Skeleton.Object then
                PlayerESPs[player].Skeleton.Object.SetColor(newColor)
            end
        end
    end)
end

local function RebuildAllESPs()
    if not getgenv().ESPEnabled then return end
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ClearPlayerESP(player)
            local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and player.Parent == Players then
                local distance = (localRoot.Position - targetRoot.Position).Magnitude
                if distance <= getgenv().ESPRange then
                    CreatePlayerESP(player)
                end
            end
        end
    end
end

-- Background ESP loop
task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().ESPEnabled then
            ClearESPs()
            continue
        end

        local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot then continue end

        for p, _ in pairs(PlayerESPs) do
            if not p or p.Parent ~= Players then
                ClearPlayerESP(p)
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and player.Parent == Players then
                    local distance = (localRoot.Position - targetRoot.Position).Magnitude
                    if distance <= getgenv().ESPRange then
                        if not PlayerESPs[player] or PlayerESPs[player].Character ~= player.Character then
                            if PlayerESPs[player] then ClearPlayerESP(player) end
                            CreatePlayerESP(player)
                        end
                    else
                        ClearPlayerESP(player)
                    end
                else
                    ClearPlayerESP(player)
                end
            end
        end
    end
end)

-- Render loop for drawing positions
RunService.RenderStepped:Connect(function()
    -- FOV circle
    FOVCircle.Visible = getgenv().FOVCircleEnabled
    if getgenv().FOVCircleEnabled then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = getgenv().FOVRadius
        FOVCircle.Color = getgenv().FOVColor
    end

    if not getgenv().ESPEnabled then return end
    for player, esp in pairs(PlayerESPs) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local onScreen, size, pos = Visuals:GetBoundingBox(player)
            local box = esp.Box
            local tracer = esp.Tracer
            local healthBarOutline = esp.HealthBarOutline
            local healthBarFill = esp.HealthBarFill
            local healthBarTicks = esp.HealthBarTicks

            if onScreen then
                local teamColor = player.TeamColor and player.TeamColor.Color or Color3.new(1, 1, 1)

                if box then
                    box.Size = size
                    box.Position = pos
                    box.Color = teamColor
                    box.Visible = getgenv().BoxEnabled
                end
                if tracer then
                    local viewport = workspace.CurrentCamera.ViewportSize
                    tracer.From = Vector2.new(viewport.X / 2, viewport.Y)
                    tracer.To = Vector2.new(pos.X + (size.X / 2), pos.Y + size.Y)
                    tracer.Color = teamColor
                    tracer.Visible = getgenv().TracerEnabled
                end
                if healthBarOutline and healthBarFill then
                    local humanoid = player.Character.Humanoid
                    local healthPercent = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
                    local barHeight = size.Y
                    local barX = pos.X - 8
                    local barY = pos.Y

                    healthBarOutline.Position = Vector2.new(barX - 1, barY - 2)
                    healthBarOutline.Size = Vector2.new(5, barHeight + 4)
                    healthBarOutline.Visible = getgenv().HealthBarEnabled

                    healthBarFill.Position = Vector2.new(barX, barY + barHeight * (1 - healthPercent))
                    healthBarFill.Size = Vector2.new(3, math.max(barHeight * healthPercent, 1))
                    healthBarFill.Color = Color3.fromHSV(healthPercent * 0.33, 0.9, 1)
                    healthBarFill.Visible = getgenv().HealthBarEnabled

                    if healthBarTicks then
                        for index, tick in ipairs(healthBarTicks) do
                            local y = barY + (barHeight * index / 5)
                            tick.From = Vector2.new(barX - 1, y)
                            tick.To = Vector2.new(barX + 4, y)
                            tick.Visible = getgenv().HealthBarEnabled
                        end
                    end
                end
            else
                if box then box.Visible = false end
                if tracer then tracer.Visible = false end
                if healthBarOutline then healthBarOutline.Visible = false end
                if healthBarFill then healthBarFill.Visible = false end
                if healthBarTicks then for _, tick in ipairs(healthBarTicks) do tick.Visible = false end end
            end
        else
            if esp.Box then esp.Box.Visible = false end
            if esp.Tracer then esp.Tracer.Visible = false end
            if esp.HealthBarOutline then esp.HealthBarOutline.Visible = false end
            if esp.HealthBarFill then esp.HealthBarFill.Visible = false end
            if esp.HealthBarTicks then for _, tick in ipairs(esp.HealthBarTicks) do tick.Visible = false end end
        end
    end
end)

Players.PlayerRemoving:Connect(ClearPlayerESP)

-- ESP UI Elements
ESPSection:CreateToggle("Normal", {
    Name = "Enable ESP",
    Flag = "ESPEnabled",
    CurrentValue = getgenv().ESPEnabled,
    Callback = function(Value)
        getgenv().ESPEnabled = Value
        Config.ESPEnabled = Value
        if not Value then ClearESPs() end
        SaveConfig()
    end,
})

ESPSection:CreateDivider()

ESPSection:CreateToggle("Normal", {
    Name = "Highlight",
    Flag = "HighlightEnabled",
    CurrentValue = getgenv().HighlightEnabled,
    Callback = function(Value)
        getgenv().HighlightEnabled = Value
        Config.HighlightEnabled = Value
        RebuildAllESPs()
        SaveConfig()
    end,
})

ESPSection:CreateToggle("Normal", {
    Name = "Box",
    Flag = "BoxEnabled",
    CurrentValue = getgenv().BoxEnabled,
    Callback = function(Value)
        getgenv().BoxEnabled = Value
        Config.BoxEnabled = Value
        RebuildAllESPs()
        SaveConfig()
    end,
})

ESPSection:CreateToggle("Normal", {
    Name = "Tracer Lines",
    Flag = "TracerEnabled",
    CurrentValue = getgenv().TracerEnabled,
    Callback = function(Value)
        getgenv().TracerEnabled = Value
        Config.TracerEnabled = Value
        RebuildAllESPs()
        SaveConfig()
    end,
})

ESPSection:CreateToggle("Normal", {
    Name = "Health Bars",
    Flag = "HealthBarEnabled",
    CurrentValue = getgenv().HealthBarEnabled,
    Callback = function(Value)
        getgenv().HealthBarEnabled = Value
        Config.HealthBarEnabled = Value
        RebuildAllESPs()
        SaveConfig()
    end,
})

ESPSection:CreateToggle("Normal", {
    Name = "Skeleton",
    Flag = "SkeletonEnabled",
    CurrentValue = getgenv().SkeletonEnabled,
    Callback = function(Value)
        getgenv().SkeletonEnabled = Value
        Config.SkeletonEnabled = Value
        RebuildAllESPs()
        SaveConfig()
    end,
})

ESPSection:CreateToggle("Normal", {
    Name = "Chams",
    Flag = "ChamsEnabled",
    CurrentValue = getgenv().ChamsEnabled,
    Callback = function(Value)
        getgenv().ChamsEnabled = Value
        Config.ChamsEnabled = Value
        RebuildAllESPs()
        SaveConfig()
    end,
})

ESPSection:CreateDivider()

ESPSection:CreateSlider({
    Name = "ESP Range",
    Value = {50, 2000},
    Increment = 50,
    Suffix = "studs",
    Flag = "ESPRange",
    CurrentValue = getgenv().ESPRange,
    Callback = function(Value)
        getgenv().ESPRange = Value
        Config.ESPRange = Value
        RebuildAllESPs()
        SaveConfig()
    end,
})

-- Greyscale
MiscVizSection:CreateToggle("Normal", {
    Name = "Greyscale World",
    Flag = "GreyscaleEnabled",
    Callback = function(Value)
        if Value then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Saturation = -1
            cc.Parent = Lighting
            getgenv()._GreyscaleEffect = cc
        else
            if getgenv()._GreyscaleEffect then
                getgenv()._GreyscaleEffect:Destroy()
                getgenv()._GreyscaleEffect = nil
            end
        end
    end,
})

-- ===== Miscellaneous Tab =====
local ModeratorSection = MiscTab:CreateSection("Moderator Detector", "Normal")
local ModeratorDetectorConnection = nil

ModeratorSection:CreateToggle("Normal", {
    Name = "Enable Moderator Detector",
    Flag = "ModeratorDetector",
    CurrentValue = getgenv().ModeratorDetector,
    Callback = function(Value)
        getgenv().ModeratorDetector = Value
        Config.ModeratorDetector = Value
        if Value then
            ModeratorDetectorConnection = Players.PlayerAdded:Connect(function(player)
                local rank = player:GetRankInGroup(game.CreatorId)
                if rank >= 248 then
                    local role = player:GetRoleInGroup(game.CreatorId)
                    UI:Notify("Warning", {
                        Title = "Moderator Detector",
                        Content = player.Name .. " (" .. role .. ") joined",
                        Duration = 5,
                        Image = "rbxassetid://4483362458",
                    })
                end
            end)
            UI:Notify("Normal", {
                Title = "Moderator Detector",
                Content = "Enabled",
                Duration = 3,
                Image = "rbxassetid://4483362458",
            })
        else
            if ModeratorDetectorConnection then
                ModeratorDetectorConnection:Disconnect()
                ModeratorDetectorConnection = nil
            end
            UI:Notify("Warning", {
                Title = "Moderator Detector",
                Content = "Disabled",
                Duration = 3,
                Image = "rbxassetid://4483362458",
            })
        end
        SaveConfig()
    end,
})

-- ===== Settings Tab =====
local SettingsSection = SettingsTab:CreateSection("UI & Configuration", "Normal")

-- Keybind to toggle UI
SettingsSection:CreateKeybind({
    Name = "Toggle UI",
    Flag = "UIToggleKey",
    Keybind = Config.UIToggleKey,
    Type = "Press",
    Callback = function()
        UI:ToggleUI()
    end,
})

SettingsSection:CreateDivider()

-- Load Configuration
SettingsSection:CreateButton({
    Name = "Load Configuration",
    Callback = function()
        LoadConfig()
        -- Apply loaded config to globals
        getgenv().ESPEnabled = Config.ESPEnabled
        getgenv().HighlightEnabled = Config.HighlightEnabled
        getgenv().BoxEnabled = Config.BoxEnabled
        getgenv().SkeletonEnabled = Config.SkeletonEnabled
        getgenv().ChamsEnabled = Config.ChamsEnabled
        getgenv().TracerEnabled = Config.TracerEnabled
        getgenv().HealthBarEnabled = Config.HealthBarEnabled
        getgenv().ESPRange = Config.ESPRange
        getgenv().SilentAimEnabled = Config.SilentAimEnabled
        getgenv().SilentAimWallCheck = Config.SilentAimWallCheck
        getgenv().SilentAimHitPart = Config.SilentAimHitPart
        getgenv().SilentAimHitChance = Config.SilentAimHitChance
        getgenv().FOVCircleEnabled = Config.FOVCircleEnabled
        getgenv().FOVRadius = Config.FOVRadius
        getgenv().FOVColor = Config.FOVColor
        getgenv().ModeratorDetector = Config.ModeratorDetector
        if getgenv().ESPEnabled then RebuildAllESPs() end
        UI:Notify("Normal", {
            Title = "Config Loaded",
            Content = "Settings loaded successfully.",
            Duration = 5,
            Image = "rbxassetid://4483362458",
        })
    end,
})

-- Reset to Default
SettingsSection:CreateButton({
    Name = "Reset to Default",
    Callback = function()
        ResetConfig()
    end,
})

-- ===== Startup Notification =====
UI:Notify("Normal", {
    Title = "Matrice v" .. Matrice.Version,
    Content = "SCP Roleplay loaded successfully.",
    Duration = 5,
    Image = "rbxassetid://12974454446",
    Actions = {
        {
            Name = "Okay!",
            Callback = function()
                print("Script ready.")
            end
        }
    }
})