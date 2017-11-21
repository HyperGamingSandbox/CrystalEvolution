
local Control = require("Control")
local Controls = require("Controls")

local DebugOverlay = Control:extend()

function _f(a)
	if a == nil then return "" end
	return "" .. a
end

function DebugOverlay:addPair(name, val, p)
	self:add(Controls.Text:new(7, 7 + self.y * self.sz, name, _get(0), 0xffffff))
	local control = self:add(Controls.Text:new(167, 7 + self.y * self.sz, _f(val), _get(0), 0xffffff))
	if p ~= nil then
		p.control = control
	else
		self.clsControls[name] = control
	end
	self.y = self.y + 1
end


function DebugOverlay:initialize(opt, args)

	self.opt = opt
	self.args = args

	local sz = 20
	self.sz = sz

	self.windowControl = self:add(RBox:new(10, 10, 220, 11 + sz * (table.getn(args)), 0x3c3c3c, 1, 0xe0e0e0))

	self.y = 0
	for i, p in ipairs(args) do
		self:addPair(p[1], p[2](), p)
	end

	if self.opt.classes ~= nil then
		self.clsControls = { }
		self:updateClasses()
	end


	self.f = queryPerformanceFrequency()
	self.p = self.f / 25
	self.time = queryPerformanceCounter()	

end

function DebugOverlay:updateClasses()
	local p = 2	
	local t = { luaClassInstanceCountByName() }
	local cnt = t[1]
	while cnt > 0 do
		local name = t[p]
		local control = self.clsControls[name]
		if control ~= nil then
			control:set(#RTF_TEXT, _f(t[p + 1]))
		else
			self:addPair(name, t[p + 1])
			self.windowControl:set(#ROF_H, 11 + self.sz * self.y)
		end
		
		cnt = cnt - 1
		p = p + 2

	end
end


function DebugOverlay:update()

	local time = queryPerformanceCounter()	
	if time - self.time < self.p then return end
	self.time = self.time + self.p

	collectgarbage()

	for i, p in ipairs(self.args) do
		p.control:set(#RTF_TEXT, _f(p[2]()))
	end

	if self.opt.classes ~= nil then
		self:updateClasses()
	end
end

return DebugOverlay