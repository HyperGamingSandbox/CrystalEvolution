
installModule("data")
installModule("image")
installModule("map")

require("AppMessages")
local Const = require("AppConst")
local Control = require("Control")

local Object = require("Object")
local RendererHost = require("DD\\Renderer\\Host")
local ThreadPumpChild = require("Thread\\PumpChild")
local LightThread = require("LightThread")
local Keys = require("Keys")

local Interface = ThreadPumpChild:extend()
local OptionFile = require("OptionFile")

local RootObject = require("Interface\\RootObject")
local RBackground = require("Interface\\RBackground")
local MainMenu = require("Interface\\Menus\\Main")
local VideoMenu = require("Interface\\Menus\\Video")
local ControlMenu = require("Interface\\Menus\\Control")
local DebugOverlay = require("Interface\\DebugOverlay")

local Loader = require("ImageLoader\\Host")
local Game = require("Game\\Game")

function Interface:init(wnd)
	self.wnd = wnd

	self.images = Map:new()
	self.images:setmt()
	_set(#IMAGES, self.images)

end

function Interface:start()

	self:setMessageNames({
		[#M_Quit]		= "onQuit",
		[#M_LoadDone]	= "onLoadDone"
	})

	self.keys = Keys:new()
	self.keys:attachToPump(self.pump)
	self.keys:registerReciever(self)

	self.dd = DD:new()
	self:send(#M_DD, self.dd)

	self.optionFile = OptionFile:new("game.cfg")
	VideoMenu.checkDefaultOptions(self.dd, self.optionFile)
	ControlMenu.checkDefaultOptions(self.optionFile)

	self.rootObject = RootObject:new()

	self.renderer = RendererHost:new(
		self.dd, self.wnd, self.pump, self.childQueue, self.rootObject.rootObject,
		self.ownerQueue, "Interface\\RenderInfoCollector", self.optionFile
	)

	local g = self.optionFile:getGroup("video")

	RendererHost.switchMode(g:get("fullscreen"), g:get("screenWidth"), g:get("screenHeight"))

	self.background = self.rootObject.mapLayer:add(RBackground:new())

	self.debugOverlay = self.rootObject.overlayLayer:add(DebugOverlay:new({
		classes = true
		},{
		{ "fps", function() return _get(1) end },
		{ "frame time", function() return _get(2) end },
		{ "sleep ms", function() return _get(3) end },
		{ "ms with sleep", function() return _get(4) end },
		{ "classes", function() return luaClassInstanceCount() end }		
	}))

	
	self.loader = Loader:new(
		self.rootObject.interfaceLayer,
		self.childQueue,
		self.pump
	)

	self:messageLoop(3)

end

function Interface:onLoadDone()
	self.loader = nil
	self:openMainMenu()
end

function Interface:openMainMenu()
	self.mainMenu = self.rootObject.interfaceLayer:add(MainMenu:new(
		-- exist game
		self.game ~= nil,
		-- video
		function()
			self:openVideoMenu()
			self.rootObject.interfaceLayer:del(self.mainMenu)
			self.mainMenu = nil			
		end,
		-- interface_cb
		function()
		end,
		-- play_cb
		function()			

			self.game = Game:new(
				self.rootObject.mapLayer,
				self.childQueue,
				self.pump,
				self.keys,
				self.optionFile,
				self.rootObject.interfaceLayer
			)

						
			self.rootObject.mapLayer:del(self.background)
			self.background = nil

			self.rootObject.interfaceLayer:del(self.mainMenu)
			self.mainMenu = nil

			self.rootObject:adterDel()

			collectgarbage()
		end,
		-- quit_cb
		function()
			self:send(#M_APPQuit)
		end,
		-- pause
		function()
		end,
		-- continue
		function()
			self.rootObject.interfaceLayer:del(self.mainMenu)
			self.mainMenu = nil

			self.rootObject:adterDel()
		end,
		-- save
		function()
			self.game:save()
		end
	))
end

function Interface:openVideoMenu()
	self.videoMenu = self.rootObject.interfaceLayer:add(VideoMenu:new(
		self.optionFile,
		function()
			self:openMainMenu()
			self.rootObject.interfaceLayer:del(self.videoMenu)
			self.videoMenu = nil
		end
	))
end

function Interface:beforeReadMessage()

	self.optionFile:update()
	self.debugOverlay:update()

	if self.videoMenu ~= nil then
		self.videoMenu:update()
	end

	--[[
	if self.loader ~= nil then
		self.loader:update()
	end
	]]

end

function Interface:onQuit()

	LightThread:new(function()
		self.dd:setCooperativeLevel(self.wnd, #DDSCL_NORMAL + #DDSCL_MULTITHREADED)
		local w, h = self.renderer.getScreenSize()
		if w ~= self.renderer.w or h ~= self.renderer.h then
			self.dd:setMode(self.renderer.w, self.renderer.h)
		end

		LightThread.yield(self.renderer:quit())

		self.work = false
		self:send(#M_Quit, "interface")
	end)

end

function Interface:keyPressed(key, alt)

	if alt and key == #Key_Return then
		LightThread:new(function()
			local fullscreen, w, h = LightThread.yield(self.renderer:switchFullscreen())
			local g = self.optionFile:getGroup("video")
			g:set("fullscreen", fullscreen)
			g:set("screenWidth", w)
			g:set("screenHeight", h)
		end)
	elseif key == #Key_Esc then

		if self.game ~= nil then

			-- check for close
			if self.mainMenu ~= nil then

				self.rootObject.interfaceLayer:del(self.mainMenu)
				self.mainMenu = nil
				self.rootObject:adterDel()

			elseif self.videoMenu ~= nil then

				self.rootObject.interfaceLayer:del(self.videoMenu)
				self.videoMenu = nil
				self.rootObject:adterDel()

			-- check for open
			elseif self.mainMenu == nil then
				self:openMainMenu()
				self.rootObject:adterDel()
			end

		end

	end

end

function Interface:keyUnPressed(key, alt)
end

return Interface
