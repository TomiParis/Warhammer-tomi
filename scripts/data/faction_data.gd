## faction_data.gd - Definiciones de facciones y relaciones imperiales
## Para agregar facción: agregar entrada en FACTIONS y RELATIONS
class_name FactionData

# Tipos de controlador posibles
const CONTROLLER_TYPES := [
	"gobernador_planetario", "adeptus_mechanicus", "ecclesiarquia",
	"adeptus_astartes", "casa_noble", "rogue_trader",
	"adeptus_arbites", "comandante_militar", "ninguno",
	"adeptus_terra", "jefe_tribal", "aristocracia_local", "nobleza_local", "cardenal",
]

# Facciones principales con metadata
const FACTIONS := {
	"gobernador_planetario": {
		"nombre": "Gobernadores Planetarios",
		"icono": "⚜",
		"color": Color(0.6, 0.55, 0.4),
		"descripcion": "Señores feudales del Imperium. Hereditarios o designados.",
	},
	"adeptus_mechanicus": {
		"nombre": "Adeptus Mechanicus",
		"icono": "⚙",
		"color": Color(0.7, 0.3, 0.2),
		"descripcion": "Culto del Omnissiah. Semi-autónomos por el Tratado de Marte.",
	},
	"ecclesiarquia": {
		"nombre": "Eclesiarquía",
		"icono": "✟",
		"color": Color(0.75, 0.65, 0.3),
		"descripcion": "Iglesia imperial. Controla la fe y las Adepta Sororitas.",
	},
	"cardenal": {
		"nombre": "Eclesiarquía (Cardinal)",
		"icono": "✟",
		"color": Color(0.8, 0.7, 0.35),
		"descripcion": "Sede del poder eclesiástico. Cardinal World.",
	},
	"adeptus_astartes": {
		"nombre": "Adeptus Astartes",
		"icono": "⚔",
		"color": Color(0.3, 0.45, 0.7),
		"descripcion": "Capítulos de Space Marines. Autónomos.",
	},
	"casa_noble": {
		"nombre": "Casas de Caballeros",
		"icono": "♞",
		"color": Color(0.65, 0.6, 0.5),
		"descripcion": "Nobleza feudal con Imperial Knights.",
	},
	"rogue_trader": {
		"nombre": "Rogue Traders",
		"icono": "☸",
		"color": Color(0.55, 0.45, 0.6),
		"descripcion": "Dinastías con Warrant of Trade. Exploradores y mercaderes.",
	},
	"adeptus_arbites": {
		"nombre": "Adeptus Arbites",
		"icono": "⚖",
		"color": Color(0.45, 0.45, 0.5),
		"descripcion": "Ley marcial temporal. Policía interplanetaria.",
	},
	"comandante_militar": {
		"nombre": "Comando Militar",
		"icono": "★",
		"color": Color(0.5, 0.55, 0.45),
		"descripcion": "Control militar directo. Mundos Fortaleza.",
	},
	"adeptus_terra": {
		"nombre": "Adeptus Terra",
		"icono": "☉",
		"color": Color(0.8, 0.7, 0.3),
		"descripcion": "Administración central del Imperium. Terra.",
	},
}

# Relaciones base entre facciones (0-100, 50=neutral)
const BASE_RELATIONS := {
	"gobernador.administratum": 60,
	"gobernador.ecclesiarquia": 50,
	"gobernador.mechanicus": 45,
	"gobernador.astartes": 40,
	"gobernador.rogue_trader": 50,
	"gobernador.inquisicion": 35,
	"ecclesiarquia.mechanicus": 30,
	"ecclesiarquia.inquisicion": 55,
	"ecclesiarquia.astartes": 50,
	"mechanicus.astartes": 60,
	"mechanicus.knight_house": 65,
	"rogue_trader.inquisicion": 25,
	"rogue_trader.navy": 35,
	"astartes.inquisicion": 40,
	"navy.administratum": 55,
}

# Títulos para gobernadores planetarios
const GOVERNOR_TITLES := [
	"Lord Governor", "Hereditary Princeps", "Lord Castellan",
	"Planetary Despot", "High King", "Archon", "Lord Commander",
	"Praefectus", "Overlord", "Magister", "Tribune", "Consul",
	"Dictator", "Palatine", "High Regent", "Seneschal", "Viceroy",
]

# Títulos para Lord Sectors
const LORD_SECTOR_TITLES := [
	"Lord Sector", "Sector Governor", "Lord Commander Sector",
	"High Prefect", "Arch-Governor", "Sector Overlord",
]

# Nombres de dinastías Rogue Trader
const ROGUE_TRADER_DYNASTIES := [
	"Winterscale", "Haarlock", "Chorda", "Bastille", "Saul",
	"Oros", "Zarkovia", "Mervallion", "Drachenstein", "Korvinus",
]

# Knight Houses canónicas
const KNIGHT_HOUSES := [
	{"nombre": "House Terryn", "alianza": "imperialis", "knights_base": 50},
	{"nombre": "House Griffith", "alianza": "imperialis", "knights_base": 40},
	{"nombre": "House Cadmus", "alianza": "imperialis", "knights_base": 35},
	{"nombre": "House Hawkshroud", "alianza": "imperialis", "knights_base": 30},
	{"nombre": "House Raven", "alianza": "mechanicum", "knights_base": 45},
	{"nombre": "House Taranis", "alianza": "mechanicum", "knights_base": 40},
	{"nombre": "House Krast", "alianza": "mechanicum", "knights_base": 35},
	{"nombre": "House Vulker", "alianza": "mechanicum", "knights_base": 30},
]

# Nombres de dinastías para gobernadores
const DYNASTY_NAMES := [
	"Varkus", "Haust", "Meridius", "Korvane", "Severina",
	"Drakhen", "Castella", "Praxus", "Solarus", "Tyrannus",
	"Valdris", "Orphiel", "Kraevon", "Bellona", "Icarion",
	"Corvinus", "Hadrian", "Flavius", "Jovian", "Agrippa",
]

# Órdenes de Sororitas
const SORORITAS_ORDERS := [
	"Order of Our Martyred Lady",
	"Order of the Valorous Heart",
	"Order of the Bloody Rose",
	"Order of the Sacred Rose",
	"Order of the Ebon Chalice",
	"Order of the Argent Shroud",
]

# Nombres de Archmagos para Mechanicus
const ARCHMAGOS_NAMES := [
	"Xerxes-VII", "Kelbor-Hal IX", "Cawl-Secundus", "Vettius-Telok",
	"Koriel-Zeth", "Anvillus-Prime", "Hexatheon-III", "Omega-Primus",
	"Gryphonne-IV", "Metallus-Rex", "Ferrus-Optic", "Cogitus-Alpha",
]
