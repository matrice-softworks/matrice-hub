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
    -- Character Modifications
    MovementEnabled = false,
    Walkspeed = 16,
    Jumppower = 50,
    NoClipEnabled = false,
    NoClipKeybind = "N",
    FlyEnabled = false,
    FlySpeed = 50,
    FlyKeybind = "F",
    -- UI
    UIToggleKey = "RightControl",
}

local CONFIG_FILE = "SCP-RP-Config.json"

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
        MovementEnabled = false,
        Walkspeed = 16,
        Jumppower = 50,
        NoClipEnabled = false,
        NoClipKeybind = "N",
        FlyEnabled = false,
        FlySpeed = 50,
        FlyKeybind = "F",
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
        Image = Matrice.Asset("circle-alert"),
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
getgenv().MovementEnabled = Config.MovementEnabled
getgenv().Walkspeed = Config.Walkspeed
getgenv().Jumppower = Config.Jumppower
getgenv().NoClipEnabled = Config.NoClipEnabled
getgenv().NoClipKeybind = Config.NoClipKeybind
getgenv().FlyEnabled = Config.FlyEnabled
getgenv().FlySpeed = Config.FlySpeed
getgenv().FlyKeybind = Config.FlyKeybind

LoadConfig()

-- ===== UI Library =====
local Library = UI:CreateLibrary({
    Name = "Matrice v" .. Matrice.Version .. " - " .. Matrice.Game.Info.Name,
    Icon = Matrice.Asset("matrice")
})

-- ===== Tabs =====
local HomeTab = Library:CreateTab("Home", Matrice.Asset("house"))
local CombatTab = Library:CreateTab("Combat", Matrice.Asset("crosshair"))
local VisualsTab = Library:CreateTab("Visuals", Matrice.Asset("palette"))
local UtilitiesTab = Library:CreateTab("Utilities", Matrice.Asset("toolbox"))
local SettingsTab = Library:CreateTab("Settings", Matrice.Asset("settings"))

-- ===== Home Tab =====
local HomeSection = HomeTab:CreateSection("Welcome", "Normal")

HomeSection:CreateCard({
    Title = "Matrice Hub",
    Description = "Matrice is a premium Roblox script hub delivering optimized, undetected, and high-quality scripts.",
    SecondaryTitle = "Version v" .. Matrice.Version,
    Image = Matrice.Asset("matrice-softworks"),
    Buttons = {
        Discord = {
            Name = "Join Discord",
            Callback = function()
                setclipboard("https://discord.gg/tester")
                UI:Notify("Normal", {
                    Title = "Copied",
                    Content = "Discord invite copied to clipboard.",
                    Duration = 3,
                    Image = Matrice.Asset("discord"),
                })
            end
        },
        GitHub = {
            Name = "Visit GitHub",
            Callback = function()
                setclipboard("https://github.com/matrice-softworks/matrice-hub")
                UI:Notify("Normal", {
                    Title = "Copied",
                    Content = "GitHub link copied to clipboard.",
                    Duration = 3,
                    Image = Matrice.Asset("globe"),
                })
            end
        }
    }
})

HomeSection:CreateDivider()

local InfoSection = HomeTab:CreateSection("Script Information", "Foldable")
InfoSection:CreateParagraph({
    Title = "About",
    Description = "This script provides ESP, Silent Aim, Moderator Detection, and Character Modifications (Movement Spoof, NoClip, Fly) for SCP: Roleplay.\n\n<b>Features:</b>\n• Full ESP system with multiple visual options\n• Silent Aim with adjustable FOV\n• Moderator/Staff detection\n• Undetected Walkspeed & JumpPower spoof\n• NoClip (disable collisions)\n• Fly mode with keybind and speed control\n• Configuration save/load/reset\n• Customizable keybinds"
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

-- Silent Aim UI
SilentAimSection:CreateToggle("Normal", {
    Name = "Enable Silent Aim",
    Flag = "SilentAimEnabled",
    CurrentValue = getgenv().SilentAimEnabled,
    Callback = function(Value)
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

-- ===== Utilities Tab =====
-- Moderator Detector
local ModeratorSection = UtilitiesTab:CreateSection("Moderator Detector", "Normal")

local ModeratorDetectorConnection = nil
local ModNotifiedPlayers = {}
local ShutdownActive = false
local SavedFeatures = {}

-- Store previous states when turning off all features
local FeatureKeys = {
    "ESPEnabled",
    "HighlightEnabled",
    "BoxEnabled",
    "SkeletonEnabled",
    "ChamsEnabled",
    "TracerEnabled",
    "HealthBarEnabled",
    "SilentAimEnabled",
    "MovementEnabled",
    "NoClipEnabled",
    "FlyEnabled",
}

local function TurnOffAllFeatures()
    SavedFeatures = {}
    for _, key in ipairs(FeatureKeys) do
        SavedFeatures[key] = getgenv()[key]
        getgenv()[key] = false
        Config[key] = false
    end
    ShutdownActive = true
    SaveConfig()
    -- Stop ESP if it was on
    if getgenv().ESPEnabled then ClearESPs() end
    -- Stop movement spoof if active
    if SpoofActive then MovementSpoof:Disable() end
    -- Stop NoClip if active
    if NoClipActive then DisableNoClip() end
    -- Stop Fly if active
    if FlyActive then StopFly() end
    UI:Notify("Warning", {
        Title = "Features Disabled",
        Content = "All features have been turned off due to moderator presence.",
        Duration = 5,
        Image = Matrice.Asset("circle-alert"),
    })
end

local function TurnOnAllFeatures()
    for key, value in pairs(SavedFeatures) do
        getgenv()[key] = value
        Config[key] = value
    end
    ShutdownActive = false
    SavedFeatures = {}
    SaveConfig()
    -- Restore ESP if needed
    if getgenv().ESPEnabled then RebuildAllESPs() end
    -- Restore movement spoof
    if getgenv().MovementEnabled then
        if not SpoofActive then MovementSpoof:Enable(getgenv().Walkspeed, getgenv().Jumppower) end
    end
    -- Restore NoClip
    if getgenv().NoClipEnabled then EnableNoClip() end
    -- Restore Fly
    if getgenv().FlyEnabled then StartFly() end
    UI:Notify("Normal", {
        Title = "Features Restored",
        Content = "All features have been turned back on.",
        Duration = 3,
        Image = Matrice.Asset("info"),
    })
end

local function CheckModerators()
    ModNotifiedPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local rank = player:GetRankInGroup(game.CreatorId)
            if rank >= 248 then
                local role = player:GetRoleInGroup(game.CreatorId)
                UI:Notify("Warning", {
                    Title = "Moderator Detector",
                    Content = player.Name .. " (" .. role .. ") is online",
                    Duration = 10,
                    Image = Matrice.Asset("user-shield"),
                    Actions = {
                        {
                            Name = "Leave Game",
                            Callback = function()
                                game:Shutdown()
                            end
                        },
                        {
                            Name = "Turn Off All Features",
                            Callback = function()
                                TurnOffAllFeatures()
                            end
                        }
                    }
                })
                ModNotifiedPlayers[player] = true
            end
        end
    end
end

local function EnableModeratorDetector()
    if ModeratorDetectorConnection then return end
    CheckModerators()
    ModeratorDetectorConnection = Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            local rank = player:GetRankInGroup(game.CreatorId)
            if rank >= 248 then
                local role = player:GetRoleInGroup(game.CreatorId)
                UI:Notify("Warning", {
                    Title = "Moderator Detector",
                    Content = player.Name .. " (" .. role .. ") joined",
                    Duration = 10,
                    Image = Matrice.Asset("user-shield"),
                    Actions = {
                        {
                            Name = "Leave Game",
                            Callback = function()
                                game:Shutdown()
                            end
                        },
                        {
                            Name = "Turn Off All Features",
                            Callback = function()
                                TurnOffAllFeatures()
                            end
                        }
                    }
                })
                ModNotifiedPlayers[player] = true
            end
        end
    end)
    -- Also handle player leaving
    if not ModNotifiedPlayers._leaveConnection then
        ModNotifiedPlayers._leaveConnection = Players.PlayerRemoving:Connect(function(player)
            if ModNotifiedPlayers[player] then
                ModNotifiedPlayers[player] = nil
                if ShutdownActive then
                    UI:Notify("Normal", {
                        Title = "Moderator Left",
                        Content = "A moderator has left. Do you want to turn all features back on?",
                        Duration = 10,
                        Image = Matrice.Asset("info"),
                        Actions = {
                            {
                                Name = "Turn On All Features",
                                Callback = function()
                                    TurnOnAllFeatures()
                                end
                            }
                        }
                    })
                end
            end
        end)
    end
    UI:Notify("Normal", {
        Title = "Moderator Detector",
        Content = "Enabled",
        Duration = 3,
        Image = Matrice.Asset("user-shield"),
    })
end

local function DisableModeratorDetector()
    if ModeratorDetectorConnection then
        ModeratorDetectorConnection:Disconnect()
        ModeratorDetectorConnection = nil
    end
    if ModNotifiedPlayers._leaveConnection then
        ModNotifiedPlayers._leaveConnection:Disconnect()
        ModNotifiedPlayers._leaveConnection = nil
    end
    ModNotifiedPlayers = {}
    UI:Notify("Warning", {
        Title = "Moderator Detector",
        Content = "Disabled",
        Duration = 3,
        Image = Matrice.Asset("user-shield"),
    })
end

ModeratorSection:CreateToggle("Normal", {
    Name = "Enable Moderator Detector",
    Flag = "ModeratorDetector",
    CurrentValue = getgenv().ModeratorDetector,
    Callback = function(Value)
        getgenv().ModeratorDetector = Value
        Config.ModeratorDetector = Value
        if Value then
            EnableModeratorDetector()
        else
            DisableModeratorDetector()
        end
        SaveConfig()
    end,
})

if getgenv().ModeratorDetector then
    EnableModeratorDetector()
end

-- ===== Character Modifications Section =====
local CharModSection = UtilitiesTab:CreateSection("Character Modifications", "Normal")

-- ===== Movement Spoof (undetected) =====
local MovementSpoof = {}
local SpoofActive = false
local CurrentHumanoid = nil
local SpoofedWalk = 16
local SpoofedJump = 50
local cachedHumanoids = {}
local GetDebugIdHandler = Instance.new("BindableFunction")
local TempHumanoid = Instance.new("Humanoid")
local indexHook, newIndexHook
local MovementCharacterConnection = nil

function GetDebugIdHandler.OnInvoke(obj)
    return obj:GetDebugId()
end
local function GetDebugId(obj)
    return GetDebugIdHandler:Invoke(obj)
end

local function GetSpoofValue(value)
    TempHumanoid.WalkSpeed = value
    return TempHumanoid.WalkSpeed
end

function cachedHumanoids:cacheHumanoid(DebugId, Humanoid)
    cachedHumanoids[DebugId] = {
        currentWalk = indexHook(Humanoid, "WalkSpeed"),
        currentJump = indexHook(Humanoid, "JumpPower"),
        lastWalk = nil,
        lastJump = nil,
    }
    return self[DebugId]
end

indexHook = hookmetamethod(game, "__index", function(self, index)
    if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
        local DebugId = GetDebugId(self)
        local cached = cachedHumanoids[DebugId]
        if self:IsDescendantOf(LocalPlayer.Character) or cached then
            if type(index) == "string" then
                local clean = string.split(index, "\0")[1]
                if clean == "WalkSpeed" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(DebugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    return cached.lastWalk or cached.currentWalk
                elseif clean == "JumpPower" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(DebugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    return cached.lastJump or cached.currentJump
                end
            end
        end
    end
    return indexHook(self, index)
end)

newIndexHook = hookmetamethod(game, "__newindex", function(self, index, newValue)
    if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
        local DebugId = GetDebugId(self)
        local cached = cachedHumanoids[DebugId]
        if self:IsDescendantOf(LocalPlayer.Character) or cached then
            if type(index) == "string" then
                local clean = string.split(index, "\0")[1]
                if clean == "WalkSpeed" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(DebugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    cached.lastWalk = GetSpoofValue(newValue)
                    return CurrentHumanoid.WalkSpeed
                elseif clean == "JumpPower" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(DebugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    cached.lastJump = GetSpoofValue(newValue)
                    return CurrentHumanoid.JumpPower
                end
            end
        end
    end
    return newIndexHook(self, index, newValue)
end)

function MovementSpoof:GetHumanoid()
    return CurrentHumanoid or (function()
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            cachedHumanoids:cacheHumanoid(humanoid:GetDebugId(), humanoid)
            return cloneref(humanoid)
        end
    end)()
end

function MovementSpoof:SetWalkSpeed(speed)
    local humanoid = MovementSpoof:GetHumanoid()
    if not humanoid then return end
    local connections = {}
    local function AddConnections(Signal)
        for _, conn in getconnections(Signal) do
            if conn.State then
                conn:Disable()
                table.insert(connections, conn)
            end
        end
    end
    AddConnections(humanoid.Changed)
    AddConnections(humanoid:GetPropertyChangedSignal("WalkSpeed"))
    humanoid.WalkSpeed = speed
    for _, conn in connections do conn:Enable() end
end

function MovementSpoof:SetJumpPower(power)
    local humanoid = MovementSpoof:GetHumanoid()
    if not humanoid then return end
    local connections = {}
    local function AddConnections(Signal)
        for _, conn in getconnections(Signal) do
            if conn.State then
                conn:Disable()
                table.insert(connections, conn)
            end
        end
    end
    AddConnections(humanoid.Changed)
    AddConnections(humanoid:GetPropertyChangedSignal("JumpPower"))
    humanoid.JumpPower = power
    for _, conn in connections do conn:Enable() end
end

function MovementSpoof:Restore()
    local humanoid = MovementSpoof:GetHumanoid()
    if humanoid then
        local debugId = humanoid:GetDebugId()
        local cached = cachedHumanoids[debugId]
        if cached then
            MovementSpoof:SetWalkSpeed(cached.lastWalk or cached.currentWalk)
            MovementSpoof:SetJumpPower(cached.lastJump or cached.currentJump)
        else
            MovementSpoof:SetWalkSpeed(16)
            MovementSpoof:SetJumpPower(50)
        end
    end
end

function MovementSpoof:Disable()
    SpoofActive = false
    MovementSpoof:Restore()
    if MovementCharacterConnection then
        MovementCharacterConnection:Disconnect()
        MovementCharacterConnection = nil
    end
end

function MovementSpoof:Enable(walk, jump)
    SpoofActive = true
    SpoofedWalk = walk or SpoofedWalk
    SpoofedJump = jump or SpoofedJump
    local humanoid = MovementSpoof:GetHumanoid()
    if humanoid then
        cachedHumanoids:cacheHumanoid(humanoid:GetDebugId(), humanoid)
        MovementSpoof:SetWalkSpeed(SpoofedWalk)
        MovementSpoof:SetJumpPower(SpoofedJump)
    end
    if not MovementCharacterConnection then
        MovementCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.1)
            local humanoid = char:FindFirstChildWhichIsA("Humanoid")
            if humanoid and SpoofActive then
                cachedHumanoids:cacheHumanoid(humanoid:GetDebugId(), humanoid)
                MovementSpoof:SetWalkSpeed(SpoofedWalk)
                MovementSpoof:SetJumpPower(SpoofedJump)
            end
        end)
    end
end

local function ToggleMovement(enable)
    if enable then
        if not SpoofActive then
            MovementSpoof:Enable(getgenv().Walkspeed or 16, getgenv().Jumppower or 50)
        end
    else
        if SpoofActive then
            MovementSpoof:Disable()
        end
    end
    getgenv().MovementEnabled = enable
    Config.MovementEnabled = enable
    SaveConfig()
end

CharModSection:CreateToggle("Normal", {
    Name = "Enable Movement Spoof",
    Flag = "MovementEnabled",
    CurrentValue = getgenv().MovementEnabled or false,
    Callback = function(Value)
        ToggleMovement(Value)
    end,
})

CharModSection:CreateSlider({
    Name = "Walkspeed",
    Value = {16, 100},
    Increment = 1,
    Suffix = "studs/s",
    Flag = "Walkspeed",
    CurrentValue = getgenv().Walkspeed or 16,
    Callback = function(Value)
        getgenv().Walkspeed = Value
        Config.Walkspeed = Value
        if SpoofActive then
            SpoofedWalk = Value
            MovementSpoof:SetWalkSpeed(Value)
        end
        SaveConfig()
    end,
})

CharModSection:CreateSlider({
    Name = "Jump Power",
    Value = {50, 200},
    Increment = 5,
    Suffix = "strength",
    Flag = "Jumppower",
    CurrentValue = getgenv().Jumppower or 50,
    Callback = function(Value)
        getgenv().Jumppower = Value
        Config.Jumppower = Value
        if SpoofActive then
            SpoofedJump = Value
            MovementSpoof:SetJumpPower(Value)
        end
        SaveConfig()
    end,
})

if getgenv().MovementEnabled then
    ToggleMovement(true)
end

-- ===== NoClip =====
local NoClipActive = false
local NoClipConnection = nil

local function SetNoClip(state)
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

local function EnableNoClip()
    if NoClipActive then return end
    NoClipActive = true
    SetNoClip(true)

    NoClipConnection = LocalPlayer.CharacterAdded:Connect(function(char)
        if NoClipActive then
            task.wait(0.1)
            SetNoClip(true)
        end
    end)

    UI:Notify("Normal", {
        Title = "NoClip",
        Content = "Enabled",
        Duration = 2,
        Image = Matrice.Asset("info"),
    })
end

local function DisableNoClip()
    if not NoClipActive then return end
    NoClipActive = false
    SetNoClip(false)
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end
    UI:Notify("Warning", {
        Title = "NoClip",
        Content = "Disabled",
        Duration = 2,
        Image = Matrice.Asset("circle-alert"),
    })
end

local function ToggleNoClip(enable)
    if enable then
        EnableNoClip()
    else
        DisableNoClip()
    end
    getgenv().NoClipEnabled = enable
    Config.NoClipEnabled = enable
    SaveConfig()
end

CharModSection:CreateDivider()

CharModSection:CreateToggle("Normal", {
    Name = "Enable NoClip",
    Flag = "NoClipEnabled",
    CurrentValue = getgenv().NoClipEnabled or false,
    Callback = function(Value)
        ToggleNoClip(Value)
    end,
})

-- NoClip Keybind (uses active state)
CharModSection:CreateKeybind({
    Name = "NoClip Toggle",
    Flag = "NoClipKeybind",
    Keybind = getgenv().NoClipKeybind or "N",
    Type = "Press",
    Callback = function()
        if getgenv().NoClipEnabled or NoClipActive then
            if NoClipActive then
                DisableNoClip()
            else
                EnableNoClip()
            end
        else
            UI:Notify("Warning", {
                Title = "NoClip Keybind",
                Content = "Enable NoClip toggle first.",
                Duration = 2,
                Image = Matrice.Asset("circle-alert"),
            })
        end
    end,
})

if getgenv().NoClipEnabled then
    EnableNoClip()
end

-- ===== Fly =====
local FlyActive = false
local FlyConnection = nil
local FlyCharacterConnection = nil
local FlySpeed = getgenv().FlySpeed or 50

local function StartFly()
    if FlyActive or not LocalPlayer.Character then return end
    FlyActive = true

    FlyConnection = RunService.Heartbeat:Connect(function()
        if not FlyActive or not LocalPlayer.Character then
            return
        end
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local forward = workspace.CurrentCamera.CFrame.LookVector
        local right = workspace.CurrentCamera.CFrame.RightVector
        local up = Vector3.new(0, 1, 0)

        local moveDirection = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + forward
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - forward
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - right
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + right
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + up
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - up
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit * FlySpeed
        end

        root.CFrame = root.CFrame + moveDirection * RunService.Heartbeat:Wait()
        root.Velocity = Vector3.new(0, 0, 0)
        root.RotVelocity = Vector3.new(0, 0, 0)
    end)

    FlyCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(char)
        if FlyActive then
            task.wait(0.1)
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.Velocity = Vector3.new(0, 0, 0)
                root.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)

    UI:Notify("Normal", {
        Title = "Fly",
        Content = "Enabled",
        Duration = 2,
        Image = Matrice.Asset("info"),
    })
end

local function StopFly()
    if not FlyActive then return end
    FlyActive = false
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    if FlyCharacterConnection then
        FlyCharacterConnection:Disconnect()
        FlyCharacterConnection = nil
    end
    local character = LocalPlayer.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.Velocity = Vector3.new(0, 0, 0)
            root.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
    UI:Notify("Warning", {
        Title = "Fly",
        Content = "Disabled",
        Duration = 2,
        Image = Matrice.Asset("circle-alert"),
    })
end

local function ToggleFly(enable)
    if enable then
        StartFly()
    else
        StopFly()
    end
    getgenv().FlyEnabled = enable
    Config.FlyEnabled = enable
    SaveConfig()
end

CharModSection:CreateDivider()

CharModSection:CreateToggle("Normal", {
    Name = "Enable Fly",
    Flag = "FlyEnabled",
    CurrentValue = getgenv().FlyEnabled or false,
    Callback = function(Value)
        ToggleFly(Value)
    end,
})

CharModSection:CreateSlider({
    Name = "Fly Speed",
    Value = {10, 200},
    Increment = 5,
    Suffix = "studs/s",
    Flag = "FlySpeed",
    CurrentValue = getgenv().FlySpeed or 50,
    Callback = function(Value)
        FlySpeed = Value
        getgenv().FlySpeed = Value
        Config.FlySpeed = Value
        SaveConfig()
    end,
})

-- Fly Keybind (uses active state)
CharModSection:CreateKeybind({
    Name = "Fly Toggle",
    Flag = "FlyKeybind",
    Keybind = getgenv().FlyKeybind or "F",
    Type = "Press",
    Callback = function()
        if getgenv().FlyEnabled or FlyActive then
            if FlyActive then
                StopFly()
            else
                StartFly()
            end
        else
            UI:Notify("Warning", {
                Title = "Fly Keybind",
                Content = "Enable Fly toggle first.",
                Duration = 2,
                Image = Matrice.Asset("circle-alert"),
            })
        end
    end,
})

if getgenv().FlyEnabled then
    ToggleFly(true)
end

CharModSection:CreateLabel({
    Description = "WASD to move, Space to fly up, Shift to fly down."
})

-- ===== Settings Tab =====
local SettingsSection = SettingsTab:CreateSection("UI & Configuration", "Normal")

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

SettingsSection:CreateButton({
    Name = "Load Configuration",
    Callback = function()
        LoadConfig()
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
        getgenv().MovementEnabled = Config.MovementEnabled
        getgenv().Walkspeed = Config.Walkspeed
        getgenv().Jumppower = Config.Jumppower
        getgenv().NoClipEnabled = Config.NoClipEnabled
        getgenv().NoClipKeybind = Config.NoClipKeybind
        getgenv().FlyEnabled = Config.FlyEnabled
        getgenv().FlySpeed = Config.FlySpeed
        getgenv().FlyKeybind = Config.FlyKeybind
        if getgenv().ESPEnabled then RebuildAllESPs() end
        if getgenv().ModeratorDetector then EnableModeratorDetector() else DisableModeratorDetector() end
        if getgenv().MovementEnabled then
            if not SpoofActive then
                MovementSpoof:Enable(getgenv().Walkspeed, getgenv().Jumppower)
            end
        else
            if SpoofActive then MovementSpoof:Disable() end
        end
        if getgenv().NoClipEnabled then
            if not NoClipActive then EnableNoClip() end
        else
            if NoClipActive then DisableNoClip() end
        end
        if getgenv().FlyEnabled then
            if not FlyActive then StartFly() end
        else
            if FlyActive then StopFly() end
        end
        UI:Notify("Normal", {
            Title = "Config Loaded",
            Content = "Settings loaded successfully.",
            Duration = 5,
            Image = Matrice.Asset("clipboard"),
        })
    end,
})

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
    Image = Matrice.Asset("matrice"),
    Actions = {
        {
            Name = "Okay!",
            Callback = function()
                print("Script ready.")
            end
        }
    }
})