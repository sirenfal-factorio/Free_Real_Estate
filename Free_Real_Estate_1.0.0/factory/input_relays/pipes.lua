require('class')
require('volt_util')
require('factory.input_relays.relay_errors')
require('factory.input_relays.relay_base')

PipeRelay = class(RelayBase, function(self)
	RelayBase.init(self)
	self.type = 'pipe'
end)

-- dir is "input", "output" or "virtual"
-- factory is either factory entity or nil if 'virtual' is requested
-- virtual may return nil, which means saving contents is not desired
function PipeRelay:get_entity_settings(factory_ent, dir, surface, position, is_external)
	if(dir == 'virtual') then
		return 'fre_connection-pipe_virtual', nil
	end

	if(is_external == false) then
		return string.format('fre_connection-pipe_%s-straight', dir), ternary(self.side == 'left' or self.side == 'right', defines.direction.east, defines.direction.north)
	end

	local factory = global.factory_entities[factory_ent.unit_number]
	local relay_index = nil
	local side = factory.inputs[self.side]

	for k, input in pairs(side) do
		if(input.relay == self) then
			relay_index = k
			break
		end
	end

	if(relay_index == nil) then
		error('Failed to find input index')
		return
	end

	local left_open = relay_index == 1 or side[relay_index - 1].relay == nil or side[relay_index - 1].relay.destroying == true
	local right_open = relay_index == #side or side[relay_index + 1].relay == nil or side[relay_index + 1].relay.destroying == true

	if(left_open and right_open) then
		return string.format('fre_connection-pipe_%s-cross', dir), nil
	elseif(left_open == false and right_open == false) then
		return string.format('fre_connection-pipe_%s-straight', dir), ternary(self.side == 'left' or self.side == 'right', defines.direction.east, defines.direction.north)
	end

	-- top and bottom: left is left (-x)
	-- left and right: left is up (-y)

	if(self.side == 'left' or self.side == 'right') then
		if(left_open) then
			return string.format('fre_connection-pipe_%s-junction', dir), defines.direction.south
		else
			return string.format('fre_connection-pipe_%s-junction', dir), defines.direction.north
		end
	else
		if(left_open) then
			return string.format('fre_connection-pipe_%s-junction', dir), defines.direction.east
		else
			return string.format('fre_connection-pipe_%s-junction', dir), defines.direction.west
		end
	end
end

function PipeRelay:get_recipe_name(dir)
	return string.format('fre_pipe-%s', dir)
end

function PipeRelay:is_empty()
	local ext = self:get_external()
	return
		(self.external_storage == nil or self.external_storage.fluidbox[1] == nil) and
		self:get_internal().fluidbox[1] == nil and
		(ext == nil or ext.fluidbox[1] == nil)
end

function PipeRelay:replace_entity(old, new)
	new.fluidbox[1] = old.fluidbox[1]
	old.destroy()
end

-- true if input completely empty, else false
function PipeRelay:transfer_contents(input, output)
	if(output == nil) then
		error('sdfgsdfgfdg\n\n' .. debug.traceback())
	end

	local input_contents = input.fluidbox[1]
	local output_contents = output.fluidbox[1]

	if(input_contents == nil) then
		return true
	end

	if(output_contents == nil) then
		output.fluidbox[1] = input_contents
		input.fluidbox[1] = nil
		return true
	end

	if(input_contents.type ~= output_contents.type) then
		return false
	end

	-- determine how much liquid we're adding
	local final_contents = output.fluidbox[1]
	final_contents.amount = final_contents.amount + input_contents.amount

	output.fluidbox[1] = final_contents
	final_contents = output.fluidbox[1]

	local transferred = final_contents.amount - output_contents.amount

	if(transferred < 1) then
		return false
	end

	-- calculate final temperature based on percentages
	local ftemp = 0

	ftemp = ftemp + ((output_contents.amount / final_contents.amount) * output_contents.temperature)
	ftemp = ftemp + ((transferred / final_contents.amount) * input_contents.temperature)

	input_contents.amount = input_contents.amount - transferred
	final_contents.temperature = ftemp

	if(input_contents.amount < 1) then
		input.fluidbox[1] = nil
	else
		input.fluidbox[1] = input_contents
	end

	output.fluidbox[1] = final_contents

	return input.fluidbox[1] == nil
end

function PipeRelay:relay()
	if(self.input == nil or self.input.fluidbox[1] == nil) then
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

	self:transfer_contents(self.input, self.output)
end