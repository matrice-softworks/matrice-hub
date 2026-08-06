-- Matrice Softworks – SCP: Roleplay (v2 UI + full features)
local UI = Matrice.UI
local Visuals = Matrice.Visuals
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
--  CONFIGURATION
-- ============================================================

local Config = {
    -- Silent Aim
    SilentAim = false,
    HitPart = "Head",
    HitChance = 100,
    TargetSelection = "Distance Priority",
    TargetPriority = "Closest",
    Hitbox = false,
    HitboxSize = 1,
    WallCheck = true,
    TeamCheck = true,
    ShowFOV = false,
    FOVRadius = 120,
    FOVColor = Color3.fromRGB(255, 255, 255),
    AutoTrigger = false,
    TriggerDelay = 50,
    AutoReload = false,

    -- ESP
    ESPEnabled = false,
    ESPBox = false,
    ESPName = false,
    ESPDistance = false,
    ESPWeapon = false,
    ESPHealthBar = false,
    ESPSkeleton = false,
    ESPTeamCheck = false,
    FriendCheck = false,
    DistanceLimit = 500,
    Highlight = false,
    Chams = false,
    TracerLines = false,
    TracerOrigin = "Bottom",

    -- Player
    WalkSpeedEnabled = false,
    WalkSpeed = 16,
    JumpPowerEnabled = false,
    JumpPower = 50,
    NoClip = false,
    NoClipKeybind = "N",
    Fly = false,
    FlyKeybind = "F",
    FlySpeed = 50,

    -- Utilities
    ModeratorDetector = false,
    AntiAFK = false,

    -- UI
    ToggleMenuKey = "LeftAlt",
}

local CONFIG_FILE = "SCP-RP-v2-Config.json"

local function SaveConfig()
    local ok, err = Matrice.SaveConfiguration(Config, CONFIG_FILE)
    if not ok then warn("Failed to save config:", err) end
end

local function LoadConfig()
    local data, err = Matrice.LoadConfiguration(CONFIG_FILE)
    if data then
        for k, v in pairs(data) do
            Config[k] = v
        end
        return true
    else
        if err and err ~= "Config file not found" then
            warn("Failed to load config:", err)
        end
        return false
    end
end

local function ResetConfig()
    Config = {
        SilentAim = false,
        HitPart = "Head",
        HitChance = 100,
        TargetSelection = "Distance Priority",
        TargetPriority = "Closest",
        Hitbox = false,
        HitboxSize = 1,
        WallCheck = true,
        TeamCheck = true,
        ShowFOV = false,
        FOVRadius = 120,
        FOVColor = Color3.fromRGB(255, 255, 255),
        AutoTrigger = false,
        TriggerDelay = 50,
        AutoReload = false,
        ESPEnabled = false,
        ESPBox = false,
        ESPName = false,
        ESPDistance = false,
        ESPWeapon = false,
        ESPHealthBar = false,
        ESPSkeleton = false,
        ESPTeamCheck = false,
        FriendCheck = false,
        DistanceLimit = 500,
        Highlight = false,
        Chams = false,
        TracerLines = false,
        TracerOrigin = "Bottom",
        WalkSpeedEnabled = false,
        WalkSpeed = 16,
        JumpPowerEnabled = false,
        JumpPower = 50,
        NoClip = false,
        NoClipKeybind = "N",
        Fly = false,
        FlyKeybind = "F",
        FlySpeed = 50,
        ModeratorDetector = false,
        AntiAFK = false,
        ToggleMenuKey = "LeftAlt",
    }
    local ok, err = Matrice.ResetConfiguration(CONFIG_FILE)
    if not ok then warn("Failed to reset config:", err) end
    SaveConfig()
    UI:Notify("Warning", {
        Title = "Config Reset",
        Content = "Settings reset to defaults. Please reload the script.",
        Duration = 5,
        Image = Matrice.Asset("circle-alert"),
    })
end

-- Apply config to globals (for internal use)
for k, v in pairs(Config) do
    getgenv()["_" .. k] = v
end

LoadConfig()

-- ============================================================
--  FEATURE STATE VARIABLES
-- ============================================================

-- Silent Aim
local SilentAimHookInstalled = false
local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Visible = false
local SilentAimRaycastParams = RaycastParams.new()
SilentAimRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
SilentAimRaycastParams.IgnoreWater = true

-- ESP
local PlayerESPs = {}
local ESPConnections = {}

-- NoClip / Fly
local NoClipActive = false
local NoClipConnection = nil
local NoClipCharConnection = nil
local FlyActive = false
local FlyConnection = nil
local FlyCharConnection = nil

-- Moderator Detector
local ModeratorDetectorAddedConnection = nil
local ModeratorDetectorRemovingConnection = nil
local ModNotifiedPlayers = {}

-- Anti AFK
local AntiAFKEnabled = false
local AntiAFKConnection = nil

-- Hostile Teams (for team check)
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

-- ============================================================
--  HELPER FUNCTIONS
-- ============================================================

local function IsEnemy(player)
    if Config.TeamCheck then
        local localTeam = LocalPlayer.Team and HostileTeams[LocalPlayer.Team.Name]
        local targetTeam = player.Team and HostileTeams[player.Team.Name]
        return localTeam ~= nil and targetTeam ~= nil and localTeam ~= targetTeam
    end
    return true
end

local function IsFriend(player)
    return Config.FriendCheck and player:IsFriendsWith(LocalPlayer.UserId)
end

-- ============================================================
--  SILENT AIM
-- ============================================================

local function GetSilentAimTarget()
    if not Config.SilentAim then return nil end
    local camera = workspace.CurrentCamera
    local cursor = UserInputService:GetMouseLocation()
    local closestPart, closestDistance = nil, Config.FOVRadius
    local players = Players:GetPlayers()
    local priority = Config.TargetPriority

    for _, player in ipairs(players) do
        if player ~= LocalPlayer and not IsFriend(player) and IsEnemy(player) then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local hitPartName = Config.HitPart
                if hitPartName == "Random" then
                    local parts = {"Head", "UpperTorso", "HumanoidRootPart"}
                    hitPartName = parts[math.random(#parts)]
                end
                local targetPart = character:FindFirstChild(hitPartName) or character:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local visible = true
                        if Config.WallCheck then
                            local localChar = LocalPlayer.Character
                            if localChar then
                                SilentAimRaycastParams.FilterDescendantsInstances = {localChar}
                                local result = workspace:Raycast(camera.CFrame.Position, targetPart.Position - camera.CFrame.Position, SilentAimRaycastParams)
                                visible = not result or result.Instance:IsDescendantOf(character)
                            end
                        end
                        if visible then
                            local distance = (Vector2.new(screenPos.X, screenPos.Y) - cursor).Magnitude
                            local dist3D = (camera.CFrame.Position - targetPart.Position).Magnitude
                            local score = distance -- default: crosshair distance
                            if priority == "Closest" then score = dist3D
                            elseif priority == "Lowest Health" then score = humanoid.Health / humanoid.MaxHealth * 100
                            end
                            if closestPart == nil or score < closestDistance then
                                closestPart = targetPart
                                closestDistance = score
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPart
end

local function FindBulletFunction()
    local controller = LocalPlayer.PlayerScripts:FindFirstChild("Controller")
    if not controller then return nil end
    local function MatchesController(c)
        if not debug or not debug.getinfo then return false end
        local success, info = pcall(debug.getinfo, c)
        return success and info and info.source == "=" .. controller:GetFullName()
    end
    if filtergc then
        local res = filtergc("function", { Constants = {"Bullet", "EasterEggThing", "SCP-066"}, IgnoreExecutor = true })
        if type(res) == "function" and MatchesController(res) then return res end
        if type(res) == "table" then
            for _, c in ipairs(res) do
                if type(c) == "function" and MatchesController(c) then return c end
            end
        end
    end
    if getgc and debug and debug.getconstants then
        for _, c in ipairs(getgc()) do
            if type(c) == "function" then
                local success, consts = pcall(debug.getconstants, c)
                if success and consts and MatchesController(c) and table.find(consts, "Bullet") and table.find(consts, "EasterEggThing") and table.find(consts, "SCP-066") then
                    return c
                end
            end
        end
    end
end

local function InstallSilentAimHook()
    if SilentAimHookInstalled then return true end
    local bulletFunc = FindBulletFunction()
    if not bulletFunc then
        warn("Silent Aim: Could not find bullet function.")
        return false
    end
    local original
    original = hookfunction(bulletFunc, function(_, hitResult, ...)
        local target = GetSilentAimTarget()
        if target and math.random(1, 100) <= Config.HitChance then
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

-- ============================================================
--  ESP
-- ============================================================

local function ClearPlayerESP(player)
    if PlayerESPs[player] then
        for _, obj in ipairs(PlayerESPs[player]) do
            if obj and obj.Remove then obj:Remove() end
        end
        PlayerESPs[player] = nil
    end
    if ESPConnections[player] then
        ESPConnections[player]:Disconnect()
        ESPConnections[player] = nil
    end
end

local function ClearAllESP()
    for player, _ in pairs(PlayerESPs) do
        ClearPlayerESP(player)
    end
end

local function CreatePlayerESP(player)
    if player == LocalPlayer or not player.Character then return end
    local teamColor = player.TeamColor and player.TeamColor.Color or Color3.new(1,1,1)
    local espObjects = {}

    local function addDrawing(type, ...)
        if type == "Box" then
            local box = Drawing.new("Square")
            box.Thickness = 1
            box.Color = teamColor
            box.Filled = false
            box.Transparency = 1
            box.Visible = false
            table.insert(espObjects, box)
            return box
        elseif type == "Line" then
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.Color = teamColor
            line.Transparency = 1
            line.Visible = false
            table.insert(espObjects, line)
            return line
        end
    end

    -- Box
    local boxObj = nil
    if Config.ESPBox then
        boxObj = addDrawing("Box")
    end

    -- Name
    local nameObj = nil
    if Config.ESPName then
        nameObj = Drawing.new("Text")
        nameObj.Size = 14
        nameObj.Center = true
        nameObj.Outline = true
        nameObj.OutlineColor = Color3.new(0,0,0)
        nameObj.Color = teamColor
        nameObj.Visible = false
        table.insert(espObjects, nameObj)
    end

    -- Distance
    local distObj = nil
    if Config.ESPDistance then
        distObj = Drawing.new("Text")
        distObj.Size = 12
        distObj.Center = true
        distObj.Outline = true
        distObj.OutlineColor = Color3.new(0,0,0)
        distObj.Color = Color3.new(1,1,1)
        distObj.Visible = false
        table.insert(espObjects, distObj)
    end

    -- Weapon
    local weaponObj = nil
    if Config.ESPWeapon then
        weaponObj = Drawing.new("Text")
        weaponObj.Size = 12
        weaponObj.Center = true
        weaponObj.Outline = true
        weaponObj.OutlineColor = Color3.new(0,0,0)
        weaponObj.Color = Color3.new(1,1,1)
        weaponObj.Visible = false
        table.insert(espObjects, weaponObj)
    end

    -- Health bar
    local healthBarOutline, healthBarFill = nil, nil
    if Config.ESPHealthBar then
        healthBarOutline = Drawing.new("Square")
        healthBarOutline.Color = Color3.fromRGB(18,20,28)
        healthBarOutline.Filled = true
        healthBarOutline.Transparency = 1
        healthBarOutline.Visible = false
        table.insert(espObjects, healthBarOutline)

        healthBarFill = Drawing.new("Square")
        healthBarFill.Filled = true
        healthBarFill.Transparency = 1
        healthBarFill.Visible = false
        table.insert(espObjects, healthBarFill)
    end

    -- Skeleton (using Visuals library)
    local skeletonObj = nil
    if Config.ESPSkeleton then
        skeletonObj = Visuals:CreateVisual("Drawing", {
            Type = "Skeleton",
            Player = player,
            Color = teamColor,
            Thickness = 1
        })
        table.insert(espObjects, skeletonObj)
    end

    -- Highlight
    local highlightObj = nil
    if Config.Highlight then
        highlightObj = Visuals:CreateVisual("Highlight", {
            Target = player.Character,
            Color = teamColor,
            Transparency = 0.5,
            StrokeColor = Color3.new(1,1,1),
            OutlineTransparency = 0,
        })
        table.insert(espObjects, highlightObj)
    end

    -- Chams
    local chamsData = nil
    if Config.Chams and player.Character then
        chamsData = {}
        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                chamsData[v] = v.Material
                v.Material = Enum.Material.ForceField
            end
        end
        table.insert(espObjects, {Remove = function()
            for part, mat in pairs(chamsData) do
                if part and part.Parent then
                    part.Material = mat
                end
            end
        end})
    end

    -- Tracer
    local tracerObj = nil
    if Config.TracerLines then
        tracerObj = addDrawing("Line")
    end

    PlayerESPs[player] = espObjects

    -- Update team color on change
    ESPConnections[player] = player:GetPropertyChangedSignal("TeamColor"):Connect(function()
        if PlayerESPs[player] then
            local newColor = player.TeamColor and player.TeamColor.Color or Color3.new(1,1,1)
            for _, obj in ipairs(PlayerESPs[player]) do
                if obj.Color then
                    obj.Color = newColor
                end
                if obj.Object and obj.Object.FillColor then
                    obj.Object.FillColor = newColor
                end
                if obj.SetColor then
                    obj:SetColor(newColor)
                end
            end
        end
    end)
end

local function RebuildAllESP()
    if not Config.ESPEnabled then return end
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ClearPlayerESP(player)
            local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and player.Parent == Players then
                local distance = (localRoot.Position - targetRoot.Position).Magnitude
                if distance <= Config.DistanceLimit then
                    CreatePlayerESP(player)
                end
            end
        end
    end
end

-- Background ESP lifecycle
task.spawn(function()
    while task.wait(0.5) do
        if not Config.ESPEnabled then
            ClearAllESP()
            continue
        end

        local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot then continue end

        for player, _ in pairs(PlayerESPs) do
            if not player or player.Parent ~= Players then
                ClearPlayerESP(player)
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not IsFriend(player) then
                local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and player.Parent == Players then
                    local distance = (localRoot.Position - targetRoot.Position).Magnitude
                    if distance <= Config.DistanceLimit then
                        if not PlayerESPs[player] or not PlayerESPs[player].Character then
                            ClearPlayerESP(player)
                            CreatePlayerESP(player)
                        end
                    else
                        ClearPlayerESP(player)
                    end
                else
                    ClearPlayerESP(player)
                end
            end
        end
    end
end)

-- Render ESP positions
RunService.RenderStepped:Connect(function()
    -- FOV circle
    FOVCircle.Visible = Config.ShowFOV
    if Config.ShowFOV then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = Config.FOVRadius
        FOVCircle.Color = Config.FOVColor
    end

    if not Config.ESPEnabled then return end
    local camera = workspace.CurrentCamera
    local viewport = camera.ViewportSize

    for player, espObjs in pairs(PlayerESPs) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local onScreen, size, pos = Visuals:GetBoundingBox(player)
            if onScreen then
                local teamColor = player.TeamColor and player.TeamColor.Color or Color3.new(1,1,1)
                local humanoid = player.Character.Humanoid
                local healthPercent = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)

                for _, obj in ipairs(espObjs) do
                    if obj.Size and obj.Position then -- Box
                        obj.Size = size
                        obj.Position = pos
                        obj.Color = teamColor
                        obj.Visible = Config.ESPBox
                    elseif obj.From and obj.To then -- Tracer
                        local origin = Vector2.new(viewport.X/2, viewport.Y)
                        if Config.TracerOrigin == "Bottom" then
                            origin = Vector2.new(viewport.X/2, viewport.Y)
                        elseif Config.TracerOrigin == "Center" then
                            origin = Vector2.new(viewport.X/2, viewport.Y/2)
                        else -- Mouse
                            origin = UserInputService:GetMouseLocation()
                        end
                        obj.From = origin
                        obj.To = Vector2.new(pos.X + size.X/2, pos.Y + size.Y)
                        obj.Color = teamColor
                        obj.Visible = Config.TracerLines
                    elseif obj.Text and obj.Position then -- Text objects
                        if obj.Size == 14 then -- Name
                            obj.Text = player.Name
                            obj.Position = Vector2.new(pos.X + size.X/2, pos.Y - 20)
                            obj.Color = teamColor
                            obj.Visible = Config.ESPName
                        elseif obj.Size == 12 and obj.Text == "" then -- Distance
                            local dist = (camera.CFrame.Position - player.Character.HumanoidRootPart.Position).Magnitude
                            obj.Text = math.floor(dist) .. "m"
                            obj.Position = Vector2.new(pos.X + size.X/2, pos.Y + size.Y + 4)
                            obj.Visible = Config.ESPDistance
                        elseif obj.Size == 12 and string.find(obj.Text or "", "Weapon") then -- Weapon
                            -- Placeholder: find weapon name
                            local weapon = player.Character:FindFirstChildOfClass("Tool")
                            obj.Text = weapon and weapon.Name or "No Weapon"
                            obj.Position = Vector2.new(pos.X + size.X/2, pos.Y + size.Y + 20)
                            obj.Visible = Config.ESPWeapon
                        end
                    elseif obj.Color and obj.Filled then -- Health bar outline/fill
                        if obj.Size and obj.Position then -- outline
                            obj.Position = Vector2.new(pos.X - 8, pos.Y - 2)
                            obj.Size = Vector2.new(5, size.Y + 4)
                            obj.Visible = Config.ESPHealthBar
                        else -- fill
                            local barX = pos.X - 7
                            local barY = pos.Y + (size.Y) * (1 - healthPercent)
                            obj.Position = Vector2.new(barX, barY)
                            obj.Size = Vector2.new(3, math.max(size.Y * healthPercent, 1))
                            obj.Color = Color3.fromHSV(healthPercent * 0.33, 0.9, 1)
                            obj.Visible = Config.ESPHealthBar
                        end
                    end
                end
            else
                -- Hide all objects
                for _, obj in ipairs(espObjs) do
                    if obj.Visible ~= nil then obj.Visible = false end
                end
            end
        else
            for _, obj in ipairs(espObjs) do
                if obj.Visible ~= nil then obj.Visible = false end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(ClearPlayerESP)

-- ============================================================
--  NO CLIP
-- ============================================================

local function SetNoClipState(state)
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

local function EnableNoClip()
    if NoClipActive then return end
    NoClipActive = true
    SetNoClipState(true)
    NoClipCharConnection = LocalPlayer.CharacterAdded:Connect(function(char)
        if NoClipActive then
            task.wait(0.1)
            SetNoClipState(true)
        end
    end)
    UI:Notify("Normal", { Title = "NoClip", Content = "Enabled", Duration = 2, Image = Matrice.Asset("info") })
end

local function DisableNoClip()
    if not NoClipActive then return end
    NoClipActive = false
    SetNoClipState(false)
    if NoClipCharConnection then
        NoClipCharConnection:Disconnect()
        NoClipCharConnection = nil
    end
    UI:Notify("Warning", { Title = "NoClip", Content = "Disabled", Duration = 2, Image = Matrice.Asset("circle-alert") })
end

local function ToggleNoClip()
    Config.NoClip = not Config.NoClip
    if Config.NoClip then EnableNoClip() else DisableNoClip() end
    SaveConfig()
end

-- ============================================================
--  FLY
-- ============================================================

local function StartFly()
    if FlyActive or not LocalPlayer.Character then return end
    FlyActive = true
    FlyConnection = RunService.Heartbeat:Connect(function()
        if not FlyActive or not LocalPlayer.Character then return end
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local forward = workspace.CurrentCamera.CFrame.LookVector
        local right = workspace.CurrentCamera.CFrame.RightVector
        local up = Vector3.new(0,1,0)
        local move = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + up end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - up end

        if move.Magnitude > 0 then move = move.Unit * Config.FlySpeed end
        root.CFrame = root.CFrame + move * RunService.Heartbeat:Wait()
        root.Velocity = Vector3.new(0,0,0)
        root.RotVelocity = Vector3.new(0,0,0)
    end)

    FlyCharConnection = LocalPlayer.CharacterAdded:Connect(function(char)
        if FlyActive then
            task.wait(0.1)
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.Velocity = Vector3.new(0,0,0)
                root.RotVelocity = Vector3.new(0,0,0)
            end
        end
    end)

    UI:Notify("Normal", { Title = "Fly", Content = "Enabled", Duration = 2, Image = Matrice.Asset("info") })
end

local function StopFly()
    if not FlyActive then return end
    FlyActive = false
    if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
    if FlyCharConnection then FlyCharConnection:Disconnect(); FlyCharConnection = nil end
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.Velocity = Vector3.new(0,0,0)
            root.RotVelocity = Vector3.new(0,0,0)
        end
    end
    UI:Notify("Warning", { Title = "Fly", Content = "Disabled", Duration = 2, Image = Matrice.Asset("circle-alert") })
end

local function ToggleFly()
    Config.Fly = not Config.Fly
    if Config.Fly then StartFly() else StopFly() end
    SaveConfig()
end

-- ============================================================
--  WALK SPEED / JUMP POWER SPOOF (undetected)
-- ============================================================

local SpoofActive = false
local CurrentHumanoid = nil
local cachedHumanoids = {}
local GetDebugIdHandler = Instance.new("BindableFunction")
local TempHumanoid = Instance.new("Humanoid")
local indexHook, newIndexHook

function GetDebugIdHandler.OnInvoke(obj) return obj:GetDebugId() end
local function GetDebugId(obj) return GetDebugIdHandler:Invoke(obj) end

local function GetSpoofValue(v) TempHumanoid.WalkSpeed = v; return TempHumanoid.WalkSpeed end

function cachedHumanoids:cacheHumanoid(DebugId, Humanoid)
    cachedHumanoids[DebugId] = {
        currentWalk = indexHook(Humanoid, "WalkSpeed"),
        currentJump = indexHook(Humanoid, "JumpPower"),
        lastWalk = nil,
        lastJump = nil,
    }
    return self[DebugId]
end

indexHook = hookmetamethod(game, "__index", function(self, idx)
    if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
        local debugId = GetDebugId(self)
        local cached = cachedHumanoids[debugId]
        if self:IsDescendantOf(LocalPlayer.Character) or cached then
            if type(idx) == "string" then
                local clean = string.split(idx, "\0")[1]
                if clean == "WalkSpeed" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(debugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    return cached.lastWalk or cached.currentWalk
                elseif clean == "JumpPower" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(debugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    return cached.lastJump or cached.currentJump
                end
            end
        end
    end
    return indexHook(self, idx)
end)

newIndexHook = hookmetamethod(game, "__newindex", function(self, idx, val)
    if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
        local debugId = GetDebugId(self)
        local cached = cachedHumanoids[debugId]
        if self:IsDescendantOf(LocalPlayer.Character) or cached then
            if type(idx) == "string" then
                local clean = string.split(idx, "\0")[1]
                if clean == "WalkSpeed" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(debugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    cached.lastWalk = GetSpoofValue(val)
                    return CurrentHumanoid.WalkSpeed
                elseif clean == "JumpPower" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(debugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    cached.lastJump = GetSpoofValue(val)
                    return CurrentHumanoid.JumpPower
                end
            end
        end
    end
    return newIndexHook(self, idx, val)
end)

local function GetSpoofedHumanoid()
    return CurrentHumanoid or (function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            cachedHumanoids:cacheHumanoid(hum:GetDebugId(), hum)
            return cloneref(hum)
        end
    end)()
end

local function SetWalkSpeedSpoof(speed)
    local hum = GetSpoofedHumanoid()
    if not hum then return end
    local conns = {}
    local function AddConns(sig)
        for _, c in getconnections(sig) do
            if c.State then
                c:Disable()
                table.insert(conns, c)
            end
        end
    end
    AddConns(hum.Changed)
    AddConns(hum:GetPropertyChangedSignal("WalkSpeed"))
    hum.WalkSpeed = speed
    for _, c in conns do c:Enable() end
end

local function SetJumpPowerSpoof(power)
    local hum = GetSpoofedHumanoid()
    if not hum then return end
    local conns = {}
    local function AddConns(sig)
        for _, c in getconnections(sig) do
            if c.State then
                c:Disable()
                table.insert(conns, c)
            end
        end
    end
    AddConns(hum.Changed)
    AddConns(hum:GetPropertyChangedSignal("JumpPower"))
    hum.JumpPower = power
    for _, c in conns do c:Enable() end
end

local function UpdateMovementSpoof()
    if Config.WalkSpeedEnabled then
        SetWalkSpeedSpoof(Config.WalkSpeed)
    end
    if Config.JumpPowerEnabled then
        SetJumpPowerSpoof(Config.JumpPower)
    end
end

-- ============================================================
--  MODERATOR DETECTOR
-- ============================================================

local function DetectModerator(enable)
    Config.ModeratorDetector = enable
    if enable then
        -- Check existing players
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local success, rank = pcall(player.GetRankInGroup, player, game.CreatorId)
                if success and rank and rank >= 248 then
                    local role = player:GetRoleInGroup(game.CreatorId)
                    UI:Notify("Warning", {
                        Title = "Moderator Detector",
                        Content = player.Name .. " (" .. role .. ") is in the server!",
                        Duration = 10,
                        Image = Matrice.Asset("user-shield"),
                        Actions = {
                            { Name = "Leave Game", Callback = function() game:Shutdown() end }
                        }
                    })
                end
            end
        end

        if ModeratorDetectorAddedConnection then
            ModeratorDetectorAddedConnection:Disconnect()
            ModeratorDetectorAddedConnection = nil
        end
        ModeratorDetectorAddedConnection = Players.PlayerAdded:Connect(function(player)
            task.wait(1)
            local success, rank = pcall(player.GetRankInGroup, player, game.CreatorId)
            if success and rank and rank >= 248 then
                local role = player:GetRoleInGroup(game.CreatorId)
                UI:Notify("Warning", {
                    Title = "Moderator Detector",
                    Content = player.Name .. " (" .. role .. ") joined the server!",
                    Duration = 10,
                    Image = Matrice.Asset("user-shield"),
                    Actions = {
                        { Name = "Leave Game", Callback = function() game:Shutdown() end }
                    }
                })
            end
        end)

        if ModeratorDetectorRemovingConnection then
            ModeratorDetectorRemovingConnection:Disconnect()
            ModeratorDetectorRemovingConnection = nil
        end
        ModeratorDetectorRemovingConnection = Players.PlayerRemoving:Connect(function(player)
            local success, rank = pcall(player.GetRankInGroup, player, game.CreatorId)
            if success and rank and rank >= 248 then
                local role = player:GetRoleInGroup(game.CreatorId)
                UI:Notify("Warning", {
                    Title = "Moderator Detector",
                    Content = player.Name .. " (" .. role .. ") left the server!",
                    Duration = 10,
                    Image = Matrice.Asset("user-shield"),
                    Actions = {
                        { Name = "Leave Game", Callback = function() game:Shutdown() end }
                    }
                })
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
    SaveConfig()
end

-- ============================================================
--  ANTI AFK
-- ============================================================

local function AntiAFK(enable)
    Config.AntiAFK = enable
    if enable then
        if getconnections then
            for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
                pcall(function() conn:Disable(); conn:Disconnect() end)
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
    SaveConfig()
end

-- ============================================================
--  UI CREATION (v2)
-- ============================================================

local Library = UI:CreateLibrary({
    Name = "Matrice Hub - SCP:RP",
    Icon = Matrice.Asset("matrice")
})

-- Advertisement (if supported)
if Library:CreateAdvertisement then
    Library:CreateAdvertisement(
        "Rocheats",
        Matrice.Asset("rocheats_banner"),
        "https://rocheats.com/?ref=matrice",
        "Link copied to your clipboard. Thanks for supporting Matrice <3"
    )
end

local CombatTab = Library:CreateTab("Combat", Matrice.Asset("crosshair"))
local VisualsTab = Library:CreateTab("Visuals", Matrice.Asset("palette"))
local PlayerTab = Library:CreateTab("Player", Matrice.Asset("user"))
local UtilitiesTab = Library:CreateTab("Utilities", Matrice.Asset("toolbox"))
local SettingsTab = Library:CreateTab("Settings", Matrice.Asset("settings"))

Library:SwitchTab()

-- ============================================================
--  COMBAT TAB
-- ============================================================

local Targeting = CombatTab:CreateSection("Targeting", "Normal")

Targeting:CreateToggle("Normal", {
    Name = "Silent Aim",
    Flag = "SilentAim",
    CurrentValue = Config.SilentAim,
    Callback = function(v)
        Config.SilentAim = v
        if v then InstallSilentAimHook() end
        SaveConfig()
    end
})

Targeting:CreateDropdown({
    Name = "Hit Part",
    Options = {"Head", "UpperTorso", "HumanoidRootPart", "Random"},
    CurrentOption = Config.HitPart,
    Flag = "HitPart",
    Callback = function(sel)
        Config.HitPart = sel
        SaveConfig()
    end
})

Targeting:CreateSlider({
    Name = "Hit Chance",
    Value = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = Config.HitChance,
    Flag = "HitChance",
    Callback = function(v)
        Config.HitChance = v
        SaveConfig()
    end
})

Targeting:CreateDropdown({
    Name = "Target Selection",
    Options = {"Distance Priority", "Closest", "FOV Priority"},
    CurrentOption = Config.TargetSelection,
    Flag = "TargetSelection",
    Callback = function(sel)
        Config.TargetSelection = sel
        SaveConfig()
    end
})

Targeting:CreateDropdown({
    Name = "Target Priority",
    Options = {"Closest", "Lowest Health", "Crosshair Distance"},
    CurrentOption = Config.TargetPriority,
    Flag = "TargetPriority",
    Callback = function(sel)
        Config.TargetPriority = sel
        SaveConfig()
    end
})

Targeting:CreateToggle("Normal", {
    Name = "Hitbox (experimental)",
    Flag = "Hitbox",
    CurrentValue = Config.Hitbox,
    Callback = function(v)
        Config.Hitbox = v
        SaveConfig()
    end
})

Targeting:CreateSlider({
    Name = "Hitbox Size",
    Value = {1, 10},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = Config.HitboxSize,
    Flag = "HitboxSize",
    Callback = function(v)
        Config.HitboxSize = v
        SaveConfig()
    end
})

local Checks = CombatTab:CreateSection("Checks", "Normal")

Checks:CreateToggle("Normal", {
    Name = "Wall Check",
    Flag = "WallCheck",
    CurrentValue = Config.WallCheck,
    Callback = function(v)
        Config.WallCheck = v
        SaveConfig()
    end
})

Checks:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "TeamCheck",
    CurrentValue = Config.TeamCheck,
    Callback = function(v)
        Config.TeamCheck = v
        SaveConfig()
    end
})

local FOVSection = CombatTab:CreateSection("FOV", "Normal")

FOVSection:CreateToggle("Normal", {
    Name = "Show FOV",
    Flag = "ShowFOV",
    CurrentValue = Config.ShowFOV,
    Callback = function(v)
        Config.ShowFOV = v
        if not v then FOVCircle.Visible = false end
        SaveConfig()
    end
})

FOVSection:CreateSlider({
    Name = "FOV Radius",
    Value = {1, 360},
    Increment = 1,
    Suffix = "°",
    CurrentValue = Config.FOVRadius,
    Flag = "FOVRadius",
    Callback = function(v)
        Config.FOVRadius = v
        SaveConfig()
    end
})

FOVSection:CreateColorPicker({
    Name = "FOV Color",
    Callback = function(c)
        Config.FOVColor = c
        SaveConfig()
    end
})

local Automation = CombatTab:CreateSection("Automation", "Normal")

Automation:CreateToggle("Normal", {
    Name = "Auto Trigger",
    Flag = "AutoTrigger",
    CurrentValue = Config.AutoTrigger,
    Callback = function(v)
        Config.AutoTrigger = v
        SaveConfig()
    end
})

Automation:CreateSlider({
    Name = "Trigger Delay",
    Value = {0, 500},
    Increment = 10,
    Suffix = "ms",
    CurrentValue = Config.TriggerDelay,
    Flag = "TriggerDelay",
    Callback = function(v)
        Config.TriggerDelay = v
        SaveConfig()
    end
})

local Weapons = CombatTab:CreateSection("Weapons", "Normal")

Weapons:CreateToggle("Normal", {
    Name = "Auto Reload",
    Flag = "AutoReload",
    CurrentValue = Config.AutoReload,
    Callback = function(v)
        Config.AutoReload = v
        SaveConfig()
    end
})

-- ============================================================
--  VISUALS TAB
-- ============================================================

local ESP = VisualsTab:CreateSection("ESP", "Normal")

ESP:CreateToggle("Normal", {
    Name = "Enable ESP",
    Flag = "ESPEnabled",
    CurrentValue = Config.ESPEnabled,
    Callback = function(v)
        Config.ESPEnabled = v
        if not v then ClearAllESP() end
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Box ESP",
    Flag = "ESPBox",
    CurrentValue = Config.ESPBox,
    Callback = function(v)
        Config.ESPBox = v
        RebuildAllESP()
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Name ESP",
    Flag = "ESPName",
    CurrentValue = Config.ESPName,
    Callback = function(v)
        Config.ESPName = v
        RebuildAllESP()
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Distance ESP",
    Flag = "ESPDistance",
    CurrentValue = Config.ESPDistance,
    Callback = function(v)
        Config.ESPDistance = v
        RebuildAllESP()
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Weapon ESP",
    Flag = "ESPWeapon",
    CurrentValue = Config.ESPWeapon,
    Callback = function(v)
        Config.ESPWeapon = v
        RebuildAllESP()
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Health Bar",
    Flag = "ESPHealthBar",
    CurrentValue = Config.ESPHealthBar,
    Callback = function(v)
        Config.ESPHealthBar = v
        RebuildAllESP()
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Skeleton ESP",
    Flag = "ESPSkeleton",
    CurrentValue = Config.ESPSkeleton,
    Callback = function(v)
        Config.ESPSkeleton = v
        RebuildAllESP()
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "ESPTeamCheck",
    CurrentValue = Config.ESPTeamCheck,
    Callback = function(v)
        Config.ESPTeamCheck = v
        RebuildAllESP()
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Friend Check",
    Flag = "FriendCheck",
    CurrentValue = Config.FriendCheck,
    Callback = function(v)
        Config.FriendCheck = v
        RebuildAllESP()
        SaveConfig()
    end
})

ESP:CreateSlider({
    Name = "Distance Limit",
    Value = {10, 1000},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = Config.DistanceLimit,
    Flag = "DistanceLimit",
    Callback = function(v)
        Config.DistanceLimit = v
        RebuildAllESP()
        SaveConfig()
    end
})

local Effects = VisualsTab:CreateSection("Effects", "Normal")

Effects:CreateToggle("Normal", {
    Name = "Highlight",
    Flag = "Highlight",
    CurrentValue = Config.Highlight,
    Callback = function(v)
        Config.Highlight = v
        RebuildAllESP()
        SaveConfig()
    end
})

Effects:CreateToggle("Normal", {
    Name = "Chams",
    Flag = "Chams",
    CurrentValue = Config.Chams,
    Callback = function(v)
        Config.Chams = v
        RebuildAllESP()
        SaveConfig()
    end
})

Effects:CreateToggle("Normal", {
    Name = "Tracer Lines",
    Flag = "TracerLines",
    CurrentValue = Config.TracerLines,
    Callback = function(v)
        Config.TracerLines = v
        RebuildAllESP()
        SaveConfig()
    end
})

Effects:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Center", "Mouse"},
    CurrentOption = Config.TracerOrigin,
    Flag = "TracerOrigin",
    Callback = function(sel)
        Config.TracerOrigin = sel
        SaveConfig()
    end
})

-- ============================================================
--  PLAYER TAB
-- ============================================================

local Character = PlayerTab:CreateSection("Character", "Normal")

Character:CreateToggle("Normal", {
    Name = "Enable Walk Speed",
    Flag = "WalkSpeedEnabled",
    CurrentValue = Config.WalkSpeedEnabled,
    Callback = function(v)
        Config.WalkSpeedEnabled = v
        UpdateMovementSpoof()
        SaveConfig()
    end
})

Character:CreateSlider({
    Name = "Walk Speed",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = Config.WalkSpeed,
    Flag = "WalkSpeed",
    Callback = function(v)
        Config.WalkSpeed = v
        if Config.WalkSpeedEnabled then UpdateMovementSpoof() end
        SaveConfig()
    end
})

Character:CreateToggle("Normal", {
    Name = "Enable Jump Power",
    Flag = "JumpPowerEnabled",
    CurrentValue = Config.JumpPowerEnabled,
    Callback = function(v)
        Config.JumpPowerEnabled = v
        UpdateMovementSpoof()
        SaveConfig()
    end
})

Character:CreateSlider({
    Name = "Jump Power",
    Value = {0, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = Config.JumpPower,
    Flag = "JumpPower",
    Callback = function(v)
        Config.JumpPower = v
        if Config.JumpPowerEnabled then UpdateMovementSpoof() end
        SaveConfig()
    end
})

Character:CreateToggle("Normal", {
    Name = "No Clip",
    Flag = "NoClip",
    CurrentValue = Config.NoClip,
    Callback = function(v)
        Config.NoClip = v
        if v then EnableNoClip() else DisableNoClip() end
        SaveConfig()
    end
})

Character:CreateKeybind({
    Name = "No Clip Keybind",
    Flag = "NoClipKeybind",
    Keybind = Config.NoClipKeybind,
    Type = "Press",
    Callback = function()
        ToggleNoClip()
    end
})

Character:CreateToggle("Normal", {
    Name = "Fly",
    Flag = "Fly",
    CurrentValue = Config.Fly,
    Callback = function(v)
        Config.Fly = v
        if v then StartFly() else StopFly() end
        SaveConfig()
    end
})

Character:CreateKeybind({
    Name = "Fly Keybind",
    Flag = "FlyKeybind",
    Keybind = Config.FlyKeybind,
    Type = "Press",
    Callback = function()
        ToggleFly()
    end
})

-- ============================================================
--  UTILITIES TAB
-- ============================================================

local Miscellaneous = UtilitiesTab:CreateSection("Miscellaneous", "Normal")

Miscellaneous:CreateToggle("Normal", {
    Name = "Moderator Detector",
    Flag = "ModeratorDetector",
    CurrentValue = Config.ModeratorDetector,
    Callback = function(v)
        DetectModerator(v)
    end
})

local AntiAFKSection = UtilitiesTab:CreateSection("Anti AFK", "Normal")

AntiAFKSection:CreateToggle("Normal", {
    Name = "Enable Anti AFK",
    Flag = "AntiAFK",
    CurrentValue = Config.AntiAFK,
    Callback = function(v)
        AntiAFK(v)
    end
})

-- ============================================================
--  SETTINGS TAB
-- ============================================================

local Interface = SettingsTab:CreateSection("Interface", "Normal")

Interface:CreateKeybind({
    Name = "Toggle Menu Key",
    Flag = "ToggleMenuKey",
    Keybind = Config.ToggleMenuKey,
    Type = "Press",
    Callback = function()
        UI:ToggleUI()
    end
})

local gameVersion = tostring((Matrice.Game and Matrice.Game.Info and Matrice.Game.Info.Version) or "N/A")
local gameChangelog = tostring((Matrice.Game and Matrice.Game.Info and Matrice.Game.Info.Changelog) or "No changelog available.")

Interface:CreateCard({
    Title = "Matrice Hub - SCP:RP",
    Description = "A script hub packed with high-quality undetectable scripts",
    SecondaryTitle = "By Matrice Softworks",
    Image = Matrice.Asset("matrice"),
    Buttons = {
        Button1 = {
            Name = "Discord",
            Callback = function()
                setclipboard("https://discord.gg/matrice")
                UI:Notify("Normal", {
                    Title = "Copied!",
                    Content = "Link copied to your clipboard. Thanks for supporting Matrice <3",
                    Duration = 3,
                    Image = Matrice.Asset("discord")
                })
            end
        },
        Button2 = {
            Name = "Website",
            Callback = function()
                setclipboard("https://getmatrice.xyz")
                UI:Notify("Normal", {
                    Title = "Copied!",
                    Content = "Link copied to your clipboard. Thanks for supporting Matrice <3",
                    Duration = 3,
                    Image = Matrice.Asset("globe")
                })
            end
        }
    }
})

Interface:CreateParagraph({
    Title = "Version " .. gameVersion,
    Description = "Changelog:\n" .. gameChangelog
})

print("SCP:RP UI loaded (v2 + all features).")
