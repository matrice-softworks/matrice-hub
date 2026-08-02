mporting
Place the script in your game’s ServerScriptService or ReplicatedStorage (if using modules).
Require it wherever you need to build UI:

lua
local AuraIS = require(path.to.AuraIS)
If you’re using it directly as a script, the library returns a table with all the methods.

Note: All audio and image assets are now served directly from Roblox using rbxassetid:// – no external downloads are required.

Creating Library
CreateLibrary
Creates the main UI window and returns a library object with methods to manage tabs, notifications, and advertisements.

lua
local Library = AuraIS:CreateLibrary(
    Name,      -- string or table: window title (or table with Name and Icon)
    Icon       -- string (optional): asset ID for the window icon
)
Example:

lua
local Library = AuraIS:CreateLibrary({
    Name = "My Awesome Script",
    Icon = "rbxassetid://11432865001"
})
Returns: A table with the following methods:

CreateTab(Title, Icon?) – creates a new tab.

Notify(y, N, O, P?) – displays a window notification.

CreateAdvertisement(Name, Image, Link, NotificationText?) – adds a rotating ad.

SwitchTab(TabName?) – switches to a tab by name (or to the first tab).

CreateTab
Adds a new tab to the sidebar and a corresponding page in the main container.

lua
local Tab = Library:CreateTab(
    Title,      -- string or table: tab title (or table with Title and Icon)
    Icon        -- string (optional): asset ID for the tab icon
)
Example:

lua
local MainTab = Library:CreateTab("Main", "rbxassetid://11432859220")
local SettingsTab = Library:CreateTab("Settings")
Returns: A tab object with the following method:

CreateSection(Title, Type) – creates a section inside this tab.

CreateSection
Organises UI elements into collapsible (foldable) or normal sections.

lua
local Section = Tab:CreateSection(
    Title,      -- string: section title
    Type        -- string: "Normal" or "Foldable"
)
Example:

lua
local General = MainTab:CreateSection("General", "Normal")
local Advanced = MainTab:CreateSection("Advanced", "Foldable")
Returns: A section object with methods to create all UI elements.

Creating Elements
Button
Creates a clickable button with error handling and animation.

lua
local Button = Section:CreateButton({
    Name = "Button Name",
    Callback = function()
        -- your code
    end
})
Methods:

SetCallback(newCallback) – updates the button’s action.

SetName(newName) – changes the button label.

Remove() – removes the button from the UI.

Example:

lua
local myButton = Section:CreateButton({
    Name = "Click Me",
    Callback = function()
        Library:Notify("Hello", "You clicked the button!", 3)
    end
})

-- Later, change its behaviour:
myButton:SetCallback(function()
    print("New action!")
end)
Toggle
Switch‑style toggles with two modes: “Normal” (slide) and “Radio” (indicator dot). Both support persistent Flags.

lua
local Toggle = Section:CreateToggle(Type, {
    Name = "Toggle Label",
    CurrentValue = false,       -- initial state (default false)
    Flag = "MyFeature",         -- optional, for configuration saving
    Callback = function(Value) end
})
Types:

"Normal" – standard slide toggle.

"Radio" – round indicator toggle (transparent when off, filled when on).

Methods:

SetToggle(value) – programmatically set the state (triggers callback and saves).

Example:

lua
local autoSave = Section:CreateToggle("Normal", {
    Name = "Auto‑Save",
    Flag = "AutoSave",
    Callback = function(v)
        print("Auto‑save is now " .. (v and "ON" or "OFF"))
    end
})
Keybind
Allows users to set a keyboard key for an action, with “Press” or “Hold” behaviour.
Persists via Configuration.Keybinds using a Flag.

lua
local Keybind = Section:CreateKeybind({
    Name = "Keybind Label",
    Flag = "MyKeybind",          -- optional, for configuration saving
    Keybind = "F",               -- default key (optional)
    Type = "Press",              -- "Press" or "Hold"
    Callback = function(Active) end
})
Types:

"Press" – toggles the state on each key press.

"Hold" – active while the key is held down.

Methods:

Set(newKey) – programmatically change the bound key.

Example:

lua
local speedBoost = Section:CreateKeybind({
    Name = "Speed Boost",
    Flag = "BoostKey",
    Keybind = "F",
    Type = "Hold",
    Callback = function(active)
        Player.Character.Humanoid.WalkSpeed = active and 50 or 16
    end
})
Textbox
Single‑line input field with placeholder and optional Flag persistence.
Saves to Configuration.Inputs.

lua
local Textbox = Section:CreateTextbox({
    Name = "Input Label",
    PlaceholderText = "Type here...",
    RemoveTextAfterFocusLost = true,  -- clear after input (optional)
    Flag = "MyInput",                 -- optional, saves to Configuration.Inputs
    Callback = function(Text) end
})
Methods:

Set(newText) – programmatically set the text; also updates the saved config if a Flag is provided.

Example:

lua
local usernameBox = Section:CreateTextbox({
    Name = "Username",
    PlaceholderText = "Enter your username",
    Flag = "Username",
    Callback = function(text)
        print("Username set to: " .. text)
    end
})
Slider
Draggable slider with a numeric value, step increment, and optional suffix.
Persists via Configuration.Sliders.

lua
local Slider = Section:CreateSlider({
    Name = "Slider Label",
    Value = {0, 100},            -- {min, max}
    Increment = 5,               -- step size
    Suffix = "%",                -- optional unit displayed after value
    CurrentValue = 50,           -- initial value
    Flag = "MySlider",           -- optional, saves to Configuration.Sliders
    Callback = function(Value) end
})
Methods:

Set(newValue) – programmatically set the slider value.

Example:

lua
local volume = Section:CreateSlider({
    Name = "Volume",
    Value = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 75,
    Flag = "Volume",
    Callback = function(v)
        game:GetService("SoundService").Volume = v / 100
    end
})
Dropdown
Select one or multiple options from a list. Supports single‑ and multi‑select.
Persists via Configuration.Dropdowns.

lua
local Dropdown = Section:CreateDropdown({
    Name = "Dropdown Label",
    Options = {"Option1", "Option2", "Option3"},
    CurrentOption = "Option1",       -- initial selection (or table for multi)
    MultipleOptions = false,         -- set true for multi‑select
    Flag = "MyDropdown",             -- optional, saves to Configuration.Dropdowns
    Callback = function(Selected) end
})
Methods:

Set(newSelection) – programmatically set the selected option(s).

Example:

lua
local food = Section:CreateDropdown({
    Name = "Favourite Food",
    Options = {"Pizza", "Sushi", "Tacos", "Burger"},
    CurrentOption = "Pizza",
    Flag = "FavoriteFood",
    Callback = function(choice)
        print("You chose: " .. tostring(choice))
    end
})
Color Picker
Interactive colour selector with hue/saturation picker, brightness slider, and rainbow toggle.

lua
local ColorPicker = Section:CreateColorPicker({
    Name = "Color Picker Label",
    Callback = function(newColor) end
})
Features:

Click and drag on the colour field to pick hue/saturation.

Drag the brightness slider (right side) to adjust lightness.

Click the rainbow switch to cycle colours automatically.

Example:

lua
local colorPicker = Section:CreateColorPicker({
    Name = "Theme Color",
    Callback = function(color)
        script.Parent.BackgroundColor3 = color
    end
})
Other Elements
Label
A simple text label (non‑interactive).

lua
local Label = Section:CreateLabel({
    Description = "This is a label"
})
Methods:

ChangeText(newText) – updates the label text.

Paragraph
A larger block of text with a title and content, supporting rich text.

lua
local Paragraph = Section:CreateParagraph({
    Title = "Paragraph Title",
    Description = "Supports <b>bold</b>, <i>italics</i>, etc."
})
Card
A card‑style container with a preview image, title, description, state text, and up to two action buttons.

lua
local Card = Section:CreateCard({
    Title = "Card Title",
    Description = "Card description",
    SecondaryTitle = "Status",          -- optional
    Image = "rbxassetid://14167800463", -- optional
    Buttons = {
        Button1 = {
            Name = "Action 1",
            Callback = function() end
        },
        Button2 = {
            Name = "Action 2",
            Callback = function() end
        }
    }
})
Divider
A horizontal line to visually separate sections.

lua
local Divider = Section:CreateDivider()
Notifications
AuraIS provides two notification systems: Side Notifications (toast‑style) and Window Notifications (modal).
Both support auto‑close on action – clicking any button immediately dismisses the notification.

Side Notifications
Call AuraIS:Notify(type, config).

lua
AuraIS:Notify(Type, {
    Title = "Title",
    Content = "Message",
    Duration = 5,
    Image = "rbxassetid://4483362458", -- optional
    Actions = {
        { Name = "OK", Callback = function() end },
        { Name = "Cancel", Callback = function() end }
    }
})
Types: "Normal", "Warning", "Error" (affects styling).

Window Notifications
Call Library:Notify(config).

lua
Library:Notify({
    Title = "Window Notification",
    Content = "This is a modal notification.",
    Duration = 5,
    Image = "rbxassetid://4483362458", -- optional
    Actions = {
        { Name = "Confirm", Callback = function() end },
        { Name = "Cancel",  Callback = function() end }
    }
})
Note: Both notification methods now play a sound (rbxassetid://255881176) when they appear and immediately close when any action button is clicked.

Advertisements
The library includes a built‑in advertisement frame that rotates through a list of ads. You can add ads using the CreateAdvertisement method on the library object.

lua
Library:CreateAdvertisement(
    Name,           -- string (display name, used internally)
    Image,          -- Roblox asset ID for the ad image
    Link,           -- URL to copy to clipboard
    NotificationText -- optional, shown when link is copied
)
Example:

lua
Library:CreateAdvertisement(
    "Blox Products",
    "rbxassetid://1234567890",
    "https://bloxproducts.com/?affiliate_key=roe",
    "Link copied to clipboard!"
)

Library:CreateAdvertisement(
    "JJBlox",
    "rbxassetid://0987654321",
    "https://jjblox.xyz",
    "Visit JJBlox!"
)
Ads rotate every 5 minutes automatically. If you add no ads, the advertisement frame is hidden.

Utility Methods
ToggleUI()
Toggles the entire UI visibility.

lua
AuraIS:ToggleUI()
SwitchTab(TabName?)
Switches to a specific tab by name. If no argument is given, jumps to the first created tab.

lua
Library:SwitchTab("Settings")
GetUIInstance()
Returns the root GUI instance (useful for debugging or manual manipulation).

lua
local uiRoot = AuraIS:GetUIInstance()
Configuration System
AuraIS automatically saves and loads all user settings to/from a JSON file located at:

text
[YourScriptFolder]/Configurations/UI.json
Supported elements:

Element	Config Key	Persisted Data
Toggle	Toggles	Boolean state
Slider	Sliders	Numeric value
Dropdown	Dropdowns	Selected option(s)
Keybind	Keybinds	Key name (string)
Textbox	Inputs	Entered text (string)
To enable persistence, simply provide a unique Flag string when creating the element.

Example with Textbox:

lua
local myTextbox = Section:CreateTextbox({
    Flag = "UserInput", -- this will be saved
    Callback = function(t) ... end
})
After the script runs, the configuration file will contain:

json
{
    "Toggles": { "MyFeatureToggle": true },
    "Sliders": { "SpeedValue": 75 },
    "Dropdowns": { "FavoriteFood": "Pizza" },
    "Keybinds": { "BoostKey": "F" },
    "Inputs": { "UserInput": "Hello world" }
}
Complete Example
lua
-- Import the library
local AuraIS = require(path.to.AuraIS)

-- Create the main window
local Library = AuraIS:CreateLibrary({
    Name = "My Script",
    Icon = "rbxassetid://11432865001"
})

-- Add a couple of ads
Library:CreateAdvertisement(
    "Blox Products",
    "rbxassetid://1234567890",
    "https://bloxproducts.com",
    "Ad link copied!"
)

-- Create tabs
local MainTab = Library:CreateTab("Main", "rbxassetid://11432859220")
local SettingsTab = Library:CreateTab("Settings")

-- Main tab sections
local General = MainTab:CreateSection("General", "Normal")
local About = MainTab:CreateSection("About", "Foldable")

-- Toggle
local featureToggle = General:CreateToggle("Normal", {
    Name = "Enable Feature",
    Flag = "FeatureEnabled",
    Callback = function(v)
        print("Feature is now " .. (v and "ON" or "OFF"))
    end
})

-- Slider
local speedSlider = General:CreateSlider({
    Name = "Speed",
    Value = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 50,
    Flag = "SpeedValue",
    Callback = function(v)
        print("Speed set to " .. v)
    end
})

-- Textbox with Flag
local nameBox = General:CreateTextbox({
    Name = "Your Name",
    PlaceholderText = "Enter your name",
    Flag = "UserName",
    Callback = function(text)
        print("Hello, " .. text)
    end
})

-- Button that shows a window notification
local btn = General:CreateButton({
    Name = "Show Notification",
    Callback = function()
        Library:Notify({
            Title = "Hello!",
            Content = "This is a window notification.",
            Duration = 4,
            Actions = {
                { Name = "OK", Callback = function() print("OK clicked") end }
            }
        })
    end
})

-- Side notification on script load
AuraIS:Notify("Normal", {
    Title = "Welcome",
    Content = "Script loaded successfully!",
    Duration = 3
})