## fleet_generator.gd - Genera Battlefleets, flotas de transporte, y rutas warp
class_name FleetGenerator

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _next_fleet_id: int = 300000
var _next_route_id: int = 400000

func generate(galaxy: Dictionary, seed_value: int = 42) -> Dictionary:
	rng.seed = seed_value + 5555

	var result: Dictionary = {
		"battlefleets": [],
		"transport_fleets": [],
		"mechanicus_fleets": [],
		"rogue_trader_fleets": [],
		"enemy_fleets": [],
		"warp_routes": [],
		"fleets_in_transit": [],
		"navigators_available": 0,
		"navigators_total": 0,
	}

	_generate_battlefleets(galaxy, result)
	_generate_transport_fleets(result)
	_generate_mechanicus_fleets(galaxy, result)
	_generate_rogue_trader_fleets(result)
	_generate_warp_routes(galaxy, result)
	_generate_navigators(result)

	return result

# =============================================================================
# BATTLEFLEETS (1 por sector)
# =============================================================================

func _generate_battlefleets(galaxy: Dictionary, result: Dictionary) -> void:
	for seg_key: String in galaxy["segmentae"]:
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		for sec_key: String in seg["sectores"]:
			var sec: Dictionary = seg["sectores"][sec_key]
			var full_key: String = seg_key + "." + sec_key
			var sec_name: String = str(sec["nombre"])

			# Determinar tamaño
			var size: String = "medio"
			if sec_key in FleetData.LARGE_FLEET_SECTORS:
				size = "grande"
			elif rng.randf() < 0.3:
				size = "pequeño"

			var tmpl: Dictionary = FleetData.BATTLEFLEET_TEMPLATES[size]
			var adm_idx: int = rng.randi_range(0, FleetData.ADMIRAL_NAMES.size() - 1)

			# Buscar planeta base (primer planeta del sector con militar alto)
			var base_id: int = -1
			var sub_dict: Dictionary = sec["subsectores"]
			for sub_key: String in sub_dict:
				var sub: Dictionary = sub_dict[sub_key]
				var planetas: Array = sub["planetas"]
				for p: Dictionary in planetas:
					if int(p["capacidad_militar"]) > 50 and base_id < 0:
						base_id = int(p["id"])

			result["battlefleets"].append({
				"id": _next_fleet_id,
				"nombre": "Battlefleet " + sec_name.replace("Sector ", ""),
				"admiral": "Lord Admiral " + str(FleetData.ADMIRAL_NAMES[adm_idx]),
				"sector": full_key,
				"base_planeta_id": base_id,
				"naves_capital": rng.randi_range(int(tmpl["naves_capital"][0]), int(tmpl["naves_capital"][1])),
				"cruceros": rng.randi_range(int(tmpl["cruceros"][0]), int(tmpl["cruceros"][1])),
				"escoltas": rng.randi_range(int(tmpl["escoltas"][0]), int(tmpl["escoltas"][1])),
				"estado": "patrulla",
				"moral": rng.randi_range(50, 85),
				"experiencia": rng.randi_range(30, 75),
			})
			_next_fleet_id += 1

# =============================================================================
# FLOTAS DE TRANSPORTE
# =============================================================================

func _generate_transport_fleets(result: Dictionary) -> void:
	var count: int = rng.randi_range(30, 50)
	for i: int in count:
		var tipo: String = "chartist" if rng.randf() < 0.6 else "free_trader"
		var des_idx: int = i % FleetData.CONVOY_DESIGNATIONS.size()
		var designation: String = str(FleetData.CONVOY_DESIGNATIONS[des_idx])

		result["transport_fleets"].append({
			"id": _next_fleet_id,
			"nombre": "Convoy %s-%s" % [designation, _roman(i / FleetData.CONVOY_DESIGNATIONS.size() + 1)],
			"tipo": tipo,
			"capacidad_tropas": rng.randi_range(2, 8) if tipo == "chartist" else rng.randi_range(1, 4),
			"capacidad_carga": rng.randi_range(5000, 20000) if tipo == "chartist" else rng.randi_range(2000, 8000),
			"estado": "disponible",
			"origen_id": -1,
			"destino_id": -1,
			"eta_turno": -1,
			"carga": {},
		})
		_next_fleet_id += 1

# =============================================================================
# RUTAS WARP
# =============================================================================

func _generate_warp_routes(galaxy: Dictionary, result: Dictionary) -> void:
	# Recopilar todos los sectores con su key
	var sector_keys: Array = []
	for seg_key: String in galaxy["segmentae"]:
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		for sec_key: String in seg["sectores"]:
			sector_keys.append(seg_key + "." + sec_key)

	# Rutas principales: entre sectores del mismo segmentum
	for seg_key: String in galaxy["segmentae"]:
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		var sec_keys: Array = seg["sectores"].keys()
		for i: int in sec_keys.size():
			for j: int in range(i + 1, sec_keys.size()):
				var key_a: String = seg_key + "." + str(sec_keys[i])
				var key_b: String = seg_key + "." + str(sec_keys[j])
				var tipo: String = "principal" if rng.randf() < 0.4 else "secundaria"
				_add_route(result, key_a, key_b, tipo)

	# Rutas entre segmentums adyacentes (Solar conecta con todos)
	var adjacencies: Array = [
		["solar", "obscurus"], ["solar", "ultima"],
		["solar", "tempestus"], ["solar", "pacificus"],
		["obscurus", "pacificus"], ["ultima", "tempestus"],
	]
	for adj: Array in adjacencies:
		var seg_a: String = str(adj[0])
		var seg_b: String = str(adj[1])
		if not galaxy["segmentae"].has(seg_a) or not galaxy["segmentae"].has(seg_b):
			continue
		var keys_a: Array = galaxy["segmentae"][seg_a]["sectores"].keys()
		var keys_b: Array = galaxy["segmentae"][seg_b]["sectores"].keys()
		if keys_a.is_empty() or keys_b.is_empty():
			continue
		# 1-2 rutas entre segmentums
		var routes_count: int = rng.randi_range(1, 2)
		for _r: int in routes_count:
			var ka: String = seg_a + "." + str(keys_a[rng.randi_range(0, keys_a.size() - 1)])
			var kb: String = seg_b + "." + str(keys_b[rng.randi_range(0, keys_b.size() - 1)])
			_add_route(result, ka, kb, "principal")

func _add_route(result: Dictionary, sector_a: String, sector_b: String, tipo: String) -> void:
	var estabilidad: int = rng.randi_range(40, 90)
	if tipo == "principal":
		estabilidad = rng.randi_range(60, 95)
	elif tipo == "menor":
		estabilidad = rng.randi_range(20, 60)

	result["warp_routes"].append({
		"id": _next_route_id,
		"sector_a": sector_a,
		"sector_b": sector_b,
		"tipo": tipo,
		"estabilidad": estabilidad,
		"peligrosidad_piratas": rng.randi_range(5, 40),
		"tiempo_base_turnos": rng.randi_range(2, 8),
	})
	_next_route_id += 1

# =============================================================================
# FLOTAS MECHANICUS
# =============================================================================

func _generate_mechanicus_fleets(galaxy: Dictionary, result: Dictionary) -> void:
	var planetas: Array = galaxy.get("planetas", [])
	for p: Dictionary in planetas:
		if str(p["tipo"]) != "forge_world":
			continue
		var tmpl: Dictionary = FleetData.MECHANICUS_FLEET_TEMPLATE
		result["mechanicus_fleets"].append({
			"id": _next_fleet_id,
			"nombre": "Explorator Fleet " + str(p["nombre"]),
			"forge_world": str(p["nombre"]),
			"forge_world_id": int(p["id"]),
			"segmentum": str(p["segmentum"]),
			"ark_mechanicus": int(tmpl["ark_mechanicus"]),
			"cruisers": rng.randi_range(int(tmpl["cruisers"][0]), int(tmpl["cruisers"][1])),
			"escorts": rng.randi_range(int(tmpl["escorts"][0]), int(tmpl["escorts"][1])),
			"estado": "exploración" if rng.randf() < 0.3 else "estacionada",
		})
		_next_fleet_id += 1

# =============================================================================
# FLOTAS ROGUE TRADER
# =============================================================================

func _generate_rogue_trader_fleets(result: Dictionary) -> void:
	# Leer dinastías del GameData
	var gd: Node = Engine.get_main_loop().root.get_node_or_null("GameData")
	if gd == null:
		return
	var traders: Array = gd.rogue_traders
	for rt: Dictionary in traders:
		var naves: int = int(rt.get("flota_naves", rng.randi_range(3, 12)))
		result["rogue_trader_fleets"].append({
			"id": _next_fleet_id,
			"nombre": "Flota " + str(rt["nombre"]),
			"dinastia": str(rt["nombre"]),
			"naves": naves,
			"estado": "comercio" if rng.randf() < 0.5 else "exploración",
			"segmentum": "pacificus" if rng.randf() < 0.6 else "ultima",
		})
		_next_fleet_id += 1

# =============================================================================
# NAVEGANTES
# =============================================================================

func _generate_navigators(result: Dictionary) -> void:
	# Pool global de Navegantes disponibles para contratación
	var total: int = rng.randi_range(80, 150)
	result["navigators_total"] = total
	result["navigators_available"] = total # Todos disponibles al inicio

func _roman(n: int) -> String:
	match n:
		1: return "I"
		2: return "II"
		3: return "III"
		4: return "IV"
		_: return str(n)
