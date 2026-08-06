-- Matrice Softworks

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Visuals = Matrice.Visuals

local FriendList = {}
local FriendListUpdateTask = nil

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
--  COMBAT TAB (Placeholders – no logic yet)
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

local SilentAimFriendCheckEnabled = false

Checks:CreateToggle("Normal", {
    Name = "Friend Check",
    Flag = "SilentAimFriendCheck",
    CurrentValue = false,
    Callback = function(Enabled)
        SilentAimFriendCheckEnabled = Enabled
        print("Friend Check (Silent Aim) " .. (Enabled and "ON" or "OFF"))
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
--  VISUALS TAB – Fully functional ESP
-- ============================================================

local ESPEnabled = false
local ESPData = {}
local ESPConnection = nil
local RenderConnection = nil
local CurrentTracerOrigin = "Bottom"

local function ClearESP(player)
    if ESPData[player] then
        for _, obj in ipairs(ESPData[player]) do
            pcall(obj.Remove, obj)
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
    table.insert(esp, box)

    local nameText = Drawing.new("Text")
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0)
    nameText.Color = teamColor
    nameText.Size = 18
    nameText.Visible = false
    nameText.Text = player.Name
    table.insert(esp, nameText)

    local distText = Drawing.new("Text")
    distText.Center = true
    distText.Outline = true
    distText.OutlineColor = Color3.new(0, 0, 0)
    distText.Color = Color3.new(1, 1, 1)
    distText.Size = 14
    distText.Visible = false
    table.insert(esp, distText)

    local weaponText = Drawing.new("Text")
    weaponText.Center = true
    weaponText.Outline = true
    weaponText.OutlineColor = Color3.new(0, 0, 0)
    weaponText.Color = Color3.new(1, 1, 1)
    weaponText.Size = 14
    weaponText.Visible = false
    table.insert(esp, weaponText)

    local healthOutline = Drawing.new("Square")
    healthOutline.Thickness = 0
    healthOutline.Filled = true
    healthOutline.Color = Color3.fromRGB(18, 20, 28)
    healthOutline.Transparency = 1
    healthOutline.Visible = false
    table.insert(esp, healthOutline)

    local healthFill = Drawing.new("Square")
    healthFill.Thickness = 0
    healthFill.Filled = true
    healthFill.Transparency = 1
    healthFill.Visible = false
    table.insert(esp, healthFill)

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Color = teamColor
    tracer.Transparency = 1
    tracer.Visible = false
    table.insert(esp, tracer)

    local skeleton = nil
    if getgenv().SkeletonEnabled then
        skeleton = Visuals:CreateVisual("Drawing", {
            Type = "Skeleton",
            Player = player,
            Color = teamColor,
            Thickness = 1
        })
        table.insert(esp, skeleton)
    end

    local highlight = nil
    if getgenv().HighlightEnabled then
        highlight = Visuals:CreateVisual("Highlight", {
            Target = player.Character,
            Color = teamColor,
            Transparency = 0.5,
            StrokeColor = Color3.new(1, 1, 1),
            OutlineTransparency = 0,
        })
        table.insert(esp, highlight)
    end

    local chams = {}
    if getgenv().ChamsEnabled and player.Character then
        for _, part in ipairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                chams[part] = part.Material
                part.Material = Enum.Material.ForceField
            end
        end
    end
    local chamsCleanup = {
        Remove = function()
            for part, mat in pairs(chams) do
                if part and part.Parent then
                    part.Material = mat
                end
            end
        end
    }
    table.insert(esp, chamsCleanup)

    ESPData[player] = esp
end

local function RebuildESP()
    ClearAllESP()
    if not ESPEnabled then return end
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if targetRoot and humanoid and humanoid.Health > 0 and player.Parent == Players then
                local distance = (localRoot.Position - targetRoot.Position).Magnitude
                if distance <= getgenv().DistanceLimit then
                    BuildESP(player)
                end
            end
        end
    end
end

local function UpdateESP()
    if not ESPEnabled then return end
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
                if distance <= getgenv().DistanceLimit then
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
    if not ESPEnabled then
        for _, esp in pairs(ESPData) do
            for _, obj in ipairs(esp) do
                if obj.Visible ~= nil then
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
                if getgenv().TeamCheckEnabled and localTeam and player.Team == localTeam then
                    for _, obj in ipairs(esp) do
                        if obj.Visible ~= nil then
                            obj.Visible = false
                        end
                    end
                    continue
                end

                if getgenv().FriendCheckEnabled and FriendList[player.UserId] then
                    for _, obj in ipairs(esp) do
                        if obj.Visible ~= nil then
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

                    if getgenv().BoxEnabled and esp[1] then
                        esp[1].Size = size
                        esp[1].Position = pos
                        esp[1].Color = teamColor
                        esp[1].Visible = true
                    else
                        if esp[1] then esp[1].Visible = false end
                    end

                    if getgenv().NameEnabled and esp[2] then
                        esp[2].Position = Vector2.new(pos.X + size.X/2, pos.Y - 20)
                        esp[2].Text = player.Name
                        esp[2].Color = teamColor
                        esp[2].Visible = true
                    else
                        if esp[2] then esp[2].Visible = false end
                    end

                    if getgenv().DistanceEnabled and esp[3] then
                        esp[3].Position = Vector2.new(pos.X + size.X/2, pos.Y + size.Y + 16)
                        esp[3].Text = math.floor(distance) .. " studs"
                        esp[3].Visible = true
                    else
                        if esp[3] then esp[3].Visible = false end
                    end

                    if getgenv().WeaponEnabled and esp[4] then
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
                        esp[4].Text = weaponName .. ammoText
                        esp[4].Position = Vector2.new(pos.X + size.X/2, pos.Y + size.Y + 34)
                        esp[4].Visible = true
                    else
                        if esp[4] then esp[4].Visible = false end
                    end

                    if getgenv().HealthBarEnabled and esp[5] and esp[6] then
                        local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                        local barX = pos.X - 8
                        local barY = pos.Y
                        local barHeight = size.Y
                        esp[5].Position = Vector2.new(barX - 1, barY - 2)
                        esp[5].Size = Vector2.new(5, barHeight + 4)
                        esp[5].Visible = true
                        esp[6].Position = Vector2.new(barX, barY + barHeight * (1 - healthPercent))
                        esp[6].Size = Vector2.new(3, math.max(barHeight * healthPercent, 1))
                        esp[6].Color = Color3.fromHSV(healthPercent * 0.33, 0.9, 1)
                        esp[6].Visible = true
                    else
                        if esp[5] then esp[5].Visible = false end
                        if esp[6] then esp[6].Visible = false end
                    end

                    if getgenv().TracerEnabled and esp[7] then
                        local origin = CurrentTracerOrigin
                        local from
                        if origin == "Bottom" then
                            from = Vector2.new(centerX, centerY)
                        else
                            from = Vector2.new(centerX, centerY/2)
                        end
                        esp[7].From = from
                        esp[7].To = Vector2.new(pos.X + size.X/2, pos.Y + size.Y)
                        esp[7].Color = teamColor
                        esp[7].Visible = true
                    else
                        if esp[7] then esp[7].Visible = false end
                    end
                else
                    for _, obj in ipairs(esp) do
                        if obj.Visible ~= nil then
                            obj.Visible = false
                        end
                    end
                end
            else
                for _, obj in ipairs(esp) do
                    if obj.Visible ~= nil then
                        obj.Visible = false
                    end
                end
            end
        else
            for _, obj in ipairs(esp) do
                if obj.Visible ~= nil then
                    obj.Visible = false
                end
            end
        end
    end
end

getgenv().ESPEnabled = false
getgenv().BoxEnabled = false
getgenv().NameEnabled = false
getgenv().DistanceEnabled = false
getgenv().WeaponEnabled = false
getgenv().HealthBarEnabled = false
getgenv().SkeletonEnabled = false
getgenv().TeamCheckEnabled = false
getgenv().FriendCheckEnabled = false
getgenv().DistanceLimit = 600
getgenv().HighlightEnabled = false
getgenv().ChamsEnabled = false
getgenv().TracerEnabled = false
getgenv().TracerOrigin = "Bottom"

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
    if FriendListUpdateTask then task.cancel(FriendListUpdateTask); FriendListUpdateTask = nil end
    ClearAllESP()
end

local ESPSection = VisualsTab:CreateSection("ESP", "Normal")

ESPSection:CreateToggle("Normal", {
    Name = "Enable ESP",
    Flag = "ESPEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        ESPEnabled = Enabled
        getgenv().ESPEnabled = Enabled
        if Enabled then
            StartESP()
        else
            StopESP()
        end
    end
})

ESPSection:CreateDivider()

ESPSection:CreateToggle("Normal", {
    Name = "Box ESP",
    Flag = "BoxEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        getgenv().BoxEnabled = Enabled
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Name ESP",
    Flag = "NameEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        getgenv().NameEnabled = Enabled
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Distance ESP",
    Flag = "DistanceEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        getgenv().DistanceEnabled = Enabled
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Weapon ESP",
    Flag = "WeaponEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        getgenv().WeaponEnabled = Enabled
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Health Bar",
    Flag = "HealthBarEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        getgenv().HealthBarEnabled = Enabled
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Skeleton ESP",
    Flag = "SkeletonEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        getgenv().SkeletonEnabled = Enabled
        if ESPEnabled then RebuildESP() end
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Team Check",
    Flag = "TeamCheckEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        getgenv().TeamCheckEnabled = Enabled
    end
})

ESPSection:CreateToggle("Normal", {
    Name = "Friend Check",
    Flag = "FriendCheckEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        getgenv().FriendCheckEnabled = Enabled
    end
})

ESPSection:CreateSlider({
    Name = "Distance Limit",
    Value = {50, 2000},
    Increment = 50,
    Suffix = " studs",
    Flag = "DistanceLimit",
    CurrentValue = 600,
    Callback = function(Value)
        getgenv().DistanceLimit = Value
    end
})

local EffectsSection = VisualsTab:CreateSection("Effects", "Normal")

EffectsSection:CreateToggle("Normal", {
    Name = "Highlight",
    Flag = "HighlightEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        getgenv().HighlightEnabled = Enabled
        if ESPEnabled then RebuildESP() end
    end
})

EffectsSection:CreateToggle("Normal", {
    Name = "Chams",
    Flag = "ChamsEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        getgenv().ChamsEnabled = Enabled
        if ESPEnabled then RebuildESP() end
    end
})

EffectsSection:CreateToggle("Normal", {
    Name = "Tracer Lines",
    Flag = "TracerEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        getgenv().TracerEnabled = Enabled
    end
})

EffectsSection:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Center"},
    CurrentOption = "Bottom",
    Flag = "TracerOrigin",
    Callback = function(Selected)
        getgenv().TracerOrigin = Selected
        CurrentTracerOrigin = Selected
    end
})

-- ============================================================
--  PLAYER TAB – Fully functional with keybind toggle (master + active)
-- ============================================================

local Character = PlayerTab:CreateSection("Character", "Normal")

-- State variables
local SpeedEnabled = false
local JumpEnabled = false
local WalkSpeedValue = 24
local JumpPowerValue = 50
local FlySpeedValue = 50

-- NoClip: master toggle + active state (keybind toggles active)
local NoClipMaster = false
local NoClipActive = false

-- Fly: master toggle + active state (keybind toggles active)
local FlyMaster = false
local FlyActive = false

local PlayerModsCharacterAddedConnection = nil

-- Apply speed/jump
local function ApplySpeedJumpToHumanoid(Humanoid)
    if not Humanoid then return end
    Humanoid.WalkSpeed = SpeedEnabled and WalkSpeedValue or 16
    Humanoid.JumpPower = JumpEnabled and JumpPowerValue or 50
end

local function ApplySpeedJumpToCharacter()
    local Char = LocalPlayer.Character
    if not Char then return end
    local Humanoid = Char:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        ApplySpeedJumpToHumanoid(Humanoid)
    end
end

-- NoClip apply
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

-- Fly logic
local FlyConnection = nil
local FlyCharacterConnection = nil

local function StartFly()
    if FlyConnection then return end
    FlyConnection = RunService.Heartbeat:Connect(function()
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
        Root.CFrame = Root.CFrame + MoveDirection * RunService.Heartbeat:Wait()
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

-- Update fly state based on master + active
local function UpdateFly()
    if FlyMaster and FlyActive then
        StartFly()
    else
        StopFly()
    end
end

-- Character respawn handler
local function OnCharacterAdded()
    task.wait(0.1)
    ApplySpeedJumpToCharacter()
    ApplyNoClip()
end

local function SetupCharacterAddedListener()
    if PlayerModsCharacterAddedConnection then
        PlayerModsCharacterAddedConnection:Disconnect()
    end
    PlayerModsCharacterAddedConnection = LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
end

-- Create UI elements
Character:CreateToggle("Normal", {
    Name = "Enable Walk Speed",
    Flag = "WalkSpeedEnabled",
    CurrentValue = false,
    Callback = function(Enabled)
        SpeedEnabled = Enabled
        ApplySpeedJumpToCharacter()
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
        if SpeedEnabled then
            ApplySpeedJumpToCharacter()
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
        ApplySpeedJumpToCharacter()
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
        if JumpEnabled then
            ApplySpeedJumpToCharacter()
        end
        print("Jump Power set to " .. Value)
    end
})

-- No Clip master toggle (no SetToggle anywhere)
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

-- No Clip keybind – toggles active state (if master is ON)
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

-- Fly master toggle (no SetToggle anywhere)
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

-- Fly keybind – toggles active state (if master is ON)
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
--  UTILITIES TAB (unchanged)
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