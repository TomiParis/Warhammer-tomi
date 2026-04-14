## fleet_panel.gd - Panel de información de una Battlefleet
extends PanelContainer

var _content: RichTextLabel = null
var _close_btn: Button = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.92)
	style.border_color = Color(0.3, 0.45, 0.6, 0.3)
	style.border_width_left = 2
	style.set_corner_radius_all(0)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", style)

	# Posición: izquierda, debajo de la lista, mismo ancho
	anchor_left = 0.0
	anchor_top = 0.0
	offset_left = 5.0
	offset_top = 315.0
	custom_minimum_size = Vector2(190, 300)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.flat = true
	_close_btn.custom_minimum_size = Vector2(30, 25)
	_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_close_btn.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	_close_btn.pressed.connect(func() -> void: visible = false)
	vbox.add_child(_close_btn)

	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.fit_content = false
	_content.scroll_active = true
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_color_override("default_color", Color(0.75, 0.72, 0.65))
	vbox.add_child(_content)

func show_battlefleet(bf: Dictionary) -> void:
	if _content == null:
		return
	visible = true
	_content.text = _build_bf_text(bf)
	_content.scroll_to_line(0)

func show_transport_summary(fleet_data: Dictionary) -> void:
	if _content == null:
		return
	visible = true
	_content.text = _build_transport_text(fleet_data)
	_content.scroll_to_line(0)

func _build_bf_text(bf: Dictionary) -> String:
	var t: String = ""

	t += "[color=#5a8ab0]⚓[/color] [color=#d9c05a][b]%s[/b][/color]\n" % str(bf["nombre"])
	t += "[color=#807a6b]Armada Imperial[/color]\n"

	t += "[color=#999080]COMANDANTE[/color]\n"
	t += "[color=#c8c0b0]%s[/color]\n" % str(bf["admiral"])

	var estado: String = str(bf["estado"])
	var estado_col: String = "6b8c5a"
	match estado:
		"desplegada": estado_col = "c09a40"
		"combate": estado_col = "8c5a5a"
		"reparaciones": estado_col = "c09a40"
	t += "[color=#999080]ESTADO[/color]\n"
	t += "[color=#%s]%s[/color]\n" % [estado_col, estado.to_upper()]

	var capital: int = int(bf["naves_capital"])
	var cruceros: int = int(bf["cruceros"])
	var escoltas: int = int(bf["escoltas"])
	var total: int = capital + cruceros + escoltas
	t += "[color=#999080]COMPOSICIÓN[/color]\n"
	t += " Capital: [color=#c8c0b0]%d[/color]\n" % capital
	t += " Cruceros: [color=#c8c0b0]%d[/color]\n" % cruceros
	t += " Escoltas: [color=#c8c0b0]%d[/color]\n" % escoltas
	t += " [color=#d9c05a]Total: %d naves[/color]\n" % total

	var poder: int = capital * 10 + cruceros * 4 + escoltas
	var poder_bar: int = clampi(floori(float(poder) / 50.0), 0, 10)
	var poder_col: String = "6b8c5a" if poder > 300 else ("c09a40" if poder > 150 else "8c5a5a")
	t += "[color=#999080]PODER DE COMBATE[/color]\n"
	t += " [color=#%s]%s[/color][color=#333]%s[/color] %d\n" % [
		poder_col, "█".repeat(poder_bar), "░".repeat(10 - poder_bar), poder]

	t += "[color=#999080]TRIPULACIÓN[/color]\n"
	t += _stat_line("Moral", int(bf["moral"]))
	t += _stat_line("Exp", int(bf["experiencia"]))

	t += "[color=#999080]ASIGNACIÓN[/color]\n"
	t += " [color=#c8c0b0]%s[/color]\n" % str(bf["sector"])

	return t

func _build_transport_text(fleet_data: Dictionary) -> String:
	var t: String = ""
	t += "[font_size=18][color=#807a6b]📦[/color] [color=#d9c05a][b]FLOTAS DE TRANSPORTE[/b][/color][/font_size]\n"
	t += "[color=#807a6b]Departmento Munitorum — Logística Imperial[/color]\n\n"

	var transports: Array = fleet_data.get("transport_fleets", [])
	var available: Array = []
	var in_route: Array = []

	for tr: Dictionary in transports:
		if str(tr["estado"]) == "disponible":
			available.append(tr)
		else:
			in_route.append(tr)

	# Resumen
	t += "[color=#999080]RESUMEN[/color]\n"
	t += " Total: [color=#c8c0b0]%d convoys[/color]\n" % transports.size()
	t += " Disponibles: [color=#6b8c5a]%d[/color]\n" % available.size()
	t += " En ruta: [color=#c09a40]%d[/color]\n\n" % in_route.size()

	# Disponibles (primeros 10)
	if not available.is_empty():
		t += "[color=#999080]DISPONIBLES[/color]\n"
		var show: int = mini(available.size(), 10)
		for i: int in show:
			var tr: Dictionary = available[i]
			var tipo: String = str(tr["tipo"]).capitalize()
			t += " [color=#6b8c5a]●[/color] %s [color=#807a6b](%s, %d reg, %sT)[/color]\n" % [
				str(tr["nombre"]), tipo, int(tr["capacidad_tropas"]),
				_fmt_num(int(tr["capacidad_carga"]))]
		if available.size() > 10:
			t += " [color=#605a4a]...y %d más[/color]\n" % (available.size() - 10)
		t += "\n"

	# En ruta (todos)
	if not in_route.is_empty():
		t += "[color=#999080]EN RUTA[/color]\n"
		for tr: Dictionary in in_route:
			var eta: int = int(tr["eta_turno"])
			t += " [color=#c09a40]→[/color] %s [color=#807a6b](ETA: turno %d)[/color]\n" % [
				str(tr["nombre"]), eta]

	# En tránsito (del warp)
	var in_transit: Array = fleet_data.get("fleets_in_transit", [])
	if not in_transit.is_empty():
		t += "\n[color=#999080]EN EL WARP[/color]\n"
		for ft: Dictionary in in_transit:
			var turnos: int = int(ft["turnos_restantes"])
			var perdido: bool = bool(ft.get("perdido_warp", false))
			if perdido:
				t += " [color=#8c5a5a]⚠ %s — PERDIDO EN EL WARP[/color]\n" % str(ft["nombre"])
			else:
				t += " [color=#807a6b]→ %s — %d turnos restantes[/color]\n" % [str(ft["nombre"]), turnos]

	return t

func _stat_line(label: String, value: int) -> String:
	var filled: int = floori(float(value) / 10.0)
	var empty: int = 10 - filled
	var col: String = "6b8c5a" if value >= 60 else ("c09a40" if value >= 30 else "8c5a5a")
	return " [color=#807a6b]%s[/color] [color=#%s]%s[/color][color=#333]%s[/color] %d\n" % [
		label, col, "█".repeat(filled), "░".repeat(empty), value]

func _fmt_num(n: int) -> String:
	if n >= 1000:
		return "%.1fK" % (float(n) / 1000.0)
	return str(n)
