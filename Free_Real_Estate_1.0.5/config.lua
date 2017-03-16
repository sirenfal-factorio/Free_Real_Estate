if not free_real_estate then free_real_estate = {} end
if not free_real_estate.config then free_real_estate.config = {} end

-- in megawatts
free_real_estate.config.power_input_per_second = 50
free_real_estate.config.power_input_multiplier = 0.8

-- 0: day/night with lamps, 1: always night with lamps, 2: day/night without lamps, 3: always day, 4: always night
-- changing lamp settings will only apply to new factories, not existing ones
free_real_estate.config.factory_time = 0
free_real_estate.config.pollution_multiplier = 1.0

-- whether you can place factories inside factories
free_real_estate.config.recursion = false

-- if the player should be killed when a factory is destroyed (not picked up)
free_real_estate.config.kill_on_destroy = false

-- whether to remove all energy from a factory's accumulator when it's picked up
free_real_estate.config.remove_energy_on_pickup = false

-- automatically set all relays to only have this many slots non-restricted on both sides
-- -1 disables this feature
free_real_estate.config.item_relay_bar = 5