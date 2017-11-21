
installModule("queue")
local RendererHost = require("DD\\Renderer\\Host")

local Control = require("Control")
local Controls = require("Controls")

local VideoMenu = Control:extend()


function VideoMenu:initialize(optionFile, back_cb)

	self.queue = Queue:new()
	local g = optionFile:getGroup("video")
	g:addQueue(self.queue)
	self.g = g

	self.modeList = RendererHost.getModeList()

	self:add(Controls.CenterWindow:new(0, 0, 350, 600, 0x3c3c3c, 1, 0x7c7c7c))

	self.fullscreenControl = self:add(Controls.CheckBox:new(10, 10, "Fullscreen", g:get("fullscreen")))

	local onOption = function(name)
		self:activateOption(name)
	end

	self:add(Controls.Text:new(10, 50, "Aspect Ratio", _get(0), 0xffffff))

	self.options = {
		["4:3"] = self:add(Controls.RadioBox:new(10, 70, "4:3", false, onOption)),
		["16:9"] = self:add(Controls.RadioBox:new(120, 70, "16:9", false, onOption)),
		["16:10"] = self:add(Controls.RadioBox:new(220, 70, "16:10", false, onOption))
	}	

	self:add(Controls.Text:new(10, 110, "Size", _get(0), 0xffffff))
	self.comboModeList = self:add(Controls.ComboBox:new(10, 130, 330, 25))

	local w, h = g:get("screenWidth"), g:get("screenHeight")
	self:updateControls(w, h)

	self:add(Controls.Button:new(10, 530, 330, 25, "Apply", function()
		g:set("fullscreen", self.fullscreenControl.state)
		local item = self.comboModeList.currentItem
		g:set("screenWidth", item.w)
		g:set("screenHeight", item.h)
		RendererHost.switchMode(self.fullscreenControl.state, item.w, item.h)
	end))

	self:add(Controls.Button:new(10, 565, 330, 25, "Back", back_cb))

end

function VideoMenu:updateControls(w, h)
	for ratio, list in pairs(self.modeList) do
		for index, item in pairs(list) do
			if item.w == w and item.h == h then
				if self.options[ratio] ~= nil then
					local ctr = self.options[ratio]
					ctr:setState(true)
					self:activateOption(ratio)
					self.comboModeList:setListIndex(index)
				end				
			end
		end
	end
end

function VideoMenu:onDel()
	self.g:delQueue(self.queue)
end

function VideoMenu:activateOption(name)
	for optionName, option in pairs(self.options) do
		if name ~= optionName then
			option:setState(false)
		end
	end	

	self.comboModeList:hideList()
	self.comboModeList:setList(self.modeList[name], 1)
end

function VideoMenu:update()
	local read = false
	while not self.queue:empty() do
		local m = self.queue:get()
		read = true
	end
	if read then		
		self.fullscreenControl:setState(self.g:get("fullscreen"))
		self:updateControls(self.g:get("screenWidth"), self.g:get("screenHeight"))
	end
end

function VideoMenu.checkDefaultOptions(dd, optionFile)

	local g = optionFile:getGroup("video")

	if g:get("fullscreen") == nil then
		g:set("fullscreen", false)
	end

	if g:get("screenWidth") == nil then
		local w, h = dd:getScreenSize()
		g:set("screenWidth", w)
		g:set("screenHeight", h)
	end

	if g:get("windowX") == nil then
		g:set("windowX", -1)
		g:set("windowY", -1)
		g:set("windowWidth", -1)
		g:set("windowHeight", -1)
	end

end

return VideoMenu
