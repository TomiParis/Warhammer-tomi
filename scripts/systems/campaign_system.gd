## campaign_system.gd - Sistema de campañas militares completo
## Resolución por turno: poder, attrition, suministros, moral, frente
class_name CampaignSystem

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _next_campaign_id: int = MilitaryData.CAMPAIGN_ID_START

func _init() -> void:
	rng.randomize()

# =============================================================================
# PROCESAR TODAS LAS CAMPAÑAS (Fase G del turno)
# =============================================================================

func process(campaigns: Array, units: Array, turno: int) -> Dictionary:
	var resumen: Dictionary = {
		"campanas_activas": 0,
		"campanas_resueltas": 0,
		"victorias": 0,
		"derrotas": 0,
		"reportes": [],
	}

	for camp_idx: int in campaigns.size():
		var camp: Dictionary = campaigns[camp_idx]
		if bool(camp.get("terminada", false)):
			continue
		resumen["campanas_activas"] += 1
		camp["duracion_turnos"] = int(camp["duracion_turnos"]) + 1

		# 1. Calcular poder de combate imperial
		var poder_imperial: float = _calc_imperial_power(camp, units)
		camp["fuerza_imperial_total"] = int(poder_imperial)

		# 2. Poder enemigo (decrece lentamente si frente alto)
		var poder_enemigo: float = float(int(camp["fuerzas_enemigas"]))
		if int(camp["frente"]) > 70:
			poder_enemigo *= 0.98 # Enemigo se debilita si está perdiendo

		# 3. Attrition
		_process_attrition(camp, units, poder_imperial, poder_enemigo)

		# 4. Suministros
		camp["suministros_semanas"] = int(camp["suministros_semanas"]) - 1
		if int(camp["suministros_semanas"]) <= 0:
			camp["moral"] = maxi(int(camp["moral"]) - 20, 0)
			# Unidades pierden fuerza sin suministros
			for uid: int in camp["fuerzas_imperiales"]:
				var unit: Dictionary = _find_unit(units, uid)
				if not unit.is_empty():
					unit["fuerza"] = maxi(int(float(int(unit["fuerza"])) * 0.9), 0)

		# 5. Moral
		_update_moral(camp, units, poder_imperial, poder_enemigo)

		# 6. Frente
		var frente_anterior: int = int(camp["frente"])
		_update_front(camp, poder_imperial, poder_enemigo)

		# 7. Evento narrativo (30% chance)
		if rng.randf() < 0.3:
			_generate_narrative(camp, turno)

		# 8. Resolución
		var frente: int = int(camp["frente"])
		if frente >= 95:
			camp["terminada"] = true
			camp["resultado"] = "victoria"
			camp["fase"] = "resolucion"
			resumen["victorias"] += 1
			resumen["campanas_resueltas"] += 1
			resumen["reportes"].append("VICTORIA: %s" % str(camp["nombre"]))
			_release_units(camp, units)
		elif frente <= 5:
			camp["terminada"] = true
			camp["resultado"] = "derrota"
			camp["fase"] = "resolucion"
			resumen["derrotas"] += 1
			resumen["campanas_resueltas"] += 1
			resumen["reportes"].append("DERROTA: %s" % str(camp["nombre"]))
			_release_units(camp, units)
		elif int(camp["moral"]) <= 0:
			camp["terminada"] = true
			camp["resultado"] = "retirada"
			camp["fase"] = "resolucion"
			resumen["derrotas"] += 1
			resumen["campanas_resueltas"] += 1
			resumen["reportes"].append("RETIRADA: %s — moral colapsó" % str(camp["nombre"]))
			_release_units(camp, units)

		camp["fuerzas_enemigas"] = int(poder_enemigo)

	return resumen

# =============================================================================
# CREAR CAMPAÑA (llamado desde event_system o manualmente)
# =============================================================================

func create_campaign(planet: Dictionary, enemigo_tipo: String, enemigo_poder: int,
	tipo_campana: String, units: Array) -> Dictionary:

	var camp_type: Dictionary = MilitaryData.CAMPAIGN_TYPES.get(tipo_campana,
		{"nombre": "Campaña", "frente_inicial": 50})

	var nombre: String = "%s de %s" % [str(camp_type["nombre"]), str(planet["nombre"])]
	var cmd_idx: int = rng.randi_range(0, MilitaryData.COMMANDER_NAMES.size() - 1)

	var camp: Dictionary = {
		"id": _next_campaign_id,
		"nombre": nombre,
		"planeta_id": int(planet["id"]),
		"planeta_nombre": str(planet["nombre"]),
		"tipo": tipo_campana,
		"fase": "combate_activo",
		"frente": int(camp_type["frente_inicial"]),
		"fuerzas_imperiales": [],
		"fuerza_imperial_total": 0,
		"fuerzas_enemigas": enemigo_poder,
		"enemigo_tipo": enemigo_tipo,
		"bajas_imperiales": 0,
		"bajas_enemigas": 0,
		"suministros_semanas": rng.randi_range(6, 16),
		"moral": 65,
		"comandante": str(MilitaryData.COMMANDER_NAMES[cmd_idx]),
		"comandante_liderazgo": rng.randi_range(30, 80),
		"estrategia": "defensa_en_profundidad",
		"duracion_turnos": 0,
		"log": ["Campaña iniciada: %s enemigos detectados" % enemigo_tipo],
		"terminada": false,
		"resultado": "",
	}
	_next_campaign_id += 1

	# Auto-asignar PDF del planeta como guarnición
	var pdf_power: int = int(planet.get("guarnicion", {}).get("pdf_size", 0))
	if pdf_power > 0:
		camp["fuerza_imperial_total"] = pdf_power
		camp["log"].append("PDF local (%d efectivos) movilizada" % pdf_power)

	# Auto-asignar regimientos estacionados en el planeta
	for unit: Dictionary in units:
		if int(unit.get("planeta_origen_id", -1)) == int(planet["id"]):
			if str(unit["estado"]) == "guarnicion" and int(unit.get("campana_id", -1)) < 0:
				unit["estado"] = "combate"
				unit["campana_id"] = camp["id"]
				camp["fuerzas_imperiales"].append(int(unit["id"]))
				camp["log"].append("%s se une a la defensa" % str(unit["nombre"]))

	return camp

# =============================================================================
# CÁLCULOS INTERNOS
# =============================================================================

func _calc_imperial_power(camp: Dictionary, units: Array) -> float:
	var total: float = 0.0
	var estrategia: Dictionary = MilitaryData.STRATEGIES.get(str(camp["estrategia"]),
		{"atk_mult": 1.0, "def_mult": 1.0})
	var es_defensa: bool = str(camp["tipo"]) == "defensa_planetaria"
	var strat_mult: float = float(estrategia["def_mult"]) if es_defensa else float(estrategia["atk_mult"])
	var cmd_mult: float = 1.0 + float(int(camp["comandante_liderazgo"])) / 200.0

	# PDF del planeta (siempre presente)
	total += float(int(camp["fuerza_imperial_total"])) * 0.5 # PDF es menos efectiva

	# Unidades asignadas
	for uid: int in camp["fuerzas_imperiales"]:
		var unit: Dictionary = _find_unit(units, uid)
		if unit.is_empty():
			continue
		var fuerza: float = float(int(unit["fuerza"]))
		var moral_mult: float = float(int(unit["moral"])) / 100.0
		var exp_mult: float = float(MilitaryData.EXP_MULT.get(str(unit["experiencia"]), 1.0))
		total += fuerza * moral_mult * exp_mult

	total *= strat_mult * cmd_mult
	return total

func _process_attrition(camp: Dictionary, units: Array, poder_imp: float, poder_enem: float) -> void:
	if poder_imp + poder_enem <= 0.0:
		return
	var ratio: float = poder_imp / (poder_imp + poder_enem)
	var estrategia: Dictionary = MilitaryData.STRATEGIES.get(str(camp["estrategia"]),
		{"attrition_mult": 1.0})
	var att_mult: float = float(estrategia["attrition_mult"])

	var bajas_imp: int = int(poder_enem * (1.0 - ratio) * 0.02 * att_mult)
	var bajas_enem: int = int(poder_imp * ratio * 0.02)

	camp["bajas_imperiales"] = int(camp["bajas_imperiales"]) + bajas_imp
	camp["bajas_enemigas"] = int(camp["bajas_enemigas"]) + bajas_enem
	camp["fuerzas_enemigas"] = maxi(int(camp["fuerzas_enemigas"]) - bajas_enem, 0)

	# Distribuir bajas entre unidades
	if bajas_imp > 0:
		var imp_units: Array = camp["fuerzas_imperiales"]
		if not imp_units.is_empty():
			var bajas_per_unit: int = maxi(bajas_imp / imp_units.size(), 1)
			for uid: int in imp_units:
				var unit: Dictionary = _find_unit(units, uid)
				if not unit.is_empty():
					unit["fuerza"] = maxi(int(unit["fuerza"]) - bajas_per_unit, 0)

func _update_moral(camp: Dictionary, units: Array, poder_imp: float, poder_enem: float) -> void:
	var moral: int = int(camp["moral"])
	var frente: int = int(camp["frente"])

	# Basado en diferencia de poder
	if poder_imp > poder_enem * 1.1:
		moral += 3
	elif poder_enem > poder_imp * 1.1:
		moral -= 5

	# Sin suministros
	if int(camp["suministros_semanas"]) <= 0:
		moral -= 20

	# Astartes presentes: +15 bonus
	for uid: int in camp["fuerzas_imperiales"]:
		var unit: Dictionary = _find_unit(units, uid)
		if not unit.is_empty() and str(unit.get("tipo_arma", "")) == "astartes":
			moral += 15
			break

	# Comandante
	moral += int(camp["comandante_liderazgo"]) / 20

	camp["moral"] = clampi(moral, 0, 100)

func _update_front(camp: Dictionary, poder_imp: float, poder_enem: float) -> void:
	if poder_imp + poder_enem <= 0.0:
		return
	var diferencia: float = (poder_imp - poder_enem) / maxf(poder_imp, poder_enem)
	var cambio: int = int(diferencia * float(rng.randi_range(2, 8)))
	camp["frente"] = clampi(int(camp["frente"]) + cambio, 0, 100)

func _generate_narrative(camp: Dictionary, turno: int) -> void:
	var tipo: String = str(camp["enemigo_tipo"])
	var narratives: Array = MilitaryData.BATTLE_NARRATIVES.get(tipo,
		MilitaryData.BATTLE_NARRATIVES.get("rebellion", []))
	if narratives.is_empty():
		return
	var text: String = str(narratives[rng.randi_range(0, narratives.size() - 1)])
	var log: Array = camp["log"]
	log.append("[T%d] %s" % [int(camp["duracion_turnos"]), text])
	if log.size() > 20:
		log.pop_front()

func _release_units(camp: Dictionary, units: Array) -> void:
	for uid: int in camp["fuerzas_imperiales"]:
		var unit: Dictionary = _find_unit(units, uid)
		if not unit.is_empty():
			unit["estado"] = "recuperacion"
			unit["campana_id"] = -1

func _find_unit(units: Array, uid: int) -> Dictionary:
	for u: Dictionary in units:
		if int(u["id"]) == uid:
			return u
	return {}

# =============================================================================
# CONSULTAS
# =============================================================================

func get_campaign_at_planet(campaigns: Array, planet_id: int) -> Dictionary:
	for camp: Dictionary in campaigns:
		if int(camp["planeta_id"]) == planet_id and not bool(camp.get("terminada", false)):
			return camp
	return {}

func get_active_campaigns(campaigns: Array) -> Array:
	var result: Array = []
	for camp: Dictionary in campaigns:
		if not bool(camp.get("terminada", false)):
			result.append(camp)
	return result
