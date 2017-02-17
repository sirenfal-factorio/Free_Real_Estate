require('class')
require('factory.input_relays.items')
require('factory.input_relays.pipes')
require('factory.input_relays.circuits')
require('factory.input_relays.relay_errors')
require('volt_util')
require('factory.areatable')

local relays = {
	['chest']=ItemRelay,
	['pipe']=PipeRelay,
	['circuit']=CircuitRelay,
}

Input = class(function(self, t)
	open_area, closed_area, selector_position, internal_position, external_offset, side = 
		assert(t[1] or t.open_area),
		assert(t[2] or t.closed_area),
		assert(t[3] or t.selector_position),
		assert(t[4] or t.internal_position),
		assert(t[5] or t.external_offset),
		assert(t[6] or t.side)

	local surface = game.surfaces['free_real_estate']

	self.open_area = open_area
	self.closed_area = closed_area
	self.internal_position = internal_position
	self.external_offset = external_offset
	self.selector = surface.create_entity({
		name='fre_factory_connection_picker',
		position=selector_position,
		force='neutral',
	})
	self.selector.destructible = false
	self.side = side

	-- currently selected type manager
	self.relay = nil
end)

local floor = math.floor

function Input:tile_status_open(status)
	local surface = game.surfaces['free_real_estate']
	local tiles = AreaTable(0, 0)
	local ents = surface.find_entities({
		{self.open_area[1].x, self.open_area[1].y},
		-- add one here because the entities are placed at 0.5 and the tile's position is 0.0
		{self.open_area[2].x+1, self.open_area[2].y+1},
	})

	for _, ent in pairs(ents) do
		ent.teleport({ent.position.x+10, ent.position.y})
	end

	if(status) then
		for x=self.open_area[1].x,self.open_area[2].x do
			for y=self.open_area[1].y,self.open_area[2].y do
				tiles:set(x, y, {name='factory-wall'})
			end
		end

		tiles:set(self.internal_position.x, self.internal_position.y, {name='factory-floor'})
	else
		for x=self.open_area[1].x,self.open_area[2].x do
			for y=self.open_area[1].y,self.open_area[2].y do
				tiles:set(x, y, {name='out-of-map'})
			end
		end

		for x=self.closed_area[1].x,self.closed_area[2].x do
			for y=self.closed_area[1].y,self.closed_area[2].y do
				tiles:set(x, y, {name='factory-wall'})
			end
		end
	end

	surface.set_tiles(tiles:build())

	for _, ent in pairs(ents) do
		-- if we grabbed smoke or something it may be invalid here
		if(ent.valid) then
			ent.teleport({ent.position.x-10, ent.position.y})
		end
	end
end

function Input:get_external_position(factory)
	return {x=factory.position.x + self.external_offset.x, y=factory.position.y + self.external_offset.y}
end

function Input:restore_meta()
	if(self.relay ~= nil) then
		local t = relays[self.relay.type]
		t.set_class(self.relay)
	end
end

-- this is called when an existing factory is placed
function Input:place_external(factory)
	return self.relay:place_external({
		factory = factory,
		internal_pos = self.internal_position,
		external_surface = factory.surface,
		external_pos = self:get_external_position(factory)
	})
end

-- checks selector and sets input appropriately
-- do_not_place_external is used from within relay code creating a factory to factory link
function Input:refresh(factory, force, do_not_place_external)
	if(self.selector.recipe == nil) then
		if(self.relay ~= nil) then
			if(self.relay:is_empty() or force) then
				self.relay:destroy(factory)
				self.relay = nil
				self:tile_status_open(false)
				return SUCCESS
			end

			return RELAY_NOT_EMPTY
		end

		return SUCCESS
	end

	local new_type, direction = string.match(self.selector.recipe.name, '^fre_(%a+)%-(%a+)$')

	if(direction ~= 'input' and direction ~= 'output') then
		error('Unknown connection direction: ' .. direction)
		return
	end

	local internal_is_output = direction == 'input'

	-- we already have a relay, make sure it's empty or the player wants to clear it
	if(self.relay ~= nil) then
		if(self.relay.type == new_type) then
			-- just for code simplicity place_external doesn't handle direction reversal
			-- that means if you're reversing directions and external isn't placed (due to picked up factory being blocked when put down)
			-- inputs will be placed, then removed and placed again for the reversal
			-- this is a very rare case, and inputs being replaced shouldn't be expensive anyway
			if(do_not_place_external ~= true and not self.relay:is_placed()) then
				local res = self.relay:place_external({
					factory = factory,
					internal_pos = self.internal_position,
					external_surface = factory.surface,
					external_pos = self:get_external_position(factory)
				})

				if(res ~= SUCCESS) then
					return res
				end
			end

			if(do_not_place_external ~= true and internal_is_output ~= self.relay.internal_is_output) then
				self.relay:reverse(factory)
			end

			return SUCCESS
		end

		if(self.relay:is_empty() or force) then
			self.relay:destroy(factory)
			self.relay = nil
			self:tile_status_open(false)
		else
			return RELAY_NOT_EMPTY
		end
	end

	self.relay = relays[new_type]()
	self.relay.side = self.side
	self.relay:_set_selector(self.selector)
	local res = self.relay:place({
		factory = factory,
		internal_pos = self.internal_position,
		external_surface = factory.surface,
		external_pos = self:get_external_position(factory),
		internal_is_output = internal_is_output,
		do_not_place_external = do_not_place_external,
	})

	if(res ~= SUCCESS) then
		self.relay = nil
		self:tile_status_open(false)
	else
		self:tile_status_open(true)
	end

	return res
end
