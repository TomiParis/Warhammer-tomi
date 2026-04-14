## fleet_panel.gd - Panel de información de una Battlefleet
extends PanelContainer

var _content: RichTextLabel = null
var _close_btn: Button = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.88)
	style.border_color = Color(0.3, 0.45, 0.6, 0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	add_theme_stylebox_override("panel", style)

	# Posición: a la derecha de la lista, se ajusta al contenido
	anchor_left = 0.0
	anchor_top = 0.0
	offset_left = 170.0
	offset_top = 50.0
	custom_minimum_size = Vector2(0, 0) # Se ajusta al contenido

	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.fit_content = true
	_content.scroll_active = false
	_content.add_theme_color_override("default_color", Color(0.7, 0.68, 0.6))
	_content.add_theme_font_size_override("normal_font_size", 10)
	add_child(_content)

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
	var estado: String = str(bf["estado"])
	var ec: String = "6b8c5a"
	match estado:
		"desplegada": ec = "c09a40"
		"combate": ec = "8c5a5a"
		"reparaciones": ec = "c09a40"

	var cap: int = int(bf["naves_capital"])
	var cru: int = int(bf["cruceros"])
	var esc: int = int(bf["escoltas"])

	t += "[color=#d9c05a][b]%s[/b][/color]\n" % str(bf["nombre"])
	t += "[color=#807a6b]%s[/color]\n" % str(bf["admiral"])
	t += "[color=#%s]%s[/color] [color=#605a4a]%s[/color]\n" % [ec, estado.to_upper(), str(bf["sector"])]
	t += "[color=#807a6b]%d cap %d cru %d esc[/color]\n" % [cap, cru, esc]
	t += "[color=#d9c05a]%d naves[/color]\n" % (cap + cru + esc)
	t += _bar("Moral", int(bf["moral"]))
	t += _bar("Exp", int(bf["experiencia"]))
	return t

func _bar(label: String, value: int) -> String:
	var f: int = floori(float(value) / 12.5)
	var e: int = 8 - f
	var c: String = "6b8c5a" if value >= 60 else ("c09a40" if value >= 30 else "8c5a5a")
	return "[color=#605a4a]%s[/color] [color=#%s]%s[/color][color=#333]%s[/color] %d\n" % [label, c, "█".repeat(f), "░".repeat(e), value]

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
