--!strict
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StartSprint = ReplicatedStorage:WaitForChild("Events"):WaitForChild("SprintEvents"):WaitForChild("StartSprint")
local StopSprint = ReplicatedStorage:WaitForChild("Events"):WaitForChild("SprintEvents"):WaitForChild("StopSprint")

local SprintKey = Enum.KeyCode.LeftShift

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == SprintKey then
		StartSprint:FireServer()
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == SprintKey then
		StopSprint:FireServer()
	end
end)
