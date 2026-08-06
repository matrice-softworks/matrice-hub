-- Matrice Softworks

-- ============================================================
--  SERVICES
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

-- ============================================================
--  REFERENCES
-- ============================================================

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
--  FEATURE VARIABLES
-- ============================================================

-- Silent Aim state
local SilentAimEnabled = false
local SilentAimWallCheck = true
local SilentAimHitPart = "Head"
local SilentAimHitChance = 100
local SilentAimHookInstalled = false
local SilentAimHook = nil
local SilentAimOriginal = nil

local FOVCircleEnabled = false
local FOVRadius = 150
local FOVColor = Color3.fromRGB(255, 255, 255)

local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Visible = false

local SilentAimRaycastParams = RaycastParams.new()
SilentAimRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
SilentAimRaycastParams.IgnoreWater = true

-- Moderator Detector
local ModeratorDetectorEnabled = false
local ModeratorDetectorAddedConnection = nil
local ModeratorDetectorRemovingConnection = nil

-- Anti AFK
local AntiAFKEnabled = false
local AntiAFKConnection = nil

-- ============================================================
--  HELPER FUNCTIONS
-- ============================================================

local function IsEnemy(Player)
    local LocalTeam = LocalPlayer.Team
    local TargetTeam = Player.Team
    if not LocalTeam or not TargetTeam then return true end
    local HostileTeams = {
        ["Administrative Department"] = 1,
        ["Chaos Insurgency"] = 0,
        ["Class - D"] = 0,
        ["Intelligence Agency"] = 1,
        ["Internal Security Department"] = 1,
        ["Medical Department"] = 1,
        ["Mobile Task Force"] = 1,
        ["Rapid Response Team"] = 1,
        ["Scientific Department"] = 1,
        ["Security Department"] = 1,
    }
    local LocalTeamValue = HostileTeams[LocalTeam.Name]
    local TargetTeamValue = HostileTeams[TargetTeam.Name]
    return LocalTeamValue == nil or TargetTeamValue == nil or LocalTeamValue ~= TargetTeamValue
end

local function GetSilentAimTarget()
    if not SilentAimEnabled then return nil end
    local Camera = workspace.CurrentCamera
    local Cursor = UserInputService:GetMouseLocation()
    local ClosestPart = nil
    local ClosestDistance = FOVRadius

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and IsEnemy(Player) then
            local Character = Player.Character
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if not Humanoid or Humanoid.Health <= 0 then continue end

            local TargetPartName = SilentAimHitPart
            if TargetPartName == "Randomized" then
                local Parts = {"Head", "UpperTorso", "HumanoidRootPart"}
                TargetPartName = Parts[math.random(1, #Parts)]
            end
            local TargetPart = Character:FindFirstChild(TargetPartName) or Character:FindFirstChild("HumanoidRootPart")
            if not TargetPart then continue end

            local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
            if not OnScreen then continue end

            if SilentAimWallCheck then
                local LocalCharacter = LocalPlayer.Character
                if LocalCharacter then
                    SilentAimRaycastParams.FilterDescendantsInstances = {LocalCharacter}
                    local Result = workspace:Raycast(Camera.CFrame.Position, TargetPart.Position - Camera.CFrame.Position, SilentAimRaycastParams)
                    if Result and not Result.Instance:IsDescendantOf(Character) then
                        continue
                    end
                end
            end

            local Distance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - Cursor).Magnitude
            if Distance < ClosestDistance then
                ClosestPart = TargetPart
                ClosestDistance = Distance
            end
        end
    end
    return ClosestPart
end

local function FindBulletFunction()
    local Controller = LocalPlayer.PlayerScripts:FindFirstChild("Controller")
    if not Controller then return nil end
    local function MatchesController(Candidate)
        if not debug or not debug.getinfo then return false end
        local Success, Info = pcall(debug.getinfo, Candidate)
        return Success and Info and Info.source == "=" .. Controller:GetFullName()
    end
    if filtergc then
        local Result = filtergc("function", {
            Constants = {"Bullet", "EasterEggThing", "SCP-066"},
            IgnoreExecutor = true,
        })
        if type(Result) == "function" and MatchesController(Result) then return Result end
        if type(Result) == "table" then
            for _, Candidate in ipairs(Result) do
                if type(Candidate) == "function" and MatchesController(Candidate) then return Candidate end
            end
        end
    end
    if getgc and debug and debug.getconstants then
        for _, Candidate in ipairs(getgc()) do
            if type(Candidate) == "function" then
                local Success, Constants = pcall(debug.getconstants, Candidate)
                if Success and Constants and MatchesController(Candidate) and table.find(Constants, "Bullet") and table.find(Constants, "EasterEggThing") and table.find(Constants, "SCP-066") then
                    return Candidate
                end
            end
        end
    end
    return nil
end

local function InstallSilentAimHook()
    if SilentAimHookInstalled then return true end
    local BulletFunction = FindBulletFunction()
    if not BulletFunction then
        warn("Silent Aim: Could not find bullet function.")
        return false
    end
    SilentAimOriginal = BulletFunction
    SilentAimHook = hookfunction(BulletFunction, function(_, HitResult, ...)
        local Target = GetSilentAimTarget()
        if Target and math.random(1, 100) <= SilentAimHitChance then
            return SilentAimOriginal(_, {
                Instance = Target,
                Position = Target.Position,
                Normal = Vector3.new(0, 1, 0),
                Material = Target.Material,
            }, ...)
        end
        return SilentAimOriginal(_, HitResult, ...)
    end)
    SilentAimHookInstalled = true
    return true
end

local function UninstallSilentAimHook()
    if SilentAimHookInstalled and SilentAimHook and SilentAimOriginal then
        pcall(function()
            hookfunction(SilentAimOriginal, SilentAimOriginal)
        end)
        SilentAimHook = nil
        SilentAimOriginal = nil
        SilentAimHookInstalled = false
    end
end

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
--  RENDER LOOP FOR FOV CIRCLE
-- ============================================================

RunService.RenderStepped:Connect(function()
    if FOVCircleEnabled then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = FOVRadius
        FOVCircle.Color = FOVColor
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
end)

-- ============================================================
--  COMBAT TAB
-- ============================================================

local Targeting = CombatTab:CreateSection("Targeting", "Normal")

Targeting:CreateToggle("Normal", {
    Name = "Silent Aim",
    Flag = "SilentAim",
    Callback = function(Enabled)
        SilentAimEnabled = Enabled
        if Enabled then
            if not InstallSilentAimHook() then
                SilentAimEnabled = false
                Matrice.UI:Notify("Error", {
                    Title = "Silent Aim",
                    Content = "Failed to install hook. Feature may not be supported.",
                    Duration = 5,
                    Image = Matrice.Asset("circle-x.png")
                })
            end
        else
            UninstallSilentAimHook()
        end
        print("Silent Aim " .. (Enabled and "ON" or "OFF"))
    end
})

Targeting:CreateDropdown({
    Name = "Hit Part",
    Options = {"Head", "UpperTorso", "HumanoidRootPart", "Randomized"},
    CurrentOption = SilentAimHitPart,
    Flag = "HitPart",
    Callback = function(Selected)
        SilentAimHitPart = Selected
        print("Hit Part set to " .. Selected)
    end
})

Targeting:CreateSlider({
    Name = "Hit Chance",
    Value = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = SilentAimHitChance,
    Flag = "HitChance",
    Callback = function(Value)
        SilentAimHitChance = Value
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
        SilentAimWallCheck = Enabled
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
        FOVCircleEnabled = Enabled
        print("Show FOV " .. (Enabled and "ON" or "OFF"))
    end
})

FOV:CreateSlider({
    Name = "FOV Radius",
    Value = {25, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = FOVRadius,
    Flag = "FOVRadius",
    Callback = function(Value)
        FOVRadius = Value
        print("FOV Radius set to " .. Value)
    end
})

FOV:CreateColorPicker({
    Name = "FOV Color",
    Callback = function(Color)
        FOVColor = Color
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