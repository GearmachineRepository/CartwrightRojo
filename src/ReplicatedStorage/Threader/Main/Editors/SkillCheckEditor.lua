--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local SkillCheckEditor = {}

function SkillCheckEditor.Render(
	Choice: DialogChoice,
	_: number,
	Parent: Instance,
	Order: number,
	OnDelete: () -> (),
	OnNavigate: (DialogTree.DialogNode) -> ()
): Frame
	local Container = Components.CreateContainer(Parent, Order)

	Components.CreateLabeledInput("Button Text:", Choice.ButtonText, Container, 1, function(NewText)
		Choice.ButtonText = NewText
	end)

	if not Choice.SkillCheck then
		return Container
	end

	Components.CreateLabel("Skill:", Container, 2)
	Components.CreateDropdown(Constants.SKILLS, Choice.SkillCheck.Skill, Container, 3, function(NewSkill)
		Choice.SkillCheck.Skill = NewSkill
	end)

	Components.CreateLabel("Difficulty:", Container, 4)
	Components.CreateNumberInput(Choice.SkillCheck.Difficulty, Container, 5, function(NewDifficulty)
		Choice.SkillCheck.Difficulty = NewDifficulty
	end)

	Components.CreateLabel("✓ Success Response:", Container, 6)
	if Choice.SkillCheck.SuccessNode then
		Components.CreateTextBox(Choice.SkillCheck.SuccessNode.Text, Container, 7, true, function(NewText)
			Choice.SkillCheck.SuccessNode.Text = NewText
		end)

		Components.CreateButton("Navigate to Success Branch →", Container, 8, Constants.COLORS.SuccessDark, function()
			OnNavigate(Choice.SkillCheck.SuccessNode)
		end)
	end

	Components.CreateLabel("✗ Failure Response:", Container, 9)
	if Choice.SkillCheck.FailureNode then
		Components.CreateTextBox(Choice.SkillCheck.FailureNode.Text, Container, 10, true, function(NewText)
			Choice.SkillCheck.FailureNode.Text = NewText
		end)

		if Choice.SkillCheck.SuccessNode then
			Components.CreateButtonRow({
				{Text = "→ Success Branch", Color = Constants.COLORS.SuccessDark, OnClick = function()
					OnNavigate(Choice.SkillCheck.SuccessNode)
				end},
				{Text = "→ Failure Branch", Color = Constants.COLORS.DangerDark, OnClick = function()
					OnNavigate(Choice.SkillCheck.FailureNode)
				end}
			}, Container, 11)
		else
			Components.CreateButton("Navigate to Failure Branch →", Container, 11, Constants.COLORS.DangerDark, function()
				OnNavigate(Choice.SkillCheck.FailureNode)
			end)
		end
	end

	Components.CreateButton("Delete Choice", Container, 100, Constants.COLORS.Danger, OnDelete)

	return Container
end

return SkillCheckEditor