## governance_generator.gd - Genera controladores detallados, Lord Sectors, Knight Houses, Rogue Traders
## Se ejecuta DESPUÉS de galaxy_generator y chapter_generator
class_name GovernanceGenerator

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func generate(galaxy: Dictionary, seed_value: int = 42) -> Dictionary:
	rng.seed = seed_value + 3333

	var result: Dictionary = {
		"lord_sectors": {},  # "seg.sec" -> lord_sector dict
		"knight_houses": [], # Array de casas
		"rogue_traders": [], # Array de dinastías
		"faction_relations": {}, # Copia mutable de BASE_RELATIONS
	}

	# 1. Expandir controladores de cada planeta
	_expand_controllers(galaxy)

	# 2. Generar Lord Sectors
	_generate_lord_sectors(galaxy, result)

	# 3. Generar Knight Houses (asignar a Knight Worlds)
	_generate_knight_houses(galaxy, result)

	# 4. Generar Rogue Traders
	_generate_rogue_traders(galaxy, result)

	# 5. Inicializar relaciones
	for key: String in FactionData.BASE_RELATIONS:
		result["faction_relations"][key] = int(FactionData.BASE_RELATIONS[key])

	return result

# =============================================================================
# EXPANDIR CONTROLADORES
# =============================================================================

func _expand_controllers(galaxy: Dictionary) -> void:
	var planetas: Array = galaxy.get("planetas", [])
	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		var ctrl: Dictionary = p.get("controlador", {})
		var tipo: String = str(ctrl.get("tipo", "gobernador_planetario"))

		match tipo:
			"gobernador_planetario":
				_expand_governor(ctrl)
			"adeptus_mechanicus":
				_expand_mechanicus(ctrl, p)
			"ecclesiarquia", "cardenal":
				_expand_ecclesiarquia(ctrl, p)
			"casa_noble":
				_expand_knight(ctrl)
			"comandante_militar":
				_expand_military(ctrl)
			"jefe_tribal":
				_expand_tribal(ctrl)
			"aristocracia_local", "nobleza_local":
				_expand_governor(ctrl)
			"adeptus_astartes":
				pass # Ya expandido por chapter_generator
			"adeptus_arbites":
				ctrl["ley_marcial"] = true
				ctrl["turnos_restantes"] = rng.randi_range(3, 12)
			_:
				pass # adeptus_terra, ninguno — dejar como está

		p["controlador"] = ctrl

func _expand_governor(ctrl: Dictionary) -> void:
	if ctrl.has("lealtad_personal"):
		return # Ya expandido (canónico)

	var titulo_idx: int = rng.randi_range(0, FactionData.GOVERNOR_TITLES.size() - 1)
	var dyn_idx: int = rng.randi_range(0, FactionData.DYNASTY_NAMES.size() - 1)

	ctrl["titulo"] = str(FactionData.GOVERNOR_TITLES[titulo_idx])
	ctrl["dinastia"] = "Casa " + str(FactionData.DYNASTY_NAMES[dyn_idx])
	ctrl["dinastia_siglos"] = rng.randi_range(1, 30)
	ctrl["lealtad_personal"] = rng.randi_range(40, 85)
	ctrl["competencia"] = rng.randi_range(20, 80)
	ctrl["corrupcion"] = rng.randi_range(0, 30)
	ctrl["ambicion"] = rng.randi_range(10, 60)

func _expand_mechanicus(ctrl: Dictionary, planet: Dictionary) -> void:
	if ctrl.has("nivel_tech"):
		return
	var name_idx: int = rng.randi_range(0, FactionData.ARCHMAGOS_NAMES.size() - 1)
	ctrl["nombre"] = "Archmagos " + str(FactionData.ARCHMAGOS_NAMES[name_idx])
	ctrl["forge_world"] = str(planet["nombre"])
	ctrl["nivel_tech"] = rng.randi_range(50, 95)
	ctrl["titan_legios"] = 1 if rng.randf() < 0.4 else 0

func _expand_ecclesiarquia(ctrl: Dictionary, _planet: Dictionary) -> void:
	if ctrl.has("fe_bonus"):
		return
	var tipo_ctrl: String = str(ctrl.get("tipo", "ecclesiarquia"))
	if tipo_ctrl == "cardenal":
		ctrl["rango"] = "Cardinal"
	else:
		var rangos: Array = ["Arch-Confessor", "Pontifex", "Prelate"]
		ctrl["rango"] = rangos[rng.randi_range(0, rangos.size() - 1)]
	ctrl["fe_bonus"] = rng.randi_range(5, 20)
	var orden_idx: int = rng.randi_range(0, FactionData.SORORITAS_ORDERS.size() - 1)
	ctrl["sororitas_orden"] = str(FactionData.SORORITAS_ORDERS[orden_idx])

func _expand_knight(ctrl: Dictionary) -> void:
	if ctrl.has("knights_operativos"):
		return
	ctrl["knights_operativos"] = rng.randi_range(20, 80)
	ctrl["alianza"] = "imperialis" if rng.randf() < 0.55 else "mechanicum"
	ctrl["honor"] = rng.randi_range(40, 90)

func _expand_military(ctrl: Dictionary) -> void:
	if ctrl.has("rango_militar"):
		return
	ctrl["rango_militar"] = "Lord Castellan"
	ctrl["lealtad_personal"] = rng.randi_range(60, 95)
	ctrl["competencia"] = rng.randi_range(50, 90)

func _expand_tribal(ctrl: Dictionary) -> void:
	ctrl["lealtad_personal"] = rng.randi_range(20, 60)
	ctrl["competencia"] = rng.randi_range(10, 40)

# =============================================================================
# LORD SECTORS
# =============================================================================

func _generate_lord_sectors(galaxy: Dictionary, result: Dictionary) -> void:
	for seg_key: String in galaxy["segmentae"]:
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		for sec_key: String in seg["sectores"]:
			var full_key: String = seg_key + "." + sec_key
			var sec: Dictionary = seg["sectores"][sec_key]
			var sec_name: String = str(sec["nombre"])

			var title_idx: int = rng.randi_range(0, FactionData.LORD_SECTOR_TITLES.size() - 1)
			var name_idx: int = rng.randi_range(0, PlanetTypes.GOVERNOR_NAMES.size() - 1)

			result["lord_sectors"][full_key] = {
				"sector": sec_name,
				"titulo": str(FactionData.LORD_SECTOR_TITLES[title_idx]),
				"nombre": str(PlanetTypes.GOVERNOR_NAMES[name_idx]),
				"influencia": rng.randi_range(30, 80),
				"lealtad": rng.randi_range(50, 90),
			}

# =============================================================================
# KNIGHT HOUSES
# =============================================================================

func _generate_knight_houses(galaxy: Dictionary, result: Dictionary) -> void:
	# Asignar casas canónicas primero
	var house_idx: int = 0
	var planetas: Array = galaxy.get("planetas", [])

	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		if str(p["tipo"]) != "knight_world":
			continue
		if str(p["controlador"]["tipo"]) != "casa_noble":
			continue

		var house: Dictionary = {}
		if house_idx < FactionData.KNIGHT_HOUSES.size():
			var canon: Dictionary = FactionData.KNIGHT_HOUSES[house_idx]
			house = {
				"nombre": str(canon["nombre"]),
				"planeta": str(p["nombre"]),
				"planeta_id": int(p["id"]),
				"knights_operativos": int(canon["knights_base"]) + rng.randi_range(-10, 10),
				"alianza": str(canon["alianza"]),
				"honor": rng.randi_range(50, 90),
				"es_canonico": true,
			}
		else:
			# Generar casa inventada
			var prefixes: Array = ["House ", "Noble House "]
			var names: Array = ["Dracon", "Veltris", "Orhaven", "Keldris", "Thundris",
				"Morvain", "Ashfeld", "Gryphon", "Stormhold", "Ironfang"]
			var n_idx: int = rng.randi_range(0, names.size() - 1)
			house = {
				"nombre": prefixes[0] + names[n_idx],
				"planeta": str(p["nombre"]),
				"planeta_id": int(p["id"]),
				"knights_operativos": rng.randi_range(15, 60),
				"alianza": "imperialis" if rng.randf() < 0.55 else "mechanicum",
				"honor": rng.randi_range(40, 85),
				"es_canonico": false,
			}

		# Actualizar controlador del planeta con la casa
		p["controlador"]["casa"] = str(house["nombre"])
		p["controlador"]["knights_operativos"] = int(house["knights_operativos"])
		p["controlador"]["alianza"] = str(house["alianza"])
		p["controlador"]["honor"] = int(house["honor"])

		result["knight_houses"].append(house)
		house_idx += 1

# =============================================================================
# ROGUE TRADERS
# =============================================================================

func _generate_rogue_traders(galaxy: Dictionary, result: Dictionary) -> void:
	var count: int = rng.randi_range(5, 8)
	var planetas: Array = galaxy.get("planetas", [])

	# Buscar planetas en Pacificus o bordes de Ultima para asignar Rogue Traders
	var candidates: Array = []
	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		var seg: String = str(p["segmentum"])
		if seg in ["pacificus", "ultima"]:
			if str(p["tipo"]) in ["frontier_world", "civilised_world", "feral_world"]:
				if str(p["controlador"]["tipo"]) == "gobernador_planetario":
					candidates.append(p)

	for i: int in count:
		var dyn_idx: int = i if i < FactionData.ROGUE_TRADER_DYNASTIES.size() else rng.randi_range(0, FactionData.ROGUE_TRADER_DYNASTIES.size() - 1)
		var dynasty_name: String = "Dinastía " + str(FactionData.ROGUE_TRADER_DYNASTIES[dyn_idx])

		var planeta_id: int = -1
		var planeta_nombre: String = "Fleet-based"
		# Asignar un planeta si hay candidatos
		if not candidates.is_empty():
			var chosen_idx: int = rng.randi_range(0, candidates.size() - 1)
			var chosen: Dictionary = candidates[chosen_idx]
			planeta_id = int(chosen["id"])
			planeta_nombre = str(chosen["nombre"])
			# Cambiar controlador del planeta
			chosen["controlador"] = {
				"tipo": "rogue_trader",
				"nombre": "Lord Captain " + str(FactionData.ROGUE_TRADER_DYNASTIES[dyn_idx]),
				"dinastia": dynasty_name,
				"warrant_era": "M" + str(rng.randi_range(30, 41)),
				"riqueza": rng.randi_range(30, 90),
				"flota_naves": rng.randi_range(3, 15),
				"reputacion": rng.randi_range(20, 80),
			}
			candidates.remove_at(chosen_idx)

		result["rogue_traders"].append({
			"nombre": dynasty_name,
			"cabeza": "Lord Captain " + str(FactionData.ROGUE_TRADER_DYNASTIES[dyn_idx]),
			"warrant_era": "M" + str(rng.randi_range(30, 41)),
			"planeta_base_id": planeta_id,
			"planeta_base": planeta_nombre,
			"riqueza": rng.randi_range(30, 90),
			"flota_naves": rng.randi_range(3, 15),
			"reputacion": rng.randi_range(20, 80),
		})
