## military_data.gd - Tipos de unidades, fuerzas especiales, estrategias, nombres
## Para agregar tipo: solo agregar entrada al diccionario
class_name MilitaryData

# IDs por rango
const UNIT_ID_START: int = 500000
const CAMPAIGN_ID_START: int = 600000

# Tipos de unidad operacional
const UNIT_TYPES := {
	"regimiento": {"nombre": "Regimiento", "fuerza_min": 3000, "fuerza_max": 10000, "poder_mult": 1.0},
	"division": {"nombre": "División", "fuerza_min": 30000, "fuerza_max": 50000, "poder_mult": 1.1},
	"cuerpo": {"nombre": "Cuerpo de Ejército", "fuerza_min": 100000, "fuerza_max": 500000, "poder_mult": 1.2},
	"ejercito": {"nombre": "Ejército", "fuerza_min": 1000000, "fuerza_max": 10000000, "poder_mult": 1.3},
	"grupo_ejercitos": {"nombre": "Grupo de Ejércitos", "fuerza_min": 50000000, "fuerza_max": 500000000, "poder_mult": 1.4},
}

# Tipos de arma
const WEAPON_TYPES := {
	"infanteria": {"nombre": "Infantería", "atk_mult": 1.0, "def_mult": 1.0},
	"blindados": {"nombre": "Blindados", "atk_mult": 1.4, "def_mult": 0.8},
	"artilleria": {"nombre": "Artillería", "atk_mult": 1.6, "def_mult": 0.6},
	"aeronautica": {"nombre": "Aeronáutica", "atk_mult": 1.3, "def_mult": 0.7},
}

# Multiplicadores de experiencia
const EXP_MULT := {
	"verde": 0.6,
	"regular": 1.0,
	"veterano": 1.3,
	"elite": 1.6,
}

# Fuerzas especiales (poder equivalente en regimientos)
const SPECIAL_FORCES := {
	"astartes_company": {
		"nombre": "Compañía Astartes",
		"poder_equivalente": 10,
		"moral_base": 95,
		"autosuficiente_turnos": 6,
		"moral_bonus_campana": 15,
	},
	"skitarii_maniple": {
		"nombre": "Maniple Skitarii",
		"poder_equivalente": 3,
		"moral_base": 50,
		"moral_max": 70,
		"regen_fuerza_turno": 0.05,
	},
	"sororitas_preceptory": {
		"nombre": "Preceptoría Sororitas",
		"poder_equivalente": 5,
		"moral_base": 95,
	},
	"knight_lance": {
		"nombre": "Lanza de Knights",
		"poder_equivalente": 8,
		"moral_base": 80,
	},
	"titan_legio": {
		"nombre": "Titan Legio",
		"poder_equivalente": 50,
		"moral_base": 90,
		"catastrofe_si_destruido": true,
	},
}

# Estrategias de campaña
const STRATEGIES := {
	"asalto_frontal": {"nombre": "Asalto Frontal", "atk_mult": 1.3, "def_mult": 0.7, "attrition_mult": 1.4},
	"cerco": {"nombre": "Cerco", "atk_mult": 0.8, "def_mult": 1.2, "attrition_mult": 0.9},
	"defensa_en_profundidad": {"nombre": "Defensa en Profundidad", "atk_mult": 0.6, "def_mult": 1.5, "attrition_mult": 0.7},
	"guerra_de_trincheras": {"nombre": "Guerra de Trincheras", "atk_mult": 0.5, "def_mult": 1.8, "attrition_mult": 0.6},
	"bombardeo_orbital": {"nombre": "Bombardeo Orbital", "atk_mult": 1.5, "def_mult": 0.5, "attrition_mult": 1.2},
	"exterminatus": {"nombre": "Exterminatus", "atk_mult": 99.0, "def_mult": 0.0, "attrition_mult": 0.0},
}

# Tipos de campaña
const CAMPAIGN_TYPES := {
	"defensa_planetaria": {"nombre": "Defensa Planetaria", "frente_inicial": 60},
	"invasion": {"nombre": "Invasión", "frente_inicial": 20},
	"reconquista": {"nombre": "Reconquista", "frente_inicial": 10},
	"cruzada": {"nombre": "Cruzada", "frente_inicial": 30},
	"exterminatus": {"nombre": "Exterminatus", "frente_inicial": 0},
}

# Nombres de regimientos por origen
const REGIMENT_PREFIXES := [
	"1st", "2nd", "3rd", "4th", "5th", "7th", "9th", "12th",
	"18th", "23rd", "42nd", "66th", "88th", "101st", "143rd", "217th",
]

const REGIMENT_SUFFIXES := [
	"Shock Troops", "Infantry", "Armoured", "Drop Troops", "Siege Regiment",
	"Light Infantry", "Heavy Infantry", "Grenadiers", "Lancers",
	"Dragoons", "Rifles", "Fusiliers", "Hussars", "Death Korps",
]

# Nombres de comandantes
const COMMANDER_NAMES := [
	"Coronel Theron", "General Aurelius", "Lord Castellan Varkus",
	"Mariscal Korvane", "Comandante Severus", "General Hadrian",
	"Coronel Octavia", "Lord General Militant Drakhen", "Mariscal Praxus",
	"General Flavius", "Coronel Stern", "Lord Commander Bellona",
]

# Templates narrativos por tipo de enemigo
const BATTLE_NARRATIVES := {
	"chaos": [
		"Los cultistas lanzan un asalto suicida contra las líneas imperiales",
		"Se reportan posesiones demoníacas entre los heridos",
		"Un marine del Caos lidera una carga contra el flanco derecho",
		"Las defensas psíquicas se debilitan — los Librarians contraatacan",
		"Los Capellanes refuerzan la moral ante las visiones del Warp",
	],
	"ork": [
		"Una horda verde masiva carga contra las trincheras",
		"Los Orks traen un Stompa al campo de batalla",
		"El WAAAGH! crece — más Orkos llegan cada día",
		"Los Stormboyz atacan desde el aire sin previo aviso",
		"Los Tankbustas destruyen un Leman Russ con cohetes improvisados",
	],
	"tyranid": [
		"Olas interminables de Hormagaunts desbordan las defensas",
		"Un Hive Tyrant coordina el asalto con precisión alienígena",
		"Las esporas Tiránidas contaminan los suministros de agua",
		"La Sombra en el Warp bloquea las comunicaciones astropáticas",
		"Los Genestealers se infiltran en los túneles subterráneos",
	],
	"rebellion": [
		"Los rebeldes toman el Spaceport provincial",
		"Se reportan deserciones en las PDF locales",
		"La propaganda rebelde se propaga entre los trabajadores",
		"Un líder rebelde carismático unifica las facciones insurgentes",
		"Sabotaje en las líneas de suministro imperiales",
	],
	"genestealer": [
		"El Culto emerge de las profundidades con fuerza inesperada",
		"Híbridos Genestealer se infiltran en el cuartel general",
		"El Patriarca dirige el asalto desde las sombras",
		"Los civiles infectados se levantan contra las PDF",
		"Los Purestrain Genestealers diezman a una compañía entera",
	],
	"necron": [
		"Los guerreros Necrones se levantan donde fueron destruidos",
		"Un Monolito aparece en el centro de la ciudad",
		"Los Destroyers Necrones barren las posiciones de artillería",
		"Los protocolos de reanimación hacen las bajas enemigas temporales",
		"Un Señor Necrón desafía al comandante imperial a duelo",
	],
}

# Regiones ficticias para el mapa del frente
const FRONT_REGIONS := [
	"Spaceport", "Capital", "Zona Industrial", "Zona Norte",
	"Zona Sur", "Tierras Bajas", "Meseta Central", "Cordillera",
]
