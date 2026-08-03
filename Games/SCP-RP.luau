-- =============================================================
--  SCP: Roleplay – Example UI using AuraIS
-- =============================================================

local AuraIS = Matrice.UI
local Library

local function Asset(name)
    return Matrice.Asset(name .. ".png")
end

-- Create main window
Library = AuraIS:CreateLibrary({
    Name = "Matrice · SCP:RP",
    Icon = Asset("matrice")
})

-- Ads
Library:CreateAdvertisement(
    "Matrice Hub",
    Asset("matrice-softworks"),
    "https://discord.gg/matrice",
    "Join our Discord!"
)

Library:CreateAdvertisement(
    "SCP:RP Tools",
    Asset("toolbox"),
    "https://example.com",
    "Check out our tools"
)

-- =============================================================
--  CREATE TABS
-- =============================================================
local CombatTab   = Library:CreateTab("Combat",   Asset("crosshair"))
local VisualsTab  = Library:CreateTab("Visuals",  Asset("palette"))
local PlayerTab   = Library:CreateTab("Player",   Asset("user-shield"))
local MiscTab     = Library:CreateTab("Misc",     Asset("toolbox"))
local SettingsTab = Library:CreateTab("Settings", Asset("settings"))

-- ✅ Activate the first tab so content appears
Library:SwitchTab()

-- =============================================================
--  COMBAT TAB
-- =============================================================
local CombatGeneral = CombatTab:CreateSection("General", "Normal")
local CombatAimbot   = CombatTab:CreateSection("Aimbot",   "Foldable")
local CombatTrigger  = CombatTab:CreateSection("Triggerbot", "Foldable")

CombatGeneral:CreateToggle("Normal", {
    Name = "Silent Aim",
    Flag = "SilentAim",
    Callback = function(v)
        print("Silent Aim " .. (v and "ON" or "OFF"))
    end
})

CombatGeneral:CreateSlider({
    Name = "Aim FOV",
    Value = {1, 360},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 120,
    Flag = "AimFOV",
    Callback = function(v)
        print("FOV set to " .. v)
    end
})

CombatGeneral:CreateKeybind({
    Name = "Aim Key",
    Flag = "AimKey",
    Keybind = "RightShift",
    Type = "Hold",
    Callback = function(active)
        print("Aim key " .. (active and "held" or "released"))
    end
})

CombatTrigger:CreateToggle("Normal", {
    Name = "Triggerbot",
    Flag = "Triggerbot",
    Callback = function(v)
        print("Triggerbot " .. (v and "ON" or "OFF"))
    end
})

CombatTrigger:CreateSlider({
    Name = "Trigger Delay",
    Value = {0, 500},
    Increment = 10,
    Suffix = "ms",
    CurrentValue = 50,
    Flag = "TriggerDelay",
    Callback = function(v)
        print("Trigger delay " .. v)
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
	Name = "Dropdown Example",
	Options = {"Cake", "Pie", "Milkshake", "Cupcake"},
	CurrentOption = {"Option 1"},
	MultipleOptions = false,
	Flag = "Dropdown1",
	Callback = function(v)
		print(v)
	end,
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
        AuraIS:Notify("Normal", {
            Title = "Copied!",
            Content = "Discord link copied to clipboard.",
            Duration = 2,
            Image = Asset("clipboard")
        })
    end
})

MiscAds:CreateLabel({
    Description = "Support us by checking our ads below!"
})

MiscAds:CreateCard({
    Title = "Matrice Hub",
    Description = "Best SCP:RP scripts",
    SecondaryTitle = "v0.1.0",
    Image = Asset("matrice-softworks"),
    Buttons = {
        Button1 = {
            Name = "Website",
            Callback = function()
                setclipboard("https://matrice-softworks.com")
                AuraIS:Notify("Normal", {
                    Title = "Copied!",
                    Content = "Website URL copied.",
                    Duration = 2,
                    Image = Asset("globe")
                })
            end
        },
        Button2 = {
            Name = "Discord",
            Callback = function()
                setclipboard("https://discord.gg/matrice")
                AuraIS:Notify("Normal", {
                    Title = "Copied!",
                    Content = "Discord invite copied.",
                    Duration = 2,
                    Image = Asset("discord")
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
        AuraIS:Notify("Normal", {
            Title = "Saved",
            Content = "Configuration saved successfully!",
            Duration = 2,
            Image = Asset("info")
        })
    end
})

print("SCP:RP UI loaded.")