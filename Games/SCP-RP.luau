--// Matrice – SCP: Roleplay (Visuals Only)
local UI = Matrice.UI
local Visuals = Matrice.Visuals

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- Minimal config
local Config = {
    ESPEnabled = false,
    HighlightEnabled = false,
    BoxEnabled = false,
    SkeletonEnabled = false,
    ChamsEnabled = false,
    TracerEnabled = false,
    HealthBarEnabled = false,
    ESPRange = 600,
}

getgenv().ESPEnabled = Config.ESPEnabled
getgenv().HighlightEnabled = Config.HighlightEnabled
getgenv().BoxEnabled = Config.BoxEnabled
getgenv().SkeletonEnabled = Config.SkeletonEnabled
getgenv().ChamsEnabled = Config.ChamsEnabled
getgenv().TracerEnabled = Config.TracerEnabled
getgenv().HealthBarEnabled = Config.HealthBarEnabled
getgenv().ESPRange = Config.ESPRange

local Library = UI:CreateLibrary({
    Name = "Matrice v" .. Matrice.Version .. " - Visuals Test",
    Icon = "rbxassetid://12974454446"
})

local VisualsTab = Library:CreateTab("Visuals", "rbxassetid://12974454446")
local ESPSection = VisualsTab:CreateSection("ESP Settings", "Normal")

-- ESP state
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
    local teamColor = player.TeamColor and player.TeamColor.Color or Color3.new(1,1,1)

    local box = nil
    if getgenv().BoxEnabled then
        box = Drawing.new("Square")
        box.Thickness = 1; box.Color = teamColor; box.Filled = false; box.Transparency = 1; box.Visible = false
    end

    local highlight = nil
    if getgenv().HighlightEnabled then
        highlight = Visuals:CreateVisual("Highlight", {
            Target = player.Character,
            Color = teamColor,
            Transparency = 0.5,
            StrokeColor = Color3.new(1,1,1),
            OutlineTransparency = 0,
        })
    end

    local skeleton = nil
    if getgenv().SkeletonEnabled then
        skeleton = Visuals:CreateVisual("Drawing", {
            Type = "Skeleton",
            Player = player,
            Color = teamColor,
            Thickness = 1
        })
    end

    local tracer = nil
    if getgenv().TracerEnabled then
        tracer = Drawing.new("Line")
        tracer.Thickness = 1; tracer.Color = teamColor; tracer.Transparency = 1; tracer.Visible = false
    end

    local healthBarOutline, healthBarFill, healthBarTicks = nil, nil, nil
    if getgenv().HealthBarEnabled then
        healthBarOutline = Drawing.new("Square"); healthBarOutline.Color = Color3.fromRGB(18,20,28); healthBarOutline.Filled = true; healthBarOutline.Transparency = 1; healthBarOutline.Visible = false
        healthBarFill = Drawing.new("Square"); healthBarFill.Filled = true; healthBarFill.Transparency = 1; healthBarFill.Visible = false
        healthBarTicks = {}
        for _ = 1,4 do
            local tick = Drawing.new("Line")
            tick.Color = Color3.fromRGB(90,96,112); tick.Thickness = 1; tick.Transparency = 0.9; tick.Visible = false
            table.insert(healthBarTicks, tick)
        end
    end

    local chams = nil
    if getgenv().ChamsEnabled and player.Character then
        chams = {}
        for _, v in pairs(player.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                chams[v] = v.Material
                v.Material = Enum.Material.ForceField
            end
        end
    end

    PlayerESPs[player] = {
        Skeleton = skeleton, Box = box, Tracer = tracer,
        HealthBarOutline = healthBarOutline, HealthBarFill = healthBarFill, HealthBarTicks = healthBarTicks,
        Highlight = highlight, Chams = chams, Character = player.Character
    }

    Connections[player.Name .. "_TeamColor"] = player:GetPropertyChangedSignal("TeamColor"):Connect(function()
        if PlayerESPs[player] then
            local newColor = player.TeamColor and player.TeamColor.Color or Color3.new(1,1,1)
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
    if not getgenv().ESPEnabled then return end
    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ClearPlayerESP(player)
            local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and player.Parent == Players then
                local distance = (localRoot.Position - targetRoot.Position).Magnitude
                if distance <= getgenv().ESPRange then
                    CreatePlayerESP(player)
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().ESPEnabled then ClearESPs(); continue end
        local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot then continue end
        for p,_ in pairs(PlayerESPs) do
            if not p or p.Parent ~= Players then ClearPlayerESP(p) end
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local targetRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local targetHumanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if targetRoot and targetHumanoid and targetHumanoid.Health > 0 and player.Parent == Players then
                    local distance = (localRoot.Position - targetRoot.Position).Magnitude
                    if distance <= getgenv().ESPRange then
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
    if not getgenv().ESPEnabled then return end
    for player, esp in pairs(PlayerESPs) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local onScreen, size, pos = Visuals:GetBoundingBox(player)
            local box = esp.Box; local tracer = esp.Tracer
            local healthBarOutline = esp.HealthBarOutline; local healthBarFill = esp.HealthBarFill; local healthBarTicks = esp.HealthBarTicks
            if onScreen then
                local teamColor = player.TeamColor and player.TeamColor.Color or Color3.new(1,1,1)
                if box then
                    box.Size = size; box.Position = pos; box.Color = teamColor; box.Visible = getgenv().BoxEnabled
                end
                if tracer then
                    local viewport = workspace.CurrentCamera.ViewportSize
                    tracer.From = Vector2.new(viewport.X/2, viewport.Y)
                    tracer.To = Vector2.new(pos.X + (size.X/2), pos.Y + size.Y)
                    tracer.Color = teamColor; tracer.Visible = getgenv().TracerEnabled
                end
                if healthBarOutline and healthBarFill then
                    local humanoid = player.Character.Humanoid
                    local healthPercent = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth,1), 0, 1)
                    local barHeight = size.Y; local barX = pos.X - 8; local barY = pos.Y
                    healthBarOutline.Position = Vector2.new(barX - 1, barY - 2)
                    healthBarOutline.Size = Vector2.new(5, barHeight + 4)
                    healthBarOutline.Visible = getgenv().HealthBarEnabled
                    healthBarFill.Position = Vector2.new(barX, barY + barHeight * (1 - healthPercent))
                    healthBarFill.Size = Vector2.new(3, math.max(barHeight * healthPercent, 1))
                    healthBarFill.Color = Color3.fromHSV(healthPercent * 0.33, 0.9, 1)
                    healthBarFill.Visible = getgenv().HealthBarEnabled
                    if healthBarTicks then
                        for index, tick in ipairs(healthBarTicks) do
                            local y = barY + (barHeight * index / 5)
                            tick.From = Vector2.new(barX - 1, y)
                            tick.To = Vector2.new(barX + 4, y)
                            tick.Visible = getgenv().HealthBarEnabled
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

-- UI toggles
ESPSection:CreateToggle("Normal", {
    Name = "Enable ESP",
    Callback = function(v)
        getgenv().ESPEnabled = v
        if not v then ClearESPs() end
    end,
})
ESPSection:CreateDivider()
ESPSection:CreateToggle("Normal", { Name = "Highlight", Callback = function(v) getgenv().HighlightEnabled = v; RebuildAllESPs() end })
ESPSection:CreateToggle("Normal", { Name = "Box", Callback = function(v) getgenv().BoxEnabled = v; RebuildAllESPs() end })
ESPSection:CreateToggle("Normal", { Name = "Tracer Lines", Callback = function(v) getgenv().TracerEnabled = v; RebuildAllESPs() end })
ESPSection:CreateToggle("Normal", { Name = "Health Bars", Callback = function(v) getgenv().HealthBarEnabled = v; RebuildAllESPs() end })
ESPSection:CreateToggle("Normal", { Name = "Skeleton", Callback = function(v) getgenv().SkeletonEnabled = v; RebuildAllESPs() end })
ESPSection:CreateToggle("Normal", { Name = "Chams", Callback = function(v) getgenv().ChamsEnabled = v; RebuildAllESPs() end })
ESPSection:CreateSlider({
    Name = "ESP Range",
    Value = {50, 2000}, Increment = 50, Suffix = "studs",
    CurrentValue = getgenv().ESPRange,
    Callback = function(v) getgenv().ESPRange = v; RebuildAllESPs() end
})

UI:Notify("Normal", {
    Title = "Visuals Only Test",
    Content = "ESP loaded. Test first‑person camera.",
    Duration = 5
})