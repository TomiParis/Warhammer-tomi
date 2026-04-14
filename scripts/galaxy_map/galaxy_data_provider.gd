## galaxy_data_provider.gd - Calcula posiciones de toda la galaxia
## Posiciones basadas en el mapa canónico de W40K (8va edición GW)
## Coordenadas: 0°=norte(arriba), 90°=este(derecha), sentido horario en el mapa
## En Godot: convertimos con _map_to_world(map_degrees, radius_fraction)
class_name GalaxyDataProvider

# Espacio total de la galaxia
const GALAXY_RADIUS: float = 4500.0
const SOLAR_RADIUS: float = 700.0 # Solar es pequeño (~5% del área)

# Terra NO está en el centro galáctico. Está desplazada al oeste.
# El centro galáctico real está a ~30% del radio, dirección map ~100° (este-sureste)
# Invertimos: Terra está desplazada DESDE el centro galáctico
# map 100° desde centro → godot deg_to_rad(100-90)=deg_to_rad(10) → esa es la dir del centro desde Terra
# Entonces Terra está en la dirección OPUESTA: deg_to_rad(10+180)=deg_to_rad(190)
const TERRA_OFFSET: Vector2 = Vector2(-1300.0, 230.0) # Terra al oeste del centro galáctico

# Rangos angulares CANÓNICOS de cada segmentum (en grados Godot, NO grados del mapa)
# Conversión: godot_deg = map_deg - 90
# Obscurus: map 315°-45° → godot 225°-315° (norte, 90° arco)
# Ultima: map 45°-200° → godot 315°-470° (este, 155° arco, EL MÁS GRANDE)
# Tempestus: map 200°-270° → godot 110°-180° (sur-suroeste, 70° arco)
# Pacificus: map 270°-315° → godot 180°-225° (oeste-noroeste, 45° arco)
const SEG_ARCS: Dictionary = {
	"obscurus":  {"start": 225.0, "end": 315.0, "arc": 90.0},
	"ultima":    {"start": 315.0, "end": 470.0, "arc": 155.0}, # 470 = 315+155, wraps past 360
	"tempestus": {"start": 110.0, "end": 180.0, "arc": 70.0},
	"pacificus": {"start": 180.0, "end": 225.0, "arc": 45.0},
}

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
var segmentum_polygons: Dictionary = {}
var segmentum_centers: Dictionary = {}
var segmentum_label_pos: Dictionary = {}

var sector_positions: Dictionary = {}
var sector_radii: Dictionary = {}
var subsector_positions: Dictionary = {}
var planet_positions: Dictionary = {}
var planet_data_by_id: Dictionary = {}

var rift_points: PackedVector2Array = PackedVector2Array()
var eye_of_terror_pos: Vector2 = Vector2.ZERO
var terra_pos: Vector2 = Vector2.ZERO
var astronomican_radius: float = 3800.0

var warp_storms: Array = []
var enemy_territories: Array = []
var hive_fleet_vectors: Array = []
var ultramar_center: Vector2 = Vector2.ZERO
var ultramar_radius: float = 350.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# =============================================================================
# CONVERSIÓN DE COORDENADAS
# =============================================================================
# map_degrees: 0°=norte, 90°=este, 180°=sur, 270°=oeste (sentido horario)
# radius_fraction: 0.0=centro, 1.0=borde de la galaxia

func _map_to_world(map_degrees: float, radius_fraction: float) -> Vector2:
	# Las coordenadas del mapa canónico son relativas a Terra
	# Desplazamos para que el centro del espacio sea el centro galáctico real
	var godot_rad: float = deg_to_rad(map_degrees - 90.0)
	var pos_from_terra: Vector2 = Vector2(cos(godot_rad), sin(godot_rad)) * (radius_fraction * GALAXY_RADIUS)
	return TERRA_OFFSET + pos_from_terra

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

	# Terra: buscar en planetas generados
	terra_pos = sector_positions.get("solar.solar", Vector2.ZERO)
	for pid: int in planet_data_by_id:
		var p: Dictionary = planet_data_by_id[pid]
		if p.get("es_canonico", false) and str(p["nombre"]) == "Terra":
			terra_pos = planet_positions.get(pid, terra_pos)
			break

	# Posiciones canónicas
	eye_of_terror_pos = _map_to_world(325.0, 0.65)

	_build_warp_storms()
	_build_enemy_territories()
	_build_hive_fleet_vectors()

	ultramar_center = sector_positions.get("ultima.ultramar", _map_to_world(120.0, 0.70))
	ultramar_radius = float(sector_radii.get("ultima.ultramar", 300.0)) * 1.3

# =============================================================================
# POLÍGONOS DE SEGMENTAE (proporciones canónicas)
# =============================================================================

func _build_segmentum_polygons() -> void:
	# Los segmentae son regiones centradas en TERRA (no en el centro galáctico)
	# Los polígonos se construyen alrededor de TERRA_OFFSET

	# Solar: círculo central pequeño alrededor de Terra
	var solar_pts: PackedVector2Array = PackedVector2Array()
	for i: int in 32:
		var angle: float = (float(i) / 32.0) * TAU
		solar_pts.append(TERRA_OFFSET + Vector2(cos(angle), sin(angle)) * SOLAR_RADIUS)
	segmentum_polygons["solar"] = solar_pts
	segmentum_centers["solar"] = TERRA_OFFSET
	segmentum_label_pos["solar"] = TERRA_OFFSET + Vector2(0.0, -SOLAR_RADIUS - 300.0)

	# Segmentae exteriores con tamaños CANÓNICOS, centrados en Terra
	for seg_key: String in SEG_ARCS:
		var arc_data: Dictionary = SEG_ARCS[seg_key]
		var a_start: float = deg_to_rad(float(arc_data["start"]))
		var a_end: float = deg_to_rad(float(arc_data["end"]))

		var pts: PackedVector2Array = PackedVector2Array()
		var steps: int = 24

		# Arco exterior (centrado en Terra)
		for i: int in steps + 1:
			var t: float = float(i) / float(steps)
			var angle: float = lerpf(a_start, a_end, t)
			pts.append(TERRA_OFFSET + Vector2(cos(angle), sin(angle)) * GALAXY_RADIUS)

		# Arco interior (reverse)
		for i: int in range(steps, -1, -1):
			var t: float = float(i) / float(steps)
			var angle: float = lerpf(a_start, a_end, t)
			pts.append(TERRA_OFFSET + Vector2(cos(angle), sin(angle)) * SOLAR_RADIUS * 1.1)

		segmentum_polygons[seg_key] = pts

		# Centro del arco
		var mid_angle: float = (a_start + a_end) / 2.0
		var mid_radius: float = (SOLAR_RADIUS + GALAXY_RADIUS) / 2.0
		segmentum_centers[seg_key] = TERRA_OFFSET + Vector2(cos(mid_angle), sin(mid_angle)) * mid_radius

		# Label FUERA del disco
		var label_radius: float = GALAXY_RADIUS + 600.0
		segmentum_label_pos[seg_key] = TERRA_OFFSET + Vector2(cos(mid_angle), sin(mid_angle)) * label_radius

# =============================================================================
# GRAN GRIETA — Trayectoria canónica
# =============================================================================

func _build_rift() -> void:
	rift_points.clear()
	# Trayectoria canónica: Ojo del Terror (map 325°) → Hadex Anomaly (map 95°)
	# Pasa al NORTE de Terra
	var control_points: Array = [
		_map_to_world(325.0, 0.70), # Origen: cerca del Ojo del Terror
		_map_to_world(340.0, 0.52), # Corredor de Nachmund
		_map_to_world(355.0, 0.35), # Se acerca a Terra por el norte
		_map_to_world(10.0, 0.22),  # Punto más cercano a Terra
		_map_to_world(30.0, 0.30),  # Entra en Ultima
		_map_to_world(50.0, 0.42),  # Norte de Ultima
		_map_to_world(70.0, 0.58),  # Se ensancha
		_map_to_world(85.0, 0.72),  # Cerca del T'au
		_map_to_world(95.0, 0.92),  # Terminus: Hadex Anomaly
	]

	for i: int in range(0, control_points.size() - 1):
		var p0: Vector2 = control_points[maxi(i - 1, 0)]
		var p1: Vector2 = control_points[i]
		var p2: Vector2 = control_points[mini(i + 1, control_points.size() - 1)]
		var p3: Vector2 = control_points[mini(i + 2, control_points.size() - 1)]
		for t_step: int in 10:
			var t: float = float(t_step) / 10.0
			rift_points.append(_catmull_rom(p0, p1, p2, p3, t))
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
# POSICIONES DE SECTORES (dentro de los arcos canónicos)
# =============================================================================

func _calculate_sector_positions(galaxy: Dictionary) -> void:
	# TODOS los sectores se posicionan relativos a TERRA_OFFSET
	# porque los segmentae están centrados en Terra, no en el centro galáctico
	for seg_key: String in galaxy["segmentae"]:
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		var sectores: Dictionary = seg["sectores"]
		var sec_keys: Array = sectores.keys()
		var count: int = sec_keys.size()

		for i: int in count:
			var sec_key: String = str(sec_keys[i])
			var full_key: String = seg_key + "." + sec_key

			if seg_key == "solar":
				# Solar: sectores alrededor de Terra
				var angle: float = (float(i) / float(count)) * TAU + _rng.randf_range(-0.2, 0.2)
				var dist: float = 200.0 + float(i) * 120.0 + _rng.randf_range(-30.0, 30.0)
				sector_positions[full_key] = TERRA_OFFSET + Vector2(cos(angle), sin(angle)) * dist
			else:
				# Segmentae exteriores: dentro de su arco angular canónico, desde Terra
				var arc: Dictionary = SEG_ARCS[seg_key]
				var a_start_deg: float = float(arc["start"])
				var a_end_deg: float = float(arc["end"])

				var margin_deg: float = float(arc["arc"]) * 0.08
				var usable_start: float = a_start_deg + margin_deg
				var usable_end: float = a_end_deg - margin_deg

				var t: float = (float(i) + 0.5) / float(count)
				var angle_deg: float = lerpf(usable_start, usable_end, t) + _rng.randf_range(-3.0, 3.0)
				var angle_rad: float = deg_to_rad(angle_deg)

				var inner: float = SOLAR_RADIUS * 1.4
				var outer: float = GALAXY_RADIUS * 0.82
				var dist: float = lerpf(inner, outer, 0.25 + t * 0.5) + _rng.randf_range(-150.0, 150.0)

				sector_positions[full_key] = TERRA_OFFSET + Vector2(cos(angle_rad), sin(angle_rad)) * dist

			# Radio proporcional a planetas
			var planet_count: int = 0
			var sec: Dictionary = sectores[sec_key]
			var sub_dict: Dictionary = sec["subsectores"]
			for sub_key: String in sub_dict:
				var sub: Dictionary = sub_dict[sub_key]
				var planetas: Array = sub["planetas"]
				planet_count += planetas.size()
			sector_radii[full_key] = 120.0 + float(planet_count) * 1.2

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
				var dist: float = sec_radius * 0.3 + _rng.randf_range(0.0, sec_radius * 0.35)
				subsector_positions[full_sub] = sec_center + Vector2(cos(angle), sin(angle)) * dist

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
					var angle: float = _rng.randf_range(0.0, TAU)
					var dist: float = _rng.randf_range(5.0, 65.0)
					var pos: Vector2 = sub_center + Vector2(cos(angle), sin(angle)) * dist

					if planet.get("es_canonico", false) and str(planet["nombre"]) == "Terra":
						pos = sub_center

					planet_positions[pid] = pos
					planet_data_by_id[pid] = planet

# =============================================================================
# WARP STORMS — posiciones canónicas
# =============================================================================

func _build_warp_storms() -> void:
	warp_storms.clear()
	warp_storms.append({
		"nombre": "The Maelstrom",
		"pos": _map_to_world(110.0, 0.25),
		"radius": 160.0,
		"color": Color(0.7, 0.2, 0.4, 0.4),
	})
	warp_storms.append({
		"nombre": "Hadex Anomaly",
		"pos": _map_to_world(95.0, 0.88),
		"radius": 130.0,
		"color": Color(0.5, 0.15, 0.5, 0.35),
	})
	warp_storms.append({
		"nombre": "Storm of the\nEmperor's Wrath",
		"pos": _map_to_world(230.0, 0.60),
		"radius": 110.0,
		"color": Color(0.6, 0.5, 0.15, 0.3),
	})
	warp_storms.append({
		"nombre": "Screaming Vortex",
		"pos": _map_to_world(310.0, 0.50),
		"radius": 80.0,
		"color": Color(0.6, 0.15, 0.2, 0.3),
	})
	warp_storms.append({
		"nombre": "Ruinstorm\nRemnant",
		"pos": _map_to_world(250.0, 0.40),
		"radius": 90.0,
		"color": Color(0.4, 0.2, 0.5, 0.25),
	})

# =============================================================================
# TERRITORIOS ENEMIGOS — posiciones canónicas
# =============================================================================

func _build_enemy_territories() -> void:
	enemy_territories.clear()

	# Imperio T'au: map 80°, radio 0.80 (Eastern Fringe, norte de Ultramar)
	enemy_territories.append({
		"nombre": "IMPERIO T'AU",
		"center": _map_to_world(80.0, 0.82),
		"radius": 220.0,
		"color": Color(0.2, 0.5, 0.6, 0.10),
		"border_color": Color(0.3, 0.6, 0.7, 0.25),
		"label_color": Color(0.3, 0.6, 0.7, 0.45),
	})

	# Octarius: map 130°, radio 0.50 (guerra Ork vs Tiránidos)
	enemy_territories.append({
		"nombre": "ZONA DE GUERRA\nOCTARIUS",
		"center": _map_to_world(130.0, 0.50),
		"radius": 250.0,
		"color": Color(0.4, 0.5, 0.1, 0.08),
		"border_color": Color(0.5, 0.6, 0.15, 0.20),
		"label_color": Color(0.5, 0.6, 0.15, 0.40),
	})

	# Dinastía Necrona Szarekhan (dispersa en el este)
	enemy_territories.append({
		"nombre": "DYNASTÍA NECRONA\nSZAREKHAN",
		"center": _map_to_world(60.0, 0.55),
		"radius": 180.0,
		"color": Color(0.3, 0.5, 0.3, 0.06),
		"border_color": Color(0.4, 0.7, 0.4, 0.18),
		"label_color": Color(0.4, 0.7, 0.4, 0.35),
	})

	# Dominios Necrones sur
	enemy_territories.append({
		"nombre": "DOMINIOS\nNECRONES",
		"center": _map_to_world(220.0, 0.55),
		"radius": 200.0,
		"color": Color(0.3, 0.5, 0.3, 0.06),
		"border_color": Color(0.4, 0.7, 0.4, 0.18),
		"label_color": Color(0.4, 0.7, 0.4, 0.35),
	})

# =============================================================================
# VECTORES DE HIVE FLEETS — trayectorias canónicas
# =============================================================================

func _build_hive_fleet_vectors() -> void:
	hive_fleet_vectors.clear()

	# Behemoth: desde el este directo a Ultramar (map ~90°, destruida en Macragge)
	var ultramar_pos: Vector2 = _map_to_world(120.0, 0.70)
	hive_fleet_vectors.append({
		"nombre": "HIVE FLEET\nBEHEMOTH",
		"points": PackedVector2Array([
			_map_to_world(90.0, 1.15),
			_map_to_world(95.0, 0.95),
			_map_to_world(105.0, 0.82),
			ultramar_pos + Vector2(200.0, 0.0),
		]),
		"color": Color(0.7, 0.15, 0.5, 0.5),
		"status": "DESTRUIDA",
	})

	# Kraken: desde el sureste, se dispersa (map ~150°)
	hive_fleet_vectors.append({
		"nombre": "HIVE FLEET\nKRAKEN",
		"points": PackedVector2Array([
			_map_to_world(155.0, 1.15),
			_map_to_world(145.0, 0.90),
			_map_to_world(135.0, 0.70),
			_map_to_world(125.0, 0.55),
		]),
		"color": Color(0.6, 0.2, 0.5, 0.5),
		"status": "FRAGMENTADA",
	})

	# Leviathan: desde abajo del plano (sur, map ~190°), la más peligrosa
	hive_fleet_vectors.append({
		"nombre": "HIVE FLEET\nLEVIATHAN",
		"points": PackedVector2Array([
			_map_to_world(195.0, 1.15),
			_map_to_world(190.0, 0.90),
			_map_to_world(180.0, 0.70),
			_map_to_world(165.0, 0.50),
			_map_to_world(150.0, 0.35),
		]),
		"color": Color(0.8, 0.2, 0.3, 0.55),
		"status": "ACTIVA",
	})

# =============================================================================
# UTILIDADES DE CONSULTA
# =============================================================================

func get_planet_color(tipo: String) -> Color:
	return PLANET_COLORS.get(tipo, Color(0.6, 0.6, 0.6, 0.7))

func get_planet_radius(planet: Dictionary) -> float:
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
	# Los segmentae están centrados en TERRA, no en el centro galáctico
	var relative_to_terra: Vector2 = world_pos - TERRA_OFFSET
	var dist_to_terra: float = relative_to_terra.length()

	if dist_to_terra < SOLAR_RADIUS * 1.1:
		return "solar"

	# Ángulo desde Terra en grados Godot
	var angle_rad: float = relative_to_terra.angle()
	var angle_deg: float = rad_to_deg(angle_rad)
	if angle_deg < 0.0:
		angle_deg += 360.0

	for seg_key: String in SEG_ARCS:
		var arc: Dictionary = SEG_ARCS[seg_key]
		var a_start: float = float(arc["start"])
		var a_end: float = float(arc["end"])

		if a_end > 360.0:
			if angle_deg >= a_start or angle_deg <= (a_end - 360.0):
				return seg_key
		else:
			if angle_deg >= a_start and angle_deg <= a_end:
				return seg_key

	return "solar"

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
