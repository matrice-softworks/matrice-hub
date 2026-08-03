-- Matrice Softworks

-- ============================================================
-- SERVICES
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

-- ============================================================
-- REFERENCES
-- ============================================================

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- STARTUP CLEANUP
-- ============================================================

pcall(function()
    CoreGui.RobloxGui["CoreScripts/NetworkPause"]:Destroy()
end)

-- ============================================================
-- WALKSPEED SPOOF (complex method)
-- ============================================================

local WalkSpeedSpoof = getgenv().WalkSpeedSpoof
local Disable = WalkSpeedSpoof and WalkSpeedSpoof.Disable
if Disable then Disable() end

local cloneref = cloneref or function(...) return ... end

WalkSpeedSpoof = {}

local PlayersService = cloneref(Players)
if not PlayersService.LocalPlayer then
    PlayersService:GetPropertyChangedSignal("LocalPlayer"):Wait()
end
local lp = cloneref(PlayersService.LocalPlayer)

local split = string.split

local GetDebugIdHandler = Instance.new("BindableFunction")
local TempHumanoid = Instance.new("Humanoid")

local cachedhumanoids = {}

local CurrentHumanoid
local newindexhook
local indexhook

function GetDebugIdHandler.OnInvoke(obj)
    return obj:GetDebugId()
end

local function GetDebugId(obj)
    return GetDebugIdHandler:Invoke(obj)
end

local function GetWalkSpeed(obj)
    TempHumanoid.WalkSpeed = obj
    return TempHumanoid.WalkSpeed
end

function cachedhumanoids:cacheHumanoid(DebugId, Humanoid)
    cachedhumanoids[DebugId] = {
        currentindex = indexhook(Humanoid, "WalkSpeed"),
        lastnewindex = nil
    }
    return self[DebugId]
end

indexhook = hookmetamethod(game, "__index", function(self, index)
    if not checkcaller() and typeof(self) == "Instance" then
        if self:IsA("Humanoid") then
            local DebugId = GetDebugId(self)
            local cached = cachedhumanoids[DebugId]

            if self:IsDescendantOf(lp.Character) or cached then
                if type(index) == "string" then
                    local cleanindex = split(index, "\0")[1]

                    if cleanindex == "WalkSpeed" then
                        if not cached then
                            cached = cachedhumanoids:cacheHumanoid(DebugId, self)
                        end

                        if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                            CurrentHumanoid = cloneref(self)
                        end

                        return cached.lastnewindex or cached.currentindex
                    end
                end
            end
        end
    end

    return indexhook(self, index)
end)

newindexhook = hookmetamethod(game, "__newindex", function(self, index, newindex)
    if not checkcaller() and typeof(self) == "Instance" then
        if self:IsA("Humanoid") then
            local DebugId = GetDebugId(self)
            local cached = cachedhumanoids[DebugId]

            if self:IsDescendantOf(lp.Character) or cached then
                if type(index) == "string" then
                    local cleanindex = split(index, "\0")[1]

                    if cleanindex == "WalkSpeed" then
                        if not cached then
                            cached = cachedhumanoids:cacheHumanoid(DebugId, self)
                        end

                        if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                            CurrentHumanoid = cloneref(self)
                        end
                        cached.lastnewindex = GetWalkSpeed(newindex)
                        return CurrentHumanoid.WalkSpeed
                    end
                end
            end
        end
    end

    return newindexhook(self, index, newindex)
end)

function WalkSpeedSpoof:Disable()
    WalkSpeedSpoof:RestoreWalkSpeed()
    hookmetamethod(game, "__index", indexhook)
    hookmetamethod(game, "__newindex", newindexhook)
    GetDebugIdHandler:Destroy()
    TempHumanoid:Destroy()
    table.clear(WalkSpeedSpoof)
    getgenv().WalkSpeedSpoof = nil
end

function WalkSpeedSpoof:GetHumanoid()
    return CurrentHumanoid or (function()
        local char = lp.Character
        local Humanoid = char and char:FindFirstChildWhichIsA("Humanoid") or nil
        if Humanoid then
            cachedhumanoids:cacheHumanoid(Humanoid:GetDebugId(), Humanoid)
            return cloneref(Humanoid)
        end
    end)()
end

function WalkSpeedSpoof:SetWalkSpeed(speed)
    local Humanoid = WalkSpeedSpoof:GetHumanoid()
    if Humanoid then
        local connections = {}
        local function AddConnectionsFromSignal(Signal)
            for _, v in getconnections(Signal) do
                if v.State then
                    v:Disable()
                    table.insert(connections, v)
                end
            end
        end
        AddConnectionsFromSignal(Humanoid.Changed)
        AddConnectionsFromSignal(Humanoid:GetPropertyChangedSignal("WalkSpeed"))
        Humanoid.WalkSpeed = speed
        for _, v in connections do
            v:Enable()
        end
    end
end

function WalkSpeedSpoof:RestoreWalkSpeed()
    local Humanoid = WalkSpeedSpoof:GetHumanoid()
    if Humanoid then
        local cached = cachedhumanoids[Humanoid:GetDebugId()]
        if cached then
            WalkSpeedSpoof:SetWalkSpeed(cached.lastnewindex or cached.currentindex)
        end
    end
end

getgenv().WalkSpeedSpoof = WalkSpeedSpoof

-- ============================================================
-- FEATURES
-- ============================================================

local ModeratorDetector = {}
ModeratorDetector.Enabled = false
ModeratorDetector.PlayerAddedConnection = nil
ModeratorDetector.PlayerRemovingConnection = nil

local AntiAFK = {}
AntiAFK.Enabled = false
AntiAFK.Connection = nil

local WalkSpeed = {}
WalkSpeed.Enabled = false
WalkSpeed.Value = 16
WalkSpeed.Active = false

local JumpPower = {}
JumpPower.Enabled = false
JumpPower.Value = 50
JumpPower.Active = false

local NoClip = {}
NoClip.Enabled = false
NoClip.Connection = nil
NoClip.Parts = {}
NoClip.Active = false

local Fly = {}
Fly.Enabled = false
Fly.Connection = nil
Fly.Speed = 50
Fly.Active = false

-- UI toggle references for keybind checking
local WalkSpeedToggleRef = nil
local JumpPowerToggleRef = nil
local NoClipToggleRef = nil
local FlyToggleRef = nil

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

local function DetectModerator(Enabled)
    ModeratorDetector.Enabled = Enabled
    if Enabled then
        Matrice.UI:Notify("Normal", {
            Title = "Moderator Detector",
            Content = "Moderator Detector is enabled.",
            Duration = 3,
            Image = Matrice.Asset("info.png")
        })

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

        if ModeratorDetector.PlayerAddedConnection then
            ModeratorDetector.PlayerAddedConnection:Disconnect()
            ModeratorDetector.PlayerAddedConnection = nil
        end
        ModeratorDetector.PlayerAddedConnection = Players.PlayerAdded:Connect(function(Player)
            if ModeratorDetector.Enabled then
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

        if ModeratorDetector.PlayerRemovingConnection then
            ModeratorDetector.PlayerRemovingConnection:Disconnect()
            ModeratorDetector.PlayerRemovingConnection = nil
        end
        ModeratorDetector.PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(Player)
            if ModeratorDetector.Enabled then
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
        if ModeratorDetector.PlayerAddedConnection then
            ModeratorDetector.PlayerAddedConnection:Disconnect()
            ModeratorDetector.PlayerAddedConnection = nil
        end
        if ModeratorDetector.PlayerRemovingConnection then
            ModeratorDetector.PlayerRemovingConnection:Disconnect()
            ModeratorDetector.PlayerRemovingConnection = nil
        end

        Matrice.UI:Notify("Normal", {
            Title = "Moderator Detector",
            Content = "Moderator Detector is disabled.",
            Duration = 3,
            Image = Matrice.Asset("info.png")
        })
    end
end

local function AntiAFK(Enabled)
    AntiAFK.Enabled = Enabled
    if Enabled then
        if getconnections then
            for _, Connection in ipairs(getconnections(LocalPlayer.Idled)) do
                pcall(function()
                    Connection:Disable()
                    Connection:Disconnect()
                end)
            end
        end

        if AntiAFK.Connection then
            AntiAFK.Connection:Disconnect()
            AntiAFK.Connection = nil
        end

        AntiAFK.Connection = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)

        Matrice.UI:Notify("Normal", {
            Title = "Anti AFK",
            Content = "Anti AFK is enabled.",
            Duration = 3,
            Image = Matrice.Asset("info.png")
        })
    else
        if AntiAFK.Connection then
            AntiAFK.Connection:Disconnect()
            AntiAFK.Connection = nil
        end
        Matrice.UI:Notify("Normal", {
            Title = "Anti AFK",
            Content = "Anti AFK is disabled.",
            Duration = 3,
            Image = Matrice.Asset("info.png")
        })
    end
end

local function ToggleWalkSpeed(Enabled)
    WalkSpeed.Enabled = Enabled
    WalkSpeed.Active = Enabled
    if WalkSpeed.Enabled and WalkSpeed.Active then
        WalkSpeedSpoof:SetWalkSpeed(WalkSpeed.Value)
        Matrice.UI:Notify("Normal", {
            Title = "Walk Speed",
            Content = "Walk Speed set to " .. WalkSpeed.Value,
            Duration = 2,
            Image = Matrice.Asset("info.png")
        })
    else
        WalkSpeedSpoof:RestoreWalkSpeed()
        Matrice.UI:Notify("Normal", {
            Title = "Walk Speed",
            Content = "Walk Speed restored.",
            Duration = 2,
            Image = Matrice.Asset("info.png")
        })
    end
end

local function ToggleJumpPower(Enabled)
    JumpPower.Enabled = Enabled
    JumpPower.Active = Enabled
    local Humanoid = WalkSpeedSpoof:GetHumanoid()
    if Humanoid then
        if JumpPower.Enabled and JumpPower.Active then
            Humanoid.JumpPower = JumpPower.Value
            Matrice.UI:Notify("Normal", {
                Title = "Jump Power",
                Content = "Jump Power set to " .. JumpPower.Value,
                Duration = 2,
                Image = Matrice.Asset("info.png")
            })
        else
            Humanoid.JumpPower = 50
            Matrice.UI:Notify("Normal", {
                Title = "Jump Power",
                Content = "Jump Power restored.",
                Duration = 2,
                Image = Matrice.Asset("info.png")
            })
        end
    end
end

local function ToggleNoClip(Enabled)
    NoClip.Enabled = Enabled
    NoClip.Active = Enabled
    if NoClip.Enabled and NoClip.Active then
        if NoClip.Connection then NoClip.Connection:Disconnect() end
        NoClip.Connection = RunService.Stepped:Connect(function()
            if not (NoClip.Enabled and NoClip.Active) then return end
            local Character = LocalPlayer.Character
            if not Character then return end
            for _, Part in ipairs(Character:GetDescendants()) do
                if Part:IsA("BasePart") and Part.CanCollide == true and Part.Name ~= "Head" then
                    Part.CanCollide = false
                    NoClip.Parts[Part] = true
                end
            end
        end)
        Matrice.UI:Notify("Normal", {
            Title = "No Clip",
            Content = "No Clip enabled.",
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
        Matrice.UI:Notify("Normal", {
            Title = "No Clip",
            Content = "No Clip disabled.",
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
            LocalPlayer.CharacterAdded:Wait()
            Character = LocalPlayer.Character
        end
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.PlatformStand = true
        end
        local Head = Character:FindFirstChild("Head")
        if Head then
            Head.Anchored = true
        end
        if Fly.Connection then Fly.Connection:Disconnect() end
        Fly.Connection = RunService.Heartbeat:Connect(function(DeltaTime)
            if not (Fly.Enabled and Fly.Active) then return end
            local Character = LocalPlayer.Character
            if not Character then return end
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            local Head = Character:FindFirstChild("Head")
            if not Humanoid or not Head then return end
            local MoveDirection = Humanoid.MoveDirection * (Fly.Speed * DeltaTime)
            local HeadCFrame = Head.CFrame
            local Camera = workspace.CurrentCamera
            local CameraCFrame = Camera.CFrame
            local CameraOffset = HeadCFrame:ToObjectSpace(CameraCFrame).Position
            CameraCFrame = CameraCFrame * CFrame.new(-CameraOffset.X, -CameraOffset.Y, -CameraOffset.Z + 1)
            local CameraPosition = CameraCFrame.Position
            local HeadPosition = HeadCFrame.Position
            local ObjectSpaceVelocity = CFrame.new(CameraPosition, Vector3.new(HeadPosition.X, CameraPosition.Y, HeadPosition.Z)):VectorToObjectSpace(MoveDirection)
            Head.CFrame = CFrame.new(HeadPosition) * (CameraCFrame - CameraPosition) * CFrame.new(ObjectSpaceVelocity)
        end)
        Matrice.UI:Notify("Normal", {
            Title = "Fly",
            Content = "Fly enabled.",
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
        Matrice.UI:Notify("Normal", {
            Title = "Fly",
            Content = "Fly disabled.",
            Duration = 2,
            Image = Matrice.Asset("info.png")
        })
    end
end

-- ============================================================
-- UI ELEMENTS
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
-- COMBAT TAB
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
-- VISUALS TAB
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
-- PLAYER TAB
-- ============================================================

local Character = PlayerTab:CreateSection("Character", "Normal")

WalkSpeedToggleRef = Character:CreateToggle("Normal", {
    Name = "Enable Walk Speed",
    Flag = "WalkSpeedEnabled",
    Callback = function(Enabled)
        ToggleWalkSpeed(Enabled)
    end
})

Character:CreateSlider({
    Name = "Walk Speed",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = WalkSpeed.Value,
    Flag = "WalkSpeed",
    Callback = function(Value)
        WalkSpeed.Value = Value
        if WalkSpeed.Enabled and WalkSpeed.Active then
            WalkSpeedSpoof:SetWalkSpeed(Value)
        end
        print("Walk Speed set to " .. Value)
    end
})

JumpPowerToggleRef = Character:CreateToggle("Normal", {
    Name = "Enable Jump Power",
    Flag = "JumpPowerEnabled",
    Callback = function(Enabled)
        ToggleJumpPower(Enabled)
    end
})

Character:CreateSlider({
    Name = "Jump Power",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = JumpPower.Value,
    Flag = "JumpPower",
    Callback = function(Value)
        JumpPower.Value = Value
        if JumpPower.Enabled and JumpPower.Active then
            local Humanoid = WalkSpeedSpoof:GetHumanoid()
            if Humanoid then
                Humanoid.JumpPower = Value
            end
        end
        print("Jump Power set to " .. Value)
    end
})

NoClipToggleRef = Character:CreateToggle("Normal", {
    Name = "No Clip",
    Flag = "NoClip",
    Callback = function(Enabled)
        ToggleNoClip(Enabled)
    end
})

Character:CreateKeybind({
    Name = "No Clip Keybind",
    Flag = "NoClipKeybind",
    Keybind = "N",
    Type = "Press",
    Callback = function(State)
        if State and NoClip.Enabled then
            NoClip.Active = not NoClip.Active
            ToggleNoClip(NoClip.Enabled) -- this will reapply state based on Enabled and Active
        end
    end
})

FlyToggleRef = Character:CreateToggle("Normal", {
    Name = "Fly",
    Flag = "Fly",
    Callback = function(Enabled)
        ToggleFly(Enabled)
    end
})

Character:CreateKeybind({
    Name = "Fly Keybind",
    Flag = "FlyKeybind",
    Keybind = "F",
    Type = "Press",
    Callback = function(State)
        if State and Fly.Enabled then
            Fly.Active = not Fly.Active
            ToggleFly(Fly.Enabled) -- this will reapply state based on Enabled and Active
        end
    end
})

Character:CreateSlider({
    Name = "Fly Speed",
    Value = {1, 200},
    Increment = 1,
    Suffix = "",
    CurrentValue = Fly.Speed,
    Flag = "FlySpeed",
    Callback = function(Value)
        Fly.Speed = Value
        print("Fly Speed set to " .. Value)
    end
})

-- ============================================================
-- UTILITIES TAB
-- ============================================================

local Miscellaneous = UtilitiesTab:CreateSection("Miscellaneous", "Normal")

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
-- SETTINGS TAB
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