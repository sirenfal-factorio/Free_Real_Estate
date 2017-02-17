require('class')

AreaTable = class(function(self, offsetx, offsety, width, height)
	self.offsetx = offsetx or 0
	self.offsety = offsety or 0
	-- self.width = width
	-- self.height = height
	self._pos = {}
end)

local function resolve(x, y, width, height)
	-- if(x > (offsetx + width) or x < offsetx) then
	-- 	error(string.format('Invalid X position: %s (must be %s <= x <= %s)', x, offsetx, offsetx+width))
	-- 	return
	-- elseif(y > (offsety + height) or y < offsety) then
	-- 	error(string.format('Invalid Y position: %s (must be %s <= y <= %s)', y, offsety, offsety+height))
	-- 	return
	-- end

	-- if(x > width or x < 0) then
	-- 	error(string.format('Invalid X position: %s (must be 0 <= x <= %s)', x, width))
	-- 	return
	-- elseif(y > height or y < 0) then
	-- 	error(string.format('Invalid Y position: %s (must be 0 <= y <= %s)', y, height))
	-- 	return
	-- end

	-- y << 32 | x
	return (y * 4294967296) + x
end

local floor = math.floor
local ti = table.insert

function AreaTable:build()
	local ret = {}

	for k,v in pairs(self._pos) do
		local x = k % 4294967296
		local y = floor(k / 4294967296)

		v['position'] = {self.offsetx+x, self.offsety+y}

		ti(ret, v)
	end

	return ret
end

function AreaTable:set(x, y, val)
	self._pos[resolve(x, y)] = val
end