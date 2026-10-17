extends GutTest
## Tests for media tone, reach, climate and dynamics (rechenmodell.md 5.6).

var _defs: GameDefs
var _state: GameState


func before_each() -> void:
	_defs = SimFixture.defs()
	_state = SimFixture.new_state()


func test_newsroom_judges_a_moderate_start_party_mildly_positive() -> void:
	# 0.3 + 0 - 10/80 - 0
	assert_almost_eq(MediaSystem.newsroom_judgement(_state.party), 0.175, 0.00001)


func test_newsroom_judgement_is_clamped() -> void:
	_state.party.credibility = 30.0
	_state.party.radicalism = 80.0
	_state.party.vs_level = 2
	assert_eq(MediaSystem.newsroom_judgement(_state.party), -1.0)


func test_owner_sympathy_depends_on_distance() -> void:
	var def := _defs.media["media.tabloid"]
	var house := _state.media["media.tabloid"]
	house.owner_ideology = Vector2(25, 0)
	assert_almost_eq(MediaSystem.owner_sympathy(_defs, def, house, Vector2.ZERO), 0.5, 0.00001)
	assert_eq(MediaSystem.owner_sympathy(_defs, def, house, Vector2(-100, 0)), -1.0)


func test_tone_mixes_owner_and_newsroom_by_independence() -> void:
	_state.media["media.tabloid"].owner_ideology = Vector2(25, 0)
	var tones := MediaSystem.tones(_state, _defs, Vector2.ZERO)
	# Independence 30: 0.7 * 0.5 + 0.3 * 0.175
	assert_almost_eq(tones["media.tabloid"], 0.4025, 0.00001)


func test_boards_sit_close_to_the_centre() -> void:
	var boards := MediaSystem.board_ideology(_defs)
	assert_true(boards.length() < 35.0 / 3.0 + 0.001, "At most a third of a rival's distance")


func test_attention_grows_with_polling() -> void:
	assert_eq(MediaSystem.attention(5.0), 0.5)
	assert_eq(MediaSystem.attention(20.0), 1.0)


func test_classic_reach_counts_national_and_regional_houses() -> void:
	# Bavaria: tabloid 35 + quality 15 + public 35 + regional south 30 = 115, times attention 0.5.
	assert_almost_eq(MediaSystem.classic_reach(_state, _defs, "land.by", 0.5), 57.5, 0.00001)
	# Berlin has no regional house: 85 * 0.5.
	assert_almost_eq(MediaSystem.classic_reach(_state, _defs, "land.be", 0.5), 42.5, 0.00001)


func test_classic_reach_includes_bonus_and_is_capped() -> void:
	_state.party.reach_classic_bonus = 50.0
	assert_eq(MediaSystem.classic_reach(_state, _defs, "land.by", 1.0), 100.0)


func test_climate_is_weighted_by_reach_and_credibility() -> void:
	var tones: Dictionary[String, float] = {}
	for media_id: String in _defs.media:
		tones[media_id] = 0.0
	tones["media.public"] = 1.0
	var influence_public := 35.0 * MediaSystem.target_credibility(85.0)
	var influence_total := influence_public
	for media_id in ["media.tabloid", "media.quality"]:
		influence_total += _state.media[media_id].reach * _state.media[media_id].credibility
	assert_almost_eq(MediaSystem.climate(_state, _defs, "land.be", tones), influence_public / influence_total, 0.00001)


func test_base_and_target_reach() -> void:
	var def := _defs.media["media.tabloid"]
	# 35 - 15 * (1 - 0.3)
	assert_almost_eq(MediaSystem.base_reach(_defs, def), 24.5, 0.00001)
	assert_almost_eq(MediaSystem.target_reach(_defs, def, _state.media["media.tabloid"]), 35.0, 0.00001)


func test_public_broadcasting_keeps_its_independence() -> void:
	_state.party.radicalism = 90.0
	_state.party.vs_level = 3
	for i in 200:
		MediaSystem.step(_state, _defs, Vector2.ZERO)
	assert_eq(_state.media["media.public"].independence, 85.0)


func test_polarizing_party_erodes_independence_of_owned_houses() -> void:
	_state.party.radicalism = 90.0
	_state.party.vs_level = 3
	_state.media["media.tabloid"].owner_ideology = Vector2.ZERO
	var before := _state.media["media.tabloid"].independence
	for i in 200:
		MediaSystem.step(_state, _defs, Vector2.ZERO)
	assert_lt(_state.media["media.tabloid"].independence, before)
	assert_true(SimLog.find(_state, "media_conflict").size() > 0, "Conflicts are logged")
