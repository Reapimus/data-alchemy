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
	assert(not self.__committing, "This transaction is currently committing and cannot be altered.")
	table.insert(self.__actions, {action="SET", key=key, setoptions=setoptions})
end

function class:Update(key: string, func: any)
	assert(not self.__committing, "This transaction is currently committing and cannot be altered.")
	table.insert(self.__actions, {action="UPDATE", key=key, func=func})
end

function class:Remove(key: string, version: string?)
	assert(not self.__committing, "This transaction is currently committing and cannot be altered.")
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
			local keyToUpdate do
				if action.action == "UPDATE" or action.action == "REMOVE" then
					keyToUpdate = action.key
				elseif action.action == "SET" then
					keyToUpdate = action.key.__keyindex
				end
			end
			if action.action == "UPDATE" then
				local snapshotGetSuccess, snapshot, snapshotInfo = pcall(function()
					return datastore:GetAsync(keyToUpdate.."_SNAPSHOT")
				end)
				if snapshotGetSuccess then
					if snapshot and os.time() - snapshotInfo.CreatedTime <= 5 then
						reject("Another transaction is already processing this key.")
					else
						local success, result, keyInfo = pcall(function()
							return datastore:UpdateAsync(keyToUpdate, function(old, oldKeyInfo)
								if old == nil then
									old = {}
									for i, v in pairs(model:GetColumnList()) do
										old[i] = v.Default
									end
								end
								if snapshot then
									old = snapshot
									oldKeyInfo = snapshotInfo
								end
								action.snapshot = {Util.deepcopy(old), oldKeyInfo}
								for name, val in pairs(old) do
									local column = model:GetColumn(name)
									if column then
										old[name] = column:deserialize(val)
									end
								end
								local newData, newUserIds, metaData = action.func(old, oldKeyInfo)

								if newData then
									for name, val in pairs(newData) do
										local column = model:GetColumn(name)
										if column then
											newData[name] = column:serialize(val)
										end
									end
								end

								return newData, newUserIds, metaData
							end)
						end)

						if success then
							table.insert(succeeded, action)
							table.insert(results, {
								Values = result;
								KeyInfo = keyInfo;
							})
						else
							failed = result
							break
						end
					end
				else
					failed = snapshot
				end
			else
				local successGet, resultGet, keyInfoGet = pcall(function()
					return datastore:GetAsync(keyToUpdate)
				end)

				if successGet then
					action.snapshot = {resultGet, keyInfoGet}

					local snapshotSaveSuccess, result = pcall(function()
						local snapshotExists = false
						local snapshotInfo: DataStoreKeyInfo
						datastore:UpdateAsync(keyToUpdate.."_SNAPSHOT", function(old, oldKeyInfo: DataStoreKeyInfo)
							if old then
								snapshotExists = old
								snapshotInfo = oldKeyInfo
								return nil
							end
							return resultGet, keyInfoGet:GetUserIds(), keyInfoGet:GetMetadata()
						end)
						if snapshotExists then
							if os.time() - snapshotInfo.CreatedTime > 5 then
								-- Assume a crash occurred at the time of this snapshot and revert it.
								local setoptions = Instance.new("DataStoreSetOptions")
								setoptions:SetMetadata(snapshotInfo:GetMetadata())
								datastore:SetAsync(keyToUpdate, snapshotExists, snapshotInfo:GetUserIds(), setoptions)
								datastore:RemoveAsync(keyToUpdate.."_SNAPSHOT")
							end
							error("Snapshot already exists, a transaction may have occurred when a server crashed.")
						end
					end)

					if snapshotSaveSuccess then
						if action.action == "SET" then
							local success, version = pcall(function()
								return datastore:SetAsync(keyToUpdate, action.key:serialize(), action.key.UserIds, action.setoptions)
							end)

							if success then
								table.insert(succeeded, action)
								table.insert(results, {
									Version = version;
								})
							else
								failed = version
								break
							end
						elseif action.action == "REMOVE" then
							local success, oldData, oldKeyInfo = pcall(function()
								if action.version then
									return datastore:RemoveVersionAsync(keyToUpdate, action.version)
								else
									return datastore:RemoveAsync(keyToUpdate)
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
								failed = oldData
								break
							end
						end
					else
						failed = result
						break
					end
				else
					failed = resultGet
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
							local keyInfo: DataStoreKeyInfo = action.snapshot[2]
							local setoptions = Instance.new("DataStoreSetOptions")
							setoptions:SetMetadata(keyInfo:GetMetadata())
							datastore:SetAsync(type(action.key) == "string" and action.key or action.key.__keyindex, action.snapshot[1], keyInfo:GetUserIds(), setoptions)
						end
					elseif action.action == "REMOVE" then
						local keyInfo: DataStoreKeyInfo = action.snapshot[2]
						local setoptions = Instance.new("DataStoreSetOptions")
						setoptions:SetMetadata(keyInfo:GetMetadata())
						datastore:SetAsync(action.key, action.snapshot[1], keyInfo:GetUserIds(), setoptions)
					end
					datastore:RemoveAsync((type(action.key) == "string" and action.key or action.key.__keyindex).."_SNAPSHOT")
				end)

				if not success then
					warn(string.format("[DATA-ALCHEMY]: Failed to rollback action '%s' for key '%s': %s", action.action, type(action.key) == "string" and action.key or action.key.__keyindex, result))
				end

				action.snapshot = nil
			end

			self.__committing = false
			reject(string.format("One of the transactions failed and all successful actions had to be rolled back: %s\n%s", tostring(failed), debug.traceback()))
		else
			for _, action in pairs(succeeded) do
				local keyToUpdate do
					if action.action == "UPDATE" or action.action == "REMOVE" then
						keyToUpdate = action.key
					elseif action.action == "SET" then
						keyToUpdate = action.key.__keyindex
					end
				end

				local success, result
				for i = 1, 3 do
					success, result = pcall(function()
						datastore:RemoveAsync(keyToUpdate.."_SNAPSHOT")
					end)
					if success then
						break
					else
						task.wait()
					end
				end

				if not success then
					warn(string.format("Failed to remove snapshot for key '%s' with error: %s", keyToUpdate, result))
				end
			end
			for name, column in pairs(model:GetColumnList()) do
				if column.OnUpdate then
					for i, action in pairs(self.__actions) do
						local key = type(action.key) == "table" and action.key.__keyindex or action.key
						pcall(function()
							column.OnUpdate(key, results[i].Values[name])
						end)
					end
				end
			end

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

function constructor.new(model: table, autoFlush: boolean): {}
	return setmetatable({
		__model = model;
		__actions = {};
		__committing = false;
		__autoflush = autoFlush;
	}, class)
end

return constructor