## movement_system.gd - Esqueleto del sistema de movimiento
## Fase F del turno: flotas, regimientos, Capítulos en tránsito
class_name MovementSystem

# Unidades en tránsito {id -> movement_dict}
var units_in_transit: Array = []
var _next_movement_id: int = 1

func process(_planetas: Array, _turno: int) -> Dictionary:
	var resumen: Dictionary = {
		"llegadas": 0,
		"en_transito": units_in_transit.size(),
		"reportes": [],
	}

	var arrived: Array = []
	for mov_idx: int in units_in_transit.size():
		var mov: Dictionary = units_in_transit[mov_idx]
		mov["turnos_restantes"] = int(mov["turnos_restantes"]) - 1

		if int(mov["turnos_restantes"]) <= 0:
			arrived.append(mov_idx)
			resumen["llegadas"] += 1
			resumen["reportes"].append(
				"%s llegó a %s" % [str(mov.get("unit_name", "?")), str(mov.get("destino_nombre", "?"))]
			)
			# TODO: Aplicar la unidad al planeta destino
			# (agregar guardia_imperial, astartes_presencia, etc.)

	# Limpiar llegadas (en reversa)
	for i: int in range(arrived.size() - 1, -1, -1):
		units_in_transit.remove_at(arrived[i])

	return resumen

func move_unit(unit_name: String, destino_id: int, destino_nombre: String, travel_turns: int) -> void:
	units_in_transit.append({
		"id": _next_movement_id,
		"unit_name": unit_name,
		"destino_id": destino_id,
		"destino_nombre": destino_nombre,
		"turnos_restantes": travel_turns,
	})
	_next_movement_id += 1

func get_units_en_route_to(planet_id: int) -> Array:
	var result: Array = []
	for mov: Dictionary in units_in_transit:
		if int(mov.get("destino_id", -1)) == planet_id:
			result.append(mov)
	return result
