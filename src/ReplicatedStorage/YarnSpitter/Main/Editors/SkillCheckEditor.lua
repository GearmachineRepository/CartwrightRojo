--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local SkillCheckEditor = {}

function SkillCheckEditor.Render(
	Choice: DialogChoice,
	Index: number,
	Parent: Instance,
	Order: number,
	OnDelete: () -> (),
	OnNavigate: (DialogTree.DialogNode) -> ()
): Frame
	local Container = Components.CreateContainer(Parent, Order)

	Components.CreateLabel("Choice " .. tostring(Index) .. " - Button Text:", Container, 1)
	Components.CreateTextBox(Choice.ButtonText, Container, 2, false, function(NewText)
		Choice.ButtonText = NewText
	end)

	if not Choice.SkillCheck then
		return Container
	end

	Components.CreateLabel("Skill:", Container, 4)
	Components.CreateDropdown(Constants.SKILLS, Choice.SkillCheck.Skill, Container, 5, function(NewSkill)
		Choice.SkillCheck.Skill = NewSkill
	end)

	Components.CreateLabel("Difficulty:", Container, 6)
	Components.CreateNumberInput(Choice.SkillCheck.Difficulty, Container, 7, function(NewDifficulty)
		Choice.SkillCheck.Difficulty = NewDifficulty
	end)

	Components.CreateLabel("✓ Success Response:", Container, 8)
	if Choice.SkillCheck.SuccessNode then
		Components.CreateTextBox(Choice.SkillCheck.SuccessNode.Text, Container, 9, true, function(NewText)
			Choice.SkillCheck.SuccessNode.Text = NewText
		end)

		Components.CreateButton("Edit Success Branch →", Container, 10, Constants.COLORS.SuccessDark, function()
			OnNavigate(Choice.SkillCheck.SuccessNode)
		end)
	end

	Components.CreateLabel("✗ Failure Response:", Container, 11)
	if Choice.SkillCheck.FailureNode then
		Components.CreateTextBox(Choice.SkillCheck.FailureNode.Text, Container, 12, true, function(NewText)
			Choice.SkillCheck.FailureNode.Text = NewText
		end)

		Components.CreateButton("Edit Failure Branch →", Container, 13, Constants.COLORS.DangerDark, function()
			OnNavigate(Choice.SkillCheck.FailureNode)
		end)
	end

	Components.CreateButton("Delete Choice", Container, 100, Constants.COLORS.Danger, OnDelete)

	return Container
end

return SkillCheckEditor