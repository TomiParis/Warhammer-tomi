## chapter_generator.gd - Genera capítulos canónicos + inventados
## Para agregar capítulos: agregar en ChapterData.CANONICAL_CHAPTERS
class_name ChapterGenerator

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _used_names: Dictionary = {}
var _next_id: int = 200000

func generate_chapters(galaxy: Dictionary, seed_value: int = 42) -> Array:
	rng.seed = seed_value + 7777 # Offset del seed para no coincidir con planetas
	_used_names.clear()

	var chapters: Array = []

	# Paso 1: Generar capítulos canónicos
	for canon_idx: int in ChapterData.CANONICAL_CHAPTERS.size():
		var canon: Dictionary = ChapterData.CANONICAL_CHAPTERS[canon_idx]
		var chapter: Dictionary = _create_canonical_chapter(canon, galaxy)
		chapters.append(chapter)
		_used_names[str(canon["nombre"])] = true

	# Paso 2: Generar ~18 capítulos inventados
	var generated_count: int = 18
	for _i: int in generated_count:
		var chapter: Dictionary = _generate_chapter(galaxy)
		if not chapter.is_empty():
			chapters.append(chapter)

	return chapters

# =============================================================================
# CAPÍTULOS CANÓNICOS
# =============================================================================

func _create_canonical_chapter(canon: Dictionary, galaxy: Dictionary) -> Dictionary:
	var mundo_natal_id: int = -1
	var segmentum: String = ""

	# Buscar planeta del mundo natal
	if not bool(canon.get("fleet_based", false)):
		var mundo_nombre: String = str(canon["mundo_natal"])
		var planetas: Array = galaxy.get("planetas", [])
		for p_idx: int in planetas.size():
			var p: Dictionary = planetas[p_idx]
			if str(p["nombre"]) == mundo_nombre:
				mundo_natal_id = int(p["id"])
				segmentum = str(p["segmentum"])
				# Marcar presencia Astartes en el planeta
				p["guarnicion"]["astartes_presencia"] = str(canon["nombre"])
				break

	# Si no encontró planeta (fleet-based o no existe), asignar segmentum por defecto
	if segmentum == "":
		match str(canon["nombre"]):
			"Ultramarines": segmentum = "ultima"
			"Blood Angels": segmentum = "ultima"
			"Dark Angels": segmentum = "obscurus"
			"Space Wolves": segmentum = "obscurus"
			"Imperial Fists": segmentum = "solar"
			"White Scars": segmentum = "ultima"
			"Iron Hands": segmentum = "obscurus"
			"Raven Guard": segmentum = "ultima"
			"Salamanders": segmentum = "ultima"
			"Black Templars": segmentum = "obscurus"
			"Grey Knights": segmentum = "solar"
			"Deathwatch": segmentum = "ultima"
			_: segmentum = "solar"

	var chapter: Dictionary = {
		"id": _next_id,
		"nombre": str(canon["nombre"]),
		"primarca": str(canon["primarca"]),
		"primarca_estado": str(canon["primarca_estado"]),
		"fundacion": str(canon["fundacion"]),
		"progenitor": str(canon["progenitor"]),
		"mundo_natal": str(canon["mundo_natal"]),
		"mundo_natal_id": mundo_natal_id,
		"segmentum": segmentum,
		"chapter_master": str(canon["chapter_master"]),
		"fuerza_total": int(canon["fuerza_total"]),
		"gene_seed": str(canon["gene_seed"]),
		"especialidad": str(canon["especialidad"]),
		"color_primario": canon["color_primario"],
		"color_secundario": canon["color_secundario"],
		"es_canonico": true,
		"fleet_based": bool(canon.get("fleet_based", false)),
		"companias": _create_companies(int(canon["fuerza_total"])),
		"flota": _create_fleet(bool(canon.get("fleet_based", false))),
		"historial": [],
		"disponible": true,
		"mision_actual": "",
	}
	_next_id += 1
	return chapter

# =============================================================================
# CAPÍTULOS GENERADOS
# =============================================================================

func _generate_chapter(galaxy: Dictionary) -> Dictionary:
	var nombre: String = _generate_name()
	if nombre == "":
		return {}

	# Elegir progenitor ponderado
	var progenitor: String = _weighted_pick(ChapterData.PROGENITOR_WEIGHTS)

	# Elegir fundación
	var fundaciones: Array = ["Segunda", "Tercera", "Cuarta", "Octava", "Décima",
		"Decimotercera", "Vigesimoprimera", "Vigesimosexta", "Ultima (Primaris)"]
	var fundacion: String = fundaciones[rng.randi_range(0, fundaciones.size() - 1)]

	# Fleet-based (~30%)
	var fleet_based: bool = rng.randf() < 0.3

	# Mundo natal (buscar planet death_world o feral_world)
	var mundo_natal: String = "Fleet-based"
	var mundo_natal_id: int = -1
	var segmentum: String = ""

	if not fleet_based:
		var candidates: Array = []
		var planetas: Array = galaxy.get("planetas", [])
		for p_idx: int in planetas.size():
			var p: Dictionary = planetas[p_idx]
			var tipo: String = str(p["tipo"])
			if tipo in ["death_world", "feral_world", "feudal_world"]:
				# Solo si no tiene ya un capítulo
				if p["guarnicion"]["astartes_presencia"] == null:
					candidates.append(p)
		if not candidates.is_empty():
			var chosen: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
			mundo_natal = str(chosen["nombre"])
			mundo_natal_id = int(chosen["id"])
			segmentum = str(chosen["segmentum"])
			chosen["guarnicion"]["astartes_presencia"] = nombre

	if segmentum == "":
		var segs: Array = ["solar", "obscurus", "ultima", "tempestus", "pacificus"]
		segmentum = segs[rng.randi_range(0, segs.size() - 1)]

	# Fuerza (no todos a capacidad)
	var fuerza: int = rng.randi_range(600, 1000)

	# Gene-seed
	var gs_roll: float = rng.randf()
	var gene_seed: String = "puro"
	if gs_roll > 0.95: gene_seed = "mutante"
	elif gs_roll > 0.85: gene_seed = "degradado"
	elif gs_roll > 0.60: gene_seed = "estable"

	# Especialidad
	var esp: String = ChapterData.SPECIALTIES[rng.randi_range(0, ChapterData.SPECIALTIES.size() - 1)]

	# Colores aleatorios pero no demasiado brillantes
	var col1: Color = Color(rng.randf_range(0.1, 0.8), rng.randf_range(0.1, 0.8), rng.randf_range(0.1, 0.8))
	var col2: Color = Color(rng.randf_range(0.1, 0.7), rng.randf_range(0.1, 0.7), rng.randf_range(0.1, 0.7))

	# Chapter Master
	var master: String = "Chapter Master " + ChapterData.MASTER_NAMES[rng.randi_range(0, ChapterData.MASTER_NAMES.size() - 1)]

	var chapter: Dictionary = {
		"id": _next_id,
		"nombre": nombre,
		"primarca": "Desconocido",
		"primarca_estado": "n/a",
		"fundacion": fundacion,
		"progenitor": progenitor,
		"mundo_natal": mundo_natal,
		"mundo_natal_id": mundo_natal_id,
		"segmentum": segmentum,
		"chapter_master": master,
		"fuerza_total": fuerza,
		"gene_seed": gene_seed,
		"especialidad": esp,
		"color_primario": col1,
		"color_secundario": col2,
		"es_canonico": false,
		"fleet_based": fleet_based,
		"companias": _create_companies(fuerza),
		"flota": _create_fleet(fleet_based),
		"historial": [],
		"disponible": true,
		"mision_actual": "",
	}
	_next_id += 1
	return chapter

# =============================================================================
# UTILIDADES
# =============================================================================

func _create_companies(fuerza_total: int) -> Array:
	var companies: Array = []
	var remaining: int = fuerza_total

	for tmpl_idx: int in ChapterData.COMPANY_TEMPLATE.size():
		var tmpl: Dictionary = ChapterData.COMPANY_TEMPLATE[tmpl_idx]
		var max_f: int = int(tmpl["fuerza_max"])
		var fuerza: int = mini(remaining, max_f)
		if fuerza < 0:
			fuerza = 0
		remaining -= fuerza

		companies.append({
			"numero": int(tmpl["numero"]),
			"nombre": str(tmpl["nombre"]),
			"tipo": str(tmpl["tipo"]),
			"fuerza": fuerza,
			"fuerza_max": max_f,
			"estado": "base",
			"planeta_desplegada": -1,
		})

	return companies

func _create_fleet(is_fleet_based: bool) -> Dictionary:
	return {
		"battle_barges": 1,
		"strike_cruisers": 2 if not is_fleet_based else 4,
		"escorts": rng.randi_range(3, 8),
	}

func _generate_name() -> String:
	for _attempt: int in 50:
		var prefix: String = ChapterData.NAME_PREFIXES[rng.randi_range(0, ChapterData.NAME_PREFIXES.size() - 1)]
		var suffix: String = ChapterData.NAME_SUFFIXES[rng.randi_range(0, ChapterData.NAME_SUFFIXES.size() - 1)]
		var name: String = prefix + " " + suffix
		if not _used_names.has(name):
			_used_names[name] = true
			return name
	return ""

func _weighted_pick(weights: Dictionary) -> String:
	var total: float = 0.0
	for key: String in weights:
		total += float(weights[key])
	var roll: float = rng.randf() * total
	var accum: float = 0.0
	for key: String in weights:
		accum += float(weights[key])
		if accum >= roll:
			return key
	return weights.keys()[0]
