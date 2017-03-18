empty_sprite = {
	filename = "__core__/graphics/empty.png",
	priority = "high",
	width = 1,
	height = 1,
	frame_count = 1,
}

data:extend({
	{
		type = "constant-combinator",
		name = "fre_connection-circuit_input",
		icon = "__base__/graphics/icons/constant-combinator.png",
		flags = {"not-blueprintable", "not-deconstructable"},
		minable = nil,
		max_health = 50,
		corpse = "small-remnants",

		collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
		selection_box = {{-0.5, -0.5}, {0.5, 0.5}},

		item_slot_count = 0,
		circuit_wire_max_distance = 25,

		sprites = {
			north = {
				filename = "__Free_Real_Estate__/graphics/entity/relays/circuit/circuit.png",
				x = 158,
				y = 0,
				width = 79,
				height = 63,
				frame_count = 1,
				shift = {0.140625, 0.140625},
			},
			east = {
				filename = "__Free_Real_Estate__/graphics/entity/relays/circuit/circuit.png",
				x = 0,
				y = 0,
				width = 79,
				height = 63,
				frame_count = 1,
				shift = {0.140625, 0.140625},
			},
			south = {
				filename = "__Free_Real_Estate__/graphics/entity/relays/circuit/circuit.png",
				x = 237,
				y = 0,
				width = 79,
				height = 63,
				frame_count = 1,
				shift = {0.140625, 0.140625},
			},
			west = {
				filename = "__Free_Real_Estate__/graphics/entity/relays/circuit/circuit.png",
				x = 79,
				y = 0,
				width = 79,
				height = 63,
				frame_count = 1,
				shift = {0.140625, 0.140625},
			}
		},

		activity_led_sprites = {
			north = empty_sprite,
			east = empty_sprite,
			south = empty_sprite,
			west = empty_sprite,
		},

		activity_led_light = {
			intensity = 0,
			size = 0,
		},

		activity_led_light_offsets = {
			{0, 0},
			{0, 0},
			{0, 0},
			{0, 0},
		},

		circuit_wire_connection_points = {
			{
				shadow = {
					red = {0.15625, -0.28125},
					green = {0.65625, -0.25}
				},
				wire = {
					red = {-0.28125, -0.5625},
					green = {0.21875, -0.5625},
				}
			},
			{
				shadow = {
					red = {0.75, -0.15625},
					green = {0.75, 0.25},
				},
				wire = {
					red = {0.46875, -0.5},
					green = {0.46875, -0.09375},
				}
			},
			{
				shadow = {
					red = {0.75, 0.5625},
					green = {0.21875, 0.5625}
				},
				wire = {
					red = {0.28125, 0.15625},
					green = {-0.21875, 0.15625}
				}
			},
			{
				shadow = {
					red = {-0.03125, 0.28125},
					green = {-0.03125, -0.125},
				},
				wire = {
					red = {-0.46875, 0},
					green = {-0.46875, -0.40625},
				}
			}
		},
	},
	{
		type = "constant-combinator",
		name = "fre_connection-circuit_output",
		icon = "__base__/graphics/icons/constant-combinator.png",
		flags = {"not-blueprintable", "not-deconstructable"},
		minable = nil,
		max_health = 50,
		corpse = "small-remnants",

		collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
		selection_box = {{-0.5, -0.5}, {0.5, 0.5}},

		item_slot_count = 20,
		circuit_wire_max_distance = 25,

		sprites = {
			north = {
				filename = "__Free_Real_Estate__/graphics/entity/relays/circuit/circuit.png",
				x = 158,
				y = 0,
				width = 79,
				height = 63,
				frame_count = 1,
				shift = {0.140625, 0.140625},
			},
			east = {
				filename = "__Free_Real_Estate__/graphics/entity/relays/circuit/circuit.png",
				x = 0,
				y = 0,
				width = 79,
				height = 63,
				frame_count = 1,
				shift = {0.140625, 0.140625},
			},
			south = {
				filename = "__Free_Real_Estate__/graphics/entity/relays/circuit/circuit.png",
				x = 237,
				y = 0,
				width = 79,
				height = 63,
				frame_count = 1,
				shift = {0.140625, 0.140625},
			},
			west = {
				filename = "__Free_Real_Estate__/graphics/entity/relays/circuit/circuit.png",
				x = 79,
				y = 0,
				width = 79,
				height = 63,
				frame_count = 1,
				shift = {0.140625, 0.140625},
			}
		},

		activity_led_sprites = {
			north = empty_sprite,
			east = empty_sprite,
			south = empty_sprite,
			west = empty_sprite,
		},

		activity_led_light = {
			intensity = 0,
			size = 0,
		},

		activity_led_light_offsets = {
			{0, 0},
			{0, 0},
			{0, 0},
			{0, 0},
		},

		circuit_wire_connection_points = {
			{
				shadow = {
					red = {0.15625, -0.28125},
					green = {0.65625, -0.25}
				},
				wire = {
					red = {-0.28125, -0.5625},
					green = {0.21875, -0.5625},
				}
			},
			{
				shadow = {
					red = {0.75, -0.15625},
					green = {0.75, 0.25},
				},
				wire = {
					red = {0.46875, -0.5},
					green = {0.46875, -0.09375},
				}
			},
			{
				shadow = {
					red = {0.75, 0.5625},
					green = {0.21875, 0.5625}
				},
				wire = {
					red = {0.28125, 0.15625},
					green = {-0.21875, 0.15625}
				}
			},
			{
				shadow = {
					red = {-0.03125, 0.28125},
					green = {-0.03125, -0.125},
				},
				wire = {
					red = {-0.46875, 0},
					green = {-0.46875, -0.40625},
				}
			}
		},
	},

	{
		type = "item",
		name = "fre_circuit-input",
		icon = "__Free_Real_Estate__/graphics/icons/connections/circuit-input.png",
		flags = {"hidden", "goes-to-quickbar"},
		stack_size = 1
	},
	{
		type = "recipe",
		name = "fre_circuit-input",
		category = "fre_factory_connection",
		enabled=false,
		ingredients = {
			{"fre_factory_connection_ingredient", 1},
		},
		result = "fre_circuit-input"
	},
	{
		type = "item",
		name = "fre_circuit-output",
		icon = "__Free_Real_Estate__/graphics/icons/connections/circuit-output.png",
		flags = {"hidden", "goes-to-quickbar"},
		stack_size = 1
	},
	{
		type = "recipe",
		name = "fre_circuit-output",
		category = "fre_factory_connection",
		enabled=false,
		ingredients = {
			{"fre_factory_connection_ingredient", 1},
		},
		result = "fre_circuit-output"
	},
})