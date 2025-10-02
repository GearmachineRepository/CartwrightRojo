--!strict
local CartStateManager = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local ObjectStateManager = require(Modules:WaitForChild("ObjectStateManager"))
local CartVisibility = require(script.Parent:WaitForChild("CartVisibility"))
local CartPositioning = require(script.Parent:WaitForChild("CartPositioning"))

local CART_TAG = "Cart"
local DRAG_TAG = "Drag"

type ServerCartData = {
	AttachedCart: Model?,
	LastUpdateTime: number?,
	IsOwner: boolean?,
	LastAttachTime: number?,
	CurrentWheelDiameter: number?
}

local PlayerCartData: {[Player]: ServerCartData} = {}

-- Check if cart can be attached
function CartStateManager.CanAttachCart(player: Player, cart: Model): (boolean, string?)
	if not CollectionService:HasTag(cart, CART_TAG) then
		return false, "Not a valid cart"
	end

	if not cart:IsDescendantOf(workspace) then
		return false, "Cart not in workspace"
	end

	-- Check if cart is already in use
	local currentState = ObjectStateManager.GetState(cart)
	if currentState ~= "Idle" then
		return false, "Cart is already in use"
	end

	-- Check ownership
	local ownerId = cart:GetAttribute("Owner")
	if ownerId and ownerId ~= player.UserId then
		return false, "Cart owned by another player"
	end

	-- Debounce check
	local data = PlayerCartData[player]
	if data and data.LastAttachTime then
		local now = tick()
		if (now - data.LastAttachTime) < 0.5 then
			return false, "Too fast - wait a moment"
		end
	end

	return true
end

-- Attach cart to player
function CartStateManager.AttachCart(player: Player, cart: Model): boolean
	local canAttach, reason = CartStateManager.CanAttachCart(player, cart)
	if not canAttach then
		warn("[CartStateManager] Cannot attach:", reason)
		return false
	end

	-- Drop prior cart if any
	local data = PlayerCartData[player]
	if data and data.AttachedCart then
		CartStateManager.DetachCart(player)
	end

	-- Initialize player data if needed
	if not data then
		data = {}
		PlayerCartData[player] = data
	end

	-- Store attachment data
	data.AttachedCart = cart
	data.LastUpdateTime = 0
	data.IsOwner = true
	data.CurrentWheelDiameter = CartPositioning.GetAverageWheelDiameter(cart)
	data.LastAttachTime = tick()

	-- Set cart state
	ObjectStateManager.SetState(cart, "InUse", {AttachedTo = player.Name})
	cart:SetAttribute("Owner", player.UserId)
	cart:SetAttribute("CurrentState", "StateB")
	player:SetAttribute("Carting", true)

	-- Physical setup
	if cart.PrimaryPart then
		cart.PrimaryPart.Anchored = true
	end

	-- Remove interactable tags while attached
	if CollectionService:HasTag(cart, CART_TAG) then
		CollectionService:RemoveTag(cart, CART_TAG)
	end

	if CollectionService:HasTag(cart, DRAG_TAG) then
		CollectionService:RemoveTag(cart, DRAG_TAG)
	end

	task.wait(0.05)
	CartVisibility.HideCart(cart)

	return true
end

-- Detach cart from player
function CartStateManager.DetachCart(player: Player): (boolean, Model?)
	local data = PlayerCartData[player]
	if not data or not data.AttachedCart then
		return false, nil
	end

	local cart = data.AttachedCart
	local wheelDiameter = data.CurrentWheelDiameter or 4

	-- Clear state
	ObjectStateManager.ForceIdle(cart)
	cart:SetAttribute("CurrentState", "StateA")
	player:SetAttribute("Carting", false)

	-- Show cart
	CartVisibility.ShowCart(cart)

	-- Position at correct height BEFORE unanchoring
	CartPositioning.PositionAtGroundLevel(cart, wheelDiameter)

	-- Unanchor
	if cart.PrimaryPart then
		cart.PrimaryPart.Anchored = false
	end

	-- Clear attachment data
	data.AttachedCart = nil

	-- Re-expose as interactable
	if not CollectionService:HasTag(cart, CART_TAG) then
		CollectionService:AddTag(cart, CART_TAG)
	end

	if not CollectionService:HasTag(cart, DRAG_TAG) then
		CollectionService:AddTag(cart, DRAG_TAG)
	end

	return true, cart
end

-- Update wheel diameter for attached cart
function CartStateManager.UpdateWheelDiameter(player: Player, cart: Model, diameter: number): ()
	local data = PlayerCartData[player]
	if not data or not data.AttachedCart or not data.IsOwner then return end
	if data.AttachedCart ~= cart then return end

	data.CurrentWheelDiameter = diameter
end

-- Update cart position from client
function CartStateManager.UpdateCartPosition(player: Player, cartCFrame: CFrame): ()
	local data = PlayerCartData[player]
	if not data or not data.AttachedCart or not data.IsOwner then return end

	if data.AttachedCart.PrimaryPart then
		data.AttachedCart.PrimaryPart.CFrame = cartCFrame
	end
end

-- Get player's attached cart
function CartStateManager.GetAttachedCart(player: Player): Model?
	local data = PlayerCartData[player]
	return data and data.AttachedCart
end

-- Get all player cart data
function CartStateManager.GetPlayerData(player: Player): ServerCartData?
	return PlayerCartData[player]
end

-- Cleanup player data
function CartStateManager.CleanupPlayer(player: Player): ()
	if PlayerCartData[player] then
		CartStateManager.DetachCart(player)
		PlayerCartData[player] = nil
	end
end

-- Get all active cart attachments (for late-join replication)
function CartStateManager.GetAllAttachments(): {[Player]: Model}
	local attachments: {[Player]: Model} = {}

	for player, data in pairs(PlayerCartData) do
		if data.AttachedCart and data.IsOwner then
			attachments[player] = data.AttachedCart
		end
	end

	return attachments
end

return CartStateManager