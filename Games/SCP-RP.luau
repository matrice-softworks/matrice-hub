-- Matrice Softworks

-- ============================================================
--  DUPLICATE EXECUTION PROTECTION
-- ============================================================
if getgenv().MatriceLoaded then
    warn("Matrice is already running!")
    return
end
getgenv().MatriceLoaded = true

-- ============================================================
--  CLEANUP HANDLER (prevents leaks on re‑execution)
-- ============================================================
getgenv().MatriceCleanup = function()
    -- Stop all connections, remove hooks, etc.
    if ESPConnection then ESPConnection:Disconnect(); ESPConnection = nil end
    if RenderConnection then RenderConnection:Disconnect(); RenderConnection = nil end
    if FriendListUpdateTask then task.cancel(FriendListUpdateTask); FriendListUpdateTask = nil end
    if FriendListAddedConnection then FriendListAddedConnection:Disconnect(); FriendListAddedConnection = nil end
    if AutoTriggerConnection then AutoTriggerConnection:Disconnect(); AutoTriggerConnection = nil end
    if AutoReloadConnection then AutoReloadConnection:Disconnect(); AutoReloadConnection = nil end
    if MovementCharacterConnection then MovementCharacterConnection:Disconnect(); MovementCharacterConnection = nil end
    if PlayerModsCharacterAddedConnection then PlayerModsCharacterAddedConnection:Disconnect(); PlayerModsCharacterAddedConnection = nil end
    if AntiAFKConnection then AntiAFKConnection:Disconnect(); AntiAFKConnection = nil end
    if ModeratorDetectorAddedConnection then ModeratorDetectorAddedConnection:Disconnect(); ModeratorDetectorAddedConnection = nil end
    if ModeratorDetectorRemovingConnection then ModeratorDetectorRemovingConnection:Disconnect(); ModeratorDetectorRemovingConnection = nil end
    if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
    if FlyCharacterConnection then FlyCharacterConnection:Disconnect(); FlyCharacterConnection = nil end

    -- Remove hooks
    if indexHook then indexHook = nil end
    if newIndexHook then newIndexHook = nil end
    if SilentAimHookInstalled then SilentAimHookInstalled = false end

    -- Clear all Drawing objects
    for _, esp in pairs(ESPData) do
        for _, obj in pairs(esp) do
            if type(obj) == "table" and obj.Remove then
                obj:Remove()
            elseif type(obj) == "userdata" then
                pcall(obj.Remove, obj)
            end
        end
    end
    ESPData = {}

    -- Clear Hitbox data
    HitboxData.OriginalSizes = {}
    HitboxData.OriginalCollisions = {}
    for _, conn in pairs(HitboxData.Connections) do
        if type(conn) == "table" then
            for _, c in pairs(conn) do
                if c then c:Disconnect() end
            end
        else
            if conn then conn:Disconnect() end
        end
    end
    HitboxData.Connections = {
        PlayerAdded = nil,
        PlayerRemoving = nil,
        SteppedLoops = {},
        CharacterAdded = {},
    }
end

-- ============================================================
--  SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Visuals = Matrice.Visuals

-- ============================================================
--  CONFIGURATION (centralised state)
-- ============================================================
local Config = {
    SilentAimEnabled = false,
    SilentAimWallCheck = true,
    SilentAimHitPart = "Head",
    SilentAimHitChance = 100,
    FOVCircleEnabled = false,
    FOVRadius = 150,
    FOVColor = Color3.fromRGB(255, 255, 255),
    SilentAimFriendCheck = false,
    TargetSelection = "Distance Priority",
    TargetPriority = "Closest",
    HitboxEnabled = false,
    HitboxSize = 10,
    AutoTriggerEnabled = false,
    AutoReloadEnabled = false,
    ESPEnabled = false,
    BoxEnabled = false,
    NameEnabled = false,
    DistanceEnabled = false,
    WeaponEnabled = false,
    HealthBarEnabled = false,
    SkeletonEnabled = false,
    TeamCheckEnabled = false,
    FriendCheckEnabled = false,
    DistanceLimit = 600,
    HighlightEnabled = false,
    ChamsEnabled = false,
    TracerEnabled = false,
    TracerOrigin = "Bottom",
}

-- ============================================================
--  FRIEND LIST
-- ============================================================
local FriendList = {}
local FriendListUpdateTask = nil
local FriendListAddedConnection = nil

local function UpdateFriendList()
    if not LocalPlayer then return end
    local Success, Pages = pcall(Players.GetFriendsAsync, Players, LocalPlayer.UserId)
    if not Success or not Pages then return end
    FriendList = {}
    local function IteratePages(Pages)
        return coroutine.wrap(function()
            while true do
                for _, Item in ipairs(Pages:GetCurrentPage()) do
                    coroutine.yield(Item)
                end
                if Pages.IsFinished then break end
                Pages:AdvanceToNextPageAsync()
            end
        end)
    end
    for Item in IteratePages(Pages) do
        FriendList[Item.Id] = true
    end
end

local function StartFriendListUpdates()
    if FriendListUpdateTask then return end
    UpdateFriendList()
    FriendListUpdateTask = task.spawn(function()
        while true do
            task.wait(300)
            UpdateFriendList()
        end
    end)
end

-- ============================================================
--  UI LIBRARY
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
--  COMBAT – Silent Aim, Hitbox, Auto Trigger, Auto Reload
-- ============================================================
local HitboxData = {
    OriginalSizes = {},
    OriginalCollisions = {},
    Connections = {
        PlayerAdded = nil,
        PlayerRemoving = nil,
        SteppedLoops = {},
        CharacterAdded = {},
    }
}

local AutoTriggerConnection = nil
local ShootHeld = false
local AutoReloadConnection = nil
local ReloadPressed = false
local SilentAimHookInstalled = false
local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Visible = false
local SilentAimRaycastParams = RaycastParams.new()
SilentAimRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
SilentAimRaycastParams.IgnoreWater = true

local Teams = {
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

local function IsEnemy(player)
    if player == LocalPlayer then return false end
    local localTeam = LocalPlayer.Team and Teams[LocalPlayer.Team.Name]
    local targetTeam = player.Team and Teams[player.Team.Name]
    return localTeam == nil or targetTeam == nil or localTeam ~= targetTeam
end

local function IsFriend(player)
    return FriendList[player.UserId] or false
end

-- ===== Hitbox Functions =====
local function ApplyHitboxToPlayer(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local rootPart = humanoid.RootPart
    if not rootPart then return end

    local size = Config.HitboxSize
    local debugId = player.UserId .. "_" .. (character:GetDebugId and character:GetDebugId() or character.Name)

    if not HitboxData.OriginalSizes[debugId] then
        HitboxData.OriginalSizes[debugId] = {}
        HitboxData.OriginalCollisions[debugId] = {}
    end

    if not HitboxData.OriginalSizes[debugId].RootPart then
        HitboxData.OriginalSizes[debugId].RootPart = rootPart.Size
    end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if not HitboxData.OriginalCollisions[debugId][part] then
                HitboxData.OriginalCollisions[debugId][part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end

    rootPart.Size = Vector3.new(size, size, size)
end

local function RestoreHitboxForPlayer(player)
    local debugId = player.UserId .. "_" .. (player.Character and player.Character.Name or "Unknown")
    if HitboxData.OriginalSizes[debugId] then
        if HitboxData.OriginalSizes[debugId].RootPart then
            local rootPart = player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").RootPart
            if rootPart then
                rootPart.Size = HitboxData.OriginalSizes[debugId].RootPart
            end
        end
        HitboxData.OriginalSizes[debugId] = nil
    end

    if HitboxData.OriginalCollisions[debugId] then
        for part, canCollide in pairs(HitboxData.OriginalCollisions[debugId]) do
            if part and part.Parent then
                part.CanCollide = canCollide
            end
        end
        HitboxData.OriginalCollisions[debugId] = nil
    end
end

local function ApplyHitboxToAllPlayers()
    if not Config.HitboxEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ApplyHitboxToPlayer(player)
        end
    end
end

local function RestoreHitboxForAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        RestoreHitboxForPlayer(player)
    end
end

-- Global stepped loop for hitbox (single loop, not per-player)
local HitboxSteppedConnection = nil
local function StartHitboxStepped()
    if HitboxSteppedConnection then return end
    HitboxSteppedConnection = RunService.Stepped:Connect(function()
        if not Config.HitboxEnabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local root = player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").RootPart
                if root then
                    root.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                end
            end
        end
    end)
end

local function StopHitboxStepped()
    if HitboxSteppedConnection then
        HitboxSteppedConnection:Disconnect()
        HitboxSteppedConnection = nil
    end
end

local function ToggleHitbox(Enabled)
    Config.HitboxEnabled = Enabled
    if Enabled then
        ApplyHitboxToAllPlayers()
        StartHitboxStepped()
        if not HitboxData.Connections.PlayerAdded then
            HitboxData.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
                if player ~= LocalPlayer and Config.HitboxEnabled then
                    local charAddedConn
                    charAddedConn = player.CharacterAdded:Connect(function(char)
                        charAddedConn:Disconnect()
                        task.wait(0.1)
                        ApplyHitboxToPlayer(player)
                    end)
                    HitboxData.Connections.CharacterAdded[player] = charAddedConn
                end
            end)
        end
        if not HitboxData.Connections.PlayerRemoving then
            HitboxData.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
                RestoreHitboxForPlayer(player)
                if HitboxData.Connections.CharacterAdded[player] then
                    HitboxData.Connections.CharacterAdded[player]:Disconnect()
                    HitboxData.Connections.CharacterAdded[player] = nil
                end
            end)
        end
    else
        RestoreHitboxForAllPlayers()
        StopHitboxStepped()
        if HitboxData.Connections.PlayerAdded then
            HitboxData.Connections.PlayerAdded:Disconnect()
            HitboxData.Connections.PlayerAdded = nil
        end
        if HitboxData.Connections.PlayerRemoving then
            HitboxData.Connections.PlayerRemoving:Disconnect()
            HitboxData.Connections.PlayerRemoving = nil
        end
        for player, conn in pairs(HitboxData.Connections.CharacterAdded) do
            conn:Disconnect()
        end
        HitboxData.Connections.CharacterAdded = {}
    end
end

-- ===== Silent Aim Target Detection =====
local function GetSilentAimTarget()
    if not Config.SilentAimEnabled then return nil end
    local cursor = UserInputService:GetMouseLocation()
    local fovRadius = Config.FOVRadius
    local targetSelection = Config.TargetSelection or "Distance Priority"
    local targetPriority = Config.TargetPriority or "Closest"

    local candidates = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsEnemy(player) then
            if Config.SilentAimFriendCheck and IsFriend(player) then continue end

            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local hitPartName = Config.SilentAimHitPart
            if hitPartName == "Randomized" then
                local hitParts = {"Head", "UpperTorso", "HumanoidRootPart"}
                hitPartName = hitParts[math.random(1, #hitParts)]
            end
            local targetPart = character and (character:FindFirstChild(hitPartName) or character:FindFirstChild("HumanoidRootPart"))

            if humanoid and humanoid.Health > 0 and targetPart then
                local screenPosition, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                local visible = true
                if Config.SilentAimWallCheck then
                    local localCharacter = LocalPlayer.Character
                    if localCharacter then
                        SilentAimRaycastParams.FilterDescendantsInstances = {localCharacter, Camera}
                        local result = workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, SilentAimRaycastParams)
                        visible = not result or result.Instance:IsDescendantOf(character)
                    end
                end
                if onScreen and visible then
                    local distCursor = (Vector2.new(screenPosition.X, screenPosition.Y) - cursor).Magnitude
                    if distCursor <= fovRadius then
                        local distPlayer = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
                                            (LocalPlayer.Character.HumanoidRootPart.Position - targetPart.Position).Magnitude) or math.huge
                        local health = humanoid.Health / math.max(humanoid.MaxHealth, 1)
                        table.insert(candidates, {
                            Part = targetPart,
                            DistCursor = distCursor,
                            DistPlayer = distPlayer,
                            Health = health,
                            Player = player,
                        })
                    end
                end
            end
        end
    end

    if #candidates == 0 then return nil end

    local primaryKey = (targetSelection == "Distance Priority" or targetSelection == "Closest") and "DistPlayer" or "DistCursor"
    local secondaryKey
    if targetPriority == "Closest" then
        secondaryKey = "DistPlayer"
    elseif targetPriority == "Lowest Health" then
        secondaryKey = "Health"
    else
        secondaryKey = "DistCursor"
    end

    table.sort(candidates, function(a, b)
        if a[primaryKey] ~= b[primaryKey] then
            return a[primaryKey] < b[primaryKey]
        end
        if primaryKey ~= secondaryKey then
            return a[secondaryKey] < b[secondaryKey]
        end
        return false
    end)

    return candidates[1].Part
end

-- ===== Silent Aim Hook =====
local function FindBulletFunction()
    local controller = LocalPlayer.PlayerScripts:FindFirstChild("Controller")
    if not controller then return nil end
    local function MatchesController(candidate)
        if not debug or not debug.getinfo then return false end
        local success, info = pcall(debug.getinfo, candidate)
        return success and info and info.source == "=" .. controller:GetFullName()
    end
    if filtergc then
        local result = filtergc("function", {
            Constants = {"Bullet", "EasterEggThing", "SCP-066"},
            IgnoreExecutor = true,
        })
        if type(result) == "function" and MatchesController(result) then return result end
        if type(result) == "table" then
            for _, candidate in ipairs(result) do
                if type(candidate) == "function" and MatchesController(candidate) then return candidate end
            end
        end
    end
    if getgc and debug and debug.getconstants then
        for _, candidate in ipairs(getgc()) do
            if type(candidate) == "function" then
                local success, constants = pcall(debug.getconstants, candidate)
                if success and constants and MatchesController(candidate) and table.find(constants, "Bullet") and table.find(constants, "EasterEggThing") and table.find(constants, "SCP-066") then
                    return candidate
                end
            end
        end
    end
end

local function InstallSilentAimHook()
    if SilentAimHookInstalled then return true end
    local bulletFunction = FindBulletFunction()
    if not bulletFunction then
        warn("Silent Aim: Could not find bullet function.")
        return false
    end
    local original
    original = hookfunction(bulletFunction, function(_, hitResult, ...)
        local target = GetSilentAimTarget()
        if target and math.random(1, 100) <= Config.SilentAimHitChance then
            return original(_, {
                Instance = target,
                Position = target.Position,
                Normal = Vector3.new(0, 1, 0),
                Material = target.Material,
            }, ...)
        end
        return original(_, hitResult, ...)
    end)
    SilentAimHookInstalled = true
    return true
end

-- ===== Auto Trigger – Hold‑based =====
local function PressShoot()
    if mouse1press then
        mouse1press()
        return true
    elseif keypress then
        keypress(0x01)
        return true
    else
        local VIM = game:GetService("VirtualInputManager")
        if VIM then
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            return true
        end
    end
    return false
end

local function ReleaseShoot()
    if mouse1release then
        mouse1release()
        return true
    elseif keyrelease then
        keyrelease(0x01)
        return true
    else
        local VIM = game:GetService("VirtualInputManager")
        if VIM then
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            return true
        end
    end
    return false
end

local function StartAutoTrigger()
    if AutoTriggerConnection then return end
    AutoTriggerConnection = RunService.RenderStepped:Connect(function()
        if not Config.AutoTriggerEnabled then
            if ShootHeld then
                ReleaseShoot()
                ShootHeld = false
            end
            return
        end

        local target = GetSilentAimTarget()
        if target then
            if not ShootHeld then
                PressShoot()
                ShootHeld = true
            end
        else
            if ShootHeld then
                ReleaseShoot()
                ShootHeld = false
            end
        end
    end)
end

local function StopAutoTrigger()
    if AutoTriggerConnection then
        AutoTriggerConnection:Disconnect()
        AutoTriggerConnection = nil
    end
    if ShootHeld then
        ReleaseShoot()
        ShootHeld = false
    end
end

-- ===== Auto Reload =====
local function PressRKey()
    if keypress and keyrelease then
        keypress(0x52)
        task.wait(0.05)
        keyrelease(0x52)
        return true
    else
        local VIM = game:GetService("VirtualInputManager")
        if VIM then
            VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game)
            return true
        end
    end
    return false
end

local function StartAutoReload()
    if AutoReloadConnection then return end
    AutoReloadConnection = RunService.RenderStepped:Connect(function()
        if not Config.AutoReloadEnabled then return end
        local playerGui = LocalPlayer.PlayerGui
        if not playerGui then return end
        local weaponUI = playerGui:FindFirstChild("WeaponUI")
        if not weaponUI then return end
        local reloadFrame = weaponUI:FindFirstChild("Reload")
        if not reloadFrame then return end

        local visible = reloadFrame.Visible
        if visible and not ReloadPressed then
            PressRKey()
            ReloadPressed = true
        elseif not visible then
            ReloadPressed = false
        end
    end)
end

local function StopAutoReload()
    if AutoReloadConnection then
        AutoReloadConnection:Disconnect()
        AutoReloadConnection = nil
    end
    ReloadPressed = false
end

-- ===== FOV circle render =====
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = Config.FOVCircleEnabled
    if Config.FOVCircleEnabled then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = Config.FOVRadius
        FOVCircle.Color = Config.FOVColor
    end
end)

-- ============================================================
--  UI ELEMENTS – COMBAT TAB
-- ============================================================
local Targeting = CombatTab:CreateSection("Targeting", "Normal")

Targeting:CreateToggle("Normal", {
    Name = "Silent Aim",
    Flag = "SilentAimEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        Config.SilentAimEnabled = Enabled
        if Enabled then
            if not InstallSilentAimHook() then
                Config.SilentAimEnabled = false
                Matrice.UI:Notify("Error", {
                    Title = "Hook Failed",
                    Content = "Could not find bullet function.",
                    Duration = 3,
                    Image = Matrice.Asset("circle-x.png")
                })
            end
        end
        print("Silent Aim " .. (Enabled and "ON" or "OFF"))
    end
})

Targeting:CreateDropdown({
    Name = "Hit Part",
    Options = {"Head", "UpperTorso", "HumanoidRootPart", "Randomized"},
    CurrentOption = "Head",
    Flag = "SilentAimHitPart",
    Callback = function(Selected)
        Config.SilentAimHitPart = Selected
        print("Hit Part set to " .. Selected)
    end
})

Targeting:CreateSlider({
    Name = "Hit Chance",
    Value = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "SilentAimHitChance",
    Callback = function(Value)
        Config.SilentAimHitChance = Value
        print("Hit Chance set to " .. Value .. "%")
    end
})

Targeting:CreateDropdown({
    Name = "Target Selection",
    Options = {"Distance Priority", "Closest", "FOV Priority"},
    CurrentOption = "Distance Priority",
    Flag = "TargetSelection",
    Callback = function(Selected)
        Config.TargetSelection = Selected
        print("Target Selection set to " .. Selected)
    end
})

Targeting:CreateDropdown({
    Name = "Target Priority",
    Options = {"Closest", "Lowest Health", "Crosshair Distance"},
    CurrentOption = "Closest",
    Flag = "TargetPriority",
    Callback = function(Selected)
        Config.TargetPriority = Selected
        print("Target Priority set to " .. Selected)
    end
})

Targeting:CreateToggle("Normal", {
    Name = "Hitbox",
    Flag = "HitboxEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        ToggleHitbox(Enabled)
        print("Hitbox " .. (Enabled and "ON" or "OFF"))
    end
})

Targeting:CreateSlider({
    Name = "Hitbox Size",
    Value = {1, 20},
    Increment = 0.5,
    Suffix = "studs",
    CurrentValue = 10,
    Flag = "HitboxSize",
    Callback = function(Value)
        Config.HitboxSize = Value
        if Config.HitboxEnabled then
            ApplyHitboxToAllPlayers()
        end
        print("Hitbox Size set to " .. Value)
    end
})

local Checks = CombatTab:CreateSection("Checks", "Normal")
Checks:CreateToggle("Normal", {
    Name = "Wall Check",
    Flag = "SilentAimWallCheck",
    CurrentValue = true,
    Callback = function(Enabled)
        Config.SilentAimWallCheck = Enabled
        print("Wall Check " .. (Enabled and "ON" or "OFF"))
    end
})
Checks:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "TeamCheck",
    CurrentValue = false,
    Callback = function(Enabled)
        print("Team Check (Combat) " .. (Enabled and "ON" or "OFF"))
    end
})
Checks:CreateToggle("Normal", {
    Name = "Friend Check",
    Flag = "SilentAimFriendCheck",
    CurrentValue = false,
    Callback = function(Enabled)
        Config.SilentAimFriendCheck = Enabled
        print("Friend Check (Silent Aim) " .. (Enabled and "ON" or "OFF"))
    end
})

local FOV = CombatTab:CreateSection("FOV", "Normal")
FOV:CreateToggle("Normal", {
    Name = "Show FOV Circle",
    Flag = "FOVCircleEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        Config.FOVCircleEnabled = Enabled
        if not Enabled then FOVCircle.Visible = false end
        print("Show FOV Circle " .. (Enabled and "ON" or "OFF"))
    end
})
FOV:CreateSlider({
    Name = "FOV Radius",
    Value = {25, 500},
    Increment = 5,
    Suffix = "px",
    Flag = "FOVRadius",
    CurrentValue = 150,
    Callback = function(Value)
        Config.FOVRadius = Value
        print("FOV Radius set to " .. Value)
    end
})
FOV:CreateColorPicker({
    Name = "FOV Color",
    Callback = function(Color)
        Config.FOVColor = Color
        print("FOV color changed to", Color)
    end
})

local Automation = CombatTab:CreateSection("Automation", "Normal")
Automation:CreateToggle("Normal", {
    Name = "Auto Trigger",
    Flag = "AutoTrigger",
    CurrentValue = false,
    Callback = function(Enabled)
        Config.AutoTriggerEnabled = Enabled
        if Enabled then
            StartAutoTrigger()
        else
            StopAutoTrigger()
        end
        print("Auto Trigger " .. (Enabled and "ON" or "OFF"))
    end
})
Automation:CreateToggle("Normal", {
    Name = "Auto Reload",
    Flag = "AutoReload",
    CurrentValue = false,
    Callback = function(Enabled)
        Config.AutoReloadEnabled = Enabled
        if Enabled then
            StartAutoReload()
        else
            StopAutoReload()
        end
        print("Auto Reload " .. (Enabled and "ON" or "OFF"))
    end
})

-- ============================================================
--  VISUALS TAB – ESP
-- ============================================================
local ESPData = {}
local ESPConnection = nil
local RenderConnection = nil
local CurrentTracerOrigin = "Bottom"

local function ClearESP(player)
    if ESPData[player] then
        for _, obj in pairs(ESPData[player]) do
            if type(obj) == "table" and obj.Remove then
                obj:Remove()
            elseif type(obj) == "userdata" then
                pcall(obj.Remove, obj)
            end
        end
        ESPData[player] = nil
    end
end

local function ClearAllESP()
    for p, _ in pairs(ESPData) do
        ClearESP(p)
    end
    ESPData = {}
end

local function GetPlayerColor(player)
    return player.TeamColor and player.TeamColor.Color or Color3.new(1, 1, 1)
end

local function BuildESP(player)
    if player == LocalPlayer or not player.Character then return end

    local teamColor = GetPlayerColor(player)
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local esp = {}

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = teamColor
    box.Filled = false
    box.Transparency = 1
    box.Visible = false
    esp.Box = box

    local nameText = Drawing.new("Text")
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0)
    nameText.Color = teamColor
    nameText.Size = 18
    nameText.Visible = false
    nameText.Text = player.Name
    esp.Name = nameText

    local distText = Drawing.new("Text")
    distText.Center = true
    distText.Outline = true
    distText.OutlineColor = Color3.new(0, 0, 0)
    distText.Color = Color3.new(1, 1, 1)
    distText.Size = 14
    distText.Visible = false
    esp.Distance = distText

    local weaponText = Drawing.new("Text")
    weaponText.Center = true
    weaponText.Outline = true
    weaponText.OutlineColor = Color3.new(0, 0, 0)
    weaponText.Color = Color3.new(1, 1, 1)
    weaponText.Size = 14
    weaponText.Visible = false
    esp.Weapon = weaponText

    local healthOutline = Drawing.new("Square")
    healthOutline.Thickness = 0
    healthOutline.Filled = true
    healthOutline.Color = Color3.fromRGB(18, 20, 28)
    healthOutline.Transparency = 1
    healthOutline.Visible = false
    esp.HealthOutline = healthOutline

    local healthFill = Drawing.new("Square")
    healthFill.Thickness = 0
    healthFill.Filled = true
    healthFill.Transparency = 1
    healthFill.Visible = false
    esp.HealthFill = healthFill

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Color = teamColor
    tracer.Transparency = 1
    tracer.Visible = false
    esp.Tracer = tracer

    if Config.SkeletonEnabled then
        local skeleton = Visuals:CreateVisual("Drawing", {
            Type = "Skeleton",
            Player = player,
            Color = teamColor,
            Thickness = 1
        })
        esp.Skeleton = skeleton
    end

    if Config.HighlightEnabled then
        local highlight = Visuals:CreateVisual("Highlight", {
            Target = player.Character,
            Color = teamColor,
            Transparency = 0.5,
            StrokeColor = Color3.new(1, 1, 1),
            OutlineTransparency = 0,
        })
        esp.Highlight = highlight
    end

    local chams = {}
    if Config.ChamsEnabled and player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                chams[part] = part.Material
                part.Material = Enum.Material.ForceField
            end
        end
    end
    esp.ChamsCleanup = {
        Remove = function()
            for part, mat in pairs(chams) do
                if part and part.Parent then
                    part.Material = mat
                end
            end
        end
    }

    ESPData[player] = esp
end

local function RebuildESP()
    ClearAllESP()
    if not Config.ESPEnabled then return end
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if targetRoot and humanoid and humanoid.Health > 0 and player.Parent == Players then
                local distance = (localRoot.Position - targetRoot.Position).Magnitude
                if distance <= Config.DistanceLimit then
                    BuildESP(player)
                end
            end
        end
    end
end

local function UpdateESP()
    if not Config.ESPEnabled then return end
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then
        ClearAllESP()
        return
    end

    local activePlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if root and humanoid and humanoid.Health > 0 and player.Parent == Players then
                local distance = (localRoot.Position - root.Position).Magnitude
                if distance <= Config.DistanceLimit then
                    activePlayers[player] = true
                    if not ESPData[player] then
                        BuildESP(player)
                    end
                else
                    if ESPData[player] then
                        ClearESP(player)
                    end
                end
            else
                if ESPData[player] then
                    ClearESP(player)
                end
            end
        end
    end
    for p, _ in pairs(ESPData) do
        if not activePlayers[p] then
            ClearESP(p)
        end
    end
end

local function RenderESP()
    if not Config.ESPEnabled then
        for _, esp in pairs(ESPData) do
            for _, obj in pairs(esp) do
                if type(obj) == "userdata" and obj.Visible ~= nil then
                    obj.Visible = false
                elseif type(obj) == "table" and obj.Visible ~= nil then
                    obj.Visible = false
                end
            end
        end
        return
    end

    local viewport = Camera.ViewportSize
    local centerX = viewport.X / 2
    local centerY = viewport.Y
    local localTeam = LocalPlayer.Team

    for player, esp in pairs(ESPData) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if Config.TeamCheckEnabled and localTeam and player.Team == localTeam then
                    for _, obj in pairs(esp) do
                        if type(obj) == "userdata" and obj.Visible ~= nil then
                            obj.Visible = false
                        elseif type(obj) == "table" and obj.Visible ~= nil then
                            obj.Visible = false
                        end
                    end
                    continue
                end

                if Config.FriendCheckEnabled and FriendList[player.UserId] then
                    for _, obj in pairs(esp) do
                        if type(obj) == "userdata" and obj.Visible ~= nil then
                            obj.Visible = false
                        elseif type(obj) == "table" and obj.Visible ~= nil then
                            obj.Visible = false
                        end
                    end
                    continue
                end

                local onScreen, size, pos, torsoPos = Visuals:GetBoundingBox(player)
                if onScreen then
                    local teamColor = GetPlayerColor(player)
                    local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
                                      (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude) or 0

                    if Config.BoxEnabled and esp.Box then
                        esp.Box.Size = size
                        esp.Box.Position = pos
                        esp.Box.Color = teamColor
                        esp.Box.Visible = true
                    elseif esp.Box then
                        esp.Box.Visible = false
                    end

                    if Config.NameEnabled and esp.Name then
                        esp.Name.Position = Vector2.new(pos.X + size.X/2, pos.Y - 20)
                        esp.Name.Text = player.Name
                        esp.Name.Color = teamColor
                        esp.Name.Visible = true
                    elseif esp.Name then
                        esp.Name.Visible = false
                    end

                    if Config.DistanceEnabled and esp.Distance then
                        esp.Distance.Position = Vector2.new(pos.X + size.X/2, pos.Y + size.Y + 16)
                        esp.Distance.Text = math.floor(distance) .. " studs"
                        esp.Distance.Visible = true
                    elseif esp.Distance then
                        esp.Distance.Visible = false
                    end

                    if Config.WeaponEnabled and esp.Weapon then
                        local weaponName = "None"
                        local ammoText = ""
                        local character = player.Character
                        if character then
                            for _, child in ipairs(character:GetChildren()) do
                                if child:IsA("Tool") then
                                    local ammo = child:FindFirstChild("Ammo")
                                    local currentAmmo = child:FindFirstChild("CurrentAmmo")
                                    local mag = child:FindFirstChild("_Mag")
                                    local identifier = child:FindFirstChild("Identifier")
                                    if ammo and currentAmmo and mag and identifier then
                                        weaponName = child.Name
                                        if ammo:IsA("IntValue") and currentAmmo:IsA("IntValue") then
                                            ammoText = " [" .. currentAmmo.Value .. "/" .. ammo.Value .. "]"
                                        end
                                        break
                                    end
                                end
                            end
                            if weaponName == "None" then
                                local tool = character:FindFirstChildOfClass("Tool")
                                if tool then
                                    weaponName = tool.Name
                                end
                            end
                        end
                        esp.Weapon.Text = weaponName .. ammoText
                        esp.Weapon.Position = Vector2.new(pos.X + size.X/2, pos.Y + size.Y + 34)
                        esp.Weapon.Visible = true
                    elseif esp.Weapon then
                        esp.Weapon.Visible = false
                    end

                    if Config.HealthBarEnabled and esp.HealthOutline and esp.HealthFill then
                        local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                        local barX = pos.X - 8
                        local barY = pos.Y
                        local barHeight = size.Y
                        esp.HealthOutline.Position = Vector2.new(barX - 1, barY - 2)
                        esp.HealthOutline.Size = Vector2.new(5, barHeight + 4)
                        esp.HealthOutline.Visible = true
                        esp.HealthFill.Position = Vector2.new(barX, barY + barHeight * (1 - healthPercent))
                        esp.HealthFill.Size = Vector2.new(3, math.max(barHeight * healthPercent, 1))
                        esp.HealthFill.Color = Color3.fromHSV(healthPercent * 0.33, 0.9, 1)
                        esp.HealthFill.Visible = true
                    else
                        if esp.HealthOutline then esp.HealthOutline.Visible = false end
                        if esp.HealthFill then esp.HealthFill.Visible = false end
                    end

                    if Config.TracerEnabled and esp.Tracer then
                        local origin = CurrentTracerOrigin
                        local from
                        if origin == "Bottom" then
                            from = Vector2.new(centerX, centerY)
                        else
                            from = Vector2.new(centerX, centerY/2)
                        end
                        esp.Tracer.From = from
                        esp.Tracer.To = Vector2.new(pos.X + size.X/2, pos.Y + size.Y)
                        esp.Tracer.Color = teamColor
                        esp.Tracer.Visible = true
                    elseif esp.Tracer then
                        esp.Tracer.Visible = false
                    end

                    -- Skeleton and Highlight are handled by VisualLibrary internally
                else
                    for _, obj in pairs(esp) do
                        if type(obj) == "userdata" and obj.Visible ~= nil then
                            obj.Visible = false
                        elseif type(obj) == "table" and obj.Visible ~= nil then
                            obj.Visible = false
                        end
                    end
                end
            else
                for _, obj in pairs(esp) do
                    if type(obj) == "userdata" and obj.Visible ~= nil then
                        obj.Visible = false
                    elseif type(obj) == "table" and obj.Visible ~= nil then
                        obj.Visible = false
                    end
                end
            end
        else
            for _, obj in pairs(esp) do
                if type(obj) == "userdata" and obj.Visible ~= nil then
                    obj.Visible = false
                elseif type(obj) == "table" and obj.Visible ~= nil then
                    obj.Visible = false
                end
            end
        end
    end
end

local function StartESP()
    if ESPConnection then ESPConnection:Disconnect() end
    if RenderConnection then RenderConnection:Disconnect() end
    ESPConnection = RunService.Heartbeat:Connect(UpdateESP)
    RenderConnection = RunService.RenderStepped:Connect(RenderESP)
    StartFriendListUpdates()
end

local function StopESP()
    if ESPConnection then ESPConnection:Disconnect(); ESPConnection = nil end
    if RenderConnection then RenderConnection:Disconnect(); RenderConnection = nil end
    if FriendListAddedConnection then
        FriendListAddedConnection:Disconnect()
        FriendListAddedConnection = nil
    end
    if FriendListUpdateTask then task.cancel(FriendListUpdateTask); FriendListUpdateTask = nil end
    ClearAllESP()
end

local ESPSection = VisualsTab:CreateSection("ESP", "Normal")
ESPSection:CreateToggle("Normal", {
    Name = "Enable ESP",
    Flag = "ESPEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        Config.ESPEnabled = Enabled
        if Enabled then
            StartESP()
        else
            StopESP()
        end
    end
})
ESPSection:CreateDivider()
ESPSection:CreateToggle("Normal", { Name = "Box ESP", Flag = "BoxEnabled", CurrentValue = false, Callback = function(Enabled) Config.BoxEnabled = Enabled end })
ESPSection:CreateToggle("Normal", { Name = "Name ESP", Flag = "NameEnabled", CurrentValue = false, Callback = function(Enabled) Config.NameEnabled = Enabled end })
ESPSection:CreateToggle("Normal", { Name = "Distance ESP", Flag = "DistanceEnabled", CurrentValue = false, Callback = function(Enabled) Config.DistanceEnabled = Enabled end })
ESPSection:CreateToggle("Normal", { Name = "Weapon ESP", Flag = "WeaponEnabled", CurrentValue = false, Callback = function(Enabled) Config.WeaponEnabled = Enabled end })
ESPSection:CreateToggle("Normal", { Name = "Health Bar", Flag = "HealthBarEnabled", CurrentValue = false, Callback = function(Enabled) Config.HealthBarEnabled = Enabled end })
ESPSection:CreateToggle("Normal", { Name = "Skeleton ESP", Flag = "SkeletonEnabled", CurrentValue = false, Callback = function(Enabled) Config.SkeletonEnabled = Enabled; if Config.ESPEnabled then RebuildESP() end })
ESPSection:CreateToggle("Normal", { Name = "Team Check", Flag = "TeamCheckEnabled", CurrentValue = false, Callback = function(Enabled) Config.TeamCheckEnabled = Enabled end })
ESPSection:CreateToggle("Normal", { Name = "Friend Check", Flag = "FriendCheckEnabled", CurrentValue = false, Callback = function(Enabled) Config.FriendCheckEnabled = Enabled end })
ESPSection:CreateSlider({
    Name = "Distance Limit",
    Value = {50, 2000},
    Increment = 50,
    Suffix = " studs",
    Flag = "DistanceLimit",
    CurrentValue = 600,
    Callback = function(Value) Config.DistanceLimit = Value end
})

local EffectsSection = VisualsTab:CreateSection("Effects", "Normal")
EffectsSection:CreateToggle("Normal", { Name = "Highlight", Flag = "HighlightEnabled", CurrentValue = false, Callback = function(Enabled) Config.HighlightEnabled = Enabled; if Config.ESPEnabled then RebuildESP() end })
EffectsSection:CreateToggle("Normal", { Name = "Chams", Flag = "ChamsEnabled", CurrentValue = false, Callback = function(Enabled) Config.ChamsEnabled = Enabled; if Config.ESPEnabled then RebuildESP() end })
EffectsSection:CreateToggle("Normal", { Name = "Tracer Lines", Flag = "TracerEnabled", CurrentValue = false, Callback = function(Enabled) Config.TracerEnabled = Enabled end })
EffectsSection:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Center"},
    CurrentOption = "Bottom",
    Flag = "TracerOrigin",
    Callback = function(Selected) Config.TracerOrigin = Selected; CurrentTracerOrigin = Selected end
})

-- ============================================================
--  PLAYER TAB – Spoof, NoClip, Fly
-- ============================================================
local Character = PlayerTab:CreateSection("Character", "Normal")

local SpoofActive = false
local SpoofedWalk = 16
local SpoofedJump = 50
local cachedHumanoids = {}
local GetDebugIdHandler = Instance.new("BindableFunction")
local TempHumanoid = Instance.new("Humanoid")
local indexHook, newIndexHook
local MovementCharacterConnection = nil
local CurrentHumanoid = nil

function GetDebugIdHandler.OnInvoke(obj)
    return obj:GetDebugId()
end
local function GetDebugId(obj)
    return GetDebugIdHandler:Invoke(obj)
end

local function GetSpoofValue(value)
    TempHumanoid.WalkSpeed = value
    return TempHumanoid.WalkSpeed
end

function cachedHumanoids:cacheHumanoid(DebugId, Humanoid)
    cachedHumanoids[DebugId] = {
        currentWalk = indexHook(Humanoid, "WalkSpeed"),
        currentJump = indexHook(Humanoid, "JumpPower"),
        lastWalk = nil,
        lastJump = nil,
    }
    return self[DebugId]
end

local function SafeClone(obj)
    if cloneref then
        return cloneref(obj)
    else
        return obj
    end
end

indexHook = hookmetamethod(game, "__index", function(self, index)
    if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
        local DebugId = GetDebugId(self)
        local cached = cachedHumanoids[DebugId]
        if self:IsDescendantOf(LocalPlayer.Character) or cached then
            if type(index) == "string" then
                local clean = string.split(index, "\0")[1]
                if clean == "WalkSpeed" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(DebugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = SafeClone(self)
                    end
                    return cached.lastWalk or cached.currentWalk
                elseif clean == "JumpPower" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(DebugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = SafeClone(self)
                    end
                    return cached.lastJump or cached.currentJump
                end
            end
        end
    end
    return indexHook(self, index)
end)

newIndexHook = hookmetamethod(game, "__newindex", function(self, index, newValue)
    if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
        local DebugId = GetDebugId(self)
        local cached = cachedHumanoids[DebugId]
        if self:IsDescendantOf(LocalPlayer.Character) or cached then
            if type(index) == "string" then
                local clean = string.split(index, "\0")[1]
                if clean == "WalkSpeed" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(DebugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = SafeClone(self)
                    end
                    cached.lastWalk = GetSpoofValue(newValue)
                    return CurrentHumanoid.WalkSpeed
                elseif clean == "JumpPower" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(DebugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = SafeClone(self)
                    end
                    cached.lastJump = GetSpoofValue(newValue)
                    return CurrentHumanoid.JumpPower
                end
            end
        end
    end
    return newIndexHook(self, index, newValue)
end)

local function GetHumanoid()
    return CurrentHumanoid or (function()
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            cachedHumanoids:cacheHumanoid(humanoid:GetDebugId(), humanoid)
            return SafeClone(humanoid)
        end
    end)()
end

local function SetWalkSpeed(speed)
    local humanoid = GetHumanoid()
    if not humanoid then return end
    local connections = {}
    local function AddConnections(Signal)
        for _, conn in ipairs(getconnections(Signal) or {}) do
            if conn.State then
                conn:Disable()
                table.insert(connections, conn)
            end
        end
    end
    AddConnections(humanoid.Changed)
    AddConnections(humanoid:GetPropertyChangedSignal("WalkSpeed"))
    humanoid.WalkSpeed = speed
    for _, conn in connections do conn:Enable() end
end

local function SetJumpPower(power)
    local humanoid = GetHumanoid()
    if not humanoid then return end
    local connections = {}
    local function AddConnections(Signal)
        for _, conn in ipairs(getconnections(Signal) or {}) do
            if conn.State then
                conn:Disable()
                table.insert(connections, conn)
            end
        end
    end
    AddConnections(humanoid.Changed)
    AddConnections(humanoid:GetPropertyChangedSignal("JumpPower"))
    humanoid.JumpPower = power
    for _, conn in connections do conn:Enable() end
end

local function RestoreMovement()
    local humanoid = GetHumanoid()
    if humanoid then
        local debugId = humanoid:GetDebugId()
        local cached = cachedHumanoids[debugId]
        if cached then
            SetWalkSpeed(cached.lastWalk or cached.currentWalk)
            SetJumpPower(cached.lastJump or cached.currentJump)
        else
            SetWalkSpeed(16)
            SetJumpPower(50)
        end
    end
end

local function EnableSpoof(walk, jump)
    SpoofActive = true
    SpoofedWalk = walk or SpoofedWalk
    SpoofedJump = jump or SpoofedJump
    local humanoid = GetHumanoid()
    if humanoid then
        cachedHumanoids:cacheHumanoid(humanoid:GetDebugId(), humanoid)
        SetWalkSpeed(SpoofedWalk)
        SetJumpPower(SpoofedJump)
    end
    if not MovementCharacterConnection then
        MovementCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.1)
            local humanoid = char:FindFirstChildWhichIsA("Humanoid")
            if humanoid and SpoofActive then
                cachedHumanoids:cacheHumanoid(humanoid:GetDebugId(), humanoid)
                SetWalkSpeed(SpoofedWalk)
                SetJumpPower(SpoofedJump)
            end
        end)
    end
end

local function DisableSpoof()
    SpoofActive = false
    RestoreMovement()
    if MovementCharacterConnection then
        MovementCharacterConnection:Disconnect()
        MovementCharacterConnection = nil
    end
end

local SpeedEnabled = false
local JumpEnabled = false
local WalkSpeedValue = 24
local JumpPowerValue = 50

local NoClipMaster = false
local NoClipActive = false
local FlyMaster = false
local FlyActive = false
local FlySpeedValue = 50

local PlayerModsCharacterAddedConnection = nil

local function ApplyNoClip()
    local Char = LocalPlayer.Character
    if not Char then return end
    local State = NoClipMaster and NoClipActive
    for _, Part in ipairs(Char:GetDescendants()) do
        if Part:IsA("BasePart") then
            Part.CanCollide = not State
        end
    end
end

local FlyConnection = nil
local FlyCharacterConnection = nil

local function StartFly()
    if FlyConnection then return end
    FlyConnection = RunService.Heartbeat:Connect(function(dt)
        if not (FlyMaster and FlyActive) or not LocalPlayer.Character then return end
        local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not Root then return end
        local Forward = Camera.CFrame.LookVector
        local Right = Camera.CFrame.RightVector
        local Up = Vector3.new(0, 1, 0)
        local MoveDirection = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then MoveDirection = MoveDirection + Forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then MoveDirection = MoveDirection - Forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then MoveDirection = MoveDirection - Right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then MoveDirection = MoveDirection + Right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then MoveDirection = MoveDirection + Up end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then MoveDirection = MoveDirection - Up end
        if MoveDirection.Magnitude > 0 then
            MoveDirection = MoveDirection.Unit * FlySpeedValue
        end
        Root.CFrame = Root.CFrame + MoveDirection * dt
        Root.Velocity = Vector3.new()
        Root.RotVelocity = Vector3.new()
    end)
    if not FlyCharacterConnection then
        FlyCharacterConnection = LocalPlayer.CharacterAdded:Connect(function()
            if FlyMaster and FlyActive then
                task.wait(0.1)
                local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if Root then
                    Root.Velocity = Vector3.new()
                    Root.RotVelocity = Vector3.new()
                end
            end
        end)
    end
end

local function StopFly()
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    if FlyCharacterConnection then
        FlyCharacterConnection:Disconnect()
        FlyCharacterConnection = nil
    end
end

local function UpdateFly()
    if FlyMaster and FlyActive then
        StartFly()
    else
        StopFly()
    end
end

local function OnCharacterAdded()
    task.wait(0.1)
    ApplyNoClip()
end

local function SetupCharacterAddedListener()
    if PlayerModsCharacterAddedConnection then
        PlayerModsCharacterAddedConnection:Disconnect()
    end
    PlayerModsCharacterAddedConnection = LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
end

Character:CreateToggle("Normal", {
    Name = "Enable Walk Speed",
    Flag = "WalkSpeedEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        SpeedEnabled = Enabled
        if Enabled then
            if not SpoofActive then
                EnableSpoof(WalkSpeedValue, JumpPowerValue)
            else
                SpoofedWalk = WalkSpeedValue
                SetWalkSpeed(WalkSpeedValue)
            end
        else
            if JumpEnabled then
                local humanoid = GetHumanoid()
                if humanoid then
                    local debugId = humanoid:GetDebugId()
                    local cached = cachedHumanoids[debugId]
                    if cached and cached.currentWalk then
                        SetWalkSpeed(cached.currentWalk)
                    else
                        SetWalkSpeed(16)
                    end
                end
            else
                DisableSpoof()
            end
        end
        print("Enable Walk Speed " .. (Enabled and "ON" or "OFF"))
    end
})
Character:CreateSlider({
    Name = "Walk Speed",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = 24,
    Flag = "WalkSpeed",
    Callback = function(Value)
        WalkSpeedValue = Value
        if SpeedEnabled and SpoofActive then
            SpoofedWalk = Value
            SetWalkSpeed(Value)
        end
        print("Walk Speed set to " .. Value)
    end
})
Character:CreateToggle("Normal", {
    Name = "Enable Jump Power",
    Flag = "JumpPowerEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        JumpEnabled = Enabled
        if Enabled then
            if not SpoofActive then
                EnableSpoof(WalkSpeedValue, JumpPowerValue)
            else
                SpoofedJump = JumpPowerValue
                SetJumpPower(JumpPowerValue)
            end
        else
            if SpeedEnabled then
                local humanoid = GetHumanoid()
                if humanoid then
                    local debugId = humanoid:GetDebugId()
                    local cached = cachedHumanoids[debugId]
                    if cached and cached.currentJump then
                        SetJumpPower(cached.currentJump)
                    else
                        SetJumpPower(50)
                    end
                end
            else
                DisableSpoof()
            end
        end
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
        JumpPowerValue = Value
        if JumpEnabled and SpoofActive then
            SpoofedJump = Value
            SetJumpPower(Value)
        end
        print("Jump Power set to " .. Value)
    end
})
Character:CreateToggle("Normal", {
    Name = "No Clip",
    Flag = "NoClip",
    CurrentValue = false,
    Callback = function(Enabled)
        NoClipMaster = Enabled
        if not Enabled then
            NoClipActive = false
        else
            NoClipActive = true
        end
        ApplyNoClip()
        print("No Clip " .. (Enabled and "ON" or "OFF"))
    end
})
Character:CreateKeybind({
    Name = "No Clip Keybind",
    Flag = "NoClipKeybind",
    Keybind = "N",
    Type = "Press",
    Callback = function(State)
        if NoClipMaster then
            NoClipActive = not NoClipActive
            ApplyNoClip()
            print("No Clip active " .. (NoClipActive and "ON" or "OFF"))
        else
            print("No Clip master toggle is off, keybind ignored")
        end
    end
})
Character:CreateToggle("Normal", {
    Name = "Fly",
    Flag = "Fly",
    CurrentValue = false,
    Callback = function(Enabled)
        FlyMaster = Enabled
        if not Enabled then
            FlyActive = false
        else
            FlyActive = true
        end
        UpdateFly()
        print("Fly " .. (Enabled and "ON" or "OFF"))
    end
})
Character:CreateKeybind({
    Name = "Fly Keybind",
    Flag = "FlyKeybind",
    Keybind = "F",
    Type = "Press",
    Callback = function(State)
        if FlyMaster then
            FlyActive = not FlyActive
            UpdateFly()
            print("Fly active " .. (FlyActive and "ON" or "OFF"))
        else
            print("Fly master toggle is off, keybind ignored")
        end
    end
})
Character:CreateSlider({
    Name = "Fly Speed",
    Value = {10, 200},
    Increment = 5,
    Suffix = "studs/s",
    Flag = "FlySpeed",
    CurrentValue = 50,
    Callback = function(Value)
        FlySpeedValue = Value
        print("Fly Speed set to " .. Value)
    end
})
SetupCharacterAddedListener()

-- ============================================================
--  UTILITIES TAB
-- ============================================================
local Miscellaneous = UtilitiesTab:CreateSection("Miscellaneous", "Normal")

local ModeratorDetectorEnabled = false
local ModeratorDetectorAddedConnection = nil
local ModeratorDetectorRemovingConnection = nil

Miscellaneous:CreateToggle("Normal", {
    Name = "Moderator Detector",
    Flag = "ModeratorDetector",
    Callback = function(Enabled)
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
        print("Moderator Detector " .. (Enabled and "ON" or "OFF"))
    end
})

local AntiAFKSection = UtilitiesTab:CreateSection("Anti AFK", "Normal")
local AntiAFKEnabled = false
local AntiAFKConnection = nil

AntiAFKSection:CreateToggle("Normal", {
    Name = "Enable Anti AFK",
    Flag = "AntiAFK",
    Callback = function(Enabled)
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
        print("Anti AFK " .. (Enabled and "ON" or "OFF"))
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