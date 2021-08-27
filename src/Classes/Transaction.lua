--!strict
local Libraries = script.Parent.Parent.Libraries
local Promise = require(Libraries.Promise)

local class = {}
class.__metatable = "LOCKED"
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end

function class:Set(key: table)
	
end

function class:Update(key: table, func: any)
	
end

function class:Remove(key: table | string, version: int?)
	
end

function class:Commit(): nil
	
end

local constructor = {}

function constructor.new(model)
	return setmetatable({
		__model = model;
		__actions = {};
		__committing = false;
		__snapshot = {};
	}, class)
end

return constructor