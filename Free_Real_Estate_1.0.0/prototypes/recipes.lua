data:extend({
	{
		type = "recipe",
		name = "fre_tempered_steel",
		energy_required = 20,
		category = "smelting",
		enabled = false,
		ingredients = {
			{"steel-plate", 1},
		},
		result = "fre_tempered_steel",
	},
	{
		type = "recipe",
		name = "fre_reinforced_beam",
		energy_required = 20,
		enabled = false,
		ingredients = {
			{"iron-plate", 20},
			{"fre_tempered_steel", 20},
			{"concrete", 20},
		},
		result = "fre_reinforced_beam",
	},
	{
		type = "recipe",
		name = "fre_electronic_relay",
		energy_required = 15,
		enabled = false,
		ingredients = {
			{"electronic-circuit", 75},
			{"red-wire", 75},
			{"copper-cable", 100},
		},
		result = "fre_electronic_relay",
	},
	{
		type = "recipe",
		name = "fre_factory",
		energy_required = 60,
		localised_name = {'entity-name.fre_factory'},
		enabled = false,
		ingredients = {
			{"concrete", 200},
			{"fre_reinforced_beam", 20},
			{"fre_electronic_relay", 10},
			{"stone-wall", 200},
		},
		result = "fre_factory",
	},



	{
		type = "recipe-category",
		name = "fre_factory_connection"
	},
	{
		type = "item",
		name = "fre_factory_connection_ingredient",
		icon = "__Free_Real_Estate__/graphics/icons/nothing.png",
		flags = {"hidden", "goes-to-quickbar"},
		stack_size = 1
	},
})