local key = script.Parent.Parent.Key
local label = script.Parent.Parent.Label
local ring = script.Parent.Parent.Ring
local function show()
	label.Top.Transparency = 0
	label.Bottom.Transparency = 0
	label.Transparent.Transparency = 0.25
	
	label.Number.Transparency = 0
	label.Number.GUI_1.Enabled = true
	label.Number.GUI_2.Enabled = true
	
	ring.Transparency = 0
	key.Transparency = 0
end

local function hide()
	label.Top.Transparency = 1
	label.Bottom.Transparency = 1
	label.Transparent.Transparency = 1

	label.Number.Transparency = 1
	label.Number.GUI_1.Enabled = false
	label.Number.GUI_2.Enabled = false

	ring.Transparency = 1
	key.Transparency = 1
end

script.Parent:GetPropertyChangedSignal("Value"):Connect(function()
	if script.Parent.Value == true then
		show()
	else
		hide()
	end
end)

hide()
script.Parent.Value = false
