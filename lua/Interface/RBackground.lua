local Control = require("Control")
local RendererHost = require("DD\\Renderer\\Host")
local RBackground = Control.makeWrap(RRect)

RBackground:addEvents({
	initArgs = function()
		local w, h = RendererHost.getViewSize()
		return 0, 0, w, h, 0x000000
	end,
	onViewSize = function(self, w, h)
		self:set(#ROF_W, w, h)
	end
})

return RBackground