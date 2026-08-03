-- =============================================================
--  SCP: Roleplay – Example UI using AuraIS
-- =============================================================

-- Create main window
local Library = Matrice.UI:CreateLibrary({
    Name = "Matrice Hub",
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
local PlayerTab   = Library:CreateTab("Player",   Matrice.Asset("user-shield.png"))
local MiscTab     = Library:CreateTab("Misc",     Matrice.Asset("toolbox.png"))
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
local VisualsESP   = VisualsTab:CreateSection("ESP", "Normal")
local VisualsChams = VisualsTab:CreateSection("Chams", "Foldable")
local VisualsWorld = VisualsTab:CreateSection("World", "Foldable")

VisualsESP:CreateToggle("Normal", {
    Name = "Box ESP",
    Flag = "BoxESP",
    Callback = function(v) print("Box ESP " .. (v and "ON" or "OFF")) end
})

VisualsESP:CreateToggle("Normal", {
    Name = "Skeleton ESP",
    Flag = "SkeletonESP",
    Callback = function(v) print("Skeleton ESP " .. (v and "ON" or "OFF")) end
})

VisualsESP:CreateToggle("Normal", {
    Name = "Health Bars",
    Flag = "HealthBars",
    Callback = function(v) print("Health Bars " .. (v and "ON" or "OFF")) end
})

VisualsESP:CreateToggle("Normal", {
    Name = "Tracers",
    Flag = "Tracers",
    Callback = function(v) print("Tracers " .. (v and "ON" or "OFF")) end
})

VisualsESP:CreateColorPicker({
    Name = "ESP Color",
    Callback = function(color)
        print("ESP color changed to", color)
    end
})

VisualsChams:CreateToggle("Normal", {
    Name = "Chams",
    Flag = "Chams",
    Callback = function(v) print("Chams " .. (v and "ON" or "OFF")) end
})

VisualsChams:CreateDropdown({
    Name = "Chams Material",
    Options = {"ForceField", "Glass", "Neon", "Plastic"},
    CurrentOption = "ForceField",
    Flag = "ChamsMaterial",
    Callback = function(choice)
        print("Chams material set to " .. choice)
    end
})

VisualsWorld:CreateToggle("Normal", {
    Name = "Greyscale World",
    Flag = "GreyscaleWorld",
    Callback = function(v) print("Greyscale World " .. (v and "ON" or "OFF")) end
})

-- =============================================================
--  PLAYER TAB
-- =============================================================
local PlayerGeneral = PlayerTab:CreateSection("General", "Normal")
local PlayerMods    = PlayerTab:CreateSection("Moderator Detector", "Foldable")

PlayerMods:CreateToggle("Normal", {
    Name = "Detect Moderators",
    Flag = "ModDetect",
    Callback = function(v)
        print("Moderator detection " .. (v and "ON" or "OFF"))
    end
})

PlayerGeneral:CreateTextbox({
    Name = "Your Name Override",
    PlaceholderText = "Enter custom name",
    Flag = "CustomName",
    Callback = function(text)
        print("Custom name set to " .. text)
    end
})

PlayerGeneral:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        Library:Notify({
            Title = "Not Implemented",
            Content = "Teleport functionality coming soon.",
            Duration = 3
        })
    end
})

-- =============================================================
--  MISC TAB
-- =============================================================
local MiscGeneral = MiscTab:CreateSection("General", "Normal")
local MiscAds     = MiscTab:CreateSection("Advertisements", "Foldable")

MiscGeneral:CreateButton({
    Name = "Copy Discord Link",
    Callback = function()
        setclipboard("https://discord.gg/matrice")
        Matrice.UI:Notify("Normal", {
            Title = "Copied!",
            Content = "Discord link copied to clipboard.",
            Duration = 2,
            Image = Matrice.Asset("clipboard.png")
        })
    end
})

MiscAds:CreateLabel({
    Description = "Support us by checking our ad below!"
})

MiscAds:CreateCard({
    Title = "Rocheats",
    Description = "Best cheating tools for SCP:RP",
    SecondaryTitle = "v2.0",
    Image = Matrice.Asset("rocheats_banner.png"),
    Buttons = {
        Button1 = {
            Name = "Visit Website",
            Callback = function()
                setclipboard("https://rocheats.com/?ref=matrice")
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

-- =============================================================
--  SETTINGS TAB
-- =============================================================
local SettingsGeneral = SettingsTab:CreateSection("General", "Normal")
local SettingsConfig  = SettingsTab:CreateSection("Configuration", "Foldable")

SettingsGeneral:CreateToggle("Normal", {
    Name = "Show UI on Startup",
    Flag = "ShowUIOnStartup",
    CurrentValue = true,
    Callback = function(v)
        print("Show UI on startup " .. (v and "ON" or "OFF"))
    end
})

SettingsConfig:CreateButton({
    Name = "Reset All Settings",
    Callback = function()
        Library:Notify({
            Title = "Reset Settings",
            Content = "Are you sure you want to reset all settings?",
            Duration = 5,
            Actions = {
                {
                    Name = "Yes",
                    Callback = function()
                        print("Settings reset!")
                    end
                },
                {
                    Name = "No",
                    Callback = function()
                        print("Reset cancelled.")
                    end
                }
            }
        })
    end
})

SettingsConfig:CreateButton({
    Name = "Save Configuration",
    Callback = function()
        Matrice.UI:Notify("Normal", {
            Title = "Saved",
            Content = "Configuration saved successfully!",
            Duration = 2,
            Image = Matrice.Asset("info.png")
        })
    end
})

print("SCP:RP UI loaded.")