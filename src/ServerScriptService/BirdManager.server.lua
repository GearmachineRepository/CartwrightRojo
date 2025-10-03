--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local PERCH_TAG = "BirdPerch"
local DETECTION_RANGE = 30
local MIN_PERCH_TIME = 5
local MAX_PERCH_TIME = 15
local MIN_FLY_AWAY_HEIGHT = 25
local MAX_FLY_AWAY_HEIGHT = 90
local FLY_AWAY_SPEED = 25
local RESPAWN_DELAY = 10

local IDLE_BOB_SPEED = 2
local IDLE_BOB_AMOUNT = 0.3

local MIN_SPAWN_DISTANCE = 40
local MAX_SPAWN_DISTANCE = 120

local Birds = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Birds")

local BIRD_MODELS = {
	{ Model = Birds:WaitForChild("Crow"), Weight = 10 }, -- common
	{ Model = Birds:WaitForChild("BlueJay"), Weight = 2 },
}

-- Bird manager
local activeBirds = {}   -- { [perch] = birdData }
local birdFolder = Instance.new("Folder")
birdFolder.Name = "Birds"
birdFolder.Parent = workspace

-- Utility: find all perches in the world
local function findAllPerches()
	local perches = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == PERCH_TAG then
			table.insert(perches, obj)
		end
	end
	return perches
end

local function getWeightedRandomBirdModel()
	local totalWeight = 0
	for _, entry in ipairs(BIRD_MODELS) do
		totalWeight += entry.Weight
	end

	local choice = math.random() * totalWeight
	local cumulative = 0

	for _, entry in ipairs(BIRD_MODELS) do
		cumulative += entry.Weight
		if choice <= cumulative then
			return entry.Model
		end
	end

	-- Fallback
	return BIRD_MODELS[1].Model
end

local function createBirdConstraints(bird, perch)
	local birdAttachment = Instance.new("Attachment")
	birdAttachment.Name = "BirdAttachment"
	birdAttachment.Parent = bird.PrimaryPart

	local perchAttachment = Instance.new("Attachment")
	perchAttachment.Name = "PerchAttachment"
	perchAttachment.WorldPosition = perch.Position + Vector3.new(0, 1, 0)
	perchAttachment.Parent = perch

	local alignPos = Instance.new("AlignPosition")
	alignPos.Attachment0 = birdAttachment
	alignPos.Attachment1 = perchAttachment
	alignPos.MaxForce = 5000
	alignPos.MaxVelocity = 5
	alignPos.Responsiveness = 15
	alignPos.Parent = bird.PrimaryPart

	local alignOrient = Instance.new("AlignOrientation")
	alignOrient.Attachment0 = birdAttachment
	alignOrient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrient.MaxTorque = 1000
	alignOrient.Responsiveness = 15
	alignOrient.Parent = bird.PrimaryPart

	return birdAttachment, perchAttachment, alignPos, alignOrient
end

local function isPlayerNearby(position, range)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (player.Character.HumanoidRootPart.Position - position).Magnitude
			if dist < range then
				return true, player
			end
		end
	end
	return false, nil
end

local function flyAway(birdData, nearbyPlayer)
	if birdData.flyingAway then
		return
	end
	birdData.flyingAway = true

	local bird = birdData.model
	local alignPos = birdData.alignPos
	local alignOrient = birdData.alignOrient
	local birdSound = birdData.birdSound
	local perchAttachment = birdData.perchAttachment
	local birdPos = bird.PrimaryPart.Position

	local fleeDirection
	if nearbyPlayer and nearbyPlayer.Character and nearbyPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local playerPos = nearbyPlayer.Character.HumanoidRootPart.Position
		fleeDirection = (birdPos - playerPos).Unit
	else
		fleeDirection = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit
	end
	
	birdSound:Play()
	
	fleeDirection = (fleeDirection + Vector3.new(
		math.random(-30, 30) / 100,
		0,
		math.random(-30, 30) / 100
		)).Unit

	if alignPos then
		alignPos.MaxVelocity = FLY_AWAY_SPEED - (FLY_AWAY_SPEED * math.random()/2)
		alignPos.Responsiveness = 30
	end

	-- Pick a random fly-away height within range
	local height = math.random(MIN_FLY_AWAY_HEIGHT, MAX_FLY_AWAY_HEIGHT)
	local horizontalDistance = 80
	local targetPos = birdPos + (fleeDirection * horizontalDistance) + Vector3.new(0, height, 0)

	if perchAttachment then
		perchAttachment.WorldPosition = targetPos
	end

	if alignOrient then
		local lookC = CFrame.lookAt(birdPos, targetPos)
		alignOrient.CFrame = lookC * CFrame.Angles(math.rad(10), 0, 0)
	end

	-- Delay then destroy
	local timeout = 10
	local startTime = tick()

	task.spawn(function()
		while tick() - startTime < timeout do
			if not bird or not bird.Parent then break end

			local dist = (bird.PrimaryPart.Position - targetPos).Magnitude
			if dist < 3 then -- close enough
				break
			end

			task.wait(0.1)
		end

		if bird and bird.Parent then
			bird:Destroy()
		end
	end)
	-- Remove from active tracking
	activeBirds[birdData.perch] = nil

	-- Schedule respawn on that perch later
	task.wait(RESPAWN_DELAY)
	if birdData.perch and birdData.perch.Parent then
		spawnBirdOnPerch(birdData.perch)
	end
end

local function idleAnimation(birdData)
	local startTime = tick()
	local bird = birdData.model
	local perchAttachment = birdData.perchAttachment
	local originalPos = birdData.originalPerchPos

	while birdData.perched and bird and bird.Parent do
		-- Check nearby players
		local nearby, player = isPlayerNearby(bird.PrimaryPart.Position, DETECTION_RANGE)
		if nearby then
			flyAway(birdData, player)
			break
		end

		local elapsed = tick() - startTime
		if elapsed > birdData.perchDuration then
			flyAway(birdData, nil)
			break
		end

		if perchAttachment and not birdData.flyingAway then
			local bob = math.sin(tick() * IDLE_BOB_SPEED) * IDLE_BOB_AMOUNT
			perchAttachment.WorldPosition = originalPos + Vector3.new(0, bob, 0)
		end

		task.wait(0.1)
	end
end

function spawnBirdOnPerch(perch)
	-- Check if any player is too close or too far
	local perchPos = perch.Position
	local nearEnough = false
	local tooClose = false

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local dist = (char.HumanoidRootPart.Position - perchPos).Magnitude
			if dist < MIN_SPAWN_DISTANCE then
				tooClose = true
				break
			elseif dist <= MAX_SPAWN_DISTANCE then
				nearEnough = true
			end
		end
	end

	if tooClose or not nearEnough then
		return -- Don't spawn too close or too far
	end

	-- Check if already occupied
	for _, birdData in ipairs(activeBirds) do
		if birdData.perch == perch then
			return -- Already has a bird
		end
	end

	-- Pick a bird model
	local selectedModel = getWeightedRandomBirdModel()
	local bird = selectedModel:Clone()
	bird.Parent = birdFolder

	if not bird.PrimaryPart then
		bird.PrimaryPart = bird:FindFirstChildWhichIsA("BasePart")
	end

	if not bird.PrimaryPart then
		warn("Bird model has no PrimaryPart!")
		bird:Destroy()
		return
	end

	-- Prep parts
	for _, part in ipairs(bird:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Massless = true
			part.CanCollide = false
			part.Anchored = false
		end
	end
	
	local sound = Instance.new("Sound")
	sound.Name = "BirdSound"
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMaxDistance = 75
	sound.RollOffMinDistance = 5
	sound.Volume = 0.75
	sound.SoundGroup = game.SoundService["Sound Effects"]
	sound.SoundId = "rbxassetid://190872950"
	sound.PlaybackSpeed = 1 - ( math.random() / 10 )
	sound.Parent = bird.PrimaryPart

	bird.PrimaryPart.Anchored = true
	bird:PivotTo(perch.CFrame * CFrame.new(0, 1, 0))
	bird.PrimaryPart.Anchored = false

	local birdAttachment, perchAttachment, alignPos, alignOrient = createBirdConstraints(bird, perch)

	local birdData = {
		model = bird,
		perch = perch,
		perched = true,
		flyingAway = false,
		birdSound = sound,
		birdAttachment = birdAttachment,
		perchAttachment = perchAttachment,
		alignPos = alignPos,
		alignOrient = alignOrient,
		originalPerchPos = perch.Position + Vector3.new(0, 1, 0),
		perchDuration = math.random(MIN_PERCH_TIME, MAX_PERCH_TIME)
	}

	table.insert(activeBirds, birdData)

	task.spawn(function()
		idleAnimation(birdData)
	end)
end

task.spawn(function()
	while true do
		local Perches = findAllPerches()

		local ShuffledPerches = table.clone(Perches)
		for CurrentIndex = #ShuffledPerches, 2, -1 do
			local RandomIndex = math.random(1, CurrentIndex)
			ShuffledPerches[CurrentIndex], ShuffledPerches[RandomIndex] = ShuffledPerches[RandomIndex], ShuffledPerches[CurrentIndex]
		end

		for _, Perch in ipairs(ShuffledPerches) do
			spawnBirdOnPerch(Perch)
			break
		end

		task.wait(3 + math.random(0, 3))
	end
end)

workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("BasePart") and obj.Name == PERCH_TAG then
		task.wait(0.5)
		spawnBirdOnPerch(obj)
	end
end)