## event_definitions.gd - Definiciones de todos los tipos de eventos
## Para agregar un evento: solo agregar entrada al diccionario correspondiente
class_name EventDefinitions

# Severidades
enum Severity { MINOR, MEDIUM, MAJOR, APOCALYPTIC }

# Categorías
enum Category { POLITICAL, MILITARY, ECONOMIC, CHAOS, XENOS, NATURAL, FAITH }

# Presupuesto de eventos por turno (cuántos slots hay por severidad)
const BUDGET := {
	Severity.MINOR: {"min": 2, "max": 5},
	Severity.MEDIUM: {"min": 0, "max": 2},
	Severity.MAJOR: {"interval_min": 8, "interval_max": 20},   # Cada N turnos
	Severity.APOCALYPTIC: {"interval_min": 30, "interval_max": 60},
}

# Colores por severidad (para UI)
const SEVERITY_COLORS := {
	Severity.MINOR: Color(0.5, 0.55, 0.45),
	Severity.MEDIUM: Color(0.8, 0.65, 0.2),
	Severity.MAJOR: Color(0.8, 0.3, 0.15),
	Severity.APOCALYPTIC: Color(0.9, 0.1, 0.1),
}

const SEVERITY_NAMES := {
	Severity.MINOR: "Menor",
	Severity.MEDIUM: "Crisis",
	Severity.MAJOR: "Catástrofe",
	Severity.APOCALYPTIC: "Apocalíptico",
}

const CATEGORY_NAMES := {
	Category.POLITICAL: "Político",
	Category.MILITARY: "Militar",
	Category.ECONOMIC: "Económico",
	Category.CHAOS: "Caos",
	Category.XENOS: "Xenos",
	Category.NATURAL: "Natural",
	Category.FAITH: "Fe",
}

# =============================================================================
# DEFINICIONES DE EVENTOS
# =============================================================================
# condicion: función que evalúa si el evento puede ocurrir en un planeta
# efectos: cambios a aplicar al planeta
# Para agregar evento: solo agregar entrada al array

const EVENTS := [
	# --- MENORES (incidentes cotidianos) ---
	{
		"id": "minor_unrest",
		"nombre": "Disturbios Civiles",
		"descripcion": "Protestas y disturbios menores en las ciudades principales.",
		"severity": Severity.MINOR,
		"category": Category.POLITICAL,
		"condicion": "lealtad < 60",
		"efectos": {"lealtad_imperial": -3, "capacidad_industrial": -2},
		"duracion": 1,
	},
	{
		"id": "minor_corruption",
		"nombre": "Escándalo de Corrupción",
		"descripcion": "Se descubre una red de corrupción en el gobierno planetario.",
		"severity": Severity.MINOR,
		"category": Category.POLITICAL,
		"condicion": "corrupcion_gobernador > 10",
		"efectos": {"lealtad_imperial": -2, "corrupcion_gobernador": 5},
		"duracion": 1,
	},
	{
		"id": "minor_tithe_shortfall",
		"nombre": "Escasez de Diezmo",
		"descripcion": "El planeta no alcanza su cuota de producción para el diezmo imperial.",
		"severity": Severity.MINOR,
		"category": Category.ECONOMIC,
		"condicion": "capacidad_industrial < 40",
		"efectos": {"capacidad_industrial": -3, "lealtad_imperial": -1},
		"duracion": 1,
	},
	{
		"id": "minor_warp_anomaly",
		"nombre": "Anomalía Warp Menor",
		"descripcion": "Fluctuaciones en la Disformidad perturban las comunicaciones.",
		"severity": Severity.MINOR,
		"category": Category.CHAOS,
		"condicion": "estabilidad_warp < 50",
		"efectos": {"estabilidad_warp": -5, "infiltracion_caos": 2},
		"duracion": 2,
	},
	{
		"id": "minor_xenos_raid",
		"nombre": "Incursión Xenos Menor",
		"descripcion": "Piratas xenos atacan naves comerciales en las rutas cercanas.",
		"severity": Severity.MINOR,
		"category": Category.XENOS,
		"condicion": "capacidad_militar < 50",
		"efectos": {"capacidad_militar": -3, "capacidad_industrial": -2},
		"duracion": 1,
	},
	{
		"id": "minor_faith_revival",
		"nombre": "Resurgimiento de Fe",
		"descripcion": "Un predicador carismático inspira un resurgimiento del culto imperial.",
		"severity": Severity.MINOR,
		"category": Category.FAITH,
		"condicion": "fe > 40",
		"efectos": {"fe_imperial": 5, "lealtad_imperial": 2},
		"duracion": 1,
	},
	{
		"id": "minor_industrial_accident",
		"nombre": "Accidente Industrial",
		"descripcion": "Una explosión en una manufactoría causa pérdidas de producción.",
		"severity": Severity.MINOR,
		"category": Category.ECONOMIC,
		"condicion": "capacidad_industrial > 50",
		"efectos": {"capacidad_industrial": -5},
		"duracion": 1,
	},
	{
		"id": "minor_mutant_sighting",
		"nombre": "Avistamiento de Mutantes",
		"descripcion": "Se reportan mutantes en los niveles inferiores. La tensión crece.",
		"severity": Severity.MINOR,
		"category": Category.CHAOS,
		"condicion": "infiltracion_caos > 10",
		"efectos": {"fe_imperial": -2, "infiltracion_caos": 1},
		"duracion": 1,
	},

	# --- MEDIOS (crisis que requieren atención) ---
	{
		"id": "medium_rebellion",
		"nombre": "Rebelión Provincial",
		"descripcion": "Una región entera se levanta contra el gobernador planetario.",
		"severity": Severity.MEDIUM,
		"category": Category.POLITICAL,
		"condicion": "lealtad < 35",
		"efectos": {"lealtad_imperial": -10, "capacidad_militar": -8, "capacidad_industrial": -10},
		"duracion": 3,
	},
	{
		"id": "medium_chaos_cult",
		"nombre": "Culto del Caos Descubierto",
		"descripcion": "La Inquisición descubre una red de cultistas del Caos infiltrados.",
		"severity": Severity.MEDIUM,
		"category": Category.CHAOS,
		"condicion": "infiltracion_caos > 25",
		"efectos": {"infiltracion_caos": -10, "fe_imperial": -5, "lealtad_imperial": -5},
		"duracion": 2,
	},
	{
		"id": "medium_genestealer",
		"nombre": "Insurrección Genestealer",
		"descripcion": "Un Culto Genestealer emerge de las sombras y ataca infraestructura clave.",
		"severity": Severity.MEDIUM,
		"category": Category.XENOS,
		"condicion": "infiltracion_genestealer > 3",
		"efectos": {"capacidad_militar": -10, "capacidad_industrial": -8, "infiltracion_genestealer": -2},
		"duracion": 3,
	},
	{
		"id": "medium_plague",
		"nombre": "Epidemia Desconocida",
		"descripcion": "Una plaga misteriosa se propaga rápidamente entre la población.",
		"severity": Severity.MEDIUM,
		"category": Category.NATURAL,
		"condicion": "estabilidad_warp < 40",
		"efectos": {"fe_imperial": -8, "capacidad_industrial": -12, "lealtad_imperial": -5},
		"duracion": 4,
	},
	{
		"id": "medium_ork_waaagh",
		"nombre": "WAAAGH! Localizado",
		"descripcion": "Una horda orka desorganizada ataca las defensas del planeta.",
		"severity": Severity.MEDIUM,
		"category": Category.XENOS,
		"condicion": "capacidad_militar < 40",
		"efectos": {"capacidad_militar": -15, "capacidad_industrial": -10},
		"duracion": 3,
	},
	{
		"id": "medium_governor_coup",
		"nombre": "Golpe de Estado",
		"descripcion": "El gobernador planetario es derrocado por una facción rival.",
		"severity": Severity.MEDIUM,
		"category": Category.POLITICAL,
		"condicion": "corrupcion_gobernador > 40",
		"efectos": {"lealtad_imperial": -8, "corrupcion_gobernador": -20, "capacidad_militar": -5},
		"duracion": 2,
	},

	# --- MAYORES (catástrofes regionales) ---
	{
		"id": "major_daemon_incursion",
		"nombre": "Incursión Demoníaca",
		"descripcion": "El Velo de la Realidad se rasga. Demonios irrumpen en el mundo material.",
		"severity": Severity.MAJOR,
		"category": Category.CHAOS,
		"condicion": "infiltracion_caos > 40 and estabilidad_warp < 30",
		"efectos": {"capacidad_militar": -25, "fe_imperial": -20, "lealtad_imperial": -15, "infiltracion_caos": 20},
		"duracion": 6,
	},
	{
		"id": "major_hive_fleet_tendril",
		"nombre": "Tendril de Flota Colmena",
		"descripcion": "Un tendril de una Flota Colmena Tiránida se aproxima al sistema.",
		"severity": Severity.MAJOR,
		"category": Category.XENOS,
		"condicion": "capacidad_militar < 50",
		"efectos": {"capacidad_militar": -30, "capacidad_industrial": -20, "lealtad_imperial": -10},
		"duracion": 8,
	},
	{
		"id": "major_full_rebellion",
		"nombre": "Rebelión Planetaria Total",
		"descripcion": "El planeta entero se levanta en armas contra el Imperium.",
		"severity": Severity.MAJOR,
		"category": Category.POLITICAL,
		"condicion": "lealtad < 20",
		"efectos": {"lealtad_imperial": -30, "capacidad_militar": -20, "fe_imperial": -15},
		"duracion": 6,
	},

	# --- APOCALÍPTICOS (cambian la partida) ---
	{
		"id": "apocalyptic_warp_storm",
		"nombre": "Tormenta Warp Masiva",
		"descripcion": "Una tormenta Warp colosal aísla todo el subsector. Las comunicaciones se cortan.",
		"severity": Severity.APOCALYPTIC,
		"category": Category.CHAOS,
		"condicion": "estabilidad_warp < 25",
		"efectos": {"estabilidad_warp": -40, "infiltracion_caos": 30, "fe_imperial": -20, "lealtad_imperial": -20},
		"duracion": 12,
	},
	{
		"id": "apocalyptic_tomb_awakening",
		"nombre": "Despertar de Mundo Tumba",
		"descripcion": "Los Necrones bajo la superficie comienzan a despertar. El planeta está condenado.",
		"severity": Severity.APOCALYPTIC,
		"category": Category.XENOS,
		"condicion": "es_tomb_world",
		"efectos": {"capacidad_militar": -40, "capacidad_industrial": -30, "lealtad_imperial": -25},
		"duracion": 12,
	},
]
