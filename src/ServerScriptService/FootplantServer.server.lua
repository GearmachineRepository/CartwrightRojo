--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")
local FootplantRemotes = Events:WaitForChild("FootplantEvents")
local OnFootPlanted = FootplantRemotes:WaitForChild("OnFootPlanted")

local FOOTPLANT_COOLDOWN = 0.1
local MAX_REQUESTS_PER_SECOND = 10
local VIOLATION_THRESHOLD = 5
local RESTRICTION_DURATION = 5

local PlayerData = {}

local function InitializePlayerData(Player: Player)
	PlayerData[Player] = {
		LastFootplantTime = 0,
		RequestTimes = {},
		ViolationCount = 0,
		RestrictedUntil = 0,
		ConsecutiveViolations = 0
	}
end

local function CleanupPlayerData(Player: Player)
	PlayerData[Player] = nil
end

local function IsRateLimited(Player: Player): boolean
	local Data = PlayerData[Player]
	if not Data then
		return true
	end

	local CurrentTime = tick()

	if CurrentTime < Data.RestrictedUntil then
		return true
	end

	local RequestTimes = Data.RequestTimes
	local CutoffTime = CurrentTime - 1

	for Index = #RequestTimes, 1, -1 do
		if RequestTimes[Index] < CutoffTime then
			table.remove(RequestTimes, Index)
		end
	end

	if #RequestTimes >= MAX_REQUESTS_PER_SECOND then
		Data.ViolationCount = Data.ViolationCount + 1
		Data.ConsecutiveViolations = Data.ConsecutiveViolations + 1

		if Data.ConsecutiveViolations >= VIOLATION_THRESHOLD then
			Data.RestrictedUntil = CurrentTime + RESTRICTION_DURATION
			warn("Player " .. Player.Name .. " temporarily restricted for footplant spam")
			Data.ConsecutiveViolations = 0
		end

		return true
	end

	table.insert(RequestTimes, CurrentTime)
	return false
end

local function IsValidFootplantTiming(Player: Player, Value: boolean): boolean
	local Data = PlayerData[Player]
	if not Data then
		return false
	end

	local CurrentTime = tick()

	if Value == true then
		local TimeSinceLastFootplant = CurrentTime - Data.LastFootplantTime

		if TimeSinceLastFootplant < FOOTPLANT_COOLDOWN then
			Data.ConsecutiveViolations = Data.ConsecutiveViolations + 1

			if Data.ConsecutiveViolations >= VIOLATION_THRESHOLD then
				Data.RestrictedUntil = CurrentTime + RESTRICTION_DURATION
				warn("Player " .. Player.Name .. " restricted for rapid footplant attempts")
				Data.ConsecutiveViolations = 0
			end

			return false
		end

		Data.ConsecutiveViolations = math.max(0, Data.ConsecutiveViolations - 1)
		Data.LastFootplantTime = CurrentTime
	end

	return true
end

local function IsPlayerMoving(Player: Player): boolean
	local Character = Player.Character
	if not Character then
		return false
	end

	local Humanoid = Character:FindFirstChild("Humanoid")
	local RootPart = Character:FindFirstChild("HumanoidRootPart")

	if not Humanoid or not RootPart then
		return false
	end

	local State = Humanoid:GetState()
	local ValidStates = {
		Enum.HumanoidStateType.Running,
		Enum.HumanoidStateType.RunningNoPhysics,
		Enum.HumanoidStateType.Climbing
	}

	local IsValidState = false
	for _, ValidState in ipairs(ValidStates) do
		if State == ValidState then
			IsValidState = true
			break
		end
	end

	if not IsValidState then
		return false
	end

	local Velocity = RootPart.AssemblyLinearVelocity
	local Speed = Velocity.Magnitude

	return Speed >= 1
end

OnFootPlanted.OnServerEvent:Connect(function(Player: Player, Value: boolean)
	if not PlayerData[Player] then
		InitializePlayerData(Player)
	end

	local Character = Player.Character
	if not Character then
		return
	end

	if IsRateLimited(Player) then
		return
	end

	if not IsValidFootplantTiming(Player, Value) then
		Character:SetAttribute("Footplanted", false)
		return
	end

	if Value == true and not IsPlayerMoving(Player) then
		Character:SetAttribute("Footplanted", false)
		return
	end

	Character:SetAttribute("Footplanted", Value)
	Character:SetAttribute("FootplantTime", tick())
end)

Players.PlayerAdded:Connect(InitializePlayerData)
Players.PlayerRemoving:Connect(CleanupPlayerData)

for _, Player in pairs(Players:GetPlayers()) do
	InitializePlayerData(Player)
end