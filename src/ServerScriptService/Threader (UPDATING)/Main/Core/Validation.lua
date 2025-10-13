--!strict
local DialogTree = require(script.Parent.DialogTree)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local Validation = {}

export type ValidationResult = {
	IsValid: boolean,
	Errors: {string}
}

function Validation.ValidateTree(Tree: DialogNode): ValidationResult
	local Errors: {string} = {}
	local VisitedNodes: {[DialogNode]: boolean} = {}

	local function ValidateNode(Node: DialogNode, Path: string)
		if VisitedNodes[Node] then
			table.insert(Errors, Path .. " - Circular reference detected")
			return
		end

		VisitedNodes[Node] = true

		if not Node.Id or Node.Id == "" then
			table.insert(Errors, Path .. " - Missing or empty node ID")
		end

		if not Node.Text or Node.Text == "" then
			table.insert(Errors, Path .. " - Missing or empty dialog text")
		end

		if Node.ReturnToNodeId then
			local Found = Validation.FindNodeById(Tree, Node.ReturnToNodeId)
			if not Found then
				table.insert(Errors, Path .. " - Invalid ReturnToNodeId: " .. Node.ReturnToNodeId)
			end
		end

		if Node.Choices then
			for Index, Choice in ipairs(Node.Choices) do
				local ChoicePath = Path .. "/Choice[" .. Index .. "]"

				if not Choice.Text or Choice.Text == "" then
					table.insert(Errors, ChoicePath .. " - Missing button text")
				end

				if Choice.ReturnToNodeId then
					local Found = Validation.FindNodeById(Tree, Choice.ReturnToNodeId)
					if not Found then
						table.insert(Errors, ChoicePath .. " - Invalid ReturnToNodeId: " .. Choice.ReturnToNodeId)
					end
				end

				if Choice.ResponseNode then
					ValidateNode(Choice.ResponseNode, ChoicePath .. "/Response")
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode then
						ValidateNode(Choice.SkillCheck.SuccessNode, ChoicePath .. "/Success")
					end
					if Choice.SkillCheck.FailureNode then
						ValidateNode(Choice.SkillCheck.FailureNode, ChoicePath .. "/Failure")
					end
				end
			end
		end

		if Node.NextResponseNode then
			ValidateNode(Node.NextResponseNode, Path .. "/Next")
		end

		VisitedNodes[Node] = nil
	end

	ValidateNode(Tree, "Root")

	return {
		IsValid = #Errors == 0,
		Errors = Errors
	}
end

function Validation.FindNodeById(Root: DialogNode, Id: string): DialogNode?
	return DialogTree.FindNodeById(Root, Id)
end

return Validation