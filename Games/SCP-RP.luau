-- Matrice Softworks

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

local CombatTab   = Library:CreateTab("Combat",   Matrice.Asset("crosshair.png"))
local VisualsTab  = Library:CreateTab("Visuals",  Matrice.Asset("palette.png"))
local PlayerTab   = Library:CreateTab("Player",   Matrice.Asset("user.png"))
local UtilitiesTab = Library:CreateTab("Utilities", Matrice.Asset("toolbox.png"))
local SettingsTab = Library:CreateTab("Settings", Matrice.Asset("settings.png"))

Library:SwitchTab()

local Targeting = CombatTab:CreateSection("Targeting", "Normal")

Targeting:CreateToggle("Normal", {
    Name = "Silent Aim",
    Flag = "SilentAim",
    Callback = function(v) print("Silent Aim " .. (v and "ON" or "OFF")) end
})

Targeting:CreateDropdown({
    Name = "Hit Part",
    Options = {"Head", "Torso", "Random"},
    CurrentOption = "Head",
    Flag = "HitPart",
    Callback = function(choice) print("Hit Part set to " .. choice) end
})

Targeting:CreateSlider({
    Name = "Hit Chance",
    Value = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "HitChance",
    Callback = function(v) print("Hit Chance set to " .. v .. "%") end
})

Targeting:CreateDropdown({
    Name = "Target Selection",
    Options = {"Distance Priority", "Closest", "FOV Priority"},
    CurrentOption = "Distance Priority",
    Flag = "TargetSelection",
    Callback = function(choice) print("Target Selection set to " .. choice) end
})

Targeting:CreateDropdown({
    Name = "Target Priority",
    Options = {"Closest", "Lowest Health", "Crosshair Distance"},
    CurrentOption = "Closest",
    Flag = "TargetPriority",
    Callback = function(choice) print("Target Priority set to " .. choice) end
})

Targeting:CreateToggle("Normal", {
    Name = "Hitbox",
    Flag = "Hitbox",
    Callback = function(v) print("Hitbox " .. (v and "ON" or "OFF")) end
})

Targeting:CreateSlider({
    Name = "Hitbox Size",
    Value = {1, 10},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "HitboxSize",
    Callback = function(v) print("Hitbox Size set to " .. v) end
})

local Checks = CombatTab:CreateSection("Checks", "Normal")

Checks:CreateToggle("Normal", {
    Name = "Wall Check",
    Flag = "WallCheck",
    Callback = function(v) print("Wall Check " .. (v and "ON" or "OFF")) end
})

Checks:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "TeamCheck",
    Callback = function(v) print("Team Check " .. (v and "ON" or "OFF")) end
})

local FOV = CombatTab:CreateSection("FOV", "Normal")

FOV:CreateToggle("Normal", {
    Name = "Show FOV",
    Flag = "ShowFOV",
    Callback = function(v) print("Show FOV " .. (v and "ON" or "OFF")) end
})

FOV:CreateSlider({
    Name = "FOV Radius",
    Value = {1, 360},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 120,
    Flag = "FOVRadius",
    Callback = function(v) print("FOV Radius set to " .. v) end
})

FOV:CreateColorPicker({
    Name = "FOV Color",
    Callback = function(color) print("FOV color changed to", color) end
})

local Automation = CombatTab:CreateSection("Automation", "Normal")

Automation:CreateToggle("Normal", {
    Name = "Auto Trigger",
    Flag = "AutoTrigger",
    Callback = function(v) print("Auto Trigger " .. (v and "ON" or "OFF")) end
})

Automation:CreateSlider({
    Name = "Trigger Delay",
    Value = {0, 500},
    Increment = 10,
    Suffix = "ms",
    CurrentValue = 50,
    Flag = "TriggerDelay",
    Callback = function(v) print("Trigger Delay set to " .. v .. "ms") end
})

local Weapons = CombatTab:CreateSection("Weapons", "Normal")

Weapons:CreateToggle("Normal", {
    Name = "Auto Reload",
    Flag = "AutoReload",
    Callback = function(v) print("Auto Reload " .. (v and "ON" or "OFF")) end
})

local ESP = VisualsTab:CreateSection("ESP", "Normal")

ESP:CreateToggle("Normal", { Name = "Enable ESP", Flag = "EnableESP", Callback = function(v) print("Enable ESP " .. (v and "ON" or "OFF")) end })
ESP:CreateToggle("Normal", { Name = "Box ESP", Flag = "BoxESP", Callback = function(v) print("Box ESP " .. (v and "ON" or "OFF")) end })
ESP:CreateToggle("Normal", { Name = "Name ESP", Flag = "NameESP", Callback = function(v) print("Name ESP " .. (v and "ON" or "OFF")) end })
ESP:CreateToggle("Normal", { Name = "Distance ESP", Flag = "DistanceESP", Callback = function(v) print("Distance ESP " .. (v and "ON" or "OFF")) end })
ESP:CreateToggle("Normal", { Name = "Weapon ESP", Flag = "WeaponESP", Callback = function(v) print("Weapon ESP " .. (v and "ON" or "OFF")) end })
ESP:CreateToggle("Normal", { Name = "Health Bar", Flag = "HealthBar", Callback = function(v) print("Health Bar " .. (v and "ON" or "OFF")) end })
ESP:CreateToggle("Normal", { Name = "Skeleton ESP", Flag = "SkeletonESP", Callback = function(v) print("Skeleton ESP " .. (v and "ON" or "OFF")) end })
ESP:CreateToggle("Normal", { Name = "Team Check", Flag = "TeamCheckESP", Callback = function(v) print("Team Check (ESP) " .. (v and "ON" or "OFF")) end })
ESP:CreateToggle("Normal", { Name = "Friend Check", Flag = "FriendCheckESP", Callback = function(v) print("Friend Check (ESP) " .. (v and "ON" or "OFF")) end })
ESP:CreateSlider({
    Name = "Distance Limit",
    Value = {10, 1000},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = 500,
    Flag = "DistanceLimit",
    Callback = function(v) print("Distance Limit set to " .. v .. " studs") end
})

local Effects = VisualsTab:CreateSection("Effects", "Normal")

Effects:CreateToggle("Normal", { Name = "Highlight", Flag = "Highlight", Callback = function(v) print("Highlight " .. (v and "ON" or "OFF")) end })
Effects:CreateToggle("Normal", { Name = "Chams", Flag = "Chams", Callback = function(v) print("Chams " .. (v and "ON" or "OFF")) end })
Effects:CreateToggle("Normal", { Name = "Tracer Lines", Flag = "TracerLines", Callback = function(v) print("Tracer Lines " .. (v and "ON" or "OFF")) end })
Effects:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Center", "Mouse"},
    CurrentOption = "Bottom",
    Flag = "TracerOrigin",
    Callback = function(choice) print("Tracer Origin set to " .. choice) end
})

-- =============================
-- SPOOF ENGINE (unified)
-- =============================
local cloneref = cloneref or function(x) return x end
local Players = cloneref(game:GetService("Players"))
if not Players.LocalPlayer then Players:GetPropertyChangedSignal("LocalPlayer"):Wait() end
local lp = cloneref(Players.LocalPlayer)
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local function CreatePropertySpoof(property, defaultValue)
    local debugHandler = Instance.new("BindableFunction")
    local tempInstance = Instance.new("Humanoid")
    local cached = {}

    function debugHandler.OnInvoke(obj) return obj:GetDebugId() end
    local function GetDebugId(obj) return debugHandler:Invoke(obj) end

    local function GetSpoofedValue(obj)
        tempInstance[property] = obj
        return tempInstance[property]
    end

    local indexHook = hookmetamethod(game, "__index", function(self, index)
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
            local id = GetDebugId(self)
            local c = cached[id]
            if self:IsDescendantOf(lp.Character) or c then
                if type(index) == "string" and index == property then
                    if not c then
                        c = { original = self[property], spoofed = nil }
                        cached[id] = c
                    end
                    return c.spoofed or c.original
                end
            end
        end
        return indexHook(self, index)
    end)

    local newIndexHook = hookmetamethod(game, "__newindex", function(self, index, new)
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
            local id = GetDebugId(self)
            local c = cached[id]
            if self:IsDescendantOf(lp.Character) or c then
                if type(index) == "string" and index == property then
                    if not c then
                        c = { original = self[property], spoofed = nil }
                        cached[id] = c
                    end
                    c.spoofed = GetSpoofedValue(new)
                    return
                end
            end
        end
        return newIndexHook(self, index, new)
    end)

    local function Set(value)
        local humanoid = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then return end
        local id = GetDebugId(humanoid)
        local c = cached[id]
        if not c then
            c = { original = humanoid[property], spoofed = nil }
            cached[id] = c
        end
        c.spoofed = value
        humanoid[property] = value
    end

    local function Reset()
        local humanoid = lp.Character and lp.Character:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then return end
        local id = GetDebugId(humanoid)
        local c = cached[id]
        if c then
            humanoid[property] = c.original
            c.spoofed = nil
        end
    end

    local function Disable()
        Reset()
        debugHandler:Destroy()
        tempInstance:Destroy()
        hookmetamethod(game, "__index", indexHook)
        hookmetamethod(game, "__newindex", newIndexHook)
    end

    return { Set = Set, Reset = Reset, Disable = Disable }
end

-- Feature factory for toggles (NoClip, Fly)
local function CreateToggleFeature(enableCallback, disableCallback)
    local enabled = false
    local function Enable()
        if not enabled then
            enabled = true
            enableCallback()
        end
    end
    local function Disable()
        if enabled then
            enabled = false
            disableCallback()
        end
    end
    local function Toggle()
        if enabled then Disable() else Enable() end
    end
    return { Enable = Enable, Disable = Disable, Toggle = Toggle, IsEnabled = function() return enabled end }
end

-- WalkSpeed & JumpPower spoofers
local walkSpoof = CreatePropertySpoof("WalkSpeed", 16)
local jumpSpoof = CreatePropertySpoof("JumpPower", 50)

-- NoClip
local noclipConnection = nil
local function enableNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Heartbeat:Connect(function()
        local char = lp.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end
local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    local char = lp.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end
local noclipFeature = CreateToggleFeature(enableNoclip, disableNoclip)

-- Fly
local flyBodyVelocity = nil
local flyConnection = nil
local flySpeed = 50
local function enableFly()
    if flyConnection then flyConnection:Disconnect() end
    local char = lp.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        if not flyBodyVelocity then
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 1e9
            flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            flyBodyVelocity.Parent = hrp
        else
            flyBodyVelocity.Parent = hrp
        end
        flyConnection = RunService.Heartbeat:Connect(function()
            if not flyFeature.IsEnabled() then return end
            local move = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move + Vector3.new(0, -1, 0) end
            if move.Magnitude > 0 then
                move = move.Unit * flySpeed
            end
            if hrp and flyBodyVelocity then
                flyBodyVelocity.Velocity = move
            end
        end)
    end
end
local function disableFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
end
local flyFeature = CreateToggleFeature(enableFly, disableFly)

-- =============================================================
--  PLAYER TAB UI
-- =============================================================
local Character = PlayerTab:CreateSection("Character", "Normal")

-- Walk Speed
local currentWalkSpeed = 16
local walkSpeedToggle
local walkSpeedSlider

walkSpeedToggle = Character:CreateToggle("Normal", {
    Name = "Enable Walk Speed",
    Flag = "EnableWalkSpeed",
    Callback = function(v)
        if v then walkSpoof.Set(currentWalkSpeed) else walkSpoof.Reset() end
    end
})

walkSpeedSlider = Character:CreateSlider({
    Name = "Walk Speed",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        currentWalkSpeed = v
        if walkSpeedToggle and walkSpeedToggle.CurrentValue then
            walkSpoof.Set(v)
        end
    end
})

-- Jump Power
local currentJumpPower = 50
local jumpPowerToggle
local jumpPowerSlider

jumpPowerToggle = Character:CreateToggle("Normal", {
    Name = "Enable Jump Power",
    Flag = "EnableJumpPower",
    Callback = function(v)
        if v then jumpSpoof.Set(currentJumpPower) else jumpSpoof.Reset() end
    end
})

jumpPowerSlider = Character:CreateSlider({
    Name = "Jump Power",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        currentJumpPower = v
        if jumpPowerToggle and jumpPowerToggle.CurrentValue then
            jumpSpoof.Set(v)
        end
    end
})

-- No Clip
local noclipToggle = Character:CreateToggle("Normal", {
    Name = "No Clip",
    Flag = "NoClip",
    Callback = function(v)
        if v then noclipFeature.Enable() else noclipFeature.Disable() end
    end
})

Character:CreateKeybind({
    Name = "No Clip Keybind",
    Flag = "NoClipKeybind",
    Keybind = "N",
    Type = "Press",
    Callback = function(active)
        if active then
            noclipFeature.Toggle()
            if noclipToggle then noclipToggle:SetToggle(noclipFeature.IsEnabled()) end
        end
    end
})

-- Fly
local flyToggle = Character:CreateToggle("Normal", {
    Name = "Fly",
    Flag = "Fly",
    Callback = function(v)
        if v then flyFeature.Enable() else flyFeature.Disable() end
    end
})

Character:CreateKeybind({
    Name = "Fly Keybind",
    Flag = "FlyKeybind",
    Keybind = "F",
    Type = "Press",
    Callback = function(active)
        if active then
            flyFeature.Toggle()
            if flyToggle then flyToggle:SetToggle(flyFeature.IsEnabled()) end
        end
    end
})

local PlayerMods = PlayerTab:CreateSection("Moderator Detector", "Foldable")

PlayerMods:CreateToggle("Normal", {
    Name = "Detect Moderators",
    Flag = "ModDetect",
    Callback = function(v) print("Moderator detection " .. (v and "ON" or "OFF")) end
})

local Teleportation = UtilitiesTab:CreateSection("Teleportation", "Normal")

Teleportation:CreateButton({
    Name = "Class D-Zone",
    Callback = function() print("Teleported to Class D-Zone") end
})

Teleportation:CreateButton({
    Name = "Security Department",
    Callback = function() print("Teleported to Security Department") end
})

local Miscellaneous = UtilitiesTab:CreateSection("Miscellaneous", "Normal")

Miscellaneous:CreateButton({
    Name = "Become A Zombie",
    Callback = function() print("Became a zombie!") end
})

Miscellaneous:CreateToggle("Normal", {
    Name = "Moderator Detector",
    Flag = "ModDetectUtil",
    Callback = function(v) print("Moderator Detector " .. (v and "ON" or "OFF")) end
})

local AntiAFK = UtilitiesTab:CreateSection("Anti AFK", "Normal")

AntiAFK:CreateToggle("Normal", {
    Name = "Enable Anti AFK",
    Flag = "AntiAFK",
    Callback = function(v) print("Anti AFK " .. (v and "ON" or "OFF")) end
})

local Interface = SettingsTab:CreateSection("Interface", "Normal")

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