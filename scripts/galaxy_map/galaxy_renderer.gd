## galaxy_renderer.gd - Renderiza el mapa galáctico con _draw()
## Dibuja según el estado actual: GALAXY, SEGMENTUM, o SECTOR
extends Node2D

# Referencia al controller y datos
var _galaxy: Dictionary = {}
var _dp: GalaxyDataProvider = null
var _map = null # GalaxyMap (untyped para acceder a propiedades custom)

# Estado actual
var _state: int = 0 # MapState enum value
var _seg_key: String = ""
var _sec_key: String = "" # "seg.sec"

# Fuentes (se cargan en setup)
var _font: Font = null
var _font_large: Font = null

# Colores UI
const C_RIFT: Color = Color(0.55, 0.08, 0.18, 0.35)
const C_RIFT_GLOW: Color = Color(0.6, 0.1, 0.25, 0.15)
const C_EYE: Color = Color(0.9, 0.3, 0.1, 0.5)
const C_TERRA: Color = Color(1.0, 0.85, 0.3, 1.0)
const C_LABEL: Color = Color(0.75, 0.72, 0.65, 0.8)
const C_LABEL_DIM: Color = Color(0.5, 0.48, 0.42, 0.5)
const C_SECTOR_BORDER: Color = Color(0.4, 0.38, 0.32, 0.25)
const C_WARP_ROUTE: Color = Color(0.3, 0.35, 0.5, 0.15)
const C_SELECTED: Color = Color(0.85, 0.75, 0.35, 0.6)
const C_SUBSECTOR_BORDER: Color = Color(0.35, 0.33, 0.28, 0.15)

func setup(galaxy: Dictionary, dp: GalaxyDataProvider, map_node: Variant) -> void:
	_galaxy = galaxy
	_dp = dp
	_map = map_node
	_font = ThemeDB.fallback_font
	_font_large = ThemeDB.fallback_font

func set_state(state: int, seg_key: String, sec_key: String) -> void:
	_state = state
	_seg_key = seg_key
	_sec_key = sec_key
	queue_redraw()

func _draw() -> void:
	if _dp == null:
		return

	# Siempre dibujar la base galáctica (elementos de fondo persisten en todas las capas)
	_draw_galaxy_layer()

	# Dibujar la capa activa encima
	match _state:
		1: _draw_segmentum_layer()
		2: _draw_sector_layer()

# =============================================================================
# CAPA 1: VISTA GALÁCTICA
# =============================================================================

func _draw_galaxy_layer() -> void:
	# Dibujar disco galáctico tenue
	_draw_galaxy_disc()

	# Dibujar polígonos de segmentae
	for seg_key: String in _dp.segmentum_polygons:
		var poly: PackedVector2Array = _dp.segmentum_polygons[seg_key]
		var color: Color = GalaxyConfig.SEG_COLORS.get(seg_key, Color(0.3, 0.3, 0.3, 0.1))
		draw_colored_polygon(poly, color)
		_draw_polygon_outline(poly, Color(color.r, color.g, color.b, 0.25), 2.0)

	# Astronomicán (círculo dorado desde Terra)
	_draw_astronomican()

	# Territorios enemigos (debajo de los sectores)
	_draw_enemy_territories()

	# Región de Ultramar
	_draw_ultramar()

	# Dibujar sectores como círculos dentro de cada segmentum
	_draw_sector_circles()

	# Warp Storms canónicas
	_draw_warp_storms()

	# Gran Grieta
	_draw_rift()

	# Ojo del Terror
	_draw_eye_of_terror()

	# Hive Fleet vectors
	_draw_hive_fleets()

	# Terra (punto brillante en el centro)
	draw_circle(_dp.terra_pos, 40.0, Color(C_TERRA.r, C_TERRA.g, C_TERRA.b, 0.2))
	draw_circle(_dp.terra_pos, 20.0, Color(C_TERRA.r, C_TERRA.g, C_TERRA.b, 0.4))
	draw_circle(_dp.terra_pos, 8.0, C_TERRA)
	_draw_label(_dp.terra_pos + Vector2(60.0, -30.0), "TERRA", C_TERRA, 100)

	# Labels de segmentae FUERA del disco
	for seg_key: String in _dp.segmentum_label_pos:
		var pos: Vector2 = _dp.segmentum_label_pos[seg_key]
		var seg_name: String = ""
		if _galaxy["segmentae"].has(seg_key):
			seg_name = str(_galaxy["segmentae"][seg_key]["nombre"]).to_upper()
		var seg_color: Color = GalaxyConfig.SEG_COLORS.get(seg_key, Color(0.5, 0.5, 0.5, 0.5))
		_draw_label(pos, seg_name, Color(seg_color.r * 3.0, seg_color.g * 3.0, seg_color.b * 3.0, 0.7), 300)

	# Indicador de la Gran Grieta (posicionado a lo largo de la grieta)
	if _dp.rift_points.size() > 20:
		var rift_mid: Vector2 = _dp.rift_points[_dp.rift_points.size() / 2]
		_draw_label(rift_mid + Vector2(0.0, -200.0), "CICATRIX MALEDICTUM", Color(0.5, 0.15, 0.2, 0.5), 180)

	# Indicadores Sanctus / Nihilus (relativos a la posición de Terra)
	var terra: Vector2 = _dp.terra_pos
	_draw_label(terra + Vector2(0.0, 2200.0), "IMPERIUM SANCTUS", Color(0.5, 0.6, 0.4, 0.3), 200)
	_draw_label(terra + Vector2(0.0, -2700.0), "IMPERIUM NIHILUS", Color(0.5, 0.3, 0.3, 0.3), 200)

# =============================================================================
# ASTRONOMICÁN
# =============================================================================

func _draw_astronomican() -> void:
	var center: Vector2 = _dp.terra_pos
	var radius: float = _dp.astronomican_radius

	# Círculo dorado tenue del rango del Astronomicán
	_draw_circle_outline(center, radius, Color(0.85, 0.7, 0.2, 0.12), 3.0)

	# Segundo anillo interior más tenue
	_draw_circle_outline(center, radius * 0.97, Color(0.85, 0.7, 0.2, 0.06), 1.5)

	# Label
	_draw_label(center + Vector2(radius + 80.0, 0.0), "ASTRONOMICÁN", Color(0.75, 0.6, 0.2, 0.35), 80)
	_draw_label(center + Vector2(radius + 80.0, 90.0), "RANGO MÁXIMO", Color(0.6, 0.5, 0.2, 0.25), 50)

# =============================================================================
# WARP STORMS CANÓNICAS
# =============================================================================

func _draw_warp_storms() -> void:
	for i: int in _dp.warp_storms.size():
		var storm: Dictionary = _dp.warp_storms[i]
		var pos: Vector2 = storm["pos"]
		var radius: float = float(storm["radius"])
		var color: Color = storm["color"]
		var nombre: String = str(storm["nombre"])

		# Glow exterior
		_draw_filled_circle(pos, radius * 1.5, Color(color.r, color.g, color.b, color.a * 0.2))
		# Core
		_draw_filled_circle(pos, radius, color)
		# Centro intenso
		_draw_filled_circle(pos, radius * 0.4, Color(color.r, color.g, color.b, minf(color.a * 1.8, 1.0)))

		# Label multilinea
		var label_color: Color = Color(color.r * 1.5, color.g * 1.5, color.b * 1.5, 0.55)
		var lines: PackedStringArray = nombre.split("\n")
		for l: int in lines.size():
			_draw_label(pos + Vector2(0.0, -radius - 50.0 + float(l) * 65.0), lines[l], label_color, 55)

# =============================================================================
# TERRITORIOS ENEMIGOS
# =============================================================================

func _draw_enemy_territories() -> void:
	for i: int in _dp.enemy_territories.size():
		var terr: Dictionary = _dp.enemy_territories[i]
		var center: Vector2 = terr["center"]
		var radius: float = float(terr["radius"])
		var color: Color = terr["color"]
		var border_color: Color = terr["border_color"]
		var label_color: Color = terr["label_color"]
		var nombre: String = str(terr["nombre"])

		_draw_filled_circle(center, radius, color)
		_draw_dashed_circle(center, radius, border_color, 3.0)

		# Label multilinea
		var lines: PackedStringArray = nombre.split("\n")
		var total_h: float = float(lines.size()) * 65.0
		for l: int in lines.size():
			_draw_label(center + Vector2(0.0, -total_h / 2.0 + float(l) * 65.0), lines[l], label_color, 60)

# =============================================================================
# REGIÓN DE ULTRAMAR
# =============================================================================

func _draw_ultramar() -> void:
	var center: Vector2 = _dp.ultramar_center
	var radius: float = _dp.ultramar_radius

	# Relleno azul muy tenue
	_draw_filled_circle(center, radius, Color(0.15, 0.25, 0.6, 0.08))
	# Borde azul
	_draw_circle_outline(center, radius, Color(0.2, 0.35, 0.7, 0.25), 2.0)
	# Label
	_draw_label(center + Vector2(0.0, -radius - 25.0), "ULTRAMAR", Color(0.3, 0.45, 0.8, 0.5), 70)
	_draw_label(center + Vector2(0.0, -radius + 40.0), "500 Mundos de los Ultramarines", Color(0.3, 0.4, 0.65, 0.3), 35)

# =============================================================================
# VECTORES DE HIVE FLEETS
# =============================================================================

func _draw_hive_fleets() -> void:
	for i: int in _dp.hive_fleet_vectors.size():
		var fleet: Dictionary = _dp.hive_fleet_vectors[i]
		var points: PackedVector2Array = fleet["points"]
		var color: Color = fleet["color"]
		var nombre: String = str(fleet["nombre"])
		var status: String = str(fleet["status"])

		if points.size() < 2:
			continue

		# Glow detrás de la línea de avance
		for j: int in range(0, points.size() - 1):
			var p1: Vector2 = points[j]
			var p2: Vector2 = points[j + 1]
			var glow_w: float = 40.0 + float(j) * 20.0
			draw_line(p1, p2, Color(color.r, color.g, color.b, 0.08), glow_w, true)

		# Línea de avance (grosor visible a zoom galáctico)
		for j: int in range(0, points.size() - 1):
			var p1: Vector2 = points[j]
			var p2: Vector2 = points[j + 1]
			var width: float = 10.0 + float(j) * 12.0
			draw_line(p1, p2, color, width, true)

		# Punta de flecha grande en el último punto
		var tip: Vector2 = points[points.size() - 1]
		var prev_pt: Vector2 = points[points.size() - 2]
		var dir: Vector2 = (tip - prev_pt).normalized()
		var perp: Vector2 = dir.rotated(PI / 2.0)
		var arrow_size: float = 180.0

		var arrow_pts: PackedVector2Array = PackedVector2Array([
			tip + dir * arrow_size,
			tip - dir * 30.0 + perp * arrow_size * 0.45,
			tip - dir * 30.0 - perp * arrow_size * 0.45,
		])
		draw_colored_polygon(arrow_pts, color)

		# Labels al inicio del vector (fuera de la galaxia, multilinea manual)
		var label_pos: Vector2 = points[0]
		var name_lines: PackedStringArray = nombre.split("\n")
		for l: int in name_lines.size():
			_draw_label(label_pos + Vector2(0.0, float(l) * 110.0), name_lines[l],
				Color(color.r, color.g, color.b, 0.7), 100)
		# Status debajo
		var status_y: float = float(name_lines.size()) * 110.0 + 30.0
		var status_color: Color = Color(0.9, 0.15, 0.15, 0.7) if status == "ACTIVA" else Color(0.5, 0.5, 0.4, 0.45)
		_draw_label(label_pos + Vector2(0.0, status_y), "[" + status + "]", status_color, 70)

func _draw_sector_circles() -> void:
	# Dibujar cada sector como un círculo con nombre en la vista galáctica
	for full_key: String in _dp.sector_positions:
		var pos: Vector2 = _dp.sector_positions[full_key]
		var radius: float = float(_dp.sector_radii[full_key])

		# Obtener datos del sector
		var parts: PackedStringArray = full_key.split(".")
		if parts.size() < 2:
			continue
		var seg_key: String = parts[0]
		var sec_key: String = parts[1]

		# Color del círculo según el segmentum
		var seg_color: Color = GalaxyConfig.SEG_COLORS.get(seg_key, Color(0.3, 0.3, 0.3, 0.1))
		var circle_color: Color = Color(seg_color.r, seg_color.g, seg_color.b, 0.35)

		# Relleno tenue del sector
		_draw_filled_circle(pos, radius, Color(seg_color.r, seg_color.g, seg_color.b, 0.06))

		# Borde del círculo del sector
		_draw_circle_outline(pos, radius, circle_color, 1.5)

		# Nombre del sector dentro o debajo del círculo
		var sec_name: String = ""
		if _galaxy["segmentae"].has(seg_key):
			var seg: Dictionary = _galaxy["segmentae"][seg_key]
			if seg["sectores"].has(sec_key):
				sec_name = str(seg["sectores"][sec_key]["nombre"])

		_draw_label(pos, sec_name, Color(0.65, 0.62, 0.55, 0.6), 60)

		# Cantidad de planetas debajo del nombre
		var planet_count: int = _count_sector_planets_by_key(seg_key, sec_key)
		_draw_label(pos + Vector2(0.0, 70.0), str(planet_count) + " mundos", C_LABEL_DIM, 40)

func _draw_galaxy_disc() -> void:
	# Disco galáctico centrado en el CENTRO GALÁCTICO REAL (Vector2.ZERO)
	var disc_r: float = GalaxyConfig.GALAXY_DISC_RADIUS
	var steps: int = 64
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in steps:
		var angle: float = (float(i) / float(steps)) * TAU
		pts.append(Vector2(cos(angle) * disc_r, sin(angle) * disc_r))
	draw_colored_polygon(pts, Color(0.06, 0.05, 0.10, 0.12))

	# Centro galáctico = Terra (en este mapa, como en los mapas oficiales GW)

func _draw_rift() -> void:
	if _dp.rift_points.size() < 2:
		return

	# Glow exterior muy ancho y difuso
	for i: int in range(0, _dp.rift_points.size() - 1):
		var p1: Vector2 = _dp.rift_points[i]
		var p2: Vector2 = _dp.rift_points[i + 1]
		draw_line(p1, p2, Color(0.4, 0.05, 0.1, 0.06), 350.0, true)

	# Glow medio
	for i: int in range(0, _dp.rift_points.size() - 1):
		var p1: Vector2 = _dp.rift_points[i]
		var p2: Vector2 = _dp.rift_points[i + 1]
		draw_line(p1, p2, Color(0.55, 0.08, 0.15, 0.12), 150.0, true)

	# Core de la grieta
	for i: int in range(0, _dp.rift_points.size() - 1):
		var p1: Vector2 = _dp.rift_points[i]
		var p2: Vector2 = _dp.rift_points[i + 1]
		draw_line(p1, p2, Color(0.7, 0.1, 0.2, 0.3), 40.0, true)

	# Centro más brillante
	for i: int in range(0, _dp.rift_points.size() - 1):
		var p1: Vector2 = _dp.rift_points[i]
		var p2: Vector2 = _dp.rift_points[i + 1]
		draw_line(p1, p2, Color(0.85, 0.15, 0.25, 0.5), 12.0, true)

func _draw_eye_of_terror() -> void:
	# Círculos concéntricos pulsantes
	var pos: Vector2 = _dp.eye_of_terror_pos
	draw_circle(pos, 250.0, Color(C_EYE.r, C_EYE.g, C_EYE.b, 0.08))
	draw_circle(pos, 150.0, Color(C_EYE.r, C_EYE.g, C_EYE.b, 0.15))
	draw_circle(pos, 70.0, Color(C_EYE.r, C_EYE.g, C_EYE.b, 0.3))
	draw_circle(pos, 25.0, C_EYE)
	_draw_label(pos + Vector2(0.0, -300.0), "OJO DEL TERROR", Color(0.8, 0.25, 0.1, 0.5), 120)

# =============================================================================
# CAPA 2: VISTA DE SEGMENTUM
# =============================================================================

func _draw_segmentum_layer() -> void:
	if _seg_key == "" or not _galaxy["segmentae"].has(_seg_key):
		return

	var seg: Dictionary = _galaxy["segmentae"][_seg_key]
	var sectores: Dictionary = seg["sectores"]

	# Fondo del segmentum (polígono más visible que en capa 1)
	if _dp.segmentum_polygons.has(_seg_key):
		var poly: PackedVector2Array = _dp.segmentum_polygons[_seg_key]
		var color: Color = GalaxyConfig.SEG_COLORS.get(_seg_key, Color(0.3, 0.3, 0.3, 0.1))
		draw_colored_polygon(poly, Color(color.r, color.g, color.b, 0.08))

	# Dibujar sectores (tamaños escalados para zoom ~0.25)
	for sec_key: String in sectores:
		var full_key: String = _seg_key + "." + sec_key
		if not _dp.sector_positions.has(full_key):
			continue

		var sec: Dictionary = sectores[sec_key]
		var pos: Vector2 = _dp.sector_positions[full_key]
		var radius: float = float(_dp.sector_radii[full_key])
		var lado: String = str(sec["lado_grieta"])

		# Relleno del sector
		var seg_col: Color = GalaxyConfig.SEG_COLORS.get(_seg_key, Color(0.3, 0.3, 0.3))
		_draw_filled_circle(pos, radius, Color(seg_col.r, seg_col.g, seg_col.b, 0.05))

		# Borde punteado del sector (grosor visible a zoom 0.25)
		var sector_color: Color = C_SECTOR_BORDER
		if lado == "nihilus":
			sector_color = Color(0.4, 0.2, 0.2, 0.25)
		_draw_dashed_circle(pos, radius, sector_color, 4.0)

		# Puntos de densidad
		_draw_density_dots(sec, pos, radius)

		# Nombre del sector (tamaño mundo, no pixels)
		var sec_name: String = str(sec["nombre"])
		_draw_label(pos + Vector2(0.0, -20.0), sec_name, C_LABEL, 45)

		# Cantidad de planetas
		var planet_count: int = _count_sector_planets(sec)
		_draw_label(pos + Vector2(0.0, 30.0), str(planet_count) + " mundos", C_LABEL_DIM, 28)

		# Sanctus/Nihilus badge
		var lado_label: String = "SANCTUS" if lado == "sanctus" else "NIHILUS"
		var lado_color: Color = Color(0.4, 0.5, 0.35, 0.35) if lado == "sanctus" else Color(0.5, 0.3, 0.25, 0.35)
		_draw_label(pos + Vector2(0.0, 60.0), lado_label, lado_color, 22)

	# Rutas warp entre sectores (grosor visible)
	var sec_keys: Array = sectores.keys()
	for i: int in sec_keys.size():
		for j: int in range(i + 1, sec_keys.size()):
			var key_a: String = _seg_key + "." + str(sec_keys[i])
			var key_b: String = _seg_key + "." + str(sec_keys[j])
			if _dp.sector_positions.has(key_a) and _dp.sector_positions.has(key_b):
				_draw_warp_route_thick(_dp.sector_positions[key_a], _dp.sector_positions[key_b], 3.0)

	# Título del segmentum
	_draw_label(_dp.segmentum_centers[_seg_key] + Vector2(0.0, -900.0),
		str(seg["nombre"]).to_upper(), C_LABEL, 80)

func _draw_density_dots(sec: Dictionary, center: Vector2, radius: float) -> void:
	var sub_dict: Dictionary = sec["subsectores"]
	var rng_local: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_local.seed = 12345

	for sub_key: String in sub_dict:
		var sub: Dictionary = sub_dict[sub_key]
		var planetas: Array = sub["planetas"]
		var count: int = planetas.size()
		var dots: int = maxi(count / 3, 2)
		for d: int in dots:
			var angle: float = rng_local.randf_range(0.0, TAU)
			var dist: float = rng_local.randf_range(15.0, radius * 0.75)
			var dot_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist
			draw_circle(dot_pos, 5.0, Color(0.6, 0.58, 0.5, 0.2))

# =============================================================================
# CAPA 3: VISTA DE SECTOR
# =============================================================================

func _draw_sector_layer() -> void:
	if _sec_key == "":
		return

	var parts: PackedStringArray = _sec_key.split(".")
	if parts.size() < 2:
		return
	var seg_key: String = parts[0]
	var sec_key: String = parts[1]

	if not _galaxy["segmentae"].has(seg_key):
		return
	var seg: Dictionary = _galaxy["segmentae"][seg_key]
	if not seg["sectores"].has(sec_key):
		return
	var sec: Dictionary = seg["sectores"][sec_key]

	var sec_pos: Vector2 = _dp.sector_positions.get(_sec_key, Vector2.ZERO)
	var sec_radius: float = float(_dp.sector_radii.get(_sec_key, 200.0))

	# Borde del sector actual (highlight)
	_draw_circle_outline(sec_pos, sec_radius, Color(0.6, 0.55, 0.3, 0.15), 2.0)

	# Dibujar subsectores (tamaños para zoom ~1.8)
	var sub_dict: Dictionary = sec["subsectores"]
	for sub_key: String in sub_dict:
		var sub: Dictionary = sub_dict[sub_key]
		var full_sub: String = _sec_key + "." + sub_key
		if not _dp.subsector_positions.has(full_sub):
			continue

		var sub_pos: Vector2 = _dp.subsector_positions[full_sub]

		# Área del subsector (borde punteado)
		_draw_dashed_circle(sub_pos, 70.0, C_SUBSECTOR_BORDER, 1.0)

		# Label del subsector
		_draw_label(sub_pos + Vector2(0.0, -78.0), str(sub["nombre"]), C_LABEL_DIM, 11)

		# Dibujar planetas
		var planetas: Array = sub["planetas"]
		for p_idx: int in planetas.size():
			_draw_planet(planetas[p_idx])

	# Rutas warp entre subsectores
	var sub_keys: Array = sub_dict.keys()
	for i: int in sub_keys.size():
		for j: int in range(i + 1, sub_keys.size()):
			var key_a: String = _sec_key + "." + str(sub_keys[i])
			var key_b: String = _sec_key + "." + str(sub_keys[j])
			if _dp.subsector_positions.has(key_a) and _dp.subsector_positions.has(key_b):
				_draw_warp_route(_dp.subsector_positions[key_a], _dp.subsector_positions[key_b])

	# Título del sector
	var sec_name: String = str(sec["nombre"])
	_draw_label(sec_pos + Vector2(0.0, -sec_radius - 20.0), sec_name.to_upper(), C_LABEL, 18)

func _draw_planet(planet: Dictionary) -> void:
	var pid: int = int(planet["id"])
	if not _dp.planet_positions.has(pid):
		return

	var pos: Vector2 = _dp.planet_positions[pid]
	var tipo: String = str(planet["tipo"])
	var color: Color = _dp.get_planet_color(tipo)
	var radius: float = _dp.get_planet_radius(planet)

	# Atenuar si está filtrado
	if _map and not _map.filter_dimmed_ids.is_empty():
		if _map.filter_dimmed_ids.has(pid):
			color = Color(color.r, color.g, color.b, 0.15)

	# Highlight si está seleccionado
	var is_selected: bool = false
	if _map and not _map.selected_planet.is_empty():
		is_selected = int(_map.selected_planet.get("id", -1)) == pid

	if is_selected:
		draw_circle(pos, radius + 6.0, Color(C_SELECTED.r, C_SELECTED.g, C_SELECTED.b, 0.3))
		draw_circle(pos, radius + 3.0, C_SELECTED)

	# Glow sutil
	draw_circle(pos, radius + 2.0, Color(color.r, color.g, color.b, 0.15))

	# Punto del planeta
	draw_circle(pos, radius, color)

	# Nombre para planetas canónicos (siempre visible)
	if planet.get("es_canonico", false):
		var nombre: String = str(planet["nombre"])
		_draw_label(pos + Vector2(radius + 5.0, -3.0), nombre, Color(0.8, 0.78, 0.7, 0.9), 8)

# =============================================================================
# UTILIDADES DE DIBUJO
# =============================================================================

func _draw_label(pos: Vector2, text: String, color: Color, size: int) -> void:
	if _font == null:
		return
	# Centrar manualmente: medir el ancho del texto y desplazar la mitad a la izquierda
	var text_width: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var centered_pos: Vector2 = Vector2(pos.x - text_width / 2.0, pos.y)
	draw_string(_font, centered_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw_polygon_outline(poly: PackedVector2Array, color: Color, width: float) -> void:
	if poly.size() < 2:
		return
	for i: int in poly.size():
		var next: int = (i + 1) % poly.size()
		draw_line(poly[i], poly[next], color, width, true)

func _draw_dashed_circle(center: Vector2, radius: float, color: Color, width: float) -> void:
	var segments: int = 48
	for i: int in segments:
		if i % 2 == 1:
			continue # Skip para crear efecto punteado
		var a1: float = (float(i) / float(segments)) * TAU
		var a2: float = (float(i + 1) / float(segments)) * TAU
		var p1: Vector2 = center + Vector2(cos(a1), sin(a1)) * radius
		var p2: Vector2 = center + Vector2(cos(a2), sin(a2)) * radius
		draw_line(p1, p2, color, width, true)

func _draw_warp_route(from: Vector2, to: Vector2) -> void:
	_draw_warp_route_thick(from, to, 1.0)

func _draw_warp_route_thick(from: Vector2, to: Vector2, width: float) -> void:
	var mid: Vector2 = (from + to) / 2.0
	var perp: Vector2 = (to - from).rotated(PI / 2.0).normalized()
	var offset_dist: float = from.distance_to(to) * 0.15
	var control: Vector2 = mid + perp * offset_dist

	var prev: Vector2 = from
	for i: int in range(1, 11):
		var t: float = float(i) / 10.0
		var p: Vector2 = from.lerp(control, t).lerp(control.lerp(to, t), t)
		draw_line(prev, p, C_WARP_ROUTE, width, true)
		prev = p

func _count_sector_planets(sec: Dictionary) -> int:
	var count: int = 0
	var sub_dict: Dictionary = sec["subsectores"]
	for sub_key: String in sub_dict:
		var sub: Dictionary = sub_dict[sub_key]
		var planetas: Array = sub["planetas"]
		count += planetas.size()
	return count

func _count_sector_planets_by_key(seg_key: String, sec_key: String) -> int:
	if not _galaxy["segmentae"].has(seg_key):
		return 0
	var seg: Dictionary = _galaxy["segmentae"][seg_key]
	if not seg["sectores"].has(sec_key):
		return 0
	return _count_sector_planets(seg["sectores"][sec_key])

func _draw_filled_circle(center: Vector2, radius: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var steps: int = 32
	for i: int in steps:
		var angle: float = (float(i) / float(steps)) * TAU
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(pts, color)

func _draw_circle_outline(center: Vector2, radius: float, color: Color, width: float) -> void:
	var steps: int = 48
	for i: int in steps:
		var a1: float = (float(i) / float(steps)) * TAU
		var a2: float = (float(i + 1) / float(steps)) * TAU
		var p1: Vector2 = center + Vector2(cos(a1), sin(a1)) * radius
		var p2: Vector2 = center + Vector2(cos(a2), sin(a2)) * radius
		draw_line(p1, p2, color, width, true)
