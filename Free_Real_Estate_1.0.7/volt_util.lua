require('util')

local floor = math.floor
local abs = math.abs

function ms_to_ticks(ms)
	return math.ceil(ms / (1000 / 60))
end

local function _clone_onto(source, override, partial)
	local partial = partial or false

	if(override['__partial__'] == true) then
		partial = true
		override['__partial__'] = nil
	else
		return override
	end

	-- TODO: handle numeric-only arrays specially here (merge properly if partial)

	for k,v in pairs(override) do
		if(source[k] ~= nil and type(source[k]) == 'table') then
			source[k] = _clone_onto(source[k], v, true)
		else
			-- __partial__ will leak for tables here, but who cares?
			source[k] = v
		end
	end

	return source
end

-- each key will fully replace that key unless __partial__ is in the table, in which case
-- it will be merged with any keys from this table replacing keys in the source table
-- partial true/false is recursive after each occurence
function clone_existing_data(entry, data, f)
	if(entry == nil) then
		error('Tried to clone non-existant data key')
	end

	local new = table.deepcopy(entry)
	data['__partial__'] = true

	local ret = _clone_onto(new, data)

	if(f ~= nil) then
		f(ret)
	end

	return ret
end

-- no_errors returns nil instead of using error() if not found
function index(t, item, no_errors)
	if(type(item) == 'function') then
		for k,v in pairs(t) do
			if(item(v) == true) then
				return k
			end
		end
	else
		for k,v in pairs(t) do
			if(v == item) then
				return k
			end
		end
	end

	if(no_errors) then
		return nil
	else
		error('Failed to find item\n\n' .. debug.traceback())
	end
end

function trim(s)
	local n = s:find"%S"
	return n and s:match(".*%S", n) or ""
end

function ternary(condition, t, f, call)
	if(condition) then
		if(call ~= false and type(t) == 'function') then
			return t()
		else
			return t
		end
	else
		if(call ~= false and type(f) == 'function') then
			return f()
		else
			return f
		end
	end
end

function snap_to_grid(t)
	local x, y = 
		assert(t[1] or t.x),
		assert(t[2] or t.y)

	local x_sign = 1

	if(x < 0) then
		x_sign = -1
	end

	local y_sign = 1

	if(y < 0) then
		y_sign = -1
	end

	return {
		x = (floor(abs(x)) + 0.5) * x_sign,
		y = (floor(abs(y)) + 0.5) * y_sign,
	}
end

function capitalize(s)
	if(#s < 2) then
		return string.upper(s)
	end

	first, s = string.match(s, '^(.)(.+)$')

	return string.upper(first) .. s
end