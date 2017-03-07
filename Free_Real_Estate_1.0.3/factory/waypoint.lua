require('class')
require('memes')

Waypoint = class(function(self)
	-- note to self: entry/exit points are represented using SimpleItemStack with health
	-- these stacks store item health as a float, not an int
	-- floats are typically perfectly accurate on ints from -16777216 to 16777216 (1 bit for sign, 24 bits for digits)
	self.next_transit_id = -16777216
	self.transit_info = {}
end)

function Waypoint:create(t)
	item_surface, item_pos, tp_surface, tp_pos, fresh, data = 
		assert(t[1] or t.item_surface),
		assert(t[2] or t.item_pos),
		assert(t[3] or t.tp_surface),
		assert(t[4] or t.tp_pos),
		t[5] or t.fresh,
		t[6] or t.data

	if(fresh == nil) then
		fresh = true
	end

	local ent = item_surface.create_entity({
		name='fre_pickup_mask',
		position={item_pos.x, item_pos.y - 0.5},
		force='neutral',
		bar=0,
	})
	ent.destructible = false

	local id = self.next_transit_id
	self.next_transit_id = self.next_transit_id + 1

	item_surface.create_entity({
		name='fre_item-pickup-only',
		position=item_pos,
		force='neutral',
		stack={name='fre_factory_transit', count=1, health=id},
	})

	self.transit_info[id] = {tp_surface=tp_surface, tp_pos=tp_pos, item_pos=item_pos, item_surface=item_surface, data=data, fresh=fresh}
	return id
end

function Waypoint:get_tp_pos(transit_id)
	return {position=self.transit_info[transit_id].tp_pos, surface=self.transit_info[transit_id].tp_surface, data=self.transit_info[transit_id].data}
end

function Waypoint:update_data(transit_id, data)
	self.transit_info[transit_id].data = data
end

function Waypoint:update_item_pos(transit_id, surface, pos)
	self.transit_info[transit_id].item_pos = pos
	self.transit_info[transit_id].item_surface = surface

	local ent = surface.create_entity({
		name='fre_pickup_mask',
		position={pos.x, pos.y - 0.5},
		force='neutral',
		bar=0,
	})
	ent.destructible = false

	local ent = surface.create_entity({
		name='fre_item-pickup-only',
		position=pos,
		force='neutral',
		stack={name='fre_factory_transit', count=1, health=transit_id},
	})
	ent.destructible = false
end

function Waypoint:update_tp_pos(transit_id, surface, pos)
	self.transit_info[transit_id].tp_surface = surface
	self.transit_info[transit_id].tp_pos = pos
end

function Waypoint:place_world(transit_id)
	local info = self.transit_info[transit_id]

	local ent = info.item_surface.create_entity({
		name='fre_pickup_mask',
		position={info.item_pos.x, info.item_pos.y - 0.5},
		force='neutral',
		bar=0,
	})
	ent.destructible = false

	local ent = info.item_surface.create_entity({
		name='fre_item-pickup-only',
		position=info.item_pos,
		force='neutral',
		stack={name='fre_factory_transit', count=1, health=transit_id},
	})
	ent.destructible = false
end

function Waypoint:clear_world(transit_id)
	local info = self.transit_info[transit_id]

	info.item_surface.find_entity('fre_pickup_mask', {info.item_pos.x, info.item_pos.y - 0.5}).destroy()
	info.item_surface.find_entity('fre_item-pickup-only', info.item_pos).destroy()
end

function Waypoint:dispose(transit_id)
	local info = self.transit_info[transit_id]

	-- factories can call clear, then dispose which calls clear again
	local item = info.item_surface.find_entity('fre_pickup_mask', {info.item_pos.x, info.item_pos.y - 0.5})
	if(item ~= nil) then
		item.destroy()
	end

	local item = info.item_surface.find_entity('fre_item-pickup-only', info.item_pos)
	if(item ~= nil) then
		item.destroy()
	end

	self.transit_info[transit_id] = nil
end

function Waypoint:teleport(player)
	local item = nil
	local check = {defines.inventory.player_main, defines.inventory.player_quickbar}
	local inven = nil

	for _, inv_id in pairs(check) do
		inven = player.get_inventory(inv_id)
		item = inven.find_item_stack('fre_factory_transit')

		if(item ~= nil) then
			break
		end
	end

	if(item == nil) then
		error('Failed to locate factory transit')
		return
	end

	local transit_id = item.health
	inven.remove(item.name)
	local transit = self.transit_info[transit_id]

	local ent = transit.item_surface.create_entity({
		name='fre_item-pickup-only',
		position=transit.item_pos,
		force='neutral',
		stack={name='fre_factory_transit', count=1, health=transit_id},
	})
	ent.destructible = false

	player.teleport(transit.tp_pos, transit.tp_surface)

	if(transit.fresh ~= nil) then
		transit.fresh = nil

		if(math.random(1,50) == 1) then
			local mi = math.random(1,#meme_magic)

			player.print(meme_magic[mi])
		end
	end

	return transit.data
end