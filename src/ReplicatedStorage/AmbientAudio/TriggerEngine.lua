--!strict

local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)
local TriggerTypes = require(script.Parent.TriggerTypes)
local TriggerZoneBuilder = require(script.Parent.TriggerZoneBuilder)
local TriggerSoundManager = require(script.Parent.TriggerSoundManager)

type TriggerZone = TriggerTypes.TriggerZone
type SoundData = TriggerTypes.SoundData

local TriggerEngine = {}

-- Channel management system for linked zones
local ChannelSounds = {} -- [ChannelId] = SoundData
local ChannelPositions = {} -- [ChannelId] = {Current = Vector3, Target = Vector3, Velocity = Vector3}
local ChannelLastWinner = {} -- [ChannelId] = TriggerZone (for hysteresis)

-- Calculate emitter position for a zone
local function GetEmitterPosition(Zone: TriggerZone, PlayerPosition: Vector3): Vector3
	local Part = Zone.Part

	if Zone.EmitterMode == "Center" then
		return Part.Position
	end

	if Zone.EmitterMode == "CenterLine" and (not Part.Shape or Part.Shape ~= Enum.PartType.Ball) then
		local T = Zone.RodT
		if T == nil then 
			T = Utils.RodTFor(Part, PlayerPosition)
			Zone.RodT = T 
		end
		return Utils.PosFromRodT(Part, T)
	end

	return Utils.NearestPoint(Part, PlayerPosition)
end

-- Update rod positions for smooth CenterLine following
local function UpdateRodPositions(Zones: {TriggerZone}, PlayerPosition: Vector3): ()
	for _, Zone in ipairs(Zones) do
		if Zone.EmitterMode == "CenterLine" then
			local T = Utils.RodTFor(Zone.Part, PlayerPosition)
			Zone.RodT = Zone.RodT and (Zone.RodT + (T - Zone.RodT) * 0.35) or T
		end
	end
end

-- Find the best zone for each channel with improved hysteresis
local function ComputeChannelWinners(Zones: {TriggerZone}, PlayerPosition: Vector3): {[string]: TriggerZone}
	local Winners = {}
	local ChannelCandidates = {} -- [ChannelId] = {{Zone, Distance, Position}}

	-- Collect candidates for each channel
	for _, Zone in ipairs(Zones) do
		if Zone.EmitterKind == "Loop" and Zone.ChannelId then
			local Position = GetEmitterPosition(Zone, PlayerPosition)
			local Distance = (Position - PlayerPosition).Magnitude

			-- Use enter radius + buffer for candidate selection
			if Distance <= Zone.EnterRadius + 2.0 then
				local ChannelId = Zone.ChannelId
				if not ChannelCandidates[ChannelId] then
					ChannelCandidates[ChannelId] = {}
				end
				table.insert(ChannelCandidates[ChannelId], {
					Zone = Zone, 
					Distance = Distance, 
					Position = Position
				})
			end
		end
	end

	-- Select winner for each channel with hysteresis
	for ChannelId, Candidates in pairs(ChannelCandidates) do
		if #Candidates == 0 then continue end

		-- Sort by distance (closest first)
		table.sort(Candidates, function(a, b) return a.Distance < b.Distance end)

		local Winner = Candidates[1].Zone
		local LastWinner = ChannelLastWinner[ChannelId]

		-- Apply hysteresis - prefer keeping current winner if close enough
		if LastWinner then
			for _, Candidate in ipairs(Candidates) do
				if Candidate.Zone == LastWinner then
					local DistanceDiff = Candidate.Distance - Candidates[1].Distance
					-- Only switch if new zone is significantly closer (2 stud hysteresis)
					if DistanceDiff <= 2.0 then
						Winner = LastWinner
						break
					end
				end
			end
		end

		Winners[ChannelId] = Winner
		ChannelLastWinner[ChannelId] = Winner
	end

	return Winners
end

-- Create or get channel sound
local function EnsureChannelSound(ChannelId: string, SoundType: string, InitialPosition: Vector3): SoundData?
	if ChannelSounds[ChannelId] then
		return ChannelSounds[ChannelId]
	end

	-- Create new channel sound
	TriggerSoundManager.EnsureCapacityForTrigger()
	local SoundData = TriggerSoundManager.CreateSound(SoundType, InitialPosition, nil)
	if SoundData then
		SoundData.Sound:Play()
		table.insert(Core.ActiveTriggers, SoundData)
		ChannelSounds[ChannelId] = SoundData

		-- Initialize channel position tracking
		ChannelPositions[ChannelId] = {
			Current = InitialPosition,
			Target = InitialPosition,
			Velocity = Vector3.new()
		}

		return SoundData
	end

	return nil
end

-- Update channel sound position smoothly
local function UpdateChannelPosition(ChannelId: string, TargetPosition: Vector3, DeltaTime: number): ()
	local ChannelPos = ChannelPositions[ChannelId]
	local SoundData = ChannelSounds[ChannelId]

	if not ChannelPos or not SoundData or not SoundData.SoundContainer then
		return
	end

	-- Update target position
	ChannelPos.Target = TargetPosition

	-- Smooth movement using SmoothDamp-like behavior
	local SmoothTime = 0.2
	local MaxSpeed = 50

	local NextPosition, NextVelocity = Utils.SmoothDampVector3(
		ChannelPos.Current, 
		ChannelPos.Target, 
		ChannelPos.Velocity, 
		SmoothTime, 
		MaxSpeed, 
		DeltaTime
	)

	ChannelPos.Current = NextPosition
	ChannelPos.Velocity = NextVelocity

	-- Update sound container position
	SoundData.Position = NextPosition
	SoundData.SoundContainer.CFrame = CFrame.new(NextPosition)
end

-- Build all trigger zones from CollectionService
function TriggerEngine.BuildZones(): ()
	Core.TriggerZones = TriggerZoneBuilder.BuildZones()

	-- Clear channel state on rebuild
	table.clear(ChannelSounds)
	table.clear(ChannelPositions)
	table.clear(ChannelLastWinner)
end

-- Main update loop for trigger system
function TriggerEngine.Update(DeltaTime: number, PlayerPosition: Vector3): ()
	-- Update rod positions for smooth following
	UpdateRodPositions(Core.TriggerZones, PlayerPosition)

	-- Compute winners for channel-linked zones
	local ChannelWinners = ComputeChannelWinners(Core.TriggerZones, PlayerPosition)

	-- Process each zone
	for _, Zone in ipairs(Core.TriggerZones) do
		local Position = GetEmitterPosition(Zone, PlayerPosition)
		local Distance = (Position - PlayerPosition).Magnitude
		local InsideEnter = Distance <= Zone.EnterRadius
		local InsideExit = Distance <= Zone.ExitRadius

		local IsLoop = Zone.EmitterKind == "Loop"
		local ChannelId = Zone.ChannelId
		local IsLinked = IsLoop and (ChannelId ~= nil)

		-- Determine if this zone should be active
		local ShouldBeActive = false
		if IsLinked then
			-- Channel-linked zone: active if it's the winner for its channel
			ShouldBeActive = ChannelWinners[ChannelId] == Zone
		else
			-- Independent zone: use normal proximity logic
			ShouldBeActive = IsLoop and InsideEnter
		end

		if IsLoop then
			if Zone.State == "OUT" then
				if ShouldBeActive then
					Zone.State = "IN"

					if IsLinked then
						-- Get or create channel sound
						local SoundData = EnsureChannelSound(ChannelId, Zone.SoundType, Position)
						if SoundData then
							Zone.ActiveSound = SoundData
							-- Update channel position target
							UpdateChannelPosition(ChannelId, Position, DeltaTime)
						end
					else
						-- Create independent sound
						TriggerSoundManager.EnsureCapacityForTrigger()
						local SoundData = TriggerSoundManager.CreateSound(Zone.SoundType, Position, Zone.Part)
						if SoundData then
							SoundData.Sound:Play()
							table.insert(Core.ActiveTriggers, SoundData)
							Zone.ActiveSound = SoundData
						end
					end
				end

			elseif Zone.State == "IN" then
				local SoundData = Zone.ActiveSound

				if SoundData then
					if IsLinked then
						-- Update channel position if we're still the winner
						if ShouldBeActive then
							UpdateChannelPosition(ChannelId, Position, DeltaTime)
						end
					else
						-- Direct position update for unlinked sounds
						SoundData.Position = Position
						if SoundData.SoundContainer then 
							SoundData.SoundContainer.CFrame = CFrame.new(Position) 
						end
					end

					-- Calculate volume based on distance from sound to player
					local SoundPosition = if IsLinked and ChannelPositions[ChannelId] 
						then ChannelPositions[ChannelId].Current 
						else Position
					local SoundDistance = (SoundPosition - PlayerPosition).Magnitude
					SoundData.TargetVolume = Utils.CalcFade(SoundDistance, Zone.EnterRadius, Zone.FadeDistance, Zone.Volume)
				end

				-- Check if we should start leaving
				if not ShouldBeActive then
					Zone.State = "LEAVING"
					Zone._exitTimer = Core.TRIGGER_EXIT_GRACE
				end

			elseif Zone.State == "LEAVING" then
				if ShouldBeActive then
					-- Re-entered, go back to IN state
					Zone.State = "IN"
					Zone._exitTimer = 0

					-- For linked zones, make sure we have the channel sound reference
					if IsLinked and ChannelSounds[ChannelId] then
						Zone.ActiveSound = ChannelSounds[ChannelId]
					end
				else
					-- Continue leaving countdown
					Zone._exitTimer -= DeltaTime
					if Zone.ActiveSound and not IsLinked then
						-- Only fade independent sounds; channel sounds are handled separately
						Zone.ActiveSound.TargetVolume = 0 
					end

					if Zone._exitTimer <= 0 then
						Zone.State = "OUT"
						if not IsLinked then
							Zone.ActiveSound = nil
						end
						Zone._exitTimer = 0
					end
				end
			end
		end
	end

	-- Handle channel sound cleanup - only fade out channels that have no active zones
	for ChannelId, SoundData in pairs(ChannelSounds) do
		local HasActiveZone = false

		-- Check if any zone is actively using this channel
		for _, Zone in ipairs(Core.TriggerZones) do
			if Zone.ChannelId == ChannelId and Zone.State == "IN" and ChannelWinners[ChannelId] == Zone then
				HasActiveZone = true
				break
			end
		end

		if not HasActiveZone then
			-- No zones are actively using this channel, start fading out
			SoundData.TargetVolume = 0
		end
	end
end

-- Commit volume changes and clean up finished sounds
function TriggerEngine.CommitVolumes(DeltaTime: number): ()
	TriggerSoundManager.CommitVolumes(DeltaTime)

	-- Clean up channel sounds that have faded out completely
	for ChannelId, SoundData in pairs(ChannelSounds) do
		if SoundData.CurrentVolume <= 0.001 and SoundData.TargetVolume <= 0.001 then
			-- Remove from active triggers
			for i = #Core.ActiveTriggers, 1, -1 do
				if Core.ActiveTriggers[i] == SoundData then
					table.remove(Core.ActiveTriggers, i)
					break
				end
			end

			-- Destroy sound
			pcall(function() SoundData.Sound:Stop() end)
			if SoundData.SoundContainer and SoundData.SoundContainer.Parent then 
				SoundData.SoundContainer:Destroy() 
			end

			-- Clear channel references
			ChannelSounds[ChannelId] = nil
			ChannelPositions[ChannelId] = nil
			ChannelLastWinner[ChannelId] = nil

			-- Clear zone references
			for _, Zone in ipairs(Core.TriggerZones) do
				if Zone.ActiveSound == SoundData then
					Zone.ActiveSound = nil
					if Zone.State ~= "OUT" then
						Zone.State = "OUT"
						Zone._exitTimer = 0
					end
				end
			end
		end
	end

	-- Clean up zone references for destroyed non-channel sounds
	for _, Zone in ipairs(Core.TriggerZones) do
		if Zone.ActiveSound and not Zone.ChannelId then
			local Found = false
			for _, SoundData in ipairs(Core.ActiveTriggers) do
				if SoundData == Zone.ActiveSound then
					Found = true
					break
				end
			end
			if not Found then
				Zone.ActiveSound = nil
				Zone.State = "OUT"
				Zone._exitTimer = 0
			end
		end
	end
end

-- Clean up all trigger-related state
function TriggerEngine.Cleanup(): ()
	-- Clean up channel sounds
	for ChannelId, SoundData in pairs(ChannelSounds) do
		pcall(function() SoundData.Sound:Stop() end)
		if SoundData.SoundContainer and SoundData.SoundContainer.Parent then 
			SoundData.SoundContainer:Destroy() 
		end
	end
	table.clear(ChannelSounds)
	table.clear(ChannelPositions)
	table.clear(ChannelLastWinner)

	TriggerSoundManager.Cleanup()
	table.clear(Core.TriggerZones)
end

return TriggerEngine