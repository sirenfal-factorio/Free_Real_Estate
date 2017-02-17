data:extend({
	{
		type = "container",
		name = "fre_connection-chest_input",
		icon = "__base__/graphics/icons/steel-chest.png",
		flags = {"not-blueprintable", "not-deconstructable"},
		minable = nil,
		max_health = 0,
		corpse = "small-remnants",
		open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.65 },
		close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.7 },
		collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
		selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
		inventory_size = 48,
		vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
		picture = {
			filename = "__base__/graphics/entity/steel-chest/steel-chest.png",
			priority = "high",
			width = 48,
			height = 34,
			shift = {0.1875, 0}
		},
	},
	{
		type = "container",
		name = "fre_connection-chest_output",
		icon = "__base__/graphics/icons/steel-chest.png",
		flags = {"not-blueprintable", "not-deconstructable"},
		minable = nil,
		max_health = 0,
		corpse = "small-remnants",
		open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.65 },
		close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.7 },
		collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
		selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
		inventory_size = 48,
		vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
		picture = {
			filename = "__base__/graphics/entity/steel-chest/steel-chest.png",
			priority = "high",
			width = 48,
			height = 34,
			shift = {0.1875, 0}
		},
	},
	-- item storage while held
	{
		type = "container",
		name = "fre_connection-chest_virtual",
		icon = "__base__/graphics/icons/steel-chest.png",
		flags = {"placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable"},
		minable = nil,
		max_health = 0,
		corpse = "small-remnants",
		open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.65 },
		close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.7 },
		collision_box = nil,
		selection_box = nil,
		inventory_size = 48,
		vehicle_impact_sound = { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
		picture = {
			filename = "__Free_Real_Estate__/graphics/nothing.png",
			width = 1,
			height = 1,
		}
	},


	{
		type = "item",
		name = "fre_chest-input",
		icon = "__Free_Real_Estate__/graphics/icons/connections/chest-input.png",
		flags = {"hidden", "goes-to-quickbar"},
		stack_size = 1
	},
	{
		type = "recipe",
		name = "fre_chest-input",
		category = "fre_factory_connection",
		enabled=false,
		ingredients = {
			{"fre_factory_connection_ingredient", 1},
		},
		result = "fre_chest-input"
	},
	{
		type = "item",
		name = "fre_chest-output",
		icon = "__Free_Real_Estate__/graphics/icons/connections/chest-output.png",
		flags = {"hidden", "goes-to-quickbar"},
		stack_size = 1
	},
	{
		type = "recipe",
		name = "fre_chest-output",
		category = "fre_factory_connection",
		enabled=false,
		ingredients = {
			{"fre_factory_connection_ingredient", 1},
		},
		result = "fre_chest-output"
	},
})