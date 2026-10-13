# Una entrega más

> Un favor cotidiano. Una última dirección. Alguien lleva tiempo esperando que llegues.

**Terror narrativo en primera persona, con pruebas de supervivencia variables y cooperativo previsto para 1–4 jugadores.**

## Estado del proyecto

Estamos en preproducción con un prólogo individual jugable y la primera prueba de supervivencia, **La presión**. Conducimos por el barrio, estacionamos, abrimos el baúl, consultamos mensajes y entregamos tres encargos. Un último paquete lleva a la casa abandonada; al entrar, la captura conduce a una silla con un mecanismo en marcha.

Los escenarios y el carro utilizan geometría provisional. Los vecinos y el captor se comunican mediante texto; no hay voces grabadas ni personajes animados. Hay una prueba mortal completa y un breve tramo de exploración posterior. El catálogo ampliado de pruebas, el cooperativo y el desarrollo completo de la historia siguen pendientes.

**Plataforma inicial:** PC, Windows x86_64.
**Motor:** Godot 4.7.2 estándar, GDScript y renderizador Compatibility.
La decisión técnica y sus límites están en [docs/decisions/001-pc-godot.md](docs/decisions/001-pc-godot.md).

### Abrir la escena de prueba

1. Descarga [Godot 4.7.2 estándar para Windows](https://github.com/godotengine/godot/releases/tag/4.7.2-stable).
2. Descarga o clona este repositorio.
3. Importa `project.godot` en Godot y pulsa F5. La escena principal es `scenes/intro.tscn`.
4. Pulsa **Comenzar**. Conduce hasta Los Cedros, frena cerca de la zona marcada y pulsa F para bajar.
5. Acércate a la parte trasera del carro, apunta al baúl y pulsa E. Recoge cada encargo y entrégalo en su puerta.
6. Después de las tres entregas, vuelve al baúl y recoge el paquete dirigido a la casa 17. Sube con F, sigue la calle, estaciona frente a la casa y entra. La captura abre **La presión**.
7. También puedes elegir **Probar La presión directamente** en el menú, o ejecutar `scenes/pressure_trial.tscn` con F6 para saltar el prólogo.

La escena anterior, `scenes/delivery_lab.tscn`, se conserva como laboratorio de interacciones y se puede ejecutar con F6.

| Control | Acción |
| --- | --- |
| W / S | Acelerar y reversa en el carro; avanzar y retroceder a pie |
| A / D | Girar en el carro; desplazarse a pie |
| Espacio | Frenar el carro |
| F | Bajar al estacionar o subir cerca del carro con el último paquete |
| Ratón | Mirar |
| E | Abrir/cerrar el baúl, recoger un paquete o llamar/entregar |
| Q | Devolver el encargo cerca del baúl abierto |
| Tab | Abrir/cerrar los mensajes |
| Esc | Abrir o cerrar el menú |

El menú permite ajustar la sensibilidad y el volumen, reiniciar o salir. El teléfono y el menú detienen la conducción. Al cambiar de aplicación se pausa y se libera el cursor. El prólogo incluye una melodía original de radio y ambiente sonoro generado dentro del motor. Es individual y no requiere cuenta ni conexión de red. Todavía no se distribuye un ejecutable exportado.

### La presión: primera prueba

Despertamos sujetos a una silla. Tres ruedas A/B/C cambian los manómetros I/II/III. Cada giro afecta dos valores; los niveles circulan del 0 al 6. La etiqueta del paquete explica las conexiones, el orden de los cierres y el objetivo de cada etapa.

- Apunta a una rueda y pulsa **E** para subir un nivel, o **Q** para bajar.
- Iguala los tres manómetros al objetivo de la etapa y apunta al cierre correcto para accionarlo con **E**.
- **Tab** abre la etiqueta. El tiempo sigue mientras lees; **Esc** abre una pausa completa.
- Un cierre equivocado o mal ajustado aumenta la presión. Girar las ruedas es reversible y no tiene penalización.
- Tienes tres minutos. El tiempo agotado o una presión del 100 % terminan en muerte.
- El control rojo ofrece un escape con lesión, después de confirmar la consecuencia dentro del juego. La lesión reduce la velocidad al caminar en la exploración posterior.
- Resolver los tres cierres libera al jugador sin lesiones. Después se puede leer la libreta de otro repartidor y llegar a la puerta de servicio.
- Tras perder o terminar, puedes repetir la misma configuración, generar otra o volver al barrio.

Las variantes cambian valores iniciales, objetivos y orden de cierres. Todas se generan a partir de movimientos alcanzables; no hay configuraciones deliberadamente imposibles. La semilla se conserva al elegir repetir.

El mecanismo y sus consecuencias son una primera versión de las reglas y la presentación. El ritmo y la dificultad necesitan evaluación con jugadores.

### Validación

Con el ejecutable de Godot disponible como `godot` en la terminal, desde la raíz:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/delivery_test.gd
godot --headless --path . --script tests/scene_test.gd
godot --headless --path . --script tests/intro_state_test.gd
godot --headless --path . --script tests/intro_scene_test.gd
godot --headless --path . --script tests/car_test.gd
godot --headless --path . --script tests/pressure_state_test.gd
godot --headless --path . --script tests/pressure_scene_test.gd
```

Se comprueban las entregas, las interacciones, la progresión del prólogo, la transición al cautiverio, la conducción y los estados de supervivencia. Un solucionador independiente verifica 120 variantes de La presión. Las pruebas no sustituyen las sesiones con jugadores ni certifican rendimiento o multijugador.

**Nombre del juego:** Una entrega más.
**Repositorio actual:** BaldeGame/SimpleGame. El identificador del repositorio se conserva; no es el título del juego.

## La experiencia que queremos crear

Comenzar con una actividad cotidiana, divertida y humana: regresar en carro con las compras y los encargos de nuestros vecinos. Conocer sus costumbres, conversar y descubrir pequeñas historias. Después, una última entrega nos conduce a una casa abandonada y convierte esa rutina en una lucha por sobrevivir.

Priorizamos controles comprensibles, funcionamiento estable, decisiones interesantes y ganas de volver a intentar. La presentación debe servir a la claridad, la atmósfera y el sonido. La dificultad nace de observar, coordinarse y decidir bajo presión.

## Historia e introducción

Nuestro personaje es alguien del barrio que vuelve en carro con encargos para sus vecinos. La radio suena, llegan mensajes y notas de voz, y el baúl está lleno de bolsas y paquetes.

Las primeras tareas permiten conducir, estacionar, consultar direcciones, encontrar los encargos y entregarlos. Hay humor y conversaciones breves: alguien advierte que no aplastemos los huevos; otra persona pide discreción sobre una compra.

En el edificio conocemos a:

- Una señora que se manda cartas a sí misma.
- Dos vecinos que dicen odiarse, pero se envían regalos.
- Alguien que recibe comida para dos, aunque asegura vivir solo.

Estas historias despiertan curiosidad y tendrán respuestas o consecuencias. No todos los comportamientos extraños significan que una persona sea peligrosa.

### La última entrega

Al regresar al carro queda un paquete dirigido a una casa que siempre hemos visto abandonada.

Conducimos hasta allí. La puerta está entreabierta. Tocamos, llamamos y entramos preguntando si hay alguien. Dentro aparece la primera evidencia clara de que algo va mal: por ejemplo, una grabación de nuestras entregas de esa tarde tomada desde un apartamento.

Quien hizo el pedido nos ha atraído hasta la casa. Somos su entretenimiento. La entrega termina en un encierro y despertamos ante la primera prueba.

La puesta en escena exacta de la captura y las grabaciones sigue abierta. Los acontecimientos esenciales son el último encargo, la casa abandonada, la entrada voluntaria y el inicio del cautiverio.

### El captor y el misterio

El captor observa, impone pruebas y reacciona a nuestras decisiones. Su identidad, motivación completa y relación con los vecinos se desarrollarán durante la escritura.

Bolsas, etiquetas, recibos, expedientes y grabaciones conectan las entregas con la casa y otras víctimas. Sobrevivir permite avanzar; investigar permite comprender al captor y preparar una fuga alternativa.

La progresión narrativa debe mantener una lógica consistente aunque cambien los retos y su orden.

## Estructura de una partida

1. **Regreso al barrio:** carro, música, mensajes y encargos.
2. **Entregas:** conversaciones, humor y aprendizaje de las interacciones.
3. **Última dirección:** viaje a la casa abandonada.
4. **Captura:** descubrimiento de la trampa y primera prueba.
5. **Supervivencia:** desafíos, exploración y decisiones con consecuencias.
6. **Desenlace:** fuga o derrota, con pistas sobre lo sucedido.

Después de vivir la introducción, se podrá elegir repetirla o comenzar desde el último encargo.

Como objetivo de diseño, la fase de cautiverio combinará seis pruebas por partida. La cantidad y la duración final se ajustarán con pruebas de juego.

## Pruebas de supervivencia

La referencia creativa es la tensión de Saw: cautiverio, mecanismos amenazantes, tiempo limitado, información incompleta y decisiones desesperadas. Queremos estudiar su catálogo de pruebas para encontrar muchas interacciones diferentes.

El siguiente catálogo propone adaptaciones con reglas propias. No es un inventario exhaustivo de las películas ni contenido ya implementado. Los detalles se describen como mecánicas de videojuego.

| Familia de prueba | Interacción principal | Dificultad |
| --- | --- | --- |
| Dispositivo con cuenta regresiva | El cautivo manipula cierres mientras un compañero busca la combinación. | Reunir información repartida entre perspectivas. |
| Habitación que se comprime | Investigar las salidas y contrastar las instrucciones del captor. | Elegir una solución con espacio y tiempo decrecientes. |
| Cámara inundada | Buscar una salida mientras otro jugador interpreta controles desde fuera. | Visibilidad reducida y coordinación a distancia. |
| Laberinto de vapor | Recorrer una ruta que un compañero modifica desde otro lugar. | Abrir un paso puede bloquear el regreso. |
| Carrusel de rescate | Interrumpir una secuencia mortal y liberar cautivos. | Atender varios rescates y distribuir recursos. |
| Prueba del silencio | Liberar a alguien sin superar un medidor de ruido del juego. | Equilibrar velocidad, precisión y tiempo; no exige micrófono. |
| Cautivos con percepciones distintas | Un jugador interpreta pistas y otro accede a los controles. | Comunicar posiciones y secuencias sin compartir perspectiva. |
| Refugios limitados | Encontrar protección y descubrir cómo compartirla. | Cuestionar una aparente necesidad de abandonar compañeros. |
| Balanza de sacrificio | Ceder recursos para desbloquear una salida. | Asumir consecuencias para las siguientes salas. |
| Rescate encadenado | Mantener controles activos mientras se libera a un cautivo. | Relevar funciones y sincronizar acciones. |
| Silo | Recuperar objetos y localizar la salida mientras cambia el terreno. | Adaptar rutas y prioridades durante la búsqueda. |
| Casa contaminada | Reconstruir mediante pistas la ubicación de un tratamiento. | Decidir cuándo dividir al grupo y cuándo permanecer juntos. |

### Reglas de diseño

- Las acciones importantes tienen señales que permiten anticipar sus efectos.
- Las mentiras del captor se pueden descubrir mediante evidencias.
- Las pruebas tienen soluciones verificables: la aleatoriedad no puede producir combinaciones imposibles.
- Conocer una familia de prueba ayuda, pero cada variante requiere observar.
- Las lesiones, los objetos gastados y los rescates pueden afectar salas posteriores.
- El espectáculo y las consecuencias deben acompañar decisiones jugables.
- Morir debe permitir comprender qué falló. Los reintentos evitan repetir esperas innecesarias.
- La dificultad se valida con jugadores; no se asume que un temporizador corto vuelve interesante una prueba.

## Variación entre partidas

La propuesta combina salas diseñadas a mano con variaciones controladas:

- **Selección y orden:** diferentes conjuntos de pruebas y rutas compatibles con la historia.
- **Papeles:** cambia quién queda atrapado, quién observa y quién interviene.
- **Lógica:** cambian las relaciones entre pistas y controles, no solamente un código numérico.
- **Recursos:** herramientas y decisiones anteriores afectan las opciones disponibles.
- **Conexiones:** rescatar a alguien puede aportar información útil para otra sala.
- **Exploración:** rutas opcionales permiten investigar al captor y preparar otra salida.

Cada variante necesita validación de resolución para la cantidad de jugadores presente. El catálogo se ampliará solo cuando las pruebas existentes sean distintas, comprensibles y estables.

## Cooperativo y modo individual

**Objetivo:** 1–4 jugadores. El cooperativo forma parte del diseño desde el inicio; todavía no está implementado.

En la introducción, el grupo llega junto en el carro: uno conduce, otro consulta las direcciones y todos pueden ayudar con los encargos. Durante el cautiverio, las pruebas reparten información y funciones entre participantes.

- Comunicación por señales y texto; el micrófono será opcional.
- Separaciones temporales y tareas simultáneas para generar dependencia real.
- Adaptación explícita al modo individual: las tareas simultáneas se convierten en secuencias resolubles.
- Recuperación ante desconexiones para evitar bloqueos.
- Posible ayuda limitada desde cámaras para jugadores muertos; esta solución se debe probar.
- La dificultad no debe depender de que todos sean expertos ni de que alguien sabotee al grupo.

El captor controlado por otro jugador no forma parte del alcance inicial.

## Presentación, accesibilidad y calidad

- Primera persona, con escenarios de alcance contenido.
- Contraste entre un barrio cotidiano y una casa opresiva.
- Sonido y señales claras para orientar, anticipar peligros y construir tensión.
- Subtítulos, texto legible y controles configurables como objetivos.
- Información importante comunicada por más de un canal, evitando depender solo del color o del sonido.
- Efectos y movimiento de cámara ajustables.
- Opciones de dificultad que mantengan las decisiones y ajusten la presión.
- Dispositivos y objetivos de rendimiento por definir antes de prometer compatibilidad.
- Pruebas completas de inicio, victoria, derrota, reintento y, cuando corresponda, reconexión.

El deseo de que sea fácil de controlar no elimina la dificultad de sus desafíos. El contenido de terror tampoco implica que se dirija a todas las edades.

## Qué debemos construir primero

### 1. Definir la base del prototipo

Base elegida: Windows y Godot 4.7.2. El vestíbulo, el prólogo y La presión ya permiten verificar la secuencia individual hasta la primera supervivencia o muerte. El siguiente paso es evaluar claridad y tensión con jugadores y validar una conexión cooperativa entre dos participantes.

### 2. Crear una secuencia completa de principio a fin

Construir con geometría y recursos provisionales:

- Un recorrido corto en carro.
- Un edificio con tres entregas que establezcan el tono y enseñen controles.
- El último paquete y el trayecto hasta la casa.
- La entrada, la captura y una primera prueba completa.
- Victoria, derrota y reinicio.

La primera prueba propuesta es **cautivos con percepciones distintas**: permite comprobar información separada y coordinación. Tendrá una variante individual. La meta inicial es poder jugar la secuencia completa, no producir todos los escenarios.

### 3. Comprobar el cooperativo pronto

Validar con dos jugadores la sincronización de objetos, controles, temporizadores, captura y resolución. Probar desconexiones y la reasignación de funciones antes de ampliar a cuatro participantes.

### 4. Completar tres pruebas diferentes

Añadir una prueba de recorrido y otra de recursos o rescate, conectadas por exploración y consecuencias. Comprobar que cada una exige habilidades distintas.

### 5. Incorporar variación y ampliar el catálogo

Introducir selección de salas, variantes resolubles y progresión narrativa. Ampliar las pruebas y el contenido solo después de verificar la experiencia completa.

## Criterios del primer prototipo

- Una persona nueva puede entender los controles y completar una entrega sin ayuda externa.
- La introducción establece personajes y una rutina que resulta agradable.
- El cambio hacia el terror se entiende y está conectado con el último pedido.
- La prueba tiene condiciones claras de éxito y fracaso.
- Es posible completar la secuencia y volver a intentarla sin bloqueos.
- En cooperativo, ambos jugadores contribuyen y observan un estado coherente.
- El modo individual dispone de una solución propia.
- Los jugadores pueden explicar por qué fallaron y qué quieren intentar después.
- La evaluación recoge disfrute, tensión, claridad y problemas de uso; no solo errores técnicos.

## Decisiones pendientes

- Posible adaptación a otras plataformas después de Windows.
- Sistema de conexión y alojamiento de partidas.
- Dirección artística y alcance del sonido.
- Historia completa del captor, vecinos y víctimas.
- Persistencia entre intentos, desenlaces y duración de las partidas.
- Reglas finales de lesiones, muerte y participación tras morir.
- Inventario ampliado de referencias y selección de nuevas pruebas.

---

**Prioridad inmediata:** una secuencia breve y jugable que empiece con encargos cotidianos y termine en una prueba de supervivencia. Ese contraste es la identidad de Una entrega más.

