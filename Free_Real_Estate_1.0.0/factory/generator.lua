require('factory.areatable')

local floor = math.floor
local ceil = math.ceil

function generate_factory(rsize)
	local surface = game.surfaces['free_real_estate']

	-- add 2 to x for inputs, 1 to y for top inputs, 3 to y for bottom exit
	-- add 2 to x, 2 to y for walls
	walls = 2
	input_row = 1
	bottom_three_exit = 3
	size = {rsize[1] + walls + (input_row*2), rsize[2] + walls + input_row + bottom_three_exit}

	-- subtract one from each dimension because allocator works from 0 indices
	size = {size[1] - 1, size[2] - 1}

	alloc = global.allocator:allocate(size)
	local tiles = AreaTable(alloc.x, alloc.y, size[1], size[2])

	-- one line of empty space on left, right, and top for inputs to push into
	local top = 1
	local bottom = alloc.size[2]-3
	local left = 1
	local right = alloc.size[1]-1

	-- skip vanilla generation
	for cx=floor((alloc.x+left)/32)-2,floor((alloc.x+right)/32)+1 do
		for cy=floor((alloc.y+top)/32)-2,floor((alloc.y+bottom)/32)+1 do
			-- game.print('nulling chunk: ' .. cx .. ', ' .. cy)
			surface.set_chunk_generated_status({cx, cy}, defines.chunk_generated_status.entities)
		end
	end

	-- game.print('top: ' .. top)
	-- game.print('bottom: ' .. bottom)
	-- game.print('left: ' .. left)
	-- game.print('right: ' .. right)

	for y=top,bottom do
		for x=left,right do
			if(
				-- top
				y == top or
				y == bottom or
				x == left or
				x == right
			) then
				tiles:set(x, y, {name='factory-wall'})
			else
				tiles:set(x, y, {name='factory-floor'})
			end
		end
	end

	local mid = floor((alloc.size[1] - 2) / 2) + 1

	for y=bottom,bottom+3 do
		-- left walls
		for x=mid-5,mid-2 do
			tiles:set(x, y, {name='factory-wall'})
		end

		-- 4x3 exit tiles at the bottom
		for x=mid-1,mid+2 do
			tiles:set(x, y, {name='factory-entrance'})
		end

		-- right walls
		for x=mid+3,mid+6 do
			tiles:set(x, y, {name='factory-wall'})
		end
	end

	-- alloc.exit = {mid+0.5, bottom+2}

	surface.set_tiles(tiles:build())
	return alloc
end