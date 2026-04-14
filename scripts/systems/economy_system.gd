## economy_system.gd - Procesa la fase económica del turno
## O(n) con n = planetas. Sin instanciación de nodos.
class_name EconomySystem

# Balance global del jugador
var throne_gelt: int = 50000 # Balance inicial

func process(planetas: Array) -> Dictionary:
	var ingresos_total: int = 0
	var gastos_total: int = 0
	var ingresos_por_seg: Dictionary = {}

	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		var seg: String = str(p["segmentum"])
		var ingresos: int = int(p["ingresos_mensuales"])

		# Planetas con amenaza activa pagan reducido
		if p.get("amenaza_actual") != null:
			ingresos = int(float(ingresos) * 0.3)

		# Planetas con lealtad muy baja no pagan
		if int(p["lealtad_imperial"]) < 15:
			ingresos = 0

		ingresos_total += ingresos
		ingresos_por_seg[seg] = int(ingresos_por_seg.get(seg, 0)) + ingresos

	# Gastos base (simplificado — se expandirá con campañas)
	gastos_total = int(float(ingresos_total) * 0.3) # 30% en mantenimiento base

	var balance: int = ingresos_total - gastos_total
	throne_gelt += balance

	return {
		"ingresos_total": ingresos_total,
		"gastos_total": gastos_total,
		"balance": balance,
		"throne_gelt": throne_gelt,
		"ingresos_por_segmentum": ingresos_por_seg,
	}
