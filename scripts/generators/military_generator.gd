## military_generator.gd - Genera guarniciones y regimientos iniciales por planeta
class_name MilitaryGenerator

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _next_unit_id: int = MilitaryData.UNIT_ID_START

func generate(galaxy: Dictionary, seed_value: int = 42) -> Array:
	rng.seed = seed_value + 9999
	var units: Array = []

	var planetas: Array = galaxy.get("planetas", [])
	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		if int(p["poblacion"]) <= 0:
			continue

		var tipo: String = str(p["tipo"])
		var militar: int = int(p["capacidad_militar"])

		# Generar guarnición basada en tipo de planeta y capacidad militar
		var regiment_count: int = 0
		match tipo:
			"hive_world":
				regiment_count = rng.randi_range(3, 8)
			"fortress_world":
				regiment_count = rng.randi_range(5, 12)
			"civilised_world":
				regiment_count = rng.randi_range(1, 3)
			"forge_world":
				regiment_count = rng.randi_range(1, 2) # Skitarii, no regimientos IG
			_:
				if militar > 50:
					regiment_count = rng.randi_range(1, 2)
				elif militar > 30:
					regiment_count = 1 if rng.randf() < 0.5 else 0

		for _i: int in regiment_count:
			var unit: Dictionary = _create_regiment(p)
			units.append(unit)

	return units

func _create_regiment(planet: Dictionary) -> Dictionary:
	var prefix_idx: int = rng.randi_range(0, MilitaryData.REGIMENT_PREFIXES.size() - 1)
	var suffix_idx: int = rng.randi_range(0, MilitaryData.REGIMENT_SUFFIXES.size() - 1)
	var nombre: String = "%s %s %s" % [
		str(MilitaryData.REGIMENT_PREFIXES[prefix_idx]),
		str(planet["nombre"]),
		str(MilitaryData.REGIMENT_SUFFIXES[suffix_idx]),
	]

	var tipo_arma: String = "infanteria"
	var roll: float = rng.randf()
	if roll > 0.85:
		tipo_arma = "blindados"
	elif roll > 0.75:
		tipo_arma = "artilleria"
	elif roll > 0.70:
		tipo_arma = "aeronautica"

	var fuerza_max: int = rng.randi_range(3000, 10000)
	var fuerza: int = rng.randi_range(int(float(fuerza_max) * 0.7), fuerza_max)

	var exp_roll: float = rng.randf()
	var experiencia: String = "regular"
	if exp_roll > 0.9:
		experiencia = "elite"
	elif exp_roll > 0.7:
		experiencia = "veterano"
	elif exp_roll < 0.2:
		experiencia = "verde"

	var cmd_idx: int = rng.randi_range(0, MilitaryData.COMMANDER_NAMES.size() - 1)

	var unit: Dictionary = {
		"id": _next_unit_id,
		"nombre": nombre,
		"tipo_unidad": "regimiento",
		"tipo_arma": tipo_arma,
		"fuerza": fuerza,
		"fuerza_max": fuerza_max,
		"moral": rng.randi_range(50, 85),
		"experiencia": experiencia,
		"suministros_semanas": rng.randi_range(4, 12),
		"planeta_origen": str(planet["nombre"]),
		"planeta_origen_id": int(planet["id"]),
		"campana_id": -1,
		"estado": "guarnicion",
		"comandante": str(MilitaryData.COMMANDER_NAMES[cmd_idx]),
	}
	_next_unit_id += 1
	return unit

func recruit_regiment(planet: Dictionary) -> Dictionary:
	# Reclutar consume población
	var fuerza: int = rng.randi_range(3000, 8000)
	var pop: int = int(planet["poblacion"])
	if pop < fuerza * 10: # Necesita 10x la población del regimiento
		return {}
	planet["poblacion"] = pop - fuerza

	var unit: Dictionary = _create_regiment(planet)
	unit["experiencia"] = "verde" # Reclutas nuevos siempre verdes
	unit["moral"] = rng.randi_range(40, 60)
	unit["suministros_semanas"] = 4
	return unit
