local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")
local FootplantRemotes = Events:WaitForChild("FootplantEvents")
local OnFootPlanted = FootplantRemotes:WaitForChild("OnFootPlanted")

-- Anti-exploit configuration
local FOOTPLANT_COOLDOWN = 0.1 -- Minimum time between footplants (8 footsteps per second max)
local MAX_REQUESTS_PER_SECOND = 10 -- Maximum remote calls per second
local VIOLATION_THRESHOLD = 5 -- How many violations before temporary restrictions
local RESTRICTION_DURATION = 5 -- How long to restrict a player (seconds)

-- Player tracking data
local PlayerData = {}

-- Initialize player data
local function InitializePlayerData(Player: Player)
	PlayerData[Player] = {
		LastFootplantTime = 0,
		RequestTimes = {},
		ViolationCount = 0,
		RestrictedUntil = 0,
		ConsecutiveViolations = 0
	}
end

-- Clean up player data
local function CleanupPlayerData(Player: Player)
	PlayerData[Player] = nil
end

-- Check if player is rate limited
local function IsRateLimited(Player: Player): boolean
	local playerData = PlayerData[Player]
	if not playerData then return true end

	local currentTime = tick()

	-- Check if player is currently restricted
	if currentTime < playerData.RestrictedUntil then
		return true
	end

	-- Clean old request times (only keep last second)
	local requestTimes = playerData.RequestTimes
	local cutoffTime = currentTime - 1

	-- Remove old entries
	for i = #requestTimes, 1, -1 do
		if requestTimes[i] < cutoffTime then
			table.remove(requestTimes, i)
		end
	end

	-- Check if too many requests in the last second
	if #requestTimes >= MAX_REQUESTS_PER_SECOND then
		-- Add violation
		playerData.ViolationCount = playerData.ViolationCount + 1
		playerData.ConsecutiveViolations = playerData.ConsecutiveViolations + 1

		-- Apply temporary restriction if too many violations
		if playerData.ConsecutiveViolations >= VIOLATION_THRESHOLD then
			playerData.RestrictedUntil = currentTime + RESTRICTION_DURATION
			warn("Player " .. Player.Name .. " temporarily restricted for footplant spam")

			-- Reset consecutive violations after restriction
			playerData.ConsecutiveViolations = 0
		end

		return true
	end

	-- Add current request time
	table.insert(requestTimes, currentTime)
	return false
end

-- Validate footplant timing
local function IsValidFootplantTiming(Player: Player, Value: boolean): boolean
	local playerData = PlayerData[Player]
	if not playerData then return false end

	local currentTime = tick()

	-- Only apply cooldown for footplant = true
	if Value == true then
		local timeSinceLastFootplant = currentTime - playerData.LastFootplantTime

		if timeSinceLastFootplant < FOOTPLANT_COOLDOWN then
			-- Too fast, add to violation count
			playerData.ConsecutiveViolations = playerData.ConsecutiveViolations + 1

			if playerData.ConsecutiveViolations >= VIOLATION_THRESHOLD then
				playerData.RestrictedUntil = currentTime + RESTRICTION_DURATION
				warn("Player " .. Player.Name .. " restricted for rapid footplant attempts")
				playerData.ConsecutiveViolations = 0
			end

			return false
		end

		-- Valid timing, reset consecutive violations and update last footplant time
		playerData.ConsecutiveViolations = math.max(0, playerData.ConsecutiveViolations - 1)
		playerData.LastFootplantTime = currentTime
	end

	return true
end

-- Additional validation: Check if player should be able to make footsteps
local function IsPlayerMoving(Player: Player): boolean
	local Character = Player.Character
	if not Character then return false end

	local Humanoid = Character:FindFirstChild("Humanoid")
	local RootPart = Character:FindFirstChild("HumanoidRootPart")

	if not Humanoid or not RootPart then return false end

	-- Check if player is in a state where footsteps make sense
	local state = Humanoid:GetState()
	local validStates = {
		Enum.HumanoidStateType.Running,
		Enum.HumanoidStateType.RunningNoPhysics,
		Enum.HumanoidStateType.Climbing
	}

	local isValidState = false
	for _, validState in ipairs(validStates) do
		if state == validState then
			isValidState = true
			break
		end
	end

	if not isValidState then return false end

	-- Check if player is actually moving
	local velocity = RootPart.AssemblyLinearVelocity
	local speed = velocity.Magnitude

	-- Must be moving at least 1 stud/second to make footsteps
	return speed >= 1
end

OnFootPlanted.OnServerEvent:Connect(function(Player: Player, Value: boolean)
	-- Initialize player data if it doesn't exist
	if not PlayerData[Player] then
		InitializePlayerData(Player)
	end

	local Character = Player.Character
	if not Character then return end

	-- Check rate limiting
	if IsRateLimited(Player) then
		-- Silently ignore - don't give feedback to potential exploiters
		return
	end

	-- Validate footplant timing
	if not IsValidFootplantTiming(Player, Value) then
		-- Invalid timing, ignore request
		Character:SetAttribute("Footplanted", false)
		return
	end

	-- Additional validation: Check if player should be making footsteps
	if Value == true and not IsPlayerMoving(Player) then
		-- Player isn't moving, ignore footplant request
		Character:SetAttribute("Footplanted", false)
		return
	end

	-- All checks passed, apply the footplant
	Character:SetAttribute("Footplanted", Value)
	Character:SetAttribute("FootplantTime", tick())
end)

-- Player management
Players.PlayerAdded:Connect(InitializePlayerData)
Players.PlayerRemoving:Connect(CleanupPlayerData)

-- Initialize existing players
for _, player in pairs(Players:GetPlayers()) do
	InitializePlayerData(player)
end