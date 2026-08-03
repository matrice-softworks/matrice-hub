-- Matrice Softworks

-- ============================================================
-- SERVICES
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- STARTUP CLEANUP
-- ============================================================

pcall(function()
    CoreGui.RobloxGui["CoreScripts/NetworkPause"]:Destroy()
end)

-- ============================================================
-- HUMAN OID SPOOFER (helper)
-- ============================================================

local HumanoidSpoofer = {}
do
    local cloneref = cloneref or function(x) return x end
    local lp = cloneref(Players)
    if not lp.LocalPlayer then
        lp:GetPropertyChangedSignal("LocalPlayer"):Wait()
    end
    lp = cloneref(lp.LocalPlayer)

    local split = string.split
    local GetDebugIdHandler = Instance.new("BindableFunction")
    local TempHumanoid = Instance.new("Humanoid")
    local cachedhumanoids = {}
    local CurrentHumanoid, newindexhook, indexhook
    local SpoofedProperties = {"WalkSpeed", "JumpPower"}

    GetDebugIdHandler.OnInvoke = function(obj)
        return obj:GetDebugId()
    end

    local function GetDebugId(obj)
        return GetDebugIdHandler:Invoke(obj)
    end

    local function GetPropertyValue(obj, prop)
        TempHumanoid[prop] = obj
        return TempHumanoid[prop]
    end

    function cachedhumanoids:cacheHumanoid(DebugId, Humanoid)
        local cache = {}
        for _, prop in ipairs(SpoofedProperties) do
            cache[prop] = {
                currentindex = indexhook(Humanoid, prop),
                lastnewindex = nil
            }
        end
        cachedhumanoids[DebugId] = cache
        return cache
    end

    indexhook = hookmetamethod(game, "__index", function(self, index)
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
            local DebugId = GetDebugId(self)
            local cached = cachedhumanoids[DebugId]
            if self:IsDescendantOf(lp.Character) or cached then
                if type(index) == "string" then
                    local clean = split(index, "\0")[1]
                    if table.find(SpoofedProperties, clean) then
                        if not cached then
                            cached = cachedhumanoids:cacheHumanoid(DebugId, self)
                        end
                        if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                            CurrentHumanoid = cloneref(self)
                        end
                        return cached[clean].lastnewindex or cached[clean].currentindex
                    end
                end
            end
        end
        return indexhook(self, index)
    end)

    newindexhook = hookmetamethod(game, "__newindex", function(self, index, newindex)
        if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
            local DebugId = GetDebugId(self)
            local cached = cachedhumanoids[DebugId]
            if self:IsDescendantOf(lp.Character) or cached then
                if type(index) == "string" then
                    local clean = split(index, "\0")[1]
                    if table.find(SpoofedProperties, clean) then
                        if not cached then
                            cached = cachedhumanoids:cacheHumanoid(DebugId, self)
                        end
                        if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                            CurrentHumanoid = cloneref(self)
                        end
                        cached[clean].lastnewindex = GetPropertyValue(newindex, clean)
                        return CurrentHumanoid[clean]
                    end
                end
            end
        end
        return newindexhook(self, index, newindex)
    end)

    function HumanoidSpoofer:Disable()
        self:RestoreAll()
        hookmetamethod(game, "__index", indexhook)
        hookmetamethod(game, "__newindex", newindexhook)
        GetDebugIdHandler:Destroy()
        TempHumanoid:Destroy()
        table.clear(self)
        getgenv().HumanoidSpoofer = nil
    end

    function HumanoidSpoofer:GetHumanoid()
        return CurrentHumanoid or (function()
            local char = lp.Character
            local Humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
            if Humanoid then
                cachedhumanoids:cacheHumanoid(Humanoid:GetDebugId(), Humanoid)
                return cloneref(Humanoid)
            end
        end)()
    end

    function HumanoidSpoofer:SetWalkSpeed(speed)
        local Humanoid = self:GetHumanoid()
        if Humanoid then
            local connections = {}
            for _, v in getconnections(Humanoid.Changed) do
                if v.State then v:Disable(); table.insert(connections, v) end
            end
            for _, v in getconnections(Humanoid:GetPropertyChangedSignal("WalkSpeed")) do
                if v.State then v:Disable(); table.insert(connections, v) end
            end
            Humanoid.WalkSpeed = speed
            for _, v in connections do v:Enable() end
        end
    end

    function HumanoidSpoofer:SetJumpPower(power)
        local Humanoid = self:GetHumanoid()
        if Humanoid then
            local connections = {}
            for _, v in getconnections(Humanoid.Changed) do
                if v.State then v:Disable(); table.insert(connections, v) end
            end
            for _, v in getconnections(Humanoid:GetPropertyChangedSignal("JumpPower")) do
                if v.State then v:Disable(); table.insert(connections, v) end
            end
            Humanoid.JumpPower = power
            for _, v in connections do v:Enable() end
        end
    end

    function HumanoidSpoofer:RestoreWalkSpeed()
        self:SetWalkSpeed(16)
    end

    function HumanoidSpoofer:RestoreJumpPower()
        self:SetJumpPower(50)
    end

    function HumanoidSpoofer:RestoreAll()
        self:RestoreWalkSpeed()
        self:RestoreJumpPower()
    end
end

getgenv().HumanoidSpoofer = HumanoidSpoofer

-- ============================================================
-- FEATURES (tables)
-- ============================================================

local ModeratorDetector = {
    Enabled = false,
    PlayerAddedConnection = nil,
    PlayerRemovingConnection = nil
}

local AntiAFK = {
    Enabled = false,
    Connection = nil
}

local WalkSpeed = {
    Enabled = false,
    Value = 16,
    Active = false
}

local JumpPower = {
    Enabled = false,
    Value = 50,
    Active = false
}

local NoClip = {
    Enabled = false,
    Connection = nil,
    Parts = {},
    Active = false
}

local Fly = {
    Enabled = false,
    Connection = nil,
    Speed = 50,
    Active = false
}

-- Toggle function references (for keybinds)
local WalkSpeedToggleRef, JumpPowerToggleRef, NoClipToggleRef, FlyToggleRef

-- ============================================================
-- TOGGLE FUNCTIONS
-- ============================================================

local function ToggleModeratorDetector(Enabled)
    ModeratorDetector.Enabled = Enabled
    if Enabled then
        Matrice.UI.Notify("Normal", {
            Title = "Moderator Detector",
            Content = "Enabled.",
            Duration = 3,
            Image = Matrice.Asset("info.png")
        })
        for _, Player in ipairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer then
                local ok, rank = pcall(Player.GetRankInGroup, Player, game.CreatorId)
                if ok and rank and rank >= 248 then
                    local role = Player:GetRoleInGroup(game.CreatorId)
                    Matrice.UI.Notify("Warning", {
                        Title = "Moderator Detector",
                        Content = Player.Name .. " (" .. role .. ") is in the server!",
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
        if ModeratorDetector.PlayerAddedConnection then
            ModeratorDetector.PlayerAddedConnection:Disconnect()
        end
        ModeratorDetector.PlayerAddedConnection = Players.PlayerAdded:Connect(function(Player)
            if ModeratorDetector.Enabled then
                task.wait(1)
                local ok, rank = pcall(Player.GetRankInGroup, Player, game.CreatorId)
                if ok and rank and rank >= 248 then
                    local role = Player:GetRoleInGroup(game.CreatorId)
                    Matrice.UI.Notify("Warning", {
                        Title = "Moderator Detector",
                        Content = Player.Name .. " (" .. role .. ") joined the server!",
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
        if ModeratorDetector.PlayerRemovingConnection then
            ModeratorDetector.PlayerRemovingConnection:Disconnect()
        end
        ModeratorDetector.PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(Player)
            if ModeratorDetector.Enabled then
                local ok, rank = pcall(Player.GetRankInGroup, Player, game.CreatorId)
                if ok and rank and rank >= 248 then
                    local role = Player:GetRoleInGroup(game.CreatorId)
                    Matrice.UI.Notify("Warning", {
                        Title = "Moderator Detector",
                        Content = Player.Name .. " (" .. role .. ") left the server!",
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
        if ModeratorDetector.PlayerAddedConnection then
            ModeratorDetector.PlayerAddedConnection:Disconnect()
            ModeratorDetector.PlayerAddedConnection = nil
        end
        if ModeratorDetector.PlayerRemovingConnection then
            ModeratorDetector.PlayerRemovingConnection:Disconnect()
            ModeratorDetector.PlayerRemovingConnection = nil
        end
        Matrice.UI.Notify("Normal", {
            Title = "Moderator Detector",
            Content = "Disabled.",
            Duration = 3,
            Image = Matrice.Asset("info.png")
        })
    end
end

local function ToggleAntiAFK(Enabled)
    AntiAFK.Enabled = Enabled
    if Enabled then
        if getconnections then
            for _, c in getconnections(LocalPlayer.Idled) do
                pcall(function()
                    c:Disable()
                    c:Disconnect()
                end)
            end
        end
        if AntiAFK.Connection then
            AntiAFK.Connection:Disconnect()
        end
        AntiAFK.Connection = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        Matrice.UI.Notify("Normal", {
            Title = "Anti AFK",
            Content = "Enabled.",
            Duration = 3,
            Image = Matrice.Asset("info.png")
        })
    else
        if AntiAFK.Connection then
            AntiAFK.Connection:Disconnect()
            AntiAFK.Connection = nil
        end
        Matrice.UI.Notify("Normal", {
            Title = "Anti AFK",
            Content = "Disabled.",
            Duration = 3,
            Image = Matrice.Asset("info.png")
        })
    end
end

local function ToggleWalkSpeed(Enabled)
    WalkSpeed.Enabled = Enabled
    WalkSpeed.Active = Enabled
    if WalkSpeed.Enabled and WalkSpeed.Active then
        HumanoidSpoofer.SetWalkSpeed(HumanoidSpoofer, WalkSpeed.Value)
        Matrice.UI.Notify("Normal", {
            Title = "Walk Speed",
            Content = "Set to " .. WalkSpeed.Value,
            Duration = 2,
            Image = Matrice.Asset("info.png")
        })
    else
        HumanoidSpoofer.RestoreWalkSpeed(HumanoidSpoofer)
        Matrice.UI.Notify("Normal", {
            Title = "Walk Speed",
            Content = "Restored.",
            Duration = 2,
            Image = Matrice.Asset("info.png")
        })
    end
end

local function ToggleJumpPower(Enabled)
    JumpPower.Enabled = Enabled
    JumpPower.Active = Enabled
    if JumpPower.Enabled and JumpPower.Active then
        HumanoidSpoofer.SetJumpPower(HumanoidSpoofer, JumpPower.Value)
        Matrice.UI.Notify("Normal", {
            Title = "Jump Power",
            Content = "Set to " .. JumpPower.Value,
            Duration = 2,
            Image = Matrice.Asset("info.png")
        })
    else
        HumanoidSpoofer.RestoreJumpPower(HumanoidSpoofer)
        Matrice.UI.Notify("Normal", {
            Title = "Jump Power",
            Content = "Restored.",
            Duration = 2,
            Image = Matrice.Asset("info.png")
        })
    end
end

local function ToggleNoClip(Enabled)
    NoClip.Enabled = Enabled
    NoClip.Active = Enabled
    if NoClip.Enabled and NoClip.Active then
        if NoClip.Connection then
            NoClip.Connection:Disconnect()
        end
        NoClip.Connection = RunService.Stepped:Connect(function()
            if not (NoClip.Enabled and NoClip.Active) then
                return
            end
            local Character = LocalPlayer.Character
            if not Character then
                return
            end
            for _, Part in ipairs(Character:GetDescendants()) do
                if Part:IsA("BasePart") and Part.CanCollide == true and Part.Name ~= "Head" then
                    Part.CanCollide = false
                    NoClip.Parts[Part] = true
                end
            end
        end)
        Matrice.UI.Notify("Normal", {
            Title = "No Clip",
            Content = "Enabled.",
            Duration = 2,
            Image = Matrice.Asset("info.png")
        })
    else
        if NoClip.Connection then
            NoClip.Connection:Disconnect()
            NoClip.Connection = nil
        end
        for Part, _ in pairs(NoClip.Parts) do
            if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part.Parent then
                Part.CanCollide = true
            end
        end
        NoClip.Parts = {}
        Matrice.UI.Notify("Normal", {
            Title = "No Clip",
            Content = "Disabled.",
            Duration = 2,
            Image = Matrice.Asset("info.png")
        })
    end
end

local function ToggleFly(Enabled)
    Fly.Enabled = Enabled
    Fly.Active = Enabled
    if Fly.Enabled and Fly.Active then
        local Character = LocalPlayer.Character
        if not Character then
            Character = LocalPlayer.CharacterAdded:Wait()
        end
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.PlatformStand = true
        end
        local Head = Character:FindFirstChild("Head")
        if Head then
            Head.Anchored = true
        end
        if Fly.Connection then
            Fly.Connection:Disconnect()
        end
        Fly.Connection = RunService.Heartbeat:Connect(function(dt)
            if not (Fly.Enabled and Fly.Active) then
                return
            end
            local Character = LocalPlayer.Character
            if not Character then
                return
            end
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            local Head = Character:FindFirstChild("Head")
            if not Humanoid or not Head then
                return
            end
            local MoveDirection = Humanoid.MoveDirection * (Fly.Speed * dt)
            local HeadCF = Head.CFrame
            local Cam = workspace.CurrentCamera
            local CamCF = Cam.CFrame
            local Offset = HeadCF:ToObjectSpace(CamCF).Position
            CamCF = CamCF * CFrame.new(-Offset.X, -Offset.Y, -Offset.Z + 1)
            local CamPos = CamCF.Position
            local HeadPos = HeadCF.Position
            local ObjSpace = CFrame.new(CamPos, Vector3.new(HeadPos.X, CamPos.Y, HeadPos.Z)):VectorToObjectSpace(MoveDirection)
            Head.CFrame = CFrame.new(HeadPos) * (CamCF - CamPos) * CFrame.new(ObjSpace)
        end)
        Matrice.UI.Notify("Normal", {
            Title = "Fly",
            Content = "Enabled.",
            Duration = 2,
            Image = Matrice.Asset("info.png")
        })
    else
        if Fly.Connection then
            Fly.Connection:Disconnect()
            Fly.Connection = nil
        end
        local Character = LocalPlayer.Character
        if Character then
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid.PlatformStand = false
            end
            local Head = Character:FindFirstChild("Head")
            if Head then
                Head.Anchored = false
            end
        end
        Matrice.UI.Notify("Normal", {
            Title = "Fly",
            Content = "Disabled.",
            Duration = 2,
            Image = Matrice.Asset("info.png")
        })
    end
end

-- ============================================================
-- UI CREATION
-- ============================================================

local Library = Matrice.UI.CreateLibrary({
    Name = "Matrice Hub - SCP:RP",
    Icon = Matrice.Asset("matrice.png")
})

Library.CreateAdvertisement(
    Library,
    "Rocheats",
    Matrice.Asset("rocheats_banner.png"),
    "https://rocheats.com/?ref=matrice",
    "Link copied to your clipboard. Thanks for supporting Matrice <3"
)

local CombatTab = Library.CreateTab(Library, "Combat", Matrice.Asset("crosshair.png"))
local VisualsTab = Library.CreateTab(Library, "Visuals", Matrice.Asset("palette.png"))
local PlayerTab = Library.CreateTab(Library, "Player", Matrice.Asset("user.png"))
local UtilitiesTab = Library.CreateTab(Library, "Utilities", Matrice.Asset("toolbox.png"))
local SettingsTab = Library.CreateTab(Library, "Settings", Matrice.Asset("settings.png"))

Library.SwitchTab(Library)

-- Combat tab
local Targeting = CombatTab.CreateSection(CombatTab, "Targeting", "Normal")
Targeting.CreateToggle(Targeting, "Normal", { Name = "Silent Aim", Flag = "SilentAim", Callback = function(e) print("Silent Aim " .. (e and "ON" or "OFF")) end })
Targeting.CreateDropdown(Targeting, { Name = "Hit Part", Options = {"Head", "Torso", "Random"}, CurrentOption = "Head", Flag = "HitPart", Callback = function(s) print("Hit Part set to " .. s) end })
Targeting.CreateSlider(Targeting, { Name = "Hit Chance", Value = {0, 100}, Increment = 1, Suffix = "%", CurrentValue = 100, Flag = "HitChance", Callback = function(v) print("Hit Chance set to " .. v .. "%") end })
Targeting.CreateDropdown(Targeting, { Name = "Target Selection", Options = {"Distance Priority", "Closest", "FOV Priority"}, CurrentOption = "Distance Priority", Flag = "TargetSelection", Callback = function(s) print("Target Selection set to " .. s) end })
Targeting.CreateDropdown(Targeting, { Name = "Target Priority", Options = {"Closest", "Lowest Health", "Crosshair Distance"}, CurrentOption = "Closest", Flag = "TargetPriority", Callback = function(s) print("Target Priority set to " .. s) end })
Targeting.CreateToggle(Targeting, "Normal", { Name = "Hitbox", Flag = "Hitbox", Callback = function(e) print("Hitbox " .. (e and "ON" or "OFF")) end })
Targeting.CreateSlider(Targeting, { Name = "Hitbox Size", Value = {1, 10}, Increment = 0.1, Suffix = "x", CurrentValue = 1, Flag = "HitboxSize", Callback = function(v) print("Hitbox Size set to " .. v) end })

local Checks = CombatTab.CreateSection(CombatTab, "Checks", "Normal")
Checks.CreateToggle(Checks, "Normal", { Name = "Wall Check", Flag = "WallCheck", Callback = function(e) print("Wall Check " .. (e and "ON" or "OFF")) end })
Checks.CreateToggle(Checks, "Normal", { Name = "Team Check", Flag = "TeamCheck", Callback = function(e) print("Team Check " .. (e and "ON" or "OFF")) end })

local FOV = CombatTab.CreateSection(CombatTab, "FOV", "Normal")
FOV.CreateToggle(FOV, "Normal", { Name = "Show FOV", Flag = "ShowFOV", Callback = function(e) print("Show FOV " .. (e and "ON" or "OFF")) end })
FOV.CreateSlider(FOV, { Name = "FOV Radius", Value = {1, 360}, Increment = 1, Suffix = "°", CurrentValue = 120, Flag = "FOVRadius", Callback = function(v) print("FOV Radius set to " .. v) end })
FOV.CreateColorPicker(FOV, { Name = "FOV Color", Callback = function(c) print("FOV color changed to", c) end })

local Automation = CombatTab.CreateSection(CombatTab, "Automation", "Normal")
Automation.CreateToggle(Automation, "Normal", { Name = "Auto Trigger", Flag = "AutoTrigger", Callback = function(e) print("Auto Trigger " .. (e and "ON" or "OFF")) end })
Automation.CreateSlider(Automation, { Name = "Trigger Delay", Value = {0, 500}, Increment = 10, Suffix = "ms", CurrentValue = 50, Flag = "TriggerDelay", Callback = function(v) print("Trigger Delay set to " .. v .. "ms") end })

local Weapons = CombatTab.CreateSection(CombatTab, "Weapons", "Normal")
Weapons.CreateToggle(Weapons, "Normal", { Name = "Auto Reload", Flag = "AutoReload", Callback = function(e) print("Auto Reload " .. (e and "ON" or "OFF")) end })

-- Visuals tab
local ESP = VisualsTab.CreateSection(VisualsTab, "ESP", "Normal")
ESP.CreateToggle(ESP, "Normal", { Name = "Enable ESP", Flag = "ESPEnabled", Callback = function(e) print("Enable ESP " .. (e and "ON" or "OFF")) end })
ESP.CreateToggle(ESP, "Normal", { Name = "Box ESP", Flag = "ESPBox", Callback = function(e) print("Box ESP " .. (e and "ON" or "OFF")) end })
ESP.CreateToggle(ESP, "Normal", { Name = "Name ESP", Flag = "ESPName", Callback = function(e) print("Name ESP " .. (e and "ON" or "OFF")) end })
ESP.CreateToggle(ESP, "Normal", { Name = "Distance ESP", Flag = "ESPDistance", Callback = function(e) print("Distance ESP " .. (e and "ON" or "OFF")) end })
ESP.CreateToggle(ESP, "Normal", { Name = "Weapon ESP", Flag = "ESPWeapon", Callback = function(e) print("Weapon ESP " .. (e and "ON" or "OFF")) end })
ESP.CreateToggle(ESP, "Normal", { Name = "Health Bar", Flag = "ESPHealthBar", Callback = function(e) print("Health Bar " .. (e and "ON" or "OFF")) end })
ESP.CreateToggle(ESP, "Normal", { Name = "Skeleton ESP", Flag = "ESPSkeleton", Callback = function(e) print("Skeleton ESP " .. (e and "ON" or "OFF")) end })
ESP.CreateToggle(ESP, "Normal", { Name = "Team Check", Flag = "ESPTeamCheck", Callback = function(e) print("Team Check (ESP) " .. (e and "ON" or "OFF")) end })
ESP.CreateToggle(ESP, "Normal", { Name = "Friend Check", Flag = "FriendCheck", Callback = function(e) print("Friend Check " .. (e and "ON" or "OFF")) end })
ESP.CreateSlider(ESP, { Name = "Distance Limit", Value = {10, 1000}, Increment = 10, Suffix = " studs", CurrentValue = 500, Flag = "DistanceLimit", Callback = function(v) print("Distance Limit set to " .. v .. " studs") end })

local Effects = VisualsTab.CreateSection(VisualsTab, "Effects", "Normal")
Effects.CreateToggle(Effects, "Normal", { Name = "Highlight", Flag = "Highlight", Callback = function(e) print("Highlight " .. (e and "ON" or "OFF")) end })
Effects.CreateToggle(Effects, "Normal", { Name = "Chams", Flag = "Chams", Callback = function(e) print("Chams " .. (e and "ON" or "OFF")) end })
Effects.CreateToggle(Effects, "Normal", { Name = "Tracer Lines", Flag = "TracerLines", Callback = function(e) print("Tracer Lines " .. (e and "ON" or "OFF")) end })
Effects.CreateDropdown(Effects, { Name = "Tracer Origin", Options = {"Bottom", "Center", "Mouse"}, CurrentOption = "Bottom", Flag = "TracerOrigin", Callback = function(s) print("Tracer Origin set to " .. s) end })

-- Player tab
local Character = PlayerTab.CreateSection(PlayerTab, "Character", "Normal")

WalkSpeedToggleRef = Character.CreateToggle(Character, "Normal", {
    Name = "Enable Walk Speed",
    Flag = "WalkSpeedEnabled",
    Callback = function(enabled)
        ToggleWalkSpeed(enabled)
    end
})
Character.CreateSlider(Character, {
    Name = "Walk Speed",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = WalkSpeed.Value,
    Flag = "WalkSpeed",
    Callback = function(value)
        WalkSpeed.Value = value
        if WalkSpeed.Enabled and WalkSpeed.Active then
            HumanoidSpoofer.SetWalkSpeed(HumanoidSpoofer, value)
        end
        print("Walk Speed set to " .. value)
    end
})

JumpPowerToggleRef = Character.CreateToggle(Character, "Normal", {
    Name = "Enable Jump Power",
    Flag = "JumpPowerEnabled",
    Callback = function(enabled)
        ToggleJumpPower(enabled)
    end
})
Character.CreateSlider(Character, {
    Name = "Jump Power",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = JumpPower.Value,
    Flag = "JumpPower",
    Callback = function(value)
        JumpPower.Value = value
        if JumpPower.Enabled and JumpPower.Active then
            HumanoidSpoofer.SetJumpPower(HumanoidSpoofer, value)
        end
        print("Jump Power set to " .. value)
    end
})

NoClipToggleRef = Character.CreateToggle(Character, "Normal", {
    Name = "No Clip",
    Flag = "NoClip",
    Callback = function(enabled)
        ToggleNoClip(enabled)
    end
})
Character.CreateKeybind(Character, {
    Name = "No Clip Keybind",
    Flag = "NoClipKeybind",
    Keybind = "N",
    Type = "Press",
    Callback = function(state)
        if state and NoClip.Enabled then
            NoClip.Active = not NoClip.Active
            ToggleNoClip(NoClip.Enabled)
        end
    end
})

FlyToggleRef = Character.CreateToggle(Character, "Normal", {
    Name = "Fly",
    Flag = "Fly",
    Callback = function(enabled)
        ToggleFly(enabled)
    end
})
Character.CreateKeybind(Character, {
    Name = "Fly Keybind",
    Flag = "FlyKeybind",
    Keybind = "F",
    Type = "Press",
    Callback = function(state)
        if state and Fly.Enabled then
            Fly.Active = not Fly.Active
            ToggleFly(Fly.Enabled)
        end
    end
})
Character.CreateSlider(Character, {
    Name = "Fly Speed",
    Value = {1, 200},
    Increment = 1,
    Suffix = "",
    CurrentValue = Fly.Speed,
    Flag = "FlySpeed",
    Callback = function(value)
        Fly.Speed = value
        print("Fly Speed set to " .. value)
    end
})

-- Utilities tab
local Miscellaneous = UtilitiesTab.CreateSection(UtilitiesTab, "Miscellaneous", "Normal")
Miscellaneous.CreateToggle(Miscellaneous, "Normal", {
    Name = "Moderator Detector",
    Flag = "ModeratorDetector",
    Callback = function(enabled)
        ToggleModeratorDetector(enabled)
    end
})

local AntiAFKSection = UtilitiesTab.CreateSection(UtilitiesTab, "Anti AFK", "Normal")
AntiAFKSection.CreateToggle(AntiAFKSection, "Normal", {
    Name = "Enable Anti AFK",
    Flag = "AntiAFK",
    Callback = function(enabled)
        ToggleAntiAFK(enabled)
    end
})

-- Settings tab
local Interface = SettingsTab.CreateSection(SettingsTab, "Interface", "Normal")
Interface.CreateKeybind(Interface, {
    Name = "Toggle Menu Key",
    Flag = "ToggleMenuKey",
    Keybind = "LeftAlt",
    Type = "Press",
    Callback = function(state)
        if state then
            Matrice.UI.ToggleUI()
        end
    end
})

local gameVersion = tostring((Matrice.Game and Matrice.Game.Info and Matrice.Game.Info.Version) or "N/A")
local gameChangelog = tostring((Matrice.Game and Matrice.Game.Info and Matrice.Game.Info.Changelog) or "No changelog available.")

Interface.CreateCard(Interface, {
    Title = "Matrice Hub - SCP:RP",
    Description = "A script hub packed with high-quality undetectable scripts",
    SecondaryTitle = "By Matrice Softworks",
    Image = Matrice.Asset("matrice.png"),
    Buttons = {
        Button1 = {
            Name = "Discord",
            Callback = function()
                setclipboard("https://discord.gg/matrice")
                Matrice.UI.Notify("Normal", {
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
                Matrice.UI.Notify("Normal", {
                    Title = "Copied!",
                    Content = "Link copied to your clipboard. Thanks for supporting Matrice <3",
                    Duration = 3,
                    Image = Matrice.Asset("globe.png")
                })
            end
        }
    }
})

Interface.CreateParagraph(Interface, {
    Title = "Version " .. gameVersion,
    Description = "Changelog:\n" .. gameChangelog
})

print("SCP:RP UI loaded.")