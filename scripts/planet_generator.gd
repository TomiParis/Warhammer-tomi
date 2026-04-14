## planet_generator.gd - Generador procedural de la galaxia
## Genera ~1000 planetas organizados en Segmentae > Sectores > Subsectores
## Fiel al lore canónico de Warhammer 40,000
class_name PlanetGenerator

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _used_names: Dictionary = {}
var _type_pool: Array = []
var _planet_id_counter: int = 0

# =============================================================================
# PUNTO DE ENTRADA PRINCIPAL
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

	# Paso 1: Construir jerarquía vacía y calcular targets por subsector
	var subsector_targets: Dictionary = _build_hierarchy(galaxy)

	# Paso 2: Crear pool global de tipos según distribución
	_build_type_pool()

	# Paso 3: Colocar planetas canónicos
	_place_canonical_planets(galaxy, subsector_targets)

	# Paso 4: Rellenar subsectores con planetas generados
	_fill_galaxy(galaxy, subsector_targets)

	# Paso 5: Aplicar reglas de coherencia del lore
	_apply_lore_coherence(galaxy)

	# Paso 6: Calcular estadísticas resumen
	galaxy["stats"] = _calculate_stats(galaxy)

	return galaxy

# =============================================================================
# PASO 1: CONSTRUIR JERARQUÍA VACÍA
# =============================================================================

func _build_hierarchy(galaxy: Dictionary) -> Dictionary:
	var targets: Dictionary = {}
	var total_subsectors: int = 0

	# Contar subsectores totales
	for seg_key: String in GameData.GALAXY_HIERARCHY:
		var seg_data: Dictionary = GameData.GALAXY_HIERARCHY[seg_key]
		for sec_key: String in seg_data["sectores"]:
			var sec_data: Dictionary = seg_data["sectores"][sec_key]
			var subsectores: Array = sec_data["subsectores"]
			total_subsectors += subsectores.size()

	# Distribuir ~1000 planetas entre subsectores
	var base_per_sub: float = 1000.0 / float(total_subsectors)

	for seg_key: String in GameData.GALAXY_HIERARCHY:
		var seg_data: Dictionary = GameData.GALAXY_HIERARCHY[seg_key]
		galaxy["segmentae"][seg_key] = {
			"nombre": seg_data["nombre"],
			"sectores": {},
		}

		for sec_key: String in seg_data["sectores"]:
			var sec_data: Dictionary = seg_data["sectores"][sec_key]
			galaxy["segmentae"][seg_key]["sectores"][sec_key] = {
				"nombre": sec_data["nombre"],
				"lado_grieta": sec_data["lado_grieta"],
				"subsectores": {},
			}

			var subsectores: Array = sec_data["subsectores"]
			for idx: int in subsectores.size():
				var sub_name: String = str(subsectores[idx])
				var sub_key: String = _make_key(sub_name)
				var full_key: String = seg_key + "." + sec_key + "." + sub_key

				# Variar cantidad ±3 del base, clampeado a [8, 16]
				var target: int = int(round(base_per_sub)) + rng.randi_range(-3, 3)
				target = clampi(target, 8, 16)
				targets[full_key] = target

				galaxy["segmentae"][seg_key]["sectores"][sec_key]["subsectores"][sub_key] = {
					"nombre": sub_name,
					"planetas": [],
				}

	return targets

# =============================================================================
# PASO 2: CONSTRUIR POOL DE TIPOS
# =============================================================================

func _build_type_pool() -> void:
	_type_pool.clear()
	for tipo: String in GameData.TYPE_DISTRIBUTION:
		var cantidad: int = int(GameData.TYPE_DISTRIBUTION[tipo])
		for i: int in cantidad:
			_type_pool.append(tipo)
	_shuffle_array(_type_pool)

# =============================================================================
# PASO 3: COLOCAR PLANETAS CANÓNICOS
# =============================================================================

func _place_canonical_planets(galaxy: Dictionary, targets: Dictionary) -> void:
	for canon_idx: int in GameData.CANONICAL_PLANETS.size():
		var canon_data: Dictionary = GameData.CANONICAL_PLANETS[canon_idx]
		var seg_key: String = str(canon_data["segmentum"])
		var sec_key: String = str(canon_data["sector"])
		var sub_key: String = _make_key(str(canon_data["subsector"]))
		var full_key: String = seg_key + "." + sec_key + "." + sub_key

		# Crear el planeta canónico con datos exactos
		var planet: Dictionary = _create_canonical_planet(canon_data, seg_key, sec_key, sub_key)

		# Registrar el nombre como usado
		_used_names[str(canon_data["nombre"])] = true

		# Agregar a la jerarquía
		var sub_dict: Dictionary = galaxy["segmentae"][seg_key]["sectores"][sec_key]["subsectores"][sub_key]
		sub_dict["planetas"].append(planet)
		galaxy["planetas"].append(planet)

		# Reducir el target de ese subsector
		if targets.has(full_key):
			targets[full_key] = int(targets[full_key]) - 1

		# Remover un tipo del pool
		_remove_from_pool(str(canon_data["tipo"]))

func _create_canonical_planet(data: Dictionary, seg_key: String, sec_key: String, sub_key: String) -> Dictionary:
	var tipo: String = str(data["tipo"])
	var sec_data: Dictionary = GameData.GALAXY_HIERARCHY[seg_key]["sectores"][sec_key]
	var lado: String = str(sec_data["lado_grieta"])
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
# PASO 4: RELLENAR LA GALAXIA
# =============================================================================

func _fill_galaxy(galaxy: Dictionary, targets: Dictionary) -> void:
	for seg_key: String in GameData.GALAXY_HIERARCHY:
		var seg_data: Dictionary = GameData.GALAXY_HIERARCHY[seg_key]

		for sec_key: String in seg_data["sectores"]:
			var sec_data: Dictionary = seg_data["sectores"][sec_key]
			var subsectores: Array = sec_data["subsectores"]

			for sub_idx: int in subsectores.size():
				var sub_name: String = str(subsectores[sub_idx])
				var sub_key: String = _make_key(sub_name)
				var full_key: String = seg_key + "." + sec_key + "." + sub_key
				var remaining: int = int(targets.get(full_key, 0))

				if remaining <= 0:
					continue

				for _i: int in remaining:
					var tipo: String = _pick_type_for_location(seg_key, sec_key)
					var planet: Dictionary = _generate_planet(tipo, seg_key, sec_key, sub_key)

					var sub_dict: Dictionary = galaxy["segmentae"][seg_key]["sectores"][sec_key]["subsectores"][sub_key]
					sub_dict["planetas"].append(planet)
					galaxy["planetas"].append(planet)

# Elegir tipo de planeta considerando ubicación y pool disponible
func _pick_type_for_location(seg_key: String, _sec_key: String) -> String:
	if _type_pool.is_empty():
		return "civilised_world"

	var mods: Dictionary = GameData.SEGMENTUM_TYPE_MODS.get(seg_key, {})

	var best_idx: int = 0
	var best_score: float = 0.0

	var candidates: int = mini(_type_pool.size(), 10)
	for _i: int in candidates:
		var idx: int = rng.randi_range(0, _type_pool.size() - 1)
		var tipo: String = str(_type_pool[idx])
		var mod: float = float(mods.get(tipo, 1.0))
		var score: float = mod * rng.randf_range(0.5, 1.5)

		if score > best_score:
			best_score = score
			best_idx = idx

	var chosen: String = str(_type_pool[best_idx])
	_type_pool.remove_at(best_idx)
	return chosen

# =============================================================================
# GENERACIÓN DE UN PLANETA INDIVIDUAL
# =============================================================================

func _generate_planet(tipo: String, seg_key: String, sec_key: String, sub_key: String) -> Dictionary:
	var type_data: Dictionary = GameData.PLANET_TYPES[tipo]
	var sec_data: Dictionary = GameData.GALAXY_HIERARCHY[seg_key]["sectores"][sec_key]
	var lado: String = str(sec_data["lado_grieta"])
	var warp_mod: int = int(sec_data["warp_mod"])

	var nombre: String = _generate_name()
	var poblacion: int = _rand_range_int(int(type_data["poblacion_min"]), int(type_data["poblacion_max"]))

	# Stats base del tipo
	var industrial: int = _rand_stat(type_data["industrial"])
	var militar: int = _rand_stat(type_data["militar"])
	var lealtad: int = _rand_stat(type_data["lealtad"])
	var fe: int = _rand_stat(type_data["fe"])
	var warp_est: int = clampi(_rand_stat(type_data["warp_estabilidad"]) + warp_mod, 0, 100)

	# Penalización por Nihilus
	if lado == "nihilus":
		lealtad = clampi(lealtad - rng.randi_range(5, 15), 0, 100)
		fe = clampi(fe - rng.randi_range(5, 15), 0, 100)
		industrial = clampi(industrial - rng.randi_range(5, 10), 0, 100)
		warp_est = clampi(warp_est - rng.randi_range(10, 20), 0, 100)

	var tithe: String = str(type_data["diezmo_default"])
	var controlador_tipo: String = str(type_data["controlador_tipo"])
	var controlador: Dictionary = _generate_controlador(controlador_tipo)

	# Astropata: 70% en Sanctus, 30% en Nihilus
	var tiene_astropata: bool = false
	if tipo != "dead_world":
		var astro_chance: float = 0.7 if lado == "sanctus" else 0.3
		tiene_astropata = rng.randf() < astro_chance

	# Propiedades ocultas
	var infiltracion_caos: int = rng.randi_range(0, 10)
	var amenaza_mod_val: int = int(sec_data["amenaza_mod"])
	if amenaza_mod_val > 50:
		infiltracion_caos += rng.randi_range(5, 20)
	infiltracion_caos = clampi(infiltracion_caos, 0, 100)

	var infiltracion_gs: int = rng.randi_range(0, 5)
	var corrupcion_gob: int = rng.randi_range(0, 20)

	# Tomb World oculto
	var es_tomb: bool = false
	var tomb_disguises: Array = GameData.TOMB_WORLD_DISGUISES
	if tomb_disguises.has(tipo) and rng.randf() < GameData.TOMB_WORLD_CHANCE:
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
		"infiltracion_genestealer": infiltracion_gs,
		"corrupcion_gobernador": corrupcion_gob,
		"es_tomb_world": es_tomb,
		"es_canonico": false,
		"flags": [],
	}

	planet["ingresos_mensuales"] = _calc_ingresos(planet)
	return planet

# =============================================================================
# PASO 5: COHERENCIA DEL LORE
# =============================================================================

func _apply_lore_coherence(galaxy: Dictionary) -> void:
	for seg_key: String in galaxy["segmentae"]:
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		for sec_key: String in seg["sectores"]:
			var sec: Dictionary = seg["sectores"][sec_key]
			var sub_keys: Array = sec["subsectores"].keys()

			for sub_idx: int in sub_keys.size():
				var sub_key: String = str(sub_keys[sub_idx])
				var sub: Dictionary = sec["subsectores"][sub_key]
				var planetas: Array = sub["planetas"]

				# Contar tipos en este subsector
				var type_count: Dictionary = {}
				for p_idx: int in planetas.size():
					var p: Dictionary = planetas[p_idx]
					var t: String = str(p["tipo"])
					type_count[t] = int(type_count.get(t, 0)) + 1

				# Si hay hive_world pero no agri_world, convertir un civilised
				var hive_count: int = int(type_count.get("hive_world", 0))
				var agri_count: int = int(type_count.get("agri_world", 0))
				if hive_count > 0 and agri_count == 0:
					for p_idx2: int in planetas.size():
						var p: Dictionary = planetas[p_idx2]
						if str(p["tipo"]) == "civilised_world" and not bool(p["es_canonico"]):
							_convert_planet_type(p, "agri_world")
							break

func _convert_planet_type(planet: Dictionary, new_type: String) -> void:
	var type_data: Dictionary = GameData.PLANET_TYPES[new_type]
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
# PASO 6: ESTADÍSTICAS RESUMEN
# =============================================================================

func _calculate_stats(galaxy: Dictionary) -> Dictionary:
	var stats: Dictionary = {
		"total_planetas": galaxy["planetas"].size(),
		"por_segmentum": {},
		"por_tipo": {},
		"por_lado_grieta": {"sanctus": 0, "nihilus": 0},
		"poblacion_total": 0,
		"tomb_worlds_ocultos": 0,
		"planetas_canonicos": 0,
	}

	var planetas: Array = galaxy["planetas"]
	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]

		var seg: String = str(p["segmentum"])
		stats["por_segmentum"][seg] = int(stats["por_segmentum"].get(seg, 0)) + 1

		var tipo: String = str(p["tipo"])
		stats["por_tipo"][tipo] = int(stats["por_tipo"].get(tipo, 0)) + 1

		var lado_str: String = str(p["lado_grieta"])
		stats["por_lado_grieta"][lado_str] = int(stats["por_lado_grieta"][lado_str]) + 1

		stats["poblacion_total"] = int(stats["poblacion_total"]) + int(p["poblacion"])

		if p["es_tomb_world"]:
			stats["tomb_worlds_ocultos"] = int(stats["tomb_worlds_ocultos"]) + 1
		if p["es_canonico"]:
			stats["planetas_canonicos"] = int(stats["planetas_canonicos"]) + 1

	return stats

# =============================================================================
# UTILIDADES DE GENERACIÓN
# =============================================================================

func _generate_name() -> String:
	for _i: int in 100:
		var p_idx: int = rng.randi_range(0, GameData.NAME_PREFIXES.size() - 1)
		var s_idx: int = rng.randi_range(0, GameData.NAME_SUFFIXES.size() - 1)
		var d_idx: int = rng.randi_range(0, GameData.NAME_DESIGNATIONS.size() - 1)
		var prefix: String = str(GameData.NAME_PREFIXES[p_idx])
		var suffix: String = str(GameData.NAME_SUFFIXES[s_idx])
		var designation: String = str(GameData.NAME_DESIGNATIONS[d_idx])
		var planet_name: String = prefix + suffix + designation

		if not _used_names.has(planet_name):
			_used_names[planet_name] = true
			return planet_name

	var fallback: String = "World-" + str(_planet_id_counter)
	_used_names[fallback] = true
	return fallback

func _generate_controlador(tipo: String) -> Dictionary:
	match tipo:
		"adeptus_mechanicus":
			return {"tipo": tipo, "nombre": "Fabricator Locum"}
		"ecclesiarquia":
			return {"tipo": tipo, "nombre": "Prelado del Ministorum"}
		"cardenal":
			return {"tipo": tipo, "nombre": "Cardenal " + _random_governor_name()}
		"adeptus_astartes":
			return {"tipo": tipo, "nombre": "Maestro de Capítulo"}
		"comandante_militar":
			return {"tipo": tipo, "nombre": "Lord Castellan " + _random_governor_name()}
		"adeptus_arbites":
			return {"tipo": tipo, "nombre": "Juez Marshal " + _random_governor_name()}
		"casa_noble":
			return {"tipo": tipo, "nombre": "Baron " + _random_governor_name()}
		"jefe_tribal":
			return {"tipo": tipo, "nombre": "Warchief " + _random_governor_name()}
		"nobleza_local":
			return {"tipo": tipo, "nombre": "Lord " + _random_governor_name()}
		"ninguno":
			return {"tipo": tipo, "nombre": "Sin gobierno"}
		_:
			var t_idx: int = rng.randi_range(0, GameData.GOVERNOR_TITLES.size() - 1)
			var title: String = str(GameData.GOVERNOR_TITLES[t_idx])
			return {"tipo": "gobernador_planetario", "nombre": title + " " + _random_governor_name()}

func _random_governor_name() -> String:
	var idx: int = rng.randi_range(0, GameData.GOVERNOR_NAMES.size() - 1)
	return str(GameData.GOVERNOR_NAMES[idx])

func _calc_pdf(poblacion: int, tipo: String) -> int:
	if poblacion <= 0:
		return 0
	var factor: float = float(GameData.PLANET_TYPES[tipo]["pdf_factor"])
	return int(float(poblacion) * factor)

func _calc_ingresos(planet: Dictionary) -> int:
	var tipo: String = str(planet["tipo"])
	if not GameData.PLANET_TYPES.has(tipo):
		return 0

	var tithe_key: String = str(planet["tithe_grade"])
	var tithe_data: Dictionary = GameData.TITHE_GRADES.get(tithe_key, {"multiplicador": 0.0})

	var pop_factor: float = 0.0
	var pop: int = int(planet["poblacion"])
	if pop > 0:
		pop_factor = log(float(pop)) / log(10.0)
	var industrial: int = int(planet["capacidad_industrial"])
	var tithe_mult: float = float(tithe_data["multiplicador"])

	return int((float(industrial) / 100.0) * pop_factor * tithe_mult * 1000.0)

func _rand_stat(stat_range: Variant) -> int:
	var arr: Array = stat_range
	return rng.randi_range(int(arr[0]), int(arr[1]))

func _rand_range_int(min_val: int, max_val: int) -> int:
	if min_val >= max_val:
		return min_val
	var range_size: int = max_val - min_val
	if range_size > 1_000_000:
		var t: float = rng.randf()
		t = t * t
		return min_val + int(float(range_size) * t)
	return rng.randi_range(min_val, max_val)

func _remove_from_pool(tipo: String) -> void:
	var idx: int = _type_pool.find(tipo)
	if idx >= 0:
		_type_pool.remove_at(idx)

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
