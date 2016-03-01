
function _new_(self, instance)
  instance = instance or {}
  setmetatable(instance, self)
  self.__index = self
  return instance
end

StopPlanOutException = {}

function StopPlanOutException:new(inExperiment)
  return _new_(self, {inExperiment = inExperiment})
end

function isOperator(op)
  return type(op) == "table" and op.op ~= nil
end

function map(obj, func, context)
  local results = {}
  if type(obj) == "table" then
    for i, val in ipairs(obj) do
      table.insert(results, func(val, i, obj))
    end
  end
  return results
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function table.slice(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

function instanceOf (subject, super)
	super = tostring(super)
	local mt = getmetatable(subject)

	while true do
		if mt == nil then return false end
		if tostring(mt) == super then return true end

		mt = getmetatable(mt)
	end
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

table.indexOf = function( t, object )
	if "table" == type( t ) then
		for i=1,#t do
			if object == t[i] then
				return i
			end
		end
	end

	return -1
end

function range(max)
  local l = {}
  for i = 1, max do
    table.insert(l, i)
  end
  return l
end
