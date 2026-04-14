## governance_system.gd - Procesa gobernanza cada turno
## Ambición de gobernadores, corrupción, sucesión, relaciones
class_name GovernanceSystem

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func process(planetas: Array, faction_relations: Dictionary, turno: int) -> Dictionary:
	var resumen: Dictionary = {
		"rebeliones": 0,
		"sucesiones": 0,
		"cambios_relacion": 0,
	}

	# Procesar cada planeta con gobernador expandido
	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		var ctrl: Dictionary = p.get("controlador", {})
		var tipo: String = str(ctrl.get("tipo", ""))

		if tipo == "gobernador_planetario" or tipo == "aristocracia_local" or tipo == "nobleza_local":
			_process_governor(p, ctrl, resumen, turno)
		elif tipo == "adeptus_arbites":
			_process_arbites(p, ctrl, resumen, turno)
		elif tipo == "ecclesiarquia" or tipo == "cardenal":
			_process_ecclesiarquia(p, ctrl)

	# Fluctuar relaciones entre facciones (sutil, ±1-2 por turno)
	for key: String in faction_relations:
		var delta: int = rng.randi_range(-1, 1)
		faction_relations[key] = clampi(int(faction_relations[key]) + delta, 5, 95)
		if delta != 0:
			resumen["cambios_relacion"] += 1

	return resumen

func _process_governor(planet: Dictionary, ctrl: Dictionary, resumen: Dictionary, _turno: int) -> void:
	if not ctrl.has("lealtad_personal"):
		return

	var lealtad_p: int = int(ctrl["lealtad_personal"])
	var competencia: int = int(ctrl.get("competencia", 50))
	var corrupcion: int = int(ctrl.get("corrupcion", 0))
	var ambicion: int = int(ctrl.get("ambicion", 30))

	# Corrupción crece lentamente
	corrupcion = clampi(corrupcion + (1 if rng.randf() < 0.08 else 0), 0, 100)

	# Ambición crece si el gobernador es competente y la corrupción es alta
	if competencia > 60 and corrupcion > 30:
		ambicion = clampi(ambicion + (1 if rng.randf() < 0.05 else 0), 0, 100)

	# Lealtad personal baja con alta corrupción
	if corrupcion > 50:
		lealtad_p = clampi(lealtad_p - 1, 0, 100)

	# Lealtad personal sube si el planeta es leal y tiene fe
	var planet_leal: int = int(planet["lealtad_imperial"])
	var planet_fe: int = int(planet["fe_imperial"])
	if planet_leal > 70 and planet_fe > 60:
		lealtad_p = clampi(lealtad_p + (1 if rng.randf() < 0.1 else 0), 0, 100)

	# Rebelión: si lealtad personal < 15 y ambición > 70
	if lealtad_p < 15 and ambicion > 70 and rng.randf() < 0.15:
		planet["amenaza_actual"] = "Rebelión del Gobernador"
		planet["lealtad_imperial"] = clampi(int(planet["lealtad_imperial"]) - 20, 0, 100)
		resumen["rebeliones"] += 1

	# Muerte natural (~0.5% por turno, genera sucesión)
	if rng.randf() < 0.005:
		_succession(planet, ctrl, resumen)

	ctrl["lealtad_personal"] = lealtad_p
	ctrl["competencia"] = competencia
	ctrl["corrupcion"] = corrupcion
	ctrl["ambicion"] = ambicion

func _process_arbites(planet: Dictionary, ctrl: Dictionary, resumen: Dictionary, _turno: int) -> void:
	# Ley marcial temporal: reducir turnos restantes
	if ctrl.has("turnos_restantes"):
		ctrl["turnos_restantes"] = int(ctrl["turnos_restantes"]) - 1
		if int(ctrl["turnos_restantes"]) <= 0:
			# Asignar nuevo gobernador
			_succession(planet, ctrl, resumen)
			ctrl["ley_marcial"] = false

func _process_ecclesiarquia(planet: Dictionary, ctrl: Dictionary) -> void:
	# Bonus de fe del controlador eclesiástico
	var fe_bonus: int = int(ctrl.get("fe_bonus", 0))
	if fe_bonus > 0:
		var fe: int = int(planet["fe_imperial"])
		planet["fe_imperial"] = clampi(fe + floori(float(fe_bonus) / 10.0), 0, 100)

func _succession(planet: Dictionary, ctrl: Dictionary, resumen: Dictionary) -> void:
	# Generar nuevo gobernador
	var new_idx: int = rng.randi_range(0, FactionData.DYNASTY_NAMES.size() - 1)
	var new_title_idx: int = rng.randi_range(0, FactionData.GOVERNOR_TITLES.size() - 1)

	ctrl["tipo"] = "gobernador_planetario"
	ctrl["nombre"] = str(FactionData.GOVERNOR_TITLES[new_title_idx]) + " " + str(FactionData.DYNASTY_NAMES[new_idx])
	ctrl["titulo"] = str(FactionData.GOVERNOR_TITLES[new_title_idx])
	ctrl["dinastia"] = "Casa " + str(FactionData.DYNASTY_NAMES[new_idx])
	ctrl["dinastia_siglos"] = 0
	ctrl["lealtad_personal"] = rng.randi_range(50, 80)
	ctrl["competencia"] = rng.randi_range(30, 70)
	ctrl["corrupcion"] = rng.randi_range(0, 15)
	ctrl["ambicion"] = rng.randi_range(15, 50)
	if ctrl.has("ley_marcial"):
		ctrl.erase("ley_marcial")
	if ctrl.has("turnos_restantes"):
		ctrl.erase("turnos_restantes")
	resumen["sucesiones"] += 1
