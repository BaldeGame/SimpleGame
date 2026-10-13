class_name DeliveryState
extends RefCounted

# Pure game state: interaction and future network authority share these rules.
const ORDERS: Array[Dictionary] = [
	{"door": "101", "item": "Cartas para Clara", "reply": "Clara: Sí, me las escribo yo. Hay cosas que necesito recordar."},
	{"door": "102", "item": "Regalo para Bruno", "reply": "Bruno: ¿De parte de Alicia? Yo no la soporto... Déjalo con cuidado."},
	{"door": "103", "item": "Cena para Tomás", "reply": "Tomás: La segunda porción es para mañana. Aquí vivo solo."},
]
var carried: int = -1
var delivered: Array[int] = []

func take_order(index: int) -> String:
	if index < 0 or index >= ORDERS.size():
		return "Ese encargo no existe."
	if carried != -1:
		return "Ya llevas un encargo. Devuélvelo al banco con Q."
	if delivered.has(index):
		return "Ese encargo ya fue entregado."
	carried = index
	return "Recogido: " + str(ORDERS[index]["item"])

func return_order() -> String:
	if carried == -1:
		return "No llevas ningún encargo."
	carried = -1
	return "Dejaste el encargo de nuevo en el banco."

func deliver(door: String) -> String:
	if carried == -1:
		return "Primero recoge un encargo del banco."
	var order: Dictionary = ORDERS[carried]
	if order["door"] != door:
		return "La etiqueta dice " + str(order["door"]) + ". Esta no es la puerta."
	delivered.append(carried)
	carried = -1
	return str(order["reply"])

func is_complete() -> bool:
	return delivered.size() == ORDERS.size()
