--[[
TODO:
- Villogó hibák (ciklusos hibák)
- Control Panel function (soft shutdown, service mode)
- kártya mouse over hint: kártya & lámpa status
- amikor esc megnyomva a lámpa identifyolás közben, a kijelölés ottmaradt
- kártya javítás animáció / minigame

]]--

---------------------------------------------------------------
-- // VARIABLES // ---- // VARIABLES // ---- // VARIABLES // --
---------------------------------------------------------------

local module = {}
local errors = {
	["Lamp"] = {
		{
			["ErrorCode"] = "001",
			["Description"] = "All lights are on (red, yellow, green)",
			["Solution"] = "Reset card",
			["Function"] = function(lamp)
				lamp.Lights.Piros.Transparency = 0
				lamp.Lights.Sarga.Transparency = 0
				lamp.Lights.Zold.Transparency = 0
			end,
			["OnFixFunc"] = function(lamp)
				lamp.Lights.Piros.Transparency = 1
				lamp.Lights.Sarga.Transparency = 1
				lamp.Lights.Zold.Transparency = 1
			end,
		},
		{
			["ErrorCode"] = "002",
			["Description"] = "Bottom light is blue",
			["Solution"] = "Change lightbulb in lamp",
			["Function"] = function(lamp)
				lamp.Lights.Piros.Transparency = 1
				lamp.Lights.Sarga.Transparency = 1
				lamp.Lights.Zold.Transparency = 0
				
				lamp.Lights.Zold.Color = Color3.fromRGB(0, 0, 255)
			end,
			["OnFixFunc"] = function(lamp)
				lamp.Lights.Piros.Transparency = 1
				lamp.Lights.Sarga.Transparency = 1
				lamp.Lights.Zold.Transparency = 1
				
				lamp.Lights.Zold.Color = Color3.fromRGB(0, 255, 0)
			end,
		},
		
	},
	["Pedestrian"] = {
		{
			["ErrorCode"] = "001",
			["Description"] = "All lights are on (red, green)",
			["Solution"] = "Reset card",
			["Function"] = function(pedestrianLamp)
				pedestrianLamp.Piros.GUI.SurfaceGui.Color.Visible = true
				pedestrianLamp.Zold.GUI.SurfaceGui.Color.Visible = true
			end,
			["OnFixFunc"] = function(pedestrianLamp)
				pedestrianLamp.Piros.GUI.SurfaceGui.Color.Visible = false
				pedestrianLamp.Zold.GUI.SurfaceGui.Color.Visible = false
			end,
		}
	},
	["Card"] = {
		{
			["ErrorCode"] = "001",
			["Description"] = "All lights are on (good, bad)",
			["Solution"] = "Change card",
			["Function"] = function(card)
				card.Bad.Bulb.Material = Enum.Material.Neon
				card.Good.Bulb.Material = Enum.Material.Neon
			end,
			["OnFixFunc"] = function(card)
				card.Bad.Bulb.Material = Enum.Material.Mud
				card.Good.Bulb.Material = Enum.Material.Neon
			end,
		}
	}
}


---------------------------------------------------------------------------------
-- // LOCAL FUNCTIONS // ---- // LOCAL FUNCTIONS // ---- // LOCAL FUNCTIONS // --
---------------------------------------------------------------------------------

-- ** GET FUNCTIONS ** --

-- Returns a table in errors[devicetype]
local function getErrorByErrorCode(devicetype: string, errorcode: string)
	if not errors[devicetype] then
		return
	end
	for key, value in errors[devicetype] do
		if value["ErrorCode"] == errorcode then
			return value
		end
	end
end

-- Returns "Card" or "Pedestrian" or "Lamp" by the device's name
local function getDeviceType(name: string)
	if typeof(name) == "Instance" then
		name = name.Name
	end
	if string.find(name, "Card") then
		return "Card"
	elseif string.find(name, "Pedestrian") then
		return "Pedestrian"
	elseif string.find(name, "Lamp") then
		return "Lamp"
	end
end

local function getLampByCard(card: Instance)
	if not card then
		return "not found"
	end
	local name = string.sub(card.Name, 6, -1)
	local intersection = card:FindFirstAncestor("Intersection")
	return intersection:FindFirstChild(name, true)
end

local function getCardByLamp(lamp: Instance)
	if not lamp then
		return
	end
	local name = "Card_"..lamp.Name
	local intersection = lamp:FindFirstAncestor("Intersection")
	return intersection:FindFirstChild(name, true)
end

-- ** FUNCTIONS ** --

local function generateRandomError(lamptype: string)
	if not errors[lamptype] then
		return
	end
	local currentErrors = errors[lamptype]
	local errorCount = #currentErrors
	return currentErrors[math.random(1, errorCount)]
end

local function fix(device)
	warn("fixing")
	if not device then
		error("no device")
		return
	end
	if not device:FindFirstChild("Override") or not device:FindFirstChild("ErrorCode") then
		error("no override or errorcode")
		return
	end
	
	local override = device.Override
	local errorcode = device.ErrorCode
	local deviceType = getDeviceType(device.Name)
	local err = getErrorByErrorCode(deviceType, errorcode.Value)

	if not err then
		error("no error table")
		return
	end

	override.Value = false
	errorcode.Value = ""
	err["OnFixFunc"](device)

	if deviceType == "Lamp" or deviceType == "Pedestrian" then
		local card = getCardByLamp(device)
		if not card then
			error("no card for lamp")
			return
		end

		card.Override.Value = false
		card.ErrorCode.Value = ""
		card.Bad.Bulb.Material = Enum.Material.Mud
		card.Good.Bulb.Material = Enum.Material.Neon
		
		if device:FindFirstChild("PromptPart") then
			device.PromptPart:Destroy()
		end
	else
		local lamp = getLampByCard(device)
		if not lamp then
			error("no lamp for card")
			return
		end

		lamp.Override.Value = false
		lamp.ErrorCode.Value = ""
	end
	
	local intersection = device:FindFirstAncestor("Intersection")
	if intersection then
		intersection.Scripting.RemoveError:Fire(device)
	end
end

---------------------------------------------------------------------------
-- // MAIN FUNCTION // ---- // MAIN FUNCTION // ---- // MAIN FUNCTION // --
---------------------------------------------------------------------------


local function displayError(device:Model, deviceError)
	if not device then
		return
	end
	local devicetype = getDeviceType(device.Name)
	if not deviceError then
		return
	end
	
	device.Override.Value = true
	deviceError["Function"](device)
	
	local lamp = nil
	local card = nil
	if devicetype == "Card" then
		lamp = getLampByCard(device)
		if not lamp then
			return
		end
		
		-- If lamp
		if getDeviceType(lamp) == "Lamp" then
			lamp.Override.Value = true
			lamp.Lights.Piros.Transparency = 1
			lamp.Lights.Sarga.Transparency = 1
			lamp.Lights.Zold.Transparency = 1
			
		-- If pedestrian lamp
		elseif getDeviceType(lamp) == "Pedestrian" then
			lamp.Override.Value = true
			lamp.Piros.GUI.SurfaceGui.Color.Visible = false
			lamp.Zold.GUI.SurfaceGui.Color.Visible = false
		end
	else
		card = getCardByLamp(device)
		if not card then
			return
		end
		card.Override.Value = true
		card.Good.Bulb.Material = Enum.Material.Mud
		card.Bad.Bulb.Material = Enum.Material.Neon
		
		-- add fix prompt
		lamp = device
		if device:FindFirstChild("PromptPart") then
			return
		end
		
		local part = Instance.new("Part")
		part.Parent = lamp
		part.Name = "PromptPart"
		part.CFrame = device:GetPivot()
		part.Anchored = true
		part.Transparency = 1
		part.CanCollide = false
		
		local prompt = Instance.new("ProximityPrompt")
		prompt.Parent = part
		prompt.ObjectText = "Traffic light"
		prompt.ActionText = "Fix lamp"
		prompt.RequiresLineOfSight = false
		
		prompt.Triggered:Connect(function(plr)
			fix(lamp)
		end)
	end
end

function module.createError(device: Instance)
	if not device then
		return
	end
	if not device:FindFirstChild("ErrorCode") or not device:FindFirstChild("Override") then
		return
	end
	local override = device.Override
	local errorcode = device.ErrorCode
	if errorcode.Value ~= "" then
		return
	end
	override.Value = true
	local deviceType = getDeviceType(device.Name)
	if deviceType == "Lamp" or deviceType == "Pedestrian" then
		if getCardByLamp(device).ErrorCode.Value ~= "" then
			return
		end
	else
		if getLampByCard(device).ErrorCode.Value ~= "" then
			return
		end
	end
	local err = generateRandomError(deviceType)
	
	errorcode.Value = err["ErrorCode"]
	displayError(device, err)
	return errorcode.Value
end

function module.showError(lamp, errorcode)
	if not errorcode then
		errorcode = lamp.ErrorCode.Value
	end
	local deviceType = getDeviceType(lamp.Name)
	local err = getErrorByErrorCode(deviceType, errorcode)
	displayError(lamp, err)
end

-- Fix a device
function module.fix(device: Instance)
	fix(device)
end

function module.getErrors()
	return errors
end

return module
