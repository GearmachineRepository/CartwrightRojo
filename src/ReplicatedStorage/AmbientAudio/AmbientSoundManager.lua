--!strict
local Core          = require(script.Parent.Core)
local Loader        = require(script.Parent.LibraryLoader)
local TriggerEngine = require(script.Parent.TriggerEngine)
local DynamicEngine = require(script.Parent.DynamicEngine)
local WindEngine    = require(script.Parent.WindEngine)

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")

local AmbientSoundManager = {}

function AmbientSoundManager.Initialize(): ()
	Loader.LoadSettings()
	Loader.LoadSoundLibrary()

	TriggerEngine.BuildZones()
	WindEngine.BuildZones()

	WindEngine.InitBed()

	-- Prime once in case the player spawns inside zones
	task.defer(function()
		local hrp = Players.LocalPlayer and Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local p = hrp.Position
			TriggerEngine.Update(0, p)
			TriggerEngine.CommitVolumes(0)
		end
	end)

	-- Heartbeat loop
	local last = os.clock()
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local dt = now - last
		last = now

		local lp = Players.LocalPlayer
		local hrp = lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local playerPos = hrp.Position

		WindEngine.UpdateZoneOverride(playerPos)
		WindEngine.UpdateBed(dt)

		TriggerEngine.Update(dt, playerPos)   -- winners, emit positions, targets
		TriggerEngine.CommitVolumes(dt)       -- fade + cleanup for looped trigger sounds

		DynamicEngine.UpdateActive(dt, playerPos) -- move/fade/cull one-shots & foliage

		Core._accum += dt
		if Core._accum >= Core.DYNAMIC_SCHEDULER_INTERVAL then
			Core._accum = 0
			DynamicEngine.ScheduleFoliage(playerPos)
			WindEngine.ScheduleGusts(playerPos)
		end
	end)
end

function AmbientSoundManager.Update(_: Vector3): () -- keep for callers
	Core.SoundUpdateCounter += 1
end

function AmbientSoundManager.RegisterDynamicSource(object: BasePart, soundType: string): ()
	DynamicEngine.Register(object, soundType)
end

function AmbientSoundManager.UnregisterDynamicSource(object: BasePart): ()
	DynamicEngine.Unregister(object)
end

function AmbientSoundManager.SetConfiguration(cfg: {[string]: any}): ()
	Core.ApplyConfig(cfg)
end

function AmbientSoundManager.AddSoundType(soundType: string, soundConfig: {[string]: any}): ()
	Core.SoundLibrary[soundType] = soundConfig
end

function AmbientSoundManager.RefreshTriggers(): ()
	TriggerEngine.BuildZones()
	-- Prime immediately
	local lp = Players.LocalPlayer
	local hrp = lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local p = hrp.Position
		TriggerEngine.Update(0, p)
		TriggerEngine.CommitVolumes(0)
	end
end

function AmbientSoundManager.Cleanup(): ()
	TriggerEngine.Cleanup()
	DynamicEngine.Cleanup()
	WindEngine.Cleanup()
	Core.Reset()
end

function AmbientSoundManager.GetStats(): {[string]: any}
	return Core.Stats()
end

function AmbientSoundManager.DebugTriggerSound(soundType: string, position: Vector3?): ()
	DynamicEngine.DebugOneShot(soundType, position)
end

return AmbientSoundManager