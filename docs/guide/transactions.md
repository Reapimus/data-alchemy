In Data Alchemy, We make use of something known as a `Transaction`, which allows us to perform either one datastore operation or multiple at once, with the guarantee that it will only apply all of the changes if they all succeed.

!!! info
    Curious and want to learn more about how a database transaction works? Check out this [wikipedia page](https://en.wikipedia.org/wiki/Database_transaction) on the subject!

## Creating a Transaction

In order to create a transaction, we must call `NewTransaction` on our `Model` instance like so:

```lua
local transaction = OurModel:NewTransaction()
```

After we have created our `Transaction`, we can then start adding actions to the transaction that will be performed once we're done. There are only 3 actions that a Transaction can perform, and these are: Set, Update, and Remove.

## Adding Actions to a Transaction

In our `Transaction` class we have 3 functions for adding different types of actions to our transaction, which will be detailed here.

### Set

The `Set` method of a transaction will add an action to perform a `SetAsync` operation, the `key` argument should be a `Key` instance created using `Model:NewKey(index)` like so:

```lua
local transaction = OurModel:NewTransaction()

local key = OurModel:NewKey("SomePlayersUserId")
key.Avatar = 123456789

transaction:Set(key)
```

### Update

The `Update` method of a transaction will add an action to perform an `UpdateAsync` operation, the `index` argument must be a string representing the key you wish to update and the `updateFunc` argument must be a function that, given the key's current data and keyinfo, returns updated data and keyinfo like so:

```lua
local transaction = OurModel:NewTransaction()

local function updateKey(oldData, oldKeyInfo)
    oldData.Name = "Kamijou Touma"
    return oldData, oldKeyInfo
end

transaction:Update("SomePlayersUserId", updateKey)
```

### Remove

The `Remove` method of a transaction will add an action to perform a `RemoveAsync` operation, the `index` argument must be a string representing the key you wish to remove and has an optional `version` argument for specifying which version of the key to remove, if not specified it will remove the entire key, it can be used like so:

```lua
local transaction = OurModel:NewTransaction()

transaction:Remove("SomePlayersUserId")
```

## Committing a Transaction

Once you've specified all the actions you wish to commit to the datastore for your transaction, you must then called the `Commit` method of the transaction like so:

```lua
local transaction = OurModel:NewTransaction()

local function updateKey(oldData, oldKeyInfo)
    oldData.Name = "Kamijou Touma"
    return oldData, oldKeyInfo
end

transaction:Update("SomePlayersUserId", updateKey)

transaction:Commit()
    :andThen(function(results)
        transaction:Flush()
        print("Transaction was a success! Results:", results)
    end)
```

It should also be noted that the function will return the results of each action, in the order in which the actions were added to the transaction. Once you're done with the transaction, you should call the `Flush` method of the transaction if you wish to reuse that instance for more transactions.

!!! info
    Don't feel like creating a `Transaction` instance but know for certain that nothing will be trying to perform actions on the datastore at the same time? You can use the transaction in the model called `Session` (`OurModel.Session`) to add actions and then when committing them, it will immediately be flushed automatically once successful.

!!! info
    For more information on the results of committing a `Transaction`, checkout the [API Reference](../../api-reference#transactioncommit) for what the results of an action may look like.