## game_data.gd - Singleton autoload con toda la data del juego
## Lee de los archivos de configuración en scripts/data/
## NUNCA hardcodear datos aquí — solo proveer acceso centralizado
extends Node

# === DATOS DE LA GALAXIA (generados al inicio) ===
var galaxy: Dictionary = {}

# === CAPÍTULOS DE SPACE MARINES ===
var chapters: Array = [] # Todos los capítulos
var chapters_by_id: Dictionary = {} # id -> chapter dict

# === ACCESOS RÁPIDOS (se llenan después de generar) ===
var planets_by_id: Dictionary = {} # id -> planet dict
var sectors_by_key: Dictionary = {} # "seg.sec" -> sector data

# === REFERENCIAS A DATOS ESTÁTICOS (class_name based) ===
# Acceso: GameData.planet_types(), GameData.galaxy_config(), etc.

static func planet_types() -> Dictionary:
	return PlanetTypes.TYPES

static func type_weights() -> Dictionary:
	return PlanetTypes.TYPE_WEIGHTS

static func tithe_grades() -> Dictionary:
	return PlanetTypes.TITHE_GRADES

static func planet_colors() -> Dictionary:
	return PlanetTypes.COLORS

static func segmentum_config() -> Dictionary:
	return GalaxyConfig.SEGMENTUM_CONFIG

static func sector_config() -> Dictionary:
	return GalaxyConfig.SECTOR_CONFIG

static func seg_arcs() -> Dictionary:
	return GalaxyConfig.SEG_ARCS

static func seg_colors() -> Dictionary:
	return GalaxyConfig.SEG_COLORS

static func canonical_planets() -> Array:
	return CanonicalData.PLANETS

# === CONSTANTES GEOMÉTRICAS ===
static func galaxy_disc_radius() -> float:
	return GalaxyConfig.GALAXY_DISC_RADIUS

static func solar_radius() -> float:
	return GalaxyConfig.SOLAR_RADIUS

static func map_radius() -> float:
	return GalaxyConfig.MAP_RADIUS

static func terra_offset() -> Vector2:
	return GalaxyConfig.TERRA_OFFSET

static func astronomican_radius() -> float:
	return GalaxyConfig.ASTRONOMICAN_RADIUS

# === FUNCIONES DE ACCESO ===

func get_planet(id: int) -> Dictionary:
	return planets_by_id.get(id, {})

func get_all_planets() -> Array:
	return galaxy.get("planetas", [])

func get_total_planets() -> int:
	var planetas: Array = galaxy.get("planetas", [])
	return planetas.size()

# Calcula el total de planetas a generar desde la config
static func get_target_planet_count() -> int:
	var total: int = 0
	for seg_key: String in GalaxyConfig.SEGMENTUM_CONFIG:
		total += int(GalaxyConfig.SEGMENTUM_CONFIG[seg_key]["planetas_target"])
	return total

# Inicializar después de generar la galaxia
func set_galaxy(new_galaxy: Dictionary) -> void:
	galaxy = new_galaxy
	_build_indexes()

func set_chapters(new_chapters: Array) -> void:
	chapters = new_chapters
	chapters_by_id.clear()
	for ch_idx: int in chapters.size():
		var ch: Dictionary = chapters[ch_idx]
		chapters_by_id[int(ch["id"])] = ch

func get_chapter_at_planet(planet_id: int) -> Dictionary:
	for ch: Dictionary in chapters:
		if int(ch["mundo_natal_id"]) == planet_id:
			return ch
		for comp: Dictionary in ch["companias"]:
			if int(comp.get("planeta_desplegada", -1)) == planet_id:
				return ch
	return {}

func _build_indexes() -> void:
	planets_by_id.clear()
	sectors_by_key.clear()

	var planetas: Array = galaxy.get("planetas", [])
	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		var pid: int = int(p["id"])
		planets_by_id[pid] = p

	for seg_key: String in galaxy.get("segmentae", {}):
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		for sec_key: String in seg.get("sectores", {}):
			var full_key: String = seg_key + "." + sec_key
			sectors_by_key[full_key] = seg["sectores"][sec_key]
