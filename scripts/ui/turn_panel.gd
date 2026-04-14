## turn_panel.gd - Panel de turno con resumen pre-confirmación
extends PanelContainer

var _fecha_label: Label = null
var _turno_btn: Button = null
var _confirm_btn: Button = null
var _speed_label: Label = null
var _balance_label: Label = null
var _auto_btn: Button = null
var _resumen_panel: PanelContainer = null
var _resumen_content: RichTextLabel = null
var _showing_resumen: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Posición: top-center
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -230.0
	offset_right = 230.0
	offset_top = 5.0
	offset_bottom = 80.0

	# Estilo
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.90)
	style.border_color = Color(0.55, 0.5, 0.3, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	# Fila superior: fecha + balance
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 20)
	vbox.add_child(top_row)

	_fecha_label = Label.new()
	_fecha_label.text = "0.999.M41"
	_fecha_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.35))
	_fecha_label.add_theme_font_size_override("font_size", 16)
	top_row.add_child(_fecha_label)

	_balance_label = Label.new()
	_balance_label.text = "50,000 TG"
	_balance_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.5))
	_balance_label.add_theme_font_size_override("font_size", 12)
	_balance_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_row.add_child(_balance_label)

	# Fila inferior: botones
	var bot_row: HBoxContainer = HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 6)
	vbox.add_child(bot_row)

	_turno_btn = _create_button("SIGUIENTE TURNO", Color(0.85, 0.78, 0.6), 13)
	_turno_btn.pressed.connect(_on_turno_pressed)
	bot_row.add_child(_turno_btn)

	_confirm_btn = _create_button("CONFIRMAR", Color(0.5, 0.8, 0.4), 13)
	_confirm_btn.visible = false
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	bot_row.add_child(_confirm_btn)

	_auto_btn = Button.new()
	_auto_btn.text = "AUTO"
	_auto_btn.toggle_mode = true
	_auto_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.45))
	_auto_btn.add_theme_font_size_override("font_size", 11)
	_auto_btn.toggled.connect(_on_auto_toggled)
	bot_row.add_child(_auto_btn)

	_speed_label = Label.new()
	_speed_label.text = "1x"
	_speed_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.42))
	_speed_label.add_theme_font_size_override("font_size", 11)
	bot_row.add_child(_speed_label)

	for spd: float in [1.0, 0.5, 0.2]:
		var spd_btn: Button = Button.new()
		spd_btn.text = "%dx" % int(1.0 / spd)
		spd_btn.flat = true
		spd_btn.add_theme_color_override("font_color", Color(0.45, 0.42, 0.38))
		spd_btn.add_theme_font_size_override("font_size", 10)
		var captured_spd: float = spd
		spd_btn.pressed.connect(func() -> void: _set_speed(captured_spd))
		bot_row.add_child(spd_btn)

	# Panel de resumen desplegable (debajo del panel principal)
	_resumen_panel = PanelContainer.new()
	_resumen_panel.visible = false
	var res_style: StyleBoxFlat = StyleBoxFlat.new()
	res_style.bg_color = Color(0.04, 0.04, 0.07, 0.92)
	res_style.border_color = Color(0.45, 0.42, 0.3, 0.2)
	res_style.set_border_width_all(1)
	res_style.set_content_margin_all(10)
	_resumen_panel.add_theme_stylebox_override("panel", res_style)
	_resumen_panel.custom_minimum_size = Vector2(440, 200)
	vbox.add_child(_resumen_panel)

	_resumen_content = RichTextLabel.new()
	_resumen_content.bbcode_enabled = true
	_resumen_content.fit_content = true
	_resumen_content.scroll_active = false
	_resumen_content.add_theme_color_override("default_color", Color(0.65, 0.62, 0.55))
	_resumen_content.add_theme_font_size_override("normal_font_size", 12)
	_resumen_panel.add_child(_resumen_content)

	call_deferred("_connect_signals")

func _create_button(text: String, color: Color, size: int) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", size)
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color(0.15, 0.13, 0.08, 0.8)
	s.border_color = Color(0.6, 0.5, 0.3, 0.4)
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	s.set_content_margin_all(6)
	btn.add_theme_stylebox_override("normal", s)
	var h: StyleBoxFlat = s.duplicate()
	h.bg_color = Color(0.2, 0.17, 0.1, 0.9)
	btn.add_theme_stylebox_override("hover", h)
	return btn

func _connect_signals() -> void:
	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	if turn_sys:
		if turn_sys.has_signal("turno_completado"):
			turn_sys.turno_completado.connect(_on_turno_completado)
		if turn_sys.has_signal("fecha_cambiada"):
			turn_sys.fecha_cambiada.connect(_on_fecha_cambiada)

# =============================================================================
# LÓGICA: mostrar resumen → confirmar → ejecutar
# =============================================================================

func _on_turno_pressed() -> void:
	if _showing_resumen:
		# Si ya está mostrando resumen, ocultarlo
		_hide_resumen()
		return

	# Mostrar resumen pre-turno
	_show_resumen()

func _on_confirm_pressed() -> void:
	_hide_resumen()
	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	if turn_sys and turn_sys.has_method("ejecutar_turno"):
		turn_sys.ejecutar_turno()

func _show_resumen() -> void:
	_showing_resumen = true
	_turno_btn.text = "CANCELAR"
	_confirm_btn.visible = true
	_resumen_panel.visible = true

	# Calcular resumen previo
	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	var gd_node: Node = get_node_or_null("/root/GameData")
	if turn_sys == null or gd_node == null:
		return

	var planetas: Array = gd_node.get_all_planets()
	var eco: EconomySystem = turn_sys.economy

	# Calcular ingresos estimados sin aplicar
	var ingresos_est: int = 0
	var planetas_en_amenaza: int = 0
	var planetas_baja_lealtad: int = 0
	for p_idx: int in planetas.size():
		var p: Dictionary = planetas[p_idx]
		if int(p["poblacion"]) <= 0:
			continue
		var ing: int = int(p["ingresos_mensuales"])
		if p.get("amenaza_actual") != null:
			ing = int(float(ing) * 0.3)
			planetas_en_amenaza += 1
		if int(p["lealtad_imperial"]) < 15:
			ing = 0
		if int(p["lealtad_imperial"]) < 30:
			planetas_baja_lealtad += 1
		ingresos_est += ing

	var gastos_est: int = int(float(ingresos_est) * 0.3)
	var balance_est: int = ingresos_est - gastos_est

	# Campañas activas (contar eventos medios+ sin resolver)
	var campanas: int = 0
	for ev: Dictionary in turn_sys.historial_eventos:
		if int(ev.get("severity", 0)) >= EventDefinitions.Severity.MEDIUM:
			if not bool(ev.get("resuelto", false)):
				campanas += 1

	var text: String = ""
	text += "[color=#999080]RESUMEN PRE-TURNO[/color]\n\n"

	# Economía
	text += "[color=#807a6b]ECONOMÍA ESTIMADA[/color]\n"
	var bal_color: String = "6b8c5a" if balance_est >= 0 else "8c5a5a"
	text += "  Ingresos: [color=#c8c0b0]%s TG[/color]\n" % _format_num(ingresos_est)
	text += "  Gastos:   [color=#c8c0b0]%s TG[/color]\n" % _format_num(gastos_est)
	text += "  Balance:  [color=#%s]%s%s TG[/color]\n" % [bal_color, "+" if balance_est >= 0 else "", _format_num(balance_est)]
	text += "  Tesoro:   [color=#c8c0b0]%s TG[/color]\n" % _format_num(eco.throne_gelt)

	# Estado del Imperium
	text += "\n[color=#807a6b]ESTADO DEL IMPERIUM[/color]\n"
	text += "  Planetas totales: [color=#c8c0b0]%d[/color]\n" % planetas.size()
	text += "  Con amenaza activa: [color=#8c5a5a]%d[/color]\n" % planetas_en_amenaza
	text += "  Lealtad baja (<30): [color=#c09a40]%d[/color]\n" % planetas_baja_lealtad
	text += "  Crisis sin resolver: [color=#8c5a5a]%d[/color]\n" % campanas

	# Turno
	text += "\n[color=#807a6b]PRÓXIMO TURNO[/color]\n"
	text += "  Fecha: [color=#d9c05a]%s[/color] → siguiente mes\n" % turn_sys.get_fecha_imperial()
	text += "  Eventos esperados: [color=#c8c0b0]3-8[/color]\n"

	_resumen_content.text = text

func _hide_resumen() -> void:
	_showing_resumen = false
	_turno_btn.text = "SIGUIENTE TURNO"
	_confirm_btn.visible = false
	_resumen_panel.visible = false

# =============================================================================
# SEÑALES Y CONTROLES
# =============================================================================

func _on_auto_toggled(pressed: bool) -> void:
	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	if turn_sys and turn_sys.has_method("set_auto_turno"):
		turn_sys.set_auto_turno(pressed)

func _set_speed(spd: float) -> void:
	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	if turn_sys and turn_sys.has_method("set_velocidad"):
		turn_sys.set_velocidad(spd)
	if _speed_label:
		_speed_label.text = "%dx" % int(1.0 / spd)

func _on_fecha_cambiada(fecha: String) -> void:
	if _fecha_label:
		_fecha_label.text = fecha

func _on_turno_completado(resumen: Dictionary) -> void:
	var eco: Dictionary = resumen.get("economia", {})
	var tg: int = int(eco.get("throne_gelt", 0))
	var balance: int = int(eco.get("balance", 0))
	var signo: String = "+" if balance >= 0 else ""
	if _balance_label:
		_balance_label.text = "%s TG (%s%s)" % [_format_num(tg), signo, _format_num(balance)]
		var color: Color = Color(0.5, 0.6, 0.4) if balance >= 0 else Color(0.7, 0.35, 0.3)
		_balance_label.add_theme_color_override("font_color", color)

	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	if turn_sys and not turn_sys.auto_turno and _auto_btn:
		_auto_btn.set_pressed_no_signal(false)

func _format_num(n: int) -> String:
	if abs(n) >= 1_000_000:
		return "%.1fM" % (float(n) / 1_000_000.0)
	elif abs(n) >= 1_000:
		return "%.1fK" % (float(n) / 1_000.0)
	return str(n)
