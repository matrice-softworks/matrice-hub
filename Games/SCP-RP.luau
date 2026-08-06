-- Matrice Softworks

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local UI = Matrice.UI
local Visuals = Matrice.Visuals

-- ============================================================
--  CONFIGURATION
-- ============================================================
local Config = {
    ESPEnabled = false,
    BoxEnabled = false,
    HighlightEnabled = false,
    SkeletonEnabled = false,
    TracerEnabled = false,
    HealthBarEnabled = false,
    ChamsEnabled = false,
    ESPRange = 600,
    SilentAimEnabled = false,
    SilentAimWallCheck = true,
    SilentAimHitPart = "Head",
    SilentAimHitChance = 100,
    FOVCircleEnabled = false,
    FOVRadius = 150,
    FOVColor = Color3.fromRGB(255, 255, 255),
    ModeratorDetector = false,
    MovementEnabled = false,
    Walkspeed = 16,
    Jumppower = 50,
    NoClipEnabled = false,
    FlyEnabled = false,
    FlySpeed = 50,
    FlyKeybind = "F",
    UIToggleKey = "LeftAlt",
    GreyscaleEnabled = false,
}

local function SaveConfig()
    local ok, err = Matrice.SaveConfiguration(Config, "SCP-RP-Config.json")
    if not ok then warn("Failed to save config:", err) end
end

local function LoadConfig()
    local data, err = Matrice.LoadConfiguration("SCP-RP-Config.json")
    if data then
        for k, v in pairs(data) do Config[k] = v end
        return true
    end
    return false
end

LoadConfig()

-- ============================================================
--  SILENT AIM
-- ============================================================
local SilentAimHookInstalled = false
local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Visible = false

local SilentAimRaycastParams = RaycastParams.new()
SilentAimRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
SilentAimRaycastParams.IgnoreWater = true

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

local function IsEnemy(player)
    local localTeam = LocalPlayer.Team and HostileTeams[LocalPlayer.Team.Name]
    local targetTeam = player.Team and HostileTeams[player.Team.Name]
    return localTeam == nil or targetTeam == nil or localTeam ~= targetTeam
end

local function GetSilentAimTarget()
    if not Config.SilentAimEnabled then return nil end
    local camera = workspace.CurrentCamera
    local cursor = UserInputService:GetMouseLocation()
    local closestPart, closestDistance = nil, Config.FOVRadius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsEnemy(player) then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local hitPartName = Config.SilentAimHitPart
            if hitPartName == "Randomized" then
                local hitParts = {"Head", "UpperTorso", "HumanoidRootPart"}
                hitPartName = hitParts[math.random(1, #hitParts)]
            end
            local targetPart = character and (character:FindFirstChild(hitPartName) or character:FindFirstChild("HumanoidRootPart"))

            if humanoid and humanoid.Health > 0 and targetPart then
                local screenPosition, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                local visible = true
                if Config.SilentAimWallCheck then
                    local localCharacter = LocalPlayer.Character
                    if localCharacter then
                        SilentAimRaycastParams.FilterDescendantsInstances = {localCharacter}
                        local result = workspace:Raycast(camera.CFrame.Position, targetPart.Position - camera.CFrame.Position, SilentAimRaycastParams)
                        visible = not result or result.Instance:IsDescendantOf(character)
                    end
                end
                if onScreen and visible then
                    local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - cursor).Magnitude
                    if distance < closestDistance then
                        closestPart = targetPart
                        closestDistance = distance
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

-- ============================================================
--  ESP / VISUALS
-- ============================================================
local PlayerESPs = {}
local Connections = {}

local function ClearPlayerESP(player)
    if PlayerESPs[player] then
        if PlayerESPs[player].Skeleton then PlayerESPs[player].Skeleton:Remove() end
        if PlayerESPs[player].Box then PlayerESPs[player].Box:Remove() end
        if PlayerESPs[player].Tracer then PlayerESPs[player].Tracer:Remove() end
        if PlayerESPs[player].HealthBarOutline then PlayerESPs[player].HealthBarOutline:Remove() end
        if PlayerESPs[player].HealthBarFill then PlayerESPs[player].HealthBarFill:Remove() end
        if PlayerESPs[player].HealthBarTicks then
            for _, tick in ipairs(PlayerESPs[player].HealthBarTicks) do tick:Remove() end
        end
        if PlayerESPs[player].Highlight then PlayerESPs[player].Highlight:Remove() end
        if PlayerESPs[player].Chams then
            for part, originalMaterial in pairs(PlayerESPs[player].Chams) do
                if part and part.Parent then part.Material = originalMaterial end
            end
        end
        PlayerESPs[player] = nil
    end
    if Connections[player.Name .. "_TeamColor"] then
        Connections[player.Name .. "_TeamColor"]:Disconnect()
        Connections[player.Name .. "_TeamColor"] = nil
    end
end

local function ClearESPs()
    for player, _ in pairs(PlayerESPs) do ClearPlayerESP(player) end
end

local function CreatePlayerESP(player)
    if player == LocalPlayer or not player.Character then return end
    local teamColor = player.TeamColor and player.TeamColor.Color or Color3.new(1, 1, 1)

    local box = nil
    if Config.BoxEnabled then
        box = Drawing.new("Square")
        box.Thickness = 1
        box.Color = teamColor
        box.Filled = false
        box.Transparency = 1
        box.Visible = false
    end

    local highlight = nil
    if Config.HighlightEnabled then
        highlight = Visuals:CreateVisual("Highlight", {
            Target = player.Character,
            Color = teamColor,
            Transparency = 0.5,
            StrokeColor = Color3.new(1, 1, 1),
            OutlineTransparency = 0,
        })
    end

    local skeleton = nil
    if Config.SkeletonEnabled then
        skeleton = Visuals:CreateVisual("Drawing", {
            Type = "Skeleton",
            Player = player,
            Color = teamColor,
            Thickness = 1
        })
    end

    local tracer = nil
    if Config.TracerEnabled then
        tracer = Drawing.new("Line")
        tracer.Thickness = 1
        tracer.Color = teamColor
        tracer.Transparency = 1
        tracer.Visible = false
    end

    local healthBarOutline, healthBarFill, healthBarTicks = nil, nil, nil
    if Config.HealthBarEnabled then
        healthBarOutline = Drawing.new("Square")
        healthBarOutline.Color = Color3.fromRGB(18, 20, 28)
        healthBarOutline.Filled = true
        healthBarOutline.Transparency = 1
        healthBarOutline.Visible = false

        healthBarFill = Drawing.new("Square")
        healthBarFill.Filled = true
        healthBarFill.Transparency = 1
        healthBarFill.Visible = false

        healthBarTicks = {}
        for _ = 1, 4 do
            local tick = Drawing.new("Line")
            tick.Color = Color3.fromRGB(90, 96, 112)
            tick.Thickness = 1
            tick.Transparency = 0.9
            tick.Visible = false
            table.insert(healthBarTicks, tick)
        end
    end

    local chams = nil
    if Config.ChamsEnabled and player.Character then
        chams = {}
        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                chams[v] = v.Material
                v.Material = Enum.Material.ForceField
            end
        end
    end

    PlayerESPs[player] = {
        Skeleton = skeleton,
        Box = box,
        Tracer = tracer,
        HealthBarOutline = healthBarOutline,
        HealthBarFill = healthBarFill,
        HealthBarTicks = healthBarTicks,
        Highlight = highlight,
        Chams = chams,
        Character = player.Character
    }

    Connections[player.Name .. "_TeamColor"] = player:GetPropertyChangedSignal("TeamColor"):Connect(function()
        if PlayerESPs[player] then
            local newColor = player.TeamColor and player.TeamColor.Color or Color3.new(1, 1, 1)
            if PlayerESPs[player].Box then PlayerESPs[player].Box.Color = newColor end
            if PlayerESPs[player].Tracer then PlayerESPs[player].Tracer.Color = newColor end
            if PlayerESPs[player].Highlight and PlayerESPs[player].Highlight.Object then
                PlayerESPs[player].Highlight.Object.FillColor = newColor
            end
            if PlayerESPs[player].Skeleton and PlayerESPs[player].Skeleton.Object then
                PlayerESPs[player].Skeleton.Object.SetColor(newColor)
            end
        end
    end)
end

local function RebuildAllESPs()
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
                if distance <= Config.ESPRange then
                    CreatePlayerESP(player)
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if not Config.ESPEnabled then
            ClearESPs()
            continue
        end

        local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot then continue end

        for p, _ in pairs(PlayerESPs) do
            if not p or p.Parent ~= Players then ClearPlayerESP(p) end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and player.Parent == Players then
                    local distance = (localRoot.Position - targetRoot.Position).Magnitude
                    if distance <= Config.ESPRange then
                        if not PlayerESPs[player] or PlayerESPs[player].Character ~= player.Character then
                            if PlayerESPs[player] then ClearPlayerESP(player) end
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

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = Config.FOVCircleEnabled
    if Config.FOVCircleEnabled then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = Config.FOVRadius
        FOVCircle.Color = Config.FOVColor
    end

    if not Config.ESPEnabled then return end
    for player, esp in pairs(PlayerESPs) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local onScreen, size, pos = Visuals:GetBoundingBox(player)
            local box = esp.Box
            local tracer = esp.Tracer
            local healthBarOutline = esp.HealthBarOutline
            local healthBarFill = esp.HealthBarFill
            local healthBarTicks = esp.HealthBarTicks

            if onScreen then
                local teamColor = player.TeamColor and player.TeamColor.Color or Color3.new(1, 1, 1)

                if box then
                    box.Size = size
                    box.Position = pos
                    box.Color = teamColor
                    box.Visible = Config.BoxEnabled
                end
                if tracer then
                    local viewport = workspace.CurrentCamera.ViewportSize
                    tracer.From = Vector2.new(viewport.X / 2, viewport.Y)
                    tracer.To = Vector2.new(pos.X + (size.X / 2), pos.Y + size.Y)
                    tracer.Color = teamColor
                    tracer.Visible = Config.TracerEnabled
                end
                if healthBarOutline and healthBarFill then
                    local humanoid = player.Character.Humanoid
                    local healthPercent = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
                    local barHeight = size.Y
                    local barX = pos.X - 8
                    local barY = pos.Y

                    healthBarOutline.Position = Vector2.new(barX - 1, barY - 2)
                    healthBarOutline.Size = Vector2.new(5, barHeight + 4)
                    healthBarOutline.Visible = Config.HealthBarEnabled

                    healthBarFill.Position = Vector2.new(barX, barY + barHeight * (1 - healthPercent))
                    healthBarFill.Size = Vector2.new(3, math.max(barHeight * healthPercent, 1))
                    healthBarFill.Color = Color3.fromHSV(healthPercent * 0.33, 0.9, 1)
                    healthBarFill.Visible = Config.HealthBarEnabled

                    if healthBarTicks then
                        for index, tick in ipairs(healthBarTicks) do
                            local y = barY + (barHeight * index / 5)
                            tick.From = Vector2.new(barX - 1, y)
                            tick.To = Vector2.new(barX + 4, y)
                            tick.Visible = Config.HealthBarEnabled
                        end
                    end
                end
            else
                if box then box.Visible = false end
                if tracer then tracer.Visible = false end
                if healthBarOutline then healthBarOutline.Visible = false end
                if healthBarFill then healthBarFill.Visible = false end
                if healthBarTicks then for _, tick in ipairs(healthBarTicks) do tick.Visible = false end end
            end
        else
            if esp.Box then esp.Box.Visible = false end
            if esp.Tracer then esp.Tracer.Visible = false end
            if esp.HealthBarOutline then esp.HealthBarOutline.Visible = false end
            if esp.HealthBarFill then esp.HealthBarFill.Visible = false end
            if esp.HealthBarTicks then for _, tick in ipairs(esp.HealthBarTicks) do tick.Visible = false end end
        end
    end
end)

Players.PlayerRemoving:Connect(ClearPlayerESP)

-- ============================================================
--  MOVEMENT SPOOF
-- ============================================================
local MovementSpoof = {}
local SpoofActive = false
local CurrentHumanoid = nil
local SpoofedWalk = 16
local SpoofedJump = 50
local cachedHumanoids = {}
local GetDebugIdHandler = Instance.new("BindableFunction")
local TempHumanoid = Instance.new("Humanoid")
local indexHook, newIndexHook
local MovementCharacterConnection = nil

function GetDebugIdHandler.OnInvoke(obj) return obj:GetDebugId() end
local function GetDebugId(obj) return GetDebugIdHandler:Invoke(obj) end

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
                        CurrentHumanoid = cloneref(self)
                    end
                    return cached.lastWalk or cached.currentWalk
                elseif clean == "JumpPower" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(DebugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
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
                        CurrentHumanoid = cloneref(self)
                    end
                    cached.lastWalk = GetSpoofValue(newValue)
                    return CurrentHumanoid.WalkSpeed
                elseif clean == "JumpPower" then
                    if not cached then cached = cachedHumanoids:cacheHumanoid(DebugId, self) end
                    if not (CurrentHumanoid and CurrentHumanoid:IsDescendantOf(game)) then
                        CurrentHumanoid = cloneref(self)
                    end
                    cached.lastJump = GetSpoofValue(newValue)
                    return CurrentHumanoid.JumpPower
                end
            end
        end
    end
    return newIndexHook(self, index, newValue)
end)

function MovementSpoof:GetHumanoid()
    return CurrentHumanoid or (function()
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            cachedHumanoids:cacheHumanoid(humanoid:GetDebugId(), humanoid)
            return cloneref(humanoid)
        end
    end)()
end

function MovementSpoof:SetWalkSpeed(speed)
    local humanoid = MovementSpoof:GetHumanoid()
    if not humanoid then return end
    local connections = {}
    local function AddConnections(Signal)
        for _, conn in getconnections(Signal) do
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

function MovementSpoof:SetJumpPower(power)
    local humanoid = MovementSpoof:GetHumanoid()
    if not humanoid then return end
    local connections = {}
    local function AddConnections(Signal)
        for _, conn in getconnections(Signal) do
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

function MovementSpoof:Restore()
    local humanoid = MovementSpoof:GetHumanoid()
    if humanoid then
        local debugId = humanoid:GetDebugId()
        local cached = cachedHumanoids[debugId]
        if cached then
            MovementSpoof:SetWalkSpeed(cached.lastWalk or cached.currentWalk)
            MovementSpoof:SetJumpPower(cached.lastJump or cached.currentJump)
        else
            MovementSpoof:SetWalkSpeed(16)
            MovementSpoof:SetJumpPower(50)
        end
    end
end

function MovementSpoof:Disable()
    SpoofActive = false
    MovementSpoof:Restore()
    if MovementCharacterConnection then
        MovementCharacterConnection:Disconnect()
        MovementCharacterConnection = nil
    end
end

function MovementSpoof:Enable(walk, jump)
    SpoofActive = true
    SpoofedWalk = walk or SpoofedWalk
    SpoofedJump = jump or SpoofedJump
    local humanoid = MovementSpoof:GetHumanoid()
    if humanoid then
        cachedHumanoids:cacheHumanoid(humanoid:GetDebugId(), humanoid)
        MovementSpoof:SetWalkSpeed(SpoofedWalk)
        MovementSpoof:SetJumpPower(SpoofedJump)
    end
    if not MovementCharacterConnection then
        MovementCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.1)
            local humanoid = char:FindFirstChildWhichIsA("Humanoid")
            if humanoid and SpoofActive then
                cachedHumanoids:cacheHumanoid(humanoid:GetDebugId(), humanoid)
                MovementSpoof:SetWalkSpeed(SpoofedWalk)
                MovementSpoof:SetJumpPower(SpoofedJump)
            end
        end)
    end
end

local function ToggleMovement(enable)
    if enable then
        if not SpoofActive then MovementSpoof:Enable(Config.Walkspeed, Config.Jumppower) end
    else
        if SpoofActive then MovementSpoof:Disable() end
    end
    Config.MovementEnabled = enable
    SaveConfig()
end

-- ============================================================
--  NOCLIP
-- ============================================================
local NoClipActive = false
local NoClipConnection = nil

local function SetNoClip(state)
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not state end
    end
end

local function EnableNoClip()
    if NoClipActive then return end
    NoClipActive = true
    SetNoClip(true)
    NoClipConnection = LocalPlayer.CharacterAdded:Connect(function(char)
        if NoClipActive then
            task.wait(0.1)
            SetNoClip(true)
        end
    end)
end

local function DisableNoClip()
    if not NoClipActive then return end
    NoClipActive = false
    SetNoClip(false)
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end
end

local function ToggleNoClip(enable)
    if enable then EnableNoClip() else DisableNoClip() end
    Config.NoClipEnabled = enable
    SaveConfig()
end

-- ============================================================
--  FLY
-- ============================================================
local FlyActive = false
local FlyConnection = nil
local FlyCharacterConnection = nil
local FlySpeed = Config.FlySpeed or 50

local function StartFly()
    if FlyActive or not LocalPlayer.Character then return end
    FlyActive = true

    FlyConnection = RunService.Heartbeat:Connect(function()
        if not FlyActive or not LocalPlayer.Character then return end
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local forward = workspace.CurrentCamera.CFrame.LookVector
        local right = workspace.CurrentCamera.CFrame.RightVector
        local up = Vector3.new(0, 1, 0)

        local moveDirection = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + up end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - up end

        if moveDirection.Magnitude > 0 then moveDirection = moveDirection.Unit * FlySpeed end

        root.CFrame = root.CFrame + moveDirection * RunService.Heartbeat:Wait()
        root.Velocity = Vector3.new(0, 0, 0)
        root.RotVelocity = Vector3.new(0, 0, 0)
    end)

    FlyCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(char)
        if FlyActive then
            task.wait(0.1)
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.Velocity = Vector3.new(0, 0, 0)
                root.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end

local function StopFly()
    if not FlyActive then return end
    FlyActive = false
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    if FlyCharacterConnection then
        FlyCharacterConnection:Disconnect()
        FlyCharacterConnection = nil
    end
    local character = LocalPlayer.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.Velocity = Vector3.new(0, 0, 0)
            root.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
end

local function ToggleFly(enable)
    if enable then StartFly() else StopFly() end
    Config.FlyEnabled = enable
    SaveConfig()
end

-- ============================================================
--  MODERATOR DETECTOR
-- ============================================================
local ModeratorDetectorConnection = nil
local ModNotifiedPlayers = {}

local function CheckModerators()
    ModNotifiedPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local Success, Rank = pcall(player.GetRankInGroup, player, game.CreatorId)
            if Success and Rank and Rank >= 248 then
                local Role = player:GetRoleInGroup(game.CreatorId)
                UI:Notify("Warning", {
                    Title = "Moderator Detector",
                    Content = player.Name .. " (" .. Role .. ") is online",
                    Duration = 10,
                    Image = Matrice.Asset("user-shield.png"),
                    Actions = {
                        { Name = "Leave Game", Callback = function() game:Shutdown() end }
                    }
                })
                ModNotifiedPlayers[player] = true
            end
        end
    end
end

local function EnableModeratorDetector()
    if ModeratorDetectorConnection then return end
    CheckModerators()
    ModeratorDetectorConnection = Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            task.wait(1)
            local Success, Rank = pcall(player.GetRankInGroup, player, game.CreatorId)
            if Success and Rank and Rank >= 248 then
                local Role = player:GetRoleInGroup(game.CreatorId)
                UI:Notify("Warning", {
                    Title = "Moderator Detector",
                    Content = player.Name .. " (" .. Role .. ") joined",
                    Duration = 10,
                    Image = Matrice.Asset("user-shield.png"),
                    Actions = {
                        { Name = "Leave Game", Callback = function() game:Shutdown() end }
                    }
                })
                ModNotifiedPlayers[player] = true
            end
        end
    end)
end

local function DisableModeratorDetector()
    if ModeratorDetectorConnection then
        ModeratorDetectorConnection:Disconnect()
        ModeratorDetectorConnection = nil
        ModNotifiedPlayers = {}
    end
end

-- ============================================================
--  UI CREATION (NEW LAYOUT)
-- ============================================================
local Library = UI:CreateLibrary({
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
--  COMBAT TAB
-- ============================================================
local Targeting = CombatTab:CreateSection("Targeting", "Normal")

Targeting:CreateToggle("Normal", {
    Name = "Silent Aim",
    Flag = "SilentAimEnabled",
    CurrentValue = Config.SilentAimEnabled,
    Callback = function(Enabled)
        Config.SilentAimEnabled = Enabled
        if Enabled and not InstallSilentAimHook() then
            Config.SilentAimEnabled = false
        end
        SaveConfig()
    end
})

Targeting:CreateDropdown({
    Name = "Hit Part",
    Options = {"Head", "UpperTorso", "HumanoidRootPart", "Randomized"},
    CurrentOption = Config.SilentAimHitPart,
    Flag = "SilentAimHitPart",
    Callback = function(Selected)
        Config.SilentAimHitPart = Selected
        SaveConfig()
    end
})

Targeting:CreateSlider({
    Name = "Hit Chance",
    Value = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = Config.SilentAimHitChance,
    Flag = "SilentAimHitChance",
    Callback = function(Value)
        Config.SilentAimHitChance = Value
        SaveConfig()
    end
})

Targeting:CreateToggle("Normal", {
    Name = "Wall Check",
    Flag = "SilentAimWallCheck",
    CurrentValue = Config.SilentAimWallCheck,
    Callback = function(Enabled)
        Config.SilentAimWallCheck = Enabled
        SaveConfig()
    end
})

Targeting:CreateToggle("Normal", {
    Name = "Show FOV",
    Flag = "FOVCircleEnabled",
    CurrentValue = Config.FOVCircleEnabled,
    Callback = function(Enabled)
        Config.FOVCircleEnabled = Enabled
        SaveConfig()
    end
})

Targeting:CreateSlider({
    Name = "FOV Radius",
    Value = {25, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = Config.FOVRadius,
    Flag = "FOVRadius",
    Callback = function(Value)
        Config.FOVRadius = Value
        SaveConfig()
    end
})

Targeting:CreateColorPicker({
    Name = "FOV Color",
    Callback = function(Color)
        Config.FOVColor = Color
        SaveConfig()
    end
})

local Checks = CombatTab:CreateSection("Checks", "Normal")
Checks:CreateToggle("Normal", {
    Name = "Wall Check",
    Flag = "WallCheck",
    Callback = function(Enabled) print("Wall Check " .. (Enabled and "ON" or "OFF")) end
})
Checks:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "TeamCheck",
    Callback = function(Enabled) print("Team Check " .. (Enabled and "ON" or "OFF")) end
})

local FOVSection = CombatTab:CreateSection("FOV", "Normal")
FOVSection:CreateToggle("Normal", {
    Name = "Show FOV",
    Flag = "ShowFOV",
    Callback = function(Enabled) print("Show FOV " .. (Enabled and "ON" or "OFF")) end
})
FOVSection:CreateSlider({
    Name = "FOV Radius",
    Value = {1, 360},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 120,
    Flag = "FOVRadius",
    Callback = function(Value) print("FOV Radius set to " .. Value) end
})
FOVSection:CreateColorPicker({
    Name = "FOV Color",
    Callback = function(Color) print("FOV color changed to", Color) end
})

local Automation = CombatTab:CreateSection("Automation", "Normal")
Automation:CreateToggle("Normal", {
    Name = "Auto Trigger",
    Flag = "AutoTrigger",
    Callback = function(Enabled) print("Auto Trigger " .. (Enabled and "ON" or "OFF")) end
})
Automation:CreateSlider({
    Name = "Trigger Delay",
    Value = {0, 500},
    Increment = 10,
    Suffix = "ms",
    CurrentValue = 50,
    Flag = "TriggerDelay",
    Callback = function(Value) print("Trigger Delay set to " .. Value .. "ms") end
})

local Weapons = CombatTab:CreateSection("Weapons", "Normal")
Weapons:CreateToggle("Normal", {
    Name = "Auto Reload",
    Flag = "AutoReload",
    Callback = function(Enabled) print("Auto Reload " .. (Enabled and "ON" or "OFF")) end
})

-- ============================================================
--  VISUALS TAB
-- ============================================================
local ESP = VisualsTab:CreateSection("ESP", "Normal")

ESP:CreateToggle("Normal", {
    Name = "Enable ESP",
    Flag = "ESPEnabled",
    CurrentValue = Config.ESPEnabled,
    Callback = function(Enabled)
        Config.ESPEnabled = Enabled
        if not Enabled then ClearESPs() end
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Box",
    Flag = "BoxEnabled",
    CurrentValue = Config.BoxEnabled,
    Callback = function(Enabled)
        Config.BoxEnabled = Enabled
        RebuildAllESPs()
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Highlight",
    Flag = "HighlightEnabled",
    CurrentValue = Config.HighlightEnabled,
    Callback = function(Enabled)
        Config.HighlightEnabled = Enabled
        RebuildAllESPs()
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Skeleton",
    Flag = "SkeletonEnabled",
    CurrentValue = Config.SkeletonEnabled,
    Callback = function(Enabled)
        Config.SkeletonEnabled = Enabled
        RebuildAllESPs()
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Tracer Lines",
    Flag = "TracerEnabled",
    CurrentValue = Config.TracerEnabled,
    Callback = function(Enabled)
        Config.TracerEnabled = Enabled
        RebuildAllESPs()
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Health Bars",
    Flag = "HealthBarEnabled",
    CurrentValue = Config.HealthBarEnabled,
    Callback = function(Enabled)
        Config.HealthBarEnabled = Enabled
        RebuildAllESPs()
        SaveConfig()
    end
})

ESP:CreateToggle("Normal", {
    Name = "Chams",
    Flag = "ChamsEnabled",
    CurrentValue = Config.ChamsEnabled,
    Callback = function(Enabled)
        Config.ChamsEnabled = Enabled
        RebuildAllESPs()
        SaveConfig()
    end
})

ESP:CreateSlider({
    Name = "ESP Range",
    Value = {50, 2000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = Config.ESPRange,
    Flag = "ESPRange",
    Callback = function(Value)
        Config.ESPRange = Value
        RebuildAllESPs()
        SaveConfig()
    end
})

local Effects = VisualsTab:CreateSection("Effects", "Normal")
Effects:CreateToggle("Normal", {
    Name = "Greyscale World",
    Flag = "GreyscaleEnabled",
    CurrentValue = Config.GreyscaleEnabled,
    Callback = function(Enabled)
        Config.GreyscaleEnabled = Enabled
        if Enabled then
            local cc = Instance.new("ColorCorrectionEffect")
            cc.Saturation = -1
            cc.Parent = Lighting
            getgenv()._GreyscaleEffect = cc
        else
            if getgenv()._GreyscaleEffect then
                getgenv()._GreyscaleEffect:Destroy()
                getgenv()._GreyscaleEffect = nil
            end
        end
        SaveConfig()
    end
})

if Config.GreyscaleEnabled then
    local cc = Instance.new("ColorCorrectionEffect")
    cc.Saturation = -1
    cc.Parent = Lighting
    getgenv()._GreyscaleEffect = cc
end

-- ============================================================
--  PLAYER TAB
-- ============================================================
local Character = PlayerTab:CreateSection("Character", "Normal")

Character:CreateToggle("Normal", {
    Name = "Enable Movement Spoof",
    Flag = "MovementEnabled",
    CurrentValue = Config.MovementEnabled,
    Callback = function(Enabled)
        ToggleMovement(Enabled)
    end
})

Character:CreateSlider({
    Name = "Walkspeed",
    Value = {16, 100},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = Config.Walkspeed,
    Flag = "Walkspeed",
    Callback = function(Value)
        Config.Walkspeed = Value
        if SpoofActive then
            SpoofedWalk = Value
            MovementSpoof:SetWalkSpeed(Value)
        end
        SaveConfig()
    end
})

Character:CreateSlider({
    Name = "Jump Power",
    Value = {50, 200},
    Increment = 5,
    Suffix = "strength",
    CurrentValue = Config.Jumppower,
    Flag = "Jumppower",
    Callback = function(Value)
        Config.Jumppower = Value
        if SpoofActive then
            SpoofedJump = Value
            MovementSpoof:SetJumpPower(Value)
        end
        SaveConfig()
    end
})

Character:CreateDivider()

Character:CreateToggle("Normal", {
    Name = "No Clip",
    Flag = "NoClipEnabled",
    CurrentValue = Config.NoClipEnabled,
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
        print("No Clip key " .. (State and "pressed" or "released"))
    end
})

Character:CreateDivider()

Character:CreateToggle("Normal", {
    Name = "Fly",
    Flag = "FlyEnabled",
    CurrentValue = Config.FlyEnabled,
    Callback = function(Enabled)
        ToggleFly(Enabled)
    end
})

Character:CreateSlider({
    Name = "Fly Speed",
    Value = {10, 200},
    Increment = 5,
    Suffix = "studs/s",
    CurrentValue = Config.FlySpeed,
    Flag = "FlySpeed",
    Callback = function(Value)
        FlySpeed = Value
        Config.FlySpeed = Value
        SaveConfig()
    end
})

Character:CreateKeybind({
    Name = "Fly Toggle",
    Flag = "FlyKeybind",
    Keybind = Config.FlyKeybind or "F",
    Type = "Press",
    Callback = function()
        local newState = not Config.FlyEnabled
        ToggleFly(newState)
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
    Callback = function(Enabled)
        Config.ModeratorDetector = Enabled
        if Enabled then
            EnableModeratorDetector()
        else
            DisableModeratorDetector()
        end
        SaveConfig()
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
    Keybind = Config.UIToggleKey or "LeftAlt",
    Type = "Press",
    Callback = function(State)
        UI:ToggleUI()
    end
})

local SettingsConfig = SettingsTab:CreateSection("Configuration", "Normal")

SettingsConfig:CreateButton({
    Name = "Load Configuration",
    Callback = function()
        LoadConfig()
        -- Update UI elements (this would require refreshing the UI or re-applying toggles)
        UI:Notify("Normal", {
            Title = "Config Loaded",
            Content = "Settings loaded successfully.",
            Duration = 3,
            Image = Matrice.Asset("info.png")
        })
    end
})

SettingsConfig:CreateButton({
    Name = "Reset to Default",
    Callback = function()
        Library:Notify({
            Title = "Reset Settings",
            Content = "Are you sure you want to reset all settings to default?",
            Duration = 5,
            Actions = {
                {
                    Name = "Yes",
                    Callback = function()
                        Config = {
                            ESPEnabled = false,
                            BoxEnabled = false,
                            HighlightEnabled = false,
                            SkeletonEnabled = false,
                            TracerEnabled = false,
                            HealthBarEnabled = false,
                            ChamsEnabled = false,
                            ESPRange = 600,
                            SilentAimEnabled = false,
                            SilentAimWallCheck = true,
                            SilentAimHitPart = "Head",
                            SilentAimHitChance = 100,
                            FOVCircleEnabled = false,
                            FOVRadius = 150,
                            FOVColor = Color3.fromRGB(255, 255, 255),
                            ModeratorDetector = false,
                            MovementEnabled = false,
                            Walkspeed = 16,
                            Jumppower = 50,
                            NoClipEnabled = false,
                            FlyEnabled = false,
                            FlySpeed = 50,
                            FlyKeybind = "F",
                            UIToggleKey = "LeftAlt",
                            GreyscaleEnabled = false,
                        }
                        SaveConfig()
                        UI:Notify("Warning", {
                            Title = "Reset",
                            Content = "Settings reset to defaults. Please reload the script.",
                            Duration = 5,
                            Image = Matrice.Asset("info.png")
                        })
                    end
                },
                {
                    Name = "No",
                    Callback = function() print("Reset cancelled.") end
                }
            }
        })
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
                UI:Notify("Normal", {
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
                UI:Notify("Normal", {
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

-- ============================================================
--  STARTUP STATE RESTORATION
-- ============================================================
if Config.ESPEnabled then RebuildAllESPs() end
if Config.SilentAimEnabled then InstallSilentAimHook() end
if Config.ModeratorDetector then EnableModeratorDetector() end
if Config.MovementEnabled then ToggleMovement(true) end
if Config.NoClipEnabled then ToggleNoClip(true) end
if Config.FlyEnabled then ToggleFly(true) end

print("SCP:RP UI loaded with all features.")