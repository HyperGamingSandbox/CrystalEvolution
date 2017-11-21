
require("Control")

require("AppMessages")
require("AppConst")

local ThreadChild = require("Thread\\PumpChild")
local Server = ThreadChild:extend()
local MapGenerator = require("MapGenerator")
local Camera = require("Server\\Camera")

function Server:start()

	self:setMessageNames({
		[#M_Quit]				= "onQuit",
		[#M_SetScale]			= "onSetScale",
		[#WM_SIZE]				= "onSize",
		[#MMG_GenerateDone]		= "onMapGenerateDone",
		[#MMG_GenerateCount] 	= "onGenerateCount",
		[#M_ChangeDir]			= "onChangeDir",
		[#MMG_Done]				= "onDone"
	})

	self.rmap = _get(#G_RMAP)
	self.terrainMap = _get(#G_TERRAINMAP)

	-- generate map
	self.mg = MapGenerator:new(self.pump, self.childQueue, self.terrainMap)
	-- self.mg
	--[[
	self.terrainMap:circle(#MAP_MID + 20, #MAP_MID + 20, 1, 1, 7.5, function(m, x, y)
		m:expand(x, y)
		local b = m:getBlock(x, y)
		b:set(x, y, 1)
	end)
	]]

	self.camera = Camera:new(self.rmap, #MAP_MID * 1024 + 512, #MAP_MID * 1024 + 512)
	self.curMoveObject = self.camera
	self.rmap:setCoords(self.camera:getPosition(self.rmap:get(#RMF_CURSCALE), self.rmap:get(#RMF_CURW, 2)))

	self:messageLoop(1)

end

function Server:beforeReadMessage()
	if self.curMoveObject ~= nil then
		self.curMoveObject:update()
	end	
end

function Server:onQuit()
	self.work = false
end

function Server:onMapGenerateDone()
	self.rmap:update()
	if self.doneCount > 0 then
		self:send(#MMG_Done, self.doneCount)
	end
	self.doneCount = nil
	self:send(#MMG_GenerateDone)
end

function Server:onDone()
	self.doneCount = self.doneCount + 1
	if self.doneCount > 10 then
		self:send(#MMG_Done, self.doneCount)
		self.doneCount = 0
	end
end

function Server:onGenerateCount(count)
	self.doneCount = 0
	self:send(#MMG_GenerateCount, count)
end

function Server:onSize(w, h)
	self.rmap:setCoords(self.camera:getPosition(self.rmap:get(#RMF_CURSCALE), w, h))
end

function Server:onSetScale(_scale)
	local w, h = self.rmap:get(#RMF_CURW, 2)
	self.rmap:set(#RMF_CURSCALE, _scale)
	self.rmap:setCoords(self.camera:getPosition(_scale, w, h))
	self.rmap:setViewSize(w, h)
end

function Server:onChangeDir(dir)
	if self.curMoveObject ~= nil then
		self.curMoveObject:changeDir(dir)
	end
end

return Server