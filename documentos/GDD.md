# Documento de Diseño de Juego (GDD) - Billar 2D

## 1. Visión General
* **Concepto Central:** Un simulador de billar (reglamento oficial de Bola 8) en 2D. Se enfoca en partidas rápidas, físicas de alta precisión y una interfaz competitiva e intuitiva, inspirada en los líderes del mercado.
* **Motor Gráfico:** Godot Engine 4.x (Físicas 2D mediante `RigidBody2D` ajustadas a 240 ticks por segundo para evitar el *tunneling*).
* **Género:** Deportes / Simulación Arcade.
* **Perspectiva:** Cámara ortográfica Top-Down (Cenital), estática sobre la mesa.
* **Tono y Estilo:** Sobrio, realista y competitivo. 

## 2. Core Gameplay Loop
El bucle principal de jugabilidad por turno consta de:
1. **Evaluación (HUD y Mesa):** El jugador analiza la disposición de las bolas, identifica su facción (Lisas o Rayadas) y chequea su tiempo disponible.
2. **Apunte (Asistido):** El jugador utiliza el mouse/táctil para visualizar la trayectoria proyectada mediante un `Line2D`.
3. **Disparo (Drag & Shoot):** El jugador arrastra desde la bola blanca hacia atrás para definir la potencia y suelta para golpear.
4. **Resolución Física:** El motor resuelve los impactos y colisiones.
5. **Evaluación de Reglas (FSM):** La máquina de estados determina si el tiro fue válido, si hay falta, si el jugador mantiene el turno o si cede el control al oponente.

## 3. Modos de Juego y Progresión
### 3.1. Local 1v1 (Hotseat)
* Dos jugadores humanos comparten el dispositivo. 
* El sistema alterna el HUD y bloquea inputs hasta que las bolas se detienen por completo.

### 3.2. Partida Rápida (Vs IA)
* Partidas sueltas contra un oponente controlado por la CPU.
* **Dificultades de IA:**
    * **Fácil:** Alto margen de "ruido" (desviación intencional de grados) en el `RayCast2D` de apunte. No planea la posición residual de la bola blanca.
    * **Medio:** Ruido moderado, apunte directo a troneras evidentes.
    * **Profesional:** Precisión milimétrica. Calcula ángulos de rebote y controla la fuerza para posicionar la blanca de cara al siguiente tiro (control de mesa).

### 3.3. Modo Torneo
* Estructura de llaves (Bracket) de 8 participantes (1 Jugador Humano vs 7 IAs).
* Requiere ganar 3 partidas consecutivas (Cuartos, Semifinal, Final).
* Progreso guardado entre rondas.

## 4. Mecánicas de Control
* **Drag & Shoot:** La interacción principal se realiza directamente sobre la bola blanca. Al hacer clic y arrastrar en dirección opuesta al objetivo, se genera un vector de tensión.
* **Línea de Asistencia:** Una línea predictiva que sale desde la parte frontal de la blanca, calculando el futuro impacto. La longitud de la línea responde proporcionalmente al estiramiento del mouse.
* **Reposicionamiento (Bola en Mano):** Tras una falta, el jugador entrante puede hacer clic sostenido sobre la bola blanca y arrastrarla libremente por la zona válida de la mesa antes de efectuar su tiro.

## 5. Sistema de Turnos y Reglas (Bola 8)
La lógica está gobernada por un `GestorJuego` actuando como Máquina de Estados Finita (FSM).
* **Mesa Abierta:** Al inicio, las facciones no están asignadas. El primero en embocar una bola de color de manera legal reclama esa facción (Lisas o Rayadas).
* **Mantener el Turno:** Se otorga si el jugador emboca al menos una bola de su facción sin cometer faltas.
* **Condiciones de Falta:**
    * Embocar la bola blanca (Scratch).
    * No contactar ninguna bola.
    * Contactar primero una bola del oponente (o la bola 8 si no es la última).
    * *Penalización:* Cambio de turno y "Bola en mano" para el oponente.
* **Temporizador de Turno (Shot Clock):** 
    * Cada jugador tiene un límite de tiempo fijo por turno (ej. 30 segundos).
    * Si el tiempo llega a cero antes de que se ejecute el disparo, se cobra una falta inmediata (Cambio de turno y Bola en mano para el rival).
* **Condiciones de Fin de Partida:**
    * **Victoria:** Limpiar la mesa de la facción propia y embocar la bola 8 limpiamente en un tiro designado.
    * **Derrota (Falta de Bola 8):** Embocar la bola 8 antes de limpiar la mesa, o embocar la bola 8 y la bola blanca en el mismo tiro.

## 6. Interfaz de Usuario (UI) / HUD
La interfaz debe ser mínima sobre la mesa, concentrando la información en los márgenes.
* **Barra Superior (Avatares y Facción):** 
    * Perfiles (Jugador 1 / Jugador 2 o IA).
    * Debajo de cada avatar, 7 espacios (slots) que se irán iluminando a medida que el jugador emboque las bolas de su facción.
* **Indicador de Turno y Tiempo:** 
    * El avatar del jugador activo se resalta.
    * Un marco alrededor del avatar (o una barra horizontal contigua) actúa como barra de progreso que se vacía, indicando el tiempo restante para disparar.
* **Notificaciones Flotantes:** Textos temporales en el centro de la pantalla para comunicar estados críticos ("Mesa Abierta", "¡Falta!", "Bola en Mano", "Victoria").

## 7. Arquitectura Técnica (Godot 4.x)
* **Manejo de Físicas:** Uso intensivo de `_integrate_forces` y `Continuous CD` en las bolas para garantizar respuestas deterministas y evitar *tunneling* a altas velocidades.
* **Detección de Reposo:** El `GestorJuego` transiciona de `BOLAS_EN_MOVIMIENTO` a `ESPERANDO_TIRO` evaluando la propiedad `sleeping` y una velocidad lineal residual (`linear_velocity.length() < 5.0`) de todas las bolas activas.
* **Centralización:** Los nodos tronera (`Area2D`) no aplican lógica de juego; solo reportan colisiones al `GestorJuego` mediante señales (`bola_embolsada`).