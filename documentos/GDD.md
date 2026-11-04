# Documento de Diseño de Juego (GDD) - Billar 2D

## 1. Visión General
* **Concepto Central:** Un simulador de billar (reglamento adaptado de Bola 8) en 2D. Se enfoca en partidas rápidas, físicas de alta precisión y una interfaz competitiva e intuitiva, inspirada en los líderes del mercado.
* **Motor Gráfico:** Godot Engine 4.x (Físicas 2D mediante `RigidBody2D` ajustadas a 240 ticks por segundo para evitar el *tunneling*).
* **Género:** Deportes / Simulación Arcade.
* **Perspectiva:** Cámara ortográfica Top-Down (Cenital), estática sobre la mesa.
* **Tono y Estilo:** Sobrio, realista y competitivo.

## 2. Core Gameplay Loop
El bucle principal de jugabilidad por turno consta de:
1. **Evaluación (HUD y Mesa):** El jugador analiza la disposición de las bolas, identifica su facción (Lisas o Rayadas), verifica si tiene "Bola en Mano" o si debe cantar tronera para la Bola 8, y chequea su tiempo disponible.
2. **Fase Pre-Tiro Condicional:**
   * **Bola en Mano (si hubo falta previa):** El jugador posiciona la bola blanca en cualquier punto libre de la mesa sin superponerse con otras bolas, bandas o troneras.
   * **Elección de Tronera (si solo resta la Bola 8):** El jugador hace clic sobre la tronera objetivo, la cual se ilumina en color **verde** para indicar el tiro cantado.
3. **Apunte (Asistido):** El jugador utiliza el mouse/táctil para visualizar la trayectoria proyectada mediante un `Line2D` y detección volumétrica (`ShapeCast` / barrido circular del radio de la bola blanca) hasta el primer punto real de impacto.
4. **Disparo (Drag & Shoot):** El jugador arrastra desde la bola blanca hacia atrás para definir la potencia y suelta para aplicar el impulso central.
5. **Resolución Física:** El motor resuelve los impactos y colisiones a 240 Hz hasta que todas las bolas alcanzan el reposo determinista.
6. **Evaluación de Reglas (FSM):** La máquina de estados evalúa el primer contacto, las bolas embocadas y las faltas para determinar si hay fin de partida, si el jugador mantiene el turno o si cede el control con penalización al oponente.

## 3. Modos de Juego y Progresión
### 3.1. Local 1v1 (Hotseat)
* Dos jugadores humanos comparten el dispositivo.
* El sistema alterna el HUD y bloquea inputs hasta que las bolas se detienen por completo.

### 3.2. Partida Rápida (Vs IA)
* Partidas sueltas contra un oponente controlado por la CPU.
* **Dificultades de IA:**
  * **Fácil:** Alto margen de "ruido" (desviación intencional de grados) en el barrido de apunte. No planea la posición residual de la bola blanca.
  * **Medio:** Ruido moderado, apunte directo a troneras evidentes.
  * **Profesional:** Precisión milimétrica. Calcula ángulos de rebote y controla la fuerza para posicionar la blanca de cara al siguiente tiro (control de mesa).

### 3.3. Modo Torneo
* Estructura de llaves (Bracket) de 8 participantes (1 Jugador Humano vs 7 IAs).
* Requiere ganar 3 partidas consecutivas (Cuartos, Semifinal, Final).
* Progreso guardado entre rondas mediante un Singleton (`Autoload`) de sesión.

## 4. Mecánicas de Control
* **Drag & Shoot:** La interacción principal se realiza con clic izquierdo. Al arrastrar en dirección opuesta al objetivo, se genera un vector de tensión proporcional a la distancia (con un umbral mínimo de cancelación para evitar tiros accidentales).
* **Línea de Asistencia Predictiva:** Una línea que sale desde la bola blanca y se recorta exactamente en el punto de colisión real calculado mediante barrido físico (`cast_motion`) con el radio de la bola blanca.
* **Reposicionamiento (Bola en Mano):**
  * Tras cualquier falta del rival, el jugador activo entra en subestado de colocación.
  * Mueve la bola blanca libremente dentro de los límites internos de la mesa sin empujar físicamente a las demás bolas.
  * El sistema valida mediante consulta espacial (`intersect_shape`) que no exista solapamiento con otras bolas, bandas ni troneras antes de confirmar la posición con clic izquierdo (pudiendo volver a levantarla con clic derecho antes de disparar).
* **Selección de Tronera (Tiro Cantado):**
  * Cuando al jugador activo ya no le quedan bolas de su facción en la mesa, se habilita la selección de troneras.
  * Al hacer clic sobre una tronera, esta se pinta de **verde** (desmarcando cualquier otra previa). No se permite efectuar el disparo a la Bola 8 sin haber seleccionado una tronera.

## 5. Sistema de Turnos y Reglas (Bola 8)
La lógica está gobernada por `GestorJuego` actuando como Máquina de Estados Finita (FSM).

### 5.1. Reglas de Saque Inicial (Break) y Mesa Abierta
* **Saque Inicial:** Es el primer tiro de la partida.
  * **Victoria por Bola 8 en el Saque:** Si el jugador emboca la Bola 8 en el tiro de saque inicial sin cometer falta (sin embocar la blanca), **gana la partida inmediatamente**. Si emboca la Bola 8 y la blanca en el saque, pierde la partida.
* **Mesa Abierta:** Al inicio las facciones no están asignadas. Con la mesa abierta (fuera del saque), es legal golpear primero cualquier bola Lisa o Rayada, pero golpear primero la Bola 8 es falta.
* **Resolución Determinista de Facción (Múltiples Bolas en el Mismo Tiro):**
  * Si en Mesa Abierta se embocan bolas de una sola facción sin cometer falta, se asigna dicha facción al jugador activo.
  * **Caso Borde (Ambas Facciones Embocadas en el Mismo Tiro):** Si caen al menos una Lisa y una Rayada en el mismo tiro sin falta, la facción se asigna según el tipo de la **primera bola contactada** por la bola blanca (evitando depender del orden del árbol de nodos). Si la primera contactada en el saque fue la 8, la mesa permanece abierta y el jugador conserva el turno.

### 5.2. Mantener el Turno y Mesa Cerrada
* En Mesa Cerrada, el jugador mantiene su turno si el tiro es legal (sin faltas) y emboca al menos una bola de su propia facción.
* **Carambola Mixta:** Si el jugador contacta primero una bola de su facción (tiro legal) y en la jugada caen tanto una bola propia como una del rival, no hay falta y el jugador mantiene el turno. Si en cambio solo cae una bola del rival (sin caer ninguna propia), no es falta pero cede el turno normalmente (sin Bola en Mano).

### 5.3. Condiciones de Falta
Se cobra falta (cambio de turno y **Bola en Mano** para el oponente) únicamente bajo las siguientes condiciones:
1. **Scratch:** Embocar la bola blanca.
2. **Sin Contacto:** La bola blanca se detiene sin haber tocado ninguna otra bola durante el tiro.
3. **Primer Contacto Ilegal:**
   * En Mesa Abierta (después del saque): Contactar primero la Bola 8.
   * En Mesa Cerrada: Contactar primero una bola de la facción del oponente, o contactar primero la Bola 8 cuando al jugador aún le quedan bolas de su facción en la mesa.
   * Cuando el jugador ya limpió su facción y tira por la Bola 8: Contactar primero una bola del oponente en lugar de la Bola 8.
4. **Tiempo Agotado (Shot Clock):** No ejecutar el disparo antes de que el reloj de turno (30 segundos) llegue a cero.
*(Nota de diseño: No se exige toque de banda posterior al impacto; basta con que el primer contacto de la bola blanca sea con una bola legal).*

### 5.4. Condiciones de Fin de Partida
* **Victoria:**
  1. Embocar la Bola 8 en el tiro de saque inicial sin cometer falta.
  2. Haber limpiado previamente todas las bolas de la facción propia y, en un tiro posterior, seleccionar una tronera (pintada de verde) y embocar la Bola 8 en dicha tronera designada sin cometer ninguna falta.
* **Derrota:**
  1. Embocar la Bola 8 cuando la mesa sigue abierta (después del saque) o cuando aún restaban bolas de la facción propia al iniciar el tiro (incluso si en el mismo tiro se emboca la última bola propia junto con la 8).
  2. Embocar la Bola 8 cometiendo cualquier falta en el mismo tiro (ej. embocar también la bola blanca o haber tocado primero una bola ilegal).
  3. Embocar la Bola 8 en una tronera distinta a la tronera verde designada.

## 6. Interfaz de Usuario (UI) / HUD
La interfaz debe ser mínima sobre la mesa, concentrando la información en los márgenes.
* **Barra Superior (Avatares y Facción):**
  * Perfiles (Jugador 1 / Jugador 2 o IA).
  * Debajo de cada avatar, 7 espacios (slots) que se irán iluminando a medida que el jugador emboque las bolas de su facción.
* **Indicador de Turno y Tiempo:**
  * El avatar del jugador activo se resalta.
  * Un marco alrededor del avatar (o una barra horizontal contigua) actúa como barra de progreso que se vacía, indicando el tiempo restante para disparar (30s).
* **Indicador de Tronera Cantada:**
  * La tronera elegida para el tiro de la Bola 8 se dibuja con un aro y relleno semitransparente **verde** directamente sobre la mesa.
* **Notificaciones Flotantes:** Textos temporales en el centro de la pantalla para comunicar estados críticos ("Mesa Abierta", "¡Falta!", "Bola en Mano", "Elegí Tronera para la 8", "Victoria").

## 7. Arquitectura Técnica (Godot 4.x)
* **Manejo de Físicas y Prohibición de Teletransporte Directo:**
  * Uso estricto de `_integrate_forces` y `Continuous CD` (`CCD_MODE_CAST_RAY` / `CAST_SHAPE`) en las bolas para garantizar respuestas deterministas y evitar *tunneling* a 240 ticks por segundo.
  * Queda prohibido modificar `global_position` o velocidades de un `RigidBody2D` fuera de `_integrate_forces` sin gestionar su estado `freeze`/`sleeping`.
* **Detección Determinista de Reposo:**
  * `GestorJuego` evalúa el movimiento en `_physics_process` (no en `_process`).
  * Cuando todas las bolas activas permanecen por debajo del umbral de velocidad lineal (`< 5.0 px/s`) durante $N$ ticks físicos consecutivos, se les aplica una parada total forzada (`linear_velocity = Vector2.ZERO`, `angular_velocity = 0.0` vía `_integrate_forces`) antes de evaluar las reglas del turno, evitando que una bola caiga en tronera mientras se procesa el cambio de turno.
* **Monitoreo de Primer Contacto:**
  * La bola blanca activa `contact_monitor = true` y evalúa sus contactos en `_integrate_forces` / `body_entered` para registrar de forma determinista el primer cuerpo `Bola` impactado en cada tiro.
* **Centralización:**
  * Los nodos `Tronera` (`Area2D`) no aplican reglas de juego; gestionan su resaltado visual verde cuando están seleccionados y emiten señales (`bola_embolsada`, `tronera_seleccionada`) hacia `GestorJuego`.
