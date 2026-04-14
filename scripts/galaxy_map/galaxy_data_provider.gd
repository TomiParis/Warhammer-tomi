## galaxy_data_provider.gd - Calcula posiciones de toda la galaxia
## Se ejecuta una sola vez y cachea todo para renderizado eficiente
class_name GalaxyDataProvider

# Espacio total de la galaxia: -5000 a +5000
const GALAXY_RADIUS: float = 4500.0
const SOLAR_RADIUS: float = 1100.0

# Colores por segmentum
const SEG_COLORS: Dictionary = {
	"solar": Color(0.85, 0.75, 0.3, 0.12),
	"obscurus": Color(0.7, 0.15, 0.15, 0.12),
	"ultima": Color(0.2, 0.35, 0.7, 0.12),
	"tempestus": Color(0.15, 0.4, 0.2, 0.12),
	"pacificus": Color(0.4, 0.15, 0.5, 0.12),
}

# Colores por tipo de planeta
const PLANET_COLORS: Dictionary = {
	"hive_world": Color(0.8, 0.65, 0.3),
	"forge_world": Color(0.7, 0.3, 0.2),
	"agri_world": Color(0.4, 0.5, 0.25),
	"civilised_world": Color(0.6, 0.6, 0.6, 0.7),
	"shrine_world": Color(0.75, 0.65, 0.3),
	"cardinal_world": Color(0.75, 0.65, 0.3),
	"death_world": Color(0.5, 0.35, 0.5),
	"fortress_world": Color(0.6, 0.65, 0.7),
	"knight_world": Color(0.7, 0.75, 0.85),
	"dead_world": Color(0.25, 0.25, 0.25),
	"feral_world": Color(0.5, 0.45, 0.35),
	"feudal_world": Color(0.55, 0.5, 0.4),
	"mining_world": Color(0.55, 0.45, 0.3),
	"paradise_world": Color(0.4, 0.6, 0.65),
	"penal_world": Color(0.45, 0.35, 0.35),
	"cemetery_world": Color(0.35, 0.35, 0.38),
	"research_station": Color(0.5, 0.55, 0.65),
}

# --- Datos calculados ---
var segmentum_polygons: Dictionary = {} # key -> PackedVector2Array
var segmentum_centers: Dictionary = {}  # key -> Vector2
var segmentum_label_pos: Dictionary = {} # key -> Vector2

var sector_positions: Dictionary = {}   # "seg.sec" -> Vector2
var sector_radii: Dictionary = {}       # "seg.sec" -> float

var subsector_positions: Dictionary = {} # "seg.sec.sub" -> Vector2

var planet_positions: Dictionary = {}   # planet_id -> Vector2
var planet_data_by_id: Dictionary = {}  # planet_id -> planet dict ref

var rift_points: PackedVector2Array = PackedVector2Array() # Gran Grieta
var eye_of_terror_pos: Vector2 = Vector2.ZERO
var terra_pos: Vector2 = Vector2.ZERO

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# =============================================================================
# PUNTO DE ENTRADA
# =============================================================================

func calculate_all(galaxy: Dictionary) -> void:
	_rng.seed = 42

	_build_segmentum_polygons()
	_build_rift()
	_calculate_sector_positions(galaxy)
	_calculate_subsector_positions(galaxy)
	_calculate_planet_positions(galaxy)

	# Posiciones especiales - buscar Terra en los planetas generados
	terra_pos = sector_positions.get("solar.solar", Vector2.ZERO)
	for pid: int in planet_data_by_id:
		var p: Dictionary = planet_data_by_id[pid]
		if p.get("es_canonico", false) and str(p["nombre"]) == "Terra":
			terra_pos = planet_positions.get(pid, terra_pos)
			break
	eye_of_terror_pos = Vector2(-800.0, -2800.0)

# =============================================================================
# POLÍGONOS DE SEGMENTAE
# =============================================================================

func _build_segmentum_polygons() -> void:
	# Solar: círculo central
	var solar_pts: PackedVector2Array = PackedVector2Array()
	for i: int in 32:
		var angle: float = (float(i) / 32.0) * TAU
		solar_pts.append(Vector2(cos(angle), sin(angle)) * SOLAR_RADIUS)
	segmentum_polygons["solar"] = solar_pts
	segmentum_centers["solar"] = Vector2.ZERO
	# Solar: label arriba del círculo central
	segmentum_label_pos["solar"] = Vector2(0.0, -SOLAR_RADIUS - 200.0)

	# Los 4 segmentae exteriores: arcos entre SOLAR_RADIUS y GALAXY_RADIUS
	# Labels bien FUERA del disco galáctico para que no se superpongan
	var outer_label: float = GALAXY_RADIUS + 800.0
	_build_arc_segment("obscurus", deg_to_rad(225.0), deg_to_rad(315.0), Vector2(0.0, -outer_label))
	_build_arc_segment("ultima", deg_to_rad(315.0), deg_to_rad(405.0), Vector2(outer_label + 400.0, 0.0))
	_build_arc_segment("tempestus", deg_to_rad(45.0), deg_to_rad(135.0), Vector2(0.0, outer_label))
	_build_arc_segment("pacificus", deg_to_rad(135.0), deg_to_rad(225.0), Vector2(-outer_label - 400.0, 0.0))

func _build_arc_segment(key: String, angle_start: float, angle_end: float, label_pos: Vector2) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var steps: int = 20

	# Arco exterior
	for i: int in steps + 1:
		var t: float = float(i) / float(steps)
		var angle: float = lerp(angle_start, angle_end, t)
		pts.append(Vector2(cos(angle), sin(angle)) * GALAXY_RADIUS)

	# Arco interior (reverse)
	for i: int in range(steps, -1, -1):
		var t: float = float(i) / float(steps)
		var angle: float = lerp(angle_start, angle_end, t)
		pts.append(Vector2(cos(angle), sin(angle)) * SOLAR_RADIUS * 1.15)

	segmentum_polygons[key] = pts

	# Centro del arco
	var mid_angle: float = (angle_start + angle_end) / 2.0
	var mid_radius: float = (SOLAR_RADIUS + GALAXY_RADIUS) / 2.0
	segmentum_centers[key] = Vector2(cos(mid_angle), sin(mid_angle)) * mid_radius
	segmentum_label_pos[key] = label_pos

# =============================================================================
# GRAN GRIETA (Cicatrix Maledictum)
# =============================================================================

func _build_rift() -> void:
	# Curva irregular del noroeste al este, pasando por el centro
	rift_points.clear()
	var control_points: Array = [
		Vector2(-4500.0, -2000.0),
		Vector2(-2500.0, -1500.0),
		Vector2(-1000.0, -800.0),
		Vector2(0.0, -300.0),
		Vector2(1200.0, 200.0),
		Vector2(2800.0, -100.0),
		Vector2(4500.0, -500.0),
	]

	# Interpolar con Catmull-Rom para suavizar
	for i: int in range(0, control_points.size() - 1):
		var p0: Vector2 = control_points[maxi(i - 1, 0)]
		var p1: Vector2 = control_points[i]
		var p2: Vector2 = control_points[mini(i + 1, control_points.size() - 1)]
		var p3: Vector2 = control_points[mini(i + 2, control_points.size() - 1)]

		for t_step: int in 10:
			var t: float = float(t_step) / 10.0
			var point: Vector2 = _catmull_rom(p0, p1, p2, p3, t)
			rift_points.append(point)

	rift_points.append(control_points[control_points.size() - 1])

func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)

# =============================================================================
# POSICIONES DE SECTORES
# =============================================================================

func _calculate_sector_positions(galaxy: Dictionary) -> void:
	for seg_key: String in galaxy["segmentae"]:
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		var center: Vector2 = segmentum_centers[seg_key]
		var sectores: Dictionary = seg["sectores"]
		var sec_keys: Array = sectores.keys()
		var count: int = sec_keys.size()

		for i: int in count:
			var sec_key: String = str(sec_keys[i])
			var full_key: String = seg_key + "." + sec_key

			# Distribuir sectores en un patrón circular alrededor del centro del segmentum
			var angle: float = (float(i) / float(count)) * TAU + _rng.randf_range(-0.2, 0.2)
			var dist: float = 400.0 + _rng.randf_range(0.0, 300.0)

			if seg_key == "solar":
				dist = 300.0 + _rng.randf_range(0.0, 200.0)

			var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist
			sector_positions[full_key] = pos

			# Radio del sector: proporcional a la cantidad de planetas
			var planet_count: int = 0
			var sec: Dictionary = sectores[sec_key]
			var sub_dict: Dictionary = sec["subsectores"]
			for sub_key: String in sub_dict:
				var sub: Dictionary = sub_dict[sub_key]
				var planetas: Array = sub["planetas"]
				planet_count += planetas.size()
			sector_radii[full_key] = 150.0 + float(planet_count) * 1.5

# =============================================================================
# POSICIONES DE SUBSECTORES
# =============================================================================

func _calculate_subsector_positions(galaxy: Dictionary) -> void:
	for seg_key: String in galaxy["segmentae"]:
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		for sec_key: String in seg["sectores"]:
			var sec: Dictionary = seg["sectores"][sec_key]
			var full_sec: String = seg_key + "." + sec_key
			var sec_center: Vector2 = sector_positions[full_sec]
			var sec_radius: float = float(sector_radii[full_sec])

			var sub_dict: Dictionary = sec["subsectores"]
			var sub_keys: Array = sub_dict.keys()
			var count: int = sub_keys.size()

			for i: int in count:
				var sub_key: String = str(sub_keys[i])
				var full_sub: String = full_sec + "." + sub_key

				var angle: float = (float(i) / float(count)) * TAU + _rng.randf_range(-0.3, 0.3)
				var dist: float = sec_radius * 0.35 + _rng.randf_range(0.0, sec_radius * 0.3)
				var pos: Vector2 = sec_center + Vector2(cos(angle), sin(angle)) * dist
				subsector_positions[full_sub] = pos

# =============================================================================
# POSICIONES DE PLANETAS
# =============================================================================

func _calculate_planet_positions(galaxy: Dictionary) -> void:
	for seg_key: String in galaxy["segmentae"]:
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		for sec_key: String in seg["sectores"]:
			var sec: Dictionary = seg["sectores"][sec_key]
			var full_sec: String = seg_key + "." + sec_key

			var sub_dict: Dictionary = sec["subsectores"]
			for sub_key: String in sub_dict:
				var sub: Dictionary = sub_dict[sub_key]
				var full_sub: String = full_sec + "." + sub_key
				var sub_center: Vector2 = subsector_positions[full_sub]
				var planetas: Array = sub["planetas"]

				for p_idx: int in planetas.size():
					var planet: Dictionary = planetas[p_idx]
					var pid: int = int(planet["id"])

					# Scatter alrededor del centro del subsector
					var angle: float = _rng.randf_range(0.0, TAU)
					var dist: float = _rng.randf_range(5.0, 80.0)
					var pos: Vector2 = sub_center + Vector2(cos(angle), sin(angle)) * dist

					# Terra: en el centro de su subsector (Sol), no aislada
					if planet.get("es_canonico", false) and str(planet["nombre"]) == "Terra":
						pos = sub_center

					planet_positions[pid] = pos
					planet_data_by_id[pid] = planet

# =============================================================================
# UTILIDADES DE CONSULTA
# =============================================================================

func get_planet_color(tipo: String) -> Color:
	return PLANET_COLORS.get(tipo, Color(0.6, 0.6, 0.6, 0.7))

func get_planet_radius(planet: Dictionary) -> float:
	# Tamaño sutil según tipo (la diferencia es mínima)
	var tipo: String = str(planet["tipo"])
	match tipo:
		"hive_world": return 4.0
		"forge_world": return 3.5
		"fortress_world": return 3.5
		"cardinal_world": return 3.0
		"dead_world": return 1.5
		"cemetery_world": return 1.5
		"research_station": return 1.5
		_: return 2.5

func find_planet_at(world_pos: Vector2, sector_key: String, galaxy: Dictionary, threshold: float = 15.0) -> Dictionary:
	# Buscar planeta más cercano al punto dado, solo en el sector visible
	var best_dist: float = threshold
	var best_planet: Dictionary = {}
	var parts: PackedStringArray = sector_key.split(".")
	if parts.size() < 2:
		return best_planet

	var seg_key: String = parts[0]
	var sec_key: String = parts[1]

	if not galaxy["segmentae"].has(seg_key):
		return best_planet
	var seg: Dictionary = galaxy["segmentae"][seg_key]
	if not seg["sectores"].has(sec_key):
		return best_planet
	var sec: Dictionary = seg["sectores"][sec_key]
	var sub_dict: Dictionary = sec["subsectores"]

	for sub_key: String in sub_dict:
		var sub: Dictionary = sub_dict[sub_key]
		var planetas: Array = sub["planetas"]
		for p_idx: int in planetas.size():
			var p: Dictionary = planetas[p_idx]
			var pid: int = int(p["id"])
			if planet_positions.has(pid):
				var pos: Vector2 = planet_positions[pid]
				var dist: float = world_pos.distance_to(pos)
				if dist < best_dist:
					best_dist = dist
					best_planet = p
	return best_planet

func find_segmentum_at(world_pos: Vector2) -> String:
	# Determinar en qué segmentum está un punto
	var dist_to_center: float = world_pos.length()
	if dist_to_center < SOLAR_RADIUS:
		return "solar"

	var angle: float = world_pos.angle()
	# Convertir a 0-TAU
	if angle < 0.0:
		angle += TAU

	# Obscurus: ~225° a ~315° (3.93 a 5.50 rad) -> en Godot: norte = -Y
	# Usando atan2 donde arriba (norte) es -Y = angle ~ -PI/2
	# Simplificamos: basado en qué cuadrante
	if world_pos.y < 0.0 and absf(world_pos.x) < absf(world_pos.y):
		return "obscurus" # Norte
	elif world_pos.x > 0.0 and absf(world_pos.x) > absf(world_pos.y):
		return "ultima" # Este
	elif world_pos.y > 0.0 and absf(world_pos.x) < absf(world_pos.y):
		return "tempestus" # Sur
	else:
		return "pacificus" # Oeste

func find_sector_at(world_pos: Vector2, seg_key: String) -> String:
	var best_dist: float = INF
	var best_key: String = ""
	for full_key: String in sector_positions:
		if full_key.begins_with(seg_key + "."):
			var pos: Vector2 = sector_positions[full_key]
			var dist: float = world_pos.distance_to(pos)
			if dist < best_dist:
				best_dist = dist
				best_key = full_key
	return best_key
