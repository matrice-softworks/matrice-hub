if not game:IsLoaded() then
    game.Loaded:Wait()
end

if getgenv().Matrice and getgenv().Matrice.IsLoaded then
    warn("Matrice is already running!")
    return
end

local Players = game:GetService("Players")
repeat
    task.wait()
until Players.LocalPlayer

getgenv().Matrice = {
    Source = "https://raw.githubusercontent.com/matrice-softworks/matrice-hub/main/",
    UI = nil,
    Visuals = nil,
    IsLoaded = false,
    Version = nil,
    Game = nil,
    GameId = tostring(game.GameId),
}

local Matrice = getgenv().Matrice

function Matrice.Create(Path)
    local Current = ""
    for Segment in string.gmatch(Path, "[^/]+") do
        Current = Current == "" and Segment or Current .. "/" .. Segment
        if not isfolder(Current) then
            local Success, Error = pcall(function()
                makefolder(Current)
            end)
            if not Success then
                return false, "Failed creating folder " .. Current .. ": " .. tostring(Error)
            end
        end
    end
    return true
end

function Matrice.Get(Path)
    local Success, Response = pcall(function()
        return game:HttpGet(Matrice.Source .. Path)
    end)
    if not Success or not Response then
        return nil, "Failed to download " .. Path .. ": " .. tostring(Response)
    end
    return Response
end

function Matrice.Download(Path)
    local Content, Error = Matrice.Get(Path)
    if not Content then
        return false, Error
    end

    local CachePath = "Matrice/Cache/" .. Path
    local Folder = string.match(CachePath, "(.+)/[^/]+$")
    if Folder then
        local Success, FolderError = Matrice.Create(Folder)
        if not Success then
            return false, FolderError
        end
    end

    if isfile(CachePath) then
        local ReadSuccess, OldContent = pcall(readfile, CachePath)
        if ReadSuccess and OldContent == Content then
            return true, Content
        end
    end

    local WriteSuccess, WriteError = pcall(function()
        writefile(CachePath, Content)
    end)
    if not WriteSuccess then
        return false, "Failed caching " .. Path .. ": " .. tostring(WriteError)
    end

    return true, Content
end

-- Download asset to Matrice/Assets/
function Matrice.DownloadAsset(Path)
    local Content, Error = Matrice.Get(Path)
    if not Content then
        return false, Error
    end

    local AssetPath = "Matrice/Assets/" .. Path
    local Folder = string.match(AssetPath, "(.+)/[^/]+$")
    if Folder then
        local Success, FolderError = Matrice.Create(Folder)
        if not Success then
            return false, FolderError
        end
    end

    if isfile(AssetPath) then
        local ReadSuccess, OldContent = pcall(readfile, AssetPath)
        if ReadSuccess and OldContent == Content then
            return true, Content
        end
    end

    local WriteSuccess, WriteError = pcall(function()
        writefile(AssetPath, Content)
    end)
    if not WriteSuccess then
        return false, "Failed caching asset " .. Path .. ": " .. tostring(WriteError)
    end

    return true, Content
end

-- Fetch GitHub tree and download all files under Assets/
function Matrice.DownloadAssets()
    local success, treeData = pcall(function()
        local response = game:HttpGet("https://api.github.com/repos/matrice-softworks/matrice-hub/git/trees/main?recursive=1")
        return game:GetService("HttpService"):JSONDecode(response)
    end)

    if not success or not treeData or not treeData.tree then
        warn("Failed to fetch repository tree for assets")
        return
    end

    for _, item in ipairs(treeData.tree) do
        if item.type == "blob" and string.sub(item.path, 1, 7) == "Assets/" then
            local assetPath = string.sub(item.path, 8) -- remove "Assets/"
            if assetPath ~= "" then
                local success, err = Matrice.DownloadAsset(assetPath)
                if not success then
                    warn("Failed to download asset:", assetPath, err)
                end
            end
        end
    end
end

function Matrice.Load(Path)
    local Success, Content = Matrice.Download(Path)
    if not Success then
        return false, Content
    end

    local Chunk, CompileError = loadstring(Content, Path)
    if not Chunk then
        return false, CompileError
    end

    local RunSuccess, Result = pcall(Chunk)
    if not RunSuccess then
        return false, Result
    end

    return true, Result
end

function Matrice.Asset(Name)
    local AssetPath = "Matrice/Assets/" .. Name .. ".png"
    if isfile(AssetPath) then
        return getcustomasset(AssetPath)
    end
    return "rbxassetid://12974454446"
end

-- ==== Configuration Helpers ====
function Matrice.SaveConfiguration(Config, FilePath)
    local Success, Error = Matrice.Create("Matrice")
    if not Success then
        return false, "Failed to create Matrice folder: " .. tostring(Error)
    end

    local json = game:GetService("HttpService"):JSONEncode(Config)
    local WriteSuccess, WriteError = pcall(function()
        writefile("Matrice/" .. FilePath, json)
    end)

    if not WriteSuccess then
        return false, "Failed to write config: " .. tostring(WriteError)
    end

    return true
end

function Matrice.LoadConfiguration(FilePath)
    local Path = "Matrice/" .. FilePath
    if not isfile(Path) then
        return nil, "Config file not found"
    end

    local ReadSuccess, Content = pcall(readfile, Path)
    if not ReadSuccess then
        return nil, "Failed to read config: " .. tostring(Content)
    end

    local DecodeSuccess, Data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(Content)
    end)

    if not DecodeSuccess then
        return nil, "Failed to parse config: " .. tostring(Data)
    end

    return Data
end

function Matrice.ResetConfiguration(FilePath)
    local Path = "Matrice/" .. FilePath
    if not isfile(Path) then
        return true, "File already removed"
    end

    local DeleteSuccess, DeleteError = pcall(delfile, Path)
    if not DeleteSuccess then
        return false, "Failed to delete config: " .. tostring(DeleteError)
    end

    return true
end
-- ==== End Configuration Helpers ====

function Matrice.GetLocalVersion()
    if not isfile("Matrice/Versions.luau") then
        return nil
    end

    local Success, Result = pcall(function()
        return loadstring(readfile("Matrice/Versions.luau"), "Versions.luau")()
    end)

    if Success then
        return Result
    end

    warn("Failed to load local version:", Result)
    return nil
end

function Matrice.SaveVersion(Content)
    local Success, Error = Matrice.Create("Matrice")
    if not Success then
        warn("Failed creating Matrice folder:", Error)
        return false
    end

    local WriteSuccess, WriteError = pcall(function()
        writefile("Matrice/Versions.luau", Content)
    end)

    if not WriteSuccess then
        warn("Failed saving version:", WriteError)
        return false
    end

    return true
end

function Matrice.DeleteFolder(Path)
    if not isfolder(Path) then
        return
    end

    for _, Item in ipairs(listfiles(Path)) do
        if isfolder(Item) then
            Matrice.DeleteFolder(Item)
            pcall(function()
                delfolder(Item)
            end)
        else
            pcall(function()
                delfile(Item)
            end)
        end
    end
end

function Matrice.ClearCache()
    if isfolder("Matrice/Cache") then
        Matrice.DeleteFolder("Matrice/Cache")
    end

    Matrice.Create("Matrice/Cache")
end

function Matrice.Update(RemoteVersion, RemoteContent)
    local LocalVersion = Matrice.GetLocalVersion()

    if LocalVersion
        and LocalVersion.Matrice
        and LocalVersion.Matrice.Version == RemoteVersion.Matrice.Version
    then
        return false
    end

    if LocalVersion then
        warn(
            "Matrice update:",
            LocalVersion.Matrice.Version,
            "->",
            RemoteVersion.Matrice.Version
        )
    else
        warn("First Matrice installation")
    end

    Matrice.ClearCache()
    Matrice.DownloadAssets() -- download assets on update

    if RemoteContent then
        Matrice.SaveVersion(RemoteContent)
    end

    return true
end

function Matrice.GetGame(Manifest)
    local Game = Manifest.Games and Manifest.Games[Matrice.GameId]

    if not Game then
        warn("This game is not supported by Matrice.")
        return nil
    end

    if Game.Info.Enabled == false then
        warn(Game.Info.Name .. " is disabled.")
        return nil
    end

    Game.Id = Matrice.GameId
    return Game
end

local RemoteContent, Error = Matrice.Get("Versions.luau")
if not RemoteContent then
    warn("Failed to fetch remote version:", Error)
    local Cached = Matrice.GetLocalVersion()
    if not Cached then
        return
    end
    Matrice.Version = Cached.Matrice.Version
    Matrice.Game = Matrice.GetGame(Cached)
    if not Matrice.Game then
        return
    end
else
    local Chunk, CompileError = loadstring(RemoteContent, "Versions.luau")
    if not Chunk then
        warn("Failed to compile remote version:", CompileError)
        local Cached = Matrice.GetLocalVersion()
        if not Cached then
            return
        end
        Matrice.Version = Cached.Matrice.Version
        Matrice.Game = Matrice.GetGame(Cached)
        if not Matrice.Game then
            return
        end
    else
        local Success, RemoteVersion = pcall(Chunk)
        if not Success then
            warn("Failed to execute remote version:", RemoteVersion)
            local Cached = Matrice.GetLocalVersion()
            if not Cached then
                return
            end
            Matrice.Version = Cached.Matrice.Version
            Matrice.Game = Matrice.GetGame(Cached)
            if not Matrice.Game then
                return
            end
        else
            Matrice.Game = Matrice.GetGame(RemoteVersion)
            if not Matrice.Game then
                return
            end

            Matrice.Update(RemoteVersion, RemoteContent)
            Matrice.Version = RemoteVersion.Matrice.Version
        end
    end
end

-- Ensure assets are downloaded if they are missing (e.g., on first run without version change)
if not isfile("Matrice/Assets/matrice.png") then
    Matrice.DownloadAssets()
end

local Success, UI = Matrice.Load("Libraries/AuraIS/Main.luau")
if not Success then
    warn("Failed to load UI:", UI)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Matrice Error",
            Text = "Failed to load UI library",
            Duration = 5,
        })
    end)
    return
end
Matrice.UI = UI

local Success, Visuals = Matrice.Load("Libraries/VisualLibrary/Main.luau")
if Success then
    Matrice.Visuals = Visuals
else
    warn("Visuals library failed to load:", Visuals)
end

Matrice.UI:Notify("Normal", {
    Title = "Matrice v" .. Matrice.Version,
    Content = "Loading " .. Matrice.Game.Info.Name .. "...",
    Duration = 3,
    Image = Matrice.Asset("matrice"),
})

local Success, ScriptError = Matrice.Load(Matrice.Game.Script)
if not Success then
    Matrice.UI:Notify("Error", {
        Title = "Load Failed",
        Content = "Failed to load " .. Matrice.Game.Info.Name .. ": " .. tostring(ScriptError),
        Duration = 5,
        Image = Matrice.Asset("matrice"),
    })
    return
end

Matrice.IsLoaded = true

Matrice.UI:Notify("Normal", {
    Title = "Matrice v" .. Matrice.Version .. " Loaded",
    Content = "Successfully loaded " .. Matrice.Game.Info.Name,
    Duration = 3,
    Image = Matrice.Asset("matrice"),
})