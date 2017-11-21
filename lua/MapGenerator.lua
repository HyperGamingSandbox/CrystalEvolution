local Object = require("Object")
local MapGenerator = Object:extend()
installModule("terrain_map")
installModule("random")
local ThreadPool = require("Thread\\Pool")

local circle = math.pi + math.pi
local circleOfsset = circle / 2 + circle / 4
local circle_2 = circle / 2
local circle_4 = circle / 4
local circle_8 = circle / 8
local circle_16 = circle / 16

function TerrainMap:circle(x, y, m, n, r, func)

	local steps = r * math.pi * 2
	local step = circle / steps / 2
	local axis = circleOfsset
	local y1, cnt = nil, 0
	local xx1, x1 = 0

	local d = function()
		if cnt > 0 then

			local y2 = y1 + y
			local a = xx1 / cnt
			local j, je = x - a, x + a
			
			je = math.ceil(je)			

			while j <= je do
				func(self, j, y2)
				j = j + 1
			end

		end
	end

	local i = 1
	while i <= steps do

		axis = axis + step
		local cy = math.ceil(r * math.sin(axis) / n)
		x1 = r * math.cos(axis) / m
		
		if cy ~= y1 then
			d()
			y1, cnt, xx1 = cy, 0, 0
		end
		cnt = cnt + 1
		xx1 = xx1 + x1

		i = i + 1
	end
	d()

end

function TerrainMap:makeFigure(r, x, y, opt)

	local branches = { }
	local startAxis

	if opt.branchStartAxis == -1 then
		startAxis = circle / 10000 * r:get(10000)
	else
		startAxis = opt.branchStartAxis + circleOfsset
	end

	for i = 1, opt.branches do
		local axis = startAxis
		if opt.branchStartDeviation ~= 0 then
			local j = r:get(1000)
			if j % 2 == 0 then j = j * -1 end
			local o = opt.branchStartDeviation / 1000 * j
			axis = axis + o
		end
		branches[i] = {
			segments = 0,
			axis = axis,
			x = x,
			y = y,
			dot = opt.dot
		}
		startAxis = startAxis + opt.branchStartAxisStep
	end

	for s = 1, opt.branchSegments do

		for i = 1, opt.branches do
			local b = branches[i]
			for d = 1, opt.branchSegmentDotCount do
				b.x = b.x + math.cos(b.axis)
				b.y = b.y + math.sin(b.axis)
				local x = math.floor(b.x)
				local y = math.floor(b.y)
				self:circle(x, y, 1, 1, b.dot / 2 + 0.3, opt.dotFunc)
				if opt.afterPlaceDotCB ~= nil then
					opt.afterPlaceDotCB(x, y, b.dot, opt.ctx)
				end

				if opt.dotChange ~= nil then
					local change = r:get(100)
					if change < opt.dotChange then
						if b.dot == opt.dotMin then
							b.dot = b.dot + 1
						elseif b.dot == opt.dotMax then
							b.dot = b.dot - 1
						else
							change = r:get(100)
							if change < 50 then
								b.dot = b.dot + 1
							else
								b.dot = b.dot - 1
							end
						end
					end
				end
			end

			if opt.segmentCB ~= nil then
				opt.segmentCB(b.x, b.y, opt.ctx)
			end

			b.segments = b.segments + 1

			if opt.branchDividing ~= nil and b.segments == opt.branchDividing then
				b.segments = 0

				local axis = b.axis - opt.branchDivideDeviation / 2
				local d = opt.branchDivideDeviation / opt.branchDivideCount
				local bi = { i }
				for j = 1, opt.branchDivideCount do
					local ni = opt.branches + 1
					opt.branches = ni
					axis = axis + d
					local nb = {
						segments = 0,
						axis = axis,
						x = b.x,
						y = b.y,
						dot = opt.dot
					}
					branches[ni] = nb
				end

				for ind, v in pairs(bi) do
					local b = branches[v]

					local j = r:get(1000)
					if j % 2 == 0 then j = j * -1 end
					local o = opt.branchSegmentDeviation / 1000 * j
					-- lprint("o " .. o)
					b.axis = b.axis + o
				end

			else
				local j = r:get(1000)
				if j % 2 == 0 then j = j * -1 end
				local o = opt.branchSegmentDeviation / 1000 * j
				b.axis = b.axis + o
			end

		end

	end

end

function TerrainMap:makeGrass(r, x, y)

	local ctx = { x1 = x, y1 = y, x2 = x, y2 = y, x = x, y = y }

	self:makeFigure(r, x, y, {
		branches = 1,
		branchStartAxis = 0,
		branchStartAxisStep = circle,
		branchStartDeviation = circle,
		dot = 5,
		dotMin = 5,
		dotMax = 12,
		dotChange = 60,
		branchSegments = 6 + math.floor(math.pow(r:get(19), 3) / 400),
		branchSegmentDeviation = circle_8,
		branchSegmentLength = 4,
		branchSegmentDotCount = 2,
		ctx = ctx,
		afterPlaceDotCB = function(x, y, size, ctx)

			if x - size < ctx.x1 then ctx.x1 = x - size end
			if x + size > ctx.x2 then ctx.x2 = x + size end
			if y - size < ctx.y1 then ctx.y1 = y - size end
			if y + size > ctx.y2 then ctx.y2 = y + size end

		end,

		dotFunc = function(m, x, y)
			m:expand(x, y)
			local b = m:getBlock(x, y)
			b:set(x, y, 1)
		end
	})

	local size = 6
	ctx.x1 = ctx.x1 - size
	ctx.x2 = ctx.x2 + size
	ctx.y1 = ctx.y1 - size
	ctx.y2 = ctx.y2 + size
	local w = (ctx.x2 - ctx.x1) / 2
	local h = (ctx.y2 - ctx.y1) / 2
	local r, m, n
	if w > h then
		r = w
		m = 1
		n = w / h
	else
		r = h
		m = h / w
		n = 1
	end

	self:circle(ctx.x1 + w, ctx.y1 + h, m, n, r * 1.3, function(m, x, y)
		local id = m:getCell(x, y)
		if id == 0 or id == #ABSENT_CELL then
			m:expand(x, y)
			local b = m:getBlock(x, y)
			b:set(x, y, 2)
		end
	end)

end



function MapGenerator:initialize(pump, queue, terrainMap)

	self.queue = queue
	self.workersPool = ThreadPool:new("MapGenerator\\Worker", queue, 6, terrainMap)

	pump:addNames({
		[#MMG_Done]		= "onDone"
	})
	pump:registerReciever(self)


	local r = Random:new(0)

	local cnt_forest = 50
	local s, c = 15, cnt_forest
	local h = s * (c + 1) / 2

	local count = cnt_forest * cnt_forest
	self.queue:send(Array:new(#MMG_GenerateCount, count))

	for y = 1, c do		
		for x = 1, c do
			local xo = r:get(10) - 5
			local yo = r:get(10) - 5
			local x, y, seed = x * s - h + xo + #MAP_MID, y * s - h + yo + #MAP_MID, r:seed()
			self.workersPool:send(#MMG_MakeForest, seed, x, y)
			-- self.terrainMap:makeGrass(r, )
		end
		-- self.progressBar:inc()
	end

	-- dprint("count " .. count)


	self.r = r
	self.count = count
	self.current = 0

end

function MapGenerator:onDone()
	self.current = self.current + 1
	if self.current >= self.count then
		self.queue:send(Array:new(#MMG_GenerateDone))
		self.workersPool:sendAll(#M_Quit)
	end
end

return MapGenerator