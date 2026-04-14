## turn_panel.gd - Panel de turno: abajo-derecha, con resumen integrado
extends PanelContainer

var _fecha_label: Label = null
var _turno_btn: Button = null
var _speed_label: Label = null
var _balance_label: Label = null
var _auto_btn: Button = null
var _resumen_content: RichTextLabel = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Posición: abajo-derecha, debajo del PlanetInfoPanel
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -430.0
	offset_right = -5.0
	offset_top = -215.0
	offset_bottom = -5.0

	# Estilo
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.90)
	style.border_color = Color(0.55, 0.5, 0.3, 0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	# Fila 1: fecha + balance
	var row1: HBoxContainer = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)

	_fecha_label = Label.new()
	_fecha_label.text = "0.999.M41"
	_fecha_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.35))
	_fecha_label.add_theme_font_size_override("font_size", 14)
	row1.add_child(_fecha_label)

	_balance_label = Label.new()
	_balance_label.text = "50K TG"
	_balance_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.5))
	_balance_label.add_theme_font_size_override("font_size", 11)
	_balance_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row1.add_child(_balance_label)

	# Fila 2: botón turno + auto + velocidad
	var row2: HBoxContainer = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 4)
	vbox.add_child(row2)

	_turno_btn = Button.new()
	_turno_btn.text = "SIGUIENTE TURNO"
	_turno_btn.add_theme_color_override("font_color", Color(0.85, 0.78, 0.6))
	_turno_btn.add_theme_font_size_override("font_size", 11)
	var btn_s: StyleBoxFlat = StyleBoxFlat.new()
	btn_s.bg_color = Color(0.12, 0.10, 0.06, 0.8)
	btn_s.border_color = Color(0.5, 0.45, 0.25, 0.4)
	btn_s.set_border_width_all(1)
	btn_s.set_corner_radius_all(2)
	btn_s.content_margin_left = 6.0
	btn_s.content_margin_right = 6.0
	btn_s.content_margin_top = 3.0
	btn_s.content_margin_bottom = 3.0
	_turno_btn.add_theme_stylebox_override("normal", btn_s)
	var btn_h: StyleBoxFlat = btn_s.duplicate()
	btn_h.bg_color = Color(0.18, 0.15, 0.08, 0.9)
	_turno_btn.add_theme_stylebox_override("hover", btn_h)
	_turno_btn.pressed.connect(_on_turno_pressed)
	row2.add_child(_turno_btn)

	_auto_btn = Button.new()
	_auto_btn.text = "AUTO"
	_auto_btn.toggle_mode = true
	_auto_btn.flat = true
	_auto_btn.add_theme_color_override("font_color", Color(0.45, 0.43, 0.38))
	_auto_btn.add_theme_font_size_override("font_size", 10)
	_auto_btn.toggled.connect(_on_auto_toggled)
	row2.add_child(_auto_btn)

	_speed_label = Label.new()
	_speed_label.text = "1x"
	_speed_label.add_theme_color_override("font_color", Color(0.45, 0.42, 0.38))
	_speed_label.add_theme_font_size_override("font_size", 10)
	row2.add_child(_speed_label)

	for spd: float in [1.0, 0.5, 0.2]:
		var sb: Button = Button.new()
		sb.text = "%dx" % int(1.0 / spd)
		sb.flat = true
		sb.add_theme_color_override("font_color", Color(0.4, 0.38, 0.33))
		sb.add_theme_font_size_override("font_size", 9)
		var cap: float = spd
		sb.pressed.connect(func() -> void: _set_speed(cap))
		row2.add_child(sb)

	# Separador
	var sep: HSeparator = HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	vbox.add_child(sep)

	# Resumen integrado (scrolleable, ocupa el resto del espacio)
	_resumen_content = RichTextLabel.new()
	_resumen_content.bbcode_enabled = true
	_resumen_content.fit_content = false
	_resumen_content.scroll_active = true
	_resumen_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_resumen_content.add_theme_color_override("default_color", Color(0.55, 0.52, 0.46))
	_resumen_content.add_theme_font_size_override("normal_font_size", 10)
	_resumen_content.text = "[color=#605a4a]Presiona SIGUIENTE TURNO.[/color]"
	vbox.add_child(_resumen_content)

	call_deferred("_connect_signals")

func _connect_signals() -> void:
	var ts: Node = get_node_or_null("/root/TurnSystem")
	if ts:
		if ts.has_signal("turno_completado"):
			ts.turno_completado.connect(_on_turno_completado)
		if ts.has_signal("fecha_cambiada"):
			ts.fecha_cambiada.connect(_on_fecha_cambiada)

func _on_turno_pressed() -> void:
	var ts: Node = get_node_or_null("/root/TurnSystem")
	if ts and ts.has_method("ejecutar_turno"):
		ts.ejecutar_turno()

func _on_auto_toggled(pressed: bool) -> void:
	var ts: Node = get_node_or_null("/root/TurnSystem")
	if ts and ts.has_method("set_auto_turno"):
		ts.set_auto_turno(pressed)

func _set_speed(spd: float) -> void:
	var ts: Node = get_node_or_null("/root/TurnSystem")
	if ts and ts.has_method("set_velocidad"):
		ts.set_velocidad(spd)
	if _speed_label:
		_speed_label.text = "%dx" % int(1.0 / spd)

func _on_fecha_cambiada(fecha: String) -> void:
	if _fecha_label:
		_fecha_label.text = fecha

func _on_turno_completado(resumen: Dictionary) -> void:
	var eco: Dictionary = resumen.get("economia", {})
	var tg: int = int(eco.get("throne_gelt", 0))
	var bal: int = int(eco.get("balance", 0))
	if _balance_label:
		var s: String = "+" if bal >= 0 else ""
		_balance_label.text = "%s TG (%s%s)" % [_fmt(tg), s, _fmt(bal)]
		_balance_label.add_theme_color_override("font_color",
			Color(0.5, 0.6, 0.4) if bal >= 0 else Color(0.7, 0.35, 0.3))

	# Actualizar resumen completo
	if _resumen_content:
		_resumen_content.text = _build_resumen(resumen)

	var ts: Node = get_node_or_null("/root/TurnSystem")
	if ts and not ts.auto_turno and _auto_btn:
		_auto_btn.set_pressed_no_signal(false)

func _build_resumen(resumen: Dictionary) -> String:
	var eco: Dictionary = resumen.get("economia", {})
	var ev_count: int = int(resumen.get("eventos_count", 0))
	var camp: Dictionary = resumen.get("campanas", {})
	var mov: Dictionary = resumen.get("movimiento", {})
	var intel_d: Dictionary = resumen.get("inteligencia", {})
	var eventos: Array = resumen.get("eventos", [])

	var ingresos: int = int(eco.get("ingresos_total", 0))
	var gastos: int = int(eco.get("gastos_total", 0))
	var balance: int = int(eco.get("balance", 0))
	var tesoro: int = int(eco.get("throne_gelt", 0))

	var t: String = ""

	# Economía
	t += "[color=#999080]ECONOMÍA[/color]\n"
	var bal_c: String = "6b8c5a" if balance >= 0 else "8c5a5a"
	t += " Ingresos: [color=#c8c0b0]%s TG[/color]\n" % _fmt(ingresos)
	t += " Gastos:   [color=#c8c0b0]%s TG[/color]\n" % _fmt(gastos)
	t += " Balance:  [color=#%s]%s%s TG[/color]\n" % [bal_c, "+" if balance >= 0 else "", _fmt(balance)]
	t += " Tesoro:   [color=#d9c05a]%s TG[/color]\n" % _fmt(tesoro)

	# Ingresos por segmentum
	var ing_seg: Dictionary = eco.get("ingresos_por_segmentum", {})
	if not ing_seg.is_empty():
		t += "\n[color=#999080]INGRESOS POR SEGMENTUM[/color]\n"
		for seg_key: String in ing_seg:
			var seg_name: String = seg_key.capitalize()
			if GalaxyConfig.SEGMENTUM_CONFIG.has(seg_key):
				seg_name = str(GalaxyConfig.SEGMENTUM_CONFIG[seg_key]["nombre"])
			t += " [color=#807a6b]%s:[/color] %s\n" % [seg_name, _fmt(int(ing_seg[seg_key]))]

	# Estado del Imperium
	var gd_node: Node = get_node_or_null("/root/GameData")
	if gd_node:
		var planetas: Array = gd_node.get_all_planets()
		var amenazas: int = 0
		var baja_lealtad: int = 0
		var nihilus_count: int = 0
		for p_idx: int in planetas.size():
			var p: Dictionary = planetas[p_idx]
			if p.get("amenaza_actual") != null:
				amenazas += 1
			if int(p["lealtad_imperial"]) < 30:
				baja_lealtad += 1
			if str(p["lado_grieta"]) == "nihilus":
				nihilus_count += 1

		t += "\n[color=#999080]ESTADO DEL IMPERIUM[/color]\n"
		t += " Planetas: [color=#c8c0b0]%d[/color]\n" % planetas.size()
		t += " Con amenaza: [color=#8c5a5a]%d[/color]\n" % amenazas
		t += " Lealtad baja: [color=#c09a40]%d[/color]\n" % baja_lealtad
		t += " En Nihilus: [color=#807a6b]%d[/color]\n" % nihilus_count

	# Flotas
	var fleet: Dictionary = resumen.get("flotas", {})
	t += "\n[color=#999080]FLOTAS[/color]\n"
	var fl_transit: int = int(fleet.get("en_transito", 0))
	var fl_arrived: int = int(fleet.get("llegadas", 0))
	var fl_lost: int = int(fleet.get("perdidos_warp", 0))
	var fl_cut: int = int(fleet.get("rutas_cortadas", 0))
	t += " En tránsito: [color=#c8c0b0]%d convoys[/color]\n" % fl_transit
	if fl_arrived > 0:
		t += " [color=#6b8c5a]%d llegaron a destino[/color]\n" % fl_arrived
	if fl_lost > 0:
		t += " [color=#8c5a5a]%d perdidos en el Warp[/color]\n" % fl_lost
	if fl_cut > 0:
		t += " [color=#c09a40]%d rutas inestables[/color]\n" % fl_cut
	var fl_enemies: int = int(fleet.get("flotas_enemigas_nuevas", 0))
	var fl_combats: int = int(fleet.get("combates_navales", 0))
	var fl_convoys_att: int = int(fleet.get("convoys_atacados", 0))
	if fl_enemies > 0:
		t += " [color=#8c5a5a]%d flotas enemigas detectadas[/color]\n" % fl_enemies
	if fl_combats > 0:
		t += " [color=#c09a40]%d combates navales[/color]\n" % fl_combats
	if fl_convoys_att > 0:
		t += " [color=#8c5a5a]%d convoys atacados[/color]\n" % fl_convoys_att

	# Alertas navales
	var alertas: Array = fleet.get("alertas", [])
	if not alertas.is_empty():
		t += "\n[color=#999080]ALERTAS NAVALES[/color]\n"
		var max_alerts: int = mini(alertas.size(), 5)
		for a_idx: int in max_alerts:
			t += " [color=#c09a40]⚠ %s[/color]\n" % str(alertas[a_idx])
		if alertas.size() > 5:
			t += " [color=#605a4a]...y %d más[/color]\n" % (alertas.size() - 5)

	# Campañas y operaciones
	t += "\n[color=#999080]OPERACIONES[/color]\n"
	t += " Campañas activas: [color=#c8c0b0]%d[/color]\n" % int(camp.get("campanas_activas", 0))
	t += " Mensajes recibidos: [color=#c8c0b0]%d[/color]\n" % int(intel_d.get("mensajes_recibidos", 0))

	var resueltas: int = int(camp.get("campanas_resueltas", 0))
	if resueltas > 0:
		t += " [color=#6b8c5a]%d campañas resueltas[/color]\n" % resueltas

	# Eventos de este turno (resumen)
	if ev_count > 0:
		t += "\n[color=#999080]EVENTOS (%d)[/color]\n" % ev_count
		var max_show: int = mini(ev_count, 5)
		for i: int in max_show:
			var ev: Dictionary = eventos[i]
			var sev: int = int(ev.get("severity", 0))
			var sev_color: Color = EventDefinitions.SEVERITY_COLORS.get(sev, Color.WHITE)
			var hex: String = sev_color.to_html(false)
			t += " [color=#%s]●[/color] %s — %s\n" % [hex, str(ev.get("nombre", "?")), str(ev.get("planeta_nombre", "?"))]
		if ev_count > 5:
			t += " [color=#605a4a]...y %d más[/color]\n" % (ev_count - 5)

	return t

func _fmt(n: int) -> String:
	if abs(n) >= 1_000_000:
		return "%.1fM" % (float(n) / 1_000_000.0)
	elif abs(n) >= 1_000:
		return "%.1fK" % (float(n) / 1_000.0)
	return str(n)
