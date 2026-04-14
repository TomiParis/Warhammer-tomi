## supply_system.gd - Cadena de suministros para campañas militares
## Planetas productores → rutas warp → campañas
class_name SupplySystem

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func process(supply_routes: Array, campaigns: Array, fleet_data: Dictionary) -> Dictionary:
	var resumen: Dictionary = {
		"entregas": 0,
		"perdidas": 0,
		"rutas_cortadas": 0,
	}

	for route_idx: int in supply_routes.size():
		var route: Dictionary = supply_routes[route_idx]
		if not bool(route.get("activa", true)):
			continue

		# Verificar si la ruta warp asociada está cortada
		if bool(route.get("cortada", false)):
			resumen["rutas_cortadas"] += 1
			continue

		# Verificar peligrosidad (chance de pérdida)
		var peligro: float = float(int(route["peligrosidad"])) / 100.0
		if rng.randf() < peligro * 0.3: # 30% del peligro se materializa
			resumen["perdidas"] += 1
			continue

		# Entregar suministros a la campaña
		var camp_id: int = int(route["campana_id"])
		for camp: Dictionary in campaigns:
			if int(camp["id"]) == camp_id and not bool(camp.get("terminada", false)):
				var capacidad: int = int(route["capacidad_por_turno"])
				# Convertir capacidad a semanas de suministro (simplificado)
				camp["suministros_semanas"] = mini(int(camp["suministros_semanas"]) + floori(float(capacidad) / 500.0), 20)
				resumen["entregas"] += 1
				break

	return resumen

func create_supply_route(campana_id: int, planeta_productor: Dictionary,
	peligrosidad: int, distancia: int) -> Dictionary:
	var tipo_supply: String = "municiones"
	match str(planeta_productor["tipo"]):
		"agri_world": tipo_supply = "alimentos"
		"forge_world": tipo_supply = "equipamiento"
		"hive_world": tipo_supply = "municiones"

	var capacidad: int = int(float(int(planeta_productor["capacidad_industrial"])) * 50.0)

	return {
		"campana_id": campana_id,
		"planeta_productor_id": int(planeta_productor["id"]),
		"planeta_productor_nombre": str(planeta_productor["nombre"]),
		"tipo_suministro": tipo_supply,
		"capacidad_por_turno": capacidad,
		"distancia_turnos": distancia,
		"peligrosidad": peligrosidad,
		"activa": true,
		"cortada": false,
	}
