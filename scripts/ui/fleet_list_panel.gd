## fleet_list_panel.gd - Lista de todas las flotas por tipo, clickeables para ubicar
extends PanelContainer

var _content: RichTextLabel = null
var _toggle_btn: Button = null
var _scroll_container: ScrollContainer = null
var _minimized: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Posición: izquierda, debajo del breadcrumb
	anchor_left = 0.0
	anchor_top = 0.0
	offset_left = 5.0
	offset_top = 30.0
	custom_minimum_size = Vector2(190, 0)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.5)
	style.set_content_margin_all(2)
	style.set_corner_radius_all(0)
	add_theme_stylebox_override("panel", style)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	_toggle_btn = Button.new()
	_toggle_btn.text = "► FLOTAS"
	_toggle_btn.flat = true
	_toggle_btn.add_theme_color_override("font_color", Color(0.4, 0.55, 0.7))
	_toggle_btn.add_theme_font_size_override("font_size", 9)
	_toggle_btn.pressed.connect(_on_toggle)
	main_vbox.add_child(_toggle_btn)

	_scroll_container = ScrollContainer.new()
	_scroll_container.visible = false
	_scroll_container.custom_minimum_size = Vector2(190, 280)
	main_vbox.add_child(_scroll_container)

	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.fit_content = true
	_content.scroll_active = false
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_color_override("default_color", Color(0.6, 0.58, 0.5))
	_content.add_theme_font_size_override("normal_font_size", 9)
	_content.meta_clicked.connect(_on_fleet_clicked)
	_scroll_container.add_child(_content)

	# Conectar señal de turno para actualizar
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	var ts: Node = get_node_or_null("/root/TurnSystem")
	if ts and ts.has_signal("turno_completado"):
		ts.turno_completado.connect(func(_r: Dictionary) -> void: _refresh())

func _on_toggle() -> void:
	_minimized = not _minimized
	_scroll_container.visible = not _minimized
	_toggle_btn.text = "▼ FLOTAS" if not _minimized else "► FLOTAS"
	# Expandir hacia abajo
	# (offset_top fijo, el panel crece por el scroll container)
	_update_style()
	if not _minimized:
		_refresh()

func _update_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if _minimized:
		style.bg_color = Color(0.0, 0.0, 0.0, 0.0) # Transparente cuando minimizado
		style.set_content_margin_all(2)
	else:
		style.bg_color = Color(0.03, 0.03, 0.06, 0.88)
		style.border_color = Color(0.3, 0.45, 0.6, 0.2)
		style.border_width_right = 1
		style.set_content_margin_all(6)
	style.set_corner_radius_all(0)
	add_theme_stylebox_override("panel", style)

func _refresh() -> void:
	if _content == null:
		return
	var gd_node: Node = get_node_or_null("/root/GameData")
	if gd_node == null:
		_content.text = "[color=#605a4a]Sin datos.[/color]"
		return

	var fl_data: Dictionary = gd_node.fleet_data
	if fl_data.is_empty():
		_content.text = "[color=#605a4a]Sin flotas generadas.[/color]"
		return

	var t: String = ""

	# === BATTLEFLEETS ===
	t += "[color=#5a8ab0][b]BATTLEFLEETS IMPERIALES[/b][/color]\n"
	var battlefleets: Array = fl_data.get("battlefleets", [])
	for bf_idx: int in battlefleets.size():
		var bf: Dictionary = battlefleets[bf_idx]
		var estado: String = str(bf["estado"])
		var estado_icon: String = "●"
		var estado_col: String = "6b8c5a"
		match estado:
			"patrulla": estado_col = "6b8c5a"
			"desplegada": estado_col = "c09a40"
			"combate": estado_col = "8c5a5a"
			"reparaciones": estado_col = "c09a40"

		var naves: int = int(bf["naves_capital"]) + int(bf["cruceros"]) + int(bf["escoltas"])
		t += " [color=#%s]%s[/color] [url=bf_%d][color=#8aaccc]%s[/color][/url]\n" % [
			estado_col, estado_icon, bf_idx, str(bf["nombre"])]
		t += "   [color=#605a4a]%s • %d naves[/color]\n" % [str(bf["admiral"]).replace("Lord Admiral ", "Adm. "), naves]

	# === FLOTAS DE TRANSPORTE ===
	t += "\n[color=#807a6b][b]TRANSPORTE IMPERIAL[/b][/color]\n"
	var transports: Array = fl_data.get("transport_fleets", [])
	var avail: int = 0
	var en_ruta: int = 0
	for tr: Dictionary in transports:
		if str(tr["estado"]) == "disponible":
			avail += 1
		else:
			en_ruta += 1
	t += " [color=#6b8c5a]%d disponibles[/color] • [color=#c09a40]%d en ruta[/color]\n" % [avail, en_ruta]
	t += " [url=transport_all][color=#8aaccc]Ver detalle de transportes[/color][/url]\n"

	# === EN TRÁNSITO (WARP) ===
	var in_transit: Array = fl_data.get("fleets_in_transit", [])
	if not in_transit.is_empty():
		t += "\n[color=#c09a40][b]EN EL WARP (%d)[/b][/color]\n" % in_transit.size()
		for ft: Dictionary in in_transit:
			var turnos: int = int(ft["turnos_restantes"])
			var perdido: bool = bool(ft.get("perdido_warp", false))
			if perdido:
				t += " [color=#8c5a5a]⚠ %s — PERDIDO[/color]\n" % str(ft["nombre"])
			else:
				t += " [color=#807a6b]→ %s (%d turnos)[/color]\n" % [str(ft["nombre"]), turnos]

	# === FLOTAS ASTARTES ===
	var chapters: Array = gd_node.chapters
	var astartes_fleets: int = 0
	for ch: Dictionary in chapters:
		var flota: Dictionary = ch.get("flota", {})
		if int(flota.get("battle_barges", 0)) > 0:
			astartes_fleets += 1
	if astartes_fleets > 0:
		t += "\n[color=#5a7a9a][b]FLOTAS ASTARTES (%d)[/b][/color]\n" % astartes_fleets
		for ch: Dictionary in chapters:
			var flota: Dictionary = ch.get("flota", {})
			var bb: int = int(flota.get("battle_barges", 0))
			var sc: int = int(flota.get("strike_cruisers", 0))
			if bb > 0:
				var col: Color = ch.get("color_primario", Color.WHITE)
				var hex: String = col.to_html(false)
				t += " [color=#%s]●[/color] [color=#8aaccc]%s[/color]\n" % [hex, str(ch["nombre"])]
				t += "   [color=#605a4a]%d BB, %d SC[/color]\n" % [bb, sc]

	_content.text = t

func _on_fleet_clicked(meta: Variant) -> void:
	var meta_str: String = str(meta)
	var gd_node: Node = get_node_or_null("/root/GameData")
	if gd_node == null:
		return

	var galaxy_map = get_tree().get_first_node_in_group("galaxy_map")
	if galaxy_map == null:
		return

	if meta_str.begins_with("bf_"):
		# Click en Battlefleet → abrir panel y navegar al sector
		var bf_idx: int = int(meta_str.substr(3))
		var battlefleets: Array = gd_node.fleet_data.get("battlefleets", [])
		if bf_idx >= 0 and bf_idx < battlefleets.size():
			var bf: Dictionary = battlefleets[bf_idx]
			if galaxy_map.has_method("_show_fleet"):
				galaxy_map._show_fleet(bf)
			# Navegar al segmentum del sector de la fleet
			var sector_key: String = str(bf["sector"])
			var parts: PackedStringArray = sector_key.split(".")
			if parts.size() >= 1 and galaxy_map.has_method("navigate_to_segmentum"):
				galaxy_map.navigate_to_segmentum(parts[0])

	elif meta_str == "transport_all":
		# Click en "Ver detalle de transportes"
		if galaxy_map.has_method("_show_fleet_transports"):
			galaxy_map._show_fleet_transports()
