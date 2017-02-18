require('class')
require('config')
require('constants')
require('inputs')
require('volt_util')
require('factory.input_relays.relay_errors')

if not free_real_estate then free_real_estate = {} end
if not free_real_estate.events then free_real_estate.events = {} end

free_real_estate.events.on_player_entered_factory = script.generate_event_name()
free_real_estate.events.on_player_left_factory = script.generate_event_name()

local FACTORY_SIZE = 36

local floor = math.floor
local ceil = math.ceil
local time_to_force_refresh = 2.5

Factory = class(function(self, factory, player)
	self.name = nil
	self.alloc = nil
	self.last_refresh = nil

	self.transit = {}
	self.transit.enter = nil
	self.transit.exit = nil

	-- external power interface (hidden entity)
	self.interface = nil
	self.accumulator = nil
	-- factory entity (may be nil if picked up)
	self.entity = factory

	-- factory is a lab for the name, we don't want users opening the UI and being confused
	factory.active = false
	factory.operable = false

	self.inputs = {}
	self.inputs.all = {}
	self.inputs.left = {}
	self.inputs.top = {}
	self.inputs.right = {}
	self.inputs.bottom = {}

	local name = 1

	while true do
		if(global.factories[tostring(name)] ~= nil) then
			name = name + 1
		else
			break
		end
	end

	self.name = tostring(name)
	factory.backer_name = '| ' .. name

	local surface = game.surfaces['free_real_estate']
	local alloc = generate_factory({FACTORY_SIZE,FACTORY_SIZE})
	self.alloc = alloc

	-- map of id (1-12): {sel: selector_ent, type: selected_type (string), contents: array of items or nil}

	local mid = alloc.x + floor((alloc.size[1] - 2) / 2) + 1

	local top = alloc.y+1
	local bottom = alloc.y+(alloc.size[2]-3)
	local left = alloc.x+1
	local right = alloc.x+(alloc.size[1]-1)

	-- create power buildings
	self.accumulator = surface.create_entity({
		name='fre_factory-power-reserve',
		position={mid-3, bottom+2},
		force=factory.force,
	})
	self.accumulator.destructible = false

	local ent = surface.create_entity({
		name='fre_factory-power-provider',
		position={mid+5, bottom+2},
		force=factory.force,
	})
	ent.destructible = false

	-- lamps
	if(free_real_estate.config.factory_time == 0 or free_real_estate.config.factory_time == 1) then
		for _, pos in pairs({
			{left, top},
			{right, top},
			{left, bottom},
			{right, bottom},
		}) do
			local ent = surface.create_entity({
				name='fre_factory-lamp',
				position=pos,
				force='neutral',
			})
			ent.destructible=false
		end
	end

	-- hardcoded to 4 per side right now because lazy, future proofed for changing later
	local connections = 5

	-- math for external connection offsets
	local top_left_offset = {
		x=factory.prototype.collision_box.left_top.x - 1,
		y=factory.prototype.collision_box.left_top.y - 1,
	}
	local top_right_offset = {
		x=factory.prototype.collision_box.right_bottom.x + 1,
		y=factory.prototype.collision_box.left_top.y - 1,
	}

	local top_count = ceil(top_right_offset.x - top_left_offset.x) - 2
	local side_count = ceil(factory.prototype.collision_box.right_bottom.y - top_left_offset.y) - 1

	local top_offset = (top_count - connections) / 2
	local side_offset = (side_count - connections) / 2

	-- internal connection pickers
	-- balance them as equally as possible
	-- left and right side
	local size = bottom - top
	local step = ceil((size / connections) - 1)
	local start = ceil((size - connections - (step * (connections - 1))) / 2) + 3

	for i=1,connections do
		self.inputs.left[i] = Input({
			open_area = {
				{x=left-1, y=alloc.y+start-1},
				{x=left, y=alloc.y+start+1},
			},
			closed_area = {
				{x=left, y=alloc.y+start-1},
				{x=left, y=alloc.y+start+1},
			},
			selector_position = {x=left, y=alloc.y+start-1},
			internal_position = {x=left, y=alloc.y+start},
			external_offset = {x=top_left_offset.x, y=top_left_offset.y + side_offset + i},
			side = 'left',
		})

		self.inputs.right[i] = Input({
			open_area = {
				{x=right, y=alloc.y+start-1},
				{x=right+1, y=alloc.y+start+1},
			},
			closed_area = {
				{x=right, y=alloc.y+start-1},
				{x=right, y=alloc.y+start+1},
			},
			selector_position = {x=right, y=alloc.y+start-1},
			internal_position = {x=right, y=alloc.y+start},
			external_offset = {x=top_right_offset.x, y=top_left_offset.y + side_offset + i},
			side = 'right',
		})
		start = start + step
	end

	-- top
	local size = right - left
	local step = ceil((size / connections) - 1)
	local start = ceil((size - connections - (step * (connections - 1))) / 2) + 3

	for i=1,connections do
		self.inputs.top[i] = Input({
			open_area = {
				{x=alloc.x+start-1, y=top-1},
				{x=alloc.x+start+1, y=top},
			},
			closed_area = {
				{x=alloc.x+start-1, y=top},
				{x=alloc.x+start+1, y=top},
			},
			selector_position = {x=alloc.x+start-1, y=top},
			internal_position = {x=alloc.x+start, y=top},
			external_offset = {x=top_left_offset.x + top_offset + i, y=top_left_offset.y},
			side = 'top',
		})
		start = start + step
	end

	for _, input in pairs(self.inputs.left) do
		table.insert(self.inputs.all, input)
	end

	for _, input in pairs(self.inputs.top) do
		table.insert(self.inputs.all, input)
	end

	for _, input in pairs(self.inputs.right) do
		table.insert(self.inputs.all, input)
	end

	local bb = factory.prototype.selection_box
	local entry_item_pos = {x=factory.position.x, y=factory.position.y + bb.right_bottom.y - 0.5}
	local exit_item_pos = {x=mid+1.0, y=bottom+3}

	-- players can teleport if they manage to reach an exit in another factory somehow
	-- probably not a big problem

	self.transit.enter = global.waypoints:create({
		item_surface=factory.surface,
		item_pos=entry_item_pos,
		tp_surface=surface,
		tp_pos={exit_item_pos.x, exit_item_pos.y-3},
		fresh=true,
		data=self,
	})

	self.transit.exit = global.waypoints:create({
		item_surface=surface,
		item_pos=exit_item_pos,
		tp_surface=factory.surface,
		tp_pos={entry_item_pos.x, entry_item_pos.y+1.5},
		fresh=false,
	})

	global.factories[self.name] = self
	self:create_external(factory, true)
end)

function Factory:_check_refresh_time()
	local tick = game.tick

	if(self.last_refresh == nil or (tick - self.last_refresh) > (time_to_force_refresh * 60)) then
		self.last_refresh = tick
		return false
	end

	self.last_refresh = nil
	return true
end

function Factory:relay_pollution()
	local surface = game.surfaces['free_real_estate']
	local top = self.alloc.y+1
	local bottom = self.alloc.y+(self.alloc.size[2]-3)
	local left = self.alloc.x+1
	local right = self.alloc.x+(self.alloc.size[1]-1)
	local pollution = 0

	for _, pos in pairs({
		{left, top},
		{right, top},
		{left, bottom},
		{right, bottom},
	}) do
		local here_pollution = surface.get_pollution(pos)
		pollution = pollution + here_pollution
		surface.pollute(pos, -here_pollution)
	end

	return pollution
end

local function _process_relay_result(player, res, pos_str)
	if(res == RELAY_NOT_EMPTY) then
		player.print(string.format(
			"%s's connection input or output is not empty. Press refresh again within %.1f seconds to delete those items or liquids and proceed anyway.",
			pos_str, time_to_force_refresh
		))
	elseif(res == EXTERNAL_CONNECTION_BLOCKED) then
		player.print(string.format(
			"%s's external connection is blocked.",
			pos_str
		))
	end
end

function Factory:refresh_inputs(player, check)
	local check = check or self:_check_refresh_time()
	local hit_all = true

	for _, input_arr in pairs({'left', 'top', 'right', 'bottom'}) do
		for i, input in pairs(self.inputs[input_arr]) do
			local res = input:refresh(self.entity, check)

			if(res ~= SUCCESS) then
				hit_all = false
			end

			if(player ~= nil) then
				_process_relay_result(player, res, string.format('%s-%i', capitalize(input_arr), i))
			end
		end
	end

	if(hit_all) then
		self.last_refresh = nil
	end

	return hit_all
end

function Factory:set_name(name)
	if(global.factories[name] ~= nil) then
		local nid = ternary(tonumber(name) ~= nil, 1, 2)
		local new_name = nil

		while true do
			new_name = string.format('%s %i', name, nid)

			if(global.factories[new_name] ~= nil) then
				nid = nid + 1
			else
				break
			end
		end

		name = new_name

		-- return false
	end

	global.factories[self.name] = nil
	self.name = name
	global.factories[self.name] = self

	self.entity.backer_name = '| ' .. self.name

	return true
end

function Factory:set_chart(force, charted)
	local top = 1
	local bottom = self.alloc.size[2]-3
	local left = 1
	local right = self.alloc.size[1]-1
	local surface = game.surfaces['free_real_estate']

	if(charted == true) then
		force.chart(
			surface,
			{
				{top, left},
				{bottom, right},
			}
		)
	else
		for cx=floor((self.alloc.x+left)/32),floor((self.alloc.x+right)/32) do
			for cy=floor((self.alloc.y+top)/32),floor((self.alloc.y+bottom)/32) do
				force.unchart_chunk(
					{cx, cy},
					surface
				)
			end
		end
	end
end

function Factory:restore_meta()
	for _, input in pairs(self.inputs.all) do
		Input.set_class(input)
		input:restore_meta()
	end
end

function Factory:create_external(factory, new, player)
	global.factory_entities[factory.unit_number] = self
	table.insert(global.factory_entity_tick, self)
	factory.backer_name = '| ' .. self.name

	-- the factory building itself doesn't contain or use energy, it's just a lab for visuals
	-- prevent it from showing up on power consumption (the interface will be there instead)
	factory.energy = 1000000

	self.interface = factory.surface.create_entity({
		name='fre_power_interface',
		position=factory.position,
		force='neutral',
	})

	if(new ~= true) then
		local mid = self.alloc.x + floor((self.alloc.size[1] - 2) / 2) + 1
		local bb = factory.prototype.selection_box
		local entry_item_pos = {x=factory.position.x, y=factory.position.y + bb.right_bottom.y - 0.5}

		global.waypoints:update_item_pos(self.transit.enter, factory.surface, entry_item_pos)
		global.waypoints:update_tp_pos(self.transit.exit, factory.surface, {entry_item_pos.x, entry_item_pos.y+1.5})

		-- replace exit because we delete it when we pick up a factory
		global.waypoints:place_world(self.transit.exit)

		self:restore_entities()

		for _, input_arr in pairs({'left', 'top', 'right', 'bottom'}) do
			for i, input in pairs(self.inputs[input_arr]) do
				if(input.relay ~= nil) then
					local res = input:place_external(factory)

					if(player ~= nil) then
						_process_relay_result(player, res, string.format('%s-%i', capitalize(input_arr), i))
					end
				end
			end
		end
	end

	table.insert(global.power_map, {self.interface, self.accumulator})
	self.entity = factory
end

function Factory:cleanup_external(factory)
	local found = nil

	for i=1,#global.power_map do
		if(global.power_map[i][2] == self.accumulator) then
			found = i
			break
		end
	end

	if(found == nil) then
		error("couldn't find internal power interface")
		return
	end

	if(free_real_estate.config.remove_energy_on_pickup) then
		self.accumulator.energy = 0
	end

	table.remove(global.power_map, found)

	for _, input in pairs(self.inputs.all) do
		if(input.relay ~= nil and input.relay:is_placed()) then
			input.relay:remove_external(factory, true)
		end
	end

	global.factory_entities[factory.unit_number] = nil
	table.remove(global.factory_entity_tick, index(global.factory_entity_tick, self))
	global.waypoints:clear_world(self.transit.enter)
	global.waypoints:clear_world(self.transit.exit)
	self.interface.destroy()
	self.interface = nil
	self.entity = nil
end

function Factory:_remove_players(exit_pos)
	self.restore = {}

	if(exit_pos == nil) then
		exit_pos = global.waypoints:get_tp_pos(self.transit.exit)
	end

	local ret = true

	-- add 2 to bounds because player on the very bottom tile can be slightly outside the radius (width + 0.5)

	for _, entity in pairs(game.surfaces['free_real_estate'].find_entities({
		{self.alloc.x, self.alloc.y+2},
		{self.alloc.x+self.alloc.size[1], self.alloc.y+self.alloc.size[2]+2}
	})) do
		if(entity.valid) then
			if(free_real_estate.constants.vehicles[entity.type] ~= nil and entity.passenger ~= nil) then
				local p = entity.passenger
				entity.passenger = nil
				p.player.teleport(exit_pos.position, exit_pos.surface)

				if(exit_pos.data ~= nil) then
					game.raise_event(free_real_estate.events.on_player_entered_factory, {player=p.player, old_factory=self, factory=exit_pos.data})
				else
					game.raise_event(free_real_estate.events.on_player_left_factory, {player=p.player, factory=self})
				end
			end

			if(entity.type == 'player') then
				entity.player.teleport(exit_pos.position, exit_pos.surface)

				if(exit_pos.data ~= nil) then
					game.raise_event(free_real_estate.events.on_player_entered_factory, {player=entity.player, old_factory=self, factory=exit_pos.data})
				else
					game.raise_event(free_real_estate.events.on_player_left_factory, {player=entity.player, factory=self})
				end
			else
				if(free_real_estate.constants.our_entities[entity.name] == nil and free_real_estate.constants.temporary[entity.type] == nil) then
					game.print('type: ' .. entity.type .. ', name: ' .. entity.name)
					ret = false
				end

				if(entity.name == 'fre_factory') then
					global.factory_entities[entity.unit_number]:_remove_players(exit_pos)
				-- skip temporary entities, smoke, etc
				-- these can cause a segfault in 0.14.22 if not skipped
				elseif(free_real_estate.constants.temporary[entity.type] == nil) then
					-- disable all entities for performance
					-- as long as we're here anyway make sure players can't get any of these buildings back somehow if this is actually a
					-- leaked destroyed factory and they've found a way to get inside it
					self.restore[entity] = {entity.operable, entity.active, entity.minable, entity.destructible}
					entity.operable = false
					entity.active = false
					entity.minable = false
					entity.destructible = false
				end
			end
		end
	end

	return ret
end

-- used for charting
function Factory:contains_players(force)
	if(force ~= nil and type(force) == 'userdata') then
		force = force.name
	end

	for _, entity in pairs(game.surfaces['free_real_estate'].find_entities({
		{self.alloc.x, self.alloc.y+2},
		{self.alloc.x+self.alloc.size[1], self.alloc.y+self.alloc.size[2]+2}
	})) do
		if(entity.valid) then
			if(free_real_estate.constants.vehicles[entity.type] ~= nil and entity.passenger ~= nil) then
				if(force == nil or entity.passenger.force.name == force) then
					return true
				end
			elseif(entity.type == 'player') then
				if(force == nil or entity.force.name == force) then
					return true
				end
			end
		end
	end

	return false
end

function Factory:restore_entities()
	local surface = game.surfaces['free_real_estate']

	for entity, flags in pairs(self.restore) do
		-- entity can be invalid here if we caught something temporary like smoke
		if(entity.valid) then
			entity.operable = flags[1]
			entity.active = flags[2]
			entity.minable = flags[3]
			entity.destructible = flags[4]
		end
	end

	self.restore = nil

	for _, entity in pairs(surface.find_entities_filtered({
		area={
			{self.alloc.x, self.alloc.y},
			{self.alloc.x+self.alloc.size[1], self.alloc.y+self.alloc.size[2]}
		},
		name='fre_factory',
	})) do
		global.factory_entities[entity.unit_number]:restore_entities()
	end
end

-- this function should not be called directly, use cleanup_factory(factory, nil, true) instead
function Factory:_destroy_factory(factory, exit_pos)
	if(factory ~= nil and factory.name ~= 'fre_factory') then
		error('what are you even doing with your life')
		return
	end

	if(exit_pos == nil) then
		exit_pos = global.waypoints:get_tp_pos(self.transit.exit)
	end

	global.waypoints:dispose(self.transit.enter)
	global.waypoints:dispose(self.transit.exit)

	local surface = game.surfaces['free_real_estate']

	-- close inputs because this area will be recycled
	for _, input in pairs(self.inputs.all) do
		if(input.relay ~= nil) then
			input:tile_status_open(false)
		end
	end

	for _, entity in pairs(surface.find_entities({
		{self.alloc.x, self.alloc.y+2},
		{self.alloc.x+self.alloc.size[1], self.alloc.y+self.alloc.size[2]+2}
	})) do
		if(entity.valid) then
			if(free_real_estate.constants.vehicles[entity.type] ~= nil and entity.passenger ~= nil) then
				local p = entity.passenger
				entity.passenger = nil
				p.player.teleport(exit_pos.position, exit_pos.surface)
				game.raise_event(free_real_estate.events.on_player_left_factory, {player=p.player, factory=self})

				-- teleport first to be friendly towards gravestone mod, etc
				-- don't kill offline players :c
				if(free_real_estate.config.kill_on_destroy and p.player.connected) then
					p.player.die()
				end
			end

			if(factory ~= nil and entity.type == 'player') then
				entity.player.teleport(exit_pos.position, exit_pos.surface)
				game.raise_event(free_real_estate.events.on_player_left_factory, {player=entity.player, factory=self})

				-- teleport first to be friendly towards gravestone mod, etc
				-- don't kill offline players :c
				if(free_real_estate.config.kill_on_destroy and entity.player.connected) then
					entity.player.die()
				end
			elseif(entity.name == 'fre_factory') then
				entity_destroyed(entity, exit_pos)
				entity.destroy()
			else
				entity.destroy()
			end
		end
	end

	global.factories[self.name] = nil
	global.allocator:free(self.alloc.size, self.alloc.index)
end

-- miner is either a player or robot who should pick up this factory
-- if nil the factory is/should be destroyed
function Factory:cleanup_factory(factory, miner, destroy)
	if(factory.name ~= 'fre_factory') then
		error('what are you even doing with your life')
		return
	elseif(miner ~= nil and destroy ~= nil) then
		error('stop confusing me')
		return
	end

	self:cleanup_external(factory)

	if(miner ~= nil) then
		-- check for empty factory, set to normal and free if so
		local is_empty = self:_remove_players()

		if(is_empty) then
			local health = factory.health / factory.prototype.max_health

			if(miner.insert({name='fre_factory', count=1, health=health}) < 1) then
				factory.surface.spill_item_stack(factory.position, {name='fre_factory', count=health})
			end

			destroy = true
		else
			local new_item = nil

			if(miner.can_insert({name='fre_factory_with_data', count=1, health=0})) then
				miner.insert({name='fre_factory_with_data', count=1, health=0})

				local check = {defines.inventory.player_quickbar, defines.inventory.player_main}

				for _, inv_id in pairs(check) do
					local inven = miner.get_inventory(inv_id)

					for i=1,#inven do
						item = inven[i]

						if(item ~= nil and item.valid_for_read) then
							if(item.name == 'fre_factory_with_data' and item.health == 0) then
								new_item = item
								break
							end
						end
					end

					if(new_item ~= nil) then
						break
					end
				end

				if(new_item == nil) then
					error('Failed to locate factory item')
					return
				end
			else
				local ent = factory.surface.create_entity({
					name='item-on-ground',
					position=factory.position,
					stack={name='fre_factory_with_data', count=1},
				})
				
				new_item = ent.stack
			end

			new_item.label = self.name
			new_item.health = factory.health / factory.prototype.max_health
			new_item.allow_manual_label_change = false
		end
	end

	local destroyed = false

	if(destroy == true) then
		destroyed = true
		self:_destroy_factory(factory)
	end

	global.factory_entities[factory.unit_number] = nil

	if(destroyed) then
		return nil
	else
		return self
	end
end