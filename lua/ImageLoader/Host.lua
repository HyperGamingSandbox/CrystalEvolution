local Object = require("Object")
local Loader = Object:extend()
local ProgressBar = require("Controls\\ProgressBar")
local ThreadPool = require("Thread\\Pool")
local scale = require("scale")

#const W_Read 			1
#const W_Scale 			2
#const W_Split			3

function Loader:initialize(layer, queue, pump)

	pump:addNames({
		[#M_ImageData]		= "onImageData"
	})
	pump:registerReciever(self)

	self.pump = pump
	self.queue = queue
	self.layer = layer

	self.tasks = 0
	self.load = { }
	self.afterWork = { }

	self:addLoad("controls.png")
	self:addScale(#T_GRASS)
	self:addScale(#T_GROUND)
	self:addScale(#T_WATER)
	self:addScale(#T_MOUNTAIN)
	self:addScale(#T_STONE)
	self:addScale(#T_CRYSTAL)

	-- dprint("tasks " .. self.tasks)

	self:startWork(self.load)

	self.progressBar = layer:add(ProgressBar:new("Load images", self.tasks))

end

function Loader:onImageData(name)
	self.progressBar:inc()
	self:startWork(self.afterWork[name])
	if self.progressBar.count == self.progressBar.current then
		self.layer:del(self.progressBar)
		if self.readPool ~= nil then
			self.readPool:sendAll(#M_Quit)
		end
		if self.scalePool ~= nil then
			self.scalePool:sendAll(#M_Quit)
		end
		self.pump:unregisterReciever(self)
		self.queue:send(Array:new(#M_LoadDone))
	end
end

function Loader:sendToReader(name)

	if self.readPool == nil then
		self.readPool = ThreadPool:new("ImageLoader\\Reader", self.queue, 8)
	end

	self.readPool:send(#M_ReadImage, name)	

end

function Loader:sendToScaler(src, dst, m, d)

	if self.scalePool == nil then
		self.scalePool = ThreadPool:new("ImageLoader\\Scaler", self.queue, 8)
	end

	self.scalePool:send(#M_ScaleImage, src, dst, m, d)	

end


function Loader:addLoad(name)

	self.tasks = self.tasks + 1

	table.insert(self.load, { type = #W_Read, name = name })

end

function Loader:addScale(name)

	self.tasks = self.tasks + scale.count + 1
	table.insert(self.load, { type = #W_Read, name = name})

	local list = { }
	for i = 1, scale.count do
		local m, d = unpack(scale.d[i])
		table.insert(list, { type = #W_Scale, src = name, dst = name .. "_" .. (i - 1), m = m, d = d })
	end

	self.afterWork[name] = list
end


function Loader:startWork(list)

	if list == nil then return end

	for i, work in pairs(list) do

		if work.type == #W_Read then

			self:sendToReader(work.name)

		elseif work.type == #W_Scale then

			self:sendToScaler(work.src, work.dst, work.m, work.d)

		elseif work.type == #W_Split then

			self:sendToSplitter(work.src, work.dst, work.w, work.h, work.x, work.y)
		end

	end

end

function Loader:update()
end

return Loader 