
local Control = require("Control")
local Controls = require("Controls")
local RendererHost = require("DD\\Renderer\\Host")

local innerPosition = function(self, parent)
	local x, y = parent:get(#ROF_X, 2)
	local bx, by = self:get(#ROF_BX, 2)
	self:set(#ROF_X, x + bx, y + by, parent:get(#ROF_W))
	self:cevent(#ROF_ONPARENTCHANGEPOS, self)
end

local InnerRBox = Control.makeWrap(RBox)
-- InnerRBox:addEvents(Control.elibs.innerPosition)
InnerRBox:addEvents({
	onParentChangePos = innerPosition,
	onAdd = innerPosition
})

local calcPos = function(o, w, h)	
	local oh = o:get(#ROF_H)
	local ow = math.floor(w * 6 / 10)
	o:set(#ROF_W, ow)
	local x, y = (w - ow) / 2, (h - oh) / 2
	o:set(#ROF_X, math.floor(x), math.floor(y))	
	o:cevent(#ROF_ONPARENTCHANGEPOS, o)
end

--[[
InnerRBox:addEvents({
	onAdd = function(self)
		-- dprint("onAdd")
		calcPos(self, RendererHost.getViewSize())
	end,
	onViewSize = function(self, w, h)
		-- dprint("onViewSize")
		calcPos(self, w, h)
	end
})
]]

local Wrap = Control.makeWrap(RenderObject)
-- Wrap:addEvents(Control.elibs.innerPosition)
Wrap:addEvents({
	onAdd = function(self)
		-- dprint("onAdd")
		calcPos(self, RendererHost.getViewSize())
	end,
	onViewSize = function(self, w, h)
		-- dprint("onViewSize")
		calcPos(self, w, h)
	end
})



local ProgressBar = Control:extend()

function ProgressBar:initialize(caption, count)

	self.count = count
	self.current = 0
	self.p = 0

	local h = 40
	self.caption = caption

	self.wrap = self:add(Wrap:new())
	self.wrap:set(#ROF_X, 0, 0, 0, h)
	self.wrap:set(#ROF_BX, 0, 0)
	self.wrap:set(#ROF_SKIPHOVER, true)

	local o = self:add(InnerRBox:new(0, 0, 0, h, 0, 1, 0xffffff))

	local wrap = self

	local InnerRRect = Control.makeWrap(RRect)
	local innerPosition = function(self, parent)
		local x, y = parent:get(#ROF_X, 2)
		local bx, by = self:get(#ROF_BX, 2)
		self:set(#ROF_X, x + bx, y + by, wrap:getW(parent))
		self:cevent(#ROF_ONPARENTCHANGEPOS, self)
	end

	InnerRRect:addEvents({
		onParentChangePos = innerPosition,
		onAdd = innerPosition
	})

	self.progress = self:add(InnerRRect:new(3, 3, 0, h - 6, 0xffffff)) 

	self.captionControl = self:add(Controls.Text:new(3, h + 3, "", _get(0), 0xffffff))
	self:updateCaption()
	
end

function ProgressBar:updateCaption()

	self.p = math.floor(self.current * 100 / self.count)
	self.captionControl:set(#RTF_TEXT, self.caption .. " " .. self.p .. "%")

end


function ProgressBar:getW(parent)
	local w = parent:get(#ROF_W) - 6
	return math.floor(w * self.p / 100)
end


function ProgressBar:inc(count)
	if count == nil then count = 1 end
	self.current = self.current + count
	self:updateCaption()
	-- local w = self.wrap:get(#ROF_W) - 6
	self.progress:set(#ROF_W, self:getW(self.wrap))
end

function ProgressBar:setCaption(caption)
	self.caption = caption
	self:updateCaption()
end

return ProgressBar