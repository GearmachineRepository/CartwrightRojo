--!strict
local NodeEditor = require(script.Parent.NodeEditor)
local Builder = require(script.Parent.Parent.Components.Builder)
local UIStateManager = require(script.Parent.Parent.Managers.UIStateManager)
local DialogTree = require(script.Parent.Parent.Core.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local SkillCheckEditor = {}

function SkillCheckEditor.Render(Parent: ScrollingFrame, Choice: DialogChoice, OnRefresh: () -> ())
	local Base = NodeEditor.CreateBase(Parent, "Skill Check Editor")

	if not Choice.SkillCheck then
		Choice.SkillCheck = {
			Skill = "Charisma",
			Difficulty = 10,
			SuccessNode = nil,
			FailureNode = nil
		}
	end

	local BasicSection = NodeEditor.CreateSection(Base.Container, "Skill Check Properties", 1)

	Builder.LabeledInput("Choice Text:", {
		Value = Choice.Text,
		PlaceholderText = "Enter choice text...",
		OnChanged = function(Text)
			Choice.Text = Text
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.Dropdown({
		Label = "Skill Type:",
		Options = {"Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma"},
		Selected = Choice.SkillCheck.Skill or "Charisma",
		OnSelected = function(Skill)
			Choice.SkillCheck.Skill = Skill
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.NumberInput({
		Label = "Difficulty:",
		Value = Choice.SkillCheck.Difficulty or 10,
		Min = 1,
		Max = 30,
		OnChanged = function(Value)
			Choice.SkillCheck.Difficulty = Value
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.Spacer(12).Parent = Base.Container

	local SuccessSection = NodeEditor.CreateSection(Base.Container, "Success Node", 2)

	if Choice.SkillCheck.SuccessNode then
		Builder.LabeledInput("Success Response:", {
			Value = Choice.SkillCheck.SuccessNode.Text,
			PlaceholderText = "Enter success text...",
			Multiline = true,
			Height = 80,
			OnChanged = function(Text)
				Choice.SkillCheck.SuccessNode.Text = Text
				OnRefresh()
			end
		}).Parent = SuccessSection

		local RemoveSuccessButton = Builder.Button({
			Text = "Remove Success Node",
			Type = "Danger",
			OnClick = function()
				Choice.SkillCheck.SuccessNode = nil
				OnRefresh()
			end
		})
		RemoveSuccessButton.Size = UDim2.new(0, 180, 0, 32)
		RemoveSuccessButton.Parent = SuccessSection
	else
		local AddSuccessButton = Builder.Button({
			Text = "Add Success Node",
			Type = "Success",
			OnClick = function()
				Choice.SkillCheck.SuccessNode = DialogTree.CreateNode("success", "Success! You passed the check.")
				OnRefresh()
			end
		})
		AddSuccessButton.Size = UDim2.new(0, 180, 0, 32)
		AddSuccessButton.Parent = SuccessSection
	end

	Builder.Spacer(12).Parent = Base.Container

	local FailureSection = NodeEditor.CreateSection(Base.Container, "Failure Node", 3)

	if Choice.SkillCheck.FailureNode then
		Builder.LabeledInput("Failure Response:", {
			Value = Choice.SkillCheck.FailureNode.Text,
			PlaceholderText = "Enter failure text...",
			Multiline = true,
			Height = 80,
			OnChanged = function(Text)
				Choice.SkillCheck.FailureNode.Text = Text
				OnRefresh()
			end
		}).Parent = FailureSection

		local RemoveFailureButton = Builder.Button({
			Text = "Remove Failure Node",
			Type = "Danger",
			OnClick = function()
				Choice.SkillCheck.FailureNode = nil
				OnRefresh()
			end
		})
		RemoveFailureButton.Size = UDim2.new(0, 180, 0, 32)
		RemoveFailureButton.Parent = FailureSection
	else
		local AddFailureButton = Builder.Button({
			Text = "Add Failure Node",
			Type = "Success",
			OnClick = function()
				Choice.SkillCheck.FailureNode = DialogTree.CreateNode("failure", "You failed the check.")
				OnRefresh()
			end
		})
		AddFailureButton.Size = UDim2.new(0, 180, 0, 32)
		AddFailureButton.Parent = FailureSection
	end
end

return SkillCheckEditor