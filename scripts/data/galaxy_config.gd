## galaxy_config.gd - Configuración escalable de la galaxia
## PARA EXPANDIR: solo modificar los números aquí, NO tocar lógica
## Agregar segmentum/sector = agregar entrada al diccionario
class_name GalaxyConfig

# =============================================================================
# GEOMETRÍA GALÁCTICA
# =============================================================================
const GALAXY_DISC_RADIUS: float = 4800.0
const SOLAR_RADIUS: float = 600.0
const MAP_RADIUS: float = 4500.0
const TERRA_OFFSET: Vector2 = Vector2(-1300.0, 230.0)
const ASTRONOMICAN_RADIUS: float = 3800.0

# =============================================================================
# CONFIGURACIÓN DE SEGMENTUMS — Cambiar estos valores para expandir
# =============================================================================
# planetas_target: cuántos planetas queremos en este segmentum
# amenaza_base_caos/xenos: valores base de amenaza
# type_mods: multiplicadores de distribución de tipos (>1 = más, <1 = menos)

const SEGMENTUM_CONFIG := {
	"solar": {
		"nombre": "Segmentum Solar",
		"descripcion": "Corazón del Imperium. Terra, Mars.",
		"fortaleza": "Mars (Anillo de Hierro)",
		"planetas_target": 200,
		"amenaza_base_caos": 5,
		"amenaza_base_xenos": 10,
		"type_mods": {
			"hive_world": 1.5, "forge_world": 1.8, "fortress_world": 0.5,
			"death_world": 0.3, "feral_world": 0.3, "research_station": 1.5,
		},
	},
	"obscurus": {
		"nombre": "Segmentum Obscurus",
		"descripcion": "Norte galáctico. Ojo del Terror, Cadia.",
		"fortaleza": "Cypra Mundi",
		"planetas_target": 200,
		"amenaza_base_caos": 40,
		"amenaza_base_xenos": 10,
		"type_mods": {
			"fortress_world": 3.0, "shrine_world": 1.3, "death_world": 1.2,
			"paradise_world": 0.3, "hive_world": 0.8,
		},
	},
	"ultima": {
		"nombre": "Segmentum Ultima",
		"descripcion": "Este galáctico, el más grande (~1/3 de la galaxia).",
		"fortaleza": "Kar Duniash",
		"planetas_target": 500,
		"amenaza_base_caos": 15,
		"amenaza_base_xenos": 35,
		"type_mods": {
			"death_world": 1.5, "feral_world": 1.5, "civilised_world": 1.2,
			"forge_world": 0.8,
		},
	},
	"tempestus": {
		"nombre": "Segmentum Tempestus",
		"descripcion": "Sur galáctico. Relativamente seguro del Caos.",
		"fortaleza": "Bakka",
		"planetas_target": 200,
		"amenaza_base_caos": 10,
		"amenaza_base_xenos": 25,
		"type_mods": {
			"shrine_world": 1.5, "cardinal_world": 1.5, "agri_world": 1.2,
			"fortress_world": 0.7, "mining_world": 1.2,
		},
	},
	"pacificus": {
		"nombre": "Segmentum Pacificus",
		"descripcion": "Oeste galáctico, poco explorado. Históricamente rebelde.",
		"fortaleza": "Hydraphur",
		"planetas_target": 200,
		"amenaza_base_caos": 20,
		"amenaza_base_xenos": 15,
		"type_mods": {
			"feudal_world": 1.5, "feral_world": 1.3, "fortress_world": 1.3,
			"forge_world": 0.5, "hive_world": 0.7,
		},
	},
}

# Colores por segmentum (para el mapa)
const SEG_COLORS := {
	"solar": Color(0.85, 0.75, 0.3, 0.12),
	"obscurus": Color(0.7, 0.15, 0.15, 0.12),
	"ultima": Color(0.2, 0.35, 0.7, 0.12),
	"tempestus": Color(0.15, 0.4, 0.2, 0.12),
	"pacificus": Color(0.4, 0.15, 0.5, 0.12),
}

# Arcos angulares canónicos (grados Godot)
# Para agregar un segmentum: agregar arco + ajustar los existentes
const SEG_ARCS := {
	"obscurus":  {"start": 225.0, "end": 315.0, "arc": 90.0},
	"ultima":    {"start": 315.0, "end": 470.0, "arc": 155.0},
	"tempestus": {"start": 110.0, "end": 180.0, "arc": 70.0},
	"pacificus": {"start": 180.0, "end": 225.0, "arc": 45.0},
}

# =============================================================================
# CONFIGURACIÓN DE SECTORES — Agregar sector = agregar entrada aquí
# =============================================================================
# map_pos: [grados_mapa, fraccion_radio] — posición canónica opcional
# Si no tiene map_pos, el generador lo posiciona automáticamente en el arco

const SECTOR_CONFIG := {
	# === SEGMENTUM SOLAR ===
	"solar": {
		"solar": {
			"nombre": "Sector Solar",
			"lado_grieta": "sanctus",
			"amenaza_mod": 10,
			"warp_mod": 20,
			"subsectores": ["Sol", "Jovian Reach", "Saturnia", "Terran Gate"],
		},
		"moebian": {
			"nombre": "Sector Moebian",
			"lado_grieta": "sanctus",
			"amenaza_mod": 25,
			"warp_mod": 10,
			"subsectores": ["Moebian Alpha", "Moebian Beta", "Atoma Prime", "Thracian Belt"],
		},
		"armageddon": {
			"nombre": "Sector Armageddon",
			"lado_grieta": "sanctus",
			"amenaza_mod": 45,
			"warp_mod": 5,
			"subsectores": ["Armageddon Prime", "Steel Host", "Ash Wastes"],
		},
		"voss": {
			"nombre": "Sector Voss",
			"lado_grieta": "sanctus",
			"amenaza_mod": 20,
			"warp_mod": 10,
			"subsectores": ["Voss Prime", "Infernus", "Kronisar", "Delphi Reach"],
		},
	},
	# === SEGMENTUM OBSCURUS ===
	"obscurus": {
		"cadian": {
			"nombre": "Sector Cadian",
			"lado_grieta": "sanctus",
			"amenaza_mod": 80,
			"warp_mod": -25,
			"subsectores": ["Cadian Gate", "Agripinaa", "Belis Corona", "Sentinel Worlds"],
		},
		"calixis": {
			"nombre": "Sector Calixis",
			"lado_grieta": "sanctus",
			"amenaza_mod": 40,
			"warp_mod": -5,
			"subsectores": ["Golgenna Reach", "Drusus Marches", "Malfian", "Hazeroth Abyss", "Josian Reach"],
		},
		"scarus": {
			"nombre": "Sector Scarus",
			"lado_grieta": "nihilus",
			"amenaza_mod": 55,
			"warp_mod": -15,
			"subsectores": ["Angelus", "Helican", "Ophidian"],
		},
		"agrippan": {
			"nombre": "Sector Agrippan",
			"lado_grieta": "nihilus",
			"amenaza_mod": 60,
			"warp_mod": -20,
			"subsectores": ["Fenris Reach", "Mordian Gate", "Vostroyan Expanse"],
		},
	},
	# === SEGMENTUM ULTIMA (el más grande) ===
	"ultima": {
		"ultramar": {
			"nombre": "Sector Ultramar",
			"lado_grieta": "sanctus",
			"amenaza_mod": 35,
			"warp_mod": 10,
			"map_pos": [120.0, 0.68],
			"subsectores": ["Macragge", "Espandor Reach", "Konor", "Tarsis", "Iax"],
		},
		"korianis": {
			"nombre": "Sector Korianis",
			"lado_grieta": "nihilus",
			"amenaza_mod": 50,
			"warp_mod": -15,
			"map_pos": [55.0, 0.48],
			"subsectores": ["Korianis Prime", "Lorn Expanse", "Aurelian", "Lithesh Reach"],
		},
		"octarius": {
			"nombre": "Sector Octarius",
			"lado_grieta": "nihilus",
			"amenaza_mod": 75,
			"warp_mod": -10,
			"map_pos": [135.0, 0.42],
			"subsectores": ["Octarius Core", "War Zone Periphery", "Grendel Stars"],
		},
		"damocles": {
			"nombre": "Sector Damocles",
			"lado_grieta": "sanctus",
			"amenaza_mod": 40,
			"warp_mod": 0,
			"map_pos": [90.0, 0.72],
			"subsectores": ["Damocles Gulf", "Dal'yth Reach", "Perdus Rift", "Baal Reach"],
		},
		"jericho_reach": {
			"nombre": "Sector Jericho Reach",
			"lado_grieta": "nihilus",
			"amenaza_mod": 70,
			"warp_mod": -20,
			"map_pos": [92.0, 0.88],
			"subsectores": ["Hadex Anomaly", "Canis Salient", "Acheros Salient", "Orpheus Salient"],
		},
		"eastern_fringe": {
			"nombre": "Sector Eastern Fringe",
			"lado_grieta": "sanctus",
			"amenaza_mod": 55,
			"warp_mod": -5,
			"map_pos": [105.0, 0.78],
			"subsectores": ["Kar Duniash", "Ichar Reach", "Thandros", "Valedor Drift", "Solemnus Gate"],
		},
		"charadon": {
			"nombre": "Sector Charadon",
			"lado_grieta": "sanctus",
			"amenaza_mod": 65,
			"warp_mod": -10,
			"map_pos": [148.0, 0.35],
			"subsectores": ["Charadon Prime", "Metalica Approach", "Ryza Corridor", "Infernus Gate"],
		},
		"tau_sept": {
			"nombre": "Sector T'au Sept",
			"lado_grieta": "sanctus",
			"amenaza_mod": 45,
			"warp_mod": 0,
			"map_pos": [78.0, 0.84],
			"subsectores": ["Dal'yth Sept", "Vior'la Reach", "Farsight Enclaves", "Startide Nexus"],
		},
		"nephilim": {
			"nombre": "Sector Nephilim",
			"lado_grieta": "nihilus",
			"amenaza_mod": 60,
			"warp_mod": -15,
			"map_pos": [62.0, 0.58],
			"subsectores": ["Nephilim Core", "Pariah Nexus", "Szarekhan Expanse"],
		},
		"ultima_macharia": {
			"nombre": "Sector Ultima Macharia",
			"lado_grieta": "sanctus",
			"amenaza_mod": 40,
			"warp_mod": 5,
			"map_pos": [175.0, 0.55],
			"subsectores": ["Macharia Reach", "Vostok Expanse", "Catachan Deeps", "Meridian Gate"],
		},
	},
	# === SEGMENTUM TEMPESTUS ===
	"tempestus": {
		"bakka": {
			"nombre": "Sector Bakka",
			"lado_grieta": "sanctus",
			"amenaza_mod": 25,
			"warp_mod": 10,
			"subsectores": ["Bakka Prime", "Medean Corridor", "Catachan Reach", "Vigil Ultima"],
		},
		"orpheus": {
			"nombre": "Sector Orpheus",
			"lado_grieta": "nihilus",
			"amenaza_mod": 55,
			"warp_mod": -15,
			"subsectores": ["Orpheus Core", "Amarok", "Bastior Reach"],
		},
		"kaurava": {
			"nombre": "Sector Kaurava",
			"lado_grieta": "sanctus",
			"amenaza_mod": 35,
			"warp_mod": 5,
			"subsectores": ["Kaurava Prime", "Kronus Reach", "Palladian"],
		},
		"krieg": {
			"nombre": "Sector Krieg",
			"lado_grieta": "sanctus",
			"amenaza_mod": 30,
			"warp_mod": 0,
			"subsectores": ["Krieg", "Arethusa Deeps", "Mordant Reach", "Ophelia Cluster"],
		},
	},
	# === SEGMENTUM PACIFICUS ===
	"pacificus": {
		"sabbat_worlds": {
			"nombre": "Sector Sabbat Worlds",
			"lado_grieta": "sanctus",
			"amenaza_mod": 60,
			"warp_mod": -10,
			"subsectores": ["Khan Group", "Cabal Systems", "Urdesh Reach", "Ancreon Sextus"],
		},
		"chiros": {
			"nombre": "Sector Chiros",
			"lado_grieta": "sanctus",
			"amenaza_mod": 30,
			"warp_mod": 5,
			"subsectores": ["Chiros Prime", "Vanity Cluster", "Prosperine"],
		},
		"macharian": {
			"nombre": "Sector Macharian",
			"lado_grieta": "nihilus",
			"amenaza_mod": 50,
			"warp_mod": -10,
			"subsectores": ["Macharius Reach", "Hax Corridor", "Frontier Worlds", "Twilight Gap"],
		},
		"vidar": {
			"nombre": "Sector Vidar",
			"lado_grieta": "sanctus",
			"amenaza_mod": 25,
			"warp_mod": 5,
			"subsectores": ["Vidar Prime", "Thalassos", "Meridian Expanse"],
		},
	},
}
