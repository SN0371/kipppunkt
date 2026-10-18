class_name TurnRunner
extends RefCounted
## Runs a turn in the order of rechenmodell.md section 2.
##
## A turn has two halves so the player can plan in between: start_turn() books income
## and the situation, then the player (or a bot) gives orders, then finish_turn()
## resolves everything else. Saving in between is allowed.


## Steps 1 and 2: income, crises, events and a new candidate pool. Afterwards the turn waits
## for the response to a pending event (EventSystem.resolve) and for orders.
static func start_turn(state: GameState, defs: GameDefs) -> void:
	assert(not state.awaiting_orders, "The turn has already started")
	assert(not state.is_over(), "The game is over")
	SimLog.add(state, "turn_started")
	EconomySystem.income(state, defs)
	CrisisSystem.step(state, defs)
	EventSystem.step(state, defs)
	PersonSystem.refresh_pool(state)
	state.awaiting_orders = true


## Steps 4 to 10: actions, counter-forces, opinion, donors, elections, decay, phase and end.
static func finish_turn(state: GameState, defs: GameDefs, orders: Array[ActionOrder]) -> void:
	assert(state.awaiting_orders, "start_turn() must be called first")
	if not state.pending_event_id.is_empty():
		# An unanswered event counts as silence (or keeping the position).
		EventSystem.resolve(state, defs, null)
	ActionResolver.resolve(state, defs, orders)
	PersonSystem.turn_effects(state, defs)
	SurveillanceSystem.step(state, defs)
	PressSystem.step(state, defs)
	PollingSystem.step(state, defs)
	DonorSystem.step(state, defs, IdeologySystem.profile(state.party, defs))
	ElectionSystem.step(state, defs)
	EconomySystem.decay(state, defs, PollingSystem.salience(state, defs))
	ModifierSystem.tick(state)
	PhaseSystem.step(state, defs)
	state.awaiting_orders = false
	if not state.is_over():
		state.turn += 1


## Plays a whole turn with the given orders; convenience for bots and tests.
static func play_turn(state: GameState, defs: GameDefs, orders: Array[ActionOrder]) -> void:
	start_turn(state, defs)
	finish_turn(state, defs, orders)
