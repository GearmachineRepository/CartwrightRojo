--!strict
local ObjectValidator = {}

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

export type ValidationResult = {
	IsValid: boolean,
	Reason: string?,
	OwnerName: string?
}

local function IsPositionInTheftZone(position: Vector3): boolean
	for _, part in ipairs(CollectionService:GetTagged("TheftZone")) do
		if part:IsA("BasePart") and part.Parent then
			local isActive = part:GetAttribute("ZoneActive")
			if isActive == nil or isActive == true then
				local partPos = part.Position
				local partSize = part.Size
				
				local min = partPos - (partSize / 2)
				local max = partPos + (partSize / 2)
				
				if position.X >= min.X and position.X <= max.X and
				   position.Y >= min.Y and position.Y <= max.Y and
				   position.Z >= min.Z and position.Z <= max.Z then
					return true
				end
			end
		end
	end
	return false
end

-- Find the owner of an instance by walking up the ancestry tree
local function GetOwningUserId(inst: Instance): number?
	local node: Instance? = inst
	while node and node ~= workspace do
		local owner = node:GetAttribute("Owner")
		if typeof(owner) == "number" then
			return owner
		end
		node = node.Parent
	end
	return nil
end

-- Get owner player name for UI display
local function GetOwnerName(inst: Instance): string?
	local ownerId = GetOwningUserId(inst)
	if not ownerId then return nil end

	local ownerPlayer = Players:GetPlayerByUserId(ownerId)
	if ownerPlayer then
		return ownerPlayer.Name
	end

	return "Player " .. tostring(ownerId)
end

local function CountWheelsOnAnchors(Cart: Model): number
	local Wagon = Cart:FindFirstChild("Wagon")
	if not Wagon or not Wagon:IsA("Model") then return 0 end
	
	local AnchorsFolder = Wagon:FindFirstChild("Anchors")
	if not AnchorsFolder or not AnchorsFolder:IsA("Folder") then return 0 end
	
	local WheelCount = 0
	for _, Anchor in ipairs(AnchorsFolder:GetChildren()) do
		if (Anchor:IsA("Attachment") or Anchor:IsA("BasePart")) and Anchor.Name:match("^Wheel") then
			local OccupantUID = Anchor:GetAttribute("OccupantUID")
			if OccupantUID and OccupantUID ~= "" then
				WheelCount = WheelCount + 1
			end
		end
	end
	
	return WheelCount
end

-- Check if object is in a valid state for interaction
local function IsInValidState(target: Instance, action: string): (boolean, string?)
	-- Objects being dragged by others
	if target:GetAttribute("BeingDragged") then
		local draggedBy = target:GetAttribute("DraggedBy")
		return false, "Being dragged by " .. tostring(draggedBy)
	end

	-- Objects currently interacting (brewing, crafting, etc.)
	if target:GetAttribute("Interacting") then
		return false, "Currently in use"
	end

	-- Brewing stations with active player
	if target:GetAttribute("BrewingPlayer") then
		local brewingPlayer = target:GetAttribute("BrewingPlayer")
		return false, "Being used by " .. tostring(brewingPlayer)
	end

	-- Snapped to grid (for drag actions only)
	if action == "drag" and target:GetAttribute("SnappedToGrid") then
		-- Allow if we're going to unsnap it
		return true
	end

	-- Carts in use
	if action == "drag" and target:GetAttribute("InUse") then
		local attachedTo = target:GetAttribute("AttachedTo")
		return false, "Cart in use by " .. tostring(attachedTo)
	end

	return true
end

-- Check if player can interact with this object
function ObjectValidator.CanInteract(player: Player, target: Instance): ValidationResult
	-- Check state first
	local stateValid, stateReason = IsInValidState(target, "interact")
	if not stateValid then
		return {
			IsValid = false,
			Reason = stateReason
		}
	end

	-- Objects without owners are fair game
	local ownerId = GetOwningUserId(target)
	if not ownerId then
		return {IsValid = true}
	end

	-- Player must match owner
	if ownerId ~= player.UserId then
		return {
			IsValid = false,
			Reason = "Owned by another player",
			OwnerName = GetOwnerName(target)
		}
	end

	return {IsValid = true}
end

-- Check if player can drag this object
function ObjectValidator.CanDrag(player: Player, target: Instance): ValidationResult
	if player:GetAttribute("Carting") then
		return {
			IsValid = false,
			Reason = "Cannot drag while pulling a cart"
		}
	end

	local stateValid, stateReason = IsInValidState(target, "drag")
	if not stateValid then
		return {
			IsValid = false,
			Reason = stateReason
		}
	end

	local ownershipCheck = ObjectValidator.CanInteract(player, target)
	
	if not ownershipCheck.IsValid then
		local isInTheftZone = false
		
		if target:IsA("Model") then
			local primaryPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
			if primaryPart then
				isInTheftZone = IsPositionInTheftZone(primaryPart.Position)
			end
		elseif target:IsA("BasePart") then
			isInTheftZone = IsPositionInTheftZone(target.Position)
		end
		
		local parentCart = nil
		local node = target.Parent
		while node and node ~= workspace do
			if node:IsA("Model") and (node:GetAttribute("Type") == "Cart" or node:HasTag("Cart")) then
				parentCart = node
				break
			end
			node = node.Parent
		end
		
		if isInTheftZone then
			if not parentCart or not parentCart:GetAttribute("InUse") then
				return {
					IsValid = true,
					Reason = "Theft allowed in this zone"
				}
			else
				return {
					IsValid = false,
					Reason = "Cannot steal from cart being towed"
				}
			end
		end
		
		return ownershipCheck
	end
	
	return ownershipCheck
end

-- Check if player can highlight/select (visual feedback only)
function ObjectValidator.CanHighlight(_: Player, target: Instance): ValidationResult
	-- Players can ALWAYS highlight to see ownership
	-- This allows non-owners to see "who owns this"
	return {
		IsValid = true,
		OwnerName = GetOwnerName(target)
	}
end

-- Check if player can snap to this placement cell/station
function ObjectValidator.CanSnapToStation(player: Player, cell: BasePart): ValidationResult
	-- Walk up to find the station/cart that owns this cell
	local station: Model? = nil
	local node = cell.Parent

	while node and node ~= workspace do
		if node:IsA("Model") and (node:GetAttribute("Type") == "Cart" or node:HasTag("Cart")) then
			station = node
			break
		end
		node = node.Parent
	end

	if not station then
		return {IsValid = true}
	end

	return ObjectValidator.CanInteract(player, station)
end

-- Check if player can attach wheel to this cart
function ObjectValidator.CanAttachWheel(Player: Player, Cart: Model, Wheel: Model): ValidationResult
	local CartValidation = ObjectValidator.CanInteract(Player, Cart)
	if not CartValidation.IsValid then
		return CartValidation
	end

	local WheelOwnerId = GetOwningUserId(Wheel)
	if WheelOwnerId and WheelOwnerId ~= Player.UserId then
		return {
			IsValid = false,
			Reason = "Wheel owned by another player",
			OwnerName = GetOwnerName(Wheel)
		}
	end

	return {IsValid = true}
end

-- Check if object meets prerequisites for an action
function ObjectValidator.MeetsPrerequisites(Target: Instance, Action: string): ValidationResult
	if Action == "pull_cart" then
		if not Target:IsA("Model") then
			return {IsValid = false, Reason = "Not a valid cart"}
		end

		local WheelCount = CountWheelsOnAnchors(Target)

		if WheelCount < 2 then
			return {
				IsValid = false,
				Reason = "Cart needs at least 2 wheels on anchor points"
			}
		end
	end

	if Action == "brew" then
		return {IsValid = true}
	end

	return {IsValid = true}
end

-- Check if object should show interaction prompt
function ObjectValidator.ShouldShowPrompt(player: Player, target: Instance): ValidationResult
	-- Always show prompts for owned objects
	local validation = ObjectValidator.CanInteract(player, target)
	if validation.IsValid then
		return {IsValid = true}
	end

	-- Show "owned by X" prompt for non-owned objects
	local ownerName = GetOwnerName(target)
	if ownerName then
		return {
			IsValid = false,
			Reason = "Owned",
			OwnerName = ownerName
		}
	end

	-- Show state-based messages
	if target:GetAttribute("BeingDragged") then
		return {
			IsValid = false,
			Reason = "Being dragged"
		}
	end

	if target:GetAttribute("InUse") then
		return {
			IsValid = false,
			Reason = "In use"
		}
	end

	return validation
end

-- Get detailed validation info for UI
function ObjectValidator.GetValidationInfo(player: Player, target: Instance, action: string): ValidationResult
	local validation: ValidationResult

	if action == "drag" then
		validation = ObjectValidator.CanDrag(player, target)
	elseif action == "interact" then
		validation = ObjectValidator.CanInteract(player, target)
	elseif action == "highlight" then
		validation = ObjectValidator.CanHighlight(player, target)
	else
		validation = {IsValid = false, Reason = "Unknown action"}
	end

	-- Add owner info if available
	if not validation.OwnerName then
		validation.OwnerName = GetOwnerName(target)
	end

	return validation
end

return ObjectValidator