## chapter_system.gd - Procesa capítulos cada turno
## Reclutamiento, recuperación, despliegue autónomo
class_name ChapterSystem

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func process(chapters: Array, planetas: Array, turno: int) -> Dictionary:
	var resumen: Dictionary = {
		"reclutados": 0,
		"desplegados": 0,
		"recuperados": 0,
	}

	for ch_idx: int in chapters.size():
		var ch: Dictionary = chapters[ch_idx]

		# Reclutamiento (lento, +2-5 marines/turno si en mundo natal)
		_process_recruitment(ch, resumen)

		# Recuperación de compañías dañadas
		_process_recovery(ch, resumen)

		# Despliegue autónomo (IA simple)
		_process_autonomous_deployment(ch, planetas, turno, resumen)

	return resumen

func _process_recruitment(chapter: Dictionary, resumen: Dictionary) -> void:
	if int(chapter["mundo_natal_id"]) < 0 and not bool(chapter["fleet_based"]):
		return # Sin mundo natal y no fleet-based = sin reclutamiento

	var fuerza: int = int(chapter["fuerza_total"])
	var max_fuerza: int = 1000
	if str(chapter["nombre"]) == "Black Templars":
		max_fuerza = 6000

	if fuerza >= max_fuerza:
		return

	# +2-5 marines por turno (muy lento)
	var nuevos: int = rng.randi_range(2, 5)

	# Gene-seed degradado = menos reclutas
	if str(chapter["gene_seed"]) == "degradado":
		nuevos = rng.randi_range(1, 3)
	elif str(chapter["gene_seed"]) == "mutante":
		nuevos = rng.randi_range(0, 2)

	nuevos = mini(nuevos, max_fuerza - fuerza)
	chapter["fuerza_total"] = fuerza + nuevos
	resumen["reclutados"] += nuevos

	# Agregar a la 10ma compañía (Scouts)
	var companias: Array = chapter["companias"]
	if companias.size() >= 10:
		var scouts: Dictionary = companias[9]
		scouts["fuerza"] = mini(int(scouts["fuerza"]) + nuevos, int(scouts["fuerza_max"]) + 20) # Scouts puede exceder

func _process_recovery(chapter: Dictionary, resumen: Dictionary) -> void:
	var companias: Array = chapter["companias"]
	for comp_idx: int in companias.size():
		var comp: Dictionary = companias[comp_idx]
		if str(comp["estado"]) == "recuperandose":
			# Recupera 5-10 marines por turno de la reserva de Scouts
			var recovery: int = rng.randi_range(3, 8)
			comp["fuerza"] = mini(int(comp["fuerza"]) + recovery, int(comp["fuerza_max"]))
			if int(comp["fuerza"]) >= int(comp["fuerza_max"]) * 0.8:
				comp["estado"] = "base"
				comp["planeta_desplegada"] = -1
				resumen["recuperados"] += 1

func _process_autonomous_deployment(chapter: Dictionary, planetas: Array, _turno: int, resumen: Dictionary) -> void:
	# Solo desplegar si el capítulo está disponible y no en misión
	if not bool(chapter["disponible"]):
		return
	if str(chapter["mision_actual"]) != "":
		return

	# Buscar amenazas graves en su segmentum
	var seg: String = str(chapter["segmentum"])
	var worst_threat_planet: Dictionary = {}
	var worst_threat_score: float = 0.0

	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		if str(p["segmentum"]) != seg:
			continue
		if p.get("amenaza_actual") == null:
			continue

		var score: float = float(100 - int(p["capacidad_militar"])) + float(int(p["infiltracion_caos"])) * 0.5
		if score > worst_threat_score and score > 60.0:
			worst_threat_score = score
			worst_threat_planet = p

	# ~20% chance de desplegar autónomamente ante amenaza grave
	if not worst_threat_planet.is_empty() and rng.randf() < 0.20:
		# Desplegar una compañía de batalla
		var companias: Array = chapter["companias"]
		for comp_idx: int in range(1, 5): # Compañías 2-5 (batalla)
			if comp_idx >= companias.size():
				break
			var comp: Dictionary = companias[comp_idx]
			if str(comp["estado"]) == "base" and int(comp["fuerza"]) > 50:
				comp["estado"] = "desplegada"
				comp["planeta_desplegada"] = int(worst_threat_planet["id"])
				chapter["mision_actual"] = "Defendiendo " + str(worst_threat_planet["nombre"])
				resumen["desplegados"] += 1

				# Boost militar al planeta
				var mil: int = int(worst_threat_planet["capacidad_militar"])
				worst_threat_planet["capacidad_militar"] = clampi(mil + 25, 0, 100)
				break

# =============================================================================
# FUNCIONES PÚBLICAS
# =============================================================================

func deploy_company(chapter: Dictionary, company_idx: int, planet: Dictionary) -> bool:
	if company_idx < 0 or company_idx >= chapter["companias"].size():
		return false
	var comp: Dictionary = chapter["companias"][company_idx]
	if str(comp["estado"]) != "base":
		return false
	comp["estado"] = "desplegada"
	comp["planeta_desplegada"] = int(planet["id"])
	chapter["mision_actual"] = "Desplegado en " + str(planet["nombre"])
	chapter["disponible"] = false
	planet["capacidad_militar"] = clampi(int(planet["capacidad_militar"]) + 25, 0, 100)
	return true

func recall_company(chapter: Dictionary, company_idx: int) -> bool:
	if company_idx < 0 or company_idx >= chapter["companias"].size():
		return false
	var comp: Dictionary = chapter["companias"][company_idx]
	if str(comp["estado"]) != "desplegada" and str(comp["estado"]) != "en_combate":
		return false
	comp["estado"] = "en_transito"
	comp["planeta_desplegada"] = -1
	# Verificar si todas las compañías están en base
	var all_base: bool = true
	for c: Dictionary in chapter["companias"]:
		if str(c["estado"]) != "base" and str(c["estado"]) != "en_transito":
			all_base = false
			break
	if all_base:
		chapter["mision_actual"] = ""
		chapter["disponible"] = true
	return true

func get_chapter_at_planet(chapters: Array, planet_id: int) -> Dictionary:
	for ch: Dictionary in chapters:
		if int(ch["mundo_natal_id"]) == planet_id:
			return ch
		for comp: Dictionary in ch["companias"]:
			if int(comp.get("planeta_desplegada", -1)) == planet_id:
				return ch
	return {}
