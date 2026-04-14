## galaxy_generator.gd - Generador procedural de la galaxia
## Lee toda la configuración de GalaxyConfig y PlanetTypes
## Para expandir: solo cambiar los datos en scripts/data/, NO este archivo
class_name GalaxyGenerator

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _used_names: Dictionary = {}
var _planet_id_counter: int = 0

# =============================================================================
# PUNTO DE ENTRADA
# =============================================================================

func generate_galaxy(seed_value: int = 42) -> Dictionary:
	rng.seed = seed_value
	_used_names.clear()
	_planet_id_counter = 0

	var galaxy: Dictionary = {
		"segmentae": {},
		"planetas": [],
		"stats": {},
	}

	# Paso 1: Construir jerarquía desde la config
	_build_hierarchy(galaxy)

	# Paso 2: Colocar planetas canónicos
	_place_canonical_planets(galaxy)

	# Paso 3: Generar planetas para cada segmentum según su target
	for seg_key: String in GalaxyConfig.SEGMENTUM_CONFIG:
		_fill_segmentum(galaxy, seg_key)

	# Paso 4: Coherencia lore
	_apply_lore_coherence(galaxy)

	# Paso 5: Stats
	galaxy["stats"] = _calculate_stats(galaxy)

	return galaxy

# =============================================================================
# PASO 1: CONSTRUIR JERARQUÍA DESDE CONFIG
# =============================================================================

func _build_hierarchy(galaxy: Dictionary) -> void:
	for seg_key: String in GalaxyConfig.SEGMENTUM_CONFIG:
		var seg_config: Dictionary = GalaxyConfig.SEGMENTUM_CONFIG[seg_key]
		galaxy["segmentae"][seg_key] = {
			"nombre": str(seg_config["nombre"]),
			"sectores": {},
		}

		# Leer sectores de la config
		if not GalaxyConfig.SECTOR_CONFIG.has(seg_key):
			continue
		var sectores_config: Dictionary = GalaxyConfig.SECTOR_CONFIG[seg_key]

		for sec_key: String in sectores_config:
			var sec_config: Dictionary = sectores_config[sec_key]
			galaxy["segmentae"][seg_key]["sectores"][sec_key] = {
				"nombre": str(sec_config["nombre"]),
				"lado_grieta": str(sec_config["lado_grieta"]),
				"subsectores": {},
			}

			var subsectores: Array = sec_config["subsectores"]
			for sub_idx: int in subsectores.size():
				var sub_name: String = str(subsectores[sub_idx])
				var sub_key: String = _make_key(sub_name)
				galaxy["segmentae"][seg_key]["sectores"][sec_key]["subsectores"][sub_key] = {
					"nombre": sub_name,
					"planetas": [],
				}

# =============================================================================
# PASO 2: PLANETAS CANÓNICOS
# =============================================================================

func _place_canonical_planets(galaxy: Dictionary) -> void:
	for canon_idx: int in CanonicalData.PLANETS.size():
		var canon: Dictionary = CanonicalData.PLANETS[canon_idx]
		var seg_key: String = str(canon["segmentum"])
		var sec_key: String = str(canon["sector"])
		var sub_key: String = _make_key(str(canon["subsector"]))

		if not galaxy["segmentae"].has(seg_key):
			continue
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		if not seg["sectores"].has(sec_key):
			continue
		var sec: Dictionary = seg["sectores"][sec_key]
		if not sec["subsectores"].has(sub_key):
			continue

		var planet: Dictionary = _create_canonical_planet(canon, seg_key, sec_key, sub_key)
		sec["subsectores"][sub_key]["planetas"].append(planet)
		galaxy["planetas"].append(planet)
		_used_names[str(canon["nombre"])] = true

# =============================================================================
# PASO 3: GENERAR PLANETAS POR SEGMENTUM
# =============================================================================

func _fill_segmentum(galaxy: Dictionary, seg_key: String) -> void:
	var seg_config: Dictionary = GalaxyConfig.SEGMENTUM_CONFIG[seg_key]
	var target: int = int(seg_config["planetas_target"])
	var type_mods: Dictionary = seg_config.get("type_mods", {})

	# Contar canónicos ya colocados
	var existing: int = _count_segmentum_planets(galaxy, seg_key)
	var remaining: int = maxi(target - existing, 0)

	if remaining <= 0:
		return

	# Construir pool de tipos para este segmentum
	var type_pool: Array = _build_type_pool(remaining, type_mods)

	# Distribuir entre subsectores del segmentum
	var subsectors: Array = _get_subsector_list(galaxy, seg_key)
	if subsectors.is_empty():
		return

	var per_sub: int = maxi(remaining / subsectors.size(), 1)
	var extra: int = remaining % subsectors.size()
	var pool_idx: int = 0

	for sub_info_idx: int in subsectors.size():
		var sub_info: Array = subsectors[sub_info_idx]
		var s_seg: String = sub_info[0]
		var s_sec: String = sub_info[1]
		var s_sub: String = sub_info[2]
		var count: int = per_sub + (1 if sub_info_idx < extra else 0)

		var sec_config: Dictionary = GalaxyConfig.SECTOR_CONFIG[s_seg][s_sec]

		for _i: int in count:
			if pool_idx >= type_pool.size():
				break
			var tipo: String = str(type_pool[pool_idx])
			pool_idx += 1

			var planet: Dictionary = _generate_planet(tipo, s_seg, s_sec, s_sub, sec_config)
			galaxy["segmentae"][s_seg]["sectores"][s_sec]["subsectores"][s_sub]["planetas"].append(planet)
			galaxy["planetas"].append(planet)

func _get_subsector_list(galaxy: Dictionary, seg_key: String) -> Array:
	var result: Array = []
	var seg: Dictionary = galaxy["segmentae"][seg_key]
	for sec_key: String in seg["sectores"]:
		var sec: Dictionary = seg["sectores"][sec_key]
		for sub_key: String in sec["subsectores"]:
			result.append([seg_key, sec_key, sub_key])
	return result

func _count_segmentum_planets(galaxy: Dictionary, seg_key: String) -> int:
	var count: int = 0
	var seg: Dictionary = galaxy["segmentae"][seg_key]
	for sec_key: String in seg["sectores"]:
		var sec: Dictionary = seg["sectores"][sec_key]
		for sub_key: String in sec["subsectores"]:
			var sub: Dictionary = sec["subsectores"][sub_key]
			var planetas: Array = sub["planetas"]
			count += planetas.size()
	return count

# =============================================================================
# POOL DE TIPOS
# =============================================================================

func _build_type_pool(count: int, type_mods: Dictionary) -> Array:
	# Construir pool con pesos escalados por los modificadores del segmentum
	var total_weight: float = 0.0
	var weighted: Array = []

	for tipo: String in PlanetTypes.TYPE_WEIGHTS:
		var base_w: float = float(PlanetTypes.TYPE_WEIGHTS[tipo])
		var mod: float = float(type_mods.get(tipo, 1.0))
		var w: float = base_w * mod
		weighted.append([tipo, w])
		total_weight += w

	# Convertir pesos a cantidades
	var pool: Array = []
	for entry_idx: int in weighted.size():
		var entry: Array = weighted[entry_idx]
		var tipo: String = str(entry[0])
		var w: float = float(entry[1])
		var qty: int = int(round(float(count) * w / total_weight))
		for _j: int in qty:
			pool.append(tipo)

	# Ajustar si el pool no coincide con count
	while pool.size() < count:
		pool.append("civilised_world")
	while pool.size() > count:
		pool.pop_back()

	# Mezclar
	_shuffle_array(pool)
	return pool

# =============================================================================
# GENERACIÓN DE PLANETA INDIVIDUAL
# =============================================================================

func _generate_planet(tipo: String, seg_key: String, sec_key: String, sub_key: String, sec_config: Dictionary) -> Dictionary:
	var type_data: Dictionary = PlanetTypes.TYPES[tipo]
	var lado: String = str(sec_config["lado_grieta"])
	var warp_mod: int = int(sec_config["warp_mod"])

	var nombre: String = _generate_name()
	var poblacion: int = _rand_range_int(int(type_data["poblacion_min"]), int(type_data["poblacion_max"]))

	var industrial: int = _rand_stat(type_data["industrial"])
	var militar: int = _rand_stat(type_data["militar"])
	var lealtad: int = _rand_stat(type_data["lealtad"])
	var fe: int = _rand_stat(type_data["fe"])
	var warp_est: int = clampi(_rand_stat(type_data["warp_estabilidad"]) + warp_mod, 0, 100)

	# Penalización Nihilus
	if lado == "nihilus":
		lealtad = clampi(lealtad - rng.randi_range(5, 15), 0, 100)
		fe = clampi(fe - rng.randi_range(5, 15), 0, 100)
		industrial = clampi(industrial - rng.randi_range(5, 10), 0, 100)
		warp_est = clampi(warp_est - rng.randi_range(10, 20), 0, 100)

	var tithe: String = str(type_data["diezmo_default"])
	var controlador: Dictionary = _generate_controlador(str(type_data["controlador_tipo"]))

	var tiene_astropata: bool = false
	if tipo != "dead_world":
		tiene_astropata = rng.randf() < (0.7 if lado == "sanctus" else 0.3)

	var infiltracion_caos: int = rng.randi_range(0, 10)
	if int(sec_config["amenaza_mod"]) > 50:
		infiltracion_caos += rng.randi_range(5, 20)
	infiltracion_caos = clampi(infiltracion_caos, 0, 100)

	var es_tomb: bool = false
	if PlanetTypes.TOMB_WORLD_DISGUISES.has(tipo) and rng.randf() < PlanetTypes.TOMB_WORLD_CHANCE:
		es_tomb = true

	var planet: Dictionary = {
		"id": _next_id(),
		"nombre": nombre,
		"tipo": tipo,
		"tipo_visible": tipo,
		"segmentum": seg_key,
		"sector": sec_key,
		"subsector": sub_key,
		"poblacion": poblacion,
		"lealtad_imperial": lealtad,
		"fe_imperial": fe,
		"capacidad_industrial": industrial,
		"capacidad_militar": militar,
		"tithe_grade": tithe,
		"guarnicion": {
			"pdf_size": _calc_pdf(poblacion, tipo),
			"guardia_imperial": 0,
			"astartes_presencia": null,
		},
		"controlador": controlador,
		"amenaza_actual": null,
		"ingresos_mensuales": 0,
		"lado_grieta": lado,
		"tiene_astropata": tiene_astropata,
		"estabilidad_warp": warp_est,
		"infiltracion_caos": infiltracion_caos,
		"infiltracion_genestealer": rng.randi_range(0, 5),
		"corrupcion_gobernador": rng.randi_range(0, 20),
		"es_tomb_world": es_tomb,
		"es_canonico": false,
		"flags": [],
	}

	planet["ingresos_mensuales"] = _calc_ingresos(planet)
	return planet

func _create_canonical_planet(data: Dictionary, seg_key: String, sec_key: String, sub_key: String) -> Dictionary:
	var tipo: String = str(data["tipo"])
	var sec_config: Dictionary = GalaxyConfig.SECTOR_CONFIG[seg_key][sec_key]
	var lado: String = str(sec_config["lado_grieta"])
	var overrides: Dictionary = data["overrides"]

	var planet: Dictionary = {
		"id": _next_id(),
		"nombre": str(data["nombre"]),
		"tipo": tipo,
		"tipo_visible": tipo,
		"segmentum": seg_key,
		"sector": sec_key,
		"subsector": sub_key,
		"poblacion": int(data["poblacion"]),
		"lealtad_imperial": int(overrides.get("lealtad_imperial", 50)),
		"fe_imperial": int(overrides.get("fe_imperial", 50)),
		"capacidad_industrial": int(overrides.get("capacidad_industrial", 50)),
		"capacidad_militar": int(overrides.get("capacidad_militar", 50)),
		"tithe_grade": str(data["tithe_grade"]),
		"guarnicion": {
			"pdf_size": _calc_pdf(int(data["poblacion"]), tipo),
			"guardia_imperial": 0,
			"astartes_presencia": data.get("astartes"),
		},
		"controlador": data.get("controlador", {"tipo": "gobernador_planetario", "nombre": "Desconocido"}),
		"amenaza_actual": null,
		"ingresos_mensuales": 0,
		"lado_grieta": lado,
		"tiene_astropata": true,
		"estabilidad_warp": int(overrides.get("estabilidad_warp", 50)),
		"infiltracion_caos": 0,
		"infiltracion_genestealer": 0,
		"corrupcion_gobernador": 0,
		"es_tomb_world": false,
		"es_canonico": true,
		"flags": data.get("flags", []),
	}

	planet["ingresos_mensuales"] = _calc_ingresos(planet)
	return planet

# =============================================================================
# COHERENCIA LORE
# =============================================================================

func _apply_lore_coherence(galaxy: Dictionary) -> void:
	for seg_key: String in galaxy["segmentae"]:
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		for sec_key: String in seg["sectores"]:
			var sec: Dictionary = seg["sectores"][sec_key]
			for sub_key: String in sec["subsectores"]:
				var sub: Dictionary = sec["subsectores"][sub_key]
				var planetas: Array = sub["planetas"]

				var has_hive: bool = false
				var has_agri: bool = false
				for p_idx: int in planetas.size():
					var p: Dictionary = planetas[p_idx]
					if str(p["tipo"]) == "hive_world": has_hive = true
					if str(p["tipo"]) == "agri_world": has_agri = true

				if has_hive and not has_agri:
					for p_idx2: int in planetas.size():
						var p: Dictionary = planetas[p_idx2]
						if str(p["tipo"]) == "civilised_world" and not bool(p["es_canonico"]):
							_convert_planet_type(p, "agri_world")
							break

func _convert_planet_type(planet: Dictionary, new_type: String) -> void:
	var type_data: Dictionary = PlanetTypes.TYPES[new_type]
	planet["tipo"] = new_type
	planet["tipo_visible"] = new_type
	planet["poblacion"] = _rand_range_int(int(type_data["poblacion_min"]), int(type_data["poblacion_max"]))
	planet["capacidad_industrial"] = _rand_stat(type_data["industrial"])
	planet["capacidad_militar"] = _rand_stat(type_data["militar"])
	planet["tithe_grade"] = str(type_data["diezmo_default"])
	planet["guarnicion"]["pdf_size"] = _calc_pdf(int(planet["poblacion"]), new_type)
	planet["controlador"] = _generate_controlador(str(type_data["controlador_tipo"]))
	planet["ingresos_mensuales"] = _calc_ingresos(planet)

# =============================================================================
# ESTADÍSTICAS
# =============================================================================

func _calculate_stats(galaxy: Dictionary) -> Dictionary:
	var stats: Dictionary = {
		"total_planetas": 0,
		"por_segmentum": {},
		"por_tipo": {},
		"por_lado_grieta": {"sanctus": 0, "nihilus": 0},
		"poblacion_total": 0,
		"tomb_worlds_ocultos": 0,
		"planetas_canonicos": 0,
	}

	var planetas: Array = galaxy["planetas"]
	stats["total_planetas"] = planetas.size()

	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		var seg: String = str(p["segmentum"])
		var tipo: String = str(p["tipo"])
		var lado: String = str(p["lado_grieta"])

		stats["por_segmentum"][seg] = int(stats["por_segmentum"].get(seg, 0)) + 1
		stats["por_tipo"][tipo] = int(stats["por_tipo"].get(tipo, 0)) + 1
		stats["por_lado_grieta"][lado] = int(stats["por_lado_grieta"][lado]) + 1
		stats["poblacion_total"] = int(stats["poblacion_total"]) + int(p["poblacion"])

		if p["es_tomb_world"]:
			stats["tomb_worlds_ocultos"] = int(stats["tomb_worlds_ocultos"]) + 1
		if p["es_canonico"]:
			stats["planetas_canonicos"] = int(stats["planetas_canonicos"]) + 1

	return stats

# =============================================================================
# UTILIDADES
# =============================================================================

func _generate_name() -> String:
	for _i: int in 100:
		var p_idx: int = rng.randi_range(0, PlanetTypes.NAME_PREFIXES.size() - 1)
		var s_idx: int = rng.randi_range(0, PlanetTypes.NAME_SUFFIXES.size() - 1)
		var d_idx: int = rng.randi_range(0, PlanetTypes.NAME_DESIGNATIONS.size() - 1)
		var planet_name: String = str(PlanetTypes.NAME_PREFIXES[p_idx]) + str(PlanetTypes.NAME_SUFFIXES[s_idx]) + str(PlanetTypes.NAME_DESIGNATIONS[d_idx])
		if not _used_names.has(planet_name):
			_used_names[planet_name] = true
			return planet_name
	var fallback: String = "World-" + str(_planet_id_counter)
	_used_names[fallback] = true
	return fallback

func _generate_controlador(tipo: String) -> Dictionary:
	match tipo:
		"adeptus_mechanicus": return {"tipo": tipo, "nombre": "Fabricator Locum"}
		"ecclesiarquia": return {"tipo": tipo, "nombre": "Prelado del Ministorum"}
		"cardenal": return {"tipo": tipo, "nombre": "Cardenal " + _random_name()}
		"adeptus_astartes": return {"tipo": tipo, "nombre": "Maestro de Capítulo"}
		"comandante_militar": return {"tipo": tipo, "nombre": "Lord Castellan " + _random_name()}
		"adeptus_arbites": return {"tipo": tipo, "nombre": "Juez Marshal " + _random_name()}
		"casa_noble": return {"tipo": tipo, "nombre": "Baron " + _random_name()}
		"jefe_tribal": return {"tipo": tipo, "nombre": "Warchief " + _random_name()}
		"nobleza_local": return {"tipo": tipo, "nombre": "Lord " + _random_name()}
		"ninguno": return {"tipo": tipo, "nombre": "Sin gobierno"}
		_:
			var t_idx: int = rng.randi_range(0, PlanetTypes.GOVERNOR_TITLES.size() - 1)
			return {"tipo": "gobernador_planetario", "nombre": str(PlanetTypes.GOVERNOR_TITLES[t_idx]) + " " + _random_name()}

func _random_name() -> String:
	return str(PlanetTypes.GOVERNOR_NAMES[rng.randi_range(0, PlanetTypes.GOVERNOR_NAMES.size() - 1)])

func _calc_pdf(poblacion: int, tipo: String) -> int:
	if poblacion <= 0: return 0
	return int(float(poblacion) * float(PlanetTypes.TYPES[tipo]["pdf_factor"]))

func _calc_ingresos(planet: Dictionary) -> int:
	var tipo: String = str(planet["tipo"])
	if not PlanetTypes.TYPES.has(tipo): return 0
	var tithe_key: String = str(planet["tithe_grade"])
	var tithe_data: Dictionary = PlanetTypes.TITHE_GRADES.get(tithe_key, {"multiplicador": 0.0})
	var pop: int = int(planet["poblacion"])
	if pop <= 0: return 0
	var pop_factor: float = log(float(pop)) / log(10.0)
	var industrial: int = int(planet["capacidad_industrial"])
	var tithe_mult: float = float(tithe_data["multiplicador"])
	return int((float(industrial) / 100.0) * pop_factor * tithe_mult * 1000.0)

func _rand_stat(stat_range: Variant) -> int:
	var arr: Array = stat_range
	return rng.randi_range(int(arr[0]), int(arr[1]))

func _rand_range_int(min_val: int, max_val: int) -> int:
	if min_val >= max_val: return min_val
	var range_size: int = max_val - min_val
	if range_size > 1_000_000:
		var t: float = rng.randf() * rng.randf()
		return min_val + int(float(range_size) * t)
	return rng.randi_range(min_val, max_val)

func _shuffle_array(arr: Array) -> void:
	for i: int in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = temp

func _make_key(text: String) -> String:
	return text.to_lower().replace(" ", "_").replace("'", "")

func _next_id() -> int:
	_planet_id_counter += 1
	return _planet_id_counter
