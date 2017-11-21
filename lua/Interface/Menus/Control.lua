local Control = require("Control")
local Controls = require("Controls")

local ControlMenu = Control:extend()

function ControlMenu:initialize()
end

function ControlMenu.checkDefaultOptions(optionFile)

	local g = optionFile:getGroup("keys")

	local default = {
		up 		= #Key_W,
		down 	= #Key_S,
		left 	= #Key_A,
		right 	= #Key_D,
		map 	= #Key_M
	}

	for name, code in pairs(default) do
		if g:get(name) == nil then
			g:set(name, code)
		end
	end

end

return ControlMenu