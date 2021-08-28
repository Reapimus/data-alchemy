## Classes

### Model

---

```lua
DataAlchemy.Model.new(datastoreName, [datastoreScope]) -> Model
```

A class that is the primary instance used in Data-Alchemy, it represents the structure that a datastore's contents should assume and enforces it.

---

#### Model[index] = column

```lua
Model[index] = Column
```

Sets the specified index in the model to a Column class which is used to represent what should be in that index in the structure of a key.

---

#### Model:GetColumn

```lua
Model:GetColumn(name) -> Column | nil
```

Returns the Column at the specified index if it exists.

---

#### Model:GetColumnList

```lua
Model:GetColumnList() -> Array<Column>
```

Returns all the Column instances in the model with their indexes being identical to their indexes in the model.

---

#### Model:NewKey

```lua
Model:NewKey(index) -> Key
```

Creates a new Key instance for this model with the specified index, which refers to the key it would represent in the datastore.

---

#### Model:NewTransaction

```lua
Model:NewTransaction()
```

Creates a new Transaction instance for this datastore which can be used to perform multiple datastore interactions at once with the guarantee that it will only succeed if all the actions succeed.

---

#### Model.Query

A Query instance for this model that allows you to perform queries on the datastore to get specified keys or list keys based on specifications.

---

#### Model.Session

A Transaction instance for this model that will automatically flush the transaction as soon as the actions have been committed.

---

### Column

```lua
DataAlchemy.Column.new(type_, [default]) -> Column
```

A class that represents how an index in the key structure should be treated.

!!! info
	The only functions this class has are intended for internal use only.

---

### Key

A class that represents a key in the datastore.

!!! warning
	This class is not intended to be created manually outside of internal functions that do so, anything that occurs as a result of creating one outside of an internal function will not be fixed.

---

#### Key.UserIds

An array of the UserIds associated with this key.

---

#### Key.Version

The version of this key.

---

#### Key.CreatedTime

The time this key was created at.

---

#### Key.UpdatedTime

The time this key was last updated.

---

#### Key:GetMetadata

```lua
Key:GetMetadata() -> Dictionary<any>
```

Gets the metadata associated with this key.

---

### Query

```lua
Model.Query -> Query
```

An object that can perform queries on a Model's datastore.

---

#### Query:FilterByKey

```lua
Query:FilterByKey(name, [version]) -> Key
```

Queries the datastore for a specified key, with an optional version of the key to query for.

---

#### Query:FilterByPrefix

```lua
Query:FilterByPrefix([prefix, [pageSize]]) -> QueryResult
```

Queries the datastore for keys that start with the specified prefix or blank if not specified and returns a `QueryResult` instance that can be used to go through the results.

---

#### Query:FilterByKeyVersion

```lua
Query:FilterByKeyVersion(key, [sortDirection, [minDate, [maxDate, [pageSize]]]]) -> QueryResult
```

Queries the datastore for versions of the specified key, within the specified minimum and maximum date ranges or no date range if not specified and a sort direction if specified. Returns a `QueryResult` instance.

---

### QueryResult

An instance that is returned by some `Query` methods to search through the results of the query.

---

#### QueryResult:GetCurrent

```lua
QueryResult:GetCurrent() -> Promise
```

Returns a promise which returns an array of `QueryKey` instances that represent keys in the query upon success.

---

#### QueryResult:GetNext

```lua
QueryResult:GetNext() -> Promise
```

Attempts to advance to the next page of the query and then returns the results of `QueryResult:GetCurrent()`

---

### QueryKey

An instance that provides information about a key returned from a `QueryResult`

---

#### QueryKey.Name

The name of the key in the datastore.

---

#### QueryKey.CreatedTime

The time at which this key was created.

---

#### QueryKey.IsDeleted

Whether or not this key was removed.

---

#### QueryKey.Version

The version of this key.

!!! caution
	`Name` is the only property filled in if this `QueryKey` was generated from a `QueryResult` resulting from `Query:FilterByPrefix`

---

### Transaction

An instance that handles multiple atomic interactions with a datastore, guaranteeing that all interactions are successful or none go through.

---

### Transaction:Set

```lua
Transaction:Set(key)
```

Creates an action in this transaction for a key in the datastore to be set using `SetAsync`

`Key` must be a `Key` instance.

---

### Transaction:Update

```lua
Transaction:Update(index, updateFunc)
```

Creates an action in this transaction for `UpdateAsync` to be used on the specified key index in the datastore.

`index` must be a string

---

### Transaction:Remove

```lua
Transaction:Remove(index, [version])
```

Creates an action in this transaction for a key to be removed from the datastore using `RemoveAsync`, or `RemoveVersionAsync` if a version is specified.

`Index` must be a string

---

### Transaction:Commit

```lua
Transaction:Commit() -> Promise
```

Commits all changes to the datastore, and if successful, the Promise will return an Array containing Dictionaries with the results of each action, in the order they were added to the transaction.

The contents of the dictionary depend on the type of action:

```lua
SET = {
	Version;
}

REMOVE = {
	Values;
	KeyInfo;
}

UPDATE = {
	Values;
	KeyInfo;
}
```

---

### Transaction:Flush

```lua
Transaction:Flush()
```

Clears the transaction of all actions that had been assigned within it.