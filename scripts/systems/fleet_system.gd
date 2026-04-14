## fleet_system.gd - Procesa flotas cada turno: viaje warp, logística, combate naval
class_name FleetSystem

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func process(fleet_data: Dictionary, planetas: Array, turno: int) -> Dictionary:
	var resumen: Dictionary = {
		"llegadas": 0,
		"en_transito": 0,
		"perdidos_warp": 0,
		"rutas_cortadas": 0,
	}

	# Procesar flotas en tránsito
	var in_transit: Array = fleet_data.get("fleets_in_transit", [])
	var arrived: Array = []

	for ft_idx: int in in_transit.size():
		var ft: Dictionary = in_transit[ft_idx]
		ft["turnos_restantes"] = int(ft["turnos_restantes"]) - 1

		if int(ft["turnos_restantes"]) <= 0:
			if bool(ft.get("perdido_warp", false)):
				# Reaparece
				ft["perdido_warp"] = false
				ft["turnos_restantes"] = 0
			arrived.append(ft_idx)
			resumen["llegadas"] += 1
		else:
			resumen["en_transito"] += 1

	# Limpiar llegados (reversa)
	for i: int in range(arrived.size() - 1, -1, -1):
		var ft: Dictionary = in_transit[arrived[i]]
		# Devolver transporte a disponible
		_return_transport(ft, fleet_data)
		in_transit.remove_at(arrived[i])

	# Fluctuar estabilidad de rutas warp
	var routes: Array = fleet_data.get("warp_routes", [])
	for r_idx: int in routes.size():
		var route: Dictionary = routes[r_idx]
		var delta: int = rng.randi_range(-2, 2)
		route["estabilidad"] = clampi(int(route["estabilidad"]) + delta, 5, 98)
		if int(route["estabilidad"]) < 20:
			resumen["rutas_cortadas"] += 1

	# Patrullas de Battlefleets reducen piratería
	var battlefleets: Array = fleet_data.get("battlefleets", [])
	for bf: Dictionary in battlefleets:
		if str(bf["estado"]) == "patrulla":
			var bf_sector: String = str(bf["sector"])
			for route: Dictionary in routes:
				if str(route["sector_a"]) == bf_sector or str(route["sector_b"]) == bf_sector:
					route["peligrosidad_piratas"] = maxi(int(route["peligrosidad_piratas"]) - 1, 0)

	return resumen

# =============================================================================
# VIAJE WARP
# =============================================================================

func calculate_warp_travel(route: Dictionary, origen_planet: Dictionary, destino_planet: Dictionary) -> Dictionary:
	var tiempo_base: int = int(route["tiempo_base_turnos"])
	var tipo_factor: float = float(FleetData.ROUTE_TYPES[str(route["tipo"])]["factor_speed"])

	# Factor warp random (0.5 a 3.0)
	var factor: float = rng.randf_range(0.5, 3.0)

	# Modificadores
	var dest_warp: int = int(destino_planet.get("estabilidad_warp", 50))
	factor *= lerpf(1.3, 0.8, float(dest_warp) / 100.0) # Baja estabilidad = más lento

	var route_estab: int = int(route["estabilidad"])
	factor *= lerpf(1.4, 0.7, float(route_estab) / 100.0) # Ruta inestable = más lento

	# Nihilus penalty
	if str(destino_planet.get("lado_grieta", "sanctus")) == "nihilus":
		factor *= FleetData.WARP_FACTOR_NIHILUS

	factor *= tipo_factor

	var tiempo_real: int = maxi(1, int(round(float(tiempo_base) * factor)))

	# Chance de perderse en el warp
	var perdido: bool = rng.randf() < FleetData.WARP_LOST_CHANCE
	if perdido:
		tiempo_real = rng.randi_range(FleetData.WARP_LOST_REAPPEAR_MIN, FleetData.WARP_LOST_REAPPEAR_MAX)

	return {
		"tiempo_base": tiempo_base,
		"factor_warp": factor,
		"tiempo_real": tiempo_real,
		"perdido_warp": perdido,
	}

# =============================================================================
# ENVIAR FLOTA
# =============================================================================

func send_fleet(fleet_data: Dictionary, transport_id: int, origen_id: int, destino_id: int,
	origen_planet: Dictionary, destino_planet: Dictionary, carga: Dictionary, turno: int) -> Dictionary:

	# Buscar transporte
	var transport: Dictionary = {}
	var transports: Array = fleet_data.get("transport_fleets", [])
	for t: Dictionary in transports:
		if int(t["id"]) == transport_id and str(t["estado"]) == "disponible":
			transport = t
			break

	if transport.is_empty():
		return {"exito": false, "error": "Transporte no disponible"}

	# Buscar ruta warp entre los sectores
	var origen_sec: String = str(origen_planet["segmentum"]) + "." + str(origen_planet["sector"])
	var destino_sec: String = str(destino_planet["segmentum"]) + "." + str(destino_planet["sector"])

	var route: Dictionary = _find_route(fleet_data, origen_sec, destino_sec)
	if route.is_empty():
		# Sin ruta directa: usar valores por defecto (wilderness space)
		route = {"tipo": "menor", "estabilidad": 30, "tiempo_base_turnos": 8}

	# Calcular viaje
	var viaje: Dictionary = calculate_warp_travel(route, origen_planet, destino_planet)

	# Marcar transporte como en ruta
	transport["estado"] = "en_ruta"
	transport["origen_id"] = origen_id
	transport["destino_id"] = destino_id
	transport["eta_turno"] = turno + viaje["tiempo_real"]
	transport["carga"] = carga

	# Agregar a flotas en tránsito
	fleet_data["fleets_in_transit"].append({
		"transport_id": transport_id,
		"nombre": str(transport["nombre"]),
		"origen_id": origen_id,
		"destino_id": destino_id,
		"turnos_restantes": viaje["tiempo_real"],
		"perdido_warp": viaje["perdido_warp"],
		"carga": carga,
	})

	return {
		"exito": true,
		"tiempo_estimado": viaje["tiempo_real"],
		"factor_warp": viaje["factor_warp"],
		"perdido_warp": viaje["perdido_warp"],
	}

func _find_route(fleet_data: Dictionary, sector_a: String, sector_b: String) -> Dictionary:
	var routes: Array = fleet_data.get("warp_routes", [])
	var best: Dictionary = {}
	var best_estab: int = -1
	for route: Dictionary in routes:
		var ra: String = str(route["sector_a"])
		var rb: String = str(route["sector_b"])
		if (ra == sector_a and rb == sector_b) or (ra == sector_b and rb == sector_a):
			if int(route["estabilidad"]) > best_estab:
				best = route
				best_estab = int(route["estabilidad"])
	return best

func _return_transport(transit: Dictionary, fleet_data: Dictionary) -> void:
	var tid: int = int(transit.get("transport_id", -1))
	var transports: Array = fleet_data.get("transport_fleets", [])
	for t: Dictionary in transports:
		if int(t["id"]) == tid:
			t["estado"] = "disponible"
			t["origen_id"] = -1
			t["destino_id"] = -1
			t["eta_turno"] = -1
			t["carga"] = {}
			break

# =============================================================================
# CONSULTAS
# =============================================================================

func get_available_transports(fleet_data: Dictionary) -> Array:
	var result: Array = []
	var transports: Array = fleet_data.get("transport_fleets", [])
	for t: Dictionary in transports:
		if str(t["estado"]) == "disponible":
			result.append(t)
	return result

func get_battlefleet_for_sector(fleet_data: Dictionary, sector_key: String) -> Dictionary:
	var battlefleets: Array = fleet_data.get("battlefleets", [])
	for bf: Dictionary in battlefleets:
		if str(bf["sector"]) == sector_key:
			return bf
	return {}

func get_route_between(fleet_data: Dictionary, sector_a: String, sector_b: String) -> Dictionary:
	return _find_route(fleet_data, sector_a, sector_b)
