local UserInputService = game:GetService("UserInputService")

local SprintKey = Enum.KeyCode.LeftShift

UserInputService.InputBegan:Connect(function(Input: InputObject, Processed: boolean)
	if Input.KeyCode == SprintKey then
		local Character = game.Players.LocalPlayer.Character
		if Character then
			Character:SetAttribute("Sprinting", true)
		end
	end
end)

UserInputService.InputEnded:Connect(function(Input: InputObject, Processed: boolean)
	if Input.KeyCode == SprintKey then
		local Character = game.Players.LocalPlayer.Character
		if Character then
			Character:SetAttribute("Sprinting", false)
		end
	end
end)
