class_name MapView
extends Control
## Stylized map of the 16 lands with overlays, zoom and clickable lands and institutions
## (game-design.md section 3.1).

signal land_selected(land_id: String)
signal place_selected(place_id: String)

## Overlay modes, in the order of the selector.
const OVERLAYS: PackedStringArray = ["regions", "polling", "turnout", "gap", "climate"]
const BORDER_COLOR := Color(0.2, 0.2, 0.25)
const SELECTED_BORDER_COLOR := Color(0.95, 0.75, 0.1)
const HOVER_TINT := Color(1, 1, 1, 0.25)
## Lands outside the playable regions are faded towards this colour in the region overlay.
const INACTIVE_COLOR := Color(0.82, 0.82, 0.84)
const INACTIVE_FADE := 0.65
const PLACE_RADIUS := 9.0
const MARGIN := 12.0
## Base colour per region for the "regions" overlay.
const REGION_COLORS: Dictionary = {
	"region.south": Color(0.55, 0.7, 0.9),
	"region.north": Color(0.55, 0.85, 0.75),
	"region.west": Color(0.85, 0.7, 0.6),
	"region.east": Color(0.85, 0.8, 0.55),
	"region.central": Color(0.75, 0.7, 0.85),
	"region.metropolises": Color(0.9, 0.6, 0.65),
}

var session: GameSession
var map: MapData
var overlay: String = "regions"
var selected_land: String = ""
var hovered_land: String = ""
var hovered_place: String = ""
## Area of the plane currently shown.
var _view: Rect2


## Prepares the view; call before it enters the tree.
func setup(game_session: GameSession, map_data: MapData) -> void:
	session = game_session
	map = map_data
	_view = Rect2(Vector2.ZERO, map.size)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Zoomed regions extend beyond the view; never draw over neighbouring controls.
	clip_contents = true
	session.changed.connect(queue_redraw)


## Shows the whole federation or zooms on a region.
func zoom_to(region_id: String) -> void:
	if region_id.is_empty():
		_view = Rect2(Vector2.ZERO, map.size)
	else:
		_view = map.bounds(Array(session.defs.regions[region_id].lands)).grow(40.0)
	queue_redraw()


## Selects an overlay mode from OVERLAYS.
func set_overlay(mode: String) -> void:
	overlay = mode
	queue_redraw()


## Returns a short explanation of the current overlay's colours.
func legend() -> String:
	return tr("ui.map.legend." + overlay)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.93, 0.94, 0.96))
	# Without room to draw, all points would collapse and triangulation would fail.
	if map == null or not session.has_game() or size.x <= MARGIN * 3.0 or size.y <= MARGIN * 3.0:
		return
	var to_screen := _plane_to_screen()
	for land_id in _drawing_order():
		var fill := _fill_color(land_id)
		if land_id == hovered_land:
			fill = fill.blend(HOVER_TINT)
		for polygon: PackedVector2Array in map.lands[land_id]:
			var points := to_screen * polygon
			draw_colored_polygon(points, fill)
			var outline := points.duplicate()
			outline.append(points[0])
			var selected := land_id == selected_land
			draw_polyline(outline, SELECTED_BORDER_COLOR if selected else BORDER_COLOR, 3.0 if selected else 1.0, true)
	for place_id: String in map.places:
		var center := to_screen * map.places[place_id]
		var radius := PLACE_RADIUS * (1.3 if place_id == hovered_place else 1.0)
		draw_circle(center, radius, _place_color(place_id))
		draw_arc(center, radius, 0.0, TAU, 24, Color.WHITE, 2.0, true)
	var hover_text := _hover_text()
	if not hover_text.is_empty():
		draw_string(get_theme_default_font(), Vector2(MARGIN, size.y - MARGIN), hover_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.BLACK)


func _gui_input(event: InputEvent) -> void:
	if map == null or not session.has_game():
		return
	if event is InputEventMouseMotion:
		var mouse: Vector2 = (event as InputEventMouseMotion).position
		var point := _plane_to_screen().affine_inverse() * mouse
		var place := _place_at(mouse)
		var land := "" if not place.is_empty() else map.land_at(point)
		if land != hovered_land or place != hovered_place:
			hovered_land = land
			hovered_place = place
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not hovered_place.is_empty():
			place_selected.emit(hovered_place)
		elif not hovered_land.is_empty():
			selected_land = hovered_land
			queue_redraw()
			land_selected.emit(hovered_land)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hovered_land = ""
		hovered_place = ""
		queue_redraw()


## Largest lands first, so small lands inside others are drawn on top.
func _drawing_order() -> Array[String]:
	var order := map.lands_by_area.duplicate()
	order.reverse()
	return order


func _plane_to_screen() -> Transform2D:
	var available := size - Vector2(MARGIN, MARGIN) * 2.0
	var zoom := minf(available.x / _view.size.x, available.y / _view.size.y)
	var offset := Vector2(MARGIN, MARGIN) + (available - _view.size * zoom) / 2.0 - _view.position * zoom
	return Transform2D(0.0, Vector2(zoom, zoom), 0.0, offset)


func _place_at(screen_point: Vector2) -> String:
	var to_screen := _plane_to_screen()
	for place_id: String in map.places:
		if screen_point.distance_to(to_screen * map.places[place_id]) <= PLACE_RADIUS * 1.3:
			return place_id
	return ""


func _fill_color(land_id: String) -> Color:
	var land := session.state.lands[land_id]
	var region := session.defs.lands[land_id].region
	var playable := session.defs.scenarios[session.state.scenario_id].playable_regions.has(region)
	var color: Color
	match overlay:
		"polling":
			color = Color(1, 1, 1).lerp(Color(0.6, 0.15, 0.5), clampf(land.polling / 10.0, 0.0, 1.0))
		"turnout":
			color = Color(0.95, 0.85, 0.75).lerp(Color(0.2, 0.45, 0.7), clampf((land.turnout - 55.0) / 30.0, 0.0, 1.0))
		"gap":
			color = Color(1, 1, 1).lerp(Color(0.85, 0.35, 0.1), clampf(land.representation_gap / 0.6, 0.0, 1.0))
		"climate":
			var climate := land.media_climate
			color = Color(1, 1, 1).lerp(Color(0.2, 0.6, 0.3) if climate >= 0.0 else Color(0.8, 0.25, 0.25), absf(climate))
		_:
			color = REGION_COLORS.get(region, Color.LIGHT_GRAY)
	if overlay == "regions" and not playable:
		return color.lerp(INACTIVE_COLOR, INACTIVE_FADE)
	return color


func _place_color(place_id: String) -> Color:
	if place_id.begins_with("media."):
		return Color(0.2, 0.45, 0.75)
	return Color(0.75, 0.2, 0.2)


func _hover_text() -> String:
	if not hovered_place.is_empty():
		return tr(hovered_place + ".name")
	if hovered_land.is_empty():
		return ""
	var land := session.state.lands[hovered_land]
	return tr("ui.map.hover") % [
		tr(hovered_land + ".name"), land.polling, land.turnout, land.representation_gap * 100.0,
	]
