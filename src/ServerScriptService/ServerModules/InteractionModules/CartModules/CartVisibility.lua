--!strict
local CartVisibility = {}

-- Hide cart and persist original states
function CartVisibility.HideCart(cart: Model): ()
	pcall(function()
		for _, part: any in ipairs(cart:GetDescendants()) do
			if part:IsA("BasePart") then
				if part:GetAttribute("OriginalTransparency") == nil then 
					part:SetAttribute("OriginalTransparency", part.Transparency) 
				end
				if part:GetAttribute("OriginalCanCollide") == nil then 
					part:SetAttribute("OriginalCanCollide", part.CanCollide) 
				end
				if part:GetAttribute("OriginalCanQuery") == nil then 
					part:SetAttribute("OriginalCanQuery", part.CanQuery) 
				end
				if part:GetAttribute("OriginalCanTouch") == nil then 
					part:SetAttribute("OriginalCanTouch", part.CanTouch) 
				end
				part.Transparency = 1
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
			elseif part:IsA("Decal") or part:IsA("Texture") then
				if part:GetAttribute("OriginalTransparency") == nil then 
					part:SetAttribute("OriginalTransparency", part.Transparency) 
				end
				part.Transparency = 1
			end
		end
	end)
end

-- Restore persisted states
function CartVisibility.ShowCart(cart: Model): ()
	for _, part: any in ipairs(cart:GetDescendants()) do
		if part:IsA("BasePart") then
			local ot = part:GetAttribute("OriginalTransparency")
			if ot ~= nil then 
				part.Transparency = ot
				part:SetAttribute("OriginalTransparency", nil) 
			end

			local occ = part:GetAttribute("OriginalCanCollide")
			if occ ~= nil then 
				part.CanCollide = occ
				part:SetAttribute("OriginalCanCollide", nil) 
			end

			local ocq = part:GetAttribute("OriginalCanQuery")
			if ocq ~= nil then 
				part.CanQuery = ocq
				part:SetAttribute("OriginalCanQuery", nil) 
			end

			local oci = part:GetAttribute("OriginalCanTouch")
			if oci ~= nil then 
				part.CanTouch = oci
				part:SetAttribute("OriginalCanTouch", nil) 
			end
		elseif part:IsA("Decal") or part:IsA("Texture") then
			local ot = part:GetAttribute("OriginalTransparency")
			if ot ~= nil then 
				part.Transparency = ot
				part:SetAttribute("OriginalTransparency", nil) 
			end
		end
	end
end

return CartVisibility