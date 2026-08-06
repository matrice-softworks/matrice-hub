-- Matrice Softworks

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Visuals = Matrice.Visuals

local Library = Matrice.UI:CreateLibrary({
    Name = "Matrice Hub - SCP:RP",
    Icon = Matrice.Asset("matrice.png")
})

Library:CreateAdvertisement(
    "Rocheats",
    Matrice.Asset("rocheats_banner.png"),
    "https://rocheats.com/?ref=matrice",
    "Link copied to your clipboard. Thanks for supporting Matrice <3"
)

local CombatTab = Library:CreateTab("Combat", Matrice.Asset("crosshair.png"))
local VisualsTab = Library:CreateTab("Visuals", Matrice.Asset("palette.png"))
local PlayerTab = Library:CreateTab("Player", Matrice.Asset("user.png"))
local UtilitiesTab = Library:CreateTab("Utilities", Matrice.Asset("toolbox.png"))
local SettingsTab = Library:CreateTab("Settings", Matrice.Asset("settings.png"))

Library:SwitchTab()

-- ============================================================
--  COMBAT TAB
-- ============================================================

local Targeting = CombatTab:CreateSection("Targeting", "Normal")

Targeting:CreateToggle("Normal", {
    Name = "Silent Aim",
    Flag = "SilentAim",
    Callback = function(Enabled)
        print("Silent Aim " .. (Enabled and "ON" or "OFF"))
    end
})

Targeting:CreateDropdown({
    Name = "Hit Part",
    Options = {"Head", "Torso", "Random"},
    CurrentOption = "Head",
    Flag = "HitPart",
    Callback = function(Selected)
        print("Hit Part set to " .. Selected)
    end
})

Targeting:CreateSlider({
    Name = "Hit Chance",
    Value = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "HitChance",
    Callback = function(Value)
        print("Hit Chance set to " .. Value .. "%")
    end
})

Targeting:CreateDropdown({
    Name = "Target Selection",
    Options = {"Distance Priority", "Closest", "FOV Priority"},
    CurrentOption = "Distance Priority",
    Flag = "TargetSelection",
    Callback = function(Selected)
        print("Target Selection set to " .. Selected)
    end
})

Targeting:CreateDropdown({
    Name = "Target Priority",
    Options = {"Closest", "Lowest Health", "Crosshair Distance"},
    CurrentOption = "Closest",
    Flag = "TargetPriority",
    Callback = function(Selected)
        print("Target Priority set to " .. Selected)
    end
})

Targeting:CreateToggle("Normal", {
    Name = "Hitbox",
    Flag = "Hitbox",
    Callback = function(Enabled)
        print("Hitbox " .. (Enabled and "ON" or "OFF"))
    end
})

Targeting:CreateSlider({
    Name = "Hitbox Size",
    Value = {1, 10},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "HitboxSize",
    Callback = function(Value)
        print("Hitbox Size set to " .. Value)
    end
})

local Checks = CombatTab:CreateSection("Checks", "Normal")

Checks:CreateToggle("Normal", {
    Name = "Wall Check",
    Flag = "WallCheck",
    Callback = function(Enabled)
        print("Wall Check " .. (Enabled and "ON" or "OFF"))
    end
})

Checks:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "TeamCheck",
    Callback = function(Enabled)
        print("Team Check " .. (Enabled and "ON" or "OFF"))
    end
})

local FOV = CombatTab:CreateSection("FOV", "Normal")

FOV:CreateToggle("Normal", {
    Name = "Show FOV",
    Flag = "ShowFOV",
    Callback = function(Enabled)
        print("Show FOV " .. (Enabled and "ON" or "OFF"))
    end
})

FOV:CreateSlider({
    Name = "FOV Radius",
    Value = {1, 360},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 120,
    Flag = "FOVRadius",
    Callback = function(Value)
        print("FOV Radius set to " .. Value)
    end
})

FOV:CreateColorPicker({
    Name = "FOV Color",
    Callback = function(Color)
        print("FOV color changed to", Color)
    end
})

local Automation = CombatTab:CreateSection("Automation", "Normal")

Automation:CreateToggle("Normal", {
    Name = "Auto Trigger",
    Flag = "AutoTrigger",
    Callback = function(Enabled)
        print("Auto Trigger " .. (Enabled and "ON" or "OFF"))
    end
})

Automation:CreateSlider({
    Name = "Trigger Delay",
    Value = {0, 500},
    Increment = 10,
    Suffix = "ms",
    CurrentValue = 50,
    Flag = "TriggerDelay",
    Callback = function(Value)
        print("Trigger Delay set to " .. Value .. "ms")
    end
})

local Weapons = CombatTab:CreateSection("Weapons", "Normal")

Weapons:CreateToggle("Normal", {
    Name = "Auto Reload",
    Flag = "AutoReload",
    Callback = function(Enabled)
        print("Auto Reload " .. (Enabled and "ON" or "OFF"))
    end
})

-- ============================================================
--  VISUALS TAB
-- ============================================================

local ESP = VisualsTab:CreateSection("ESP", "Normal")

local ESPEnabled = false
local ESPSettings = {
    Box = false,
    Name = false,
    Distance = false,
    Weapon = false,
    HealthBar = false,
    Skeleton = false,
    TeamCheck = false,
    FriendCheck = false,
    DistanceLimit = 500,
    Color = Color3.fromRGB(255, 255, 255)
}

local PlayerVisuals = {}

local function UpdatePlayerVisuals(Player)
    if not Player or not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
        if PlayerVisuals[Player] then
            for _, Visual in ipairs(PlayerVisuals[Player]) do
                pcall(Visual.Remove, Visual)
            end
            PlayerVisuals[Player] = nil
        end
        return
    end

    if not ESPEnabled then
        if PlayerVisuals[Player] then
            for _, Visual in ipairs(PlayerVisuals[Player]) do
                pcall(Visual.Remove, Visual)
            end
            PlayerVisuals[Player] = nil
        end
        return
    end

    local Settings = ESPSettings
    local Color = Settings.Color
    local VisualList = {}

    if Settings.Box then
        local Box = Visuals:CreateVisual("Drawing", {
            Type = "Square",
            Color = Color,
            Thickness = 1,
            Filled = false,
        })
        Box:StartTracking(Player)
        table.insert(VisualList, Box)
    end

    if Settings.Name then
        local NameText = Visuals:CreateVisual("Drawing", {
            Type = "Text",
            Color = Color,
            Size = 14,
            Center = true,
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
            Text = Player.Name,
        })
        NameText:StartTracking(Player, "Top")
        table.insert(VisualList, NameText)
    end

    if Settings.Distance then
        local DistanceText = Visuals:CreateVisual("Drawing", {
            Type = "Text",
            Color = Color,
            Size = 12,
            Center = true,
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
        })
        DistanceText:StartTracking(Player, "Bottom")
        table.insert(VisualList, DistanceText)
        RunService.RenderStepped:Connect(function()
            if DistanceText and DistanceText.Object and Player and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                local Distance = (Player.Character.HumanoidRootPart.Position - (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new())).Magnitude
                if Distance <= Settings.DistanceLimit then
                    DistanceText.Object.Text = math.floor(Distance) .. "m"
                    DistanceText.Object.Visible = true
                else
                    DistanceText.Object.Visible = false
                end
            end
        end)
    end

    if Settings.Weapon then
        local WeaponText = Visuals:CreateVisual("Drawing", {
            Type = "Text",
            Color = Color,
            Size = 12,
            Center = true,
            Outline = true,
            OutlineColor = Color3.fromRGB(0, 0, 0),
        })
        WeaponText:StartTracking(Player, "TopRight")
        table.insert(VisualList, WeaponText)
        RunService.RenderStepped:Connect(function()
            if WeaponText and WeaponText.Object and Player and Player.Character then
                local Character = Player.Character
                local Tool = Character:FindFirstChildOfClass("Tool")
                WeaponText.Object.Text = Tool and Tool.Name or "None"
            end
        end)
    end

    if Settings.Skeleton then
        local Skeleton = Visuals:CreateVisual("Drawing", {
            Type = "Skeleton",
            Player = Player,
            Color = Color,
            Thickness = 1.5,
        })
        table.insert(VisualList, Skeleton)
    end

    if Settings.HealthBar then
        local HealthBar = Visuals:CreateVisual("Drawing", {
            Type = "Square",
            Color = Color3.fromRGB(0, 255, 0),
            Thickness = 1,
            Filled = true,
        })
        HealthBar:StartTracking(Player, "Left")
        table.insert(VisualList, HealthBar)
        RunService.RenderStepped:Connect(function()
            if HealthBar and HealthBar.Object and Player and Player.Character then
                local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
                if Humanoid then
                    local Health = Humanoid.Health / Humanoid.MaxHealth
                    HealthBar.Object.Color = Color3.fromRGB(255 * (1 - Health), 255 * Health, 0)
                    HealthBar.Object.Size = Vector2.new(6, 50 * Health)
                end
            end
        end)
    end

    PlayerVisuals[Player] = VisualList
end

local function UpdateAllPlayers()
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            UpdatePlayerVisuals(Player)
        end
    end
end

local function ClearPlayerVisuals(Player)
    if PlayerVisuals[Player] then
        for _, Visual in ipairs(PlayerVisuals[Player]) do
            pcall(Visual.Remove, Visual)
        end
        PlayerVisuals[Player] = nil
    end
end

ESP:CreateToggle("Normal", {
    Name = "Enable ESP",
    Flag = "ESPEnabled",
    Callback = function(Enabled)
        ESPEnabled = Enabled
        if not Enabled then
            for Player, _ in pairs(PlayerVisuals) do
                ClearPlayerVisuals(Player)
            end
        else
            UpdateAllPlayers()
        end
    end
})

ESP:CreateToggle("Normal", {
    Name = "Box ESP",
    Flag = "ESPBox",
    Callback = function(Enabled)
        ESPSettings.Box = Enabled
        UpdateAllPlayers()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Name ESP",
    Flag = "ESPName",
    Callback = function(Enabled)
        ESPSettings.Name = Enabled
        UpdateAllPlayers()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Distance ESP",
    Flag = "ESPDistance",
    Callback = function(Enabled)
        ESPSettings.Distance = Enabled
        UpdateAllPlayers()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Weapon ESP",
    Flag = "ESPWeapon",
    Callback = function(Enabled)
        ESPSettings.Weapon = Enabled
        UpdateAllPlayers()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Health Bar",
    Flag = "ESPHealthBar",
    Callback = function(Enabled)
        ESPSettings.HealthBar = Enabled
        UpdateAllPlayers()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Skeleton ESP",
    Flag = "ESPSkeleton",
    Callback = function(Enabled)
        ESPSettings.Skeleton = Enabled
        UpdateAllPlayers()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "ESPTeamCheck",
    Callback = function(Enabled)
        ESPSettings.TeamCheck = Enabled
        UpdateAllPlayers()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Friend Check",
    Flag = "FriendCheck",
    Callback = function(Enabled)
        ESPSettings.FriendCheck = Enabled
        UpdateAllPlayers()
    end
})

ESP:CreateSlider({
    Name = "Distance Limit",
    Value = {10, 1000},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 500,
    Flag = "DistanceLimit",
    Callback = function(Value)
        ESPSettings.DistanceLimit = Value
        UpdateAllPlayers()
    end
})

ESP:CreateColorPicker({
    Name = "ESP Color",
    Callback = function(Color)
        ESPSettings.Color = Color
        UpdateAllPlayers()
    end
})

local Effects = VisualsTab:CreateSection("Effects", "Normal")

Effects:CreateToggle("Normal", {
    Name = "Highlight",
    Flag = "Highlight",
    Callback = function(Enabled)
        print("Highlight " .. (Enabled and "ON" or "OFF"))
    end
})

Effects:CreateToggle("Normal", {
    Name = "Chams",
    Flag = "Chams",
    Callback = function(Enabled)
        print("Chams " .. (Enabled and "ON" or "OFF"))
    end
})

Effects:CreateToggle("Normal", {
    Name = "Tracer Lines",
    Flag = "TracerLines",
    Callback = function(Enabled)
        print("Tracer Lines " .. (Enabled and "ON" or "OFF"))
    end
})

Effects:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Center", "Mouse"},
    CurrentOption = "Bottom",
    Flag = "TracerOrigin",
    Callback = function(Selected)
        print("Tracer Origin set to " .. Selected)
    end
})

-- ============================================================
--  PLAYER TAB
-- ============================================================

local Character = PlayerTab:CreateSection("Character", "Normal")

Character:CreateToggle("Normal", {
    Name = "Enable Walk Speed",
    Flag = "WalkSpeedEnabled",
    Callback = function(Enabled)
        print("Enable Walk Speed " .. (Enabled and "ON" or "OFF"))
    end
})

Character:CreateSlider({
    Name = "Walk Speed",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(Value)
        print("Walk Speed set to " .. Value)
    end
})

Character:CreateToggle("Normal", {
    Name = "Enable Jump Power",
    Flag = "JumpPowerEnabled",
    Callback = function(Enabled)
        print("Enable Jump Power " .. (Enabled and "ON" or "OFF"))
    end
})

Character:CreateSlider({
    Name = "Jump Power",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(Value)
        print("Jump Power set to " .. Value)
    end
})

Character:CreateToggle("Normal", {
    Name = "No Clip",
    Flag = "NoClip",
    Callback = function(Enabled)
        print("No Clip " .. (Enabled and "ON" or "OFF"))
    end
})

Character:CreateKeybind({
    Name = "No Clip Keybind",
    Flag = "NoClipKeybind",
    Keybind = "N",
    Type = "Press",
    Callback = function(State)
        print("No Clip key " .. (State and "pressed" or "released"))
    end
})

Character:CreateToggle("Normal", {
    Name = "Fly",
    Flag = "Fly",
    Callback = function(Enabled)
        print("Fly " .. (Enabled and "ON" or "OFF"))
    end
})

Character:CreateKeybind({
    Name = "Fly Keybind",
    Flag = "FlyKeybind",
    Keybind = "F",
    Type = "Press",
    Callback = function(State)
        print("Fly key " .. (State and "pressed" or "released"))
    end
})

-- ============================================================
--  UTILITIES TAB
-- ============================================================

local Miscellaneous = UtilitiesTab:CreateSection("Miscellaneous", "Normal")

local ModeratorDetectorEnabled = false
local ModeratorDetectorAddedConnection = nil
local ModeratorDetectorRemovingConnection = nil

Miscellaneous:CreateToggle("Normal", {
    Name = "Moderator Detector",
    Flag = "ModeratorDetector",
    Callback = function(Enabled)
        ModeratorDetectorEnabled = Enabled
        if Enabled then
            for _, Player in ipairs(Players:GetPlayers()) do
                if Player ~= LocalPlayer then
                    local Success, Rank = pcall(Player.GetRankInGroup, Player, game.CreatorId)
                    if Success and Rank and Rank >= 248 then
                        local Role = Player:GetRoleInGroup(game.CreatorId)
                        Matrice.UI:Notify("Warning", {
                            Title = "Moderator Detector",
                            Content = Player.Name .. " (" .. Role .. ") is in the server!",
                            Duration = 10,
                            Image = Matrice.Asset("user-shield.png"),
                            Actions = {
                                {
                                    Name = "Leave Game",
                                    Callback = function()
                                        game:Shutdown()
                                    end
                                }
                            }
                        })
                    end
                end
            end

            if ModeratorDetectorAddedConnection then
                ModeratorDetectorAddedConnection:Disconnect()
                ModeratorDetectorAddedConnection = nil
            end
            ModeratorDetectorAddedConnection = Players.PlayerAdded:Connect(function(Player)
                if ModeratorDetectorEnabled then
                    task.wait(1)
                    local Success, Rank = pcall(Player.GetRankInGroup, Player, game.CreatorId)
                    if Success and Rank and Rank >= 248 then
                        local Role = Player:GetRoleInGroup(game.CreatorId)
                        Matrice.UI:Notify("Warning", {
                            Title = "Moderator Detector",
                            Content = Player.Name .. " (" .. Role .. ") joined the server!",
                            Duration = 10,
                            Image = Matrice.Asset("user-shield.png"),
                            Actions = {
                                {
                                    Name = "Leave Game",
                                    Callback = function()
                                        game:Shutdown()
                                    end
                                }
                            }
                        })
                    end
                end
            end)

            if ModeratorDetectorRemovingConnection then
                ModeratorDetectorRemovingConnection:Disconnect()
                ModeratorDetectorRemovingConnection = nil
            end
            ModeratorDetectorRemovingConnection = Players.PlayerRemoving:Connect(function(Player)
                if ModeratorDetectorEnabled then
                    local Success, Rank = pcall(Player.GetRankInGroup, Player, game.CreatorId)
                    if Success and Rank and Rank >= 248 then
                        local Role = Player:GetRoleInGroup(game.CreatorId)
                        Matrice.UI:Notify("Warning", {
                            Title = "Moderator Detector",
                            Content = Player.Name .. " (" .. Role .. ") left the server!",
                            Duration = 10,
                            Image = Matrice.Asset("user-shield.png"),
                            Actions = {
                                {
                                    Name = "Leave Game",
                                    Callback = function()
                                        game:Shutdown()
                                    end
                                }
                            }
                        })
                    end
                end
            end)
        else
            if ModeratorDetectorAddedConnection then
                ModeratorDetectorAddedConnection:Disconnect()
                ModeratorDetectorAddedConnection = nil
            end
            if ModeratorDetectorRemovingConnection then
                ModeratorDetectorRemovingConnection:Disconnect()
                ModeratorDetectorRemovingConnection = nil
            end
        end
    end
})

local AntiAFKSection = UtilitiesTab:CreateSection("Anti AFK", "Normal")

local AntiAFKEnabled = false
local AntiAFKConnection = nil

AntiAFKSection:CreateToggle("Normal", {
    Name = "Enable Anti AFK",
    Flag = "AntiAFK",
    Callback = function(Enabled)
        AntiAFKEnabled = Enabled
        if Enabled then
            if getconnections then
                for _, Connection in ipairs(getconnections(LocalPlayer.Idled)) do
                    pcall(function()
                        Connection:Disable()
                        Connection:Disconnect()
                    end)
                end
            end
            if AntiAFKConnection then
                AntiAFKConnection:Disconnect()
                AntiAFKConnection = nil
            end
            AntiAFKConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        else
            if AntiAFKConnection then
                AntiAFKConnection:Disconnect()
                AntiAFKConnection = nil
            end
        end
    end
})

-- ============================================================
--  SETTINGS TAB
-- ============================================================

local Interface = SettingsTab:CreateSection("Interface", "Normal")

Interface:CreateKeybind({
    Name = "Toggle Menu Key",
    Flag = "ToggleMenuKey",
    Keybind = "LeftAlt",
    Type = "Press",
    Callback = function(State)
        Matrice.UI:ToggleUI()
    end
})

local gameVersion = tostring((Matrice.Game and Matrice.Game.Info and Matrice.Game.Info.Version) or "N/A")
local gameChangelog = tostring((Matrice.Game and Matrice.Game.Info and Matrice.Game.Info.Changelog) or "No changelog available.")

Interface:CreateCard({
    Title = "Matrice Hub - SCP:RP",
    Description = "A script hub packed with high-quality undetectable scripts",
    SecondaryTitle = "By Matrice Softworks",
    Image = Matrice.Asset("matrice.png"),
    Buttons = {
        Button1 = {
            Name = "Discord",
            Callback = function()
                setclipboard("https://discord.gg/matrice")
                Matrice.UI:Notify("Normal", {
                    Title = "Copied!",
                    Content = "Link copied to your clipboard. Thanks for supporting Matrice <3",
                    Duration = 3,
                    Image = Matrice.Asset("discord.png")
                })
            end
        },
        Button2 = {
            Name = "Website",
            Callback = function()
                setclipboard("https://getmatrice.xyz")
                Matrice.UI:Notify("Normal", {
                    Title = "Copied!",
                    Content = "Link copied to your clipboard. Thanks for supporting Matrice <3",
                    Duration = 3,
                    Image = Matrice.Asset("globe.png")
                })
            end
        }
    }
})

Interface:CreateParagraph({
    Title = "Version " .. gameVersion,
    Description = "Changelog:\n" .. gameChangelog
})

print("SCP:RP UI loaded.")

-- ============================================================
--  PLAYER CONNECTIONS FOR ESP
-- ============================================================

Players.PlayerAdded:Connect(function(Player)
    if Player ~= LocalPlayer then
        Player.CharacterAdded:Connect(function()
            UpdatePlayerVisuals(Player)
        end)
        UpdatePlayerVisuals(Player)
    end
end)

Players.PlayerRemoving:Connect(function(Player)
    ClearPlayerVisuals(Player)
end)