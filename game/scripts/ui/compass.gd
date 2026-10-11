class_name Compass
extends Control

const HALF_FOV := PI / 2.0
const CARDINALS := {0: "N", 45: "NE", 90: "E", 135: "SE", 180: "S", 225: "SW", 270: "W", 315: "NW"}
const LABEL_SIZE := 14
const COLOR_BG := Color(0.08, 0.07, 0.06, 0.65)
const COLOR_TICK := Color(1, 1, 1, 0.55)
const COLOR_TEXT := Color(1, 0.96, 0.88)
const COLOR_POI := Color(1.0, 0.72, 0.25)
const COLOR_VISITED := Color(0.6, 0.6, 0.6)

var heading := 0.0
var player_pos := Vector2.ZERO
var pois: Array[PoiData] = []


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h * 0.55)), COLOR_BG)
	for deg in range(0, 360, 15):
		var bearing := wrapf(deg_to_rad(deg) - heading, -PI, PI)
		if absf(bearing) > HALF_FOV:
			continue
		var x := CompassMath.bearing_to_x(bearing, HALF_FOV, w)
		if CARDINALS.has(deg):
			var label: String = CARDINALS[deg]
			var fs := 18 if label.length() == 1 else 13
			var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
			draw_string(font, Vector2(x - tw * 0.5, h * 0.4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, COLOR_TEXT)
		else:
			draw_line(Vector2(x, h * 0.12), Vector2(x, h * 0.28), COLOR_TICK, 2.0)
	draw_line(Vector2(w * 0.5, 0), Vector2(w * 0.5, h * 0.08), COLOR_TEXT, 3.0)
	_draw_pois(font, w, h)


func _draw_pois(font: Font, w: float, h: float) -> void:
	var markers: Array[float] = []
	var centers: Array[float] = []
	var widths: Array[float] = []
	var texts: Array[String] = []
	for poi in pois:
		var bearing := CompassMath.relative_bearing(heading, player_pos, poi.position_2d())
		var text := "%s  %dm" % [poi.display_name, int(poi.position_2d().distance_to(player_pos))]
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
		texts.append(text)
		markers.append(CompassMath.bearing_to_x(bearing, HALF_FOV, w))
		centers.append(clampf(markers.back(), tw * 0.5, w - tw * 0.5))
		widths.append(tw)
	var rows := CompassMath.label_rows(centers, widths)
	var y := h * 0.55
	for i in pois.size():
		var x := markers[i]
		var color := COLOR_VISITED if GameState.is_visited(pois[i].id) else COLOR_POI
		draw_colored_polygon(PackedVector2Array([Vector2(x, y - 2), Vector2(x - 8, y + 10), Vector2(x + 8, y + 10)]), color)
		var tx := centers[i] - widths[i] * 0.5
		var ty := y + 26 + rows[i] * (LABEL_SIZE + 6)
		draw_string_outline(font, Vector2(tx, ty), texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, 4, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(tx, ty), texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, color)
