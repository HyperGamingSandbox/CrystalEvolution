installModule("terrain_map")
local Object = require("Object")

local Const = require("AppConst")
local scale = require("scale")
local Control = require("Control")
local RendererHost = require("DD\\Renderer\\Host")
local ThreadHost = require("Thread\\Host")
local ProgressBar = require("Controls\\ProgressBar")

local Game = Object:extend()

function Game:initialize(mapLayer, queue, pump, keys, optionFile, layer)

	self.layer = layer

	self.keys = keys
	keys:registerReciever(self)
	self.optionFile = optionFile

	self.mapLayer = mapLayer

	self.map = TerrainMap:new()
	_set(#G_TERRAINMAP, self.map)

	local WRMap = Control.makeWrap(RMap)
	WRMap:addEvents({
		onAdd = function(self)
			self:setViewSize(RendererHost.getViewSize())
		end,
		onViewSize = function(self, w, h)
			self:setViewSize(w, h)
		end
	})

	local t = Const.TerrainImages
	self.rmap = WRMap:new(self.map, scale.count, table.getn(t) + 1)
	_set(#G_RMAP, self.rmap)

	self.scale = 0
	local images = _get(#IMAGES)
	for i = 1, scale.count do
		local scaleIndex = i - 1
		local m, d = unpack(scale.d[i])

		self.rmap:setScaleInfo(scaleIndex, 200 * m / d, 200 * m /d)
		for j = 1, table.getn(t) do
			local item = t[j]
			self.rmap:setCellImage(scaleIndex, item.id, images:get(item.name .. "_" .. scaleIndex))
		end
	end

	self.rmap:setCoords(#MAP_MID * 1024, #MAP_MID * 1024)
	
	self.mapLayer:add(self.rmap)

	self.server = ThreadHost:new("Server\\Server", queue)

	pump:addNames({
		[#WM_MOUSEWHEEL]		= "onMouseWheel",
		[#WM_SIZE]				= "onSize",
		[#MMG_GenerateCount]	= "onGenerateCount",
		[#MMG_Done]				= "onGenerateWorkDone",
		[#MMG_GenerateDone]		= "onGenerateDone"
	})
	pump:registerReciever(self)
	
end

function Game:onGenerateWorkDone(count)
	-- dprint("onGenerateWorkDone")
	self.progressBar:inc(count)
end

function Game:onGenerateDone()
	self.layer:del(self.progressBar)
	self.progressBar = nil
end

function Game:onGenerateCount(count)
	self.progressBar = self.layer:add(ProgressBar:new("Generating map - forest", count))
end

function Game:onSize(w, h)
	self.server:send(#WM_SIZE, w, h)
end

function Game:onMouseWheel(dir)
	if dir < 0 then
		-- forward
		if self.scale ~= scale.count - 1 then
			self:setScale(self.scale + 1)
		end
	else
		if self.scale ~= 0 then
			self:setScale(self.scale - 1)
		end
	end
end

function Game:setScale(_scale)
	self.scale = _scale
	self.server:send(#M_SetScale, _scale)
	-- send to server
	--[[
	self.rmap:set(#RMF_CURSCALE, _scale)
	self.rmap:setViewSize(RendererHost.getViewSize())
	]]
end

local dirs = {
	{ 7, 0, 1 },
	{ 6,-1, 2 },
	{ 5, 4, 3 }
}

function Game:checkChangeDirection(key)

	local keys = self.optionFile:getGroup("keys")
	local keyStates = self.keys.keyStates

	local up = keys:get("up")
	local down = keys:get("down")
	local left = keys:get("left")
	local right = keys:get("right")

	if key == up or key == down or key == left or key == right then
		local x, y = 2, 2
		if keyStates[up]		then y = y - 1 end
		if keyStates[down]		then y = y + 1 end
		if keyStates[left]		then x = x - 1 end
		if keyStates[right]		then x = x + 1 end		
		local dir = dirs[y][x]
		self.server:send(#M_ChangeDir, dir)
	end

end

function Game:keyPressed(key, alt)
	self:checkChangeDirection(key)
end

function Game:keyUnPressed(key, alt)
	self:checkChangeDirection(key)
end

function Game:save()
	local d = self.map:store()
	
end

return Game 