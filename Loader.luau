if not game:IsLoaded() then
    game.Loaded:Wait()
end

if getgenv().Matrice and (getgenv().Matrice.IsLoaded or getgenv().Matrice.IsUpdating) then
    warn("Matrice is already running!")
    return
end

local Branch = ... or "main"

getgenv().Matrice = {
    Source = "https://raw.githubusercontent.com/matrice-softworks/matrice-hub/" .. Branch .. "/",

    UI = nil,
    Visuals = nil,

    PlaceId = tostring(game.PlaceId),

    IsLoaded = false,
    IsUpdating = false,
}

local Matrice = getgenv().Matrice

local HttpService = game:GetService("HttpService")

function Matrice.Get(Path)
    return game:HttpGet(Matrice.Source .. Path)
end

function Matrice.Load(Path)
    local CachePath = "Matrice/Cache/" .. Path
    local Content

    if isfile(CachePath) then
        Content = readfile(CachePath)
    else
        Content = Matrice.Get(Path)

        local Folder = CachePath:match("(.+)/[^/]+$")
        if Folder then
            pcall(makefolder, Folder)
        end

        pcall(writefile, CachePath, Content)
    end

    local Chunk, Error = loadstring(Content, Path)

    if not Chunk then
        error(Error)
    end

    return Chunk()
end

function Matrice.Download(Path)
    local Content = Matrice.Get(Path)

    local CachePath = "Matrice/Cache/" .. Path

    local Folder = CachePath:match("(.+)/[^/]+$")

    if Folder then
        pcall(makefolder, Folder)
    end

    pcall(writefile, CachePath, Content)

    return Content
end

function Matrice.Asset(Name)
    local Path = "Matrice/Assets/" .. Name

    if isfile(Path) then
        return getcustomasset(Path)
    end

    return "rbxassetid://12974454446"
end

function Matrice.Version()
    if not isfile("Matrice/Versions.json") then
        return nil
    end

    local Success, Content = pcall(
        readfile,
        "Matrice/Versions.json"
    )

    if not Success or not Content then
        return nil
    end

    local Decode, Data = pcall(
        HttpService.JSONDecode,
        HttpService,
        Content
    )

    if Decode then
        return Data
    end

    return nil
end

function Matrice.Game()
    local Version = Matrice.Version()

    if not Version or not Version.Games then
        return nil
    end

    local Game = Version.Games[Matrice.PlaceId]

    if Game and Game.Info and Game.Info.Enabled ~= false then
        if Game.Info.Publish then
            if tostring(game.PlaceVersion) ~= tostring(Game.Info.Publish) then
                return nil
            end
        end
        return Game
    end

    return nil
end

function Matrice.Update()
    if Matrice.IsUpdating then
        return false, "Update already running"
    end

    Matrice.IsUpdating = true

    local TreeUrl =
        "https://api.github.com/repos/matrice-softworks/matrice-hub/git/trees/"
        .. Branch
        .. "?recursive=1"

    local TreeSuccess, TreeContent = pcall(
        game.HttpGet,
        game,
        TreeUrl
    )

    if not TreeSuccess then
        Matrice.IsUpdating = false
        return false, "Failed to fetch GitHub tree (network error)"
    end

    local DecodeSuccess, Tree = pcall(
        HttpService.JSONDecode,
        HttpService,
        TreeContent
    )

    if not DecodeSuccess then
        Matrice.IsUpdating = false
        return false, "Invalid JSON from GitHub API"
    end

    if Tree.message then
        Matrice.IsUpdating = false
        return false, "GitHub API error: " .. Tree.message
    end

    if not Tree.tree then
        Matrice.IsUpdating = false
        return false, "Missing 'tree' field in API response"
    end

    local SHAInfo = {
        Branch = Branch,
        Files = {}
    }

    if isfile("Matrice/CacheInfo.json") then
        local Success, Content = pcall(
            readfile,
            "Matrice/CacheInfo.json"
        )

        if Success then
            local Decode, Data = pcall(
                HttpService.JSONDecode,
                HttpService,
                Content
            )

            if Decode
                and Data.Branch == Branch
                and Data.Files then

                SHAInfo = Data
            end
        end
    end

    local RemoteFiles = {}

    for _, File in ipairs(Tree.tree) do
        if File.type == "blob" then
            RemoteFiles[File.path] = true
        end
    end

    for Path,_ in pairs(SHAInfo.Files) do
        if not RemoteFiles[Path] then
            local DeletePath =
                "Matrice/Cache/" .. Path

            if isfile(DeletePath) then
                pcall(delfile, DeletePath)
            end

            SHAInfo.Files[Path] = nil
        end
    end

    local Changed = {}

    for _, File in ipairs(Tree.tree) do
        if File.type == "blob" then
            local OldSHA =
                SHAInfo.Files[File.path]

            if not OldSHA
                or OldSHA ~= File.sha then

                table.insert(
                    Changed,
                    File
                )
            end
        end
    end

    local Downloaded = 0
    local Failed = {}

    for _, File in ipairs(Changed) do
        local Success = pcall(function()
            local Content =
                game:HttpGet(
                    Matrice.Source .. File.path
                )

            local CachePath =
                "Matrice/Cache/" .. File.path

            local Folder =
                CachePath:match("(.+)/[^/]+$")

            if Folder then
                pcall(makefolder, Folder)
            end

            writefile(
                CachePath,
                Content
            )

            if File.path:match("^Assets/") then
                local AssetName =
                    File.path:match("^Assets/(.+)$")

                if AssetName then
                    local AssetPath =
                        "Matrice/Assets/" .. AssetName

                    local AssetFolder =
                        AssetPath:match("(.+)/[^/]+$")

                    if AssetFolder then
                        pcall(
                            makefolder,
                            AssetFolder
                        )
                    end

                    pcall(
                        writefile,
                        AssetPath,
                        Content
                    )
                end
            end

            SHAInfo.Files[File.path] =
                File.sha

            Downloaded += 1
        end)

        if not Success then
            table.insert(
                Failed,
                File.path
            )
        end
    end

    pcall(
        makefolder,
        "Matrice"
    )

    pcall(
        writefile,
        "Matrice/CacheInfo.json",
        HttpService:JSONEncode(SHAInfo)
    )

    local RemoteVersion

    local VersionSuccess, VersionContent =
        pcall(
            game.HttpGet,
            game,
            Matrice.Source .. "Versions.json"
        )

    if VersionSuccess and VersionContent then
        local Decode, Data =
            pcall(
                HttpService.JSONDecode,
                HttpService,
                VersionContent
            )

        if Decode then
            RemoteVersion = Data

            pcall(
                writefile,
                "Matrice/Versions.json",
                HttpService:JSONEncode(Data)
            )
        end
    end

    Matrice.IsUpdating = false

    if #Failed > 0 then
        return false,
            "Failed files: "
            .. table.concat(
                Failed,
                ", "
            )
    end

    return true,
        "Updated "
        .. tostring(Downloaded)
        .. " files"
end

local Updated, UpdateMessage =
    Matrice.Update()

warn(
    "Matrice:",
    UpdateMessage
)

local Version =
    Matrice.Version()

if not Version then
    pcall(function()
        game:GetService("StarterGui")
            :SetCore(
                "SendNotification",
                {
                    Title = "Matrice",
                    Text = "Missing Versions.json",
                    Duration = 5
                }
            )
    end)

    return
end

local Game =
    Matrice.Game()

if not Game then
    pcall(function()
        game:GetService("StarterGui")
            :SetCore(
                "SendNotification",
                {
                    Title = "Matrice",
                    Text = "This game is not supported by Matrice.",
                    Duration = 5
                }
            )
    end)

    return
end

Matrice.Game = Game

pcall(function()
    Matrice.UI =
        Matrice.Load(
            "Libraries/AuraIS/Main.luau"
        )
end)

if not Matrice.UI then
    pcall(function()
        game:GetService("StarterGui")
            :SetCore(
                "SendNotification",
                {
                    Title = "Matrice Error",
                    Text = "User interface failed to load!",
                    Duration = 5
                }
            )
    end)

    return
end

pcall(function()
    Matrice.Visuals =
        Matrice.Load(
            "Libraries/VisualLibrary/Main.luau"
        )
end)

local Loaded, Error =
    pcall(function()
        Matrice.Load(
            Game.Script
        )
    end)

if not Loaded then
    Matrice.UI:Notify(
        "Error",
        {
            Title = "Load Failed",
            Content =
                "Failed to load "
                .. Game.Info.Name
                .. ": "
                .. tostring(Error),
            Duration = 5,
            Image =
                Matrice.Asset(
                    "matrice.png"
                )
        }
    )

    return
end

Matrice.IsLoaded = true

Matrice.UI:Notify(
    "Normal",
    {
        Title =
            "Matrice v"
            .. Version.Matrice.Version
            .. " Loaded",
        Content =
            "Successfully loaded "
            .. Game.Info.Name,
        Duration = 5,
        Image =
            Matrice.Asset(
                "matrice.png"
            )
    }
)