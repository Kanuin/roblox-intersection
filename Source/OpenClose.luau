local TweenService = game:GetService("TweenService")

-- Your provided animate function
local function animate(object, goal, animtime, style, direction)
	local tweenInfo = TweenInfo.new(
		animtime, -- Time (0.5 seconds for fast opening/closing)
		style or Enum.EasingStyle.Sine, -- EasingStyle (Sine for smooth, realistic motion)
		direction or Enum.EasingDirection.Out, -- EasingDirection (Out for deceleration)
		0, -- RepeatCount
		false, -- Reverses
		0 -- DelayTime
	)
	local tween = TweenService:Create(object, tweenInfo, goal)
	tween:Play()
end

-- Store the initial CFrame of the hinge at the start
local hingeHitbox = script.Parent.HingeHitbox
local initialCFrame = hingeHitbox.CFrame -- Store initial CFrame

script.Parent.Handle.ProximityPrompt.Triggered:Connect(function(plr)
	-- Check if the door is in the closed position by comparing the current CFrame with the initial CFrame
	if hingeHitbox.CFrame == initialCFrame then
		--plr.Character:PivotTo(script.Parent.Parent.UserTPPos.CFrame)
		animate(plr.Character:WaitForChild("HumanoidRootPart"), { CFrame = script.Parent.Parent.UserTPPos.CFrame }, 0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
		-- open the door by rotating 90 degrees around the Y-axis with realistic easing
		local goal = { CFrame = hingeHitbox.CFrame * CFrame.Angles(0, math.rad(90), 0) }
		animate(hingeHitbox, goal, 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out) -- 0.5s speed for opening
		script.Parent.Parent.Parent.Parent.Values.CurrentPlayer.Value = plr
		script.Parent.Handle.ProximityPrompt.Enabled = false
		game.ReplicatedStorage.TrafficLightSystem.OpenCamera:FireClient(plr, script.Parent.Parent.CamPosTop, script.Parent.Parent.CamPosMiddle)
	end
end)

game.ReplicatedStorage.TrafficLightSystem.ClosedMenu.OnServerEvent:Connect(function()
	-- close the door by rotating back to the initial position with smoother closing easing
	script.Parent.Parent.Parent.Parent.Values.CurrentPlayer.Value = nil
	local goal = { CFrame = initialCFrame }
	animate(hingeHitbox, goal, 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut) -- InOut for smooth start and finish during closing
	wait(1)
	script.Parent.Handle.ProximityPrompt.Enabled = true
end)
