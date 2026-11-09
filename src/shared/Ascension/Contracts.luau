--!strict
-- Contracts describe network payloads, never client authority over damage or rewards.
export type Aim = { x: number, y: number, z: number }
export type ActionRequest = {
	version: number,
	session: string,
	seq: number,
	action: string,
	aim: Aim?,
	item: string?,
	target: number?,
	enabled: boolean?,
}
export type AttackDefinition = {
	Id: string,
	Animation: string,
	Windup: number,
	Active: number,
	Recovery: number,
	Duration: number,
	Multiplier: number,
	FocusCost: number,
	StaminaCost: number,
	Sweep: string,
	Impact: string,
	CancelAfter: number,
	Markers: { [string]: number },
}
export type CombatEvent = {
	version: number,
	encounter: string,
	attack: number?,
	result: string,
	position: Vector3,
	material: string,
	timestamp: number,
	seed: number,
	actor: number?,
	sequence: number?,
	pattern: string?,
	ends: number?,
	damage: number?,
}
export type AssetRecord = {
	Source: string,
	Kind: string,
	Rights: string,
	CommercialUse: boolean,
	Attribution: string,
	LicenseVerified: boolean,
	SHA256: string,
	Owner: string,
	RobloxId: number,
	Status: string,
	Required: boolean,
	EngineEvidence: string,
}
return table.freeze({ Requests = 2, CombatEvents = 1, Attacks = 2, Profiles = 3 })
