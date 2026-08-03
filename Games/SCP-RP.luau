-- Matrice Softworks

-- ============================================================
--  SERVICES
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================
--  REFERENCES
-- ============================================================

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
--  STARTUP CLEANUP
-- ============================================================

pcall(function()
    CoreGui.RobloxGui["CoreScripts/NetworkPause"]:Destroy()
end)

-- ============================================================
--  FEATURE VARIABLES
-- ============================================================

local ModeratorDetectorEnabled = false
local ModeratorDetectorAddedConnection = nil
local ModeratorDetectorRemovingConnection = nil

local AntiAFKEnabled = false
local AntiAFKConnection = nil

-- ============================================================
--  HELPER FUNCTIONS
-- ============================================================

local function DetectModerator(Enabled)
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

local function AntiAFK(Enabled)
    AntiAFKEnabled = Enabled
    if Enabled then
        if not AntiAFKConnection then
            AntiAFKConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    else
        if AntiAFKConnection then
            AntiAFKConnection:Disconnect()
            AntiAFKConnection = nil
        end
    end
end

local function Get008Infection()
    pcall(function()
        local Player = LocalPlayer
        if not Player then return end
        local Character = Player.Character
        if not Character then
            Player.CharacterAdded:Wait()
            Character = Player.Character
        end

        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        if not RootPart then return end

        local Origin = RootPart.CFrame
        local TargetCFrame = CFrame.new(207.819214, 0.177170038, -1261.79102)

        -- Step 1: Teleport to target to load the area
        RootPart.CFrame = TargetCFrame
        task.wait(0.5)

        -- Step 2: Check cap and open if closed
        local Cap = workspace:FindFirstChild("SCPs")
        if Cap then
            Cap = Cap:FindFirstChild("SCP-008")
            if Cap then
                Cap = Cap:FindFirstChild("Cap")
                if Cap then
                    local RotX = Cap.Rotation.X
                    local IsClosed = math.abs(RotX - 105.002998) < 0.5
                    if IsClosed then
                        local Remote = ReplicatedStorage:FindFirstChild("Remotes")
                        if Remote then
                            Remote = Remote:FindFirstChild("Interact")
                            if Remote then
                                local LidKnob = workspace:WaitForChild("Sector 3"):WaitForChild("Biohazard"):WaitForChild("Bridge008Control"):WaitForChild("LidKnob")
                                Remote:FireServer(LidKnob)
                                task.wait(2)
                            end
                        end
                    end
                end
            end
        end

        -- Step 3: Teleport to target again (after cap opens)
        RootPart.CFrame = TargetCFrame
        task.wait(0.2)

        -- Step 4: Teleport to origin (to reload)
        RootPart.CFrame = Origin
        task.wait(0.2)

        -- Step 5: Teleport back to target (final position)
        RootPart.CFrame = TargetCFrame

        -- Anchor/unanchor for infection effect
        local UpperTorso = Character:FindFirstChild("UpperTorso")
        if UpperTorso then
            UpperTorso.Anchored = true
            task.wait(1)
            UpperTorso.Anchored = false
        end

        print("SCP-008 Infection applied.")
    end)
end

-- ============================================================
--  UI CREATION
-- ============================================================

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

ESP:CreateToggle("Normal", {
    Name = "Enable ESP",
    Flag = "ESPEnabled",
    Callback = function(Enabled)
        print("Enable ESP " .. (Enabled and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Box ESP",
    Flag = "ESPBox",
    Callback = function(Enabled)
        print("Box ESP " .. (Enabled and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Name ESP",
    Flag = "ESPName",
    Callback = function(Enabled)
        print("Name ESP " .. (Enabled and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Distance ESP",
    Flag = "ESPDistance",
    Callback = function(Enabled)
        print("Distance ESP " .. (Enabled and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Weapon ESP",
    Flag = "ESPWeapon",
    Callback = function(Enabled)
        print("Weapon ESP " .. (Enabled and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Health Bar",
    Flag = "ESPHealthBar",
    Callback = function(Enabled)
        print("Health Bar " .. (Enabled and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Skeleton ESP",
    Flag = "ESPSkeleton",
    Callback = function(Enabled)
        print("Skeleton ESP " .. (Enabled and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "ESPTeamCheck",
    Callback = function(Enabled)
        print("Team Check (ESP) " .. (Enabled and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Friend Check",
    Flag = "FriendCheck",
    Callback = function(Enabled)
        print("Friend Check " .. (Enabled and "ON" or "OFF"))
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
        print("Distance Limit set to " .. Value .. " studs")
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

local Teleportation = UtilitiesTab:CreateSection("Teleportation", "Normal")

Teleportation:CreateButton({
    Name = "Class D-Zone",
    Callback = function()
        print("Teleported to Class D-Zone")
    end
})

Teleportation:CreateButton({
    Name = "Security Department",
    Callback = function()
        print("Teleported to Security Department")
    end
})

local Miscellaneous = UtilitiesTab:CreateSection("Miscellaneous", "Normal")

Miscellaneous:CreateButton({
    Name = "SCP-008 Infection",
    Callback = function()
        Get008Infection()
    end
})

Miscellaneous:CreateToggle("Normal", {
    Name = "Moderator Detector",
    Flag = "ModeratorDetector",
    Callback = function(Enabled)
        DetectModerator(Enabled)
    end
})

local AntiAFKSection = UtilitiesTab:CreateSection("Anti AFK", "Normal")

AntiAFKSection:CreateToggle("Normal", {
    Name = "Enable Anti AFK",
    Flag = "AntiAFK",
    Callback = function(Enabled)
        AntiAFK(Enabled)
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
        print("Toggle UI triggered")
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