## fleet_data.gd - Tipos de naves, plantillas de Battlefleets, nombres
## Para agregar tipo de nave: agregar en SHIP_TYPES
class_name FleetData

const SHIP_TYPES := {
	"battleship": {"nombre": "Battleship", "poder": 100, "blindaje": 90, "velocidad": 20},
	"grand_cruiser": {"nombre": "Grand Cruiser", "poder": 80, "blindaje": 75, "velocidad": 30},
	"cruiser": {"nombre": "Cruiser", "poder": 60, "blindaje": 60, "velocidad": 45},
	"light_cruiser": {"nombre": "Light Cruiser", "poder": 40, "blindaje": 45, "velocidad": 60},
	"frigate": {"nombre": "Frigate", "poder": 20, "blindaje": 30, "velocidad": 75},
	"destroyer": {"nombre": "Destroyer", "poder": 15, "blindaje": 20, "velocidad": 85},
	"transport": {"nombre": "Transport", "poder": 5, "blindaje": 25, "velocidad": 40},
	"battle_barge": {"nombre": "Battle Barge (Astartes)", "poder": 95, "blindaje": 95, "velocidad": 35},
	"strike_cruiser": {"nombre": "Strike Cruiser (Astartes)", "poder": 65, "blindaje": 70, "velocidad": 55},
	"ark_mechanicus": {"nombre": "Ark Mechanicus", "poder": 85, "blindaje": 85, "velocidad": 25},
}

# Plantilla de Battlefleet por tamaño de sector
const BATTLEFLEET_TEMPLATES := {
	"grande": {"naves_capital": [12, 20], "cruceros": [30, 50], "escoltas": [60, 100]},
	"medio": {"naves_capital": [7, 12], "cruceros": [20, 35], "escoltas": [40, 70]},
	"pequeño": {"naves_capital": [5, 8], "cruceros": [15, 25], "escoltas": [30, 50]},
}

# Sectores con Battlefleets grandes (fortalezas de segmentum y fronteras)
const LARGE_FLEET_SECTORS := ["solar", "cadian", "ultramar", "bakka"]

# Nombres de Lord Admirals
const ADMIRAL_NAMES := [
	"Quarren", "Ravenburg", "Spire", "Stryken", "Haldane",
	"Semper", "Calvert", "Mourndark", "Dreyfus", "Hackett",
	"Zhukova", "Thracian", "Korolov", "Stern", "Massimo",
	"Bellerophon", "Artemis", "Castellan", "Ferron", "Basilius",
	"Thalassa", "Vortigern", "Hadrian", "Octavius", "Severus",
]

# Nombres para convoys de transporte
const CONVOY_DESIGNATIONS := [
	"Alpha", "Beta", "Gamma", "Delta", "Epsilon",
	"Zeta", "Eta", "Theta", "Iota", "Kappa",
	"Lambda", "Mu", "Nu", "Xi", "Omicron",
]

# Tipos de ruta warp
const ROUTE_TYPES := {
	"principal": {"factor_speed": 0.7, "factor_safety": 0.8, "color": Color(0.3, 0.6, 0.35, 0.25)},
	"secundaria": {"factor_speed": 1.0, "factor_safety": 1.0, "color": Color(0.5, 0.5, 0.3, 0.2)},
	"menor": {"factor_speed": 1.4, "factor_safety": 1.3, "color": Color(0.5, 0.35, 0.25, 0.15)},
}

# Factor warp por lado de la grieta
const WARP_FACTOR_NIHILUS: float = 1.6 # Viajes en Nihilus son 60% más lentos
const WARP_LOST_CHANCE: float = 0.02
const WARP_LOST_REAPPEAR_MIN: int = 5
const WARP_LOST_REAPPEAR_MAX: int = 20

# Flotas Mechanicus (Explorator)
const MECHANICUS_FLEET_TEMPLATE := {
	"ark_mechanicus": 1,
	"cruisers": [2, 5],
	"escorts": [4, 10],
}

# Flotas enemigas
const ENEMY_FLEET_TYPES := {
	"chaos_warband": {
		"nombre": "Flota del Caos",
		"origen": "eye_of_terror",
		"poder_min": 80, "poder_max": 300,
		"frecuencia": 0.15, # chance por turno de aparecer
	},
	"ork_waaagh": {
		"nombre": "WAAAGH! Fleet",
		"origen": "octarius",
		"poder_min": 50, "poder_max": 200,
		"frecuencia": 0.10,
	},
	"tyranid_tendril": {
		"nombre": "Tendril Tiránido",
		"origen": "eastern_fringe",
		"poder_min": 150, "poder_max": 500,
		"frecuencia": 0.03,
	},
	"dark_eldar_raid": {
		"nombre": "Incursión Drukhari",
		"origen": "webway",
		"poder_min": 30, "poder_max": 100,
		"frecuencia": 0.08,
	},
	"necron_harvest": {
		"nombre": "Flota Cosecha Necrona",
		"origen": "tomb_world",
		"poder_min": 100, "poder_max": 400,
		"frecuencia": 0.02,
	},
}

# Nombres para flotas del Caos
const CHAOS_FLEET_NAMES := [
	"Flota de la Plaga", "Armada de Sangre", "Cruzada Negra",
	"Flota del Cambio", "Armada del Placer", "Horda del Despoiler",
	"Flota Apóstol", "Armada Renegada", "Cruzada Carmesí",
]

# Navegantes (Navis Nobilite)
const NAVIGATOR_HOUSES := [
	"Casa Benetek", "Casa Nostromo", "Casa Yeshar",
	"Casa Mercator", "Casa Ortellius", "Casa Castellan",
	"Casa Vor'cle", "Casa Domus Travellian", "Casa Aleene",
]
