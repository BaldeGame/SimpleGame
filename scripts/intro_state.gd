class_name IntroState
extends RefCounted

# Scene code owns movement and distance. These rules own the delivery route.
enum Phase { ARRIVAL, DELIVERIES, LAST_PACKAGE, TO_HOUSE, HOUSE, CAPTURED }

const LAST_PACKAGE: int = 3
const HOUSE_ADDRESS: String = "Casa 17 · Calle del Olmo"
const ORDERS: Array[Dictionary] = [
	{
		"door": "101",
		"item": "Cartas para Clara",
		"message": "Clara · 101: Mis cartas van juntas. Sí, las escribí yo. ¡No te olvides de pasar!",
		"reply": "Clara: Gracias, cariño. Sí, me las escribo yo. Hay cosas que necesito recordar.",
	},
	{
		"door": "102",
		"item": "Regalo para Bruno",
		"message": "Alicia · Para Bruno, 102: Déjale el regalo. Y no le digas que tardé una hora eligiéndolo.",
		"reply": "Bruno: ¿De parte de Alicia? Yo no la soporto... Bueno, déjalo con cuidado. Muy con cuidado.",
	},
	{
		"door": "103",
		"item": "Cena para Tomás",
		"message": "Tomás · 103: Dos cenas, por favor. Que lleguen calientes. La segunda es para mañana.",
		"reply": "Tomás: Gracias. La segunda porción es para mañana. Aquí vivo solo. ¿Quieres propina o un postre?",
	},
]

var phase: Phase = Phase.ARRIVAL
var carried: int = -1
var delivered: Array[int] = []
var trunk_open: bool = false


func arrive_at_building() -> String:
	if phase != Phase.ARRIVAL:
		return "Ya has llegado al edificio."
	phase = Phase.DELIVERIES
	trunk_open = false
	return "Llegaste a casa. Baja y abre el baúl para sacar los encargos."


func toggle_trunk() -> String:
	if phase == Phase.ARRIVAL:
		return "Estaciona junto al edificio antes de abrir el baúl."
	if phase == Phase.CAPTURED:
		return "El carro quedó fuera."
	trunk_open = not trunk_open
	return "Baúl abierto." if trunk_open else "Baúl cerrado."


func take_order(index: int) -> String:
	if phase != Phase.DELIVERIES:
		return "Ahora no quedan encargos de los vecinos por recoger." if is_complete() else "Primero estaciona junto al edificio."
	if index < 0 or index >= ORDERS.size():
		return "Ese encargo no existe."
	if not trunk_open:
		return "Abre el baúl para recoger el encargo."
	if carried != -1:
		return "Ya llevas un encargo. Devuélvelo al baúl antes de recoger otro."
	if delivered.has(index):
		return "Ese encargo ya fue entregado."
	carried = index
	return "Recogido: " + str(ORDERS[index]["item"])


func return_order() -> String:
	if carried == -1:
		return "No llevas ningún encargo."
	if phase not in [Phase.DELIVERIES, Phase.TO_HOUSE]:
		return "Ahora tienes que llevar el paquete hasta la puerta."
	if not trunk_open:
		return "Abre el baúl para devolver el encargo."
	carried = -1
	return "Dejaste el encargo de nuevo en el baúl."


func deliver(door: String) -> String:
	if phase != Phase.DELIVERIES:
		return "El último paquete va a " + HOUSE_ADDRESS + "." if carried == LAST_PACKAGE else "Ahora no tienes entregas pendientes en el edificio."
	if carried < 0 or carried >= ORDERS.size():
		return "Recoge el encargo correspondiente del baúl."
	var order: Dictionary = ORDERS[carried]
	if str(order["door"]) != door:
		return "La etiqueta dice " + str(order["door"]) + ". Esta no es la puerta."
	delivered.append(carried)
	carried = -1
	if is_complete():
		phase = Phase.LAST_PACKAGE
	return str(order["reply"])


func take_last_package() -> String:
	if not is_complete() or phase not in [Phase.LAST_PACKAGE, Phase.TO_HOUSE]:
		return "Termina primero los tres encargos de los vecinos."
	if not trunk_open:
		return "Abre el baúl para revisar el último paquete."
	if carried != -1:
		return "Ya llevas un paquete."
	carried = LAST_PACKAGE
	phase = Phase.TO_HOUSE
	return "Queda una entrega: " + HOUSE_ADDRESS + ". Esa casa lleva años abandonada."


func arrive_at_house() -> String:
	if phase != Phase.TO_HOUSE or carried != LAST_PACKAGE:
		return "Necesitas recoger el último paquete antes de ir a esa dirección."
	phase = Phase.HOUSE
	trunk_open = false
	return "La dirección coincide. La puerta está entreabierta."


func enter_house() -> String:
	if phase != Phase.HOUSE or carried != LAST_PACKAGE:
		return "Sigue la dirección de la última entrega."
	phase = Phase.CAPTURED
	carried = -1
	trunk_open = false
	return "¿Hola? ¿Hay alguien?\n\nLa puerta se cierra detrás de ti. La entrega era para ti."


func is_complete() -> bool:
	return delivered.size() == ORDERS.size()


func objective() -> String:
	match phase:
		Phase.ARRIVAL:
			return "Conduce hasta el edificio y estaciona."
		Phase.DELIVERIES:
			if carried >= 0:
				return "Entrega en el apartamento " + str(ORDERS[carried]["door"]) + " · %d/3 completadas" % delivered.size()
			return "Abre el baúl y recoge los encargos · %d/3 completadas" % delivered.size()
		Phase.LAST_PACKAGE:
			return "Vuelve al carro. Todavía queda un paquete en el baúl."
		Phase.TO_HOUSE:
			if carried == -1:
				return "Recoge el último paquete del baúl antes de salir."
			return "Conduce hasta " + HOUSE_ADDRESS + "."
		Phase.HOUSE:
			return "Acércate a la puerta y entrega el último paquete."
		Phase.CAPTURED:
			return "La entrega era una trampa. Continuará…"
	return ""


func carrying_text() -> String:
	if carried == LAST_PACKAGE:
		return "Paquete sin remitente · " + HOUSE_ADDRESS
	if carried >= 0 and carried < ORDERS.size():
		return str(ORDERS[carried]["item"]) + " · Apartamento " + str(ORDERS[carried]["door"])
	return "Manos libres"


func phone_messages() -> String:
	var messages: PackedStringArray = []
	for index in range(ORDERS.size()):
		var marker := "✓ Entregado\n" if delivered.has(index) else ""
		messages.append(marker + str(ORDERS[index]["message"]))
	if phase >= Phase.LAST_PACKAGE:
		messages.append("Número desconocido: Queda un paquete en el baúl. " + HOUSE_ADDRESS + ". Por favor, entrégalo en persona.")
	return "\n\n".join(messages)
