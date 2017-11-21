
local Control = require("Control")
local Controls = require("Controls")

local MainMenu = Control:extend()

function MainMenu:initialize(
	gameExists,
	video_cb, interface_cb, play_cb, quit_cb,
	pause_cb, continue_cb, save_cb
)

	self:add(Controls.CenterWindow:new(0, 0, 350, 600, 0x3c3c3c, 1, 0x7c7c7c))

	self:add(Controls.Button:new(10, 10, 330, 25, "Video", video_cb))
	self:add(Controls.Button:new(10, 45, 330, 25, "Keys"))
	self:add(Controls.Button:new(10, 80, 330, 25, "Interface", interface_cb))

	if gameExists then
		self:add(Controls.Button:new(10, 115, 330, 25, "Pause game", pause_cb))
		self:add(Controls.Button:new(10, 150, 330, 25, "Continue game", continue_cb))
		self:add(Controls.Button:new(10, 185, 330, 25, "Save game", save_cb))
		self:add(Controls.Button:new(10, 220, 330, 25, "Load game"))
	else
		self:add(Controls.Button:new(10, 115, 330, 25, "Play", play_cb))
	end

	self:add(Controls.Button:new(10, 565, 330, 25, "Quit", quit_cb))

end

return MainMenu