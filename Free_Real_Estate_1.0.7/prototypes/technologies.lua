data:extend({
	{
		type = "technology",
		name = "fre_factory",
		icon = "__Free_Real_Estate__/graphics/icons/factory.png",
		localised_name = {'entity-name.fre_factory'},
		icon_size = 128,
		effects = {
			{
				type = "unlock-recipe",
				recipe = "fre_factory",
			},
			{
				type = "unlock-recipe",
				recipe = "fre_tempered_steel",
			},
			{
				type = "unlock-recipe",
				recipe = "fre_reinforced_beam",
			},
			{
				type = "unlock-recipe",
				recipe = "fre_electronic_relay",
			},
		},
		prerequisites = {"concrete", "electronics", "steel-processing"},
		unit = {
			count = 150,
			ingredients = {
				{"science-pack-1", 1},
				{"science-pack-2", 1},
			},
			time = 20,
		},
		order = "c-c-d",
	}
})
