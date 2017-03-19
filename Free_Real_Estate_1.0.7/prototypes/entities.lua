require('volt_util')
require('constants')

local power_input_per_second = free_real_estate.config.power_input_per_second

if(free_real_estate.config.power_input_multiplier < 1.0) then
	power_input_per_second = power_input_per_second + (power_input_per_second * (1.0 - free_real_estate.config.power_input_multiplier))
end

data:extend({
	{
		--type = "electric-energy-interface",
		type = 'lab',

		operable = false,
		on_animation = {
			filename = "__Free_Real_Estate__/graphics/entity/factory.png",
			width = 300,
			height = 242,
			shift = {0.5, 0},
			frame_count = 1,
			priority = "extra-high",
		},
		off_animation = {
			filename = "__Free_Real_Estate__/graphics/entity/factory.png",
			width = 300,
			height = 242,
			shift = {0.875, 1.0},
			frame_count = 1,
			priority = "extra-high",
		},
		working_sound = nil,
		inputs = {},

		name = "fre_factory",
		icon = "__Free_Real_Estate__/graphics/icons/factory.png",
		flags = {"not-blueprintable", "not-deconstructable"},
		-- minable = {hardness = 0.2, mining_time = 6, result = nil},
		-- max_health = 5000,
		minable = {hardness = 0.2, mining_time = 2.0, result = nil},
		max_health = 5000,
		corpse = "big-remnants",
		-- collision_box = {{-2.95, -2.95}, {2.95, 2.4}},
		-- selection_box = {{-3, -3}, {3, 3}},
		-- collision_box = {{-3.4, -3.4}, {3.4, 3.4}},
		-- selection_box = {{-3.6, -3.5}, {3.6, 3.9}},
		collision_box = {{-3.45, -3.2}, {3.45, 3.3}},
		selection_box = {{-3.5, -3.5}, {3.5, 3.5}},

		-- collision_box = {{-3.4, -3}, {3.4, 3}},
		-- selection_box = {{-3.6, -3.5}, {3.6, 3.9}},

		-- this is ignored because we have to do it programmatically, see death event in control.lua
		dying_explosion = "massive-explosion",
		energy_source = {
			type = "electric",
			usage_priority = "secondary-input"
		},
		energy_usage = "1KW",
	},

	-- utility
	{
		type = "assembling-machine",
		name = "fre_factory_connection_picker",
		icon = "__base__/graphics/icons/constant-combinator.png",
		flags = {"not-on-map", "not-blueprintable", "not-deconstructable"},
		minable = nil,
		max_health = 250,
		corpse = "big-remnants",
		dying_explosion = "medium-explosion",
		collision_box = {{-0.15, -0.15}, {0.15, 0.15}},
		selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
		animation = {
	        filename = "__base__/graphics/entity/combinator/combinator-entities.png",
	        y = 126,
	        width = 79,
	        height = 63,
	        frame_count = 1,
	        shift = {0.140625, 0.140625},
		},
		open_sound = { filename = "__base__/sound/machine-open.ogg", volume = 0.85 },
		close_sound = { filename = "__base__/sound/machine-close.ogg", volume = 0.75 },
		crafting_categories = {"fre_factory_connection"},
		crafting_speed = 0.75,
		energy_source = {
			type = "electric",
			usage_priority = "secondary-input",
			emissions = 0
		},
		energy_usage = "1kW",
		ingredient_count = 1,
	},
	{
		type = "electric-energy-interface",
		name = "fre_power_interface",
		icon = "__Free_Real_Estate__/graphics/icons/factory.png",
		collision_box = {{-3.45, -3.2}, {3.45, 3.3}},
		flags = {"not-blueprintable", "not-deconstructable", "not-on-map", "placeable-off-grid"},
		max_health = 0,
		minable = nil,
		corpse = "medium-remnants",
		collision_mask = {},
		energy_source = {
			type = "electric",
			buffer_capacity = power_input_per_second .. 'MJ',
			usage_priority = "secondary-input",
			input_flow_limit = power_input_per_second .. 'MW',
			output_flow_limit = '0W',
		},
		energy_production = "0W",
		energy_usage = "0kW",
		picture = {
			filename = "__core__/graphics/empty.png",
			priority = "low",
			width = 1,
			height = 1,
		},
	},
	{
		type = "lamp",
		name = "fre_factory-lamp",
		icon = "__base__/graphics/icons/small-lamp.png",
		flags = {"not-on-map", "not-blueprintable", "not-deconstructable"},
		minable = nil,
		max_health = 55,
		corpse = "small-remnants",
		collision_box = {{-0.15, -0.15}, {0.15, 0.15}},
		-- selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
		energy_source = {
			type = "electric",
			usage_priority = "secondary-input"
		},
		energy_usage_per_tick = "1KW",
		light = {intensity = 0.9, size = 58},
		picture_off = {
			filename = "__base__/graphics/entity/small-lamp/light-off.png",
			priority = "high",
			width = 67,
			height = 58,
			frame_count = 1,
			axially_symmetrical = false,
			direction_count = 1,
			shift = {-0.015625, 0.15625},
		},
		picture_on = {
			filename = "__base__/graphics/entity/small-lamp/light-on-patch.png",
			priority = "high",
			width = 62,
			height = 62,
			frame_count = 1,
			axially_symmetrical = false,
			direction_count = 1,
			shift = {-0.03125, -0.03125},
		},
	},


	clone_existing_data(data.raw['electric-pole'].substation, {
		name = 'fre_factory-power-provider',
		flags = {"not-on-map", "not-blueprintable", "not-deconstructable"},
		maximum_wire_distance = 0,
		supply_area_distance = 40,
		order = 'a',
	}, function(cloned) cloned.minable = nil end),
	clone_existing_data(data.raw.accumulator.accumulator, {
		name = 'fre_factory-power-reserve',
		flags = {"not-on-map", "not-blueprintable", "not-deconstructable"},
		order = 'a',
		energy_source = {
			type = "electric",
			buffer_capacity = (free_real_estate.config.power_input_per_second*5) .. 'MJ',
			usage_priority = "secondary-input",
			input_flow_limit = '0MW',
			output_flow_limit = free_real_estate.config.power_input_per_second .. 'MW',
		},
	}, function(cloned) cloned.minable = nil cloned.working_sound = nil end),

	-- waypoints
	{
		type = "item-entity",
		name = "fre_item-pickup-only",
		flags = {"placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable"},
		collision_box = {{-0.14, -0.14}, {0.14, 0.14}},
		selection_box = {{-0.17, -0.17}, {0.17, 0.17}}
	},
	{
		type = "container",
		name = "fre_pickup_mask",
		icon = "__Free_Real_Estate__/graphics/icons/nothing.png",
		flags = {"placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable"},
	    max_health = 200,
	    corpse = "small-remnants",
		collision_box = {{-1.5, -1.5}, {1.5, 1.5}},
		collision_mask = {
			-- "ground-tile", "water-tile", "resource-layer", "floor-layer", "item-layer", "object-layer", "ghost-layer", "doodad-layer"
			-- 'ground-tile',
			-- 'water-tile',
			'resource-layer',
			'floor-layer',
			'item-layer',
			'object-layer',
			-- 'player-layer',
			'doodad-layer',
		},
		-- selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
		inventory_size = 1,
		picture = {
			filename = "__Free_Real_Estate__/graphics/nothing.png",
			width = 1,
			height = 1,
		},
	},
})