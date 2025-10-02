-- Copy the processor into Studio, then:
local processor = require(script.Parent:WaitForChild("PlantAnalyzer"))

-- Process one plant
processor:ProcessPlant(workspace["Gift Tree"], "Gift Tree")

---- Process entire folder
--processor:ProcessAllPlantsInFolder(workspace.Plants)

---- Quick process (auto-detects)
--processor:QuickProcess(workspace.Plants.Rose)