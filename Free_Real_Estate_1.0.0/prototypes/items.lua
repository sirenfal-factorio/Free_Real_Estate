require('volt_util')

data:extend({
	{
		type = "item",
		name = "fre_factory",
		localised_name = {'entity-name.fre_factory'},
		icon = "__Free_Real_Estate__/graphics/icons/factory.png",
		flags = {"goes-to-quickbar"},
		subgroup = "production-machine",
		order = "y[factory]-a[factory]",
		place_result = "fre_factory",
		stack_size = 10,
	},
	{
		type = "item-with-label",
		name = "fre_factory_with_data",
		localised_name = {'entity-name.fre_factory'},
		icon = "__Free_Real_Estate__/graphics/icons/factory.png",
		flags = {"goes-to-quickbar"},
		subgroup = "production-machine",
		order = "y[factory]-a[factory]",
		place_result = "fre_factory",
		draw_label_for_cursor_render = true,
		stack_size = 1,
	},
	{
		type = "item",
		name = "fre_factory_transit",
		icon = "__Free_Real_Estate__/graphics/icons/nothing.png",
		flags = {"hidden", "goes-to-quickbar"},
		stack_size = 1
	},

	{
		type = "item",
		name = "fre_tempered_steel",
		icon = "__Free_Real_Estate__/graphics/icons/tempered-steel.png",
		stack_size = 100,

		flags = {"goes-to-main-inventory"},
		subgroup = "intermediate-product",
		order = "d[tempered-steel]",
	},
	{
		type = "item",
		name = "fre_reinforced_beam",
		icon = "__Free_Real_Estate__/graphics/icons/reinforced-beam.png",
		stack_size = 50, 

		flags = {"goes-to-main-inventory"},
		subgroup = "intermediate-product",
		order = "d[reinforced-beam]",
	},
	{
		type = "item",
		name = "fre_electronic_relay",
		icon = "__Free_Real_Estate__/graphics/icons/electronic-relay.png",
		stack_size = 10,

		flags = {"goes-to-main-inventory"},
		subgroup = "intermediate-product",
		order = "d[electronic-relay]",
	},


	{
		type = "item",
		name = "fre_gold_medal",
		localised_description = {'item-description.fre_gold_medal'},
		icon = "__Free_Real_Estate__/graphics/icons/gold-medal.png",
		stack_size = 1,

		flags = {"goes-to-main-inventory"},
		order = "zzzzzzzzzzzz",
	},
})