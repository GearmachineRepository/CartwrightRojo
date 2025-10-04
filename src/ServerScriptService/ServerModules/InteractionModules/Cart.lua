--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CartModules = script.Parent:WaitForChild("CartModules")
local SoundModule = require(Modules:WaitForChild("SoundPlayer"))
local CartStateManager = require(CartModules:WaitForChild("CartStateManager"))
local OwnershipManager = require(Modules:WaitForChild("OwnershipManager"))
local PhysicsGroups = require(Modules:WaitForChild("PhysicsGroups"))

local Events = ReplicatedStorage:WaitForChild("Events")
local CartEvents = Events:WaitForChild("CartEvents")
local attachCartEvent = CartEvents:WaitForChild("AttachCart")
local detachCartEvent = CartEvents:WaitForChild("DetachCart")
local updateCartEvent = CartEvents:WaitForChild("UpdateCart")
local updateWheelHeightEvent = CartEvents:WaitForChild("UpdateWheelHeight")

local CART_TAG = "Cart"
local UPDATE_RATE = 0.1

-- Remote Event: Client requests to attach cart
attachCartEvent.OnServerEvent:Connect(function(player: Player, actionOrCart, maybeCart: Model?)
	local action: string?, cart: Model?
	if typeof(actionOrCart) == "string" then
		action = actionOrCart
		cart = maybeCart
	else
		return
	end

	if action ~= "REQUEST" then return end
	if not cart then return end

	-- Attempt to attach using CartStateManager
	local success = CartStateManager.AttachCart(player, cart)

	if success then
		-- Owner builds visual
		attachCartEvent:FireClient(player, "CONFIRM_OWNER", cart)

		-- Spectators replicate
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				attachCartEvent:FireClient(other, "REPLICATE_OTHERS", player, cart)
			end
		end
	end
end)

-- Remote Event: Client requests to detach cart
detachCartEvent.OnServerEvent:Connect(function(player: Player)
	local success, cart = CartStateManager.DetachCart(player)

	if success and cart then
		print("[CartServer] Detaching cart for:", player.Name, "Cart:", cart.Name)
		-- Inform all clients with both player AND cart
		detachCartEvent:FireAllClients(player, cart)
	end
end)

-- Remote Event: Owner sends position updates
updateCartEvent.OnServerEvent:Connect(function(player: Player, cartCFrame: CFrame, _: number?)
	local data = CartStateManager.GetPlayerData(player)
	if not data or not data.IsOwner then return end

	local now = tick()
	if now - (data.LastUpdateTime or 0) < UPDATE_RATE then return end
	data.LastUpdateTime = now

	CartStateManager.UpdateCartPosition(player, cartCFrame)
end)

-- Remote Event: Wheel diameter updates from client
updateWheelHeightEvent.OnServerEvent:Connect(function(player: Player, cart: Model, wheelDiameter: number)
	CartStateManager.UpdateWheelDiameter(player, cart, wheelDiameter)
end)

-- Player cleanup
Players.PlayerRemoving:Connect(function(player)
	CartStateManager.CleanupPlayer(player)
end)

-- Late join replication
Players.PlayerAdded:Connect(function(newPlayer)
	task.wait(2)

	local attachments = CartStateManager.GetAllAttachments()
	for owner, cart in pairs(attachments) do
		attachCartEvent:FireClient(newPlayer, "REPLICATE_OTHERS", owner, cart)
	end
end)

-- Interaction Functions (for ObjectDatabase integration)
return {
	StateAFunction = function(player: Player, object: Instance, config: any)
		if object:IsA("Model") and CollectionService:HasTag(object, CART_TAG) then
			local ownerId = object:GetAttribute("Owner")
			if ownerId and ownerId ~= player.UserId then return end

			object:SetAttribute("Owner", player.UserId)
			object:SetAttribute("Type", "Cart")

            OwnershipManager.TrackOwnership(object, player.UserId)
            PhysicsGroups.SetToGroup(object, "Dragging")

			-- Invite owner to request attach
			attachCartEvent:FireClient(player, object)
			if config and config.InteractionSound then
				SoundModule.PlaySound(config.InteractionSound, object.PrimaryPart)
			end
		end
	end,

	StateBFunction = function(player: Player, object: Instance, config: any)
		if object:IsA("Model") then
			if object:GetAttribute("AttachedTo") == player.Name then
				local success, cart = CartStateManager.DetachCart(player)

				if success and cart then
					-- Inform all clients
					detachCartEvent:FireAllClients(player, cart)
                    OwnershipManager.UpdateInteractionTime(object)
           			PhysicsGroups.SetToGroup(object, "Static")

					if config and config.ReleaseSound then
						SoundModule.PlaySound(config.ReleaseSound, object.PrimaryPart)
					end
				end
			end
		end
	end
}