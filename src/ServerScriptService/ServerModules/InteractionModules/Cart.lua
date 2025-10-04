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
local GeneralUtil = require(Modules:WaitForChild("GeneralUtil"))

local Events = ReplicatedStorage:WaitForChild("Events")
local CartEvents = Events:WaitForChild("CartEvents")
local AttachCartEvent = CartEvents:WaitForChild("AttachCart")
local DetachCartEvent = CartEvents:WaitForChild("DetachCart")
local UpdateCartEvent = CartEvents:WaitForChild("UpdateCart")
local UpdateWheelHeightEvent = CartEvents:WaitForChild("UpdateWheelHeight")

local CART_TAG = "Cart"

AttachCartEvent.OnServerEvent:Connect(function(Player: Player, ActionOrCart, MaybeCart: Model?)
	local Action: string?
	local Cart: Model?

	if typeof(ActionOrCart) == "string" then
		Action = ActionOrCart
		Cart = MaybeCart
	else
		return
	end

	if Action ~= "REQUEST" then
		return
	end

	if not Cart then
		return
	end

	local Success = CartStateManager.AttachCart(Player, Cart)

	if Success then
		AttachCartEvent:FireClient(Player, "CONFIRM_OWNER", Cart)

		for _, Other in ipairs(Players:GetPlayers()) do
			if Other ~= Player then
				AttachCartEvent:FireClient(Other, "REPLICATE_OTHERS", Player, Cart)
			end
		end
	end
end)

DetachCartEvent.OnServerEvent:Connect(function(Player: Player)
	local Success, Cart = CartStateManager.DetachCart(Player)

	if Success and Cart then
		print("[CartServer] Detaching cart for:", Player.Name, "Cart:", Cart.Name)
		DetachCartEvent:FireAllClients(Player, Cart)
	end
end)

UpdateCartEvent.OnServerEvent:Connect(function(Player: Player, CartCFrame: CFrame, _: number?)
	local Data = CartStateManager.GetPlayerData(Player)
	if not Data or not Data.IsOwner then
		return
	end

	local Now = tick()
	if Now - (Data.LastUpdateTime or 0) < GeneralUtil.UPDATE_RATE then
		return
	end

	Data.LastUpdateTime = Now

	CartStateManager.UpdateCartPosition(Player, CartCFrame)
end)

UpdateWheelHeightEvent.OnServerEvent:Connect(function(Player: Player, Cart: Model, WheelDiameter: number)
	CartStateManager.UpdateWheelDiameter(Player, Cart, WheelDiameter)
end)

Players.PlayerRemoving:Connect(function(Player)
	CartStateManager.CleanupPlayer(Player)
end)

Players.PlayerAdded:Connect(function(NewPlayer)
	task.wait(2)

	local Attachments = CartStateManager.GetAllAttachments()
	for Owner, Cart in pairs(Attachments) do
		AttachCartEvent:FireClient(NewPlayer, "REPLICATE_OTHERS", Owner, Cart)
	end
end)

return {
	StateAFunction = function(Player: Player, Object: Instance, Config: any)
		if Object:IsA("Model") and CollectionService:HasTag(Object, CART_TAG) then
			local OwnerId = Object:GetAttribute("Owner")
			if OwnerId and OwnerId ~= Player.UserId then
				return
			end

			Object:SetAttribute("Owner", Player.UserId)
			Object:SetAttribute("Type", "Cart")

			OwnershipManager.TrackOwnership(Object, Player.UserId)
			PhysicsGroups.SetToGroup(Object, "Dragging")

			AttachCartEvent:FireClient(Player, Object)

			if Config and Config.InteractionSound then
				SoundModule.PlaySound(Config.InteractionSound, Object.PrimaryPart)
			end
		end
	end,

	StateBFunction = function(Player: Player, Object: Instance, Config: any)
		if Object:IsA("Model") then
			if Object:GetAttribute("AttachedTo") == Player.Name then
				local Success, Cart = CartStateManager.DetachCart(Player)

				if Success and Cart then
					DetachCartEvent:FireAllClients(Player, Cart)
					OwnershipManager.UpdateInteractionTime(Object)
					PhysicsGroups.SetToGroup(Object, "Static")

					if Config and Config.ReleaseSound then
						SoundModule.PlaySound(Config.ReleaseSound, Object.PrimaryPart)
					end
				end
			end
		end
	end
}