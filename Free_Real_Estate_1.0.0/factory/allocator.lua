require('constants')
require('class')

Allocator = class(function(self)
	-- map of key -> block_index
	self.size_index = {}
	-- array[block_index] -> {size={10, 10}, left_x=0, next_index=0, free_indices={}}
	self.size_blocks = {}
end)

local floor = math.floor

-- factories are stored as rows of constants.free_real_estate.constants.factories_per_row with constants.free_real_estate.constants.spacing_per_entry between each factory
-- different factory size "blocks" are infinite vertical chunks slotted next to each other
-- e.g. free_real_estate.constants.spacing_per_entry = 2, free_real_estate.constants.factories_per_row = 2
-- 6 2x2s are allocated, 5 5x5 are allocated
--
-- ____  ____  _______ _______
-- |  |  |  |  |     | |     |
-- |  |  |  |  |     | |     |
-- ‾‾‾‾  ‾‾‾‾  |     | |     |
-- ____  ____  |     | |     |
-- |  |  |  |  |     | |     |
-- |  |  |  |  ‾‾‾‾‾‾‾ ‾‾‾‾‾‾‾
-- ‾‾‾‾  ‾‾‾‾  _______ _______
-- ____  ____  |     | |     |
-- |  |  |  |  |     | |     |
-- |  |  |  |  |     | |     |
-- ‾‾‾‾  ‾‾‾‾  |     | |     |
--             |     | |     |
--             ‾‾‾‾‾‾‾ ‾‾‾‾‾‾‾
--             _______
--             |     |
--             |     |
--             |     |
--             |     |
--             |     |
--             ‾‾‾‾‾‾‾

local function pop_from_set(t)
	local ret = nil

	for k,_ in pairs(t) do
		ret = k
		break
	end

	if(ret == nil) then
		return nil
	end

	t[ret] = nil
	return ret
end

function Allocator:allocate(size)
	-- is there anything lua doesn't suck at? no bitwise operators? what the fuck
	--local key = (size[1] << 32) | size[2]
	local key = (size[1] * 4294967296) + size[2]
	local block_index = self.size_index[key]
	local block_info = nil

	if(self.size_index[key] == nil) then
		local last_index = #self.size_blocks
		-- for some reason chunks at 0,0 don't unchart properly, skip that area
		local left_x = 32*30

		if(last_index > 0) then
			local last = self.size_blocks[last_index]
			left_x = last.left_x + (last.size[1] * free_real_estate.constants.factories_per_row) + (free_real_estate.constants.spacing_per_entry * free_real_estate.constants.factories_per_row) + free_real_estate.constants.spacing_per_entry
		end

		block_info = {
			size = size,
			left_x = left_x,
			-- next free index
			next_index = 0,
			-- indices that have been deleted and are free to use, use these before incrementing next_index
			free_indices = {},
		}

		table.insert(self.size_blocks, block_info)
		self.size_index[key] = last_index + 1
	else
		block_info = self.size_blocks[block_index]
	end

	-- it's the caller's responsibility to wipe the area of entities *when it is removed*, not here
	local index = pop_from_set(block_info.free_indices)

	if(index == nil) then
		index = block_info.next_index
		block_info.next_index = block_info.next_index + 1
	end

	local row = floor(index / free_real_estate.constants.factories_per_row)
	local col = index % free_real_estate.constants.factories_per_row

	return {
		index=index,
		x=block_info.left_x + ((size[1] + free_real_estate.constants.spacing_per_entry + 1) * col),
		y=((size[2] + free_real_estate.constants.spacing_per_entry + 1) * row),
		size=size,
	}
end

function Allocator:free(size, index)
	local key = (size[1] * 4294967296) + size[2]
	local block_index = self.size_index[key]
	block_info = self.size_blocks[block_index]

	if(block_info.free_indices[index] ~= nil) then
		error(string.format('Double free: (%i, %i) index %i', size[1], size[2], index))
		return
	elseif(index >= block_info.next_index) then
		error(string.format("Tried to free index that wasn't allocated: (%i, %i) %i", size[1], size[2], index))
		return
	end

	block_info.free_indices[index] = true
end