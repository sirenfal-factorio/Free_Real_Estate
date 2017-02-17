require('volt_util')

empty_sprite = {
	filename = "__core__/graphics/empty.png",
	priority = "high",
	width = 1,
	height = 1,
}

pipe_base = {
	type = "storage-tank",
	icon = "__base__/graphics/icons/storage-tank.png",
	flags = {"not-blueprintable", "not-deconstructable"},
	order = 'a',
	minable = nil,
	max_health = 250,
	corpse = "medium-remnants",
	collision_box = {{-0.29, -0.29}, {0.29, 0.29}},
	selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
	fluid_box = {
		base_area = 100,
		pipe_covers = pipecoverspictures(),
	},
	window_bounding_box = {{-0.3, -0.3}, {0.3, 0.3}},
	pictures = {
		fluid_background = empty_sprite,
		window_background = empty_sprite,
		flow_sprite = empty_sprite,
	},
	flow_length_in_ticks = 360,
}

data:extend({
	clone_existing_data(pipe_base, {
		name = "fre_connection-pipe_input-straight",
		fluid_box = {
			__partial__ = true,
			pipe_connections = {
				{ position = {0, -1} },
				{ position = {0, 1} },
			},
		},
		pictures = {
			__partial__ = true,
			picture = {
				sheet = {
					filename = "__Free_Real_Estate__/graphics/entity/relays/pipe/pipe-straight.png",
					priority = "high",
					frames = 2,
					width = 44,
					height = 44,
				},
			},
		},
	}),
	clone_existing_data(pipe_base, {
		name = "fre_connection-pipe_input-junction",
		fluid_box = {
			__partial__ = true,
			pipe_connections = {
				{ position = {1, 0} },
				{ position = {0, 1} },
				{ position = {-1, 0} },
			},
		},
		pictures = {
			__partial__ = true,
			picture = {
				sheet = {
					filename = "__Free_Real_Estate__/graphics/entity/relays/pipe/pipe-junction.png",
					priority = "high",
					frames = 4,
					width = 44,
					height = 44,
				},
			},
		},
	}),
	clone_existing_data(pipe_base, {
		name = "fre_connection-pipe_input-cross",
		fluid_box = {
			__partial__ = true,
			pipe_connections = {
				{ position = {1, 0} },
				{ position = {0, 1} },
				{ position = {-1, 0} },
				{ position = {0, -1} },
			},
		},
		pictures = {
			__partial__ = true,
			picture = {
				sheet = {
					filename = "__Free_Real_Estate__/graphics/entity/relays/pipe/pipe-cross.png",
					priority = "high",
					frames = 1,
					width = 40,
					height = 40,
				},
			},
		},
	}),

	clone_existing_data(pipe_base, {
		name = "fre_connection-pipe_output-straight",
		fluid_box = {
			__partial__ = true,
			pipe_connections = {
				{ position = {0, -1} },
				{ position = {0, 1} },
			},
		},
		pictures = {
			__partial__ = true,
			picture = {
				sheet = {
					filename = "__Free_Real_Estate__/graphics/entity/relays/pipe/pipe-straight.png",
					priority = "high",
					frames = 2,
					width = 44,
					height = 44,
				},
			},
		},
	}),
	clone_existing_data(pipe_base, {
		name = "fre_connection-pipe_output-junction",
		fluid_box = {
			__partial__ = true,
			pipe_connections = {
				{ position = {1, 0} },
				{ position = {0, 1} },
				{ position = {-1, 0} },
			},
		},
		pictures = {
			__partial__ = true,
			picture = {
				sheet = {
					filename = "__Free_Real_Estate__/graphics/entity/relays/pipe/pipe-junction.png",
					priority = "high",
					frames = 4,
					width = 44,
					height = 44,
				},
			},
		},
	}),
	clone_existing_data(pipe_base, {
		name = "fre_connection-pipe_output-cross",
		fluid_box = {
			__partial__ = true,
			pipe_connections = {
				{ position = {1, 0} },
				{ position = {0, 1} },
				{ position = {-1, 0} },
				{ position = {0, -1} },
			},
		},
		pictures = {
			__partial__ = true,
			picture = {
				sheet = {
					filename = "__Free_Real_Estate__/graphics/entity/relays/pipe/pipe-cross.png",
					priority = "high",
					frames = 1,
					width = 40,
					height = 40,
				},
			},
		},
	}),
	clone_existing_data(pipe_base, {
		name = "fre_connection-pipe_virtual",
		fluid_box = {
			__partial__ = true,
			pipe_connections = {
			},
		},
		pictures = {
			__partial__ = true,
			picture = {
				sheet = {
					filename = "__Free_Real_Estate__/graphics/entity/relays/pipe/pipe-cross.png",
					priority = "high",
					frames = 1,
					width = 40,
					height = 40,
				},
			},
		},
		flags = {"placeable-off-grid", "not-on-map", "not-blueprintable", "not-deconstructable"},
		collision_box = nil,
		selection_box = nil,
		picture = {
			filename = "__Free_Real_Estate__/graphics/nothing.png",
			width = 1,
			height = 1,
		}
	}),


	{
		type = "item",
		name = "fre_pipe-input",
		icon = "__Free_Real_Estate__/graphics/icons/connections/pipe-input.png",
		flags = {"hidden", "goes-to-quickbar"},
		stack_size = 1
	},
	{
		type = "recipe",
		name = "fre_pipe-input",
		category = "fre_factory_connection",
		enabled=false,
		ingredients = {
			{"fre_factory_connection_ingredient", 1},
		},
		result = "fre_pipe-input"
	},
	{
		type = "item",
		name = "fre_pipe-output",
		icon = "__Free_Real_Estate__/graphics/icons/connections/pipe-output.png",
		flags = {"hidden", "goes-to-quickbar"},
		stack_size = 1
	},
	{
		type = "recipe",
		name = "fre_pipe-output",
		category = "fre_factory_connection",
		enabled=false,
		ingredients = {
			{"fre_factory_connection_ingredient", 1},
		},
		result = "fre_pipe-output"
	},
})