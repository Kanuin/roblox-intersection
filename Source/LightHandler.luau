--[[
    Light Handler
    
    Main functions for handling traffic lights of an intersection, including:
    - cycle of traffic lights
    - contol cabinet functions 
    - generating random errors to fix
    
    Traffic lights can contain 3 or 2 lamps according to its usage:
    - for vehicles contains 3 lamps: red, yellow and green (Piros, Sarga, Zold)
    - for pedestrians contains 2 lamps: red and green (Piros, Zold)
    
    Traffic light cycle:
    - for vehicles: red, red-yellow, green, yellow, red
    - for pedestrians: red, green, flashing green, red
]]

---------------------
-- // VARIABLES // --
---------------------

local main = script.Parent.Parent
local values = main.Values
local TweenService = game:GetService("TweenService")

local boxinside = main.ControlBox.Body.Inside
local powerSwitch = boxinside.PowerSwitch
local errorModule = require(game.Workspace.TrafficLights.Modules.ErrorModule)
local controlpanel = boxinside.ControlPanel
local cpbuttons = controlpanel.LowerButtons
local cpscreen = controlpanel.Display.SurfaceGui.ScreenFace

local indOnColor = Color3.fromRGB(0,250,0)
local indOffColor = Color3.fromRGB(27, 42, 53)

local deviceTypes = {"PedestrianLamp", "Lamp", "Card"}

local generateErrorTime = {
	["From"] = 1, -- In seconds
	["To"] = 2 -- In seconds
}

local screenText = {
	[1] = nil,
	[2] = nil,
	[3] = nil,
	[4] = nil,
}

local indicators = {
	["InitializeCards"] = nil,
	["PauseCycle"] = nil,
	["ServiceMode"] = nil,
	["SoftShutdown"] = nil,
	["StartCycle"] = nil,
}

local varakoztatas = 3
local villogoZoldTime = 0.7
local road1times = {
    ["Red"] = 15,
    ["RedYellow"] = 2,
    ["Yellow"] = 3,
    ["Green"] = 10,
}

local road2times = {
    ["Red"] = 15,
    ["RedYellow"] = 2,
    ["Yellow"] = 3,
    ["Green"] = 10,
}

local errors = {}
local currentErrorIndex = 0

---------------------------
-- // LOCAL FUNCTIONS // --
---------------------------

--[[
	Turns all the traffic lights off.
]]
local function turnOffAllLamps()
    print("Turning off all lamps")
    for _, object in main.Phases:GetChildren() do
        if object:IsA("Folder") then
            for _, lamp in object:GetChildren() do
                if lamp:IsA("Folder") then
                    for _, pedestrianLamp in lamp:GetChildren() do
                        pedestrianLamp.Piros.GUI.SurfaceGui.Color.Visible = false
                        pedestrianLamp.Zold.GUI.SurfaceGui.Color.Visible = false
                    end
                elseif lamp:IsA("Model") then
                    lamp.Lights.Piros.Transparency = 1
                    lamp.Lights.Sarga.Transparency = 1
                    lamp.Lights.Zold.Transparency = 1
                end
            end
        end
    end
end

--[[
	Sets the leds of a control card.
]]
local function cardlight(name, ledtype, turningOn) 
	if main.Values.SystemIsOn.Value == false then
		return
	end
    print("Setting card light for:", name, ledtype, "Turning on:", turningOn)
    if boxinside.Cards:FindFirstChild("Card_"..name) then
		local card = boxinside.Cards["Card_"..name]
		if card.Override.Value == true then
			if card.ErrorCode.Value ~= "" then
				errorModule.showError(card)
			end
			return
		end
        if card:FindFirstChild(ledtype) then
            local led = card[ledtype]
            if turningOn then
                led.Bulb.Material = Enum.Material.Neon
            else
                led.Bulb.Material = Enum.Material.Mud
            end
        end
    end
end

--[[
	Sets all the pedestrian lamps of given phase to given color.
	When turningOn is false, lamp will be turned off. 
]]
local function pedestrian(phase:string, color: string, turningOn: boolean)
	if main.Values.SystemIsOn.Value == false then
		turnOffAllLamps()
		return
	end
    print("Setting pedestrian lights for phase:", phase, color, "Turning on:", turningOn)
    if main.Phases:FindFirstChild(phase) then
        local currentphase = main.Phases[phase]
        if currentphase:FindFirstChild("Pedestrian") then
            local lamps = currentphase["Pedestrian"]
            for _, object in lamps:GetChildren() do
				if object:IsA("Model") then
					if object.Override.Value == true then
						if object.ErrorCode.Value ~= "" then
							errorModule.showError(object)
						end
						continue
					end
                    if object:FindFirstChild(color) and object[color]:FindFirstChild("GUI") then
                        local GUI = object[color]["GUI"]
                        if GUI:FindFirstChild("SurfaceGui") then
                            local light = GUI.SurfaceGui.Color
                            light.Visible = turningOn
                        end
                    end
                end
            end
        end
    end
end

--[[
	Sets all the vahicle lamps of given phase to given color.
	When turningOn is false, lamp will be turned off. 
]]
local function light(phase:string, color:string, turningOn:boolean)
	if main.Values.SystemIsOn.Value == false then
		turnOffAllLamps()
		return
	end
    print("Setting vehicle lights for phase:", phase, color, "Turning on:", turningOn)
    if main.Phases:FindFirstChild(phase) then
        local lamps = main.Phases[phase]
        for _, object in lamps:GetChildren() do
			if object:IsA("Model") and object.Lights then
				if object.Override.Value == true then
					if object.ErrorCode.Value ~= "" then
						errorModule.showError(object)
					end
					continue
				end
                if object.Lights:FindFirstChild(color) then
                    local light = object.Lights[color]
                    light.Transparency = turningOn and 0 or 1
                end
            end
        end
    end
end

--[[
	Sets the display of the control cabinet to saved one.
]]
local function loadScreen()
	cpscreen.L1.Text = screenText[1]
	cpscreen.L2.Text = screenText[2]
	cpscreen.L3.Text = screenText[3]
	cpscreen.L4.Text = screenText[4]
end

--[[
	Saves the content of control cabinet display and clears it.
]]
local function turnOffScreen()
	screenText[1] = cpscreen.L1.Text
	screenText[2] = cpscreen.L2.Text
	screenText[3] = cpscreen.L3.Text
	screenText[4] = cpscreen.L4.Text
	
	cpscreen.L1.Text = ""
	cpscreen.L2.Text = ""
	cpscreen.L3.Text = ""
	cpscreen.L4.Text = ""
end

--[[
	Sets the indicators of control cabinet to saved one.
]]
local function loadIndicators()
	cpbuttons.InitializeCards.Indicator.Color = indicators["InitializeCards"]
	cpbuttons.PauseCycle.Indicator.Color = indicators["PauseCycle"]
	cpbuttons.ServiceMode.Indicator.Color = indicators["ServiceMode"]
	cpbuttons.SoftShutdown.Indicator.Color = indicators["SoftShutdown"]
	cpbuttons.StartCycle.Indicator.Color = indicators["StartCycle"]
end

--[[
	Saves the indicators of control cabinet and turns them off
]]
local function turnOffIndicators()
	indicators["InitializeCards"] = cpbuttons.InitializeCards.Indicator.Color
	indicators["PauseCycle"] = cpbuttons.PauseCycle.Indicator.Color
	indicators["ServiceMode"] = cpbuttons.ServiceMode.Indicator.Color
	indicators["SoftShutdown"] = cpbuttons.SoftShutdown.Indicator.Color
	indicators["StartCycle"] = cpbuttons.StartCycle.Indicator.Color
	
	cpbuttons.InitializeCards.Indicator.Color = indOffColor
	cpbuttons.PauseCycle.Indicator.Color = indOffColor
	cpbuttons.ServiceMode.Indicator.Color = indOffColor
	cpbuttons.SoftShutdown.Indicator.Color = indOffColor
	cpbuttons.StartCycle.Indicator.Color = indOffColor
end

--[[
	Sets the pedestrion lamp to flashing green.
]]
local function villogoZold(phase)
	if main.Values.SystemIsOn.Value == false then
		turnOffAllLamps()
		return
	end
    print("Starting flashing green for phase:", phase)
    for _ = 1, 5 do
        pedestrian(phase, "Zold", true)
        task.wait(villogoZoldTime)
        pedestrian(phase, "Zold", false)
        task.wait(villogoZoldTime)
    end
end

--[[
	Initialize all the card leds:
	- green led is on: card and its lamp works
	- red led is on: its lamp failed
	- both leds are on: card failure
	- both leds are off: no lamp found for card
]]
local function initializeCardLights()
	print("Initializing card lights")
	cpbuttons.InitializeCards.Indicator.Color = indOnColor
	
	-- Get phases
	for _, object in main.Phases:GetChildren() do
		
		-- If actual phase
		if object:IsA("Folder") then
			
			-- Get lamps in phase
			for _, lamp in object:GetChildren() do
				
				-- If pedestrian lamps folder
				if lamp:IsA("Folder") then
					
					-- Get pedestrian lamps
					for _, pedestrianLamp in lamp:GetChildren() do
						if pedestrianLamp.Override.Value == true then
							if pedestrianLamp.ErrorCode.Value ~= "" then
								errorModule.showError(pedestrianLamp)
							end
							if boxinside.Cards["Card_"..pedestrianLamp.Name].ErrorCode.Value ~= "" then
								cardlight(pedestrianLamp.Name, "Good", false)
							end
							continue
						end
						cardlight(pedestrianLamp.Name, "Good", true)
						task.wait(0.3)
					end
					
				-- If actual lamp
				elseif lamp:IsA("Model") then
					if lamp.Override.Value == true then
						if lamp.ErrorCode.Value ~= "" then
							errorModule.showError(lamp)
						end
						if boxinside.Cards["Card_"..lamp.Name].ErrorCode.Value ~= "" then
							cardlight(lamp.Name, "Good", false)
						end
						continue
					end
                    cardlight(lamp.Name, "Good", true)
					task.wait(0.3)
                end
            end
        end
	end
	cpbuttons.InitializeCards.Indicator.Color = indOffColor
end


--[[
	Turns all the card leds off.
]]
local function turnOffCardLights()
    print("Turning off card lights")
    for _, object in boxinside.Cards:GetChildren() do
		object.Good.Bulb.Material = Enum.Material.Mud
		object.Bad.Bulb.Material = Enum.Material.Mud
    end
end

--[[
	Returns with randomly a selected deevice (card or traffic light).
	deviceType: "pedestrianlamp", "lamp" or "card"
]]
local function getRandomDevice(deviceType: string)
	deviceType = deviceType:lower()
	local cards = boxinside.Cards:GetChildren()
	local newCards = {}
	for count, object in cards do
		if deviceType == "pedestrianlamp" then
			if string.find(object.Name, "Pedestrian") then
				table.insert(newCards, object)
				continue
			end
		elseif deviceType == "lamp" then
			if string.find(object.Name, "Lamp") then
				table.insert(newCards, object)
				continue
			end
		else
			table.insert(newCards, object)
		end
	end
	local randomDevice = newCards[math.random(1, #newCards)]
	if deviceType ~= "card" then
		randomDevice = script.Parent.Parent.Phases:FindFirstChild(string.sub(randomDevice.Name, 6, -1), true)
	end
	return randomDevice
end

--[[
	Shows an error text on control cabinet display.
]]
local function setDisplayErrorText(errorindex: number)
	if not errorindex then
		error("no errorindex received")
	end
	if not errors[errorindex] then
		return
	end
	currentErrorIndex = errorindex
	cpscreen.L2.Text = `- [{errorindex}/{#errors}] {errors[errorindex]["Device"]} - #{errors[errorindex]["Error"]}`
end

local cycle = nil
local errorcycle = nil
local controlcabinetdisplaycycle = nil

--[[
	Loops a lamp cycle:
    - for vehicles: red, red-yellow, green, yellow, red
    - for pedestrians: red, green, flashing green, red
]]
local function lampCycle()
	if values.SystemIsOn.Value then
		while values.SystemIsOn.Value do
			print("Executing light sequence")

			-- Phase 1
			light("Phase1", "Piros", true)
			light("Phase2", "Piros", true)
			pedestrian("Phase1", "Piros", true)
			pedestrian("Phase2", "Piros", true)

			light("Phase2", "Sarga", true)
			task.wait(road2times.RedYellow)
			light("Phase2", "Sarga", false)
			light("Phase2", "Piros", false)
			light("Phase2", "Zold", true)
			pedestrian("Phase2", "Piros", false)
			pedestrian("Phase2", "Zold", true)
			task.wait(road2times.Green)
			villogoZold("Phase2")
			pedestrian("Phase2", "Piros", true)
			light("Phase2", "Zold", false)
			light("Phase2", "Sarga", true)
			task.wait(road2times.Yellow)
			light("Phase2", "Sarga", false)
			light("Phase2", "Piros", true)

			task.wait(varakoztatas)

			-- Phase 2
			light("Phase1", "Sarga", true)
			task.wait(road1times.RedYellow)
			light("Phase1", "Sarga", false)
			light("Phase1", "Piros", false)
			light("Phase1", "Zold", true)
			pedestrian("Phase1", "Piros", false)
			pedestrian("Phase1", "Zold", true)
			task.wait(road1times.Green)
			villogoZold("Phase1")
			pedestrian("Phase1", "Piros", true)
			light("Phase1", "Zold", false)
			light("Phase1", "Sarga", true)
			task.wait(road1times.Yellow)
			light("Phase1", "Sarga", false)
			light("Phase1", "Piros", true)

			task.wait(varakoztatas)
		end
	end
end

--[[
	Starts an async (in coroutine) lamp cycle 
]]
local function startCycle()
	cpbuttons.StartCycle.Indicator.Color = indOnColor
	cpbuttons.PauseCycle.Indicator.Color = indOffColor
	cycle = coroutine.create(lampCycle)
	coroutine.resume(cycle)
end

--[[
	Stops the previously started lamp cycle 
]]
local function stopCycle()
	cpbuttons.PauseCycle.Indicator.Color = indOnColor
	cpbuttons.StartCycle.Indicator.Color = indOffColor
	if cycle then
		coroutine.close(cycle)
	end
end

--[[
	Loops error generation sequence. Randonly select a device and breaks it.
]]
local function errorCycle()
	if values.SystemIsOn.Value then
		while values.SystemIsOn.Value do
			print("Executing error generating sequence")
			local waittime = math.random(generateErrorTime["From"], generateErrorTime["To"])
			task.wait(waittime)
			local deviceType = deviceTypes[math.random(1, #deviceTypes)]
			local device = getRandomDevice(deviceType)
			local errorcode = errorModule.createError(device)
			table.insert(errors, {["Error"] = errorcode, ["Device"] = device.Name})
		end
	end
end

--[[
	Starts an async (in coroutine) error generation sequence
]]
local function startErrorCycle()
	errorcycle = coroutine.create(errorCycle)
	coroutine.resume(errorcycle)
end

--[[
	Stops the previously started error generation sequence
]]
local function stopErrorCycle()
	if errorcycle then
		coroutine.close(errorcycle)
	end
end

--[[
	Updates contrtol cabinet display every 5 seconds
]]
local function controlCabinetDisplayCycle()
	if values.SystemIsOn.Value then
		while values.SystemIsOn.Value do
			if #errors == 0 then -- If  0 (if table is empty)
				cpscreen.L1.Text = "ALL SYSTEMS OPERATIONAL"
				cpscreen.L2.Text = ""
				currentErrorIndex = 0
			else
				cpscreen.L1.Text = "ERROR DETECTED"
				setDisplayErrorText(1)
			end
			task.wait(5)
		end
	end
end

--[[
	Starts an async (in coroutine) control cabinet display update sequence 
]]
local function startcontrolCabinetDisplayCycle()
	controlcabinetdisplaycycle = coroutine.create(controlCabinetDisplayCycle)
	coroutine.resume(controlcabinetdisplaycycle)
end

--[[
	Stops the previously started control cabinet display update sequence
]]
local function stopcontrolCabinetDisplayCycle()
	if controlcabinetdisplaycycle then
		coroutine.close(controlcabinetdisplaycycle)
	end
end

--[[
	Turns on/off intersection
]]
local function togglePower(turningOn)
    print("Toggling power. Turning on:", turningOn)
	if not turningOn then
		powerSwitch.Interactive.CFrame = powerSwitch.Interactive.CFrame * CFrame.Angles(math.rad(10), 0, 0)
		if values.CurrentPlayer.Value then
			game.ReplicatedStorage.TrafficLightSystem.PlaySound:FireClient(values.CurrentPlayer.Value, "PowerSwitch")
		end
		stopCycle()
		stopErrorCycle()
		stopcontrolCabinetDisplayCycle()
		turnOffIndicators()
		turnOffAllLamps()
		turnOffScreen()
        turnOffCardLights()
	else
		powerSwitch.Interactive.CFrame = powerSwitch.Interactive.CFrame * CFrame.Angles(math.rad(-10), 0, 0)
		if values.CurrentPlayer.Value then
			game.ReplicatedStorage.TrafficLightSystem.PlaySound:FireClient(values.CurrentPlayer.Value, "PowerSwitch")
		end
		loadScreen()
		loadIndicators()
        initializeCardLights()
    end
end

--[[
	Moves the selection outline to a card.
	
	moveTo: Model The card to move the selection to
]] 
local function moveSelection(moveTo: Model)
	local selection = nil
	if not moveTo then
		return
	end
	selection = moveTo.Parent.Parent.Card_selection
	selection.Transparency = 0.5
	local targetPos = moveTo.Body.Position
	selection.Position = targetPos
end

----------------------------------
-- // CONTROL PANEL FUNCTION // --
----------------------------------

--[[
	Binds card interactions
]]
local selection = boxinside.Card_selection
local guiClone = nil
for count, object in boxinside.Cards:GetChildren() do
	if not object:IsA("Model") then
		continue
	end
	if not object:FindFirstChild("ClickDetector") then
		continue
	end
	local clickdetector = object.ClickDetector
	-- moving selection outline
	clickdetector.MouseHoverEnter:Connect(function(plr)
		if not values.CurrentPlayer.Value then
			return
		end
		if plr ~= values.CurrentPlayer.Value then
			return
		end
		if values.CardSelectionActive.Value == false then
			return
		end
		
		moveSelection(object)
	end)
	-- show context menu (identify, fix, exit)
	clickdetector.MouseClick:Connect(function(plr)
		if not values.CurrentPlayer.Value then
			return
		end
		if plr ~= values.CurrentPlayer.Value then
			return
		end
		
		values.CardSelectionActive.Value = false
		moveSelection(object)
		if guiClone then
			guiClone:Destroy()
			guiClone = nil
		end
		guiClone = game.ReplicatedStorage.TrafficLightSystem.SelectionGUI:Clone()
		guiClone.Adornee = object.Handle
		guiClone.Parent = plr.PlayerGui
		
		if object.ErrorCode.Value == "" then
			guiClone.List.Replace.Visible = false
		end
	end)
end

--[[
	Closing card context menu
]]
game.ReplicatedStorage.TrafficLightSystem.ClosedCardMenu.OnServerEvent:Connect(function(client, intersection)
	if intersection == script.Parent.Parent then -- if target intersection is current intersection
		if client == values.CurrentPlayer.Value then -- if sent from correct client
			if guiClone then
				guiClone:Destroy()
				guiClone = nil
			end
			values.CardSelectionActive.Value = true
		end
	end
end)

--[[
	"fix" context menu handling
]]
game.ReplicatedStorage.TrafficLightSystem.FixDevice.OnServerEvent:Connect(function(client, device)
	if not device then
		return
	end
	if client == values.CurrentPlayer.Value then -- if sent from correct client
		errorModule.fix(device)
		
	end
end)

--[[
	Hanldes control panel of control cabinet "start cycle" button,
	which starts a new lamp cycle  
]]
cpbuttons.StartCycle.Button.ClickDetector.MouseClick:Connect(function(plr)
	if values.SystemIsOn.Value == false then
		return
	end
	if values.CurrentPlayer.Value ~= plr then
		return
	end
	if values.KeyInserted.Value == false then
		cpscreen.L4.Text = ""
		wait(0.5)
		cpscreen.L4.Text = "INSERT KEY"
		return
	end
	if cpbuttons.StartCycle.Indicator.Color == indOnColor then
		return
	end
	
	print(":: BUTTONS :: StartCycle pressed")
	if cpbuttons.StartCycle.Indicator.Color == indOffColor then
		startCycle()
	else
		cpscreen.L4.Text = ""
		wait(0.5)
		cpscreen.L4.Text = "ALREADY CYCLING"
		wait(2)
		cpscreen.L4.Text = if values.KeyInserted.Value == true then "KEY INSERTED" else "INSERT KEY"
	end
end)

--[[
	Hanldes control panel of control cabinet "stop cycle" button,
	which stops the current lamp cycle  
]]
cpbuttons.PauseCycle.Button.ClickDetector.MouseClick:Connect(function(plr)
	if values.SystemIsOn.Value == false then
		return
	end
	if values.CurrentPlayer.Value ~= plr then
		return
	end
	if values.KeyInserted.Value == false then
		cpscreen.L4.Text = ""
		wait(0.5)
		cpscreen.L4.Text = "INSERT KEY"
		return
	end

	print(":: BUTTONS :: PauseCycle pressed")
	stopCycle()
end)

--[[
	Turns on intersection service mode (every lamp flashes yellow)
	TODO  
]]
cpbuttons.ServiceMode.Button.ClickDetector.MouseClick:Connect(function(plr)
	if values.SystemIsOn.Value == false then
		return
	end
	if values.CurrentPlayer.Value ~= plr then
		return
	end
	if values.KeyInserted.Value == false then
		cpscreen.L4.Text = ""
		wait(0.5)
		cpscreen.L4.Text = "INSERT KEY"
		return
	end

	print(":: BUTTONS :: ServiceMode pressed")
end)

--[[
	Waits for current cycle to be over and stops it.
	Every lamp is "red" 
	TODO  
]]
cpbuttons.SoftShutdown.Button.ClickDetector.MouseClick:Connect(function(plr)
	if values.SystemIsOn.Value == false then
		return
	end
	if values.CurrentPlayer.Value ~= plr then
		return
	end
	if values.KeyInserted.Value == false then
		cpscreen.L4.Text = ""
		wait(0.5)
		cpscreen.L4.Text = "INSERT KEY"
		return
	end
	
	print(":: BUTTONS :: SoftShutdown / HaltLights pressed")
end)

--[[
	Initializes cards in the control cabinet.
	- turns off the card leds
	- initialize cards   
]]
cpbuttons.InitializeCards.Button.ClickDetector.MouseClick:Connect(function(plr)
	if values.SystemIsOn.Value == false then
		return
	end
	if values.CurrentPlayer.Value ~= plr then
		return
	end
	if values.KeyInserted.Value == false then
		cpscreen.L4.Text = ""
		wait(0.5)
		cpscreen.L4.Text = "INSERT KEY"
		return
	end

	print(":: BUTTONS :: InitializeCards  pressed")
	turnOffCardLights()
	initializeCardLights()
end)

--[[
	Inserts or removes "control key" to/from control cabinet. 
]]
controlpanel.Key.ClickBox.ClickDetector.MouseClick:Connect(function(plr)
	if values.SystemIsOn.Value == false then
		return
	end
	if values.CurrentPlayer.Value ~= plr then
		return
	end
	
	values.KeyInserted.Value = not values.KeyInserted.Value
	controlpanel.Key.Tool.Visible.Value = not controlpanel.Key.Tool.Visible.Value
	
	cpscreen.L4.Text = if values.KeyInserted.Value == true then "KEY INSERTED" else "INSERT KEY"
	
	print(":: BUTTONS :: Key toggled")
end)

--[[
	Desing button, never will have functionality assigned to it. 
]]
cpbuttons.Useless.ToggleBatteries.Button.ClickDetector.MouseClick:Connect(function(plr)
	if values.SystemIsOn.Value == false then
		return
	end
	if values.CurrentPlayer.Value ~= plr then
		return
	end
	cpscreen.L4.Text = ""
	wait(0.5)
	cpscreen.L4.Text = "COMING SOON"
	wait(2)
	cpscreen.L4.Text = if values.KeyInserted.Value == true then "KEY INSERTED" else "INSERT KEY"

	print(":: BUTTONS :: ToggleBatteries  pressed")
end)

--[[
	Control cabinet display pager buttons.
	Displays next error if any or starts it over
]]
controlpanel.SideButtons.Next.Label.ClickDetector.MouseClick:Connect(function(plr)
	if values.SystemIsOn.Value == false then
		return
	end
	if values.CurrentPlayer.Value ~= plr then
		return
	end
	if #errors == 0 then
		controlpanel.SideButtons.Next.Indicator.Color = Color3.fromRGB(255,0,0)
		task.wait(0.2)
		controlpanel.SideButtons.Next.Indicator.Color = indOffColor
		return
	end
	
	if #errors == currentErrorIndex then
		currentErrorIndex = 1
	else
		currentErrorIndex += 1
	end
	setDisplayErrorText(currentErrorIndex)
	controlpanel.SideButtons.Next.Indicator.Color = indOnColor
	task.wait(0.2)
	controlpanel.SideButtons.Next.Indicator.Color = indOffColor
end)

--[[
	Control cabinet display pager buttons.
	Displays previous error if any or the last one
]]
controlpanel.SideButtons.Prev.Label.ClickDetector.MouseClick:Connect(function(plr)
	if values.SystemIsOn.Value == false then
		return
	end
	if values.CurrentPlayer.Value ~= plr then
		return
	end
	if #errors == 0 then
		controlpanel.SideButtons.Prev.Indicator.Color = Color3.fromRGB(255,0,0)
		task.wait(0.2)
		controlpanel.SideButtons.Prev.Indicator.Color = indOffColor
		return
	end

	if currentErrorIndex == 1 then
		currentErrorIndex = #errors
	else
		currentErrorIndex -= 1
	end
	setDisplayErrorText(currentErrorIndex)
	controlpanel.SideButtons.Prev.Indicator.Color = indOnColor
	task.wait(0.2)
	controlpanel.SideButtons.Prev.Indicator.Color = indOffColor
end)

--[[
	Turns on/off system value with control cabinet power switch.   
]]
powerSwitch.Interactive.ClickDetector.MouseClick:Connect(function(plr)
	if values.CurrentPlayer.Value ~= plr then
		return
	end

	print("Toggling power (mouse click) detected")
	values.SystemIsOn.Value = not values.SystemIsOn.Value
end)

-------------------------
-- // MAIN FUNCTION // --
-------------------------

--[[
	RemoveError is Bindableevent that is called when an error is fixed.
	Removes error from local errors table.  
]]
script.Parent.RemoveError.Event:Connect(function(device:Instance)
	if not device then 
		return
	end
	for index, value in errors do
		if value then
			if value["Device"] == device.Name then
				table.remove(errors, index)
				return
			end
		end
	end
end)

--[[
	User closes control cabinet.  
]]
game.ReplicatedStorage.TrafficLightSystem.ClosedMenu.OnServerEvent:Connect(function()
	if guiClone then
		guiClone:Destroy()
		guiClone = nil
	end
	values.CardSelectionActive.Value = true
end)

--[[
	Detects changes of system power  
]]
values.SystemIsOn:GetPropertyChangedSignal("Value"):Connect(function()
    print("SystemIsOn value changed. Current value:", values.SystemIsOn.Value)
	togglePower(values.SystemIsOn.Value)
end)


-- main starter functions 
print("Script initialized")
wait(1)
turnOffScreen()
turnOffIndicators()
values.SystemIsOn.Value = true
startCycle()
startcontrolCabinetDisplayCycle()
startErrorCycle()


-- generates errors for debugging
--[[
task.wait(5)
local errorcode = errorModule.createError(main.Phases.Phase1.Lamp1)
table.insert(errors, {["Error"] = errorcode, ["Device"] = "Lamp1"})
errorcode = errorModule.createError(main.Phases.Phase1.Pedestrian.PedestrianLamp3)
table.insert(errors, {["Error"] = errorcode, ["Device"] = "PedestrianLamp3"})
errorcode = errorModule.createError(boxinside.Cards.Card_Lamp5)
table.insert(errors, {["Error"] = errorcode, ["Device"] = "Card_Lamp5"})
--]]
