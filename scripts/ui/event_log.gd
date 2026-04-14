## event_log.gd - Log de eventos, al lado del minimap, contraíble
extends PanelContainer

var _content: RichTextLabel = null
var _tab_current: Button = null
var _tab_history: Button = null
var _showing_current: bool = true
var _event_count_label: Label = null
var _active_category_filter: int = -1
var _expand_btn: Button = null
var _expanded: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Posición: abajo-derecha, a la izquierda del minimap
	# Minimap está en offset_left = -(330 + 160 + 5) = -495 desde la derecha
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -810.0 # A la izquierda del minimap
	offset_right = -500.0
	offset_top = -130.0 # Contraído por default
	offset_bottom = -5.0

	# Estilo
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.88)
	style.border_color = Color(0.45, 0.42, 0.3, 0.2)
	style.border_width_top = 1
	style.set_corner_radius_all(0)
	style.set_content_margin_all(6)
	add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	# Fila de pestañas + expandir
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	vbox.add_child(tabs)

	var title: Label = Label.new()
	title.text = "EVENTOS"
	title.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5))
	title.add_theme_font_size_override("font_size", 11)
	tabs.add_child(title)

	_tab_current = _create_tab("Turno", true)
	_tab_current.pressed.connect(func() -> void: _show_tab(true))
	tabs.add_child(_tab_current)

	_tab_history = _create_tab("Historial", false)
	_tab_history.pressed.connect(func() -> void: _show_tab(false))
	tabs.add_child(_tab_history)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(spacer)

	_event_count_label = Label.new()
	_event_count_label.text = "0"
	_event_count_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.42))
	_event_count_label.add_theme_font_size_override("font_size", 9)
	tabs.add_child(_event_count_label)

	_expand_btn = Button.new()
	_expand_btn.text = "▲"
	_expand_btn.flat = true
	_expand_btn.add_theme_color_override("font_color", Color(0.5, 0.48, 0.42))
	_expand_btn.add_theme_font_size_override("font_size", 9)
	_expand_btn.pressed.connect(_toggle_expand)
	tabs.add_child(_expand_btn)

	# Filtros compactos
	var filter_row: HBoxContainer = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 2)
	vbox.add_child(filter_row)

	var all_btn: Button = _create_filter_btn("All", -1)
	filter_row.add_child(all_btn)
	for cat_key: int in EventDefinitions.CATEGORY_NAMES:
		var cat_name: String = str(EventDefinitions.CATEGORY_NAMES[cat_key])
		var short: String = cat_name.substr(0, 3)
		var cat_btn: Button = _create_filter_btn(short, cat_key)
		filter_row.add_child(cat_btn)

	# Contenido
	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.scroll_active = true
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_color_override("default_color", Color(0.6, 0.58, 0.5))
	_content.add_theme_font_size_override("normal_font_size", 10)
	_content.meta_clicked.connect(_on_planet_clicked)
	vbox.add_child(_content)

	call_deferred("_connect_signals")

func _toggle_expand() -> void:
	_expanded = not _expanded
	if _expanded:
		offset_top = -320.0
		_expand_btn.text = "▼"
	else:
		offset_top = -130.0
		_expand_btn.text = "▲"

func _create_filter_btn(text: String, category: int) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.flat = true
	btn.add_theme_color_override("font_color", Color(0.4, 0.38, 0.33))
	btn.add_theme_font_size_override("font_size", 8)
	var cap_cat: int = category
	btn.pressed.connect(func() -> void:
		_active_category_filter = cap_cat
		_refresh_content()
	)
	return btn

func _create_tab(text: String, active: bool) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.flat = true
	var color: Color = Color(0.8, 0.72, 0.5) if active else Color(0.45, 0.42, 0.38)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 10)
	return btn

func _connect_signals() -> void:
	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	if turn_sys:
		if turn_sys.has_signal("turno_completado"):
			turn_sys.turno_completado.connect(_on_turno_completado)

func _on_planet_clicked(meta: Variant) -> void:
	var pid: int = int(str(meta))
	if pid <= 0:
		return
	var gd_node: Node = get_node_or_null("/root/GameData")
	if gd_node == null:
		return
	var planet: Dictionary = gd_node.planets_by_id.get(pid, {})
	if planet.is_empty():
		return
	var galaxy_map = get_tree().get_first_node_in_group("galaxy_map")
	if galaxy_map and galaxy_map.has_method("navigate_to_planet"):
		galaxy_map.navigate_to_planet(planet)

func _show_tab(current: bool) -> void:
	_showing_current = current
	_tab_current.add_theme_color_override("font_color",
		Color(0.8, 0.72, 0.5) if current else Color(0.45, 0.42, 0.38))
	_tab_history.add_theme_color_override("font_color",
		Color(0.8, 0.72, 0.5) if not current else Color(0.45, 0.42, 0.38))
	_refresh_content()

func _on_turno_completado(_resumen: Dictionary) -> void:
	_show_tab(true)
	_refresh_content()

func _refresh_content() -> void:
	if _content == null:
		return

	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	if turn_sys == null:
		_content.text = "[color=#605a4a]Sin datos.[/color]"
		return

	var eventos_raw: Array = turn_sys.eventos_turno_actual if _showing_current else turn_sys.historial_eventos

	var eventos: Array = []
	if _active_category_filter < 0:
		eventos = eventos_raw
	else:
		for ev_idx: int in eventos_raw.size():
			var ev: Dictionary = eventos_raw[ev_idx]
			if int(ev.get("category", -1)) == _active_category_filter:
				eventos.append(ev)

	if _event_count_label:
		_event_count_label.text = str(eventos.size())

	if eventos.is_empty():
		_content.text = "[color=#605a4a]Sin eventos.[/color]"
		return

	var text: String = ""
	var max_show: int = mini(eventos.size(), 30)

	for i: int in max_show:
		var ev: Dictionary = eventos[i]
		var sev: int = int(ev.get("severity", 0))
		var sev_color: Color = EventDefinitions.SEVERITY_COLORS.get(sev, Color.WHITE)
		var hex: String = sev_color.to_html(false)

		var planeta_id: String = str(ev.get("planeta_id", ""))
		var planeta_nombre: String = str(ev.get("planeta_nombre", "?"))

		text += "[color=#%s]●[/color] [b]%s[/b] — " % [hex, str(ev.get("nombre", "?"))]
		text += "[url=%s][color=#c9a84c]%s[/color][/url]\n" % [planeta_id, planeta_nombre]

	_content.text = text
