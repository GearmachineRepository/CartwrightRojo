--!strict
local Visuals = {}

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")
local BlurEffect = Lighting:WaitForChild("Blur")

local active = {}

-- Setup default FOV
function Visuals.Setup()
	LocalPlayer:SetAttribute("Core_FOV", 70)
end

function Visuals.Return_Core_FOV()
	return LocalPlayer:GetAttribute("Core_FOV")
end

-- Change FOV with tweening
function Visuals.Change_FOV(fov, duration)
	duration = duration or 0.5
	if fov == 70 then
		fov = LocalPlayer:GetAttribute("Core_FOV")
	end
	if Camera then
		local tween = TweenService:Create(Camera, TweenInfo.new(duration * (math.random(95, 105) * 0.01), Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			FieldOfView = fov
		})
		tween:Play()
		Debris:AddItem(tween, tween.TweenInfo.Time)
	end
end

-- Apply blur effect (if needed)
function Visuals.Blur(size, duration)
	local tween = TweenService:Create(BlurEffect, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = size
	})
	tween:Play()
	Debris:AddItem(tween, duration)
end

-- Begin visual transition
function Visuals.Show(id, useBlur)
	if not table.find(active, id) then
		table.insert(active, id)
	end
	Visuals.Change_FOV(60, 0.3)
	if useBlur then
		Visuals.Blur(15, 0.1)
	end
end

-- End visual transition
function Visuals.Hide(id)
	local index = table.find(active, id)
	if index then
		table.remove(active, index)
	end
	if #active == 0 then
		LocalPlayer:SetAttribute("Core_FOV", 70)
		Visuals.Change_FOV(70, 0.3)
		Visuals.Blur(0, 0.3)
	end
end

function Visuals.Can()
	return #active == 0
end

return Visuals
