--!strict
local Libraries = script.Parent.Parent.Libraries
local Promise = require(Libraries.Promise)
local Util = require(script.Parent.util)

local class = {}
class.__metatable = "LOCKED"
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end

function class:Set(key: table, setoptions: DataStoreSetOptions)
	table.insert(self.__actions, {action="SET", key=key, setoptions=setoptions})
end

function class:Update(key: string, func: any)
	table.insert(self.__actions, {action="UPDATE", key=key, func=func})
end

function class:Remove(key: string, version: string?)
	table.insert(self.__actions, {action="REMOVE", key=key, version=version})
end

function class:Commit()
	assert(not self.__committing, "Cannot commit a transaction that is already being committed.")
	local model = self.__model
	local datastore = model.__datastore

	return Promise.async(function(resolve, reject)
		local failed = false
		local succeeded = {}
		local results = {}
		for _, action in pairs(self.__actions) do
			if action.action == "UPDATE" then
				local success, result, keyInfo = pcall(function()
					return datastore:UpdateAsync(action.key, function(old, oldKeyInfo)
						action.snapshot = {Util.deepcopy(old), oldKeyInfo:Clone()}
						for name, val in pairs(old) do
							local column = model:GetColumn(name)
							if column then
								old[name] = column:deserialize(val)
							end
						end
						local newData, newKeyInfo, metaData = action.func(old, oldKeyInfo)

						if newData then
							for name, val in pairs(newData) do
								local column = model:GetColumn(name)
								if column then
									newData[name] = column:serialize(val)
								end
							end
						end

						return newData, newKeyInfo, metaData
					end)
				end)

				if success then
					table.insert(succeeded, action)
					table.insert(results, {
						Values = result;
						KeyInfo = keyInfo;
					})
				else
					failed = true
					break
				end
			else
				local successGet, resultGet, keyInfoGet = pcall(function()
					return datastore:GetAsync(type(action.key) == "string" and action.key or action.key.__keyindex)
				end)

				if successGet then
					action.snapshot = {resultGet, keyInfoGet}

					if action.action == "SET" then
						local success, version = pcall(function()
							return datastore:SetAsync(action.key.__keyindex, action.key:serialize(), action.setoptions)
						end)

						if success then
							table.insert(succeeded, action)
							table.insert(results, {
								Version = version;
							})
						else
							failed = true
							break
						end
					elseif action.action == "REMOVE" then
						local success, oldData, oldKeyInfo = pcall(function()
							if action.version then
								return datastore:RemoveVersionAsync(action.key, action.version)
							else
								return datastore:RemoveAsync(action.key)
							end
						end)

						if success then
							table.insert(succeeded, action)

							if oldData and oldKeyInfo then
								for name, val in pairs(oldData) do
									local column = model:GetColumn(name)
									if column then
										oldData[name] = column:deserialize(val)
									end
								end
								table.insert(results, {
									Values = oldData;
									KeyInfo = oldKeyInfo
								})
							else
								table.insert(results, {})
							end
						else
							failed = true
							break
						end
					end
				else
					failed = true
					break
				end
			end
		end

		if failed then
			for _, action in pairs(succeeded) do
				local success, result = pcall(function()
					if action.action == "SET" or action.action == "UPDATE" then
						if action.snapshot == nil then
							datastore:RemoveAsync(type(action.key) == "string" and action.key or action.key.__keyindex)
						else
							datastore:SetAsync(type(action.key) == "string" and action.key or action.key.__keyindex, action.snapshot[1], action.snapshot[2])
						end
					elseif action.action == "REMOVE" then
						datastore:SetAsync(action.key, action.snapshot[1], action.snapshot[2])
					end
				end)

				if not success then
					warn(string.format("[DATA-ALCHEMY]: Failed to rollback action '%s' for key '%s': %s", action.action, type(action.key) == "string" and action.key or action.key.__keyindex, result))
				end

				action.snapshot = nil
			end

			self.__committing = false
			reject("One of the transactions failed and all successful actions had to be rolled back")
		else
			if self.__autoflush then
				self:Flush()
			end
			self.__committing = false
			resolve(results)
		end
	end)
end

function class:Flush()
	table.clear(self.__actions)
end

local constructor = {}

function constructor.new(model: table, autoFlush: boolean): table
	return setmetatable({
		__model = model;
		__actions = {};
		__committing = false;
		__autoflush = autoFlush;
	}, class)
end

return constructor