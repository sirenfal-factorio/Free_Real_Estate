require('constants')
require('factory.allocator')
require('factory.generator')
require('factory.factory')
require('factory.waypoint')
require('config')
require('volt_util')
require('memes')

local floor = math.floor
local ceil = math.ceil
local mike_active = nil

local function do_init()
	global.allocator = global.allocator or Allocator()

	-- name: alloc array; all factories exist here
	global.factories = global.factories or {}
	-- entity.unit_number to factory object
	global.factory_entities = global.factory_entities or {}
	-- array of factories that are currently placed in the world
	global.factory_entity_tick = global.factory_entity_tick or {}
	-- player.index to factory if they're in a factory
	global.player_location = global.player_location or {}

	global.waypoints = global.waypoints or Waypoint()

	global.player_cursor_info = global.player_cursor_info or {}

	-- array of {external power interface, factory accumulator}
	global.power_map = global.power_map or {}

	-- array of input_relays
	global.active_relays = global.active_relays or {}

	global.tick_relay_index = global.tick_relay_index or 1
	global.tick_pollution_index = global.tick_pollution_index or 1

	global.tick_skip = global.tick_skip or {}

	local surface = game.surfaces['free_real_estate']

	-- make sure connection recipes are accessible on the assemblers
	game.forces['neutral'].recipes['fre_chest-input'].enabled = true
	game.forces['neutral'].recipes['fre_chest-output'].enabled = true
	game.forces['neutral'].recipes['fre_pipe-input'].enabled = true
	game.forces['neutral'].recipes['fre_pipe-output'].enabled = true
	game.forces['neutral'].recipes['fre_circuit-input'].enabled = true
	game.forces['neutral'].recipes['fre_circuit-output'].enabled = true

	-- day/night, with or without lamps
	if(free_real_estate.config.factory_time == 0 or free_real_estate.config.factory_time == 2) then
		surface.daytime = game.surfaces['nauvis'].daytime
		surface.freeze_daytime(false)
	-- always night, with or without lamps
	elseif(free_real_estate.config.factory_time == 1 or free_real_estate.config.factory_time == 4) then
		surface.daytime = 0.5
		surface.freeze_daytime(true)
	-- always day
	elseif(free_real_estate.config.factory_time == 3) then
		surface.daytime = 0.0
		surface.freeze_daytime(true)
	end
end

local function schedule_mike(min, max)
	local minute = 60*60
	mike_active = game.tick + math.random(
		ternary(min ~= nil, function() return minute*min end, minute*35),
		ternary(max ~= nil, function() return minute*max end, minute*250)
	)
end

-- this is a joke "reward" to my friend for strenuously bug-testing
-- it won't run unless he joins and doesn't affect gameplay
local function check_mike()
	local player = game.players['elfleadermike']

	if(player == nil) then
		mike_active = nil
		return
	end

	if(player.get_item_count('fre_gold_medal') < 1) then
		if(player.insert({name='fre_gold_medal', count=1}) < 1) then
			if(player.connected == false) then
				mike_active = nil
			else
				schedule_mike(5,10)
			end

			return
		end
	end

	if(player.connected == false) then
		mike_active = nil
	else
		schedule_mike()
	end
end

script.on_init(function()
	local surface = game.create_surface('free_real_estate', {width=1, height=1, autoplace_controls={}, terrain_segmentation='none', water='none'})
	do_init()

	check_mike()
end)

script.on_load(function()
	global.allocator = Allocator.set_class(global.allocator)

	for _, factory in pairs(global.factories) do
		Factory.set_class(factory)
		factory:restore_meta()
	end

	global.waypoints = Waypoint.set_class(global.waypoints)
end)

script.on_configuration_changed(function(data)
	do_init()

	check_mike()
end)

local tick_spread = free_real_estate.constants.tick_spread
local TICK_SKIP_RELAY_INDEX = 1
local TICK_SKIP_POLLUTION_INDEX = 2

local function tick_power()
	for i=1,#global.power_map do
		local interfaces = global.power_map[i]

		local available_power = interfaces[1].energy * free_real_estate.config.power_input_multiplier
		local current_power = interfaces[2].energy
		-- no point reading the prototype to determine maximum energy, just get a delta to determine what we spent
		interfaces[2].energy = interfaces[2].energy + available_power

		local spent_power = interfaces[2].energy - current_power

		-- game.print(string.format('available: %i, current: %i, spent: %i', available_power, current_power, spent_power))

		if(spent_power > 0) then
			interfaces[1].energy = interfaces[1].energy - (spent_power / free_real_estate.config.power_input_multiplier)
		end
	end
end

local function tick_relays()
	local l = #global.active_relays

	if(l < 1) then
		return
	end

	local per_run = ceil(l / tick_spread)

	for i=1+((global.tick_relay_index-1)*per_run),global.tick_relay_index*per_run do
		if(i > l) then
			-- don't do any more relay updates until next tick
			global.tick_skip[TICK_SKIP_RELAY_INDEX] = true
			global.tick_relay_index = 1
			return
		end

		local relay = global.active_relays[i]

		relay:relay()
	end

	global.tick_relay_index = global.tick_relay_index + 1
end

local function tick_pollution()
	local l = #global.factory_entity_tick

	if(l < 1) then
		return
	end

	local per_run = ceil(l / tick_spread)

	for i=1+((global.tick_pollution_index-1)*per_run),global.tick_pollution_index*per_run do
		if(i > l) then
			-- don't do any more pollution updates until next tick
			global.tick_skip[TICK_SKIP_POLLUTION_INDEX] = true
			global.tick_pollution_index = 1
			return
		end

		local factory = global.factory_entity_tick[i]
		local pollution = factory:relay_pollution()

		if(pollution > 0) then
			factory.entity.surface.pollute(factory.entity.position, pollution * free_real_estate.config.pollution_multiplier)
		end
	end

	global.tick_pollution_index = global.tick_pollution_index + 1
end

local tick_lookup = {}

-- equally space ticks out to smooth and prevent lag bursts
-- tick_power moved to run every tick
local tick_functions = {tick_relays}

if(free_real_estate.config.pollution_multiplier > 0) then
	table.insert(tick_functions, tick_pollution)
end

local tick_time = free_real_estate.constants.tick_time
local tick_split = tick_time / (tick_spread * #tick_functions)
-- functions can't be serialized in global
local tick_skip_index = {
	[tick_relays] = TICK_SKIP_RELAY_INDEX,
	[tick_pollution] = TICK_SKIP_POLLUTION_INDEX,
}

for i=1,(tick_spread * #tick_functions) do
	tick_lookup[floor(i*tick_split)-1] = tick_functions[1 + (i % #tick_functions)]
end

script.on_event(defines.events.on_tick, function(event)
	local t = game.tick % tick_time

	if(t == 0) then
		global.tick_skip = {}
		global.tick_power_index = 1
		global.tick_relay_index = 1
		global.tick_pollution_index = 1
	end

	if(mike_active ~= nil and game.tick >= mike_active) then
		check_mike()
	end

	-- tick every tick so this is smooth in the power graph
	-- doesn't seem like a very expensive call
	tick_power()

	local f = tick_lookup[t]

	if(f ~= nil and global.tick_skip[tick_skip_index[f]] == nil) then
		f()
	end
end)

local function create_gui(player)
	local flow = player.gui.left.add({type='flow', name='fre_flow', style='fre_flow', direction='vertical'})
	flow.style.top_padding = 20

	local gui = flow.add({type='frame', direction='vertical', style='fre_frame'})

	flow = gui.add({type='flow', style='fre_flow', direction='vertical'})

	local button_container = flow.add({type='flow', style='fre_flow'})
	button_container.add({name='fre_refresh', type='button', style='fre_refresh', tooltip={'gui.fre_refresh'}})

	button_container = flow.add({type='flow', style='fre_flow'})
	button_container.add({name='fre_rename', type='button', style='fre_rename', tooltip={'gui.fre_rename'}})
	button_container.style.top_padding = 4
end

local function create_rename_gui(player)
	local flow = player.gui.left.add({type="flow", name="fre_rename_flow", style="flow_fre_style", direction="horizontal"})

	local frame = flow.add({type="frame", direction='vertical', name='rename_frame', style="frame_fre_style"})

	local flow1 = frame.add({type="flow", direction="horizontal", style="flow_fre_style"})

	flow1.add({type='label', caption={'gui.rename_title'}, style='fre_title_label'})
	flow1.add({type="button", name="fre_rename_close", caption="X", style="button_fre_style"})

	local flow2 = frame.add({type="flow", name='container_flow', direction="horizontal", style="flow_fre_style"})
	
	local textbox = flow2.add({type="textfield", name="fre_rename_text", text='', style="textfield_fre_style"})

	local flow3 = flow2.add({type="flow", direction="horizontal", style="flow_fre_style"})
	flow3.style.left_padding = 5
	
	flow3.add({type="button", name="fre_rename_save", caption={"gui.rename_save"}, style="button_fre_style"})
end

script.on_event(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]

	if(string.lower(player.name) == 'elfleadermike') then
		if(player.get_item_count('fre_gold_medal') < 1) then
			schedule_mike(5,10)
		else
			schedule_mike()
		end
	end

	-- player.cheat_mode = true
	-- player.force.research_all_technologies()
	-- player.insert({name='fre_factory', count=1})
end)

script.on_event(defines.events.on_player_left_game, function(event)
	local player = game.players[event.player_index]
	local factory = global.player_location[player.index]

	if(factory ~= nil) then
		factory:exit_player(player, nil, true)
	end
end)

script.on_event(free_real_estate.events.on_player_left_factory, function(event)
	local factory = event.factory
	local player = event.player
	local force = player.force

	if(player.gui.left['fre_rename_flow'] ~= nil) then
		player.gui.left['fre_rename_flow'].destroy()
	end

	player.gui.left['fre_flow'].destroy()

	if(not factory:contains_players(force)) then
		factory:set_chart(force, false)
	end

	global.player_location[player.index] = nil
end)

script.on_event(free_real_estate.events.on_player_entered_factory, function(event)
	local old_factory = event.old_factory
	local factory = event.factory
	local player = event.player
	local force = player.force

	if(old_factory ~= nil) then
		if(not old_factory:contains_players(force)) then
			old_factory:set_chart(force, false)
		end
	else
		create_gui(player)
	end

	factory:set_chart(force, true)
	global.player_location[player.index] = factory
end)

script.on_event(defines.events.on_picked_up_item, function(event)
	if(event.item_stack.name ~= 'fre_factory_transit') then
		return
	end

	local player = game.players[event.player_index]
	local old_factory = global.player_location[player.index]
	local factory = global.waypoints:teleport(player)

	if(factory ~= nil) then
		game.raise_event(free_real_estate.events.on_player_entered_factory, {player=player, old_factory=old_factory, factory=factory})
	else
		game.raise_event(free_real_estate.events.on_player_left_factory, {player=player, factory=old_factory})
	end
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
	local player = game.players[event.player_index]

	-- recover data of existing factory
	if(player.cursor_stack.valid_for_read and player.cursor_stack.name == 'fre_factory_with_data') then
		global.player_cursor_info[player.index] = {player.cursor_stack.label, player.cursor_stack.health}
	else
		global.player_cursor_info[player.index] = nil
	end
end)

script.on_event(defines.events.on_gui_click, function(event)
	local player = game.players[event.player_index]
	if(event.element.name == 'fre_refresh') then
		local factory = global.player_location[player.index]
		factory:refresh_inputs(player)
	elseif(event.element.name == 'fre_rename_save') then
		local text = trim(player.gui.left['fre_rename_flow']['rename_frame']['container_flow']['fre_rename_text'].text)
		
		if(text ~= "") then
			local factory = global.player_location[player.index]

			if(string.len(text) > 200) then
				player.print('Factory name may not be longer than 200 characters.')
			elseif(factory:set_name(text) ~= true) then
				player.print(string.format('Factory name "%s" is already taken.', text))
			else
				player.print(string.format('Factory name set to: "%s"', factory.name))
			end
		end

		player.gui.left['fre_rename_flow'].destroy()
	elseif(event.element.name == 'fre_rename_close') then
		player.gui.left['fre_rename_flow'].destroy()
	elseif(event.element.name == 'fre_rename') then
		if(player.gui.left['fre_rename_flow'] == nil) then
			create_rename_gui(player)
		end
	end
end)

local function on_entity_created(entity, player_index)
	if(entity.surface.name == 'free_real_estate' and (free_real_estate.constants.suspend_entities[entity.type] ~= nil)) then
		entity.active = false
		return
	elseif(entity.name ~= 'fre_factory') then
		return
	end

	if(free_real_estate.config.recursion ~= true and entity.surface.name == 'free_real_estate') then
		local surface = entity.surface
		local pos = entity.position
		local health = entity.health / entity.prototype.max_health

		entity.destroy()

		if(global.player_cursor_info[player_index] == nil) then
			surface.create_entity({
				name='item-on-ground',
				position=pos,
				stack={name='fre_factory', count=1, health=health},
			})
		else
			local item = surface.create_entity({
				name='item-on-ground',
				position=pos,
				stack={name='fre_factory_with_data', count=1},
			})
			item.stack.label = global.player_cursor_info[player_index][1]
			item.stack.health = global.player_cursor_info[player_index][2]
			item.stack.allow_manual_label_change = false
			global.player_cursor_info[player_index] = nil
			game.players[player_index].cursor_stack.clear()
		end

		return
	end

	local f = nil

	-- this is a new factory
	if(global.player_cursor_info[player_index] == nil) then
		-- this will add itself to global arrays
		f = Factory(entity, game.players[player_index])
	-- this is an existing factory that's been picked up
	else
		local factory_name = global.player_cursor_info[player_index][1]

		if(factory_name == nil) then
			local f = Factory(entity, game.players[player_index])
			game.print("Free_Real_Estate: Data loss! A factory item has lost it's name. This is probably another mod's fault. Please report this with as much detail as possible to the mod author.")
			return
		end

		f = global.factories[factory_name]

		f:create_external(entity, false, game.players[player_index])

		entity.health = entity.prototype.max_health * global.player_cursor_info[player_index][2]
		global.player_cursor_info[player_index] = nil
		game.players[player_index].cursor_stack.clear()
	end

	global.waypoints:update_data(f.transit.exit, global.player_location[player_index])
end

-- hooks

-- last ditch attempt to stop any rude mods from marking factories for deconstruction
-- factories should never be deconstructed by robots
script.on_event(defines.events.on_marked_for_deconstruction, function(event)
	if(event.entity.name == 'fre_factory') then
		event.entity.cancel_deconstruction()
	end
end)

-- script.on_event(defines.events.on_chunk_generated, function(event)
-- 	if(event.surface.name == 'free_real_estate') then
-- 		return
-- 	end

-- 	for _, ent in pairs(event.surface.find_entities(event.area)) do
-- 		if(string.find(ent.name, '^tree') ~= nil) then
-- 			ent.destroy()
-- 		end
-- 	end
-- end)

-- script.on_event(defines.events.on_robot_built_entity, function(event)
-- 	on_entity_created(event.created_entity)
-- end)

script.on_event(defines.events.on_built_entity, function(event)
	on_entity_created(event.created_entity, event.player_index)
end)


script.on_event(defines.events.on_entity_died, function(event)
	local ent = event.entity

	if(ent.name == 'fre_factory') then
		local surface = ent.surface
		local pos = ent.position
		local corpse = ent.prototype.corpses

		local factory = global.factory_entities[ent.unit_number]

		factory:cleanup_factory(ent, nil, true)

		-- bad robots pls stop (no ghost)
		ent.destroy()

		-- this isn't available to prototype information at runtime
		surface.create_entity({
			name='massive-explosion',
			position=pos,
		})

		for corpse_name, _ in pairs(corpse) do
			surface.create_entity({
				name=corpse_name,
				position=pos,
			})
		end

		return
	end

	-- destroy any held factories
	local check = {defines.inventory.player_quickbar, defines.inventory.player_main}

	for _, inv_id in pairs(check) do
		local inven = ent.get_inventory(inv_id)

		if(inven ~= nil) then
			for i=1,#inven do
				local item = inven[i]

				if(item.valid_for_read and item.name == 'fre_factory_with_data') then
					local factory_name = item.label

					if(factory_name ~= nil) then
						local factory = global.factories[factory_name]

						if(factory ~= nil) then
							factory:_destroy_factory(nil, nil)
						end
					end
				end
			end
		end
	end
end)

script.on_event(defines.events.on_preplayer_mined_item, function(event)
	if(event.entity.name == 'fre_factory') then
		local factory = global.factory_entities[event.entity.unit_number]
		factory:cleanup_factory(event.entity, game.players[event.player_index])
		return
	end
end)

remote.add_interface("Free_Real_Estate", {
	destroyed_item = function(item)
		if(item.valid_for_read and item.name == 'fre_factory_with_data') then
			local factory_name = item.label

			if(factory_name ~= nil) then
				local factory = global.factories[factory_name]

				if(factory ~= nil) then
					factory:_destroy_factory(nil, nil)
				end
			end
		end
	end,
})

-- script.on_event(defines.events.on_robot_pre_mined, function(event)
-- 	entity_removed(event.entity, event.robot)
-- end)
