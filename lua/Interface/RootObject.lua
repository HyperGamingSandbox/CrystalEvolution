
local Control = require("Control")
local Object = require("Object")
local RootObject = Object:extend()
local RendererHost = require("DD\\Renderer\\Host")

function RootObject:adterDel()
	self:hoverObjectLeave()
	RendererHost.setCursor(#Cursor_Arrow)
	self:onMouseMove(self, self.mx, self.my)
end

function RootObject:hoverObjectLeave()

	if self.hoveredObject == nil then return end

	local p = self.hoveredObject:get(#ROF_LPUSHSTATE)
	if p then
		self.hoveredObject:set(#ROF_LPUSHSTATE, false)
		self.hoveredObject:event(#ROF_LUP)
	end

	self.hoveredObject:set(#ROF_ISHOVER, false)

	self.hoveredObject:set(#ROF_LPUSHSTATE, false)
	self.hoveredObject:event(#ROF_ONHOVERLOST)
	self.hoveredObject = nil

end

function RootObject:onMouseMove(o, x, y)
	-- lets walk throw all layers

	self.mx = x
	self.my = y

	local childs = self.rootObject:get(#ROF_CHILDS)
	local i, hid = childs:count(), 0
	if self.hoveredObject ~= nil then
		hid = self.hoveredObject:get(#ROF_ID)
		if hid == nil then
			hid = 0
			self.hoveredObject = nil
		end
	end

	while i > 0 do
		i = i - 1
		local layer = childs:get(i)
		-- dprint("layer:isPointOn")
		local newHoveredObject = layer:isPointOn(x, y)
		-- dprint("layer:isPointOn end")

		if newHoveredObject ~= nil then

			-- dprint("newHoveredObject")

			local id = newHoveredObject:get(#ROF_ID)
			if id == hid then
				return
			end

			if hid > 0 then
				self:hoverObjectLeave()
			end

			-- onHover event
			self.hoveredObject = newHoveredObject
			self.hoveredObject:set(#ROF_ISHOVER, true)
			self.hoveredObject:event(#ROF_ONHOVER)

			if self.lstate then
				self.hoveredObject:set(#ROF_LPUSHSTATE, true)
				self.hoveredObject:event(#ROF_LDOWN)
			end

			return

		end		
	end

	if hid > 0 then
		self:hoverObjectLeave()
	end
end

function RootObject:onLDown(o)
	self.lstate = true
	if self.hoveredObject ~= nil then
		self.hoveredObject:set(#ROF_LPUSHSTATE, true)
		self.hoveredObject:event(#ROF_LDOWN)
	end
end

function RootObject:onLUp(o)
	self.lstate = false
	if self.hoveredObject ~= nil then
		self.hoveredObject:set(#ROF_LPUSHSTATE, false)
		self.hoveredObject:event(#ROF_LUP)
		self.hoveredObject:event(#ROF_LCLICK)
	end

end

local childProxyEvent = function(event)
	return event, function(self, ...)
		self:cevent(event, ...)
	end
end

function RootObject:initialize()

	self.hoveredObject = nil
	self.lstate = false

	self.rootObject = RenderObject:new()

	self.rootObject:set(#ROF_ONMOUSEMOVE, function(o, x, y)
		self:onMouseMove(o, x ,y)
	end)

	self.rootObject:set(#ROF_LDOWN, function(o)
		self:onLDown(o)
	end)

	self.rootObject:set(#ROF_LUP, function(o)
		self:onLUp(o)
	end)

	self.rootObject:set(childProxyEvent(#ROF_ONVIEWSIZE))

	self.mapLayer = self.rootObject:add(RenderObject:new())
	self.mapLayer:set(childProxyEvent(#ROF_ONVIEWSIZE))

	self.objectsLayer = self.rootObject:add(RenderObject:new())

	self.interfaceLayer = self.rootObject:add(RenderObject:new())
	self.interfaceLayer:set(childProxyEvent(#ROF_ONVIEWSIZE))

	self.overlayLayer = self.rootObject:add(RenderObject:new())

end

return RootObject