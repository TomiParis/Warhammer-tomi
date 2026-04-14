## campaign_system.gd - Esqueleto del sistema de campañas militares
## Fase D del turno: procesa guerras activas, attrition, avance
class_name CampaignSystem

# Campañas activas {id -> campaign_dict}
var active_campaigns: Dictionary = {}
var _next_campaign_id: int = 1

func process(planetas: Array, turno: int) -> Dictionary:
	var resumen: Dictionary = {
		"campanas_activas": active_campaigns.size(),
		"campanas_resueltas": 0,
		"reportes": [],
	}

	# Procesar cada campaña activa
	var to_remove: Array = []
	for campaign_id: String in active_campaigns:
		var campaign: Dictionary = active_campaigns[campaign_id]
		var result: Dictionary = _process_campaign(campaign, planetas, turno)

		if result.get("reporte", "") != "":
			resumen["reportes"].append(result["reporte"])

		# Reducir duración
		campaign["turnos_restantes"] = int(campaign["turnos_restantes"]) - 1
		if int(campaign["turnos_restantes"]) <= 0:
			to_remove.append(campaign_id)
			resumen["campanas_resueltas"] += 1

	# Limpiar campañas terminadas
	for cid: String in to_remove:
		var camp: Dictionary = active_campaigns[cid]
		# Limpiar amenaza del planeta
		var pid: int = int(camp.get("planeta_id", -1))
		for p: Dictionary in planetas:
			if int(p["id"]) == pid:
				p["amenaza_actual"] = null
				break
		active_campaigns.erase(cid)

	return resumen

func _process_campaign(_campaign: Dictionary, _planetas: Array, _turno: int) -> Dictionary:
	# TODO: Implementar lógica de attrition, suministros, avance de frente
	# Por ahora retorna un reporte vacío
	return {"reporte": ""}

func start_campaign(planeta_id: int, nombre: String, duracion: int) -> void:
	var cid: String = "camp_" + str(_next_campaign_id)
	_next_campaign_id += 1
	active_campaigns[cid] = {
		"id": cid,
		"planeta_id": planeta_id,
		"nombre": nombre,
		"duracion": duracion,
		"turnos_restantes": duracion,
	}
