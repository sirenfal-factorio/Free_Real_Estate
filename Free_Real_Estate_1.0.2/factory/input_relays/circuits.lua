require('class')
require('volt_util')
require('factory.input_relays.relay_errors')
require('factory.input_relays.relay_base')

local min = math.min
local ti = table.insert

CircuitRelay = class(RelayBase, function(self)
	RelayBase.init(self)
	self.type = 'circuit'
end)

-- dir is "input", "output" or "virtual"
-- virtual may return nil, which means saving contents is not desired
function CircuitRelay:get_entity_settings(factory_ent, dir, surface, position, is_external)
	if(dir == 'virtual') then
		return nil
	end

	local rotation = nil

	if(self.side == 'left') then
		rotation = ternary(is_external, defines.direction.west, defines.direction.east)
	elseif(self.side == 'right') then
		rotation = ternary(is_external, defines.direction.east, defines.direction.west)
	elseif(self.side == 'top') then
		rotation = ternary(is_external, defines.direction.north, defines.direction.south)
	elseif(self.side == 'bottom') then
		rotation = ternary(is_external, defines.direction.south, defines.direction.north)
	end

	return 'fre_connection-circuit_' .. dir, rotation, false
end

function CircuitRelay:get_recipe_name(dir)
	return string.format('fre_circuit-%s', dir)
end

function CircuitRelay:is_empty()
	return true
end

function CircuitRelay:replace_entity(old, new)
	old.destroy()
end

-- true if input completely empty, else false
function CircuitRelay:transfer_contents(input, output)
	return true
end

function CircuitRelay:relay()
	if(self.input == nil) then
		return
	end
	
	local source_red = self.input.get_circuit_network(defines.wire_type.red)
	local source_green = self.input.get_circuit_network(defines.wire_type.green)

	if(source_red ~= nil) then
		source_red = source_red.signals
	end

	if(source_green ~= nil) then
		source_green = source_green.signals
	end

	local signals = {}

	if(source_red == nil and source_green == nil) then
		self.output.get_or_create_control_behavior().parameters = nil
		return
	elseif(source_red == nil and source_green ~= nil) then
		for i=1,min(20, #source_green) do
			ti(signals, source_green[i])
		end
	elseif(source_red ~= nil and source_green == nil) then
		for i=1,min(20, #source_red) do
			ti(signals, source_red[i])
		end
	else
		-- both networks are connected and not empty
		local rl = #source_red
		local gl = #source_green

		-- if we have more than enough space for both networks
		if(rl + gl <= 20) then
			for _, v in pairs(source_green) do
				ti(source_red, v)
			end
			
			signals = source_red
		-- if we have extra space for one network
		elseif(rl < 10) then
			local extra = 10 - rl

			for i=1,min(10+extra, #source_green) do
				ti(source_red, source_green[i])
			end

			signals = source_red
		elseif(gl < 10) then
			local extra = 10 - gl

			for i=1,min(10+extra, #source_red) do
				ti(source_green, source_red[i])
			end

			signals = source_green
		-- there's too many signals in both networks, interleave the first 10
		else
			for i=1,10 do
				ti(signals, source_red[i])
				ti(signals, source_green[i])
			end
		end
	end

	for i, v in pairs(signals) do
		v.index = i
	end

	self.output.get_or_create_control_behavior().parameters = { parameters=signals }
end