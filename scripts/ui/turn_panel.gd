## turn_panel.gd - Panel de turno: fecha, botón siguiente turno, velocidad, resumen
extends PanelContainer

var _fecha_label: Label = null
var _turno_btn: Button = null
var _speed_label: Label = null
var _balance_label: Label = null
var _auto_btn: Button = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Posición: top-center
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -220.0
	offset_right = 220.0
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

	# Layout
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

	# Fila inferior: botón turno + velocidad
	var bot_row: HBoxContainer = HBoxContainer.new()
	bot_row.add_theme_constant_override("separation", 8)
	vbox.add_child(bot_row)

	_turno_btn = Button.new()
	_turno_btn.text = "SIGUIENTE TURNO"
	_turno_btn.add_theme_color_override("font_color", Color(0.85, 0.78, 0.6))
	_turno_btn.add_theme_font_size_override("font_size", 13)
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.13, 0.08, 0.8)
	btn_style.border_color = Color(0.6, 0.5, 0.3, 0.4)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(2)
	btn_style.set_content_margin_all(6)
	_turno_btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover: StyleBoxFlat = btn_style.duplicate()
	btn_hover.bg_color = Color(0.2, 0.17, 0.1, 0.9)
	_turno_btn.add_theme_stylebox_override("hover", btn_hover)
	_turno_btn.pressed.connect(_on_turno_pressed)
	bot_row.add_child(_turno_btn)

	# Auto-turno
	_auto_btn = Button.new()
	_auto_btn.text = "AUTO"
	_auto_btn.toggle_mode = true
	_auto_btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.45))
	_auto_btn.add_theme_font_size_override("font_size", 11)
	_auto_btn.toggled.connect(_on_auto_toggled)
	bot_row.add_child(_auto_btn)

	# Velocidad
	_speed_label = Label.new()
	_speed_label.text = "1x"
	_speed_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.42))
	_speed_label.add_theme_font_size_override("font_size", 11)
	bot_row.add_child(_speed_label)

	for spd: float in [1.0, 0.5, 0.2]:
		var spd_btn: Button = Button.new()
		var label: String = "%dx" % int(1.0 / spd)
		spd_btn.text = label
		spd_btn.flat = true
		spd_btn.add_theme_color_override("font_color", Color(0.45, 0.42, 0.38))
		spd_btn.add_theme_font_size_override("font_size", 10)
		var captured_spd: float = spd
		spd_btn.pressed.connect(func() -> void: _set_speed(captured_spd))
		bot_row.add_child(spd_btn)

	# Conectar señales del TurnSystem
	if Engine.has_singleton("TurnSystem"):
		pass # Se conecta en _enter_tree si es autoload
	# Conexión diferida para cuando TurnSystem esté disponible
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	if turn_sys:
		if turn_sys.has_signal("turno_completado"):
			turn_sys.turno_completado.connect(_on_turno_completado)
		if turn_sys.has_signal("fecha_cambiada"):
			turn_sys.fecha_cambiada.connect(_on_fecha_cambiada)

func _on_turno_pressed() -> void:
	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	if turn_sys and turn_sys.has_method("ejecutar_turno"):
		turn_sys.ejecutar_turno()

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

	# Auto-pausa: desactivar botón toggle si se pausó
	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	if turn_sys and not turn_sys.auto_turno and _auto_btn:
		_auto_btn.set_pressed_no_signal(false)

func _format_num(n: int) -> String:
	if abs(n) >= 1_000_000:
		return "%.1fM" % (float(n) / 1_000_000.0)
	elif abs(n) >= 1_000:
		return "%.1fK" % (float(n) / 1_000.0)
	return str(n)
