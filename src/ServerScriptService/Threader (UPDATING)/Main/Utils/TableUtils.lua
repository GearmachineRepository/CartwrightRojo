--!strict
local TableUtils = {}

function TableUtils.DeepCopy(Table: any): any
	if type(Table) ~= "table" then
		return Table
	end

	local Copy = {}
	for Key, Value in pairs(Table) do
		if type(Value) == "table" then
			Copy[Key] = TableUtils.DeepCopy(Value)
		else
			Copy[Key] = Value
		end
	end

	return Copy
end

function TableUtils.Merge(Target: {[any]: any}, Source: {[any]: any}): {[any]: any}
	for Key, Value in pairs(Source) do
		if type(Value) == "table" and type(Target[Key]) == "table" then
			TableUtils.Merge(Target[Key], Value)
		else
			Target[Key] = Value
		end
	end

	return Target
end

function TableUtils.Compare(A: any, B: any): boolean
	if type(A) ~= type(B) then
		return false
	end

	if type(A) ~= "table" then
		return A == B
	end

	for Key, Value in pairs(A) do
		if not TableUtils.Compare(Value, B[Key]) then
			return false
		end
	end

	for Key in pairs(B) do
		if A[Key] == nil then
			return false
		end
	end

	return true
end

function TableUtils.FindIndex(Table: {any}, Predicate: (any) -> boolean): number?
	for Index, Value in ipairs(Table) do
		if Predicate(Value) then
			return Index
		end
	end
	return nil
end

function TableUtils.Filter(Table: {any}, Predicate: (any) -> boolean): {any}
	local Result = {}
	for _, Value in ipairs(Table) do
		if Predicate(Value) then
			table.insert(Result, Value)
		end
	end
	return Result
end

function TableUtils.Map(Table: {any}, Transform: (any) -> any): {any}
	local Result = {}
	for Index, Value in ipairs(Table) do
		Result[Index] = Transform(Value)
	end
	return Result
end

function TableUtils.Contains(Table: {any}, Item: any): boolean
	for _, Value in ipairs(Table) do
		if Value == Item then
			return true
		end
	end
	return false
end

function TableUtils.RemoveValue(Table: {any}, Item: any): boolean
	for Index, Value in ipairs(Table) do
		if Value == Item then
			table.remove(Table, Index)
			return true
		end
	end
	return false
end

return TableUtils