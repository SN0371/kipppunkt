extends GutTest
## Tests for donors (rechenmodell.md section 5.4).

var _defs: GameDefs
var _state: GameState


func before_each() -> void:
	_defs = SimFixture.defs()
	_state = SimFixture.new_state()


func test_surveillance_penalty_by_kind() -> void:
	assert_eq(DonorSystem.surveillance_penalty("stock", 0), 0.0)
	assert_eq(DonorSystem.surveillance_penalty("stock", 1), 20.0)
	assert_eq(DonorSystem.surveillance_penalty("stock", 3), 60.0)
	assert_eq(DonorSystem.surveillance_penalty("family", 1), 0.0, "Family businesses react later")
	assert_eq(DonorSystem.surveillance_penalty("family", 2), 15.0)
	assert_eq(DonorSystem.surveillance_penalty("midsize", 1), 15.0)


func test_topic_support_rewards_matching_and_punishes_opposite_positions() -> void:
	var supplier := _defs.donors["donor.auto_supplier"]
	assert_eq(DonorSystem.topic_support(supplier, _state.party), 0.0, "No positions, no support")
	_state.party.positions["topic.taxes"] = 2
	_state.party.positions["topic.combustion_ban"] = -2
	assert_eq(DonorSystem.topic_support(supplier, _state.party), 2.0, "Full agreement on both topics")
	_state.party.positions["topic.combustion_ban"] = 2
	assert_eq(DonorSystem.topic_support(supplier, _state.party), 0.0, "+1 and -1 cancel out")
	_state.party.positions["topic.wind_power"] = 2
	assert_eq(DonorSystem.topic_support(supplier, _state.party), 0.0, "Other topics do not count")


func test_party_without_positions_leaves_donors_neutral() -> void:
	var target := DonorSystem.target_satisfaction(_state, _defs, "donor.auto_supplier", Vector2.ZERO)
	assert_eq(target, 35.0, "Below the payment threshold, above the withdrawal threshold")
	assert_lt(target, DonorSystem.PAYMENT_THRESHOLD)
	assert_gt(target, DonorSystem.WITHDRAWAL_THRESHOLD)


func test_matching_positions_and_ideology_give_full_satisfaction() -> void:
	_state.party.positions["topic.taxes"] = 2
	_state.party.positions["topic.combustion_ban"] = -2
	# 35 + 25 * 2 + 15 * (1 - 0)
	var target := DonorSystem.target_satisfaction(_state, _defs, "donor.auto_supplier", Vector2(40, 20))
	assert_almost_eq(target, 100.0, 0.0001)


func test_opposite_positions_drive_donors_away() -> void:
	_state.party.positions["topic.taxes"] = -2
	_state.party.positions["topic.combustion_ban"] = 2
	# 35 - 25 * 2 + 15 * (1 - 2 * 1)
	var target := DonorSystem.target_satisfaction(_state, _defs, "donor.auto_supplier", Vector2(-100, -100))
	assert_almost_eq(target, -30.0, 0.0001)


func test_payment_scales_with_satisfaction_and_credibility() -> void:
	var donor := _state.donors["donor.auto_supplier"]
	donor.satisfaction = 100.0
	_state.party.credibility = 100.0
	assert_almost_eq(DonorSystem.payment(_state, _defs, "donor.auto_supplier"), 15.0, 0.0001)
	_state.party.credibility = 0.0
	assert_almost_eq(DonorSystem.payment(_state, _defs, "donor.auto_supplier"), 7.5, 0.0001)
	donor.satisfaction = 40.0
	assert_eq(DonorSystem.payment(_state, _defs, "donor.auto_supplier"), 0.0)


func test_inactive_donor_pays_nothing() -> void:
	var donor := _state.donors["donor.auto_supplier"]
	donor.satisfaction = 100.0
	donor.active = false
	assert_eq(DonorSystem.payment(_state, _defs, "donor.auto_supplier"), 0.0)


func test_unhappy_donor_withdraws_and_returns_with_half_payment() -> void:
	var donor := _state.donors["donor.wind_energy"]
	donor.satisfaction = 0.0
	_state.party.vs_level = 3
	DonorSystem.step(_state, _defs, Vector2(100, 100))
	DonorSystem.step(_state, _defs, Vector2(100, 100))
	assert_false(donor.active, "Withdrew after two turns below 30")
	_state.party.vs_level = 0
	_state.party.positions["topic.wind_power"] = 2
	for i in DonorSystem.RETURN_DELAY_TURNS + 10:
		_state.turn += 1
		DonorSystem.step(_state, _defs, Vector2(0, -30))
	assert_true(donor.active, "Returned once satisfied again")
	assert_almost_eq(donor.max_payment, 6.0, 0.0001)
