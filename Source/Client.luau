local TweenService = game:GetService("TweenService")
local inputservice = game:GetService("UserInputService")
local Players = game:GetService("Players")

local oldspeed = nil
local oldcampos = nil
local topPart = nil
local bottomPart = nil
local highlight = nil

local function animate(object, goal, animtime, style, direction)
	local tweenInfo = TweenInfo.new(
		animtime, -- Time
		style or Enum.EasingStyle.Quint, -- EasingStyle
		direction or Enum.EasingDirection.InOut, -- EasingDirection
		0, -- RepeatCount
		false, -- Reverses
		0 -- DelayTime
	)
	local tween = TweenService:Create(object, tweenInfo, goal)
	tween:Play()
	return tween
end

local function moveCamBack(plr)
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	-- Define the target CFrame
	local targetCFrame = oldcampos
	
	-- Use the animate function to tween the camera's CFrame
	animate(camera, {CFrame = targetCFrame}, 2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
	
	-- Lock the camera to the head after the animation
	task.delay(2, function()
		camera.CameraType = Enum.CameraType.Custom
	end)
end

-- Move the camera to a part
local function moveCameraToPart(player, part, animTime, easingStyle, easingDirection)
	local camera = workspace.CurrentCamera -- Access the current camera
	if not camera then return end
	
	-- Define the target CFrame
	local targetCFrame = part.CFrame

	-- Use the animate function to tween the camera's CFrame
	animate(camera, {CFrame = targetCFrame}, animTime, easingStyle, easingDirection)

	-- Lock the camera to the target part after the animation
	task.delay(animTime, function()
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = targetCFrame
	end)
end



-- Freeze the player's character
local function freezeCharacter(player)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			oldspeed = humanoid.WalkSpeed
			humanoid.WalkSpeed = 0 -- Freeze the character by setting WalkSpeed to 0
			-- Optional: Disable character movement by anchoring the HumanoidRootPart temporarily
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				rootPart.Anchored = true
			end
		end
	end
end

-- Unfreeze the player's character
local function unfreezeCharacter(player)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = oldspeed or 16 -- Reset WalkSpeed to default (or any desired value)
			-- Optional: Re-enable character movement
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				rootPart.Anchored = false
			end
		end
	end
end

local player = Players.LocalPlayer -- Get the local player
local targetPart = nil
game.Workspace:WaitForChild(player.Name)
local cabinetui = player.PlayerGui.ControlCabinetGUI
local moveButtonOldPos = nil
local moveButtonOldRotation = nil
local camOldPos = nil

local function identifyLamp(lamp: Instance)
	local camera = workspace.CurrentCamera -- Access the current camera
	if not camera then
		return
	end
	if not lamp then
		return
	end
	
	moveButtonOldPos = cabinetui.Move.Position
	moveButtonOldRotation = cabinetui.Move.Rotation
	camOldPos = camera.CFrame
	
	cabinetui.Move.Position = cabinetui.Close.Position
	cabinetui.Move.Rotation = 180
	cabinetui.Close.Visible = false
	
	local targetCam = nil
	if lamp.Name:find("Pedestrian") then
		targetCam = lamp.Parent.Parent.Parent.IdentifyLampPos
	else
		targetCam = lamp.Parent.Parent.IdentifyLampPos
	end
	
	if not targetCam then
		return
	end
	highlight = Instance.new("Highlight")
	highlight.Parent = lamp
	highlight.FillColor = Color3.fromRGB(0,255,0)
	moveCameraToPart(player, targetCam, 2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
end



game.ReplicatedStorage.TrafficLightSystem.OpenCamera.OnClientEvent:Connect(function(targetPart, part2)
	topPart = targetPart
	bottomPart = part2
	-- Freeze the character
	freezeCharacter(player)
	wait(0.4)
	oldcampos = workspace.CurrentCamera.CFrame
	
	-- Move the camera to the target part over 2 seconds
	moveCameraToPart(player, targetPart, 2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
	wait(1.7)
	cabinetui.Enabled = true
end)

cabinetui.Close.MouseButton1Click:Connect(function()
	cabinetui.Enabled = false
	moveCamBack(player)
	task.wait(2)
	unfreezeCharacter(player)
	task.wait(1)
	game.ReplicatedStorage.TrafficLightSystem.ClosedMenu:FireServer()
	cabinetui.Move.Position = UDim2.new(0.5, -24, 1, -69)
	cabinetui.Move.Rotation = 90
end)

inputservice.InputBegan:Connect(function(input)
	if cabinetui.Enabled == false then return end
	if input.KeyCode == Enum.KeyCode.Escape then
		cabinetui.Enabled = false
		unfreezeCharacter(player)
		moveCamBack(player)
		task.wait(3)
		game.ReplicatedStorage.TrafficLightSystem.ClosedMenu:FireServer()
		cabinetui.Move.Position = UDim2.new(0.5, -24, 1, -69)
		cabinetui.Move.Rotation = 90
	end
end)

cabinetui.Move.Position = UDim2.new(0.5, -24, 1, -69)
cabinetui.Move.Rotation = 90

cabinetui.Move.MouseButton1Click:Connect(function()
	if cabinetui.Move.Position == UDim2.new(0.5, -24, 0, 20) then
		moveCameraToPart(player, topPart, 1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		cabinetui.Move.Position = UDim2.new(0.5, -24, 1, -69)
		cabinetui.Move.Rotation = 90
	elseif cabinetui.Move.Position == UDim2.new(0.5, -24, 1, -69) then
		moveCameraToPart(player, bottomPart, 1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		cabinetui.Move.Position = UDim2.new(0.5, -24, 0, 20)
		cabinetui.Move.Rotation = -90
	else
		if moveButtonOldPos and moveButtonOldRotation and camOldPos then
			local targetCFrame = camOldPos
			animate(workspace.CurrentCamera, {CFrame = targetCFrame}, 2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
			cabinetui.Move.Position = moveButtonOldPos
			cabinetui.Move.Rotation = moveButtonOldRotation
			cabinetui.Close.Visible = true
			
			if highlight then
				highlight:Destroy()
				highlight = nil
			end
		end
	end
end)

game.ReplicatedStorage.TrafficLightSystem.PlaySound.OnClientEvent:Connect(function(sound)
	if game.ReplicatedStorage.TrafficLightSystem.Sounds:FindFirstChild(sound) then
		game.ReplicatedStorage.TrafficLightSystem.Sounds[sound]:Play()
	end
end)

local selectionui = nil
player.PlayerGui.ChildAdded:Connect(function(child)
	if child.Name == "SelectionGUI" then
		if child:FindFirstChild("TrafficLightSystemByKanuin111") then
			selectionui = child
			selectionui.Exit.MouseButton1Click:Connect(function()
				local intersection = selectionui.Adornee.Parent.Parent.Parent.Parent.Parent.Parent
				if not intersection then
					return
				end
				game.ReplicatedStorage.TrafficLightSystem.ClosedCardMenu:FireServer(intersection)
			end)
			selectionui.Identify.MouseButton1Click:Connect(function()
				local intersection = selectionui.Adornee.Parent.Parent.Parent.Parent.Parent.Parent
				if not intersection then
					return
				end
				local card = selectionui.Adornee.Parent
				local name = string.sub(card.Name, 6, -1)
				local lamp = intersection:FindFirstChild(name, true)
				if not lamp then
					selectionui.Identify.Visible = false
					task.wait(0.2)
					selectionui.Identify.Visible = true
					selectionui.Identify.BackgroundColor3 = Color3.fromRGB(255, 96, 96)
					task.wait(0.4)
					selectionui.Identify.Visible = false
					task.wait(0.2)
					selectionui.Identify.Visible = true
					selectionui.Identify.BackgroundColor3 = Color3.fromRGB(50,50,50)
				else
					identifyLamp(lamp)
				end
			end)
		end
	end
end)



--[[
if not mouse.Target then
		if selectedcard then
			moveModel(selectedcard, "down")
			selectedcard = nil
		end
		return
	end
	
	local card = nil
	local targetParent = mouse.Target.Parent
	if string.sub(targetParent.Name, 1, 5) == "Card_" and targetParent.Parent.Parent.Parent.Parent.Parent.Parent == game.Workspace.TrafficLights then
		card = targetParent
	elseif string.sub(targetParent.Parent.Name, 1, 5) == "Card_" and targetParent.Parent.Parent.Parent.Parent.Parent.Parent.Parent == game.Workspace.TrafficLights then
		card = targetParent.Parent
	end
	
	if card ~= selectedcard then
		if selectedcard then
			moveModel(selectedcard, "down")
		end

		selectedcard = card
		moveModel(selectedcard, "up")
		return
	end
	
	if selectedcard then
		moveModel(selectedcard, "down")
		selectedcard = nil
	end]]

--[[

if not model or not direction then
		return
	end
	direction = direction:lower()
	for count, object in model:GetDescendants() do
		if object:IsA("BasePart") then  -- Check if the object is a part
			if direction == "up" then
				animate(object, {CFrame = object.CFrame + Vector3.new(0, 0.102, 0)}, 0.3)
			else
				animate(object, {CFrame = object.CFrame - Vector3.new(0, 0.102, 0)}, 0.3)
			end
		end
	end]]
