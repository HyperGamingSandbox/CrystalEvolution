
installModule("data")
installModule("image")

require("AppMessages")
require("AppConst")

local ThreadChild = require("Thread\\PumpChild")
local Reader = ThreadChild:extend()

function Reader:start()

	-- C_Thread_SetName("Reader:" .. self.index)
	self:setMessageNames({
		[#M_Quit]		= "onQuit",
		[#M_ReadImage]	= "onRead"
	})

	self.imageMap = _get(#IMAGES)

	self:poolMessageLoop(0)

end

function Reader:onQuit()
	self.work = false
end

function Reader:onRead(name)
	self.imageMap:set(name, Image:new(loadFileData("resource\\" .. name)))
	self:send(#M_ImageData, name)
end

return Reader