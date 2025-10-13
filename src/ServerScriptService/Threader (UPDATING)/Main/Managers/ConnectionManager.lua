--!strict
local ConnectionManager = {}

export type ConnectionGroup = {
	Add: (self: ConnectionGroup, Connection: RBXScriptConnection) -> (),
	Cleanup: (self: ConnectionGroup) -> (),
	IsEmpty: (self: ConnectionGroup) -> boolean
}

type ConnectionGroupImpl = ConnectionGroup & {
	Connections: {RBXScriptConnection}
}

function ConnectionManager.Create(): ConnectionGroup
	local Group: ConnectionGroupImpl = {
		Connections = {}
	} :: any

	function Group:Add(Connection: RBXScriptConnection)
		table.insert(self.Connections, Connection)
	end

	function Group:Cleanup()
		for _, Connection in ipairs(self.Connections) do
			if Connection.Connected then
				Connection:Disconnect()
			end
		end
		self.Connections = {}
	end

	function Group:IsEmpty(): boolean
		return #self.Connections == 0
	end

	return Group
end

return ConnectionManager