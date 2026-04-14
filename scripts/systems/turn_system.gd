## turn_system.gd - Autoload que gestiona el estado del turno y coordina las fases
## Cada turno = 1 mes imperial. Procesa economía, planetas, eventos.
extends Node

# Señales
signal turno_completado(resumen: Dictionary)
signal evento_generado(evento: Dictionary)
signal fecha_cambiada(fecha_str: String)

# Estado del turno
var turno_actual: int = 0
var mes: int = 0    # 0-11
var anio: int = 999
var milenio: int = 41

# Velocidad
var auto_turno: bool = false
var velocidad: float = 1.0 # Segundos entre turnos en auto
var _auto_timer: float = 0.0
var pausar_en_evento_mayor: bool = true

# Subsistemas (se instancian acá para acceso centralizado)
var economy: EconomySystem = EconomySystem.new()
var planet_update: PlanetUpdateSystem = PlanetUpdateSystem.new()
var events: EventSystem = EventSystem.new()
var campaigns: CampaignSystem = CampaignSystem.new()
var intel: IntelSystem = IntelSystem.new()
var movement: MovementSystem = MovementSystem.new()
var chapter_sys: ChapterSystem = ChapterSystem.new()
var governance: GovernanceSystem = GovernanceSystem.new()
var fleet_sys: FleetSystem = FleetSystem.new()

# Historial de eventos
var eventos_turno_actual: Array = []
var historial_eventos: Array = [] # Últimos 200 eventos
const MAX_HISTORIAL: int = 200

# Resumen del último turno
var ultimo_resumen: Dictionary = {}

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not auto_turno:
		return
	_auto_timer += delta
	if _auto_timer >= velocidad:
		_auto_timer = 0.0
		ejecutar_turno()

# =============================================================================
# FECHA IMPERIAL
# =============================================================================

func get_fecha_imperial() -> String:
	return "%d.%03d.M%d" % [mes, anio, milenio]

func _avanzar_fecha() -> void:
	mes += 1
	if mes >= 12:
		mes = 0
		anio += 1
		if anio >= 1000:
			anio = 0
			milenio += 1
	fecha_cambiada.emit(get_fecha_imperial())

# =============================================================================
# EJECUTAR TURNO
# =============================================================================

func ejecutar_turno() -> void:
	turno_actual += 1
	_avanzar_fecha()
	eventos_turno_actual.clear()

	var galaxy: Dictionary = GameData.galaxy
	if galaxy.is_empty():
		return

	var planetas: Array = galaxy.get("planetas", [])
	if planetas.is_empty():
		return

	# Fase A: Economía
	var resumen_eco: Dictionary = economy.process(planetas)

	# Fase B: Actualización planetaria (batch)
	planet_update.process(planetas, turno_actual)

	# Fase C: Eventos (presupuesto controlado)
	var nuevos_eventos: Array = events.process(planetas, turno_actual)
	for ev_idx: int in nuevos_eventos.size():
		var ev: Dictionary = nuevos_eventos[ev_idx]
		eventos_turno_actual.append(ev)
		historial_eventos.push_front(ev)
		evento_generado.emit(ev)

	# Limpiar historial viejo
	while historial_eventos.size() > MAX_HISTORIAL:
		historial_eventos.pop_back()

	# Fase D: Gobernanza imperial
	var gd_node: Node = get_node_or_null("/root/GameData")
	var faction_rels: Dictionary = gd_node.faction_relations if gd_node else {}
	var resumen_gov: Dictionary = governance.process(planetas, faction_rels, turno_actual)

	# Fase E: Flotas y navegación warp
	var fl_data: Dictionary = gd_node.fleet_data if gd_node else {}
	var resumen_fleet: Dictionary = fleet_sys.process(fl_data, planetas, turno_actual)

	# Fase F: Capítulos de Space Marines
	var ch_list: Array = gd_node.chapters if gd_node else []
	var resumen_chapters: Dictionary = chapter_sys.process(ch_list, planetas, turno_actual)

	# Fase G: Campañas militares
	var resumen_camp: Dictionary = campaigns.process(planetas, turno_actual)

	# Fase H: Inteligencia
	var resumen_intel: Dictionary = intel.process(planetas, turno_actual)

	# Fase I: Movimiento
	var resumen_mov: Dictionary = movement.process(planetas, turno_actual)

	# Construir resumen
	ultimo_resumen = {
		"turno": turno_actual,
		"fecha": get_fecha_imperial(),
		"economia": resumen_eco,
		"eventos_count": eventos_turno_actual.size(),
		"eventos": eventos_turno_actual,
		"gobernanza": resumen_gov,
		"flotas": resumen_fleet,
		"chapters": resumen_chapters,
		"campanas": resumen_camp,
		"inteligencia": resumen_intel,
		"movimiento": resumen_mov,
	}

	turno_completado.emit(ultimo_resumen)

	# Auto-pausa si hay evento mayor o apocalíptico
	if pausar_en_evento_mayor:
		for ev: Dictionary in eventos_turno_actual:
			var sev: int = int(ev.get("severity", 0))
			if sev >= EventDefinitions.Severity.MAJOR:
				auto_turno = false
				break

# =============================================================================
# CONTROLES DE VELOCIDAD
# =============================================================================

func set_velocidad(nueva: float) -> void:
	velocidad = nueva

func toggle_auto_turno() -> void:
	auto_turno = not auto_turno
	_auto_timer = 0.0

func set_auto_turno(val: bool) -> void:
	auto_turno = val
	_auto_timer = 0.0
