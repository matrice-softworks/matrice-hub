--[[
    Weapon Ammo Spoofer (Adapted from WalkSpeed Spoof)
    Automatically detects weapons with Ammo / CurrentAmmo properties.
]]

local cloneref = cloneref or function(...) return ... end

-- Configuration
local SPOOFED_AMMO = 999  -- Change this to whatever number you want

local Players = cloneref(game:GetService("Players"))
if not Players.LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end
local lp = cloneref(Players.LocalPlayer)

-- Cache to store original values and detect weapons
local weaponCache = {}

-- Helper to check if an instance is a weapon (has ammo properties)
local function isWeapon(instance)
    if not instance or not instance:IsA("Tool") then
        return false
    end
    -- Check if it has the custom properties you mentioned
    local hasAmmo = instance:FindFirstChild("Ammo") ~= nil or instance:IsA("NumberValue")
    local hasCurrentAmmo = instance:FindFirstChild("CurrentAmmo") ~= nil or instance:IsA("NumberValue")
    -- We also check if it has _Mag and Identifier as you specified
    local hasMag = instance:FindFirstChild("_Mag") ~= nil
    local hasIdentifier = instance:FindFirstChild("Identifier") ~= nil
    
    return hasAmmo or hasCurrentAmmo or hasMag or hasIdentifier
end

-- The actual spoofing hooks
local old_index = hookmetamethod(game, "__index", function(self, index)
    -- Check if we are allowed to spoof this
    if not checkcaller() and typeof(self) == "Instance" then
        -- Only target weapons (Tools)
        if self:IsA("Tool") or self:IsA("NumberValue") then
            -- If it's a NumberValue, we actually want to spoof its .Value property
            if self:IsA("NumberValue") and index == "Value" then
                local parent = self.Parent
                if parent and isWeapon(parent) then
                    return SPOOFED_AMMO -- Return infinite ammo
                end
            end

            -- If the tool itself has Ammo or CurrentAmmo as direct properties
            if self:IsA("Tool") and (index == "Ammo" or index == "CurrentAmmo") then
                -- Check if the tool is in the player's possession
                if self:IsDescendantOf(lp.Character) or self:IsDescendantOf(lp.Backpack) then
                    return SPOOFED_AMMO
                end
            end
        end
    end
    return old_index(self, index)
end)

local old_newindex = hookmetamethod(game, "__newindex", function(self, index, newvalue)
    -- Block the game from resetting our ammo
    if not checkcaller() and typeof(self) == "Instance" then
        if self:IsA("Tool") or self:IsA("NumberValue") then
            if self:IsA("NumberValue") and index == "Value" then
                local parent = self.Parent
                if parent and isWeapon(parent) then
                    return -- Silently block the game from changing it back
                end
            end

            if self:IsA("Tool") and (index == "Ammo" or index == "CurrentAmmo") then
                if self:IsDescendantOf(lp.Character) or self:IsDescendantOf(lp.Backpack) then
                    return -- Block the write
                end
            end
        end
    end
    return old_newindex(self, index, newvalue)
end)

-- Auto-Detect Function (Scans current weapons and new ones)
local function scanForWeapons()
    -- Check Backpack
    for _, tool in ipairs(lp.Backpack:GetChildren()) do
        if isWeapon(tool) then
            -- Force a "read" of the ammo to trigger our hook and cache it
            local _ = tool.Ammo
            local _ = tool.CurrentAmmo
        end
    end
    -- Check Character
    local char = lp.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if isWeapon(tool) then
                local _ = tool.Ammo
                local _ = tool.CurrentAmmo
            end
        end
    end
end

-- Scan immediately
scanForWeapons()

-- Scan every time you equip a new tool
lp.Backpack.ChildAdded:Connect(function(child)
    task.wait(0.1) -- Wait for the tool to fully replicate
    if isWeapon(child) then
        -- Force spoof
        child.Ammo = SPOOFED_AMMO
        child.CurrentAmmo = SPOOFED_AMMO
    end
end)

-- Scan when your character respawns
lp.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        task.wait(0.1)
        if isWeapon(child) then
            child.Ammo = SPOOFED_AMMO
            child.CurrentAmmo = SPOOFED_AMMO
        end
    end)
    scanForWeapons()
end)

print("Weapon Ammo Spoofer Loaded! All weapons will show " .. SPOOFED_AMMO .. " ammo.")