--!strict

local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)
local TriggerTypes = require(script.Parent.TriggerTypes)

type TriggerZone = TriggerTypes.TriggerZone
type ChannelState = TriggerTypes.ChannelState
type WinnerInfo = TriggerTypes.WinnerInfo

local TriggerWinnerSelection = {}

-- Configuration
local WINNER_HYSTERESIS = 3.0 -- Studs - current winner must be beaten by this margin
local DISTANCE_EPSILON = 0.01 -- Smaller epsilon for more precise comparisons
local MAX_WINNER_DISTANCE = 2.0 -- Maximum distance change per frame to prevent teleports

-- Calculate emitter position for a zone
local function GetEmitterPosition(Zone: TriggerZone, PlayerPosition: Vector3): Vector3
	local Part = Zone.Part

	-- Exact center of the trigger part
	if Zone.EmitterMode == "Center" then
		return Part.Position
	end

	-- Centerline along the long axis (non-spheres)
	if Zone.EmitterMode == "CenterLine" and (not Part.Shape or Part.Shape ~= Enum.PartType.Ball) then
		local T = Zone.RodT
		if T == nil then 
			T = Utils.RodTFor(Part, PlayerPosition)
			Zone.RodT = T 
		end
		return Utils.PosFromRodT(Part, T)
	end

	-- Fallback: nearest point on the volume
	return Utils.NearestPoint(Part, PlayerPosition)
end

-- Update rod position with smooth following for zones that use CenterLine
function TriggerWinnerSelection.UpdateRodPositions(Zones: {TriggerZone}, PlayerPosition: Vector3): ()
	for _, Zone in ipairs(Zones) do
		if Zone.EmitterMode == "CenterLine" then
			local T = Utils.RodTFor(Zone.Part, PlayerPosition)
			Zone.RodT = Zone.RodT and (Zone.RodT + (T - Zone.RodT) * 0.35) or T
		end
	end
end

-- Find the best path through connected zones
local function FindBestPath(Candidates: {WinnerInfo}, CurrentWinner: WinnerInfo?, PlayerPosition: Vector3): WinnerInfo
	if #Candidates == 0 then
		error("FindBestPath called with empty candidates")
	end

	-- If no current winner, just pick the closest
	if not CurrentWinner then
		table.sort(Candidates, function(a, b) return a.Distance < b.Distance end)
		return Candidates[1]
	end

	-- Check if current winner is still valid
	local CurrentWinnerStillValid = false
	for _, Candidate in ipairs(Candidates) do
		if Candidate.Zone == CurrentWinner.Zone then
			CurrentWinnerStillValid = true
			break
		end
	end

	-- If current winner is no longer in range, find closest alternative
	if not CurrentWinnerStillValid then
		table.sort(Candidates, function(a, b) return a.Distance < b.Distance end)
		return Candidates[1]
	end

	-- Current winner is still valid - apply path-finding logic
	local CurrentPosition = GetEmitterPosition(CurrentWinner.Zone, PlayerPosition)
	local BestCandidate = CurrentWinner
	local BestScore = math.huge

	for _, Candidate in ipairs(Candidates) do
		local CandidatePosition = GetEmitterPosition(Candidate.Zone, PlayerPosition)
		local DistanceToPlayer = Candidate.Distance
		local PositionalJump = (CandidatePosition - CurrentPosition).Magnitude

		-- Score based on distance to player + penalty for large positional jumps
		local Score = DistanceToPlayer + (PositionalJump * 2.0)

		-- Heavy penalty for teleport-like jumps
		if PositionalJump > 10.0 then
			Score = Score + 100.0
		end

		-- Apply hysteresis - current winner gets a bonus
		if Candidate.Zone == CurrentWinner.Zone then
			Score = Score - WINNER_HYSTERESIS
		end

		if Score < BestScore then
			BestScore = Score
			BestCandidate = Candidate
		end
	end

	-- Double-check for teleports - if best candidate would cause large jump, try to find closer alternative
	if BestCandidate.Zone ~= CurrentWinner.Zone then
		local BestPosition = GetEmitterPosition(BestCandidate.Zone, PlayerPosition)
		local Jump = (BestPosition - CurrentPosition).Magnitude

		if Jump > MAX_WINNER_DISTANCE then
			-- Look for a candidate that's closer to current position
			for _, Candidate in ipairs(Candidates) do
				local CandidatePosition = GetEmitterPosition(Candidate.Zone, PlayerPosition)
				local CandidateJump = (CandidatePosition - CurrentPosition).Magnitude

				if CandidateJump < Jump and Candidate.Distance <= (BestCandidate.Distance + 5.0) then
					BestCandidate = Candidate
					break
				end
			end
		end
	end

	return BestCandidate
end

-- Compute winners for each channel with improved path-following
function TriggerWinnerSelection.ComputeWinners(
	Zones: {TriggerZone}, 
	ChannelStates: {[string]: ChannelState}, 
	PlayerPosition: Vector3
): {[string]: WinnerInfo}
	local Winners: {[string]: WinnerInfo} = {}

	-- Collect all candidates by channel
	local Candidates: {[string]: {WinnerInfo}} = {}

	for _, Zone in ipairs(Zones) do
		if Zone.EmitterKind ~= "Loop" or not Zone.ChannelId then continue end

		local Position = GetEmitterPosition(Zone, PlayerPosition)
		local Distance = (Position - PlayerPosition).Magnitude

		-- Use the zone's enter radius to determine candidacy
		if Distance <= Zone.EnterRadius then
			local ChannelId = Zone.ChannelId
			if not Candidates[ChannelId] then
				Candidates[ChannelId] = {}
			end
			table.insert(Candidates[ChannelId], {Zone = Zone, Distance = Distance})
		end
	end

	-- Process each channel's candidates with path-finding
	for ChannelId, CandidateList in pairs(Candidates) do
		if #CandidateList == 0 then continue end

		local ChannelState = ChannelStates[ChannelId]
		local CurrentWinner = nil

		-- Get current winner info if available
		if ChannelState and ChannelState.CurrentZone then
			for _, Candidate in ipairs(CandidateList) do
				if Candidate.Zone == ChannelState.CurrentZone then
					CurrentWinner = Candidate
					break
				end
			end
		end

		-- Find the best path through the zones
		local Winner = FindBestPath(CandidateList, CurrentWinner, PlayerPosition)
		Winners[ChannelId] = Winner

		-- Log winner changes for debugging
		if ChannelState and Winner.Zone ~= ChannelState.CurrentZone then
			local CurrentZoneName = ChannelState.CurrentZone and ChannelState.CurrentZone.Part.Name or "nil"
			print(string.format("[WINNER_CHANGE] Channel %s: %s -> %s (distance: %.2f)", 
				ChannelId, CurrentZoneName, Winner.Zone.Part.Name, Winner.Distance))
		end
	end

	-- Handle channels that lost all candidates
	for ChannelId, ChannelState in pairs(ChannelStates) do
		if not Winners[ChannelId] and ChannelState.CurrentZone then
			print(string.format("[NO_WINNER] Channel %s lost all candidates, was %s", 
				ChannelId, ChannelState.CurrentZone.Part.Name))
		end
	end

	return Winners
end

return TriggerWinnerSelection