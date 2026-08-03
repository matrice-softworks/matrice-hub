-- =============================================================
--  SCP: Roleplay – Example UI using AuraIS
--  All settings are automatically saved by AuraIS.
-- =============================================================

-- Create main window
local Library = Matrice.UI:CreateLibrary({
    Name = "Matrice Hub - SCP:RP",
    Icon = Matrice.Asset("matrice.png")
})

-- Single advertisement – Rocheats
Library:CreateAdvertisement(
    "Rocheats",
    Matrice.Asset("rocheats_banner.png"),
    "https://rocheats.com/?ref=matrice",
    "Link copied to your clipboard. Thanks for supporting Matrice <3"
)

-- =============================================================
--  CREATE TABS
-- =============================================================
local CombatTab   = Library:CreateTab("Combat",   Matrice.Asset("crosshair.png"))
local VisualsTab  = Library:CreateTab("Visuals",  Matrice.Asset("palette.png"))
local PlayerTab   = Library:CreateTab("Player",   Matrice.Asset("user.png"))
local UtilitiesTab = Library:CreateTab("Utilities", Matrice.Asset("toolbox.png"))
local SettingsTab = Library:CreateTab("Settings", Matrice.Asset("settings.png"))

-- Activate the first tab
Library:SwitchTab()

-- =============================================================
--  COMBAT TAB
-- =============================================================

-- Targeting Section
local Targeting = CombatTab:CreateSection("Targeting", "Normal")

Targeting:CreateToggle("Normal", {
    Name = "Silent Aim",
    Flag = "SilentAim",
    Callback = function(v)
        print("Silent Aim " .. (v and "ON" or "OFF"))
    end
})

Targeting:CreateDropdown({
    Name = "Hit Part",
    Options = {"Head", "Torso", "Random"},
    CurrentOption = "Head",
    Flag = "HitPart",
    Callback = function(choice)
        print("Hit Part set to " .. choice)
    end
})

Targeting:CreateSlider({
    Name = "Hit Chance",
    Value = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "HitChance",
    Callback = function(v)
        print("Hit Chance set to " .. v .. "%")
    end
})

Targeting:CreateDropdown({
    Name = "Target Selection",
    Options = {"Distance Priority", "Closest", "FOV Priority"},
    CurrentOption = "Distance Priority",
    Flag = "TargetSelection",
    Callback = function(choice)
        print("Target Selection set to " .. choice)
    end
})

Targeting:CreateDropdown({
    Name = "Target Priority",
    Options = {"Closest", "Lowest Health", "Crosshair Distance"},
    CurrentOption = "Closest",
    Flag = "TargetPriority",
    Callback = function(choice)
        print("Target Priority set to " .. choice)
    end
})

-- Checks Section
local Checks = CombatTab:CreateSection("Checks", "Normal")

Checks:CreateToggle("Normal", {
    Name = "Wall Check",
    Flag = "WallCheck",
    Callback = function(v)
        print("Wall Check " .. (v and "ON" or "OFF"))
    end
})

Checks:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "TeamCheck",
    Callback = function(v)
        print("Team Check " .. (v and "ON" or "OFF"))
    end
})

-- FOV Section
local FOV = CombatTab:CreateSection("FOV", "Normal")

FOV:CreateToggle("Normal", {
    Name = "Show FOV",
    Flag = "ShowFOV",
    Callback = function(v)
        print("Show FOV " .. (v and "ON" or "OFF"))
    end
})

FOV:CreateSlider({
    Name = "FOV Radius",
    Value = {1, 360},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 120,
    Flag = "FOVRadius",
    Callback = function(v)
        print("FOV Radius set to " .. v)
    end
})

FOV:CreateColorPicker({
    Name = "FOV Color",
    Callback = function(color)
        print("FOV color changed to", color)
    end
})

-- Automation Section
local Automation = CombatTab:CreateSection("Automation", "Normal")

Automation:CreateToggle("Normal", {
    Name = "Auto Trigger",
    Flag = "AutoTrigger",
    Callback = function(v)
        print("Auto Trigger " .. (v and "ON" or "OFF"))
    end
})

Automation:CreateSlider({
    Name = "Trigger Delay",
    Value = {0, 500},
    Increment = 10,
    Suffix = "ms",
    CurrentValue = 50,
    Flag = "TriggerDelay",
    Callback = function(v)
        print("Trigger Delay set to " .. v .. "ms")
    end
})

-- Weapons Section
local Weapons = CombatTab:CreateSection("Weapons", "Normal")

Weapons:CreateToggle("Normal", {
    Name = "Auto Reload",
    Flag = "AutoReload",
    Callback = function(v)
        print("Auto Reload " .. (v and "ON" or "OFF"))
    end
})

-- =============================================================
--  VISUALS TAB
-- =============================================================

-- ESP Section
local ESP = VisualsTab:CreateSection("ESP", "Normal")

ESP:CreateToggle("Normal", {
    Name = "Enable ESP",
    Flag = "EnableESP",
    Callback = function(v)
        print("Enable ESP " .. (v and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Box ESP",
    Flag = "BoxESP",
    Callback = function(v)
        print("Box ESP " .. (v and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Name ESP",
    Flag = "NameESP",
    Callback = function(v)
        print("Name ESP " .. (v and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Distance ESP",
    Flag = "DistanceESP",
    Callback = function(v)
        print("Distance ESP " .. (v and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Weapon ESP",
    Flag = "WeaponESP",
    Callback = function(v)
        print("Weapon ESP " .. (v and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Health Bar",
    Flag = "HealthBar",
    Callback = function(v)
        print("Health Bar " .. (v and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Skeleton ESP",
    Flag = "SkeletonESP",
    Callback = function(v)
        print("Skeleton ESP " .. (v and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "TeamCheckESP",
    Callback = function(v)
        print("Team Check (ESP) " .. (v and "ON" or "OFF"))
    end
})

ESP:CreateToggle("Normal", {
    Name = "Friend Check",
    Flag = "FriendCheckESP",
    Callback = function(v)
        print("Friend Check (ESP) " .. (v and "ON" or "OFF"))
    end
})

ESP:CreateSlider({
    Name = "Distance Limit",
    Value = {10, 1000},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 500,
    Flag = "DistanceLimit",
    Callback = function(v)
        print("Distance Limit set to " .. v .. " studs")
    end
})

-- Effects Section
local Effects = VisualsTab:CreateSection("Effects", "Normal")

Effects:CreateToggle("Normal", {
    Name = "Highlight",
    Flag = "Highlight",
    Callback = function(v)
        print("Highlight " .. (v and "ON" or "OFF"))
    end
})

Effects:CreateToggle("Normal", {
    Name = "Chams",
    Flag = "Chams",
    Callback = function(v)
        print("Chams " .. (v and "ON" or "OFF"))
    end
})

Effects:CreateToggle("Normal", {
    Name = "Tracer Lines",
    Flag = "TracerLines",
    Callback = function(v)
        print("Tracer Lines " .. (v and "ON" or "OFF"))
    end
})

Effects:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Center", "Mouse"},
    CurrentOption = "Bottom",
    Flag = "TracerOrigin",
    Callback = function(choice)
        print("Tracer Origin set to " .. choice)
    end
})

-- =============================================================
--  PLAYER TAB
-- =============================================================

-- Character Section
local Character = PlayerTab:CreateSection("Character", "Normal")

Character:CreateToggle("Normal", {
    Name = "Enable Walk Speed",
    Flag = "EnableWalkSpeed",
    Callback = function(v)
        print("Enable Walk Speed " .. (v and "ON" or "OFF"))
    end
})

Character:CreateSlider({
    Name = "Walk Speed",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        print("Walk Speed set to " .. v)
    end
})

Character:CreateToggle("Normal", {
    Name = "Enable Jump Power",
    Flag = "EnableJumpPower",
    Callback = function(v)
        print("Enable Jump Power " .. (v and "ON" or "OFF"))
    end
})

Character:CreateSlider({
    Name = "Jump Power",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        print("Jump Power set to " .. v)
    end
})

Character:CreateToggle("Normal", {
    Name = "No Clip",
    Flag = "NoClip",
    Callback = function(v)
        print("No Clip " .. (v and "ON" or "OFF"))
    end
})

Character:CreateKeybind({
    Name = "No Clip Keybind",
    Flag = "NoClipKeybind",
    Keybind = "N",
    Type = "Press",
    Callback = function(active)
        print("No Clip key " .. (active and "pressed" or "released"))
    end
})

Character:CreateToggle("Normal", {
    Name = "Fly",
    Flag = "Fly",
    Callback = function(v)
        print("Fly " .. (v and "ON" or "OFF"))
    end
})

Character:CreateKeybind({
    Name = "Fly Keybind",
    Flag = "FlyKeybind",
    Keybind = "F",
    Type = "Press",
    Callback = function(active)
        print("Fly key " .. (active and "pressed" or "released"))
    end
})

-- Moderator Detector Section (kept as foldable)
local PlayerMods = PlayerTab:CreateSection("Moderator Detector", "Foldable")

PlayerMods:CreateToggle("Normal", {
    Name = "Detect Moderators",
    Flag = "ModDetect",
    Callback = function(v)
        print("Moderator detection " .. (v and "ON" or "OFF"))
    end
})

-- =============================================================
--  UTILITIES TAB
-- =============================================================

-- Teleportation Section
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

-- Miscellaneous Section
local Miscellaneous = UtilitiesTab:CreateSection("Miscellaneous", "Normal")

Miscellaneous:CreateButton({
    Name = "Become A Zombie",
    Callback = function()
        print("Became a zombie!")
    end
})

Miscellaneous:CreateToggle("Normal", {
    Name = "Moderator Detector",
    Flag = "ModDetectUtil",
    Callback = function(v)
        print("Moderator Detector " .. (v and "ON" or "OFF"))
    end
})

-- Anti AFK Section
local AntiAFK = UtilitiesTab:CreateSection("Anti AFK", "Normal")

AntiAFK:CreateToggle("Normal", {
    Name = "Enable Anti AFK",
    Flag = "AntiAFK",
    Callback = function(v)
        print("Anti AFK " .. (v and "ON" or "OFF"))
    end
})

-- =============================================================
--  SETTINGS TAB
-- =============================================================

-- Interface Section
local Interface = SettingsTab:CreateSection("Interface", "Normal")

-- Fixed: toggles on every press (no if active)
Interface:CreateKeybind({
    Name = "Toggle Menu Key",
    Flag = "ToggleMenuKey",
    Keybind = "LeftAlt",
    Type = "Press",
    Callback = function(active)
        print("Toggle UI triggered")
        Matrice.UI:ToggleUI()
    end
})

-- Matrice Hub Info Card
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

-- Paragraph for version and changelog
Interface:CreateParagraph({
    Title = "Version " .. gameVersion,
    Description = "Changelog:\n" .. gameChangelog
})

print("SCP:RP UI loaded.")