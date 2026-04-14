## main.gd - Punto de entrada del juego
## Genera la galaxia y muestra un resumen en consola
extends Node

var galaxy: Dictionary

func _ready() -> void:
	print("=" .repeat(70))
	print("  SUPER WARHAMMER - Imperium of Man Galaxy Generator")
	print("  Era Indomitus, circa M42")
	print("=" .repeat(70))
	print("")

	var start: int = Time.get_ticks_msec()

	var generator: GalaxyGenerator = GalaxyGenerator.new()
	galaxy = generator.generate_galaxy(42)

	var elapsed: int = Time.get_ticks_msec() - start
	print(">>> Galaxia generada en %d ms" % elapsed)
	print("")

	_print_summary()
	_print_segmentum_detail()
	_print_type_distribution()
	_print_canonical_planets()
	_print_first_planets_per_segmentum()
	_print_rift_division()
	_print_hidden_stats()

	print("")
	print("=" .repeat(70))
	print("  Generación completa. El Emperador Protege.")
	print("=" .repeat(70))

# =============================================================================
# RESUMEN GENERAL
# =============================================================================

func _print_summary() -> void:
	var stats: Dictionary = galaxy["stats"]
	print("--- RESUMEN GENERAL ---")
	print("  Total de planetas: %d" % int(stats["total_planetas"]))
	print("  Población total del Imperium: %s" % _format_population(int(stats["poblacion_total"])))
	print("  Planetas canónicos: %d" % int(stats["planetas_canonicos"]))
	print("  Tomb Worlds ocultos: %d (el jugador no lo sabe)" % int(stats["tomb_worlds_ocultos"]))
	print("")

# =============================================================================
# DETALLE POR SEGMENTUM
# =============================================================================

func _print_segmentum_detail() -> void:
	print("--- PLANETAS POR SEGMENTUM ---")
	var stats: Dictionary = galaxy["stats"]
	var seg_names: Dictionary = {
		"solar": "Segmentum Solar",
		"obscurus": "Segmentum Obscurus",
		"ultima": "Segmentum Ultima",
		"tempestus": "Segmentum Tempestus",
		"pacificus": "Segmentum Pacificus",
	}

	var seg_order: Array = ["solar", "obscurus", "ultima", "tempestus", "pacificus"]
	for seg_idx: int in seg_order.size():
		var seg_key: String = seg_order[seg_idx]
		var count: int = int(stats["por_segmentum"].get(seg_key, 0))
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		var sectores_dict: Dictionary = seg["sectores"]
		var sector_count: int = sectores_dict.size()
		var sub_count: int = 0
		for sec_key: String in sectores_dict:
			var sec: Dictionary = sectores_dict[sec_key]
			var sub_dict: Dictionary = sec["subsectores"]
			sub_count += sub_dict.size()
		print("  %s: %d planetas (%d sectores, %d subsectores)" % [
			str(seg_names[seg_key]), count, sector_count, sub_count
		])

		# Detalle por sector
		for sec_key: String in sectores_dict:
			var sec: Dictionary = sectores_dict[sec_key]
			var sub_dict: Dictionary = sec["subsectores"]
			var sec_planets: int = 0
			for sub_key: String in sub_dict:
				var sub: Dictionary = sub_dict[sub_key]
				var planetas: Array = sub["planetas"]
				sec_planets += planetas.size()
			var lado: String = str(sec["lado_grieta"])
			print("    └─ %s [%s]: %d planetas" % [str(sec["nombre"]), lado.to_upper(), sec_planets])
	print("")

# =============================================================================
# DISTRIBUCIÓN POR TIPO
# =============================================================================

func _print_type_distribution() -> void:
	print("--- DISTRIBUCIÓN POR TIPO DE MUNDO ---")
	var stats: Dictionary = galaxy["stats"]
	var type_counts: Dictionary = stats["por_tipo"]

	# Ordenar por cantidad (mayor a menor)
	var types_sorted: Array = type_counts.keys()
	types_sorted.sort_custom(func(a: Variant, b: Variant) -> bool: return int(type_counts[a]) > int(type_counts[b]))

	var total: int = int(stats["total_planetas"])
	for t_idx: int in types_sorted.size():
		var tipo: String = str(types_sorted[t_idx])
		var count: int = int(type_counts[tipo])
		var nombre: String = str(PlanetTypes.TYPES[tipo]["nombre"]) if PlanetTypes.TYPES.has(tipo) else tipo
		var pct: float = (float(count) / float(total)) * 100.0
		var bar: String = "#".repeat(int(pct))
		print("  %-25s %4d (%5.1f%%) %s" % [nombre, count, pct, bar])
	print("")

# =============================================================================
# PLANETAS CANÓNICOS
# =============================================================================

func _print_canonical_planets() -> void:
	print("--- PLANETAS CANÓNICOS ENCONTRADOS ---")
	var planetas: Array = galaxy["planetas"]
	for p_idx: int in planetas.size():
		var planet: Dictionary = planetas[p_idx]
		if not planet["es_canonico"]:
			continue
		var tipo: String = str(planet["tipo"])
		var tipo_name: String = str(PlanetTypes.TYPES[tipo]["nombre"]) if PlanetTypes.TYPES.has(tipo) else tipo
		var flags: Array = planet["flags"]
		var flags_str: String = ""
		if not flags.is_empty():
			var flag_strs: PackedStringArray = PackedStringArray()
			for f_idx: int in flags.size():
				flag_strs.append(str(flags[f_idx]))
			flags_str = " [%s]" % ", ".join(flag_strs)
		print("  %-15s | %-22s | Pop: %-15s | Tithe: %-16s | %s%s" % [
			str(planet["nombre"]),
			tipo_name,
			_format_population(int(planet["poblacion"])),
			str(planet["tithe_grade"]),
			str(planet["lado_grieta"]).to_upper(),
			flags_str,
		])
	print("")

# =============================================================================
# PRIMEROS 5 PLANETAS POR SEGMENTUM
# =============================================================================

func _print_first_planets_per_segmentum() -> void:
	print("--- MUESTRA: 5 PLANETAS POR SEGMENTUM ---")
	var seg_order: Array = ["solar", "obscurus", "ultima", "tempestus", "pacificus"]
	for seg_idx: int in seg_order.size():
		var seg_key: String = seg_order[seg_idx]
		var seg: Dictionary = galaxy["segmentae"][seg_key]
		print("  [%s]" % str(seg["nombre"]))
		var shown: int = 0
		for sec_key: String in seg["sectores"]:
			if shown >= 5:
				break
			var sec: Dictionary = seg["sectores"][sec_key]
			for sub_key: String in sec["subsectores"]:
				if shown >= 5:
					break
				var sub: Dictionary = sec["subsectores"][sub_key]
				var planetas: Array = sub["planetas"]
				for p_idx: int in planetas.size():
					if shown >= 5:
						break
					var planet: Dictionary = planetas[p_idx]
					var tipo: String = str(planet["tipo"])
					var tipo_name: String = str(PlanetTypes.TYPES[tipo]["nombre"]) if PlanetTypes.TYPES.has(tipo) else tipo
					print("    %-20s | %-22s | Pop: %-15s | %s > %s" % [
						str(planet["nombre"]),
						tipo_name,
						_format_population(int(planet["poblacion"])),
						str(sec["nombre"]),
						str(sub["nombre"]),
					])
					shown += 1
		print("")

# =============================================================================
# DIVISIÓN DE LA GRAN GRIETA
# =============================================================================

func _print_rift_division() -> void:
	print("--- GRAN GRIETA (Cicatrix Maledictum) ---")
	var stats: Dictionary = galaxy["stats"]
	var grieta: Dictionary = stats["por_lado_grieta"]
	var sanctus: int = int(grieta["sanctus"])
	var nihilus: int = int(grieta["nihilus"])
	var total: int = int(stats["total_planetas"])
	print("  Imperium Sanctus: %d planetas (%.1f%%)" % [sanctus, float(sanctus) / float(total) * 100.0])
	print("  Imperium Nihilus:  %d planetas (%.1f%%)" % [nihilus, float(nihilus) / float(total) * 100.0])
	print("  > Los planetas en Nihilus tienen peores stats base (aislados del Astronomicón)")
	print("")

# =============================================================================
# STATS OCULTAS (debug)
# =============================================================================

func _print_hidden_stats() -> void:
	print("--- ESTADÍSTICAS OCULTAS (debug) ---")
	var tomb_count: int = 0
	var high_chaos: int = 0
	var high_gs: int = 0
	var corrupt_gov: int = 0

	var planetas: Array = galaxy["planetas"]
	for p_idx: int in planetas.size():
		var planet: Dictionary = planetas[p_idx]
		if planet["es_tomb_world"]:
			tomb_count += 1
		if int(planet["infiltracion_caos"]) > 30:
			high_chaos += 1
		if int(planet["infiltracion_genestealer"]) > 3:
			high_gs += 1
		if int(planet["corrupcion_gobernador"]) > 15:
			corrupt_gov += 1

	print("  Tomb Worlds ocultos: %d" % tomb_count)
	print("  Planetas con alta infiltración Caos (>30): %d" % high_chaos)
	print("  Planetas con semilla Genestealer (>3): %d" % high_gs)
	print("  Gobernadores corruptos (>15): %d" % corrupt_gov)

# =============================================================================
# UTILIDADES DE FORMATO
# =============================================================================

func _format_population(pop: int) -> String:
	if pop <= 0:
		return "0"
	elif pop >= 1_000_000_000_000:
		return "%.1f billones" % (float(pop) / 1_000_000_000_000.0)
	elif pop >= 1_000_000_000:
		return "%.1f mil M" % (float(pop) / 1_000_000_000.0)
	elif pop >= 1_000_000:
		return "%.1f M" % (float(pop) / 1_000_000.0)
	elif pop >= 1_000:
		return "%.1f K" % (float(pop) / 1_000.0)
	else:
		return str(pop)
