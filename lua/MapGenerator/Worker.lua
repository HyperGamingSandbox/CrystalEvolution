
installModule("data")

require("AppMessages")
require("AppConst")
installModule("random")

local ThreadChild = require("Thread\\PumpChild")
local Worker = ThreadChild:extend()
local MapGenerator = require("MapGenerator")

function Worker:init(terrainMap)
	self.terrainMap = terrainMap
end

function Worker:start()

	self:setMessageNames({
		[#M_Quit]			= "onQuit",
		[#MMG_MakeForest]	= "onMakeForest"
	})

	self:poolMessageLoop(1)

end

function Worker:onQuit()
	self.work = false
end

function Worker:onMakeForest(seed, x, y)
	local r = Random:new(seed)
	self.terrainMap:makeGrass(r, x, y)
	self:send(#MMG_Done)
end

return Worker