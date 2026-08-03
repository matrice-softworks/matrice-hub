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

-- ----------------------------------------------------------------------
-- SPOOFED CHARACTER FUNCTIONS (WalkSpeed, JumpPower, NoClip, Fly)
-- ----------------------------------------------------------------------
local cloneref = cloneref or function(...) return ... end
local Players = cloneref(game:GetService("Players"))
local lp = Players.LocalPlayer or Players:WaitForChild("LocalPlayer")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Spoof = {}
Spoof.WalkSpeed = {}
Spoof.JumpPower = {}
Spoof.NoClip = {}
Spoof.Fly = {}

-- helpers
local function GetDebugIdHandler()
    local handler = Instance.new("BindableFunction")
    handler.OnInvoke = function(obj) return obj:GetDebugId() end
    return handler
end

local function GetHumanoid()
    local char = lp.Character
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function GetRootPart()
    local char = lp.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- WalkSpeed spoof (using provided method)
do
    local TempHumanoid = Instance.new("Humanoid")
    local GetDebugId = GetDebugIdHandler()
    local cached = {}
    local CurrentHumanoid
    local indexhook, newindexhook

    local function GetWalkSpeed(obj)
        TempHumanoid.WalkSpeed = obj
        return TempHumanoid.WalkSpeed
    end

    indexhook = hookmetamethod(game, "__index", function(self, index)
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
            local id = GetDebugId(self)
            local entry = cached[id]
            if self:IsDescendantOf(lp.Character) or entry then
                if index == "WalkSpeed" then
                    if not entry then
                        entry = { current = self.WalkSpeed, last = nil }
                        cached[id] = entry
                    end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    return entry.last or entry.current
                end
            end
        end
        return indexhook(self, index)
    end)

    newindexhook = hookmetamethod(game, "__newindex", function(self, index, value)
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
            local id = GetDebugId(self)
            local entry = cached[id]
            if self:IsDescendantOf(lp.Character) or entry then
                if index == "WalkSpeed" then
                    if not entry then
                        entry = { current = self.WalkSpeed, last = nil }
                        cached[id] = entry
                    end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    entry.last = GetWalkSpeed(value)
                    return CurrentHumanoid.WalkSpeed
                end
            end
        end
        return newindexhook(self, index, value)
    end)

    function Spoof.WalkSpeed:Set(speed)
        local h = GetHumanoid()
        if h then
            local id = GetDebugId(h)
            local entry = cached[id]
            if not entry then
                entry = { current = h.WalkSpeed, last = nil }
                cached[id] = entry
            end
            local connections = {}
            local function DisableConnection(conn)
                if conn.State then conn:Disable() table.insert(connections, conn) end
            end
            for _, conn in getconnections(h.Changed) do DisableConnection(conn) end
            for _, conn in getconnections(h:GetPropertyChangedSignal("WalkSpeed")) do DisableConnection(conn) end
            h.WalkSpeed = speed
            for _, conn in connections do conn:Enable() end
        end
    end

    function Spoof.WalkSpeed:Restore()
        local h = GetHumanoid()
        if h then
            local id = GetDebugId(h)
            local entry = cached[id]
            if entry then
                Spoof.WalkSpeed:Set(entry.last or entry.current)
            end
        end
    end

    function Spoof.WalkSpeed:Disable()
        Spoof.WalkSpeed:Restore()
        -- reset hooks? not needed since we keep them active
    end
end

-- JumpPower spoof (same pattern as WalkSpeed)
do
    local TempHumanoid = Instance.new("Humanoid")
    local GetDebugId = GetDebugIdHandler()
    local cached = {}
    local CurrentHumanoid
    local indexhook, newindexhook

    local function GetJumpPower(obj)
        TempHumanoid.JumpPower = obj
        return TempHumanoid.JumpPower
    end

    indexhook = hookmetamethod(game, "__index", function(self, index)
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
            local id = GetDebugId(self)
            local entry = cached[id]
            if self:IsDescendantOf(lp.Character) or entry then
                if index == "JumpPower" then
                    if not entry then
                        entry = { current = self.JumpPower, last = nil }
                        cached[id] = entry
                    end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    return entry.last or entry.current
                end
            end
        end
        return indexhook(self, index)
    end)

    newindexhook = hookmetamethod(game, "__newindex", function(self, index, value)
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
            local id = GetDebugId(self)
            local entry = cached[id]
            if self:IsDescendantOf(lp.Character) or entry then
                if index == "JumpPower" then
                    if not entry then
                        entry = { current = self.JumpPower, last = nil }
                        cached[id] = entry
                    end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    entry.last = GetJumpPower(value)
                    return CurrentHumanoid.JumpPower
                end
            end
        end
        return newindexhook(self, index, value)
    end)

    function Spoof.JumpPower:Set(speed)
        local h = GetHumanoid()
        if h then
            local id = GetDebugId(h)
            local entry = cached[id]
            if not entry then
                entry = { current = h.JumpPower, last = nil }
                cached[id] = entry
            end
            local connections = {}
            local function DisableConnection(conn)
                if conn.State then conn:Disable() table.insert(connections, conn) end
            end
            for _, conn in getconnections(h.Changed) do DisableConnection(conn) end
            for _, conn in getconnections(h:GetPropertyChangedSignal("JumpPower")) do DisableConnection(conn) end
            h.JumpPower = speed
            for _, conn in connections do conn:Enable() end
        end
    end

    function Spoof.JumpPower:Restore()
        local h = GetHumanoid()
        if h then
            local id = GetDebugId(h)
            local entry = cached[id]
            if entry then
                Spoof.JumpPower:Set(entry.last or entry.current)
            end
        end
    end
end

-- NoClip spoof (simple collision toggle)
do
    local NoclipActive = false
    local NoclipConnection
    local function UpdateNoclip()
        local root = GetRootPart()
        if root then
            root.CanCollide = not NoclipActive
        end
    end
    function Spoof.NoClip:Set(state)
        NoclipActive = state
        if NoclipConnection then NoclipConnection:Disconnect() end
        if state then
            NoclipConnection = RunService.Heartbeat:Connect(UpdateNoclip)
        else
            NoclipConnection = nil
            UpdateNoclip()
        end
    end
    function Spoof.NoClip:Toggle()
        Spoof.NoClip:Set(not NoclipActive)
    end
end

-- Fly spoof (BodyVelocity)
do
    local FlyActive = false
    local FlyConnection, FlyBV
    local FlySpeed = 50

    local function CreateFlyBV()
        local root = GetRootPart()
        if not root then return end
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1, 1, 1) * 1e6
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = root
        return bv
    end

    local function UpdateFly()
        if not FlyActive then return end
        local root = GetRootPart()
        if not root then return end
        local direction = Vector3.new()
        local forward = root.CFrame.LookVector
        local right = root.CFrame.RightVector
        local up = root.CFrame.UpVector

        local move = Vector3.new(
            (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0),
            (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
        )
        direction = (forward * move.Z + right * move.X + up * move.Y).Unit * FlySpeed
        if FlyBV then
            FlyBV.Velocity = direction
        end
    end

    function Spoof.Fly:Set(state)
        FlyActive = state
        if FlyConnection then FlyConnection:Disconnect() end
        if FlyBV then FlyBV:Destroy() end
        if state then
            FlyBV = CreateFlyBV()
            FlyConnection = RunService.Heartbeat:Connect(UpdateFly)
        else
            FlyBV = nil
            FlyConnection = nil
        end
    end

    function Spoof.Fly:SetSpeed(speed)
        FlySpeed = speed
    end
end

-- ----------------------------------------------------------------------
-- PLAYER TAB UI ELEMENTS (using spoofed functions)
-- ----------------------------------------------------------------------
local Character = PlayerTab:CreateSection("Character", "Normal")

local walkSpeedEnabled = false
local jumpPowerEnabled = false
local noClipEnabled = false
local flyEnabled = false

Character:CreateToggle("Normal", {
    Name = "Enable Walk Speed",
    Flag = "EnableWalkSpeed",
    Callback = function(v)
        walkSpeedEnabled = v
        if v then
            local speed = tonumber(WalkSpeedSlider.CurrentValue) or 16
            Spoof.WalkSpeed:Set(speed)
        else
            Spoof.WalkSpeed:Restore()
        end
    end
})

local WalkSpeedSlider = Character:CreateSlider({
    Name = "Walk Speed",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        if walkSpeedEnabled then
            Spoof.WalkSpeed:Set(v)
        end
    end
})

Character:CreateToggle("Normal", {
    Name = "Enable Jump Power",
    Flag = "EnableJumpPower",
    Callback = function(v)
        jumpPowerEnabled = v
        if v then
            local power = tonumber(JumpSlider.CurrentValue) or 50
            Spoof.JumpPower:Set(power)
        else
            Spoof.JumpPower:Restore()
        end
    end
})

local JumpSlider = Character:CreateSlider({
    Name = "Jump Power",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        if jumpPowerEnabled then
            Spoof.JumpPower:Set(v)
        end
    end
})

Character:CreateToggle("Normal", {
    Name = "No Clip",
    Flag = "NoClip",
    Callback = function(v)
        noClipEnabled = v
        Spoof.NoClip:Set(v)
    end
})

Character:CreateKeybind({
    Name = "No Clip Keybind",
    Flag = "NoClipKeybind",
    Keybind = "N",
    Type = "Press",
    Callback = function(active)
        if active then
            noClipEnabled = not noClipEnabled
            Spoof.NoClip:Set(noClipEnabled)
        end
    end
})

Character:CreateToggle("Normal", {
    Name = "Fly",
    Flag = "Fly",
    Callback = function(v)
        flyEnabled = v
        Spoof.Fly:Set(v)
    end
})

Character:CreateKeybind({
    Name = "Fly Keybind",
    Flag = "FlyKeybind",
    Keybind = "F",
    Type = "Press",
    Callback = function(active)
        if active then
            flyEnabled = not flyEnabled
            Spoof.Fly:Set(flyEnabled)
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
        if active then Matrice.UI:ToggleUI() end
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