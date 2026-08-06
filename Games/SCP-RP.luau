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

-- Target Selection & Priority
local TargetSelection = "FOV Priority"
local TargetPriority = "Closest"

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
    local LocalChar = LocalPlayer.Character
    if not LocalChar then return nil end
    local LocalRoot = LocalChar:FindFirstChild("HumanoidRootPart")
    if not LocalRoot then return nil end

    local Candidates = {}

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
                SilentAimRaycastParams.FilterDescendantsInstances = {LocalChar}
                local Result = workspace:Raycast(Camera.CFrame.Position, TargetPart.Position - Camera.CFrame.Position, SilentAimRaycastParams)
                if Result and not Result.Instance:IsDescendantOf(Character) then
                    continue
                end
            end

            local WorldDist = (LocalRoot.Position - TargetPart.Position).Magnitude
            local ScreenDist = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - Cursor).Magnitude

            table.insert(Candidates, {
                Part = TargetPart,
                WorldDistance = WorldDist,
                ScreenDistance = ScreenDist,
                Health = Humanoid.Health,
                MaxHealth = Humanoid.MaxHealth,
            })
        end
    end

    if #Candidates == 0 then return nil end

    local function ComparePrimary(a, b)
        if TargetSelection == "FOV Priority" then
            return a.ScreenDistance < b.ScreenDistance
        elseif TargetSelection == "Closest" then
            return a.WorldDistance < b.WorldDistance
        elseif TargetSelection == "Distance Priority" then
            if a.WorldDistance ~= b.WorldDistance then
                return a.WorldDistance < b.WorldDistance
            else
                return a.ScreenDistance < b.ScreenDistance
            end
        end
        return false
    end

    local function CompareSecondary(a, b)
        if TargetPriority == "Closest" then
            return a.WorldDistance < b.WorldDistance
        elseif TargetPriority == "Lowest Health" then
            local aHealthFrac = a.Health / a.MaxHealth
            local bHealthFrac = b.Health / b.MaxHealth
            return aHealthFrac < bHealthFrac
        elseif TargetPriority == "Crosshair Distance" then
            return a.ScreenDistance < b.ScreenDistance
        end
        return false
    end

    table.sort(Candidates, function(a, b)
        local primary = ComparePrimary(a, b)
        if primary ~= false then return primary end
        return CompareSecondary(a, b)
    end)

    return Candidates[1].Part
end

-- ============================================================
--  IMPROVED HOOK INSTALLATION (crash‑proof & robust)
-- ============================================================

local function FindBulletFunction()
    -- Strategy 1: Look in LocalPlayer's scripts for a function with "bullet" constants
    local function SearchInScripts()
        for _, script in ipairs(LocalPlayer.PlayerScripts:GetDescendants()) do
            if script:IsA("ModuleScript") or script:IsA("LocalScript") then
                local success, funcs = pcall(function()
                    return getgc(true)
                end)
                if success and funcs then
                    for _, func in ipairs(funcs) do
                        if type(func) == "function" then
                            local info = debug.getinfo(func)
                            if info and info.source and info.source:find(script.Name) then
                                local constants = debug.getconstants(func)
                                if constants and (table.find(constants, "Bullet") or table.find(constants, "bullet") or table.find(constants, "Fire")) then
                                    return func
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    -- Strategy 2: Use filtergc (if available)
    local function UseFilterGC()
        if filtergc then
            local results = filtergc("function", {
                Constants = {"Bullet", "Fire", "Shoot"},
                IgnoreExecutor = true,
            })
            if type(results) == "function" then return results end
            if type(results) == "table" then
                for _, func in ipairs(results) do
                    if type(func) == "function" then
                        local info = debug.getinfo(func)
                        if info and info.source and info.source:find("Controller") then
                            return func
                        end
                    end
                end
            end
        end
        return nil
    end

    -- Strategy 3: Hook the tool's Fire method (fallback)
    local function HookToolFire()
        local character = LocalPlayer.Character
        if not character then return nil end
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                local fireEvent = tool:FindFirstChild("Fire") or tool:FindFirstChild("Shoot")
                if fireEvent and fireEvent:IsA("RemoteEvent") then
                    local oldFire
                    oldFire = hookfunction(fireEvent.FireServer, function(self, ...)
                        local target = GetSilentAimTarget()
                        if target then
                            print("Silent Aim: Intercepted tool fire, redirecting to target")
                            return oldFire(self, target, ...)
                        end
                        return oldFire(self, ...)
                    end)
                    return oldFire
                end
            end
        end
        return nil
    end

    -- Try strategies in order
    local func = SearchInScripts() or UseFilterGC() or HookToolFire()
    if func then
        print("Silent Aim: Found bullet function")
        return func
    else
        warn("Silent Aim: Could not find bullet function")
        return nil
    end
end

local function InstallSilentAimHook()
    if SilentAimHookInstalled then return true end

    local BulletFunction = FindBulletFunction()
    if not BulletFunction then
        warn("Silent Aim: Could not find bullet function.")
        return false
    end

    SilentAimOriginal = BulletFunction
    local HookSuccess, HookError = pcall(function()
        SilentAimHook = hookfunction(BulletFunction, function(...)
            local Args = {...}
            local HitResult = Args[2]
            if HitResult and type(HitResult) == "table" then
                local Target = GetSilentAimTarget()
                if Target and math.random(1, 100) <= SilentAimHitChance then
                    Args[2] = {
                        Instance = Target,
                        Position = Target.Position,
                        Normal = Vector3.new(0, 1, 0),
                        Material = Target.Material,
                    }
                    print("Silent Aim: Redirected bullet to", Target.Name)
                end
            end
            return SilentAimOriginal(unpack(Args))
        end)
    end)

    if not HookSuccess then
        warn("Silent Aim: Hook failed:", HookError)
        SilentAimOriginal = nil
        return false
    end

    SilentAimHookInstalled = true
    print("Silent Aim: Hook installed successfully")
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
        print("Silent Aim: Hook removed")
    end
end

-- ============================================================
--  MODERATOR DETECTOR & ANTI AFK (unchanged)
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
--  UI CREATION (unchanged)
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
    end
})

Targeting:CreateDropdown({
    Name = "Hit Part",
    Options = {"Head", "UpperTorso", "HumanoidRootPart", "Randomized"},
    CurrentOption = SilentAimHitPart,
    Flag = "HitPart",
    Callback = function(Selected)
        SilentAimHitPart = Selected
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
    end
})

Targeting:CreateDropdown({
    Name = "Target Selection",
    Options = {"FOV Priority", "Closest", "Distance Priority"},
    CurrentOption = TargetSelection,
    Flag = "TargetSelection",
    Callback = function(Selected)
        TargetSelection = Selected
    end
})

Targeting:CreateDropdown({
    Name = "Target Priority",
    Options = {"Closest", "Lowest Health", "Crosshair Distance"},
    CurrentOption = TargetPriority,
    Flag = "TargetPriority",
    Callback = function(Selected)
        TargetPriority = Selected
    end
})

Targeting:CreateToggle("Normal", {
    Name = "Hitbox",
    Flag = "Hitbox",
    Callback = function(Enabled) end
})

Targeting:CreateSlider({
    Name = "Hitbox Size",
    Value = {1, 10},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "HitboxSize",
    Callback = function(Value) end
})

local Checks = CombatTab:CreateSection("Checks", "Normal")

Checks:CreateToggle("Normal", {
    Name = "Wall Check",
    Flag = "WallCheck",
    Callback = function(Enabled)
        SilentAimWallCheck = Enabled
    end
})

Checks:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "TeamCheck",
    Callback = function(Enabled) end
})

local FOV = CombatTab:CreateSection("FOV", "Normal")

FOV:CreateToggle("Normal", {
    Name = "Show FOV",
    Flag = "ShowFOV",
    Callback = function(Enabled)
        FOVCircleEnabled = Enabled
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
    end
})

FOV:CreateColorPicker({
    Name = "FOV Color",
    Callback = function(Color)
        FOVColor = Color
    end
})

local Automation = CombatTab:CreateSection("Automation", "Normal")
Automation:CreateToggle("Normal", { Name = "Auto Trigger", Flag = "AutoTrigger", Callback = function(Enabled) end })
Automation:CreateSlider({ Name = "Trigger Delay", Value = {0, 500}, Increment = 10, Suffix = "ms", CurrentValue = 50, Flag = "TriggerDelay", Callback = function(Value) end })

local Weapons = CombatTab:CreateSection("Weapons", "Normal")
Weapons:CreateToggle("Normal", { Name = "Auto Reload", Flag = "AutoReload", Callback = function(Enabled) end })

-- ============================================================
--  VISUALS TAB (placeholders)
-- ============================================================

local ESP = VisualsTab:CreateSection("ESP", "Normal")
ESP:CreateToggle("Normal", { Name = "Enable ESP", Flag = "ESPEnabled", Callback = function(Enabled) end })
ESP:CreateToggle("Normal", { Name = "Box ESP", Flag = "ESPBox", Callback = function(Enabled) end })
ESP:CreateToggle("Normal", { Name = "Name ESP", Flag = "ESPName", Callback = function(Enabled) end })
ESP:CreateToggle("Normal", { Name = "Distance ESP", Flag = "ESPDistance", Callback = function(Enabled) end })
ESP:CreateToggle("Normal", { Name = "Weapon ESP", Flag = "ESPWeapon", Callback = function(Enabled) end })
ESP:CreateToggle("Normal", { Name = "Health Bar", Flag = "ESPHealthBar", Callback = function(Enabled) end })
ESP:CreateToggle("Normal", { Name = "Skeleton ESP", Flag = "ESPSkeleton", Callback = function(Enabled) end })
ESP:CreateToggle("Normal", { Name = "Team Check", Flag = "ESPTeamCheck", Callback = function(Enabled) end })
ESP:CreateToggle("Normal", { Name = "Friend Check", Flag = "FriendCheck", Callback = function(Enabled) end })
ESP:CreateSlider({ Name = "Distance Limit", Value = {10, 1000}, Increment = 10, Suffix = " studs", CurrentValue = 500, Flag = "DistanceLimit", Callback = function(Value) end })

local Effects = VisualsTab:CreateSection("Effects", "Normal")
Effects:CreateToggle("Normal", { Name = "Highlight", Flag = "Highlight", Callback = function(Enabled) end })
Effects:CreateToggle("Normal", { Name = "Chams", Flag = "Chams", Callback = function(Enabled) end })
Effects:CreateToggle("Normal", { Name = "Tracer Lines", Flag = "TracerLines", Callback = function(Enabled) end })
Effects:CreateDropdown({ Name = "Tracer Origin", Options = {"Bottom", "Center", "Mouse"}, CurrentOption = "Bottom", Flag = "TracerOrigin", Callback = function(Selected) end })

-- ============================================================
--  PLAYER TAB (placeholders)
-- ============================================================

local Character = PlayerTab:CreateSection("Character", "Normal")
Character:CreateToggle("Normal", { Name = "Enable Walk Speed", Flag = "WalkSpeedEnabled", Callback = function(Enabled) end })
Character:CreateSlider({ Name = "Walk Speed", Value = {0, 100}, Increment = 1, Suffix = "", CurrentValue = 16, Flag = "WalkSpeed", Callback = function(Value) end })
Character:CreateToggle("Normal", { Name = "Enable Jump Power", Flag = "JumpPowerEnabled", Callback = function(Enabled) end })
Character:CreateSlider({ Name = "Jump Power", Value = {0, 100}, Increment = 1, Suffix = "", CurrentValue = 50, Flag = "JumpPower", Callback = function(Value) end })
Character:CreateToggle("Normal", { Name = "No Clip", Flag = "NoClip", Callback = function(Enabled) end })
Character:CreateKeybind({ Name = "No Clip Keybind", Flag = "NoClipKeybind", Keybind = "N", Type = "Press", Callback = function(State) end })
Character:CreateToggle("Normal", { Name = "Fly", Flag = "Fly", Callback = function(Enabled) end })
Character:CreateKeybind({ Name = "Fly Keybind", Flag = "FlyKeybind", Keybind = "F", Type = "Press", Callback = function(State) end })

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