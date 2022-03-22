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

	self.__committing = true
	return Promise.async(function(resolve, reject)
		local failed = false
		local succeeded = {}
		local results = {}
		for _, action in pairs(self.__actions) do
			-- Determine the key to use based on the type of action
			local keyToUpdate do
				if action.action == "UPDATE" or action.action == "REMOVE" then
					keyToUpdate = action.key
				elseif action.action == "SET" then
					keyToUpdate = action.key.__keyindex
				end
			end
			if action.action == "UPDATE" then
				-- Check if there is a snapshot of the key, potentially left behind by a previous failed transaction
				local snapshotGetSuccess, snapshot, snapshotInfo = pcall(function()
					return datastore:GetAsync(keyToUpdate.."_SNAPSHOT")
				end)
				-- If there was no datastore error, continue
				if snapshotGetSuccess then
					-- Check how old the snapshot is, if it exists
					if snapshot and os.time() - snapshotInfo.CreatedTime <= 5 then
						-- If there was a snapshot and it isn't older than 5 seconds, reject the transaction
						reject("Another transaction is already processing this key.")
					else
						local success, result, keyInfo = pcall(function()
							return datastore:UpdateAsync(keyToUpdate, function(old, oldKeyInfo)
								-- Autofill in default values if the old value is nil
								if old == nil then
									old = {}
									for i, v in pairs(model:GetColumnList()) do
										old[i] = v.Default
									end
								end
								-- If the snapshot exists, replace the old value with the snapshot
								if snapshot then
									old = snapshot
									oldKeyInfo = snapshotInfo
								end
								-- Create a deep copy of the old value for the action's snapshot in case a rollback is needed
								action.snapshot = {Util.deepcopy(old), oldKeyInfo}
								-- Loop through the old value's columns and deserialize the values
								for name, val in pairs(old) do
									local column = model:GetColumn(name)
									if column then
										old[name] = column:deserialize(val)
									end
								end

								-- Call the update function
								local newData, newUserIds, metaData = action.func(old, oldKeyInfo)

								-- Finally, serialize the new values
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
							-- Insert the result into the results table & the succeeded table
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
				-- Attempt to get the key
				local successGet, resultGet, keyInfoGet = pcall(function()
					return datastore:GetAsync(keyToUpdate)
				end)

				if successGet then
					-- If it succeededm capture a snapshot of its current state
					action.snapshot = {resultGet, keyInfoGet}

					-- Attempt to save the snapshot
					local snapshotSaveSuccess, result = pcall(function()
						local snapshotExists = false
						local snapshotInfo: DataStoreKeyInfo
						datastore:UpdateAsync(keyToUpdate.."_SNAPSHOT", function(old, oldKeyInfo: DataStoreKeyInfo)
							if old then
								-- If an old snapshot already exists, tell the rest of the code about it and prevent overwriting it
								snapshotExists = old
								snapshotInfo = oldKeyInfo
								return nil
							end
							return resultGet, keyInfoGet:GetUserIds(), keyInfoGet:GetMetadata()
						end)
						if snapshotExists then
							-- If we know that a snapshot already exists, check how old it is
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
						-- If the snapshot succeeded, we can continue
						if action.action == "SET" then
							-- Attempt to set the key
							local success, version = pcall(function()
								return datastore:SetAsync(keyToUpdate, action.key:serialize(), action.key.UserIds, action.setoptions)
							end)

							if success then
								-- Insert the result into the results table & the succeeded table
								table.insert(succeeded, action)
								table.insert(results, {
									Version = version;
								})
							else
								failed = version
								break
							end
						elseif action.action == "REMOVE" then
							-- Attempt to remove the key
							local success, oldData, oldKeyInfo = pcall(function()
								if action.version then
									return datastore:RemoveVersionAsync(keyToUpdate, action.version)
								else
									return datastore:RemoveAsync(keyToUpdate)
								end
							end)

							if success then
								-- Insert the result into the results table & the succeeded table
								table.insert(succeeded, action)

								if oldData and oldKeyInfo then
									-- Old data needs to be deserialized first before being inserted into the results table
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
									-- If there was no old data, insert an empty table
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
			-- Something caused the transaction to fail, rollback the transaction
			for _, action in pairs(succeeded) do
				local success, result = pcall(function()
					if action.action == "SET" or action.action == "UPDATE" then
						if action.snapshot == nil then
							-- Start by removing the set key if it didn't exist before the transaction
							datastore:RemoveAsync(type(action.key) == "string" and action.key or action.key.__keyindex)
						else
							-- If the key existed before the transaction, restore it
							local keyInfo: DataStoreKeyInfo = action.snapshot[2]
							local setoptions = Instance.new("DataStoreSetOptions")
							setoptions:SetMetadata(keyInfo:GetMetadata())
							datastore:SetAsync(type(action.key) == "string" and action.key or action.key.__keyindex, action.snapshot[1], keyInfo:GetUserIds(), setoptions)
						end
					elseif action.action == "REMOVE" then
						-- Bring back the old data if it existed before the transaction
						local keyInfo: DataStoreKeyInfo = action.snapshot[2]
						local setoptions = Instance.new("DataStoreSetOptions")
						setoptions:SetMetadata(keyInfo:GetMetadata())
						datastore:SetAsync(action.key, action.snapshot[1], keyInfo:GetUserIds(), setoptions)
					end
					-- Finally, remove the snapshot
					datastore:RemoveAsync((type(action.key) == "string" and action.key or action.key.__keyindex).."_SNAPSHOT")
				end)

				if not success then
					-- Somehow the rollback failed, log it and leave it to the system to automatically catch this failed rollback next time the keys are worked on by a transaction
					warn(string.format("[DATA-ALCHEMY]: Failed to rollback action '%s' for key '%s': %s", action.action, type(action.key) == "string" and action.key or action.key.__keyindex, result))
				end

				-- Erase the snapshot from the action in case the transaction is reused later
				action.snapshot = nil
			end

			-- Indicate that the transaction is no longer committing and return the error
			self.__committing = false
			reject(string.format("One of the transactions failed and all successful actions had to be rolled back: %s\n%s", tostring(failed), debug.traceback()))
		else
			-- There was no failure, we can continue with cleanup and resolve the transaction
			for _, action in pairs(succeeded) do
				-- Determine the key to update based on the type of action
				local keyToUpdate do
					if action.action == "UPDATE" or action.action == "REMOVE" then
						keyToUpdate = action.key
					elseif action.action == "SET" then
						keyToUpdate = action.key.__keyindex
					end
				end

				-- Make 3 attempts to remove the snapshot
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
					-- We failed to remove the snapshot for some reason, log it and hope the system doesn't unintentionally revert the changes the next time the keys are worked on by a transaction
					warn(string.format("Failed to remove snapshot for key '%s' with error: %s", keyToUpdate, result))
				end
			end
			-- Loop through the column list and execute the OnUpdate callbacks for them
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

			-- Automatically clean up all the actions in the transaction if it is set to do so
			if self.__autoflush then
				self:Flush()
			end

			-- Finally, resolve the transaction and indicate that it is no longer committing
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