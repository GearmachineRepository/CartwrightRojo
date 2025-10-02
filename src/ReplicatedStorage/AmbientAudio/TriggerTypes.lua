--!strict

export type SoundData = {
	Sound: Sound,
	TargetVolume: number,
	CurrentVolume: number,
	Position: Vector3,
	SoundType: string,
	SourceObject: BasePart?,
	IsLooped: boolean,
	SoundContainer: BasePart?,
	Attachment: Attachment?,
	IsDynamic: boolean,
	_vel: Vector3?,
	_deathTime: number?,
}

export type TriggerZone = {
	Part: BasePart,
	SoundType: string,
	EmitterMode: string,     -- "CenterLine" | "NearestPoint" | "Center"
	EmitterKind: string,     -- "Loop" | "LocalGusts" | "BurstField"
	EnterRadius: number,
	ExitRadius: number,
	FadeDistance: number,
	Volume: number,
	ChannelId: string?,
	RodT: number?,
	LastRodUpdate: number,
	State: "OUT" | "IN" | "LEAVING",
	ActiveSound: SoundData?,
	_exitTimer: number,
	_gusts: {SoundData}?,
	_gustAcc: number?,
	_burst: {acc: number, actives: {SoundData}}?,
}

export type ChannelState = {
	ActiveSound: SoundData?,
	CurrentZone: TriggerZone?,
	TargetPos: Vector3?,
	Vel: Vector3?,
	LastWinnerChange: number?,
}

export type WinnerInfo = {
	Zone: TriggerZone,
	Distance: number,
}

return {}