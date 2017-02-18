require('class')
require('volt_util')
require('factory.input_relays.relay_errors')
require('factory.input_relays.relay_base')

ItemRelay = class(RelayBase, function(self)
	RelayBase.init(self)
	self.type = 'chest'
end)

-- dir is "input", "output" or "virtual"
-- virtual may return nil, which means saving contents is not desired
function ItemRelay:get_entity_settings(factory_ent, dir, surface, position, is_external)
	return 'fre_connection-chest_' .. dir, nil
end

function ItemRelay:get_recipe_name(dir)
	return string.format('fre_chest-%s', dir)
end

function ItemRelay:is_empty()
	local ext = self:get_external()
	return
		(self.external_storage == nil or self.external_storage.has_items_inside() == false) and
		self:get_internal().has_items_inside() == false and
		(ext == nil or ext.has_items_inside() == false)
end

function ItemRelay:replace_entity(old, new)
	local old_inven = old.get_inventory(defines.inventory.chest)
	local new_inven = new.get_inventory(defines.inventory.chest)

	for i=1,#old_inven do
		new_inven[i].set_stack(old_inven[i])
	end

	new_inven.setbar(old_inven.getbar())

	old.destroy()
end

-- true if input completely empty, else false
function ItemRelay:transfer_contents(input, output)
	local input = input.get_inventory(defines.inventory.chest)
	local output = output.get_inventory(defines.inventory.chest)

	for i=1,#input do
		local input_item = input[i]

		if(input_item.valid_for_read) then
			local inserted = output.insert(input_item)

			if(inserted > 0) then
				if(inserted >= input_item.count) then
					input_item.clear()
				else
					input_item.count = input_item.count - inserted
				end
			end
		end
	end

	-- for i=1,#input do
	-- 	local input_item = input[i]

	-- 	if(input_item.valid_for_read) then
	-- 		for j=1,output.getbar() do
	-- 			local output_item = output[j]

	-- 			if(not output_item.valid_for_read) then
	-- 				output_item.set_stack(input_item)
	-- 				input_item.clear()
	-- 				break
	-- 			elseif(input_item.name == output_item.name and input_item.health == output_item.health) then
	-- 				-- skip checking prototype, just use a delta
	-- 				local available = input_item.count
	-- 				local current = output_item.count
	-- 				output_item.count = output_item.count + available
	-- 				local transferred = output_item.count - current

	-- 				if(transferred == available) then
	-- 					input_item.clear()
	-- 					break
	-- 				else
	-- 					input_item.count = input_item.count - transferred
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end

	return input.is_empty()
end

function ItemRelay:relay()
	if(self.input == nil or self.input.has_items_inside() == false) then
		return
	end

	-- if all stack slots are consumed (fastest way to check)
	if(not self.input.can_insert('fre_factory_transit') or not self.output.can_insert('fre_factory_transit')) then
		return
	end

	if(self.external_storage ~= nil) then
		if(self:transfer_contents(self.external_storage, self.output) == true) then
			self.external_storage.destroy()
			self.external_storage = nil
		else
			return
		end
	end

	if(self.remote_relay ~= nil and self.remote_relay.external_storage ~= nil) then
		if(self:transfer_contents(self.remote_relay.external_storage, self.output) == true) then
			self.remote_relay.external_storage.destroy()
			self.remote_relay.external_storage = nil
		else
			return
		end
	end

	local input = self.input.get_inventory(defines.inventory.chest)
	local output = self.output.get_inventory(defines.inventory.chest)

	for i=1,#input do
		local input_item = input[i]

		if(input_item.valid_for_read) then
			local inserted = output.insert(input_item)

			if(inserted > 0) then
				if(inserted >= input_item.count) then
					input_item.clear()
				else
					input_item.count = input_item.count - inserted
				end
			end
		end
	end
end

-- teleport items on the ground into the chest we're placing
function ItemRelay:place_external(t)
	local factory, external_surface, external_pos = 
		t[1] or t.factory,
		t[2] or t.external_surface,
		t[3] or t.external_pos

	local items = {}

	for _, item in pairs(external_surface.find_entities_filtered({
		area={
			{external_pos.x, external_pos.y},
			{external_pos.x + 1, external_pos.y + 1},
		},
		name='item-on-ground',
	})) do
		item.teleport({item.position.x, item.position.y+5})
		table.insert(items, item)
	end

	local res = RelayBase.place_external(self, t)

	if(res == SUCCESS) then
		local external_inventory = self:get_external().get_inventory(defines.inventory.chest)

		-- copy items picked up from the ground into the newly placed chest
		for _, item_ent in pairs(items) do
			local input_item = item_ent.stack
			local inserted = external_inventory.insert(input_item)

			if(inserted > 0) then
				if(inserted >= input_item.count) then
					item_ent.destroy()
				else
					input_item.count = input_item.count - inserted
				end
			end
		end
	end

	-- move any items we didn't have space for back to where they were and call it a day
	for _, item in pairs(items) do
		if(item.valid) then
			item.teleport({item.position.x, item.position.y-5})
		end
	end

	return res
end