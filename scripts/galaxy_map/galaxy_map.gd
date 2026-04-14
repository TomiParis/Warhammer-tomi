## galaxy_map.gd - Controller principal del mapa galáctico
## Maneja Camera2D, input, state machine y coordinación general
extends Node2D

# === ESTADOS ===
enum MapState { GALAXY, SEGMENTUM, SECTOR }

# === ZOOM LEVELS ===
const ZOOM_GALAXY: float = 0.065
const ZOOM_SEGMENTUM: float = 0.25
const ZOOM_SECTOR: float = 1.8
const ZOOM_MIN: float = 0.04
const ZOOM_MAX: float = 4.0
const ZOOM_SPEED: float = 0.1
const PAN_SPEED: float = 1.0

# === NODOS ===
@onready var camera: Camera2D = $Camera2D
@onready var renderer: Node2D = $GalaxyRenderer
@onready var ui_layer: CanvasLayer = $UILayer
@onready var breadcrumb: HBoxContainer = $UILayer/Breadcrumb
@onready var tooltip: PanelContainer = $UILayer/Tooltip
@onready var info_panel: PanelContainer = $UILayer/PlanetInfoPanel
@onready var search_panel: PanelContainer = $UILayer/SearchPanel
@onready var filter_panel: PanelContainer = $UILayer/FilterPanel
@onready var minimap_container: Control = $UILayer/Minimap
@onready var chapter_panel: PanelContainer = $UILayer/ChapterPanel
@onready var fleet_list_panel: PanelContainer = $UILayer/FleetListPanel
@onready var campaign_panel: PanelContainer = $UILayer/CampaignPanel

# === DATOS ===
var galaxy: Dictionary = {}
var data_provider: GalaxyDataProvider = GalaxyDataProvider.new()
var current_state: MapState = MapState.GALAXY
var selected_segmentum: String = ""
var selected_sector: String = "" # "seg.sec"
var selected_planet: Dictionary = {}
var hovered_planet: Dictionary = {}

# === INPUT ===
var _is_panning: bool = false
var _pan_start: Vector2 = Vector2.ZERO
var _current_zoom: float = ZOOM_GALAXY
var _target_zoom: float = ZOOM_GALAXY
var _is_transitioning: bool = false

# === FILTROS ===
var active_filters: Dictionary = {} # tipo -> bool, lado -> bool, etc.
var filter_dimmed_ids: Dictionary = {} # planet_id -> true si atenuado

func _ready() -> void:
	add_to_group("galaxy_map")

	# Generar la galaxia usando el generador escalable
	var generator: GalaxyGenerator = GalaxyGenerator.new()
	galaxy = generator.generate_galaxy(42)

	# Calcular posiciones
	data_provider.calculate_all(galaxy)

	# Configurar cámara
	camera.zoom = Vector2(ZOOM_GALAXY, ZOOM_GALAXY)
	_current_zoom = ZOOM_GALAXY
	_target_zoom = ZOOM_GALAXY
	camera.position = Vector2.ZERO

	# Registrar galaxia en el singleton GameData
	var gd_node: Node = get_node_or_null("/root/GameData")
	if gd_node and gd_node.has_method("set_galaxy"):
		gd_node.set_galaxy(galaxy)

	# Generar Capítulos de Space Marines
	var ch_gen: ChapterGenerator = ChapterGenerator.new()
	var ch_list: Array = ch_gen.generate_chapters(galaxy, 42)
	if gd_node and gd_node.has_method("set_chapters"):
		gd_node.set_chapters(ch_list)
	print(">>> %d Capítulos de Space Marines generados" % ch_list.size())

	# Generar sistema de gobernanza
	var gov_gen: GovernanceGenerator = GovernanceGenerator.new()
	var gov_data: Dictionary = gov_gen.generate(galaxy, 42)
	if gd_node and gd_node.has_method("set_governance"):
		gd_node.set_governance(gov_data)
	print(">>> Gobernanza: %d Lord Sectors, %d Knight Houses, %d Rogue Traders" % [
		gov_data["lord_sectors"].size(), gov_data["knight_houses"].size(), gov_data["rogue_traders"].size()
	])

	# Generar flotas y rutas warp
	var fl_gen: FleetGenerator = FleetGenerator.new()
	var fl_data: Dictionary = fl_gen.generate(galaxy, 42)
	if gd_node and gd_node.has_method("set_fleet_data"):
		gd_node.set_fleet_data(fl_data)
	print(">>> Flotas: %d Battlefleets, %d Transportes, %d Rutas Warp" % [
		fl_data["battlefleets"].size(), fl_data["transport_fleets"].size(), fl_data["warp_routes"].size()
	])

	# Generar unidades militares (guarniciones)
	var mil_gen: MilitaryGenerator = MilitaryGenerator.new()
	var mil_units: Array = mil_gen.generate(galaxy, 42)
	if gd_node:
		gd_node.military_units = mil_units
	print(">>> Militar: %d regimientos generados" % mil_units.size())

	# Pasar datos al renderer
	renderer.setup(galaxy, data_provider, self)

	# Inicializar UI
	_setup_ui()

	# Conectar señales del sistema de turnos
	var turn_sys: Node = get_node_or_null("/root/TurnSystem")
	if turn_sys and turn_sys.has_signal("turno_completado"):
		turn_sys.turno_completado.connect(_on_turno_completado)

	# Informar al renderer del estado inicial
	renderer.set_state(MapState.GALAXY, "", "")

func _on_turno_completado(_resumen: Dictionary) -> void:
	# Redibujar el mapa para reflejar cambios de stats/amenazas
	renderer.queue_redraw()

func _setup_ui() -> void:
	# Inicializar componentes UI
	if breadcrumb and breadcrumb.has_method("setup"):
		breadcrumb.setup(self)
	if info_panel:
		info_panel.visible = false
	if search_panel:
		search_panel.visible = false
		if search_panel.has_method("setup"):
			search_panel.setup(self)
	if tooltip:
		tooltip.visible = false
	if filter_panel and filter_panel.has_method("setup"):
		filter_panel.setup(self)
	if minimap_container and minimap_container.has_method("setup"):
		minimap_container.setup(self, data_provider)

func _process(delta: float) -> void:
	# Zoom suave (solo cuando NO hay tween activo)
	if not _is_transitioning and absf(_current_zoom - _target_zoom) > 0.001:
		_current_zoom = lerpf(_current_zoom, _target_zoom, delta * 8.0)
		camera.zoom = Vector2(_current_zoom, _current_zoom)
		renderer.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return

	# --- Ignorar input si el mouse está sobre un panel de UI ---
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if _is_mouse_over_ui():
			return

	# --- ZOOM con scroll ---
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_target_zoom = clampf(_target_zoom * 1.15, ZOOM_MIN, ZOOM_MAX)
				_check_state_transition()
				get_viewport().set_input_as_handled()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_target_zoom = clampf(_target_zoom / 1.15, ZOOM_MIN, ZOOM_MAX)
				_check_state_transition()
				get_viewport().set_input_as_handled()

			# --- PAN con click derecho ---
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				_is_panning = true
				_pan_start = mb.position
				get_viewport().set_input_as_handled()

			# --- SELECCIÓN con click izquierdo ---
			elif mb.button_index == MOUSE_BUTTON_LEFT:
				_handle_click(mb.global_position)
				get_viewport().set_input_as_handled()

		elif not mb.pressed:
			if mb.button_index == MOUSE_BUTTON_RIGHT:
				_is_panning = false

	# --- PAN arrastrando ---
	if event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if _is_panning:
			var delta_pan: Vector2 = -mm.relative / _current_zoom * PAN_SPEED
			camera.position += delta_pan
			renderer.queue_redraw()
		else:
			_handle_hover(mm.position)

	# --- ATAJOS ---
	if event is InputEventKey:
		var key: InputEventKey = event
		if key.pressed:
			if key.keycode == KEY_F and key.ctrl_pressed:
				_toggle_search()
				get_viewport().set_input_as_handled()
			elif key.keycode == KEY_ESCAPE:
				_go_back()
				get_viewport().set_input_as_handled()

func _is_mouse_over_ui() -> bool:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ui_panels: Array = [info_panel, filter_panel, search_panel, chapter_panel, fleet_list_panel]
	var turn_p: Control = ui_layer.get_node_or_null("TurnPanel")
	if turn_p:
		ui_panels.append(turn_p)
	var ev_log: Control = ui_layer.get_node_or_null("EventLog")
	if ev_log:
		ui_panels.append(ev_log)
	for panel in ui_panels:
		if panel == null or not panel is Control:
			continue
		var ctrl: Control = panel as Control
		if ctrl.visible and ctrl.get_global_rect().has_point(mouse_pos):
			return true
	return false

# =============================================================================
# TRANSICIONES ENTRE CAPAS
# =============================================================================

func _check_state_transition() -> void:
	var seg_zoom: float = _calc_segmentum_zoom(selected_segmentum) if selected_segmentum != "" else ZOOM_SEGMENTUM

	match current_state:
		MapState.SECTOR:
			# Alejar desde sector: volver a segmentum (umbral más sensible)
			if _target_zoom < seg_zoom * 3.0:
				_enter_segmentum(selected_segmentum)
		MapState.SEGMENTUM:
			# Acercar: entrar a sector
			if _target_zoom > seg_zoom * 5.0 and selected_segmentum != "":
				var sec: String = data_provider.find_sector_at(camera.position, selected_segmentum)
				if sec != "":
					_enter_sector(sec)
			# Alejar: volver a galaxia
			elif _target_zoom < ZOOM_GALAXY * 1.8:
				_enter_galaxy()
		MapState.GALAXY:
			pass # Solo se entra a segmentum por click, no por zoom

func _handle_click(screen_pos: Vector2) -> void:
	var world_pos: Vector2 = _screen_to_world(screen_pos)

	match current_state:
		MapState.GALAXY:
			# Solo navegar si el click cae DENTRO de un segmentum visible
			# (dentro del disco galáctico y del polígono del segmentum)
			var dist_to_terra: float = world_pos.distance_to(data_provider.TERRA_OFFSET)
			if dist_to_terra > data_provider.GALAXY_DISC_RADIUS:
				return # Click fuera de la galaxia
			var seg: String = data_provider.find_segmentum_at(world_pos)
			if seg != "":
				navigate_to_segmentum(seg)

		MapState.SEGMENTUM:
			# Primero verificar si clickeó una Battlefleet
			var bf: Dictionary = _find_battlefleet_at(world_pos, 30.0 / _current_zoom)
			if not bf.is_empty():
				_show_fleet(bf)
				return
			# Solo navegar si el click cae DENTRO del radio del sector
			var sec: String = data_provider.find_sector_at_within_radius(world_pos, selected_segmentum)
			if sec != "":
				navigate_to_sector(sec)

		MapState.SECTOR:
			# Primero buscar si clickeó un capítulo
			var ch: Dictionary = _find_chapter_at(world_pos, 15.0 / _current_zoom)
			if not ch.is_empty():
				_show_chapter(ch)
				return

			var planet: Dictionary = data_provider.find_planet_at(
				world_pos, selected_sector, galaxy, 20.0 / _current_zoom
			)
			if not planet.is_empty():
				select_planet(planet)
				# Si el planeta tiene un capítulo, también se puede ver
				_hide_chapter()
			else:
				deselect_planet()
				_hide_chapter()

func _handle_hover(screen_pos: Vector2) -> void:
	if current_state != MapState.SECTOR:
		if tooltip:
			tooltip.visible = false
		return

	var world_pos: Vector2 = _screen_to_world(screen_pos)
	var planet: Dictionary = data_provider.find_planet_at(
		world_pos, selected_sector, galaxy, 20.0 / _current_zoom
	)

	if not planet.is_empty() and tooltip and tooltip.has_method("show_planet"):
		hovered_planet = planet
		tooltip.show_planet(planet, screen_pos)
	elif tooltip:
		tooltip.visible = false
		hovered_planet = {}

func _find_chapter_at(world_pos: Vector2, threshold: float) -> Dictionary:
	var gd_node: Node = get_node_or_null("/root/GameData")
	if gd_node == null:
		return {}
	var ch_list: Array = gd_node.chapters
	var best_dist: float = threshold
	var best_ch: Dictionary = {}
	for ch_idx: int in ch_list.size():
		var ch: Dictionary = ch_list[ch_idx]
		var mundo_id: int = int(ch["mundo_natal_id"])
		if mundo_id < 0:
			continue
		if not data_provider.planet_positions.has(mundo_id):
			continue
		var pos: Vector2 = data_provider.planet_positions[mundo_id]
		var dist: float = world_pos.distance_to(pos)
		if dist < best_dist:
			best_dist = dist
			best_ch = ch
	return best_ch

func _show_chapter(ch: Dictionary) -> void:
	if chapter_panel and chapter_panel.has_method("show_chapter"):
		chapter_panel.show_chapter(ch)
		chapter_panel.visible = true
		if info_panel:
			info_panel.visible = false

func _hide_chapter() -> void:
	if chapter_panel:
		chapter_panel.visible = false

func _find_battlefleet_at(world_pos: Vector2, threshold: float) -> Dictionary:
	var gd_node: Node = get_node_or_null("/root/GameData")
	if gd_node == null:
		return {}
	var fl_data: Dictionary = gd_node.fleet_data
	if fl_data.is_empty():
		return {}
	var battlefleets: Array = fl_data.get("battlefleets", [])
	for bf: Dictionary in battlefleets:
		var bf_sector: String = str(bf["sector"])
		if not bf_sector.begins_with(selected_segmentum):
			continue
		if not data_provider.sector_positions.has(bf_sector):
			continue
		var pos: Vector2 = data_provider.sector_positions[bf_sector] + Vector2(0.0, -50.0)
		if world_pos.distance_to(pos) < threshold:
			return bf
	return {}

func _show_fleet(_bf: Dictionary) -> void:
	# El fleet_list_panel maneja todo ahora — expandirlo si está minimizado
	if fleet_list_panel and fleet_list_panel.has_method("_on_toggle"):
		if fleet_list_panel._minimized:
			fleet_list_panel._on_toggle()

func _hide_fleet() -> void:
	pass

func _show_campaign(camp: Dictionary) -> void:
	var gd_node: Node = get_node_or_null("/root/GameData")
	if campaign_panel and campaign_panel.has_method("show_campaign"):
		var mil_units: Array = gd_node.military_units if gd_node else []
		campaign_panel.show_campaign(camp, mil_units)
		campaign_panel.visible = true
		if info_panel:
			info_panel.visible = false

func _show_fleet_transports() -> void:
	if fleet_list_panel and fleet_list_panel.has_method("_switch_tab"):
		if fleet_list_panel._minimized:
			fleet_list_panel._on_toggle()
		fleet_list_panel._switch_tab("transport")

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var cam_pos: Vector2 = camera.global_position
	var offset: Vector2 = (screen_pos - viewport_size / 2.0) / _current_zoom
	return cam_pos + offset

# =============================================================================
# NAVEGACIÓN PÚBLICA (llamada desde UI)
# =============================================================================

func navigate_to_segmentum(seg_key: String) -> void:
	var target_pos: Vector2 = data_provider.segmentum_centers.get(seg_key, Vector2.ZERO)
	# Zoom dinámico: segmentums más grandes necesitan zoom más lejano
	var zoom: float = _calc_segmentum_zoom(seg_key)
	_animate_to(target_pos, zoom, func() -> void: _enter_segmentum(seg_key))

func _calc_segmentum_zoom(seg_key: String) -> float:
	if seg_key == "solar":
		return 0.35 # Solar es compacto
	var arcs: Dictionary = GalaxyConfig.SEG_ARCS
	if arcs.has(seg_key):
		var arc_size: float = float(arcs[seg_key]["arc"])
		# 60° arco → zoom 0.25, 150° arco → zoom 0.12
		return clampf(15.0 / arc_size, 0.08, 0.35)
	return ZOOM_SEGMENTUM

func navigate_to_sector(sector_full_key: String) -> void:
	var target_pos: Vector2 = data_provider.sector_positions.get(sector_full_key, Vector2.ZERO)
	_animate_to(target_pos, ZOOM_SECTOR, func() -> void: _enter_sector(sector_full_key))

func navigate_to_planet(planet: Dictionary) -> void:
	var pid: int = int(planet["id"])
	var pos: Vector2 = data_provider.planet_positions.get(pid, Vector2.ZERO)
	var seg: String = str(planet["segmentum"])
	var sec: String = seg + "." + str(planet["sector"])

	# Navegar por capas hasta llegar al planeta
	selected_segmentum = seg
	selected_sector = sec
	_animate_to(pos, ZOOM_SECTOR * 1.5, func() -> void:
		_enter_sector(sec)
		select_planet(planet)
	)

func navigate_to_galaxy() -> void:
	_animate_to(Vector2.ZERO, ZOOM_GALAXY, func() -> void: _enter_galaxy())

func _go_back() -> void:
	match current_state:
		MapState.SECTOR:
			navigate_to_segmentum(selected_segmentum)
		MapState.SEGMENTUM:
			navigate_to_galaxy()
		MapState.GALAXY:
			pass # Ya estamos en el nivel más alto

func select_planet(planet: Dictionary) -> void:
	selected_planet = planet
	if info_panel and info_panel.has_method("show_planet"):
		info_panel.show_planet(planet)
		info_panel.visible = true
	renderer.queue_redraw()

func deselect_planet() -> void:
	selected_planet = {}
	if info_panel:
		info_panel.visible = false
	renderer.queue_redraw()

func _toggle_search() -> void:
	if search_panel:
		search_panel.visible = not search_panel.visible
		if search_panel.visible and search_panel.has_method("focus_search"):
			search_panel.focus_search()

# =============================================================================
# CAMBIOS DE ESTADO INTERNOS
# =============================================================================

func _enter_galaxy() -> void:
	current_state = MapState.GALAXY
	selected_segmentum = ""
	selected_sector = ""
	deselect_planet()
	renderer.set_state(MapState.GALAXY, "", "")
	_update_breadcrumb()

func _enter_segmentum(seg_key: String) -> void:
	current_state = MapState.SEGMENTUM
	selected_segmentum = seg_key
	selected_sector = ""
	deselect_planet()
	renderer.set_state(MapState.SEGMENTUM, seg_key, "")
	_update_breadcrumb()

func _enter_sector(sector_full_key: String) -> void:
	current_state = MapState.SECTOR
	var parts: PackedStringArray = sector_full_key.split(".")
	if parts.size() >= 2:
		selected_segmentum = parts[0]
	selected_sector = sector_full_key
	renderer.set_state(MapState.SECTOR, selected_segmentum, sector_full_key)
	_update_breadcrumb()

func _update_breadcrumb() -> void:
	if breadcrumb and breadcrumb.has_method("update_path"):
		breadcrumb.update_path(current_state, selected_segmentum, selected_sector, galaxy)

# =============================================================================
# ANIMACIÓN
# =============================================================================

func _animate_to(target_pos: Vector2, target_zoom_val: float, on_complete: Callable) -> void:
	_is_transitioning = true
	_target_zoom = target_zoom_val

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	tween.tween_property(camera, "position", target_pos, 0.4)
	# Tweenar zoom visual directamente via método (camera.zoom + variable interna)
	tween.tween_method(func(val: float) -> void:
		_current_zoom = val
		camera.zoom = Vector2(val, val)
		renderer.queue_redraw()
	, _current_zoom, target_zoom_val, 0.4)

	tween.chain().tween_callback(func() -> void:
		_is_transitioning = false
		on_complete.call()
	)
