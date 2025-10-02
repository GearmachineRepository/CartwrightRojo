local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DistanceSphere = ReplicatedStorage:WaitForChild("DistanceSphere")

local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")

local ActiveSphere = workspace:FindFirstChild("DistanceSphere")

if ActiveSphere then
	ActiveSphere:Destroy()
	ActiveSphere = nil
end

while task.wait() do
	if not Character or not Character.PrimaryPart or not Humanoid or Humanoid.Health <= 0 then
		Character = script.Parent
		Humanoid = if Character then Character:FindFirstChild("Humanoid") else nil
		continue
	end
	
	if not ActiveSphere then
		ActiveSphere = DistanceSphere:Clone()
		ActiveSphere.Parent = workspace
	else
		ActiveSphere:PivotTo(Character.PrimaryPart.CFrame)
	end
end