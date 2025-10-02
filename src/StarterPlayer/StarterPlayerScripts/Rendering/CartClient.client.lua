--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CartConfigurations = require(Modules:WaitForChild("CartConfigurations"))

local Events = ReplicatedStorage:WaitForChild("Events")
local CartEvents = Events:WaitForChild("CartEvents")
local attachCartEvent = CartEvents:WaitForChild("AttachCart")
local detachCartEvent = CartEvents:WaitForChild("DetachCart")
local updateCartEvent = CartEvents:WaitForChild("UpdateCart")
local updateWheelHeightEvent = CartEvents:WaitForChild("UpdateWheelHeight")

local SERVER_UPDATE_INTERVAL = 0.1
local MAX_RENDER_DISTANCE = 500
local HIGH_DETAIL_DISTANCE = 100
local MEDIUM_DETAIL_DISTANCE = 250

type CartData = {
	ServerCart: Model?,
	VisualCart: Model?,
	UpdateConnection: RBXScriptConnection?,
	ServerUpdateConnection: RBXScriptConnection?,
	ClientUpdateConnection: RBXScriptConnection?,
	OrientationConnection: RBXScriptConnection?,
	LastTiltAngle: number,
	CartLength: number?,
	LastServerUpdate: number?,
	LastPosition: Vector3?,
	WheelRotation: number,
	IsOwner: boolean?,
	WheelMotor: Motor6D?,
	WagonMotor: Motor6D?,
	Config: {[string]: any}?,
	DistanceToLocalPlayer: number?,
	DetailLevel: string?,
	AlignOrientation: AlignOrientation?,
	Attachment: Attachment?
}
local ClientCartData: {[Player]: CartData} | {} = {}

local originalMouseSensitivity: number?
local originalShiftLockAttribute: boolean?
local originalWalkSpeed: number?
local originalAutoRotate: boolean?

local LastWheelDiameter: number = 0

local function GetDistanceToPlayer(position: Vector3): number
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return math.huge end
	return (position - rootPart.Position).Magnitude
end

local function GetDetailLevel(distance: number): string
	if distance > MAX_RENDER_DISTANCE then
		return "CULLED"
	elseif distance <= HIGH_DETAIL_DISTANCE then
		return "HIGH"
	elseif distance <= MEDIUM_DETAIL_DISTANCE then
		return "MEDIUM"
	else
		return "LOW"
	end
end

local function GetCartLength(cart: Model): number
	local _, size = cart:GetBoundingBox()
	return size.Z * 0.5
end

local function GetAverageWheelDiameter(cart: Model): number
	local diameters = {}

	for _, descendant in ipairs(cart:GetDescendants()) do
		if descendant:IsA("Model") and descendant:GetAttribute("PartType") == "Wheel" then
			local _, size = descendant:GetBoundingBox()
			local diameter = math.max(size.X, size.Z)
			table.insert(diameters, diameter)
		end
	end

	if #diameters == 0 then
		return 4
	end

	local sum = 0
	for _, diameter in ipairs(diameters) do
		sum += diameter
	end
	return sum / #diameters
end

local function CloneVisualCart(serverCart: Model): Model?
	if not serverCart or not serverCart.Parent then
		warn("Server cart not found or not in workspace")
		return nil
	end

	local visualCart = serverCart:Clone()
	visualCart.Name = serverCart.Name .. "_Visual"
	visualCart.Parent = workspace

	CollectionService:RemoveTag(visualCart, "Cart")
	CollectionService:RemoveTag(visualCart, "Interactable")
	CollectionService:RemoveTag(visualCart, "Drag")
	CollectionService:RemoveTag(visualCart, "StateMachine")

	for _, d: any in pairs(visualCart:GetDescendants()) do
		if d:IsA("Instance") then
			CollectionService:RemoveTag(d, "Cart")
			CollectionService:RemoveTag(d, "Interactable")
			CollectionService:RemoveTag(d, "Drag")
			CollectionService:RemoveTag(d, "StateMachine")
		end

		if d:IsA("BillboardGui") or d:IsA("SurfaceGui") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
			d:Destroy()
		end

		if d:IsA("BasePart") then
			local ot = d:GetAttribute("OriginalTransparency")
			if ot ~= nil then 
				d.Transparency = ot
				d:SetAttribute("OriginalTransparency", nil)
			end
			local occ = d:GetAttribute("OriginalCanCollide")
			if occ ~= nil then 
				d.CanCollide = occ
				d:SetAttribute("OriginalCanCollide", nil)
			end
			local ocq = d:GetAttribute("OriginalCanQuery")
			if ocq ~= nil then 
				d.CanQuery = ocq
				d:SetAttribute("OriginalCanQuery", nil)
			end
			local oci = d:GetAttribute("OriginalCanTouch")
			if oci ~= nil then 
				d.CanTouch = oci
				d:SetAttribute("OriginalCanTouch", nil)
			end
		end

		if d:IsA("Decal") or d:IsA("Texture") then
			local ot = d:GetAttribute("OriginalTransparency")
			if ot ~= nil then
				d.Transparency = ot
				d:SetAttribute("OriginalTransparency", nil)
			end
		end
	end

	CollectionService:AddTag(visualCart, "VisualCart")

	if visualCart.PrimaryPart then
		visualCart.PrimaryPart.Anchored = true
	end

	return visualCart
end

local function UpdateCartPhysics(targetPlayer: Player, data: CartData, isOwner: boolean)
	if not data.VisualCart or not data.Config then return end
	local character: Model? = targetPlayer.Character
	if not character then return end
	local rootPart: BasePart? = character and character:FindFirstChild("HumanoidRootPart") :: BasePart
	local cartPart = data.VisualCart.PrimaryPart
	if not rootPart or not cartPart then return end

	local playerPosition = rootPart.Position
	local playerLookVector = rootPart.CFrame.LookVector

	cartPart.CFrame = rootPart.CFrame

	local cartBackPosition = playerPosition - (playerLookVector * (data.CartLength :: number))

	local wheelDiameter = GetAverageWheelDiameter(data.VisualCart)
	local wheelRadius = (wheelDiameter/2) - 0.3
	if LastWheelDiameter ~= wheelDiameter then
		LastWheelDiameter = wheelDiameter
		updateWheelHeightEvent:FireServer(data.ServerCart, wheelDiameter)
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character, data.VisualCart}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local rayOrigin = cartBackPosition + Vector3.new(0, 5, 0)
	local rayDirection = Vector3.new(0, -data.Config.RAYCAST_DISTANCE, 0)
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)

	if data.WagonMotor then
		if rayResult then
			local backGroundY = rayResult.Position.Y
			local handlesY = playerPosition.Y - data.Config.CART_LIFT_HEIGHT
			local targetBackWheelsY = backGroundY + wheelRadius + data.Config.MIN_WHEEL_CLEARANCE
			local heightDiff = handlesY - targetBackWheelsY
			local targetHingeAngle = math.atan2(heightDiff, (data.CartLength :: number))
			targetHingeAngle = math.clamp(targetHingeAngle, -data.Config.MAX_TILT_ANGLE, data.Config.MAX_TILT_ANGLE)

			local angleDifference = math.abs(targetHingeAngle - data.LastTiltAngle)
			local dynamicAlpha = data.Config.LERP_ALPHA
			if angleDifference > math.rad(30) then
				dynamicAlpha = data.Config.LERP_ALPHA * 2.5
			elseif angleDifference > math.rad(15) then
				dynamicAlpha = data.Config.LERP_ALPHA * 1.5
			end

			local smoothedAngle = data.LastTiltAngle + (targetHingeAngle - data.LastTiltAngle) * dynamicAlpha

			local actualBackWheelY = playerPosition.Y - data.Config.CART_LIFT_HEIGHT + ((data.CartLength :: number) * math.sin(-smoothedAngle))
			local additionalLift = 0
			local requiredWheelBottomY = backGroundY + data.Config.MIN_WHEEL_CLEARANCE
			local actualWheelBottomY = actualBackWheelY - data.Config.WHEEL_RADIUS
			if actualWheelBottomY < requiredWheelBottomY then
				additionalLift = (requiredWheelBottomY - actualWheelBottomY)
			end

			local wagonRelativePos = Vector3.new(0, -(data.Config.CART_LIFT_HEIGHT - additionalLift), 0)
			local wagonOffset = CFrame.new(wagonRelativePos) * CFrame.Angles(-smoothedAngle, 0, 0)
			data.WagonMotor.C1 = wagonOffset
			data.LastTiltAngle = smoothedAngle
		else
			local targetAngle = 0
			local smoothedAngle = data.LastTiltAngle + (targetAngle - data.LastTiltAngle) * data.Config.LERP_ALPHA
			local wagonRelativePos = Vector3.new(0, -data.Config.CART_LIFT_HEIGHT, 0)
			local wagonOffset = CFrame.new(wagonRelativePos) * CFrame.Angles(-smoothedAngle, 0, 0)
			data.WagonMotor.C1 = wagonOffset
			data.LastTiltAngle = smoothedAngle
		end
	end

	if data.WheelMotor then
		local currentPosition = playerPosition
		local distanceTraveled = (currentPosition - (data.LastPosition or currentPosition)).Magnitude
		data.LastPosition = currentPosition

		local rotationAmount = distanceTraveled / (wheelRadius * math.pi)
		data.WheelRotation += rotationAmount
		data.WheelMotor.C1 = CFrame.Angles(0, 0, -data.WheelRotation)

		if isOwner then
			local MoveSound = cartPart and cartPart:FindFirstChild("MoveSound") :: Sound
			local Humanoid = character:FindFirstChild("Humanoid") :: Humanoid
			if MoveSound and Humanoid then
				MoveSound.Playing = Humanoid.MoveDirection.Magnitude > 0
				MoveSound.PlaybackSpeed = 1 * (rootPart.AssemblyLinearVelocity.Magnitude/10)
			end
		end
	end
end

local function UpdateCartDetailLevels()
	for targetPlayer, data in pairs(ClientCartData) do
		if data.VisualCart and not data.IsOwner then
			local cartPart = data.VisualCart.PrimaryPart
			if cartPart then
				local distance = GetDistanceToPlayer(cartPart.Position)
				local newDetailLevel = GetDetailLevel(distance)
				data.DistanceToLocalPlayer = distance

				if data.DetailLevel ~= newDetailLevel then
					data.DetailLevel = newDetailLevel
					if data.ClientUpdateConnection then
						data.ClientUpdateConnection:Disconnect()
						data.ClientUpdateConnection = nil :: any
					end

					if newDetailLevel == "CULLED" then
						data.VisualCart.Parent = nil
					else
						if not data.VisualCart.Parent then
							data.VisualCart.Parent = workspace
						end
						if newDetailLevel == "HIGH" or newDetailLevel == "MEDIUM" then
							data.ClientUpdateConnection = RunService.RenderStepped:Connect(function()
								UpdateCartPhysics(targetPlayer, data :: any, false)
							end)
						end
					end
				end
			end
		end
	end
end

local function UpdateAlignOrientation(data: CartData)
	if not data.AlignOrientation or not data.Attachment then return end
	
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not humanoid or not rootPart then return end
	
	local isMoving = humanoid.MoveDirection.Magnitude > 0.1
	local camera = workspace.CurrentCamera
	local isFirstPerson = camera and (camera.CFrame.Position - rootPart.Position).Magnitude < 2
	
	if isMoving or isFirstPerson then
		local targetCFrame: CFrame
		if isFirstPerson then
			targetCFrame = camera.CFrame
		else
			targetCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + humanoid.MoveDirection)
		end
		data.AlignOrientation.CFrame = targetCFrame
	else
		data.AlignOrientation.CFrame = data.Attachment.WorldCFrame
	end
end

local function ApplyCartCameraSettings(config: {[string]: any})
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid") :: Humanoid

	if not originalMouseSensitivity then 
		originalMouseSensitivity = UserInputService.MouseDeltaSensitivity 
	end
	if originalShiftLockAttribute == nil then
		originalShiftLockAttribute = player:GetAttribute("ShiftLockEnabled")
		if originalShiftLockAttribute == nil then 
			originalShiftLockAttribute = true 
		end
	end
	if humanoid then
		if not originalWalkSpeed then 
			originalWalkSpeed = humanoid.WalkSpeed 
		end
		if originalAutoRotate == nil then
			originalAutoRotate = humanoid.AutoRotate
		end
	end

	UserInputService.MouseDeltaSensitivity = config.CAMERA_SENSITIVITY
	player:SetAttribute("ShiftLockEnabled", false)
	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	if humanoid then
		humanoid.WalkSpeed = math.max(0, humanoid.WalkSpeed - config.WALKSPEED_REDUCTION)
		humanoid.AutoRotate = false
	end
end

local function RestoreNormalCameraSettings()
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid") :: Humanoid

	if originalMouseSensitivity then 
		UserInputService.MouseDeltaSensitivity = originalMouseSensitivity
	end
	if originalShiftLockAttribute ~= nil then 
		player:SetAttribute("ShiftLockEnabled", originalShiftLockAttribute)
	end
	if humanoid then
		if originalWalkSpeed then 
			humanoid.WalkSpeed = originalWalkSpeed 
		end
		if originalAutoRotate ~= nil then
			humanoid.AutoRotate = originalAutoRotate
		end
	end

	originalMouseSensitivity = nil
	originalShiftLockAttribute = nil
	originalWalkSpeed = nil
	originalAutoRotate = nil
end

local function DetachCartClient(targetPlayer: Player)
	local data = ClientCartData[targetPlayer]
	if not data then 
		warn("[CartClient] No data found for player:", targetPlayer.Name)
		return 
	end

	if data.UpdateConnection then 
		data.UpdateConnection:Disconnect()
		data.UpdateConnection = nil 
	end
	if data.ServerUpdateConnection then 
		data.ServerUpdateConnection:Disconnect()
		data.ServerUpdateConnection = nil 
	end
	if data.ClientUpdateConnection then 
		data.ClientUpdateConnection:Disconnect()
		data.ClientUpdateConnection = nil 
	end
	if data.OrientationConnection then
		data.OrientationConnection:Disconnect()
		data.OrientationConnection = nil
	end

	if data.AlignOrientation then
		data.AlignOrientation:Destroy()
		data.AlignOrientation = nil
	end
	if data.Attachment then
		data.Attachment:Destroy()
		data.Attachment = nil
	end

	if data.VisualCart then 
		data.VisualCart:Destroy()
		data.VisualCart = nil 
	end

	if targetPlayer == player and data.IsOwner then
		RestoreNormalCameraSettings()
	end

	ClientCartData[targetPlayer] = nil
end

local function AttachCartClient(serverCart: Model)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart
	local Humanoid = character and character:FindFirstChild("Humanoid") :: Humanoid
	if not rootPart or not Humanoid then return end

	if ClientCartData[player] and ClientCartData[player].ServerCart == serverCart then
		return
	end

	local config = CartConfigurations.GetConfig(serverCart)
	local visualCart = CloneVisualCart(serverCart)
	if not visualCart then return end

	local data = ClientCartData[player] or {}
	ClientCartData[player] = data

	data.ServerCart = serverCart
	data.VisualCart = visualCart
	data.CartLength = GetCartLength(visualCart)
	data.LastTiltAngle = 0
	data.LastServerUpdate = 0
	data.LastPosition = rootPart.Position
	data.WheelRotation = 0
	data.IsOwner = true
	data.Config = config

	ApplyCartCameraSettings(config)

	local attachment = Instance.new("Attachment")
	attachment.Name = "CartOrientationAttachment"
	attachment.Parent = rootPart

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "CartAlignOrientation"
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.ReactionTorqueEnabled = true
	alignOrientation.PrimaryAxisOnly = false
	alignOrientation.RigidityEnabled = false
	alignOrientation.MaxAngularVelocity = 15
	alignOrientation.MaxTorque = 5000
	alignOrientation.Responsiveness = 25
	alignOrientation.Parent = rootPart

	data.Attachment = attachment
	data.AlignOrientation = alignOrientation

	data.OrientationConnection = RunService.RenderStepped:Connect(function()
		UpdateAlignOrientation(data)
	end)

	local wagon = visualCart:FindFirstChild("Wagon")
	local wagonRoot = wagon and wagon:FindFirstChild("WagonRoot")
	data.WheelMotor = wagonRoot and wagonRoot:FindFirstChild("WheelMotor")
	data.WagonMotor = visualCart.PrimaryPart and visualCart.PrimaryPart:FindFirstChild("WagonRoot")

	data.UpdateConnection = RunService.RenderStepped:Connect(function()
		if not rootPart.Parent or not visualCart.Parent then
			DetachCartClient(player)
			return
		end
		UpdateCartPhysics(player, data, true)
	end)

	data.ServerUpdateConnection = RunService.Heartbeat:Connect(function()
		local now = tick()
		if now - (data.LastServerUpdate or 0) >= SERVER_UPDATE_INTERVAL then
			data.LastServerUpdate = now
			if data.VisualCart and data.VisualCart.PrimaryPart then
				updateCartEvent:FireServer(data.VisualCart.PrimaryPart.CFrame, data.WheelRotation)
			end
		end
	end)
end

local function AttachCartReplicated(targetPlayer: Player, serverCart: Model)
	local config = CartConfigurations.GetConfig(serverCart)
	local visualCart = CloneVisualCart(serverCart)
	if not visualCart then return end

	local data = ClientCartData[targetPlayer] or {}
	ClientCartData[targetPlayer] = data

	data.ServerCart = serverCart
	data.VisualCart = visualCart
	data.CartLength = GetCartLength(visualCart)
	data.LastTiltAngle = 0
	data.LastPosition = Vector3.new(0, 0, 0)
	data.WheelRotation = 0
	data.IsOwner = false
	data.Config = config
	data.DistanceToLocalPlayer = math.huge
	data.DetailLevel = "LOW"

	local wagon = visualCart:FindFirstChild("Wagon")
	local wagonRoot = wagon and wagon:FindFirstChild("WagonRoot")
	data.WheelMotor = wagonRoot and wagonRoot:FindFirstChild("WheelMotor")
	data.WagonMotor = visualCart.PrimaryPart and visualCart.PrimaryPart:FindFirstChild("WagonRoot")
end

RunService.Heartbeat:Connect(function()
	UpdateCartDetailLevels()
end)

attachCartEvent.OnClientEvent:Connect(function(a, b, c)
	if typeof(a) == "Instance" and a:IsA("Model") then
		local serverCart = a :: Model
		local ownerId = serverCart:GetAttribute("Owner")

		if ownerId == player.UserId then
			attachCartEvent:FireServer("REQUEST", serverCart)
		end
		return
	end

	if typeof(a) == "string" then
		local action = a
		if action == "CONFIRM_OWNER" then
			local serverCart = b :: Model
			AttachCartClient(serverCart)
			return
		elseif action == "REPLICATE_OTHERS" then
			local targetPlayer = b :: Player
			local serverCart = c :: Model
			if targetPlayer ~= player then
				AttachCartReplicated(targetPlayer, serverCart)
			end
			return
		end
	end
end)

detachCartEvent.OnClientEvent:Connect(function(targetPlayer, cart)
	if not targetPlayer then
		for p, data in pairs(ClientCartData) do
			if data.ServerCart == cart then
				targetPlayer = p
				break
			end
		end
	end

	if not targetPlayer then
		warn("[CartClient] Could not determine player for detach event")
		return
	end

	DetachCartClient(targetPlayer)
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		RestoreNormalCameraSettings()
	end
	DetachCartClient(leavingPlayer)
end)

task.spawn(function()
	while true do
		task.wait(5)

		for checkPlayer, data in pairs(ClientCartData) do
			if not checkPlayer.Parent then
				warn("[CartClient] Cleaning up orphaned data for disconnected player")
				DetachCartClient(checkPlayer)
			end

			if data.ServerCart and not data.ServerCart.Parent then
				warn("[CartClient] Server cart missing, cleaning up visual for:", checkPlayer.Name)
				DetachCartClient(checkPlayer)
			end

			if data.VisualCart and not data.VisualCart.Parent then
				warn("[CartClient] Orphaned visual cart detected for:", checkPlayer.Name)
				DetachCartClient(checkPlayer)
			end
		end
	end
end)

local function OnCharacterAdded()
	task.wait(1)
end

if player.Character then
	OnCharacterAdded()
end
player.CharacterAdded:Connect(OnCharacterAdded)