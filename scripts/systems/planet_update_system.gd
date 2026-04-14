## planet_update_system.gd - Actualiza stats de todos los planetas cada turno
## O(n) batch. Sin nodos, puro cálculo numérico.
class_name PlanetUpdateSystem

func process(planetas: Array, _turno: int) -> void:
	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]

		# Saltar mundos muertos sin población
		if int(p["poblacion"]) <= 0:
			continue

		var lealtad: int = int(p["lealtad_imperial"])
		var fe: int = int(p["fe_imperial"])
		var industrial: int = int(p["capacidad_industrial"])
		var chaos: int = int(p["infiltracion_caos"])
		var gs: int = int(p["infiltracion_genestealer"])
		var corrupcion: int = int(p["corrupcion_gobernador"])
		var warp: int = int(p["estabilidad_warp"])
		var lado: String = str(p["lado_grieta"])
		var tiene_amenaza: bool = p.get("amenaza_actual") != null

		# === LEALTAD ===
		var delta_lealtad: float = 0.0
		if fe > 60 and not tiene_amenaza:
			delta_lealtad += 0.3  # Fe alta estabiliza
		if chaos > 20:
			delta_lealtad -= float(chaos) * 0.03
		if corrupcion > 30:
			delta_lealtad -= float(corrupcion) * 0.02
		if tiene_amenaza:
			delta_lealtad -= 1.5
		lealtad = clampi(lealtad + int(delta_lealtad), 0, 100)

		# === FE ===
		var delta_fe: float = 0.0
		if str(p["tipo"]) in ["shrine_world", "cardinal_world"]:
			delta_fe += 0.3  # Mundos religiosos mantienen fe
		if chaos > 15:
			delta_fe -= float(chaos) * 0.02
		if lado == "nihilus":
			delta_fe -= 0.1  # Aislamiento del Astronomicán
		if gs > 2:
			delta_fe -= 0.5
		fe = clampi(fe + int(delta_fe), 0, 100)

		# === INFILTRACIÓN DEL CAOS (crece lento, siempre) ===
		var delta_chaos: float = 0.15  # Base
		if lado == "nihilus":
			delta_chaos += 0.2  # Nihilus más vulnerable
		if fe < 30:
			delta_chaos += 0.15  # Fe baja = más vulnerable
		if warp < 30:
			delta_chaos += 0.2  # Warp inestable
		if fe > 70:
			delta_chaos -= 0.1  # Fe alta resiste
		chaos = clampi(chaos + int(delta_chaos * 10.0) if delta_chaos >= 0.1 else chaos, 0, 100)

		# === INFILTRACIÓN GENESTEALER (crece muy lento) ===
		if gs > 0:
			# Solo crece si ya hay semilla
			var delta_gs: float = 0.05
			if int(p["poblacion"]) > 5_000_000_000:
				delta_gs += 0.03  # Mundos populosos son más vulnerables
			gs = clampi(gs + (1 if randf() < delta_gs else 0), 0, 100)

		# === CORRUPCIÓN DEL GOBERNADOR (crece lento) ===
		var delta_corr: float = 0.1
		if lealtad < 40:
			delta_corr += 0.1  # Baja supervisión
		if industrial > 70:
			delta_corr += 0.05  # Más recursos = más tentación
		corrupcion = clampi(corrupcion + (1 if randf() < delta_corr else 0), 0, 100)

		# === ESTABILIDAD WARP (fluctúa) ===
		var delta_warp: float = randf_range(-0.5, 0.5)
		if lado == "nihilus":
			delta_warp -= 0.2
		if chaos > 30:
			delta_warp -= 0.3
		warp = clampi(warp + int(delta_warp), 0, 100)

		# === POBLACIÓN (crecimiento lento en mundos estables) ===
		var pop: int = int(p["poblacion"])
		if not tiene_amenaza and lealtad > 30:
			var growth: float = 0.0001  # 0.01% por turno
			pop = int(float(pop) * (1.0 + growth))

		# Aplicar cambios al planeta
		p["lealtad_imperial"] = lealtad
		p["fe_imperial"] = fe
		p["capacidad_industrial"] = industrial
		p["infiltracion_caos"] = chaos
		p["infiltracion_genestealer"] = gs
		p["corrupcion_gobernador"] = corrupcion
		p["estabilidad_warp"] = warp
		p["poblacion"] = pop
