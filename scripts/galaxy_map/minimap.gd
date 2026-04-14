## minimap.gd - Minimapa en la esquina inferior izquierda
## Muestra siempre la vista galáctica con un rectángulo de posición
extends Control

var _map = null
var _dp: GalaxyDataProvider = null

const MINIMAP_SIZE: float = 160.0
const GALAXY_RANGE: float = 5000.0 # -5000 a 5000

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)

	# Posición: esquina inferior izquierda
	anchor_left = 0.0
	anchor_top = 1.0
	offset_left = 10.0
	offset_top = -MINIMAP_SIZE - 10.0
	size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)

func setup(map_ref: Node2D, dp: GalaxyDataProvider) -> void:
	_map = map_ref
	_dp = dp
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _dp == null or _map == null:
		return

	# Fondo
	draw_rect(Rect2(Vector2.ZERO, Vector2(MINIMAP_SIZE, MINIMAP_SIZE)),
		Color(0.03, 0.03, 0.06, 0.85))

	# Borde
	draw_rect(Rect2(Vector2.ZERO, Vector2(MINIMAP_SIZE, MINIMAP_SIZE)),
		Color(0.4, 0.38, 0.3, 0.3), false, 1.0)

	# Dibujar segmentae como manchas de color
	for seg_key: String in _dp.segmentum_centers:
		var world_pos: Vector2 = _dp.segmentum_centers[seg_key]
		var mini_pos: Vector2 = _world_to_mini(world_pos)
		var color: Color = GalaxyConfig.SEG_COLORS.get(seg_key, Color.WHITE)
		var radius: float = 15.0 if seg_key == "solar" else 25.0
		draw_circle(mini_pos, radius, Color(color.r, color.g, color.b, 0.3))

	# Terra
	var terra_mini: Vector2 = _world_to_mini(Vector2.ZERO)
	draw_circle(terra_mini, 2.0, Color(1.0, 0.85, 0.3, 0.8))

	# Gran Grieta simplificada
	if _dp.rift_points.size() >= 2:
		var prev: Vector2 = _world_to_mini(_dp.rift_points[0])
		for i: int in range(1, _dp.rift_points.size(), 5):
			var curr: Vector2 = _world_to_mini(_dp.rift_points[i])
			draw_line(prev, curr, Color(0.5, 0.1, 0.15, 0.3), 1.0)
			prev = curr

	# Rectángulo de viewport actual
	var cam_pos: Vector2 = _map.camera.global_position
	var zoom: float = _map._current_zoom
	var vp_size: Vector2 = get_viewport_rect().size
	var world_vp_size: Vector2 = vp_size / zoom

	var rect_pos: Vector2 = _world_to_mini(cam_pos - world_vp_size / 2.0)
	var rect_size: Vector2 = world_vp_size / (GALAXY_RANGE * 2.0) * MINIMAP_SIZE
	var min_v: Vector2 = Vector2(4.0, 4.0)
	var max_v: Vector2 = Vector2(MINIMAP_SIZE - 2.0, MINIMAP_SIZE - 2.0)
	rect_size = rect_size.clamp(min_v, max_v)

	draw_rect(Rect2(rect_pos, rect_size),
		Color(0.85, 0.75, 0.35, 0.5), false, 1.0)

func _world_to_mini(world_pos: Vector2) -> Vector2:
	# Convertir posición del mundo (-5000..5000) a minimapa (0..MINIMAP_SIZE)
	var normalized: Vector2 = (world_pos + Vector2(GALAXY_RANGE, GALAXY_RANGE)) / (GALAXY_RANGE * 2.0)
	return normalized * MINIMAP_SIZE

func _gui_input(event: InputEvent) -> void:
	# Click en el minimapa para navegar
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var mini_pos: Vector2 = mb.position
			var world_pos: Vector2 = _mini_to_world(mini_pos)
			if _map:
				_map.camera.position = world_pos
				_map.renderer.queue_redraw()
			get_viewport().set_input_as_handled()

func _mini_to_world(mini_pos: Vector2) -> Vector2:
	var normalized: Vector2 = mini_pos / MINIMAP_SIZE
	return normalized * (GALAXY_RANGE * 2.0) - Vector2(GALAXY_RANGE, GALAXY_RANGE)
