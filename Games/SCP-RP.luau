-- Matrice Softworks

-- ============================================================
--  SERVICES
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")

-- ============================================================
--  REFERENCES
-- ============================================================

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Visuals = Matrice.Visuals

-- ============================================================
--  FEATURE MODULES
-- ============================================================

local SilentAim = {}
SilentAim.Enabled = false
SilentAim.WallCheck = true
SilentAim.HitPart = "Head"
SilentAim.HitChance = 100
SilentAim.HookInstalled = false
SilentAim.OriginalFunction = nil

local FOV = {}
FOV.Enabled = false
FOV.Radius = 150
FOV.Color = Color3.fromRGB(255, 255, 255)
FOV.Circle = Drawing.new("Circle")
FOV.Circle.Filled = false
FOV.Circle.Thickness = 1
FOV.Circle.NumSides = 64
FOV.Circle.Visible = false

local Hitbox = {}
Hitbox.Enabled = false
Hitbox.Size = 1

local WallCheck = {}
WallCheck.Enabled = false

local TeamCheck = {}
TeamCheck.Enabled = false

local AutoTrigger = {}
AutoTrigger.Enabled = false

local TriggerDelay = {}
TriggerDelay.Value = 50

local AutoReload = {}
AutoReload.Enabled = false

local ESP = {}
ESP.Enabled = false
ESP.Settings = {
    Box = false,
    Name = false,
    Distance = false,
    Weapon = false,
    HealthBar = false,
    Skeleton = false,
    TeamCheck = false,
    FriendCheck = false,
    DistanceLimit = 500
}
ESP.PlayerData = {}
ESP.Connections = {}
ESP.RenderConnection = nil
ESP.UpdateConnection = nil

local Highlight = {}
Highlight.Enabled = false

local Chams = {}
Chams.Enabled = false

local TracerLines = {}
TracerLines.Enabled = false

local TracerOrigin = {}
TracerOrigin.Selected = "Bottom"

local Greyscale = {}
Greyscale.Enabled = false
Greyscale.Effect = nil

local WalkSpeed = {}
WalkSpeed.Enabled = false
WalkSpeed.Value = 16

local JumpPower = {}
JumpPower.Enabled = false
JumpPower.Value = 50

local NoClip = {}
NoClip.Enabled = false
NoClip.Keybind = "N"
NoClip.Active = false
NoClip.Connection = nil

local Fly = {}
Fly.Enabled = false
Fly.Keybind = "F"
Fly.Speed = 50
Fly.Active = false
Fly.Connection = nil
Fly.CharacterConnection = nil

local ModeratorDetector = {}
ModeratorDetector.Enabled = false
ModeratorDetector.Connection = nil
ModeratorDetector.AddedConnection = nil
ModeratorDetector.RemovingConnection = nil

local AntiAFK = {}
AntiAFK.Enabled = false
AntiAFK.Connection = nil

local MovementSpoof = {}
MovementSpoof.Enabled = false
MovementSpoof.Active = false
MovementSpoof.WalkSpeed = 16
MovementSpoof.JumpPower = 50
MovementSpoof.CurrentHumanoid = nil
MovementSpoof.CachedHumanoids = {}
MovementSpoof.CharacterConnection = nil
MovementSpoof.IndexHook = nil
MovementSpoof.NewIndexHook = nil

-- ============================================================
--  HELPER FUNCTIONS
-- ============================================================

local function GetPlayerRank(Player)
    if not Player or not Player.Parent or Player.Parent ~= Players then
        return nil
    end
    local Success, Rank = pcall(Player.GetRankInGroup, Player, game.CreatorId)
    if Success then
        return Rank
    end
    return nil
end

local function GetPlayerRole(Player)
    if not Player or not Player.Parent or Player.Parent ~= Players then
        return nil
    end
    local Success, Role = pcall(Player.GetRoleInGroup, Player, game.CreatorId)
    if Success then
        return Role
    end
    return nil
end

local function IsEnemy(Player)
    local LocalTeam = LocalPlayer.Team
    local TargetTeam = Player.Team
    if not LocalTeam or not TargetTeam then return true end
    return LocalTeam ~= TargetTeam
end

-- ============================================================
--  SILENT AIM FUNCTIONS
-- ============================================================

local function GetSilentAimTarget()
    if not SilentAim.Enabled then return nil end
    local Camera = workspace.CurrentCamera
    local Cursor = UserInputService:GetMouseLocation()
    local ClosestPart = nil
    local ClosestDistance = FOV.Radius

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and IsEnemy(Player) then
            local Character = Player.Character
            if not Character then continue end
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            if not Humanoid or Humanoid.Health <= 0 then continue end

            local HitPartName = SilentAim.HitPart
            if HitPartName == "Randomized" then
                local Parts = {"Head", "UpperTorso", "HumanoidRootPart"}
                HitPartName = Parts[math.random(1, #Parts)]
            end

            local TargetPart = Character:FindFirstChild(HitPartName) or Character:FindFirstChild("HumanoidRootPart")
            if not TargetPart then continue end

            local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(TargetPart.Position)
            if not OnScreen then continue end

            local Visible = true
            if SilentAim.WallCheck then
                local LocalCharacter = LocalPlayer.Character
                if LocalCharacter then
                    local Params = RaycastParams.new()
                    Params.FilterType = Enum.RaycastFilterType.Exclude
                    Params.FilterDescendantsInstances = {LocalCharacter}
                    Params.IgnoreWater = true
                    local Result = workspace:Raycast(Camera.CFrame.Position, TargetPart.Position - Camera.CFrame.Position, Params)
                    if Result and not Result.Instance:IsDescendantOf(Character) then
                        Visible = false
                    end
                end
            end

            if Visible then
                local Distance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - Cursor).Magnitude
                if Distance < ClosestDistance then
                    ClosestPart = TargetPart
                    ClosestDistance = Distance
                end
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
                if Success and Constants and MatchesController(Candidate) and
                   table.find(Constants, "Bullet") and
                   table.find(Constants, "EasterEggThing") and
                   table.find(Constants, "SCP-066") then
                    return Candidate
                end
            end
        end
    end
    return nil
end

local function InstallSilentAim()
    if SilentAim.HookInstalled then return true end
    local BulletFunction = FindBulletFunction()
    if not BulletFunction then
        warn("Silent Aim: Could not find bullet function.")
        return false
    end

    local Original
    Original = hookfunction(BulletFunction, function(_, HitResult, ...)
        local Target = GetSilentAimTarget()
        if Target and math.random(1, 100) <= SilentAim.HitChance then
            return Original(_, {
                Instance = Target,
                Position = Target.Position,
                Normal = Vector3.new(0, 1, 0),
                Material = Target.Material,
            }, ...)
        end
        return Original(_, HitResult, ...)
    end)

    SilentAim.OriginalFunction = Original
    SilentAim.HookInstalled = true
    return true
end

local function ToggleSilentAim(Enabled)
    SilentAim.Enabled = Enabled
    if Enabled then
        if not InstallSilentAim() then
            SilentAim.Enabled = false
            warn("Silent Aim installation failed.")
        end
    end
end

-- ============================================================
--  MOVEMENT SPOOF FUNCTIONS
-- ============================================================

local GetDebugIdHandler = Instance.new("BindableFunction")
local TempHumanoid = Instance.new("Humanoid")

function GetDebugIdHandler.OnInvoke(Object)
    return Object:GetDebugId()
end

local function GetDebugId(Object)
    return GetDebugIdHandler:Invoke(Object)
end

local function GetSpoofValue(Value)
    TempHumanoid.WalkSpeed = Value
    return TempHumanoid.WalkSpeed
end

local function CacheHumanoid(CacheTable, DebugId, Humanoid)
    CacheTable[DebugId] = {
        CurrentWalk = MovementSpoof.IndexHook(Humanoid, "WalkSpeed"),
        CurrentJump = MovementSpoof.IndexHook(Humanoid, "JumpPower"),
        LastWalk = nil,
        LastJump = nil,
    }
    return CacheTable[DebugId]
end

local function SetupMovementSpoof()
    MovementSpoof.CachedHumanoids = {}
    MovementSpoof.IndexHook = hookmetamethod(game, "__index", function(Self, Index)
        if not checkcaller() and typeof(Self) == "Instance" and Self:IsA("Humanoid") then
            local DebugId = GetDebugId(Self)
            local Cached = MovementSpoof.CachedHumanoids[DebugId]
            if Self:IsDescendantOf(LocalPlayer.Character) or Cached then
                if type(Index) == "string" then
                    local Clean = string.split(Index, "\0")[1]
                    if Clean == "WalkSpeed" then
                        if not Cached then Cached = CacheHumanoid(MovementSpoof.CachedHumanoids, DebugId, Self) end
                        if not (MovementSpoof.CurrentHumanoid and MovementSpoof.CurrentHumanoid:IsDescendantOf(game)) then
                            MovementSpoof.CurrentHumanoid = cloneref(Self)
                        end
                        return Cached.LastWalk or Cached.CurrentWalk
                    elseif Clean == "JumpPower" then
                        if not Cached then Cached = CacheHumanoid(MovementSpoof.CachedHumanoids, DebugId, Self) end
                        if not (MovementSpoof.CurrentHumanoid and MovementSpoof.CurrentHumanoid:IsDescendantOf(game)) then
                            MovementSpoof.CurrentHumanoid = cloneref(Self)
                        end
                        return Cached.LastJump or Cached.CurrentJump
                    end
                end
            end
        end
        return MovementSpoof.IndexHook(Self, Index)
    end)

    MovementSpoof.NewIndexHook = hookmetamethod(game, "__newindex", function(Self, Index, NewValue)
        if not checkcaller() and typeof(Self) == "Instance" and Self:IsA("Humanoid") then
            local DebugId = GetDebugId(Self)
            local Cached = MovementSpoof.CachedHumanoids[DebugId]
            if Self:IsDescendantOf(LocalPlayer.Character) or Cached then
                if type(Index) == "string" then
                    local Clean = string.split(Index, "\0")[1]
                    if Clean == "WalkSpeed" then
                        if not Cached then Cached = CacheHumanoid(MovementSpoof.CachedHumanoids, DebugId, Self) end
                        if not (MovementSpoof.CurrentHumanoid and MovementSpoof.CurrentHumanoid:IsDescendantOf(game)) then
                            MovementSpoof.CurrentHumanoid = cloneref(Self)
                        end
                        Cached.LastWalk = GetSpoofValue(NewValue)
                        return MovementSpoof.CurrentHumanoid.WalkSpeed
                    elseif Clean == "JumpPower" then
                        if not Cached then Cached = CacheHumanoid(MovementSpoof.CachedHumanoids, DebugId, Self) end
                        if not (MovementSpoof.CurrentHumanoid and MovementSpoof.CurrentHumanoid:IsDescendantOf(game)) then
                            MovementSpoof.CurrentHumanoid = cloneref(Self)
                        end
                        Cached.LastJump = GetSpoofValue(NewValue)
                        return MovementSpoof.CurrentHumanoid.JumpPower
                    end
                end
            end
        end
        return MovementSpoof.NewIndexHook(Self, Index, NewValue)
    end)
end

local function GetMovementHumanoid()
    if MovementSpoof.CurrentHumanoid and MovementSpoof.CurrentHumanoid:IsDescendantOf(game) then
        return MovementSpoof.CurrentHumanoid
    end
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
    if Humanoid then
        CacheHumanoid(MovementSpoof.CachedHumanoids, Humanoid:GetDebugId(), Humanoid)
        return cloneref(Humanoid)
    end
    return nil
end

local function SetMovementWalkSpeed(Speed)
    local Humanoid = GetMovementHumanoid()
    if not Humanoid then return end
    local Connections = {}
    local function AddConnections(Signal)
        for _, Conn in getconnections(Signal) do
            if Conn.State then
                Conn:Disable()
                table.insert(Connections, Conn)
            end
        end
    end
    AddConnections(Humanoid.Changed)
    AddConnections(Humanoid:GetPropertyChangedSignal("WalkSpeed"))
    Humanoid.WalkSpeed = Speed
    for _, Conn in Connections do Conn:Enable() end
end

local function SetMovementJumpPower(Power)
    local Humanoid = GetMovementHumanoid()
    if not Humanoid then return end
    local Connections = {}
    local function AddConnections(Signal)
        for _, Conn in getconnections(Signal) do
            if Conn.State then
                Conn:Disable()
                table.insert(Connections, Conn)
            end
        end
    end
    AddConnections(Humanoid.Changed)
    AddConnections(Humanoid:GetPropertyChangedSignal("JumpPower"))
    Humanoid.JumpPower = Power
    for _, Conn in Connections do Conn:Enable() end
end

local function RestoreMovement()
    local Humanoid = GetMovementHumanoid()
    if Humanoid then
        local DebugId = Humanoid:GetDebugId()
        local Cached = MovementSpoof.CachedHumanoids[DebugId]
        if Cached then
            SetMovementWalkSpeed(Cached.LastWalk or Cached.CurrentWalk)
            SetMovementJumpPower(Cached.LastJump or Cached.CurrentJump)
        else
            SetMovementWalkSpeed(16)
            SetMovementJumpPower(50)
        end
    end
end

local function DisableMovementSpoof()
    MovementSpoof.Active = false
    RestoreMovement()
    if MovementSpoof.CharacterConnection then
        MovementSpoof.CharacterConnection:Disconnect()
        MovementSpoof.CharacterConnection = nil
    end
end

local function EnableMovementSpoof()
    MovementSpoof.Active = true
    local Humanoid = GetMovementHumanoid()
    if Humanoid then
        CacheHumanoid(MovementSpoof.CachedHumanoids, Humanoid:GetDebugId(), Humanoid)
        SetMovementWalkSpeed(MovementSpoof.WalkSpeed)
        SetMovementJumpPower(MovementSpoof.JumpPower)
    end
    if not MovementSpoof.CharacterConnection then
        MovementSpoof.CharacterConnection = LocalPlayer.CharacterAdded:Connect(function(Character)
            task.wait(0.1)
            local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
            if Humanoid and MovementSpoof.Active then
                CacheHumanoid(MovementSpoof.CachedHumanoids, Humanoid:GetDebugId(), Humanoid)
                SetMovementWalkSpeed(MovementSpoof.WalkSpeed)
                SetMovementJumpPower(MovementSpoof.JumpPower)
            end
        end)
    end
end

local function ToggleMovementSpoof(Enabled)
    MovementSpoof.Enabled = Enabled
    if Enabled then
        if not MovementSpoof.IndexHook then
            SetupMovementSpoof()
        end
        EnableMovementSpoof()
    else
        DisableMovementSpoof()
    end
end

-- ============================================================
--  NOCLIP FUNCTIONS
-- ============================================================

local function SetNoClipState(State)
    local Character = LocalPlayer.Character
    if not Character then return end
    for _, Part in ipairs(Character:GetDescendants()) do
        if Part:IsA("BasePart") then
            Part.CanCollide = not State
        end
    end
end

local function EnableNoClip()
    if NoClip.Active then return end
    NoClip.Active = true
    SetNoClipState(true)
    if NoClip.Connection then NoClip.Connection:Disconnect() end
    NoClip.Connection = LocalPlayer.CharacterAdded:Connect(function()
        if NoClip.Active then
            task.wait(0.1)
            SetNoClipState(true)
        end
    end)
end

local function DisableNoClip()
    if not NoClip.Active then return end
    NoClip.Active = false
    SetNoClipState(false)
    if NoClip.Connection then
        NoClip.Connection:Disconnect()
        NoClip.Connection = nil
    end
end

local function ToggleNoClip(Enabled)
    NoClip.Enabled = Enabled
    if Enabled then
        EnableNoClip()
    else
        DisableNoClip()
    end
end

-- ============================================================
--  FLY FUNCTIONS
-- ============================================================

local function StartFly()
    if Fly.Active or not LocalPlayer.Character then return end
    Fly.Active = true

    Fly.Connection = RunService.Heartbeat:Connect(function()
        if not Fly.Active or not LocalPlayer.Character then return end
        local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not Root then return end

        local Forward = workspace.CurrentCamera.CFrame.LookVector
        local Right = workspace.CurrentCamera.CFrame.RightVector
        local Up = Vector3.new(0, 1, 0)

        local MoveDirection = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then MoveDirection = MoveDirection + Forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then MoveDirection = MoveDirection - Forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then MoveDirection = MoveDirection - Right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then MoveDirection = MoveDirection + Right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then MoveDirection = MoveDirection + Up end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then MoveDirection = MoveDirection - Up end

        if MoveDirection.Magnitude > 0 then
            MoveDirection = MoveDirection.Unit * Fly.Speed
        end

        Root.CFrame = Root.CFrame + MoveDirection * RunService.Heartbeat:Wait()
        Root.Velocity = Vector3.new(0, 0, 0)
        Root.RotVelocity = Vector3.new(0, 0, 0)
    end)

    Fly.CharacterConnection = LocalPlayer.CharacterAdded:Connect(function(Character)
        if Fly.Active then
            task.wait(0.1)
            local Root = Character:FindFirstChild("HumanoidRootPart")
            if Root then
                Root.Velocity = Vector3.new(0, 0, 0)
                Root.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end

local function StopFly()
    if not Fly.Active then return end
    Fly.Active = false
    if Fly.Connection then
        Fly.Connection:Disconnect()
        Fly.Connection = nil
    end
    if Fly.CharacterConnection then
        Fly.CharacterConnection:Disconnect()
        Fly.CharacterConnection = nil
    end
    local Character = LocalPlayer.Character
    if Character then
        local Root = Character:FindFirstChild("HumanoidRootPart")
        if Root then
            Root.Velocity = Vector3.new(0, 0, 0)
            Root.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
end

local function ToggleFly(Enabled)
    Fly.Enabled = Enabled
    if Enabled then
        StartFly()
    else
        StopFly()
    end
end

-- ============================================================
--  ESP FUNCTIONS (using VisualLibrary)
-- ============================================================

local function ClearPlayerESP(Player)
    if ESP.PlayerData[Player] then
        local Data = ESP.PlayerData[Player]
        if Data.Skeleton then Data.Skeleton:Remove() end
        if Data.Box then Data.Box:Remove() end
        if Data.Tracer then Data.Tracer:Remove() end
        if Data.Highlight then Data.Highlight:Remove() end
        if Data.HealthBarOutline then Data.HealthBarOutline:Remove() end
        if Data.HealthBarFill then Data.HealthBarFill:Remove() end
        if Data.HealthBarTicks then
            for _, Tick in ipairs(Data.HealthBarTicks) do Tick:Remove() end
        end
        if Data.Chams then
            for Part, OriginalMaterial in pairs(Data.Chams) do
                if Part and Part.Parent then
                    Part.Material = OriginalMaterial
                end
            end
        end
        ESP.PlayerData[Player] = nil
    end
    if ESP.Connections[Player.Name .. "_TeamColor"] then
        ESP.Connections[Player.Name .. "_TeamColor"]:Disconnect()
        ESP.Connections[Player.Name .. "_TeamColor"] = nil
    end
end

local function ClearAllESP()
    for Player, _ in pairs(ESP.PlayerData) do
        ClearPlayerESP(Player)
    end
end

local function CreatePlayerESP(Player)
    if Player == LocalPlayer or not Player.Character then return end
    local TeamColor = Player.TeamColor and Player.TeamColor.Color or Color3.new(1, 1, 1)

    local Box = nil
    if ESP.Settings.Box then
        Box = Visuals:CreateVisual("Drawing", {Type="Square", Thickness=1, Color=TeamColor, Filled=false, Transparency=1})
        Box:StartTracking(Player)
    end

    local Tracer = nil
    if TracerLines.Enabled then
        Tracer = Visuals:CreateVisual("Drawing", {Type="Line", Thickness=1, Color=TeamColor, Transparency=1})
        Tracer:StartTracking(Player)
    end

    local Skeleton = nil
    if ESP.Settings.Skeleton then
        Skeleton = Visuals:CreateVisual("Drawing", {Type="Skeleton", Player=Player, Color=TeamColor, Thickness=1})
        Skeleton:StartTracking(true)
    end

    local HighlightObj = nil
    if Highlight.Enabled then
        HighlightObj = Visuals:CreateVisual("Highlight", {
            Target = Player.Character,
            Color = TeamColor,
            Transparency = 0.5,
            StrokeColor = Color3.new(1,1,1),
            OutlineTransparency = 0
        })
    end

    local HealthBarOutline = nil
    local HealthBarFill = nil
    local HealthBarTicks = nil
    if ESP.Settings.HealthBar then
        HealthBarOutline = Drawing.new("Square")
        HealthBarOutline.Color = Color3.fromRGB(18, 20, 28)
        HealthBarOutline.Filled = true
        HealthBarOutline.Transparency = 1
        HealthBarOutline.Visible = false

        HealthBarFill = Drawing.new("Square")
        HealthBarFill.Filled = true
        HealthBarFill.Transparency = 1
        HealthBarFill.Visible = false

        HealthBarTicks = {}
        for _ = 1, 4 do
            local Tick = Drawing.new("Line")
            Tick.Color = Color3.fromRGB(90, 96, 112)
            Tick.Thickness = 1
            Tick.Transparency = 0.9
            Tick.Visible = false
            table.insert(HealthBarTicks, Tick)
        end
    end

    local Chams = nil
    if Chams.Enabled and Player.Character then
        Chams = {}
        for _, Part in pairs(Player.Character:GetDescendants()) do
            if Part:IsA("BasePart") then
                Chams[Part] = Part.Material
                Part.Material = Enum.Material.ForceField
            end
        end
    end

    ESP.PlayerData[Player] = {
        Skeleton = Skeleton,
        Box = Box,
        Tracer = Tracer,
        Highlight = HighlightObj,
        HealthBarOutline = HealthBarOutline,
        HealthBarFill = HealthBarFill,
        HealthBarTicks = HealthBarTicks,
        Chams = Chams,
        Character = Player.Character
    }

    ESP.Connections[Player.Name .. "_TeamColor"] = Player:GetPropertyChangedSignal("TeamColor"):Connect(function()
        if ESP.PlayerData[Player] then
            local NewColor = Player.TeamColor and Player.TeamColor.Color or Color3.new(1, 1, 1)
            local Data = ESP.PlayerData[Player]
            if Data.Box and Data.Box.Object then Data.Box.Object.Color = NewColor end
            if Data.Tracer and Data.Tracer.Object then Data.Tracer.Object.Color = NewColor end
            if Data.Skeleton then Data.Skeleton:SetColor(NewColor) end
            if Data.Highlight and Data.Highlight.Object then Data.Highlight.Object.FillColor = NewColor end
        end
    end)
end

local function RebuildAllESP()
    if not ESP.Enabled then return end
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            ClearPlayerESP(Player)
            local TargetRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local TargetHumanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
            if TargetRoot and TargetHumanoid and TargetHumanoid.Health > 0 and Player.Parent == Players then
                local Distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position and (LocalPlayer.Character.HumanoidRootPart.Position - TargetRoot.Position).Magnitude) or math.huge
                if Distance <= ESP.Settings.DistanceLimit then
                    CreatePlayerESP(Player)
                end
            end
        end
    end
end

local function StartESP()
    if ESP.RenderConnection then return end

    ESP.RenderConnection = RunService.RenderStepped:Connect(function()
        if not ESP.Enabled then
            for _, Data in pairs(ESP.PlayerData) do
                if Data.Box and Data.Box.Object then Data.Box.Object.Visible = false end
                if Data.Tracer and Data.Tracer.Object then Data.Tracer.Object.Visible = false end
                if Data.HealthBarOutline then Data.HealthBarOutline.Visible = false end
                if Data.HealthBarFill then Data.HealthBarFill.Visible = false end
                if Data.HealthBarTicks then for _, Tick in ipairs(Data.HealthBarTicks) do Tick.Visible = false end end
            end
            return
        end

        for Player, Data in pairs(ESP.PlayerData) do
            if not Player or not Player.Parent then
                ClearPlayerESP(Player)
                continue
            end

            local OnScreen, Size, Pos = Visuals:GetBoundingBox(Player)
            local TeamColor = Player.TeamColor and Player.TeamColor.Color or Color3.new(1, 1, 1)

            if Data.Box and Data.Box.Object then
                if OnScreen and ESP.Settings.Box then
                    Data.Box.Object.Position = Pos
                    Data.Box.Object.Size = Size
                    Data.Box.Object.Color = TeamColor
                    Data.Box.Object.Visible = true
                else
                    Data.Box.Object.Visible = false
                end
            end

            if Data.Tracer and Data.Tracer.Object then
                if OnScreen and TracerLines.Enabled then
                    local Viewport = workspace.CurrentCamera.ViewportSize
                    Data.Tracer.Object.From = Vector2.new(Viewport.X / 2, Viewport.Y)
                    Data.Tracer.Object.Visible = true
                else
                    Data.Tracer.Object.Visible = false
                end
            end

            if Data.HealthBarOutline and Data.HealthBarFill then
                if OnScreen and ESP.Settings.HealthBar then
                    local Humanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
                    if Humanoid and Humanoid.Health > 0 then
                        local HealthPercent = math.clamp(Humanoid.Health / math.max(Humanoid.MaxHealth, 1), 0, 1)
                        local BarHeight = Size.Y
                        local BarX = Pos.X - 8
                        local BarY = Pos.Y

                        Data.HealthBarOutline.Position = Vector2.new(BarX - 1, BarY - 2)
                        Data.HealthBarOutline.Size = Vector2.new(5, BarHeight + 4)
                        Data.HealthBarOutline.Visible = true

                        Data.HealthBarFill.Position = Vector2.new(BarX, BarY + BarHeight * (1 - HealthPercent))
                        Data.HealthBarFill.Size = Vector2.new(3, math.max(BarHeight * HealthPercent, 1))
                        Data.HealthBarFill.Color = Color3.fromHSV(HealthPercent * 0.33, 0.9, 1)
                        Data.HealthBarFill.Visible = true

                        if Data.HealthBarTicks then
                            for Index, Tick in ipairs(Data.HealthBarTicks) do
                                local Y = BarY + (BarHeight * Index / 5)
                                Tick.From = Vector2.new(BarX - 1, Y)
                                Tick.To = Vector2.new(BarX + 4, Y)
                                Tick.Visible = true
                            end
                        end
                    else
                        Data.HealthBarOutline.Visible = false
                        Data.HealthBarFill.Visible = false
                        if Data.HealthBarTicks then for _, Tick in ipairs(Data.HealthBarTicks) do Tick.Visible = false end end
                    end
                else
                    Data.HealthBarOutline.Visible = false
                    Data.HealthBarFill.Visible = false
                    if Data.HealthBarTicks then for _, Tick in ipairs(Data.HealthBarTicks) do Tick.Visible = false end end
                end
            end
        end
    end)

    ESP.UpdateConnection = RunService.Heartbeat:Connect(function()
        if ESP.Enabled then
            for Player, _ in pairs(ESP.PlayerData) do
                if not Player or Player.Parent ~= Players then
                    ClearPlayerESP(Player)
                end
            end

            local LocalRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not LocalRoot then return end

            for _, Player in ipairs(Players:GetPlayers()) do
                if Player ~= LocalPlayer then
                    local TargetRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    local TargetHumanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
                    if TargetRoot and TargetHumanoid and TargetHumanoid.Health > 0 and Player.Parent == Players then
                        local Distance = (LocalRoot.Position - TargetRoot.Position).Magnitude
                        if Distance <= ESP.Settings.DistanceLimit then
                            if not ESP.PlayerData[Player] or ESP.PlayerData[Player].Character ~= Player.Character then
                                if ESP.PlayerData[Player] then ClearPlayerESP(Player) end
                                CreatePlayerESP(Player)
                            end
                        else
                            ClearPlayerESP(Player)
                        end
                    else
                        ClearPlayerESP(Player)
                    end
                end
            end
        end
    end)
end

local function StopESP()
    if ESP.RenderConnection then
        ESP.RenderConnection:Disconnect()
        ESP.RenderConnection = nil
    end
    if ESP.UpdateConnection then
        ESP.UpdateConnection:Disconnect()
        ESP.UpdateConnection = nil
    end
    ClearAllESP()
end

local function ToggleESP(Enabled)
    ESP.Enabled = Enabled
    if Enabled then
        StartESP()
    else
        StopESP()
    end
end

-- ============================================================
--  GREYSCALE FUNCTIONS
-- ============================================================

local function ToggleGreyscale(Enabled)
    Greyscale.Enabled = Enabled
    if Enabled then
        if Greyscale.Effect then Greyscale.Effect:Destroy() end
        Greyscale.Effect = Instance.new("ColorCorrectionEffect")
        Greyscale.Effect.Saturation = -1
        Greyscale.Effect.Parent = Lighting
    else
        if Greyscale.Effect then
            Greyscale.Effect:Destroy()
            Greyscale.Effect = nil
        end
    end
end

-- ============================================================
--  MODERATOR DETECTOR FUNCTIONS
-- ============================================================

local function CheckModerators()
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Rank = GetPlayerRank(Player)
            if Rank and Rank >= 248 then
                local Role = GetPlayerRole(Player)
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
end

local function EnableModeratorDetector()
    if ModeratorDetector.Connection then return end
    CheckModerators()

    ModeratorDetector.AddedConnection = Players.PlayerAdded:Connect(function(Player)
        if ModeratorDetector.Enabled then
            task.wait(1)
            local Rank = GetPlayerRank(Player)
            if Rank and Rank >= 248 then
                local Role = GetPlayerRole(Player)
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

    ModeratorDetector.RemovingConnection = Players.PlayerRemoving:Connect(function(Player)
        if ModeratorDetector.Enabled then
            local Rank = GetPlayerRank(Player)
            if Rank and Rank >= 248 then
                local Role = GetPlayerRole(Player)
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

    ModeratorDetector.Connection = true
end

local function DisableModeratorDetector()
    if ModeratorDetector.AddedConnection then
        ModeratorDetector.AddedConnection:Disconnect()
        ModeratorDetector.AddedConnection = nil
    end
    if ModeratorDetector.RemovingConnection then
        ModeratorDetector.RemovingConnection:Disconnect()
        ModeratorDetector.RemovingConnection = nil
    end
    ModeratorDetector.Connection = nil
end

local function ToggleModeratorDetector(Enabled)
    ModeratorDetector.Enabled = Enabled
    if Enabled then
        EnableModeratorDetector()
    else
        DisableModeratorDetector()
    end
end

-- ============================================================
--  ANTI AFK FUNCTIONS
-- ============================================================

local function ToggleAntiAFK(Enabled)
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
    else
        if AntiAFK.Connection then
            AntiAFK.Connection:Disconnect()
            AntiAFK.Connection = nil
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
--  COMBAT TAB
-- ============================================================

local Targeting = CombatTab:CreateSection("Targeting", "Normal")

Targeting:CreateToggle("Normal", {
    Name = "Silent Aim",
    Flag = "SilentAim",
    Callback = function(Enabled)
        ToggleSilentAim(Enabled)
        print("Silent Aim " .. (Enabled and "ON" or "OFF"))
    end
})

Targeting:CreateToggle("Normal", {
    Name = "Wall Check",
    Flag = "SilentAimWallCheck",
    CurrentValue = SilentAim.WallCheck,
    Callback = function(Enabled)
        SilentAim.WallCheck = Enabled
        print("Wall Check " .. (Enabled and "ON" or "OFF"))
    end
})

Targeting:CreateToggle("Normal", {
    Name = "Show FOV",
    Flag = "ShowFOV",
    Callback = function(Enabled)
        FOV.Enabled = Enabled
        print("Show FOV " .. (Enabled and "ON" or "OFF"))
    end
})

Targeting:CreateSlider({
    Name = "FOV Radius",
    Value = {25, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = FOV.Radius,
    Flag = "FOVRadius",
    Callback = function(Value)
        FOV.Radius = Value
        print("FOV Radius set to " .. Value)
    end
})

Targeting:CreateColorPicker({
    Name = "FOV Color",
    Callback = function(Color)
        FOV.Color = Color
        print("FOV color changed to", Color)
    end
})

Targeting:CreateDropdown({
    Name = "Hit Part",
    Options = {"Head", "UpperTorso", "HumanoidRootPart", "Randomized"},
    CurrentOption = SilentAim.HitPart,
    Flag = "HitPart",
    Callback = function(Selected)
        SilentAim.HitPart = Selected
        print("Hit Part set to " .. Selected)
    end
})

Targeting:CreateSlider({
    Name = "Hit Chance",
    Value = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = SilentAim.HitChance,
    Flag = "HitChance",
    Callback = function(Value)
        SilentAim.HitChance = Value
        print("Hit Chance set to " .. Value .. "%")
    end
})

Targeting:CreateToggle("Normal", {
    Name = "Hitbox",
    Flag = "Hitbox",
    Callback = function(Enabled)
        Hitbox.Enabled = Enabled
        print("Hitbox " .. (Enabled and "ON" or "OFF"))
    end
})

Targeting:CreateSlider({
    Name = "Hitbox Size",
    Value = {1, 10},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = Hitbox.Size,
    Flag = "HitboxSize",
    Callback = function(Value)
        Hitbox.Size = Value
        print("Hitbox Size set to " .. Value)
    end
})

local FOVSection = CombatTab:CreateSection("FOV", "Normal")

FOVSection:CreateToggle("Normal", {
    Name = "Show FOV",
    Flag = "ShowFOV",
    Callback = function(Enabled)
        FOV.Enabled = Enabled
        print("Show FOV " .. (Enabled and "ON" or "OFF"))
    end
})

FOVSection:CreateSlider({
    Name = "FOV Radius",
    Value = {25, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = FOV.Radius,
    Flag = "FOVRadius",
    Callback = function(Value)
        FOV.Radius = Value
        print("FOV Radius set to " .. Value)
    end
})

FOVSection:CreateColorPicker({
    Name = "FOV Color",
    Callback = function(Color)
        FOV.Color = Color
        print("FOV color changed to", Color)
    end
})

local Checks = CombatTab:CreateSection("Checks", "Normal")

Checks:CreateToggle("Normal", {
    Name = "Wall Check",
    Flag = "WallCheck",
    Callback = function(Enabled)
        WallCheck.Enabled = Enabled
        print("Wall Check " .. (Enabled and "ON" or "OFF"))
    end
})

Checks:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "TeamCheck",
    Callback = function(Enabled)
        TeamCheck.Enabled = Enabled
        print("Team Check " .. (Enabled and "ON" or "OFF"))
    end
})

local Automation = CombatTab:CreateSection("Automation", "Normal")

Automation:CreateToggle("Normal", {
    Name = "Auto Trigger",
    Flag = "AutoTrigger",
    Callback = function(Enabled)
        AutoTrigger.Enabled = Enabled
        print("Auto Trigger " .. (Enabled and "ON" or "OFF"))
    end
})

Automation:CreateSlider({
    Name = "Trigger Delay",
    Value = {0, 500},
    Increment = 10,
    Suffix = "ms",
    CurrentValue = TriggerDelay.Value,
    Flag = "TriggerDelay",
    Callback = function(Value)
        TriggerDelay.Value = Value
        print("Trigger Delay set to " .. Value .. "ms")
    end
})

local Weapons = CombatTab:CreateSection("Weapons", "Normal")

Weapons:CreateToggle("Normal", {
    Name = "Auto Reload",
    Flag = "AutoReload",
    Callback = function(Enabled)
        AutoReload.Enabled = Enabled
        print("Auto Reload " .. (Enabled and "ON" or "OFF"))
    end
})

-- ============================================================
--  VISUALS TAB
-- ============================================================

local ESPSection = VisualsTab:CreateSection("ESP", "Normal")

ESPSection:CreateToggle("Normal", {
    Name = "Enable ESP",
    Flag = "ESPEnabled",
    Callback = function(Enabled)
        ToggleESP(Enabled)
        print("Enable ESP " .. (Enabled and "ON" or "OFF"))
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Box ESP",
    Flag = "ESPBox",
    Callback = function(Enabled)
        ESP.Settings.Box = Enabled
        if ESP.Enabled then RebuildAllESP() end
        print("Box ESP " .. (Enabled and "ON" or "OFF"))
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Name ESP",
    Flag = "ESPName",
    Callback = function(Enabled)
        ESP.Settings.Name = Enabled
        if ESP.Enabled then RebuildAllESP() end
        print("Name ESP " .. (Enabled and "ON" or "OFF"))
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Distance ESP",
    Flag = "ESPDistance",
    Callback = function(Enabled)
        ESP.Settings.Distance = Enabled
        if ESP.Enabled then RebuildAllESP() end
        print("Distance ESP " .. (Enabled and "ON" or "OFF"))
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Weapon ESP",
    Flag = "ESPWeapon",
    Callback = function(Enabled)
        ESP.Settings.Weapon = Enabled
        if ESP.Enabled then RebuildAllESP() end
        print("Weapon ESP " .. (Enabled and "ON" or "OFF"))
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Health Bar",
    Flag = "ESPHealthBar",
    Callback = function(Enabled)
        ESP.Settings.HealthBar = Enabled
        if ESP.Enabled then RebuildAllESP() end
        print("Health Bar " .. (Enabled and "ON" or "OFF"))
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Skeleton ESP",
    Flag = "ESPSkeleton",
    Callback = function(Enabled)
        ESP.Settings.Skeleton = Enabled
        if ESP.Enabled then RebuildAllESP() end
        print("Skeleton ESP " .. (Enabled and "ON" or "OFF"))
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "ESPTeamCheck",
    Callback = function(Enabled)
        ESP.Settings.TeamCheck = Enabled
        if ESP.Enabled then RebuildAllESP() end
        print("Team Check (ESP) " .. (Enabled and "ON" or "OFF"))
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Friend Check",
    Flag = "FriendCheck",
    Callback = function(Enabled)
        ESP.Settings.FriendCheck = Enabled
        if ESP.Enabled then RebuildAllESP() end
        print("Friend Check " .. (Enabled and "ON" or "OFF"))
    end
})

ESPSection:CreateSlider({
    Name = "Distance Limit",
    Value = {50, 2000},
    Increment = 50,
    Suffix = " studs",
    CurrentValue = ESP.Settings.DistanceLimit,
    Flag = "DistanceLimit",
    Callback = function(Value)
        ESP.Settings.DistanceLimit = Value
        if ESP.Enabled then RebuildAllESP() end
        print("Distance Limit set to " .. Value .. " studs")
    end
})

local Effects = VisualsTab:CreateSection("Effects", "Normal")

Effects:CreateToggle("Normal", {
    Name = "Highlight",
    Flag = "Highlight",
    Callback = function(Enabled)
        Highlight.Enabled = Enabled
        if ESP.Enabled then RebuildAllESP() end
        print("Highlight " .. (Enabled and "ON" or "OFF"))
    end
})

Effects:CreateToggle("Normal", {
    Name = "Chams",
    Flag = "Chams",
    Callback = function(Enabled)
        Chams.Enabled = Enabled
        if ESP.Enabled then RebuildAllESP() end
        print("Chams " .. (Enabled and "ON" or "OFF"))
    end
})

Effects:CreateToggle("Normal", {
    Name = "Tracer Lines",
    Flag = "TracerLines",
    Callback = function(Enabled)
        TracerLines.Enabled = Enabled
        if ESP.Enabled then RebuildAllESP() end
        print("Tracer Lines " .. (Enabled and "ON" or "OFF"))
    end
})

Effects:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Center", "Mouse"},
    CurrentOption = TracerOrigin.Selected,
    Flag = "TracerOrigin",
    Callback = function(Selected)
        TracerOrigin.Selected = Selected
        print("Tracer Origin set to " .. Selected)
    end
})

Effects:CreateToggle("Normal", {
    Name = "Greyscale World",
    Flag = "GreyscaleWorld",
    Callback = function(Enabled)
        ToggleGreyscale(Enabled)
        print("Greyscale World " .. (Enabled and "ON" or "OFF"))
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
        ToggleMovementSpoof(Enabled)
        print("Enable Walk Speed " .. (Enabled and "ON" or "OFF"))
    end
})

Character:CreateSlider({
    Name = "Walk Speed",
    Value = {16, 100},
    Increment = 1,
    Suffix = "",
    CurrentValue = MovementSpoof.WalkSpeed,
    Flag = "WalkSpeed",
    Callback = function(Value)
        MovementSpoof.WalkSpeed = Value
        if MovementSpoof.Active then
            SetMovementWalkSpeed(Value)
        end
        print("Walk Speed set to " .. Value)
    end
})

Character:CreateToggle("Normal", {
    Name = "Enable Jump Power",
    Flag = "JumpPowerEnabled",
    Callback = function(Enabled)
        ToggleMovementSpoof(Enabled)
        print("Enable Jump Power " .. (Enabled and "ON" or "OFF"))
    end
})

Character:CreateSlider({
    Name = "Jump Power",
    Value = {50, 200},
    Increment = 5,
    Suffix = "",
    CurrentValue = MovementSpoof.JumpPower,
    Flag = "JumpPower",
    Callback = function(Value)
        MovementSpoof.JumpPower = Value
        if MovementSpoof.Active then
            SetMovementJumpPower(Value)
        end
        print("Jump Power set to " .. Value)
    end
})

Character:CreateToggle("Normal", {
    Name = "No Clip",
    Flag = "NoClip",
    Callback = function(Enabled)
        ToggleNoClip(Enabled)
        print("No Clip " .. (Enabled and "ON" or "OFF"))
    end
})

Character:CreateKeybind({
    Name = "No Clip Keybind",
    Flag = "NoClipKeybind",
    Keybind = NoClip.Keybind,
    Type = "Press",
    Callback = function(State)
        if State then
            ToggleNoClip(not NoClip.Enabled)
        end
        print("No Clip key " .. (State and "pressed" or "released"))
    end
})

Character:CreateToggle("Normal", {
    Name = "Fly",
    Flag = "Fly",
    Callback = function(Enabled)
        ToggleFly(Enabled)
        print("Fly " .. (Enabled and "ON" or "OFF"))
    end
})

Character:CreateKeybind({
    Name = "Fly Keybind",
    Flag = "FlyKeybind",
    Keybind = Fly.Keybind,
    Type = "Press",
    Callback = function(State)
        if State then
            ToggleFly(not Fly.Enabled)
        end
        print("Fly key " .. (State and "pressed" or "released"))
    end
})

Character:CreateSlider({
    Name = "Fly Speed",
    Value = {10, 200},
    Increment = 5,
    Suffix = "",
    CurrentValue = Fly.Speed,
    Flag = "FlySpeed",
    Callback = function(Value)
        Fly.Speed = Value
        print("Fly Speed set to " .. Value)
    end
})

Character:CreateLabel({
    Description = "WASD to move, Space to fly up, Shift to fly down."
})

-- ============================================================
--  UTILITIES TAB
-- ============================================================

local Utilities = UtilitiesTab:CreateSection("Utilities", "Normal")

Utilities:CreateToggle("Normal", {
    Name = "Moderator Detector",
    Flag = "ModeratorDetector",
    Callback = function(Enabled)
        ToggleModeratorDetector(Enabled)
        print("Moderator Detector " .. (Enabled and "ON" or "OFF"))
    end
})

Utilities:CreateToggle("Normal", {
    Name = "Enable Anti AFK",
    Flag = "AntiAFK",
    Callback = function(Enabled)
        ToggleAntiAFK(Enabled)
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

-- ============================================================
--  FOV RENDER LOOP
-- ============================================================

RunService.RenderStepped:Connect(function()
    if FOV.Enabled then
        FOV.Circle.Position = UserInputService:GetMouseLocation()
        FOV.Circle.Radius = FOV.Radius
        FOV.Circle.Color = FOV.Color
        FOV.Circle.Visible = true
    else
        FOV.Circle.Visible = false
    end
end)

-- ============================================================
--  PLAYER REMOVING CLEANUP
-- ============================================================

Players.PlayerRemoving:Connect(function(Player)
    if ESP.PlayerData[Player] then
        ClearPlayerESP(Player)
    end
end)

print("SCP:RP UI loaded.")