--!strict
--!optimize 2

local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local PhysicsGroupModule = {}

type CollisionRules = {[number]: {[number]: string | boolean}}
type Rule = {[number]: string | boolean}

local PhysicsGroups: {[number]: string} = {
	[1] = "Dragging",
	[2] = "Characters",
	[3] = "Static"
}

local CollisionRules: CollisionRules = {
	{"Dragging", "Characters", false},
	{"Dragging", "Dragging", false},
	{"Characters", "Characters", false},
	{"Characters", "Static", true},
	{"Static", "Static", true},
	{"Dragging", "Static", false},
}

if RunService:IsServer() then
	for _: number, GroupName: string in pairs(PhysicsGroups) do
		pcall(function()
			PhysicsService:RegisterCollisionGroup(GroupName)
		end)
	end

	for _, Rule: Rule in pairs(CollisionRules) do
		PhysicsService:CollisionGroupSetCollidable(Rule[1], Rule[2], Rule[3])
	end
end

local function IsNPC(instance: Instance): boolean
	local model = instance:IsA("Model") and instance or instance:FindFirstAncestorOfClass("Model")
	if not model then return false end

	-- Use either attribute or tag
	return model:GetAttribute("IsNPC") == true or CollectionService:HasTag(model, "NPC")
end


function PhysicsGroupModule.SetToGroup(InstanceToSet: Instance, GroupName: string): ()
	if not InstanceToSet then
		return
	end

	if InstanceToSet:IsA("BasePart") then
		pcall(function()
			InstanceToSet.CollisionGroup = GroupName
		end)
		return
	end

	for _, Descendant: Instance in pairs(InstanceToSet:GetDescendants()) do
		if Descendant:IsA("BasePart") then
			pcall(function()
				Descendant.CollisionGroup = GroupName
			end)
		end
	end
end

function PhysicsGroupModule.SetProperty(InstanceToSet: Instance, Property: string, Value: any): ()
	if not InstanceToSet or IsNPC(InstanceToSet) then
		return
	end

	if InstanceToSet:IsA("BasePart") then
		pcall(function()
			local Part: BasePart = InstanceToSet :: BasePart
			if Property == "CanCollide" and Part.Transparency >= 1 then
				Part.CanCollide = false
				return
			end
			(Part :: any)[Property] = Value
		end)
		return
	end

	for _, Descendant: Instance in pairs(InstanceToSet:GetDescendants()) do
		if IsNPC(Descendant) then
			continue
		end

		if Descendant:IsA("BasePart") then
			pcall(function()
				local Part: BasePart = Descendant :: BasePart
				if Property == "CanCollide" and Part.Transparency >= 1 then
					Part.CanCollide = false
					return
				end
				(Part :: any)[Property] = Value
			end)
		end
	end
end


return PhysicsGroupModule