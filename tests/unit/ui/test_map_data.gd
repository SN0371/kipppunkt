extends GutTest
## Tests the generated map data.

var _map: MapData


func before_all() -> void:
	_map = MapData.load_default()


func test_map_has_all_lands_and_places() -> void:
	assert_not_null(_map)
	assert_eq(_map.lands.keys().size(), 16)
	for land_id: String in SimFixture.defs().lands:
		assert_true(_map.lands.has(land_id), land_id)
	for place_id in ["institution.bundestag", "media.public"]:
		assert_true(_map.places.has(place_id), place_id)


func test_cities_lie_in_the_right_lands() -> void:
	assert_eq(_map.land_at(_map.places["institution.bundestag"]), "land.be", "Berlin, not Brandenburg")
	assert_eq(_map.land_at(_map.places["institution.constitutional_court"]), "land.bw")
	assert_eq(_map.land_at(_map.places["media.regional_south"]), "land.by")
	assert_eq(_map.land_at(_map.places["institution.domestic_intelligence"]), "land.nw")


func test_city_states_are_hit_before_surrounding_lands() -> void:
	assert_eq(_map.lands_by_area[0], "land.hb", "Bremen is the smallest land")
	assert_lt(_map.lands_by_area.find("land.be"), _map.lands_by_area.find("land.bb"))


func test_region_bounds_lie_inside_the_map() -> void:
	var bounds := _map.bounds(["land.by", "land.bw"])
	assert_true(Rect2(Vector2.ZERO, _map.size).encloses(bounds))
	assert_gt(bounds.size.x, 100.0)
