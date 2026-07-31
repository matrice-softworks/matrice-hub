--// Matrice – SCP: Roleplay (UI Only)
local UI = Matrice.UI

local Library = UI:CreateLibrary({
    Name = "Matrice v" .. Matrice.Version .. " - UI Test",
    Icon = "rbxassetid://12974454446"
})

-- Tabs (only UI elements)
local HomeTab = Library:CreateTab("Home", "rbxassetid://12974454446")
local SettingsTab = Library:CreateTab("Settings", "rbxassetid://12974454446")

-- Home Section
local HomeSection = HomeTab:CreateSection("Welcome", "Normal")
HomeSection:CreateLabel({ Description = "This is a UI‑only test. No ESP, no Silent Aim." })
HomeSection:CreateDivider()
HomeSection:CreateParagraph({
    Title = "About",
    Description = "If first‑person camera works here, the UI is not the culprit."
})

-- Settings Section (just to show UI elements)
local SettingsSection = SettingsTab:CreateSection("UI Settings", "Normal")
SettingsSection:CreateKeybind({
    Name = "Toggle UI",
    Keybind = "RightControl",
    Type = "Press",
    Callback = function() UI:ToggleUI() end
})

UI:Notify("Normal", {
    Title = "UI Only Test",
    Content = "Loaded. Test first‑person camera.",
    Duration = 5,
    Image = "rbxassetid://12974454446"
})