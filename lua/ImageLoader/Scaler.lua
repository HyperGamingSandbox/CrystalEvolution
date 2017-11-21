
installModule("data")
installModule("image")

require("AppMessages")
require("AppConst")

local ThreadChild = require("Thread\\PumpChild")
local Scaler = ThreadChild:extend()

function Scaler:start()

	-- C_Thread_SetName("Reader:" .. self.index)
	self:setMessageNames({
		[#M_Quit]		= "onQuit",
		[#M_ScaleImage]	= "onScale"
	})

	self.imageMap = _get(#IMAGES)

	self:poolMessageLoop(0)

end

function Scaler:onQuit()
	self.work = false
end

function Scaler:onScale(src, dst, m, d)

	local image = self.imageMap:get(src)
	local scaleImage = image:scale(m, d)

	self.imageMap:set(dst, scaleImage)
	self:send(#M_ImageData, dst)
end

return Scaler