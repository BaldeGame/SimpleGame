# 001 — Juego independiente para PC

- Estado: base adoptada para el prototipo; revisable con evidencia.
- Plataforma inicial: Windows x86_64.
- Motor: Godot 4.7.2 estable, edición estándar.
- Lenguaje: GDScript.
- Renderizador inicial: Compatibility.

## Motivo

El usuario eligió un juego independiente para PC. Godot permite construir escenas 3D, exportar a Windows y trabajar con una API de multijugador de alto nivel. Empezamos con geometría sencilla y un motor abierto para concentrarnos en las interacciones.

La selección no promete un rendimiento determinado ni elimina el trabajo necesario para un cooperativo estable. Mediremos en dispositivos concretos.

## Primera entrega técnica

Un vestíbulo individual permite caminar, mirar, recoger y devolver paquetes, llamar a puertas y completar tres entregas. Incluye menú, pausa de interacción, sensibilidad y reinicio. No incluye conducción, casa de terror ni red.

Las reglas de entrega están separadas de la escena y del jugador para que se puedan validar y, más adelante, ejecutar desde la autoridad de la partida.

## Cooperativo propuesto

Probar primero dos jugadores con un anfitrión que valide las interacciones. ENet es un candidato para la prueba local. La conexión por internet, servicio de retransmisión, invitaciones y recuperación de sesión siguen pendientes. No se implementa una API de red ficticia antes de probarla.

## Fuentes

- https://godotengine.org/download/windows/
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html
- https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
