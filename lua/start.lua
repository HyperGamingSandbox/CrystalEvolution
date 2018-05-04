
require("AppMessages")
require("Windows")
require("Queue")

local RendererHost = require("DD\\Renderer\\Host")
local dd, wnd, wndState = nil, nil, false

local MessagePump = require("MessagePump")
local ThreadHost = require("Thread\\Host")

local Object = require("Object")

local Main = Object:extend()

function Main:initialize(instance, cmdShow)

	self.threads = { }

	self.instance = instance
	self.cmdShow = cmdShow

	self.pump = MessagePump:new({
		[#WM_CLOSE]			= "onQuit",
		[#WM_DESTROY]		= "onQuit",
		[#M_APPQuit]		= "onQuit",

		[#WM_SIZE]			= "onSize",
		[#WM_PAINT]			= "onPaint",
		[#WM_ERASEBKGND]	= "skipMessage",
		-- [#WM_NCPAINT]		= "skipMessage",
		[#WM_SYSKEYDOWN]	= "onSysKeyDown",
		[#WM_SYSKEYUP]		= "onSysKeyUp",
		[#WM_KEYDOWN]		= "onKeyDown",
		[#WM_KEYUP]			= "onKeyUp",
		[#WM_CHAR]			= "onChar",		
		[#WM_ACTIVATE]		= "onWindowActive",
		[#WM_MOVE]			= "onWindowMove",


		[#WM_MOUSEMOVE]		= "onMouseEvent",
		[#WM_LBUTTONDOWN]	= "onMouseEvent",
		[#WM_LBUTTONUP]		= "onMouseEvent",
		-- [#WM_LBUTTONDBLCLK]		= "onMouseEvent",

		[#WM_MOUSEWHEEL]	= "onMouseWheel",
		[#WM_MOUSELEAVE]	= "onMouseLeave",

		[#MR_SetCursor]		= "onRSetCursor",

		[#M_Quit]			= "onThreadQuit",
		[#M_DD]				= "onDD"
	})

	self.pump:registerReciever(self)

	local f = Font:new("verdana", 15)
	f:create()

	_set(0, f)

end

function Main:start()

	local wndClass = WindowClass:new()

	wndClass.style 			= #CS_HREDRAW + #CS_VREDRAW
	wndClass.instance 		= self.instance
	wndClass.lpszClassName 	= "wndclass1"

	wndClass:register()

	wnd = Window:new()

	wnd.wndProc 	= function(hwnd, message, ...)	
		if not self.pump:onMessage(message, ...) then
			return DefWindowProc(hwnd, message, ...)
		end
		return 0
	end

	wnd.className = "wndclass1"
	wnd.title 	= "Crystal Evolution"
	wnd.instance 	= self.instance

	if not wnd:create() then
		return 1
	end

	wnd:removeStyle(#WS_MAXIMIZEBOX)

	self.queue = Queue:new()
	self.interfaceThread = ThreadHost:new("Interface\\Thread", self.queue, wnd)

	wnd:show(self.cmdShow)
	wnd:update()

	local r = MessageLoop(3, function()
		-- collectgarbage()
		self:readQueue()
	end)

	-- cleanup
	wnd:close()

	self.interfaceThread:send(#M_Quit)

	while true do
		if self:cleanDone() then
			break
		end
		self:readQueue()
		threadYield()
	end


	return r

end

function Main:onMouseWheel(lparam, wparam)
	-- dprint("Main:onMouseLeave")
	self.interfaceThread:send(#WM_MOUSEWHEEL, word(wparam, 1))
end

function Main:onMouseLeave()
	-- dprint("Main:onMouseLeave")
	self.interfaceThread:send(#WM_MOUSELEAVE)
end


local cursorCache = { }
function Main:onRSetCursor(cursorId)
	local cursor = cursorCache[cursorId]
	if cursor == nil then
		cursor = Cursor:new(cursorId)
		cursorCache[cursorId] = cursor
	end
	cursor:set()
end


function Main:onWindowMove(lparam)
	self.interfaceThread:send(#WM_MOVE, word(lparam, 0), word(lparam, 1))
end

function Main:onSize(lparam, wparam)

	if wparam == #SIZE_RESTORED or wparam == #SIZE_MAXIMIZED then

		if not wndState then
			wndState = true
			self.interfaceThread:send(#MR_WndRestored)
		end

		self.interfaceThread:send(#WM_SIZE, word(lparam, 0), word(lparam, 1))

	elseif wparam == #SIZE_MINIMIZED then

		wndState = false
		self.interfaceThread:send(#MR_WndMinimized)
	end
end

function Main:onPaint()
	wnd:validateRect()
	return true
end

function Main:skipMessage()
	return true
end

function Main:onSysKeyDown(lparam, wparam)
	self.interfaceThread:send(#WM_SYSKEYDOWN, wparam)
end

function Main:onSysKeyUp(lparam, wparam)
	self.interfaceThread:send(#WM_SYSKEYUP, wparam)
end

function Main:onKeyDown(lparam, wparam)
	self.interfaceThread:send(#WM_KEYDOWN, wparam)
end

function Main:onKeyUp(lparam, wparam)
	self.interfaceThread:send(#WM_KEYUP, wparam)
end

function Main:onWindowActive(lparam, wparam)
	self.interfaceThread:send(#WM_ACTIVATE, wparam)
end

function Main:onMouseEvent(lparam, wparam)
	self.interfaceThread:send(#WM_MOUSEMOVE, word(lparam, 0), word(lparam, 1))
	self.interfaceThread:send(#MR_MouseButtons, wparam)
end


function Main:cleanDone()
	if self.threads.interface then return true end
	return false
end

function Main:onThreadQuit(threadName)
	-- dprint("thread " .. threadName .. " done")
	self.threads[threadName] = true
end

function Main:onQuit()

	if dd ~= nil then
		dd:setCooperativeLevel(wnd, #DDSCL_NORMAL + #DDSCL_MULTITHREADED)		
	end

	PostQuitMessage(0)
	return true
end

function Main:onDD(_dd)
	dd = _dd
end

function Main:readQueue()
	while not self.queue:empty() do
		self.pump:onMessage(self.queue:get():get())
	end
end

function start(instance, cmdShow)	

	local m = Main:new(instance, cmdShow)
	local r = m:start()
	return r

end

function exit()
	if dd ~= nil then
		dd:setCooperativeLevel(wnd, #DDSCL_NORMAL + #DDSCL_MULTITHREADED)		
	end
end
