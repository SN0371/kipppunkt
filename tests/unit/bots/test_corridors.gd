extends GutTest
## Tests the measurable balancing corridors with synthetic game results.


func test_patient_needs_a_majority_by_turn_forty() -> void:
	var rows := _rows(6, {"outcome": "won", "bundestag_turn": 40})
	rows.append_array(_rows(4, {"outcome": "won", "bundestag_turn": 56}))
	assert_true(Corridors.check("patient", rows)["passed"])
	rows = _rows(5, {"outcome": "won", "bundestag_turn": 24})
	rows.append_array(_rows(5, {"outcome": "timeout"}))
	assert_false(Corridors.check("patient", rows)["passed"], "Exactly half is not a majority")


func test_radical_needs_early_wins_and_suspicion() -> void:
	var rows := _rows(5, {"outcome": "won", "bundestag_turn": 24, "suspected_turn": 14})
	rows.append_array(_rows(5, {"outcome": "timeout"}))
	assert_true(Corridors.check("radical", rows)["passed"])
	rows = _rows(10, {"outcome": "won", "bundestag_turn": 24})
	assert_false(Corridors.check("radical", rows)["passed"], "Never suspected")
	rows = _rows(10, {"outcome": "won", "bundestag_turn": 40, "suspected_turn": 14})
	assert_false(Corridors.check("radical", rows)["passed"], "Too slow")


func test_suspicion_after_entering_bundestag_does_not_count() -> void:
	var rows := _rows(10, {"outcome": "won", "bundestag_turn": 24, "suspected_turn": 30})
	assert_false(Corridors.check("radical", rows)["passed"])


func test_two_faced_needs_exposure_six_to_ten_turns_after_first_message() -> void:
	var rows := _rows(6, {"first_message_turn": 1, "first_exposure_turn": 8})
	rows.append_array(_rows(4, {"first_message_turn": 1, "first_exposure_turn": 3}))
	assert_true(Corridors.check("two_faced", rows)["passed"])
	rows = _rows(10, {"first_message_turn": 1})
	assert_false(Corridors.check("two_faced", rows)["passed"], "Never exposed")


func test_passive_and_random() -> void:
	assert_true(Corridors.check("passive", _rows(6, {"outcome": "irrelevant"}) + _rows(4, {"outcome": "timeout"}))["passed"])
	assert_false(Corridors.check("passive", _rows(10, {"outcome": "timeout"}))["passed"])
	assert_true(Corridors.check("random", _rows(1, {"outcome": "won"}) + _rows(9, {"outcome": "split"}))["passed"])
	assert_false(Corridors.check("random", _rows(2, {"outcome": "won"}) + _rows(8, {"outcome": "split"}))["passed"])


func test_no_games_fail() -> void:
	assert_false(Corridors.check("patient", [] as Array[Dictionary])["passed"])


## Returns count identical rows with defaults for every metric, overridden by values.
func _rows(count: int, values: Dictionary) -> Array[Dictionary]:
	var row := {
		"outcome": "timeout", "bundestag_turn": GameMetrics.NEVER, "suspected_turn": GameMetrics.NEVER,
		"first_message_turn": GameMetrics.NEVER, "first_exposure_turn": GameMetrics.NEVER,
	}
	row.merge(values, true)
	var rows: Array[Dictionary] = []
	for i in count:
		rows.append(row.duplicate())
	return rows
