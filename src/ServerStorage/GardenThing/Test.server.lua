local PlantGrower = require(script.Parent:WaitForChild("PlantGrower"))
local MachineSystem = require(script.Parent:WaitForChild("MachineSystem"))

for Index, Plant in pairs(workspace:WaitForChild("Plants"):GetChildren()) do
	Plant:SetAttribute("PlantType", Plant.Name) -- Set PlantType so machine can find it
end

-- Setup sprinkler to boost chances
local MySprinklerModel = workspace:WaitForChild("Garden Sprinkler")
MachineSystem:Construct(MySprinklerModel, "Sprinkler")
MachineSystem:StartMachine(MySprinklerModel)
MachineSystem:AddWater(MySprinklerModel, 100)

-- Now grow the plants (they should have modifiers applied)
for Index, Plant in pairs(workspace:WaitForChild("Plants"):GetChildren()) do
	task.spawn(function()
		PlantGrower:GrowPlant(Plant, Plant.Name)
	end)
end

task.wait(12)

PlantGrower:HarvestFruit(workspace.Plants["Offering Tree"], "Fruit_01")