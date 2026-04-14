## event_system.gd - Genera eventos por turno con presupuesto controlado
## NO tira dados por planeta. Selecciona planetas ponderadamente.
class_name EventSystem

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _last_major_turn: int = 0
var _last_apocalyptic_turn: int = 0

func _init() -> void:
	rng.randomize()

func process(planetas: Array, turno: int) -> Array:
	var eventos: Array = []

	# Calcular presupuesto de este turno
	var budget_minor: int = rng.randi_range(
		EventDefinitions.BUDGET[EventDefinitions.Severity.MINOR]["min"],
		EventDefinitions.BUDGET[EventDefinitions.Severity.MINOR]["max"]
	)
	var budget_medium: int = rng.randi_range(
		EventDefinitions.BUDGET[EventDefinitions.Severity.MEDIUM]["min"],
		EventDefinitions.BUDGET[EventDefinitions.Severity.MEDIUM]["max"]
	)

	# Mayores: solo cada N turnos
	var budget_major: int = 0
	var major_interval: int = rng.randi_range(
		EventDefinitions.BUDGET[EventDefinitions.Severity.MAJOR]["interval_min"],
		EventDefinitions.BUDGET[EventDefinitions.Severity.MAJOR]["interval_max"]
	)
	if turno - _last_major_turn >= major_interval:
		budget_major = 1
		_last_major_turn = turno

	# Apocalípticos: muy raros
	var budget_apocalyptic: int = 0
	var apoc_interval: int = rng.randi_range(
		EventDefinitions.BUDGET[EventDefinitions.Severity.APOCALYPTIC]["interval_min"],
		EventDefinitions.BUDGET[EventDefinitions.Severity.APOCALYPTIC]["interval_max"]
	)
	if turno - _last_apocalyptic_turn >= apoc_interval:
		budget_apocalyptic = 1
		_last_apocalyptic_turn = turno

	# Calcular pesos de riesgo para todos los planetas (O(n))
	var pesos: Array = []
	var peso_total: float = 0.0
	var planetas_con_evento: Dictionary = {} # Evitar acumular eventos

	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		if int(p["poblacion"]) <= 0:
			pesos.append(0.0)
			continue

		var peso: float = 5.0 # Base
		peso += float(int(p["infiltracion_caos"])) * 0.3
		peso += float(100 - int(p["lealtad_imperial"])) * 0.2
		peso += float(int(p["corrupcion_gobernador"])) * 0.2
		peso += float(100 - int(p["estabilidad_warp"])) * 0.1

		if str(p["lado_grieta"]) == "nihilus":
			peso += 15.0

		# Reducir si ya tiene evento activo
		if p.get("amenaza_actual") != null:
			peso *= 0.2

		pesos.append(maxf(peso, 0.0))
		peso_total += maxf(peso, 0.0)

	if peso_total <= 0.0:
		return eventos

	# Generar eventos por severidad
	_generate_events_for_severity(EventDefinitions.Severity.MINOR, budget_minor,
		planetas, pesos, peso_total, planetas_con_evento, eventos, turno)
	_generate_events_for_severity(EventDefinitions.Severity.MEDIUM, budget_medium,
		planetas, pesos, peso_total, planetas_con_evento, eventos, turno)
	_generate_events_for_severity(EventDefinitions.Severity.MAJOR, budget_major,
		planetas, pesos, peso_total, planetas_con_evento, eventos, turno)
	_generate_events_for_severity(EventDefinitions.Severity.APOCALYPTIC, budget_apocalyptic,
		planetas, pesos, peso_total, planetas_con_evento, eventos, turno)

	return eventos

func _generate_events_for_severity(severity: int, budget: int,
	planetas: Array, pesos: Array, peso_total: float,
	planetas_con_evento: Dictionary, eventos: Array, turno: int) -> void:

	for _slot: int in budget:
		# Seleccionar planeta ponderado
		var planet_idx: int = _weighted_select(pesos, peso_total)
		if planet_idx < 0 or planet_idx >= planetas.size():
			continue

		var p: Dictionary = planetas[planet_idx]
		var pid: int = int(p["id"])

		# Evitar duplicados en el mismo planeta este turno
		if planetas_con_evento.has(pid):
			continue
		planetas_con_evento[pid] = true

		# Seleccionar tipo de evento apropiado para este planeta
		var event_def: Dictionary = _select_event_type(p, severity)
		if event_def.is_empty():
			continue

		# Crear instancia del evento
		var evento: Dictionary = {
			"id": str(event_def["id"]) + "_" + str(turno) + "_" + str(pid),
			"definition_id": str(event_def["id"]),
			"nombre": str(event_def["nombre"]),
			"descripcion": str(event_def["descripcion"]),
			"severity": severity,
			"category": int(event_def["category"]),
			"planeta_id": pid,
			"planeta_nombre": str(p["nombre"]),
			"segmentum": str(p["segmentum"]),
			"sector": str(p["sector"]),
			"turno": turno,
			"duracion": int(event_def["duracion"]),
			"turnos_restantes": int(event_def["duracion"]),
			"efectos": event_def["efectos"],
			"resuelto": false,
		}

		# Aplicar efectos inmediatos al planeta
		_apply_effects(p, event_def["efectos"])

		# Marcar planeta con amenaza
		p["amenaza_actual"] = str(event_def["nombre"])

		# Auto-generar campaña para eventos militares MEDIUM+
		if severity >= EventDefinitions.Severity.MEDIUM:
			var cat: int = int(event_def["category"])
			if cat in [EventDefinitions.Category.MILITARY, EventDefinitions.Category.CHAOS,
				EventDefinitions.Category.XENOS]:
				_auto_create_campaign(p, event_def, severity)

		# Reducir peso del planeta para futuros eventos este turno
		pesos[planet_idx] *= 0.1

		eventos.append(evento)

func _weighted_select(pesos: Array, peso_total: float) -> int:
	if peso_total <= 0.0:
		return -1
	var roll: float = rng.randf() * peso_total
	var acum: float = 0.0
	for i: int in pesos.size():
		acum += float(pesos[i])
		if acum >= roll:
			return i
	return pesos.size() - 1

func _select_event_type(planet: Dictionary, target_severity: int) -> Dictionary:
	# Filtrar eventos que coincidan con la severidad y condiciones del planeta
	var candidates: Array = []

	var lealtad: int = int(planet["lealtad_imperial"])
	var fe: int = int(planet["fe_imperial"])
	var chaos: int = int(planet["infiltracion_caos"])
	var gs: int = int(planet["infiltracion_genestealer"])
	var corrupcion: int = int(planet["corrupcion_gobernador"])
	var warp: int = int(planet["estabilidad_warp"])
	var industrial: int = int(planet["capacidad_industrial"])
	var militar: int = int(planet["capacidad_militar"])
	var es_tomb: bool = bool(planet.get("es_tomb_world", false))

	for ev_idx: int in EventDefinitions.EVENTS.size():
		var ev: Dictionary = EventDefinitions.EVENTS[ev_idx]
		if int(ev["severity"]) != target_severity:
			continue

		# Evaluar condición simple (string parsing básico)
		var cond: String = str(ev["condicion"])
		var passes: bool = _eval_condition(cond, lealtad, fe, chaos, gs, corrupcion, warp, industrial, militar, es_tomb)

		if passes:
			candidates.append(ev)

	if candidates.is_empty():
		return {}

	# Elegir random entre candidatos
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func _eval_condition(cond: String, lealtad: int, fe: int, chaos: int, gs: int,
	corrupcion: int, warp: int, industrial: int, militar: int, es_tomb: bool) -> bool:
	# Parser simple de condiciones — evalúa expresiones como "lealtad < 60"
	# Soporta: <, >, and, or y variables predefinidas
	if cond == "es_tomb_world":
		return es_tomb

	# Separar por "and"
	var parts: PackedStringArray = cond.split(" and ")
	for part_idx: int in parts.size():
		var part: String = parts[part_idx].strip_edges()
		if not _eval_single(part, lealtad, fe, chaos, gs, corrupcion, warp, industrial, militar):
			return false
	return true

func _eval_single(expr: String, lealtad: int, fe: int, chaos: int, gs: int,
	corrupcion: int, warp: int, industrial: int, militar: int) -> bool:
	# Parsear "variable op valor"
	var val_map: Dictionary = {
		"lealtad": lealtad, "fe": fe, "infiltracion_caos": chaos,
		"infiltracion_genestealer": gs, "corrupcion_gobernador": corrupcion,
		"estabilidad_warp": warp, "capacidad_industrial": industrial,
		"capacidad_militar": militar,
	}

	if expr.contains(" < "):
		var p: PackedStringArray = expr.split(" < ")
		var var_name: String = p[0].strip_edges()
		var threshold: int = int(p[1].strip_edges())
		return int(val_map.get(var_name, 50)) < threshold
	elif expr.contains(" > "):
		var p: PackedStringArray = expr.split(" > ")
		var var_name: String = p[0].strip_edges()
		var threshold: int = int(p[1].strip_edges())
		return int(val_map.get(var_name, 50)) > threshold

	return false # Condición no reconocida

func _auto_create_campaign(planet: Dictionary, event_def: Dictionary, severity: int) -> void:
	var gd_node: Node = Engine.get_main_loop().root.get_node_or_null("GameData")
	if gd_node == null:
		return

	# Verificar que no haya ya una campaña en este planeta
	var camp_sys: CampaignSystem = CampaignSystem.new()
	var existing: Dictionary = camp_sys.get_campaign_at_planet(gd_node.campaigns, int(planet["id"]))
	if not existing.is_empty():
		return

	# Determinar tipo de enemigo por categoría
	var enemigo: String = "rebellion"
	var cat: int = int(event_def["category"])
	if cat == EventDefinitions.Category.CHAOS:
		enemigo = "chaos"
	elif cat == EventDefinitions.Category.XENOS:
		var ev_id: String = str(event_def["id"])
		if ev_id.contains("ork"): enemigo = "ork"
		elif ev_id.contains("genestealer"): enemigo = "genestealer"
		elif ev_id.contains("tyranid") or ev_id.contains("hive"): enemigo = "tyranid"
		else: enemigo = "ork"

	# Poder enemigo basado en severidad
	var poder_base: int = 5000
	if severity == EventDefinitions.Severity.MAJOR:
		poder_base = rng.randi_range(20000, 80000)
	elif severity == EventDefinitions.Severity.APOCALYPTIC:
		poder_base = rng.randi_range(100000, 500000)
	else:
		poder_base = rng.randi_range(5000, 20000)

	var camp: Dictionary = camp_sys.create_campaign(planet, enemigo, poder_base,
		"defensa_planetaria", gd_node.military_units)
	gd_node.campaigns.append(camp)

func _apply_effects(planet: Dictionary, efectos: Dictionary) -> void:
	for key: String in efectos:
		if planet.has(key):
			var current: int = int(planet[key])
			var delta: int = int(efectos[key])
			planet[key] = clampi(current + delta, 0, 100)
