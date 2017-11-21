local f = function(n, i)
	if type(n) ~= "number" then n = 0 end
	_set(i, math.floor(n))
end

return function(pc)
	f(pc.periodsPerSecond, 1)
	f(pc.msCurrentPeriod, 2)
	f(pc.sleepMS, 3)
	f(pc.msWithSleep, 4)
end