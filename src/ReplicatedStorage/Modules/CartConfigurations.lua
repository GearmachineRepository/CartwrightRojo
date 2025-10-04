--!strict

local CartConfigurations = {}

local DEFAULT_CONFIG = {
	WHEEL_RADIUS = 0.9,
	MIN_WHEEL_CLEARANCE = 0.1,
	CART_LIFT_HEIGHT = 0.95,
	MAX_TILT_ANGLE = math.rad(55),
	LERP_ALPHA = 0.15,
	RAYCAST_DISTANCE = 50,
	CAMERA_SENSITIVITY = 0.25,
	WALKSPEED_REDUCTION = 2.5,
	WHEEL_ROTATION_RADIUS = 3,
}

local CART_CONFIGS = {
	["Small Cart"] = {
		WHEEL_RADIUS = 0.9,
		MIN_WHEEL_CLEARANCE = 0.05,
		CART_LIFT_HEIGHT = 0.95,
		MAX_TILT_ANGLE = math.rad(55),
		LERP_ALPHA = 0.2,
		WHEEL_ROTATION_RADIUS = 2.75,
		BaseMaxWeight = 80,
	},

	["Large Cart"] = {
		WHEEL_RADIUS = 2.5,
		MIN_WHEEL_CLEARANCE = 0.15,
		CART_LIFT_HEIGHT = 1.2,
		MAX_TILT_ANGLE = math.rad(35),
		LERP_ALPHA = 0.1,
		CAMERA_SENSITIVITY = 0.2,
		WALKSPEED_REDUCTION = 6,
		WHEEL_ROTATION_RADIUS = 4,
	},

	["Small Wagon"] = {
		WHEEL_RADIUS = 1.2,
		MIN_WHEEL_CLEARANCE = 0.08,
		CART_LIFT_HEIGHT = 0.7,
		MAX_TILT_ANGLE = math.rad(65),
		LERP_ALPHA = 0.25,
		CAMERA_SENSITIVITY = 0.4,
		WALKSPEED_REDUCTION = 2,
		WHEEL_ROTATION_RADIUS = 2.5,
	},

	["Large Wagon"] = {
		WHEEL_RADIUS = 2.0,
		MIN_WHEEL_CLEARANCE = 0.2,
		CART_LIFT_HEIGHT = 1.0,
		MAX_TILT_ANGLE = math.rad(70),
		LERP_ALPHA = 0.12,
		CAMERA_SENSITIVITY = 0.25,
		WALKSPEED_REDUCTION = 3,
		WHEEL_ROTATION_RADIUS = 3.5,
	},
}

function CartConfigurations.GetConfig(CartModel: Model): {[string]: any}
	local CartName = CartModel.Name
	local CartConfig = CART_CONFIGS[CartName] or {}

	local FinalConfig = {}
	for Key, Value in pairs(DEFAULT_CONFIG) do
		FinalConfig[Key] = CartConfig[Key] or Value
	end

	return FinalConfig
end

function CartConfigurations.GetAllConfigs(): {[string]: {[string]: any}}
	local AllConfigs = {}
	for CartName, _ in pairs(CART_CONFIGS) do
		AllConfigs[CartName] = CartConfigurations.GetConfig({Name = CartName} :: any)
	end
	return AllConfigs
end

function CartConfigurations.AddConfig(CartName: string, Config: {[string]: any}): ()
	CART_CONFIGS[CartName] = Config
end

function CartConfigurations.UpdateConfig(CartName: string, Updates: {[string]: any}): ()
	if CART_CONFIGS[CartName] then
		for Key, Value in pairs(Updates) do
			CART_CONFIGS[CartName][Key] = Value
		end
	else
		warn("Cart configuration '" .. CartName .. "' not found")
	end
end

return CartConfigurations