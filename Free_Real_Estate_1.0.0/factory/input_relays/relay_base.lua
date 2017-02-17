require('class')
require('volt_util')
require('factory.input_relays.relay_errors')

local abs = math.abs

RelayBase = class(function(self)
	self.selector = nil
	self.external_storage = nil
	self.input = nil
	self.output = nil
	self.internal_is_output = nil

	self.remote_relay = nil
end)

function RelayBase:_set_selector(ent)
	self.selector = ent
end

function RelayBase:_set_internal(ent)
	if(self.internal_is_output) then
		self.output = ent
	else
		self.input = ent
	end
end

function RelayBase:_set_external(ent)
	if(self.internal_is_output) then
		self.input = ent
	else
		self.output = ent
	end
end

function RelayBase:get_internal()
	if(self.internal_is_output) then
		return self.output
	else
		return self.input
	end
end

function RelayBase:get_external()
	if(self.internal_is_output) then
		return self.input
	else
		return self.output
	end
end

-- get the relay that belongs in the active list
function RelayBase:_get_primary_relay()
	if(self.remote_relay == nil) then
		return self
	end

	if(self.internal_is_output) then
		return self
	else
		return self.remote_relay
	end
end

function RelayBase:is_placed()
	return self:get_external() ~= nil
end

-- refresh external entities if they're dirty
function RelayBase:check_external(t)
	local factory, external_surface, external_pos = 
		t[1] or t.factory,
		t[2] or t.external_surface,
		t[3] or t.external_pos

	local ent_name, rotation, operable = self:get_entity_settings(factory, ternary(not self.internal_is_output, 'output', 'input'), external_surface, external_pos, self.remote_relay == nil)
	local external = self:get_external()

	if(external == nil) then
		-- error('check_external with no external placed?')
		return
	end

	if(ent_name ~= external.name or (rotation ~= nil and rotation ~= external.direction)) then
		local new = external.surface.create_entity({
			name=ent_name,
			position=external.position,
			force='neutral',
		})
		new.destructible = false
		new.minable = false
		new.rotatable = false
		new.operable = ternary(operable == nil, true, operable)

		if(rotation ~= nil) then
			new.direction = rotation
		end

		self:replace_entity(external, new)
		self:_set_external(new)

		if(self.remote_relay ~= nil) then
			self.remote_relay:_set_internal(new)
		end
	end
end

function RelayBase:refresh_adjacent(factory_ent)
	local factory = global.factory_entities[factory_ent.unit_number]
	local relay_index = nil
	local side = factory.inputs[self.side]

	for k, input in pairs(side) do
		if(input.relay == self) then
			relay_index = k
			break
		end
	end

	if(relay_index == nil) then
		error('Failed to find input index')
		return
	end

	local left_open = relay_index == 1 or side[relay_index - 1].relay == nil
	local right_open = relay_index == #side or side[relay_index + 1].relay == nil

	if(not left_open) then
		local input = side[relay_index-1]
		input.relay:check_external({factory_ent, input.external_surface, input.external_pos})
	end

	if(not right_open) then
		local input = side[relay_index+1]
		input.relay:check_external({factory_ent, input.external_surface, input.external_pos})
	end
end

-- if _force is true don't try to connect to other factories, place on top of them
-- this is for fixing connections as we pick up a factory that was previously linked
function RelayBase:place(t, _force)
	local factory, internal_pos, external_surface, external_pos, internal_is_output, do_not_place_external = 
		t[1] or t.factory,
		t[2] or t.internal_pos,
		t[3] or t.external_surface,
		t[4] or t.external_pos,
		t[5] or t.internal_is_output,
		t[6] or t.do_not_place_external

	assert(internal_pos ~= nil)
	assert(external_surface ~= nil)
	assert(external_pos ~= nil)
	assert(internal_is_output ~= nil)

	self.internal_is_output = internal_is_output
	
	local surface = game.surfaces['free_real_estate']

	local internal = self:place_internal({factory, internal_pos})

	if(do_not_place_external ~= true) then
		local res = self:place_external({factory, external_surface, external_pos})

		if(res ~= SUCCESS) then
			self.input = nil
			self.output = nil
			internal.destroy()
			return res
		end
	end

	return SUCCESS
end

function RelayBase:place_internal(t)
	local factory, internal_pos = 
		t[1] or t.factory,
		t[2] or t.internal_pos

	local surface = game.surfaces['free_real_estate']

	local ent_name, rotation, operable = self:get_entity_settings(factory, ternary(self.internal_is_output, 'output', 'input'), surface, internal_pos, false)
	local internal = surface.create_entity({
		name=ent_name,
		position=internal_pos,
		force='neutral',
	})
	internal.destructible = false
	internal.minable = false
	internal.rotatable = false
	internal.operable = ternary(operable == nil, true, operable)
	if(rotation ~= nil) then
		internal.direction = rotation
	end

	self:_set_internal(internal)

	return internal
end

function RelayBase:place_external(t)
	local factory, external_surface, external_pos = 
		t[1] or t.factory,
		t[2] or t.external_surface,
		t[3] or t.external_pos

	local surface = game.surfaces['free_real_estate']
	local linked_factory = external_surface.find_entity('fre_factory', external_pos)
	local external = nil

	if(linked_factory ~= nil) then
		linked_factory = global.factory_entities[linked_factory.unit_number]

		local linked_input_pos = table.deepcopy(external_pos)
		local diff = {x=factory.position.x - linked_factory.entity.position.x, y=factory.position.y - linked_factory.entity.position.y}
		local scan_dir = nil

		if(abs(diff.y) > abs(diff.x)) then
			if(diff.y > 0) then
				-- north
				scan_dir = 'top'
				linked_input_pos.y = linked_input_pos.y + 1
			else
				-- south
				scan_dir = 'bottom'
				linked_input_pos.y = linked_input_pos.y - 1
			end
		else
			if(diff.x > 0) then
				-- east
				scan_dir = 'right'
				linked_input_pos.x = linked_input_pos.x + 1
			else
				-- west
				scan_dir = 'left'
				linked_input_pos.x = linked_input_pos.x - 1
			end
		end

		external_pos = snap_to_grid(linked_input_pos)
		local remote = nil

		for i, input in pairs(linked_factory.inputs[scan_dir]) do
			local other = snap_to_grid(input:get_external_position(linked_factory.entity))

			if(other.x == external_pos.x and other.y == external_pos.y) then
				remote = input
				break
			end
		end

		if(remote == nil) then
			return EXTERNAL_CONNECTION_BLOCKED
		end

		-- the output side is always the active relay in the global :relay() list for linked relays
		-- we handle directions here, refresh will skip it
		remote.selector.recipe = self:get_recipe_name(ternary(self.internal_is_output, 'output', 'input'))
		local res = remote:refresh(linked_factory.entity, nil, true)
		-- remote.selector.recipe = nil

		if(res ~= SUCCESS) then
			return res
		end

		-- fix remote direction, this happens if the remote already had a connection of the same type but not in the correct direction
		if(remote.internal_is_output == self.internal_is_output) then
			local ent_name, rotation, operable = self:get_entity_settings(factory, ternary(self.internal_is_output, 'output', 'input'), surface, remote.internal_position, false)
			local chest = surface.create_entity({
				name=ent_name,
				position=remote.internal_position,
				force='neutral',
			})
			chest.destructible = false
			chest.minable = false
			chest.rotatable = false
			chest.operable = ternary(operable == nil, true, operable)
			if(rotation ~= nil) then
				chest.direction = rotation
			end

			self:replace_entity(remote.relay:get_internal(), chest)
			remote.relay:_set_internal(chest)
			remote.relay.internal_is_output = not self.internal_is_output
		end

		remote.relay.remote_relay = self
		self.remote_relay = remote.relay

		external = remote.relay:get_internal()
		remote.relay:_set_external(self:get_internal())
	else
		local ent_name, rotation, operable = self:get_entity_settings(factory, ternary(not self.internal_is_output, 'output', 'input'), external_surface, external_pos, true)

		local pos = external_surface.can_place_entity({
			name=ent_name,
			position=external_pos,
			force='neutral'
		})

		if(pos == false) then
			return EXTERNAL_CONNECTION_BLOCKED
		end

		external = external_surface.create_entity({
			name=ent_name,
			position=external_pos,
			force='neutral',
		})

		if(external == nil) then
			return EXTERNAL_CONNECTION_BLOCKED
		end

		external.destructible = false
		external.minable = false
		external.rotatable = false
		external.operable = ternary(operable == nil, true, operable)

		if(rotation ~= nil) then
			external.direction = rotation
		end
	end

	self:_set_external(external)

	if(self.external_storage ~= nil) then
		if(self:transfer_contents(self.external_storage, self.output) == true) then
			self.external_storage.destroy()
			self.external_storage = nil
		end
	end

	if(self.remote_relay ~= nil and self.remote_relay.external_storage ~= nil) then
		if(self:transfer_contents(self.remote_relay.external_storage, self.output) == true) then
			self.remote_relay.external_storage.destroy()
			self.remote_relay.external_storage = nil
		end
	end

	self:refresh_adjacent(factory)

	-- this can be a double add if check_external is called on a remote_relay
	if(index(global.active_relays, self:_get_primary_relay(), true) == nil) then
		table.insert(global.active_relays, self:_get_primary_relay())
	end

	return SUCCESS
end

function RelayBase:remove_external(factory, save)
	local external = self:get_external()
	table.remove(global.active_relays, index(global.active_relays, self:_get_primary_relay()))

	-- external can be nil if we picked up this factory, then put it down, the input was blocked, and then picked it up again
	if(external ~= nil) then
		if(self.remote_relay ~= nil) then
			self:_set_external(nil)
			self.remote_relay:_set_external(nil)

			self.remote_relay.remote_relay = nil
			self.remote_relay = nil
		elseif(save == true) then
			local surface = game.surfaces['free_real_estate']
			local ent_name, rotation, operable = self:get_entity_settings(nil, 'virtual', surface, self:get_internal().position, false)

			if(ent_name ~= nil) then
				local storage = surface.create_entity({
					name=ent_name,
					position=self:get_internal().position,
					force='neutral',
				})
				storage.destructible = false
				storage.minable = false
				storage.rotatable = false
				storage.operable = ternary(operable == nil, true, operable)

				if(rotation ~= nil) then
					storage.direction = rotation
				end

				self.external_storage = storage
				self:replace_entity(external, storage)
			else
				external.destroy()
			end
		else
			external.destroy()
		end

		if(self.internal_is_output) then
			self.input = nil
		else
			self.output = nil
		end
	end

	self:refresh_adjacent(factory)
end

function RelayBase:reverse(factory)
	-- local x = self.output
	-- self.output = self.input
	-- self.input = x
	local active_index = index(global.active_relays, self:_get_primary_relay())

	self.input, self.output = self.output, self.input

	for _, key in pairs({'input', 'output'}) do
		local old = self[key]

		-- output can be nil here in certain cases with picked-up factories
		if(old ~= nil) then
			local ent_name, rotation, operable = self:get_entity_settings(factory, key, surface, old.position, self[key] ~= self:get_external())

			local new = old.surface.create_entity({
				name=ent_name,
				position=old.position,
				force='neutral',
			})
			new.destructible = false
			new.minable = false
			new.rotatable = false
			new.operable = ternary(operable == nil, true, operable)

			if(rotation ~= nil) then
				new.direction = rotation
			end

			self[key] = new
			self:replace_entity(old, new)
		end
	end

	if(self.remote_relay ~= nil) then
		self.remote_relay.selector.recipe = self:get_recipe_name(ternary(not self.internal_is_output, 'output', 'input'))

		table.remove(global.active_relays, active_index)

		self.remote_relay.input, self.remote_relay.output = self.input, self.output
		self.remote_relay.internal_is_output = self.internal_is_output

		self.internal_is_output = not self.internal_is_output

		table.insert(global.active_relays, self:_get_primary_relay())
	else
		self.internal_is_output = not self.internal_is_output
	end
end

function RelayBase:destroy(factory)
	-- flag to detect when check_external is being called from the :destroy() method
	self.destroying = true

	if(self:is_placed()) then
		if(self.remote_relay ~= nil) then
			table.remove(global.active_relays, index(global.active_relays, self:_get_primary_relay()))
			self:_set_external(nil)
			self.remote_relay:_set_external(nil)

			self.remote_relay.remote_relay = nil
			self.remote_relay = nil
		else
			table.remove(global.active_relays, index(global.active_relays, self:_get_primary_relay()))
		end
	end

	if(self.input ~= nil) then
		self.input.destroy()
		self.input = nil
	end

	if(self.output ~= nil) then
		self.output.destroy()
		self.output = nil
	end

	self:refresh_adjacent(factory)
end