--!strict
local HttpService = game:GetService("HttpService")
local class = {}
class.__metatable = "LOCKED"
class.__index = function(self, what: string): any
	if class[what] ~= nil then
		return class[what]
	end
	return rawget(self, "__values")[what]
end
class.__newindex = function(self, what: string, to: any)
	if what == "UserIds" then
		assert(type(to) == "table", "UserIds must be a table of UserIds")
		rawset(self, "UserIds", to)
	end
	local model = self.__model
	local column = model:GetColumn(what)
	local isValid, reason = column:validate(to)

	if isValid then
		self.__values[what] = to
	else
		error(string.format("Failed to set column in key '%s': %s", what, reason or "Failed type check"), 2)
	end
end
class.__tostring = function(self): string
	local model = self.__model
	local columnList = model:GetColumnList()

	local toConcat = {"<Index=", self.__keyindex}
	for name, column in pairs(columnList) do
		table.insert(toConcat, " " .. name .. "=" .. tostring(column:serialize(self[name])))
	end

	table.insert(toConcat, "/>")
	return table.concat(toConcat, "")
end

function class:GetMetadata(): {}
	return rawget(self, "Metadata")
end

function class:SetMetadata(metadata: {})
	assert(#HttpService:JSONEncode(metadata) <= 300, "Metadata cannot exceed 300 characters")
	rawset(self, "Metadata", metadata)
end

function class:__SetKeyInfo(keyInfo: DataStoreKeyInfo)
	rawset(self, "UserIds", keyInfo:GetUserIds())
	rawset(self, "Version", keyInfo.Version)
	rawset(self, "CreatedTime", keyInfo.CreatedTime)
	rawset(self, "UpdatedTime", keyInfo.UpdatedTime)
	self:SetMetadata(keyInfo:GetMetadata())
end

function class:serialize()
	local result = {}

	for name, value in pairs(self.__values) do
		local column = self.__model:GetColumn(name)
		if column then
			result[name] = column:serialize(value)
		end
	end

	return result
end

local constructor = {}

function constructor.new(model: table, index: string): {}
	if type(index) == "number" then index = tostring(index) end
	assert(model ~= nil, "Invalid argument #1 to Key.new (No Model object provided)")
	assert(model.GetColumn ~= nil, "Invalid argument #1 to Key.new (Expected Model object)")
	assert(index ~= nil, "Invalid argument #2 to Key.new (Index cannot  be nil)")
	assert(#index <= 50, "Invalid argument #2 to Key.new (Index cannot be longer than 50 characters)")
	local values = {}

	for name, column in pairs(model:GetColumnList()) do
		if column.Default == nil and not column.Nullable then
			error(string.format("Column '%s' has no default and is not nullable!", name), 2)
		end
		if type(column.Default) == "function" then
			values[name] = column.Default(index)
		else
			values[name] = column.Default
		end
	end

	return setmetatable({
		__values = values;
		__model = model;
		__keyindex = index;
		UserIds = {};
	}, class)
end

return constructor