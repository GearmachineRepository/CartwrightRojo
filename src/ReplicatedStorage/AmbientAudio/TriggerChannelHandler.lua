--!strict

local TweenService = game:GetService("TweenService")
local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)
local TriggerTypes = require(script.Parent.TriggerTypes)

type ChannelState = TriggerTypes.ChannelState
type SoundData = TriggerTypes.SoundData
type TriggerZone = TriggerTypes.TriggerZone
type WinnerInfo = TriggerTypes.WinnerInfo

local TriggerChannelHandler = {}

-- Configuration - made configurable through Core
Core.TRIGGER_SMOOTH_TIME = Core.TRIGGER_SMOOTH_TIME or 0.25
Core.TRIGGER_MAX_SPEED = Core.TRIGGER_MAX_SPEED or 40
Core.CHANNEL_PERSISTENCE_TIME = Core.CHANNEL_PERSISTENCE_TIME or 2.0 -- Time to keep channel alive without winner



-- Smooth target position updates to prevent discontinuous jumps
function TriggerChannelHandler.UpdateTargetPosition(ChannelState: ChannelState, NewTarget: Vector3): boolean
	local _ = 8.0 -- Studs - maximum distance target can jump instantly
	local PositionChanged = false

	if ChannelState.TargetPos then
		local Distance = (NewTarget - ChannelState.TargetPos).Magnitude
		if Distance > 0.1 then
			ChannelState.TargetPos = NewTarget
			PositionChanged = true
		end
	else
		ChannelState.TargetPos = NewTarget
		PositionChanged = true
	end

	return PositionChanged
end

-- SmoothDamp wrapper for container movement
local function SmoothDampVector3(Current: Vector3, Target: Vector3, Velocity: Vector3, SmoothTime: number, MaxSpeed: number?, DeltaTime: number)
	if TweenService and TweenService.SmoothDamp then
		return TweenService:SmoothDamp(Current, Target, Velocity, SmoothTime, MaxSpeed, DeltaTime)
	else
		return Utils.SmoothDampVector3(Current, Target, Velocity, SmoothTime, MaxSpeed, DeltaTime)
	end
end

-- Get current channel states
function TriggerChannelHandler.GetChannelStates(): {[string]: ChannelState}
	return Core.ChannelState
end

-- Initialize channel state if it doesn't exist
function TriggerChannelHandler.EnsureChannelState(ChannelId: string): ChannelState
	if not Core.ChannelState[ChannelId] then
		Core.ChannelState[ChannelId] = {
			ActiveSound = nil,
			CurrentZone = nil,
			TargetPos = nil,
			Vel = nil,
			LastWinnerChange = nil,
		}
	end
	return Core.ChannelState[ChannelId]
end

-- Handle channel handoff for linked zones
function TriggerChannelHandler.HandleChannelHandoff(
	ChannelId: string,
	NewZone: TriggerZone,
	NewPosition: Vector3,
	ActiveSound: SoundData?
): ()
	local ChannelState = TriggerChannelHandler.EnsureChannelState(ChannelId)

	-- Set active sound if provided
	if ActiveSound then
		ChannelState.ActiveSound = ActiveSound
		NewZone.ActiveSound = ActiveSound
	end

	-- Only update zone reference if it actually changed
	local ZoneChanged = ChannelState.CurrentZone ~= NewZone
	if ZoneChanged then
		ChannelState.CurrentZone = NewZone
		ChannelState.LastWinnerChange = tick()
	end

	-- Update target position with smoothing
	local _ = TriggerChannelHandler.UpdateTargetPosition(ChannelState, NewPosition)

	-- Initialize velocity if needed
	if not ChannelState.Vel then
		ChannelState.Vel = Vector3.new()
	end

	-- For CenterLine emitters on zone changes, ensure smooth transitions
	if ZoneChanged and NewZone.EmitterMode == "CenterLine" then
		local CurrentSound = ChannelState.ActiveSound
		if CurrentSound and CurrentSound.SoundContainer then
			local CurrentContainerPosition = CurrentSound.SoundContainer.Position
			-- Adjust the new zone's RodT to minimize position jumps
			local IdealT = Utils.RodTFor(NewZone.Part, CurrentContainerPosition)
			NewZone.RodT = IdealT
		end
	end
end

-- Smooth movement for all channel containers
function TriggerChannelHandler.UpdateChannelContainers(DeltaTime: number): ()
	for _, ChannelState in pairs(Core.ChannelState) do
		local SoundData = ChannelState.ActiveSound
		local TargetPosition = ChannelState.TargetPos

		if SoundData and TargetPosition and SoundData.SoundContainer then
			local CurrentPosition = SoundData.SoundContainer.Position
			local Velocity = ChannelState.Vel or Vector3.new()

			-- Only update if we're not already very close to target
			local DistanceToTarget = (TargetPosition - CurrentPosition).Magnitude
			if DistanceToTarget > 0.05 then
				local NextPosition, NextVelocity = SmoothDampVector3(
					CurrentPosition,
					TargetPosition,
					Velocity,
					Core.TRIGGER_SMOOTH_TIME,
					Core.TRIGGER_MAX_SPEED,
					DeltaTime
				)

				ChannelState.Vel = NextVelocity
				SoundData.Position = NextPosition
				SoundData.SoundContainer.CFrame = CFrame.new(NextPosition)
			end
		end
	end
end



-- Clean up channel references when sounds are destroyed
function TriggerChannelHandler.CleanupChannelReferences(DestroyedSound: SoundData): ()
	for _, ChannelState in pairs(Core.ChannelState) do
		if ChannelState.ActiveSound == DestroyedSound then
			ChannelState.ActiveSound = nil
			-- Don't clear other state immediately - let natural cleanup handle it
		end
	end
end

-- Clean up all channel states
function TriggerChannelHandler.Cleanup(): ()
	table.clear(Core.ChannelState)
end

return TriggerChannelHandler