## galaxy_data_provider.gd - Calcula posiciones de toda la galaxia
## Posiciones basadas en el mapa canónico de W40K (8va edición GW)
## Coordenadas: 0°=norte(arriba), 90°=este(derecha), sentido horario en el mapa
## En Godot: convertimos con _map_to_world(map_degrees, radius_fraction)
class_name GalaxyDataProvider

# Espacio total de la galaxia
var GALAXY_DISC_RADIUS: float = 4800.0 # Radio del disco visual desde el centro galáctico (0,0)
var SOLAR_RADIUS: float = 600.0 # Radio del Segmentum Solar alrededor de Terra
var MAP_RADIUS: float = 4500.0 # Radio fijo para posicionar elementos canónicos desde Terra

# Terra desplazada al oeste del centro galáctico (~26,000 ly en la realidad)
var TERRA_OFFSET: Vector2 = Vector2(-1300.0, 230.0)

# Rangos angulares CANÓNICOS de cada segmentum (en grados Godot, NO grados del mapa)
# Conversión: godot_deg = map_deg - 90
# Obscurus: map 315°-45° → godot 225°-315° (norte, 90° arco)
# Ultima: map 45°-200° → godot 315°-470° (este, 155° arco, EL MÁS GRANDE)
# Tempestus: map 200°-270° → godot 110°-180° (sur-suroeste, 70° arco)
# Pacificus: map 270°-315° → godot 180°-225° (oeste-noroeste, 45° arco)
# Datos leídos de archivos centralizados (se inicializan en _init)
var SEG_ARCS: Dictionary = {}
var SEG_COLORS: Dictionary = {}
var PLANET_COLORS: Dictionary = {}

func _init() -> void:
	SEG_ARCS = GalaxyConfig.SEG_ARCS
	SEG_COLORS = GalaxyConfig.SEG_COLORS
	PLANET_COLORS = PlanetTypes.COLORS
	GALAXY_DISC_RADIUS = GalaxyConfig.GALAXY_DISC_RADIUS
	SOLAR_RADIUS = GalaxyConfig.SOLAR_RADIUS
	MAP_RADIUS = GalaxyConfig.MAP_RADIUS
	TERRA_OFFSET = GalaxyConfig.TERRA_OFFSET
	astronomican_radius = GalaxyConfig.ASTRONOMICAN_RADIUS

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
	# Posiciona elementos canónicos usando RADIO FIJO desde Terra
	# (la distorsión por disco asimétrico solo afecta a los polígonos de segmentae)
	var godot_rad: float = deg_to_rad(map_degrees - 90.0)
	var pos_from_terra: Vector2 = Vector2(cos(godot_rad), sin(godot_rad)) * (radius_fraction * MAP_RADIUS)
	return TERRA_OFFSET + pos_from_terra

# Calcula la distancia desde Terra al borde del disco galáctico en un ángulo dado
# Intersección rayo-círculo: rayo desde TERRA_OFFSET en dirección angle_rad
# con el círculo de radio GALAXY_DISC_RADIUS centrado en (0,0)
func _terra_to_disc_edge(angle_rad: float) -> float:
	var dir: Vector2 = Vector2(cos(angle_rad), sin(angle_rad))
	var p_dot_d: float = TERRA_OFFSET.dot(dir)
	var p_sq: float = TERRA_OFFSET.length_squared()
	var r_sq: float = GALAXY_DISC_RADIUS * GALAXY_DISC_RADIUS
	var discriminant: float = p_dot_d * p_dot_d - p_sq + r_sq
	if discriminant < 0.0:
		return 3000.0 # Fallback
	return -p_dot_d + sqrt(discriminant)

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
	terra_pos = sector_positions.get("solar.solar", TERRA_OFFSET)
	for pid: int in planet_data_by_id:
		var p: Dictionary = planet_data_by_id[pid]
		if p.get("es_canonico", false) and str(p["nombre"]) == "Terra":
			terra_pos = planet_positions.get(pid, terra_pos)
			break

	# Posiciones canónicas
	eye_of_terror_pos = _map_to_world(325.0, 0.60)

	_build_warp_storms()
	_build_enemy_territories()
	_build_hive_fleet_vectors()

	ultramar_center = sector_positions.get("ultima.ultramar", _map_to_world(120.0, 0.70))
	ultramar_radius = float(sector_radii.get("ultima.ultramar", 300.0)) * 1.3

# =============================================================================
# POLÍGONOS DE SEGMENTAE (proporciones canónicas)
# =============================================================================

func _build_segmentum_polygons() -> void:
	# Solar: círculo central alrededor de Terra
	var solar_pts: PackedVector2Array = PackedVector2Array()
	for i: int in 32:
		var angle: float = (float(i) / 32.0) * TAU
		solar_pts.append(TERRA_OFFSET + Vector2(cos(angle), sin(angle)) * SOLAR_RADIUS)
	segmentum_polygons["solar"] = solar_pts
	segmentum_centers["solar"] = TERRA_OFFSET
	segmentum_label_pos["solar"] = TERRA_OFFSET + Vector2(0.0, -SOLAR_RADIUS - 250.0)

	# Segmentae exteriores: desde SOLAR_RADIUS hasta el BORDE DEL DISCO GALÁCTICO
	# El radio exterior VARÍA según la dirección (porque Terra no está en el centro)
	for seg_key: String in GalaxyConfig.SEG_ARCS:
		var arc_data: Dictionary = SEG_ARCS[seg_key]
		var a_start: float = deg_to_rad(float(arc_data["start"]))
		var a_end: float = deg_to_rad(float(arc_data["end"]))

		var pts: PackedVector2Array = PackedVector2Array()
		var steps: int = 32

		# Arco exterior: sigue el borde del disco galáctico (radio variable)
		for i: int in steps + 1:
			var t: float = float(i) / float(steps)
			var angle: float = lerpf(a_start, a_end, t)
			var edge_dist: float = _terra_to_disc_edge(angle)
			pts.append(TERRA_OFFSET + Vector2(cos(angle), sin(angle)) * edge_dist)

		# Arco interior: borde del Solar (radio fijo)
		for i: int in range(steps, -1, -1):
			var t: float = float(i) / float(steps)
			var angle: float = lerpf(a_start, a_end, t)
			pts.append(TERRA_OFFSET + Vector2(cos(angle), sin(angle)) * SOLAR_RADIUS * 1.05)

		segmentum_polygons[seg_key] = pts

		# Centro del arco (a mitad de camino entre Solar y borde del disco)
		var mid_angle: float = (a_start + a_end) / 2.0
		var mid_edge: float = _terra_to_disc_edge(mid_angle)
		var mid_radius: float = (SOLAR_RADIUS + mid_edge) / 2.0
		segmentum_centers[seg_key] = TERRA_OFFSET + Vector2(cos(mid_angle), sin(mid_angle)) * mid_radius

		# Label FUERA del disco en esa dirección
		var label_dist: float = mid_edge + 400.0
		segmentum_label_pos[seg_key] = TERRA_OFFSET + Vector2(cos(mid_angle), sin(mid_angle)) * label_dist

# =============================================================================
# GRAN GRIETA — Trayectoria canónica
# =============================================================================

func _build_rift() -> void:
	rift_points.clear()
	# Cicatrix Maledictum: Eye of Terror (NW) → Hadex Anomaly (E)
	# Pasa al NORTE de Terra, bien separada (~15% del radio galáctico)
	# En el mapa canónico cruza el tercio superior de la galaxia
	var control_points: Array = [
		_map_to_world(320.0, 0.75), # Origen: Ojo del Terror (NW)
		_map_to_world(335.0, 0.58), # Corredor de Nachmund
		_map_to_world(350.0, 0.40), # Norte de Solar
		_map_to_world(5.0, 0.28),   # Pasa al norte de Terra
		_map_to_world(20.0, 0.22),  # Punto más cercano a Terra (aún al norte)
		_map_to_world(40.0, 0.30),  # Entra en Ultima norte
		_map_to_world(55.0, 0.40),  # Norte de Ultima
		_map_to_world(70.0, 0.52),  # Se ensancha hacia el este
		_map_to_world(80.0, 0.65),  # Eastern Fringe
		_map_to_world(90.0, 0.80),  # Cerca del T'au
		_map_to_world(95.0, 0.95),  # Terminus: Hadex Anomaly (borde E)
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
	# Buscar datos de la jerarquía original para map_pos
	var hierarchy: Dictionary = GalaxyConfig.SECTOR_CONFIG

	for seg_key: String in galaxy["segmentae"]:
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		var sectores: Dictionary = seg["sectores"]
		var sec_keys: Array = sectores.keys()
		var count: int = sec_keys.size()

		for i: int in count:
			var sec_key: String = str(sec_keys[i])
			var full_key: String = seg_key + "." + sec_key

			# Buscar si el sector tiene posición canónica definida (map_pos)
			var has_map_pos: bool = false
			if hierarchy.has(seg_key):
				var h_seg: Dictionary = hierarchy[seg_key]
				if h_seg.has(sec_key):
					var h_sec: Dictionary = h_seg[sec_key]
					if h_sec.has("map_pos"):
						var mp: Array = h_sec["map_pos"]
						var jitter: Vector2 = Vector2(_rng.randf_range(-60.0, 60.0), _rng.randf_range(-60.0, 60.0))
						sector_positions[full_key] = _map_to_world(float(mp[0]), float(mp[1])) + jitter
						has_map_pos = true

			if not has_map_pos:
				if seg_key == "solar":
					# Solar: sectores en círculo alrededor de Terra
					var angle: float = (float(i) / float(count)) * TAU + _rng.randf_range(-0.15, 0.15)
					var dist: float = 350.0 + _rng.randf_range(-50.0, 80.0)
					sector_positions[full_key] = TERRA_OFFSET + Vector2(cos(angle), sin(angle)) * dist
				else:
					# Algoritmo genérico para sectores sin map_pos
					var arc: Dictionary = SEG_ARCS[seg_key]
					var a_start_deg: float = float(arc["start"])
					var a_end_deg: float = float(arc["end"])
					var margin_deg: float = float(arc["arc"]) * 0.08
					var t: float = (float(i) + 0.5) / float(count)
					var angle_deg: float = lerpf(a_start_deg + margin_deg, a_end_deg - margin_deg, t)
					var angle_rad: float = deg_to_rad(angle_deg + _rng.randf_range(-3.0, 3.0))
					var edge_dist: float = _terra_to_disc_edge(angle_rad)
					var dist: float = lerpf(SOLAR_RADIUS * 1.3, edge_dist * 0.80, 0.2 + t * 0.55)
					dist += _rng.randf_range(-100.0, 100.0)
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

	# Behemoth: viene del ESTE puro (map 90°), directo a Ultramar (map 120°, 0.70)
	# Primer contacto en 745.M41, destruida en la Batalla de Macragge
	hive_fleet_vectors.append({
		"nombre": "HIVE FLEET\nBEHEMOTH",
		"points": PackedVector2Array([
			_map_to_world(95.0, 1.20),  # Fuera de la galaxia, este
			_map_to_world(95.0, 1.00),  # Borde galáctico este
			_map_to_world(100.0, 0.85), # Eastern Fringe
			_map_to_world(110.0, 0.75), # Hacia Ultramar
			_map_to_world(118.0, 0.70), # Macragge
		]),
		"color": Color(0.8, 0.1, 0.45, 0.55),
		"status": "DESTRUIDA",
	})

	# Kraken: viene del SURESTE (map ~140°), se dispersa en múltiples tendriles
	# Segundo contacto en 992.M41, fragmentada pero activa
	hive_fleet_vectors.append({
		"nombre": "HIVE FLEET\nKRAKEN",
		"points": PackedVector2Array([
			_map_to_world(140.0, 1.20),  # Fuera de la galaxia, SE
			_map_to_world(138.0, 1.00),  # Borde galáctico SE
			_map_to_world(130.0, 0.80),  # Penetra el Eastern Fringe
			_map_to_world(120.0, 0.60),  # Se dispersa
			_map_to_world(110.0, 0.45),  # Hacia el interior
		]),
		"color": Color(0.6, 0.15, 0.55, 0.50),
		"status": "FRAGMENTADA",
	})

	# Leviathan: viene del SUR (map ~180°), ataque en tenaza desde abajo
	# del plano galáctico. La más peligrosa, sigue ACTIVA
	hive_fleet_vectors.append({
		"nombre": "HIVE FLEET\nLEVIATHAN",
		"points": PackedVector2Array([
			_map_to_world(185.0, 1.20),  # Debajo del plano galáctico
			_map_to_world(183.0, 1.00),  # Borde sur
			_map_to_world(178.0, 0.80),  # Penetra por el sur
			_map_to_world(170.0, 0.60),  # Avanza al norte
			_map_to_world(160.0, 0.40),  # Interior de Ultima sur
		]),
		"color": Color(0.85, 0.15, 0.2, 0.60),
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

	for seg_key: String in GalaxyConfig.SEG_ARCS:
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
