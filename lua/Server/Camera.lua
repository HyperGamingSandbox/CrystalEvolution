local Object = require("Object")
local Camera = Object:extend()
local scale = require("scale")

local f = queryPerformanceFrequency()
local period = math.floor(f / 10000)

function Camera:initialize(rmap, x, y)
	self.rmap = rmap
	self.x = x
	self.y = y
	self.dir = -1
	self.counter = queryPerformanceCounter()
end

function Camera:getPosition(_scale, w, h)

	local m, d = unpack(scale.d[_scale + 1])

	local k = 2.56 * d / m
	dprint("k " .. k .. " w " .. w .. " h " .. h)

	local x, y =  math.floor(self.x - w * k), math.floor(self.y - h * k)
	dprint("" .. (x - #MAP_MID * 1024) .. " " .. (y - #MAP_MID * 1024))
	return x, y
end

function Camera:changeDir(dir)
	self.dir = dir
end

local k = math.pi / 4
local k2 = math.pi + math.pi / 2
-- local v = 660
local v = 1560
local vm = v / 1000000

function Camera:update()

	local q = self:getQuant()
	if q == -1 then return end
	if self.dir == -1 then return end

	local v = q * vm

	local dx = ( math.cos(self.dir * k + k2) * v )
	local dy = ( math.sin(self.dir * k + k2) * v )

	local _scale = self.rmap:get(#RMF_CURSCALE)
	local m, d = unpack(scale.d[_scale + 1])

	self.x = self.x + dx * d / m
	self.y = self.y + dy * d / m

	self.rmap:setCoords(self:getPosition(_scale, self.rmap:get(#RMF_CURW, 2)))

end

function Camera:getQuant()
	
	local c = queryPerformanceCounter()
	local t = c - self.counter
	--[[
	local e = t * 1000000 / f
	self.counter = self.counter + t
	return e
	]]

	if t < period then return -1 end

	t = math.floor(t / period) * period
	local e = (0.0 + t) * 1000000.0 / (f + 0.0)

	self.counter = self.counter + t
	return e

end


return Camera