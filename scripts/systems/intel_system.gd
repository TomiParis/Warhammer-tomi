## intel_system.gd - Esqueleto del sistema de inteligencia
## Fase E del turno: mensajes astropáticos, niveles de intel, revelaciones
class_name IntelSystem

# Mensajes en tránsito {id -> message_dict}
var messages_in_transit: Array = []

# Nivel de inteligencia por planeta {planet_id -> 0-100}
var intel_levels: Dictionary = {}

func process(planetas: Array, turno: int) -> Dictionary:
	var resumen: Dictionary = {
		"mensajes_recibidos": 0,
		"intel_actualizado": 0,
		"revelaciones": [],
	}

	# Procesar mensajes en tránsito (llegan con delay)
	var received: Array = []
	for msg_idx: int in messages_in_transit.size():
		var msg: Dictionary = messages_in_transit[msg_idx]
		msg["turnos_restantes"] = int(msg["turnos_restantes"]) - 1
		if int(msg["turnos_restantes"]) <= 0:
			received.append(msg_idx)
			resumen["mensajes_recibidos"] += 1
			# TODO: Procesar contenido del mensaje

	# Limpiar mensajes recibidos (en reversa para no romper índices)
	for i: int in range(received.size() - 1, -1, -1):
		messages_in_transit.remove_at(received[i])

	# Decay natural de inteligencia en planetas sin astropata
	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		var pid: int = int(p["id"])
		var current_intel: int = int(intel_levels.get(pid, 50))

		if not bool(p["tiene_astropata"]):
			current_intel = maxi(current_intel - 1, 0)

		# Nihilus pierde intel más rápido
		if str(p["lado_grieta"]) == "nihilus":
			current_intel = maxi(current_intel - 1, 0)

		intel_levels[pid] = current_intel

	return resumen

func send_message(from_planet_id: int, content: String, delay_turns: int) -> void:
	messages_in_transit.append({
		"from": from_planet_id,
		"content": content,
		"turnos_restantes": delay_turns,
	})

func get_intel_level(planet_id: int) -> int:
	return int(intel_levels.get(planet_id, 50))
