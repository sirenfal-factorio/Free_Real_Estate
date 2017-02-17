if not free_real_estate then free_real_estate = {} end
if not free_real_estate.constants then free_real_estate.constants = {} end

free_real_estate.constants.tick_spread = 5
-- 60 = 1s
-- shorter tick times require better cpu/more ups
free_real_estate.constants.tick_time = 120

-- THIS CANNOT BE CHANGED ON AN EXISTING MAP
free_real_estate.constants.factories_per_row = 2
free_real_estate.constants.spacing_per_entry = 150


-- these entity types are not allowed inside factories and will be disabled
free_real_estate.constants.suspend_entities = {car=true, ['solar-panel']=true}

-- these entities still count as "empty" inside a factory, which will stop the factory from being saved when
-- it's picked up
free_real_estate.constants.our_entities = {
	['fre_factory-power-provider']=true,
	['fre_factory-power-reserve']=true,
	['fre_item-pickup-only']=true,
	['fre_pickup_mask']=true,
	['fre_factory-lamp']=true,
	['fre_factory_connection_picker']=true,
}

-- no way to determine this programmatically...
free_real_estate.constants.vehicles = {
	['car']=true,
	['locomotive']=true,
}

-- do not suspend or restore these when a factory is picked up/placed
-- these can cause a crash in 0.14.22
free_real_estate.constants.temporary = {
	['smoke']=true,
	['particle']=true,
	['corpse']=true,
}