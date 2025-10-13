--!strict
local HistoryManager = {}

export type Command = {
	Name: string,
	Execute: () -> (),
	Undo: () -> (),
	Data: any?
}

local History: {Command} = {}
local CurrentIndex = 0
local MaxHistory = 50

function HistoryManager.RecordChange(Name: string, ExecuteFunc: () -> (), UndoFunc: () -> (), Data: any?)
	local Command: Command = {
		Name = Name,
		Execute = ExecuteFunc,
		Undo = UndoFunc,
		Data = Data
	}

	if CurrentIndex < #History then
		for Index = #History, CurrentIndex + 1, -1 do
			table.remove(History, Index)
		end
	end

	table.insert(History, Command)
	CurrentIndex = #History

	if #History > MaxHistory then
		table.remove(History, 1)
		CurrentIndex = CurrentIndex - 1
	end

	ExecuteFunc()
end

function HistoryManager.Undo()
	if not HistoryManager.CanUndo() then
		return
	end

	local Command = History[CurrentIndex]
	Command.Undo()
	CurrentIndex = CurrentIndex - 1
end

function HistoryManager.Redo()
	if not HistoryManager.CanRedo() then
		return
	end

	CurrentIndex = CurrentIndex + 1
	local Command = History[CurrentIndex]
	Command.Execute()
end

function HistoryManager.CanUndo(): boolean
	return CurrentIndex > 0
end

function HistoryManager.CanRedo(): boolean
	return CurrentIndex < #History
end

function HistoryManager.Clear()
	History = {}
	CurrentIndex = 0
end

function HistoryManager.GetHistory(): {Command}
	return History
end

function HistoryManager.GetCurrentIndex(): number
	return CurrentIndex
end

return HistoryManager