--!strict

local ComponentLibrary = script.Parent.Parent.ComponentLibrary
local Labels = require(ComponentLibrary.Labels)
local Buttons = require(ComponentLibrary.Buttons)
local Inputs = require(ComponentLibrary.Inputs)
local Containers = require(ComponentLibrary.Containers)

local Components = {}

Components.CreateLabel = Labels.CreateLabel
Components.CreateInlineLabel = Labels.CreateInlineLabel
Components.CreateSectionLabel = Labels.CreateSectionLabel

Components.CreateButton = Buttons.CreateButton
Components.CreateButtonRow = Buttons.CreateButtonRow
Components.CreateToggleButton = Buttons.CreateToggleButton

Components.CreateTextBox = Inputs.CreateTextBox
Components.CreateLabeledInput = Inputs.CreateLabeledInput
Components.CreateDropdown = Inputs.CreateDropdown
Components.CreateNumberInput = Inputs.CreateNumberInput

Components.CreateContainer = Containers.CreateContainer
Components.CreateCollapsibleSection = Containers.CreateCollapsibleSection

return Components