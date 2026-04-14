## planet_info_panel.gd - Panel lateral con información detallada del planeta
extends PanelContainer

var _content: RichTextLabel = null
var _close_btn: Button = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Estilo del panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.92)
	style.border_color = Color(0.55, 0.5, 0.3, 0.25)
	style.border_width_left = 2
	style.set_corner_radius_all(0)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	add_theme_stylebox_override("panel", style)

	# Layout — panel anclado a la derecha, ocupa todo el alto disponible
	custom_minimum_size = Vector2(320, 0)
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = -330.0
	offset_top = 5.0
	offset_bottom = -220.0 # Espacio para TurnPanel (215px + 5px gap)
	offset_right = -5.0

	# Contenido con VBox
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	# Botón cerrar
	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.flat = true
	_close_btn.custom_minimum_size = Vector2(30, 25)
	_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_close_btn.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	_close_btn.pressed.connect(func() -> void: visible = false)
	vbox.add_child(_close_btn)

	# Rich text scrolleable dentro del espacio disponible
	_content = RichTextLabel.new()
	_content.name = "Content"
	_content.bbcode_enabled = true
	_content.fit_content = false # NO crecer — scrollear dentro del espacio
	_content.scroll_active = true
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_color_override("default_color", Color(0.75, 0.72, 0.65))
	_content.meta_clicked.connect(_on_meta_clicked)
	vbox.add_child(_content)

func show_planet(planet: Dictionary) -> void:
	if _content == null:
		return
	visible = true
	_content.text = _build_planet_text(planet)
	_content.scroll_to_line(0)

func _build_planet_text(p: Dictionary) -> String:
	var nombre: String = str(p["nombre"])
	var tipo_key: String = str(p["tipo"])
	var tipo_name: String = str(PlanetTypes.TYPES[tipo_key]["nombre"]) if PlanetTypes.TYPES.has(tipo_key) else tipo_key
	var pop: int = int(p["poblacion"])
	var lado: String = str(p["lado_grieta"])
	var tithe: String = str(p["tithe_grade"])
	var tithe_name: String = str(PlanetTypes.TITHE_GRADES[tithe]["nombre"]) if PlanetTypes.TITHE_GRADES.has(tithe) else tithe

	var controlador: Dictionary = p.get("controlador", {})
	var ctrl_nombre: String = str(controlador.get("nombre", "Desconocido"))

	var guarnicion: Dictionary = p.get("guarnicion", {})
	var pdf: int = int(guarnicion.get("pdf_size", 0))
	var astartes: Variant = guarnicion.get("astartes_presencia")

	var lealtad: int = int(p["lealtad_imperial"])
	var fe_val: int = int(p["fe_imperial"])
	var industrial: int = int(p["capacidad_industrial"])
	var militar: int = int(p["capacidad_militar"])
	var warp: int = int(p["estabilidad_warp"])
	var astropata: bool = bool(p["tiene_astropata"])
	var ingresos: int = int(p["ingresos_mensuales"])

	var seg_name: String = _get_seg_name(str(p["segmentum"]))
	var sec_name: String = _get_sec_name(str(p["segmentum"]), str(p["sector"]))

	# Badge de lado de la grieta
	var lado_badge: String = ""
	if lado == "sanctus":
		lado_badge = "[color=#6b8c5a]SANCTUS[/color]"
	else:
		lado_badge = "[color=#8c5a5a]NIHILUS[/color]"

	# Badge de tipo con color
	var tipo_color: String = PlanetTypes.COLORS.get(tipo_key, Color.WHITE).to_html(false)
	var tipo_badge: String = "[color=#%s]%s[/color]" % [tipo_color, tipo_name]

	var text: String = ""
	text += "[font_size=20][color=#d9c05a][b]%s[/b][/color][/font_size]\n" % nombre
	text += "%s  •  %s\n" % [tipo_badge, lado_badge]
	text += "[color=#807a6b]%s > %s[/color]\n" % [seg_name, sec_name]
	text += "\n"

	# Población
	text += "[color=#999080]POBLACIÓN[/color]\n"
	text += "[color=#c8c0b0]%s habitantes[/color]\n\n" % _format_pop(pop)

	# Diezmo
	text += "[color=#999080]GRADO DE DIEZMO[/color]\n"
	text += "[color=#c8c0b0]%s[/color]\n\n" % tithe_name

	# Gobernanza expandida
	text += _build_governance_section(controlador)

	# Stats con barras de texto
	text += "[color=#999080]ESTADÍSTICAS[/color]\n"
	text += _stat_bar("Lealtad", lealtad)
	text += _stat_bar("Fe Imperial", fe_val)
	text += _stat_bar("Industria", industrial)
	text += _stat_bar("Militar", militar)
	text += _stat_bar("Est. Warp", warp)
	text += "\n"

	# Guarnición
	text += "[color=#999080]GUARNICIÓN[/color]\n"
	text += "[color=#c8c0b0]PDF: %s efectivos[/color]\n" % _format_pop(pdf)
	if astartes != null and str(astartes) != "":
		text += "[color=#d9c05a]Astartes: [url=chapter_%s]%s[/url][/color]\n" % [str(astartes), str(astartes)]
	text += "\n"

	# Info adicional
	text += "[color=#999080]COMUNICACIONES[/color]\n"
	text += "[color=#c8c0b0]Astropata: %s[/color]\n" % ("Sí" if astropata else "No")
	text += "[color=#c8c0b0]Ingresos: %d Throne Gelt/mes[/color]\n" % ingresos

	# Flotas del sector
	text += _build_fleet_section(str(p["segmentum"]), str(p["sector"]))

	# Amenaza actual
	var amenaza = p.get("amenaza_actual")
	if amenaza != null and str(amenaza) != "":
		text += "\n[color=#8c3a3a]⚠ AMENAZA ACTIVA[/color]\n"
		text += "[color=#c85a5a]%s[/color]\n" % str(amenaza)

	# Flags
	var flags: Array = p.get("flags", [])
	if not flags.is_empty():
		text += "\n[color=#999080]ESTADO[/color]\n"
		for f_idx: int in flags.size():
			text += "[color=#8c5a5a]• %s[/color]\n" % str(flags[f_idx]).to_upper()

	# Eventos del planeta (activos + historial reciente)
	text += _build_planet_events(int(p["id"]))

	return text

func _stat_bar(label: String, value: int) -> String:
	var filled: int = floori(float(value) / 5.0) # 20 chars max
	var empty: int = 20 - filled
	var bar_color: String = "6b8c5a" if value >= 60 else ("c09a40" if value >= 30 else "8c5a5a")
	return "[color=#807a6b]%-12s[/color] [color=#%s]%s[/color][color=#333]%s[/color] [color=#807a6b]%d[/color]\n" % [
		label, bar_color, "█".repeat(filled), "░".repeat(empty), value
	]

func _format_pop(pop: int) -> String:
	if pop <= 0: return "0"
	elif pop >= 1_000_000_000: return "%.1f mil millones" % (float(pop) / 1_000_000_000.0)
	elif pop >= 1_000_000: return "%.1f millones" % (float(pop) / 1_000_000.0)
	elif pop >= 1_000: return "%d mil" % floori(float(pop) / 1000.0)
	else: return str(pop)

func _build_fleet_section(seg_key: String, sec_key: String) -> String:
	var gd_node: Node = get_node_or_null("/root/GameData")
	if gd_node == null:
		return ""
	var fl_data: Dictionary = gd_node.fleet_data
	if fl_data.is_empty():
		return ""

	var sector_key: String = seg_key + "." + sec_key
	var t: String = "\n[color=#999080]FLOTAS DEL SECTOR[/color]\n"

	# Battlefleet del sector
	var battlefleets: Array = fl_data.get("battlefleets", [])
	var found_bf: bool = false
	for bf: Dictionary in battlefleets:
		if str(bf["sector"]) == sector_key:
			var estado_col: String = "6b8c5a"
			if str(bf["estado"]) == "combate":
				estado_col = "8c5a5a"
			elif str(bf["estado"]) == "reparaciones":
				estado_col = "c09a40"
			t += " [color=#5a7a9a]⚓[/color] [color=#c8c0b0]%s[/color]\n" % str(bf["nombre"])
			t += "   [color=#807a6b]%s[/color]\n" % str(bf["admiral"])
			t += "   [color=#807a6b]%d capital, %d cruceros, %d escoltas[/color]\n" % [
				int(bf["naves_capital"]), int(bf["cruceros"]), int(bf["escoltas"])]
			t += "   Estado: [color=#%s]%s[/color]\n" % [estado_col, str(bf["estado"]).capitalize()]
			found_bf = true
			break
	if not found_bf:
		t += " [color=#605a4a]Sin Battlefleet asignada[/color]\n"

	# Transportes disponibles (global, no por sector)
	var transports: Array = fl_data.get("transport_fleets", [])
	var available: int = 0
	var in_route: int = 0
	for tr: Dictionary in transports:
		if str(tr["estado"]) == "disponible":
			available += 1
		elif str(tr["estado"]) == "en_ruta":
			in_route += 1
	t += " [color=#807a6b]Transportes: %d disponibles, %d en ruta[/color]\n" % [available, in_route]

	# Flotas en tránsito hacia/desde este sector
	var in_transit: Array = fl_data.get("fleets_in_transit", [])
	var transit_count: int = 0
	for ft: Dictionary in in_transit:
		transit_count += 1
	if transit_count > 0:
		t += " [color=#807a6b]Convoys en tránsito: %d[/color]\n" % transit_count

	return t + "\n"

func _build_governance_section(ctrl: Dictionary) -> String:
	var tipo: String = str(ctrl.get("tipo", ""))
	var nombre: String = str(ctrl.get("nombre", "Desconocido"))

	# Ícono y color de facción
	var faction_info: Dictionary = FactionData.FACTIONS.get(tipo, {})
	var icono: String = str(faction_info.get("icono", "●"))
	var faction_name: String = str(faction_info.get("nombre", tipo))
	var col: Color = faction_info.get("color", Color(0.6, 0.6, 0.6))
	var hex: String = col.to_html(false)

	var t: String = "[color=#999080]GOBERNANZA[/color]\n"
	t += "[color=#%s]%s %s[/color]\n" % [hex, icono, faction_name]
	t += "[color=#c8c0b0]%s[/color]\n" % nombre

	# Detalles según tipo
	match tipo:
		"gobernador_planetario", "aristocracia_local", "nobleza_local":
			if ctrl.has("titulo"):
				t += "[color=#807a6b]%s[/color]\n" % str(ctrl["titulo"])
			if ctrl.has("dinastia"):
				t += "[color=#807a6b]%s (%d siglos)[/color]\n" % [
					str(ctrl["dinastia"]), int(ctrl.get("dinastia_siglos", 0))]
			if ctrl.has("competencia"):
				t += "[color=#807a6b]Competencia: %d  Ambición: %d[/color]\n" % [
					int(ctrl["competencia"]), int(ctrl.get("ambicion", 0))]
		"adeptus_mechanicus":
			if ctrl.has("nivel_tech"):
				t += "[color=#807a6b]Nivel Tecnológico: %d[/color]\n" % int(ctrl["nivel_tech"])
			if int(ctrl.get("titan_legios", 0)) > 0:
				t += "[color=#c09a40]Titan Legio disponible[/color]\n"
		"ecclesiarquia", "cardenal":
			if ctrl.has("rango"):
				t += "[color=#807a6b]Rango: %s[/color]\n" % str(ctrl["rango"])
			if ctrl.has("sororitas_orden"):
				t += "[color=#807a6b]Sororitas: %s[/color]\n" % str(ctrl["sororitas_orden"])
		"casa_noble":
			if ctrl.has("casa"):
				t += "[color=#807a6b]%s[/color]\n" % str(ctrl["casa"])
			if ctrl.has("knights_operativos"):
				t += "[color=#807a6b]Knights: %d operativos[/color]\n" % int(ctrl["knights_operativos"])
			if ctrl.has("alianza"):
				t += "[color=#807a6b]Alianza: %s[/color]\n" % str(ctrl["alianza"]).capitalize()
		"rogue_trader":
			if ctrl.has("dinastia"):
				t += "[color=#807a6b]%s[/color]\n" % str(ctrl["dinastia"])
			if ctrl.has("warrant_era"):
				t += "[color=#807a6b]Warrant: %s[/color]\n" % str(ctrl["warrant_era"])
			if ctrl.has("flota_naves"):
				t += "[color=#807a6b]Flota: %d naves[/color]\n" % int(ctrl["flota_naves"])
		"comandante_militar":
			if ctrl.has("rango_militar"):
				t += "[color=#807a6b]%s[/color]\n" % str(ctrl["rango_militar"])
		"adeptus_arbites":
			if bool(ctrl.get("ley_marcial", false)):
				var turnos: int = int(ctrl.get("turnos_restantes", 0))
				t += "[color=#8c5a5a]LEY MARCIAL (%d turnos)[/color]\n" % turnos

	t += "\n"
	return t

func _on_meta_clicked(meta: Variant) -> void:
	var meta_str: String = str(meta)
	if meta_str.begins_with("chapter_"):
		var ch_name: String = meta_str.substr(8) # Quitar "chapter_"
		var gd_node: Node = get_node_or_null("/root/GameData")
		if gd_node == null:
			return
		# Buscar capítulo por nombre
		for ch: Dictionary in gd_node.chapters:
			if str(ch["nombre"]) == ch_name:
				var galaxy_map = get_tree().get_first_node_in_group("galaxy_map")
				if galaxy_map and galaxy_map.has_method("_show_chapter"):
					galaxy_map._show_chapter(ch)
				break

func _build_planet_events(planet_id: int) -> String:
	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	if turn_sys == null:
		return ""

	# Buscar eventos de este planeta en el historial
	var planet_events: Array = []
	var historial: Array = turn_sys.historial_eventos
	for ev_idx: int in historial.size():
		var ev: Dictionary = historial[ev_idx]
		if int(ev.get("planeta_id", -1)) == planet_id:
			planet_events.append(ev)
		if planet_events.size() >= 10:
			break # Máximo 10 eventos recientes

	if planet_events.is_empty():
		return ""

	var text: String = "\n[color=#999080]EVENTOS RECIENTES[/color]\n"

	for ev_idx: int in planet_events.size():
		var ev: Dictionary = planet_events[ev_idx]
		var sev: int = int(ev.get("severity", 0))
		var sev_color: Color = EventDefinitions.SEVERITY_COLORS.get(sev, Color.WHITE)
		var sev_name: String = str(EventDefinitions.SEVERITY_NAMES.get(sev, ""))
		var hex: String = sev_color.to_html(false)
		var turno: String = str(ev.get("turno", "?"))

		text += "[color=#%s]●[/color] " % hex
		text += "[color=#c8c0b0]%s[/color]" % str(ev.get("nombre", "?"))
		text += " [color=#605a4a][%s, T%s][/color]\n" % [sev_name, turno]

		# Efectos aplicados
		var efectos: Dictionary = ev.get("efectos", {})
		if not efectos.is_empty():
			var efecto_strs: PackedStringArray = PackedStringArray()
			for key: String in efectos:
				var val: int = int(efectos[key])
				var signo: String = "+" if val > 0 else ""
				efecto_strs.append("%s%d %s" % [signo, val, _short_stat_name(key)])
			text += "  [color=#605a4a]%s[/color]\n" % ", ".join(efecto_strs)

	return text

func _short_stat_name(key: String) -> String:
	match key:
		"lealtad_imperial": return "Lealtad"
		"fe_imperial": return "Fe"
		"capacidad_industrial": return "Industria"
		"capacidad_militar": return "Militar"
		"estabilidad_warp": return "Warp"
		"infiltracion_caos": return "Caos"
		"infiltracion_genestealer": return "Genestealer"
		"corrupcion_gobernador": return "Corrupción"
		_: return key

func _get_seg_name(seg_key: String) -> String:
	if GalaxyConfig.SEGMENTUM_CONFIG.has(seg_key):
		return str(GalaxyConfig.SEGMENTUM_CONFIG[seg_key]["nombre"])
	return seg_key

func _get_sec_name(seg_key: String, sec_key: String) -> String:
	if GalaxyConfig.SECTOR_CONFIG.has(seg_key):
		var sectores: Dictionary = GalaxyConfig.SECTOR_CONFIG[seg_key]
		if sectores.has(sec_key):
			return str(sectores[sec_key]["nombre"])
	return sec_key
