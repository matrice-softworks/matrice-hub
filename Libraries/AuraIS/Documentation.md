# Aura Interface Suite (AuraIS)

> A powerful, feature-rich UI library for Roblox with persistent configuration, smooth animations, and a modern dark theme.  
> Built for performance, flexibility, and a professional user experience.

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/c075d655-f42e-4445-870d-f6579ae0c0b0)
![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/53caccd0-2d9f-47f1-bfdd-a109549ff680)
![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/1fde4956-cdd6-41c0-94ec-ab60225673ef)

---

## Table of Contents

- [Features](#features)
- [Importing](#importing)
- [Creating Library](#creating-library)
  - [Window](#create-window)
  - [Tab](#create-tab)
  - [Section](#create-sections)
- [Creating Elements](#creating-elements)
  - [Button](#button)
  - [Toggle](#toggle)
  - [Keybind](#keybind)
  - [Textbox](#textbox)
  - [Slider](#slider)
  - [Dropdown](#dropdown)
  - [Color Picker](#color-picker)
- [Other Elements](#other-elements)
  - [Text Label](#text-label)
  - [Paragraph](#paragraph)
  - [Card](#card)
  - [Divider](#divider)
- [Notifications](#notifications)
  - [Side Notifications](#side-notifications)
  - [Window Notifications](#window-notifications)
- [Utility Methods](#utility-methods)
- [Configuration System](#configuration-system)

---

## Importing

### 1. Import the module:
```lua
local AuraIS = require(path.to.AuraIS)
```

### 2. Optional: Pre-load assets
The library will automatically download required assets (sounds, images) from GitHub when needed.

---

## Creating Library

### Create Window

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/b9ec4810-8e2f-4b7a-89b6-134cc3fca0a8)

```lua
local Library = AuraIS:CreateLibrary({
    Name = "Example", -- Window title
    Icon = "rbxassetid://11432865001" -- Window icon (optional)
})
```

**Returns:** Library object with methods for creating tabs and notifications.

**Parameters:**
- `Name` (string): The title displayed on the window
- `Icon` (string, optional): Image asset ID for the window icon

---

### Create Tab

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/ee9c99c6-de39-4646-ac9c-367fa887c9aa)

```lua
local Tab = Library:CreateTab(
    "Hi", -- Title
    "rbxassetid://11432859220" -- Icon (optional)
)
```

**Returns:** Tab object with methods for creating sections.

**Parameters:**
- `Title` (string): The name displayed on the tab
- `Icon` (string, optional): Image asset ID for the tab icon

> **Note:** The first tab created will automatically be selected.

---

### Create Sections

#### Normal Section:

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/1d58fd6e-dcaa-4a17-bf80-b13614483522)

```lua
local Section = Tab:CreateSection(
    "Section 1", -- Section title
    "Normal" -- Section type: "Normal" or "Foldable"
)
```

#### Foldable Section:

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/f273bb51-ce58-4052-88d1-5a437aea2aef)

```lua
local FoldableSection = Tab:CreateSection(
    "Section 2", -- Section title
    "Foldable" -- Click to collapse/expand
)
```

**Returns:** Section object with methods for creating UI elements.

**Parameters:**
- `Title` (string): The section title
- `Type` (string): "Normal" or "Foldable" - Foldable sections can be collapsed

---

## Creating Elements

### Button

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/a52452ff-4eb6-4959-a336-5caaf0b4668a)

```lua
local Button = Section:CreateButton({
    Name = "Button Example",
    Callback = function()
        print("Button clicked!")
    end,
})
```

**Methods:**
```lua
-- Update button text dynamically
Button:SetName("New Button Name")

-- Update callback function
Button:SetCallback(function()
    print("New callback!")
end)

-- Remove button from UI
Button:Remove()
```

**Features:**
- Error handling - Button turns red if callback errors
- Success animation on click
- Dynamic name and callback updates
- Clean removal from UI
- Click sound feedback

---

### Toggle

#### Switch Toggle

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/28959316-2284-42e1-92fa-ec63c39e0782)

```lua
local Toggle = Section:CreateToggle("Normal", {
    Name = "Toggle Example",
    CurrentValue = false, -- Initial state
    Flag = "ToggleExample", -- Unique identifier for config saving
    Callback = function(Value)
        print("Toggle is now: " .. tostring(Value))
    end,
})
```

**Methods:**
```lua
-- Programmatically set toggle state
Toggle:SetToggle(true)
```

#### Radio Toggle

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/d7c0f1a9-9aa5-4969-bca4-d720ed60a585)

```lua
local RadioToggle = Section:CreateToggle("Radio", {
    Name = "Radio Toggle Example",
    CurrentValue = false,
    Flag = "RadioExample",
    Callback = function(Value)
        print("Radio value: " .. tostring(Value))
    end,
})
```

**Methods:**
```lua
RadioToggle:SetToggle(true)
```

**Features:**
- Auto-saves state using Flag
- Smooth toggle animations
- Hover effects with size and color changes
- Error handling with visual feedback
- Callback wrapped in `task.spawn` to prevent UI blocking
- Click sound feedback

---

### Keybind

Create customizable keybind controls for your scripts.

```lua
local Keybind = Section:CreateKeybind({
    Name = "Keybind Example",
    Flag = "MyKeybind", -- Unique identifier for config saving
    Keybind = "F", -- Default key (optional)
    Type = "Press", -- "Press" or "Hold"
    Callback = function(Active)
        print("Keybind state: " .. tostring(Active))
    end,
})
```

**Methods:**
```lua
-- Programmatically set keybind
Keybind:Set("G")
```

**Types:**
- **Press:** Toggles on each key press
- **Hold:** Active while key is held down

**Features:**
- Click to rebind (shows "..." while waiting for input)
- Auto-saves to configuration
- Visual feedback for key selection
- Click sound on the keybind box

---

### Textbox

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/ecc9407c-138e-4e2c-921e-a9c2b4227e9a)

```lua
local Textbox = Section:CreateTextbox({
    Name = "Input Example",
    PlaceholderText = "Enter text here...",
    RemoveTextAfterFocusLost = true, -- Clear after input
    Flag = "MyInput", -- Optional: saves to Configuration.Inputs
    Callback = function(Text)
        print("User entered: " .. Text)
    end,
})
```

**Methods:**
```lua
-- Programmatically set text
Textbox:Set("New text")
-- Also updates the saved configuration if Flag is provided.
```

**Features:**
- Auto-resizing input box
- Placeholder text support
- Optional text clearing after input
- **Flag support** – saves to `Configuration.Inputs` for persistence
- Click sound feedback (on interaction)

---

### Slider

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/5e074ca0-0600-4192-b926-66914c46a625)

```lua
local Slider = Section:CreateSlider({
    Name = "Slider Example",
    Value = {0, 100}, -- {Min, Max}
    Increment = 10, -- Step size
    Suffix = "Dragons", -- Displayed after value
    CurrentValue = 10, -- Initial value
    Flag = "Slider1", -- Unique identifier for config saving
    Callback = function(Value)
        print("Slider value: " .. Value)
    end,
})
```

**Methods:**
```lua
-- Programmatically set value
Slider:Set(50)
```

**Features:**
- Smooth drag interaction
- Display suffix (e.g., "%", "ms", "Dragons")
- Auto-saves using Flag
- Visual progress bar with theme colour
- Click sound on drag start

---

### Dropdown

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/699ef030-f26f-48bd-b9ea-c07fb4839674)

```lua
local Dropdown = Section:CreateDropdown({
    Name = "Dropdown Example",
    Options = {"Cake", "Pie", "Milkshake", "Cupcake"},
    CurrentOption = "Cake", -- Initial selection (or table for multi)
    MultipleOptions = false, -- true for multi-select
    Flag = "Dropdown1", -- Unique identifier for config saving
    Callback = function(Value)
        print("Selected: " .. tostring(Value))
    end,
})
```

**Methods:**
```lua
-- Programmatically set selection
Dropdown:Set("Cake") -- For single-select
Dropdown:Set({"Cake", "Pie"}) -- For multi-select
```

**Features:**
- Single and multi-select modes
- Auto-saves using Flag
- Animated expand/collapse
- Hover effects on options
- **Auto‑callback on load** – if Flag exists, the callback is triggered with the saved value on creation.
- **Auto‑close** – for single‑select, the dropdown closes automatically after selection.
- Click sound on interaction.

---

### Color Picker

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/9a17431d-c3b0-49b0-89c4-aef07e6568f4)

```lua
local ColorPicker = Section:CreateColorPicker({
    Name = "Color Picker",
    Callback = function(newColor)
        print("New color: " .. tostring(newColor))
    end,
})
```

**Features:**
- Interactive RGB color selection
- Darkness slider
- Click and drag to select colors
- Real-time color updates
- Rainbow toggle (click the switch for animated cycling)

---

## Other Elements

### Text Label

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/6a5e977a-2f48-4e40-be1a-c195ed8fa400)

```lua
local Label = Section:CreateLabel({
    Description = "This is a sample description"
})
```

### Paragraph

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/6d0e58c8-88d3-4c17-9131-59ccfd378e71)

```lua
local Paragraph = Section:CreateParagraph({
    Title = "My Paragraph",
    Description = "This is a sample paragraph. Supports <b>rich text</b> formatting."
})
```

**Note:** Description supports rich text formatting.

---

### Card

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/b6601685-a168-4c17-a2a6-6ddbe3db856a)

```lua
local Card = Section:CreateCard({
    Title = "My Card",
    Description = "This is a sample card.",
    SecondaryTitle = "Card State",
    Image = "rbxassetid://14167800463",
    Buttons = {
        Button1 = {
            Name = "Button 1",
            Callback = function()
                print("Button 1 clicked")
            end
        },
        Button2 = {
            Name = "Button 2",
            Callback = function()
                print("Button 2 clicked")
            end
        }
    }
})
```

**Features:**
- Preview image support
- Multiple action buttons (up to 2)
- State display

---

### Divider

Add visual separators between elements.

```lua
local Divider = Section:CreateDivider()
```

**Features:**
- Clean visual separation
- Full-width line with subtle style

---

## Notifications

AuraIS provides two notification systems: Side Notifications (toast-style) and Window Notifications (modal-style). Both support **auto‑close on action** – clicking a button dismisses the notification immediately.

### Side Notifications

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/a7c6312a-74e0-4cc1-8c9c-fc4632cfebea)

**Types:** "Normal", "Warning", "Error" (affects styling)

```lua
-- Normal notification
AuraIS:Notify("Normal", {
    Title = "Notification Title",
    Content = "Notification Content",
    Duration = 5, -- Seconds before auto-dismiss
    Image = "rbxassetid://4483362458", -- Optional icon
    Actions = {
        {
            Name = "Okay!",
            Callback = function()
                print("User tapped Okay!")
            end
        },
        {
            Name = "Cancel",
            Callback = function()
                print("User tapped Cancel!")
            end
        }
    }
})

-- Warning notification
AuraIS:Notify("Warning", {
    Title = "Warning!",
    Content = "This is a warning notification",
    Duration = 5,
    Actions = {
        {
            Name = "Dismiss",
            Callback = function()
                print("Warning dismissed!")
            end
        }
    }
})

-- Error notification
AuraIS:Notify("Error", {
    Title = "Error!",
    Content = "Something went wrong",
    Duration = 5,
    Actions = {
        {
            Name = "Retry",
            Callback = function()
                print("Retrying...")
            end
        },
        {
            Name = "Ignore",
            Callback = function()
                print("Error ignored!")
            end
        }
    }
})
```

**Parameters:**
- `Type` (string): "Normal", "Warning", or "Error"
- `Title` (string): Notification title
- `Content` (string): Notification message
- `Duration` (number): Time in seconds before auto-dismiss
- `Image` (string, optional): Icon image asset ID
- `Actions` (table, optional): Array of action objects with Name and Callback

**Actions:**
- Multiple actions supported
- Each action appears as a clickable button
- Auto-sizing based on text length
- Triggers click sound when pressed
- **Auto-close** – clicking any action immediately dismisses the notification (sets duration to 0)

---

### Window Notifications

Example:

![image](https://github.com/GamingScripter/Darkrai-Y/assets/102379753/ca564ed2-149f-4fef-ae04-fcb6c7de331c)

```lua
Library:Notify({
    Title = "Notification Title",
    Content = "Notification Content",
    Duration = 5,
    Image = "rbxassetid://4483362458",
    Actions = {
        {
            Name = "Okay!",
            Callback = function()
                print("User tapped Okay!")
            end
        },
        {
            Name = "Cancel",
            Callback = function()
                print("User tapped Cancel!")
            end
        }
    }
})
```

**Features:**
- Modal-style overlay
- Custom action buttons
- Timer display with countdown
- Auto-dismiss on timer end
- **Auto-close on action** – button press dismisses immediately

**Actions:**
- Multiple actions supported
- Each action appears as a clickable button
- Auto-sizing based on text length
- Triggers click sound when pressed
- Wrapped in pcall for error protection

---

## Utility Methods

### UI Control
```lua
-- Toggle UI visibility
AuraIS:ToggleUI()
```

### Tab Management
```lua
-- Switch to a specific tab by name
Library:SwitchTab("Tab Name")

-- Switch to first tab
Library:SwitchTab()
```

### Section Management
```lua
-- Remove a section entirely
Section:Remove()

-- Update section name
Section:SetName("New Section Name")
```

---

## Configuration System

AuraIS automatically saves and loads UI state using JSON files.

### How it works:
- Configuration saved to: `[ScriptFolder]/Configurations/UI.json`
- Automatically loads on library creation
- Saves on any state change
- Supports: Toggles, Sliders, Dropdowns, Keybinds, Inputs (textboxes)

### Using Flags:
```lua
-- Toggle with Flag
local Toggle = Section:CreateToggle("Normal", {
    Flag = "MyFeature", -- This will be saved
    -- ...
})

-- Slider with Flag
local Slider = Section:CreateSlider({
    Flag = "MySlider", -- This will be saved
    -- ...
})

-- Dropdown with Flag
local Dropdown = Section:CreateDropdown({
    Flag = "MyDropdown", -- This will be saved
    -- ...
})

-- Keybind with Flag
local Keybind = Section:CreateKeybind({
    Flag = "MyKeybind", -- This will be saved
    -- ...
})

-- Textbox with Flag
local Textbox = Section:CreateTextbox({
    Flag = "MyInput", -- This will be saved
    -- ...
})
```

### Configuration Structure:
```json
{
    "Toggles": {
        "MyFeature": true,
        "AnotherFeature": false
    },
    "Sliders": {
        "MySlider": 50,
        "SpeedValue": 75
    },
    "Dropdowns": {
        "MyDropdown": "Cake",
        "MultiDropdown": ["Option1", "Option2"]
    },
    "Keybinds": {
        "MyKeybind": "F",
        "ActionKey": "G"
    },
    "Inputs": {
        "MyInput": "User entered text"
    }
}
```

---

## Example: Complete Script Setup

```lua
local AuraIS = require(path.to.AuraIS)

-- Create Library
local Library = AuraIS:CreateLibrary({
    Name = "My Script",
    Icon = "rbxassetid://11432865001"
})

-- Create Tab
local MainTab = Library:CreateTab("Main", "rbxassetid://11432859220")

-- Create Section
local Settings = MainTab:CreateSection("Settings", "Normal")

-- Create Toggle
local Toggle = Settings:CreateToggle("Normal", {
    Name = "Enable Feature",
    Flag = "FeatureEnabled",
    Callback = function(v)
        print("Feature: " .. tostring(v))
    end
})

-- Create Slider
local Slider = Settings:CreateSlider({
    Name = "Speed",
    Value = {0, 100},
    Increment = 5,
    Suffix = "%",
    Flag = "SpeedValue",
    Callback = function(v)
        print("Speed: " .. v)
    end
})

-- Create Button
local Button = Settings:CreateButton({
    Name = "Click Me",
    Callback = function()
        Library:Notify({
            Title = "Hello!",
            Content = "Button clicked!",
            Duration = 3
        })
    end
})

-- Notify user
AuraIS:Notify("Normal", {
    Title = "Welcome",
    Content = "Script loaded successfully!",
    Duration = 3
})
```

