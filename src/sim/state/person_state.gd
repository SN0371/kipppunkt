class_name PersonState
extends RefCounted
## A person in the party's staff or candidate pool (game-design.md 3.6, rechenmodell.md 10).

## Hidden agendas; "none" for most people.
const AGENDAS: PackedStringArray = ["none", "careerist", "ideologue", "journalist", "informant"]
## Party functions in the MVP; an empty role means the person is in the candidate pool.
const ROLES: PackedStringArray = [
	"", "chair", "general_secretary", "treasurer", "state_chair_south", "state_chair_north",
]

var id: String = ""
var name: String = ""
var role: String = ""
var loyalty: float = 0.0
## Persuasion: how strongly the person moves public opinion.
var persuasion: float = 0.0
## Influence behind the scenes.
var network: float = 0.0
var competence: float = 0.0
## Hidden from the player until revealed.
var agenda: String = "none"
var agenda_revealed: bool = false
## Material collected by an undercover journalist; publishes at 100.
var material: float = 0.0


## Serializes the person to plain JSON-compatible data.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"role": role,
		"loyalty": loyalty,
		"persuasion": persuasion,
		"network": network,
		"competence": competence,
		"agenda": agenda,
		"agenda_revealed": agenda_revealed,
		"material": material,
	}


## Restores a person from data written by to_dict().
static func from_dict(d: Dictionary, reader: JsonReader, ctx: String) -> PersonState:
	var person := PersonState.new()
	person.id = reader.read_string(d, "id", ctx)
	person.name = reader.read_string(d, "name", ctx)
	person.role = reader.read_enum(d, "role", ctx, ROLES)
	person.loyalty = reader.read_float(d, "loyalty", ctx, 0.0, 100.0)
	person.persuasion = reader.read_float(d, "persuasion", ctx, 0.0, 100.0)
	person.network = reader.read_float(d, "network", ctx, 0.0, 100.0)
	person.competence = reader.read_float(d, "competence", ctx, 0.0, 100.0)
	person.agenda = reader.read_enum(d, "agenda", ctx, AGENDAS)
	person.agenda_revealed = reader.read_bool(d, "agenda_revealed", ctx)
	person.material = reader.read_float(d, "material", ctx, 0.0)
	return person
