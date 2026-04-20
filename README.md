DOKKAN APPLE

Demo:
https://youtu.be/6lE0jnRl4zQ

Swift Input-Driven Battle Game

Un juego de estrategia por turnos desarrollado en Swift y Xcode 12.4, inspirado en las mecánicas de combate de Dragon Ball Z: Dokkan Battle. El objetivo es sobrevivir a oleadas infinitas de enemigos, gestionando rotaciones de personajes y posicionamiento defensivo.
🎮 Mecánicas de Juego
Gestión de Equipo y Rotación

    Equipo: Formado por 7 unidades únicas.

    Stats por Unidad: Cada personaje cuenta con atributos individuales de:

        ATK (Ataque) y DEF (Defensa).

        Dodge (Evasión), Crit (Crítico) y AA (Ataque Adicional).

    Sistema de Rotación: Solo 3 unidades están activas por turno. El orden se genera al inicio de la partida.

    Previsualización: Puedes ver las próximas 3 unidades en cola mediante un sistema de saturación de color (las unidades activas resaltan, las futuras están sombreadas).

El Turno de Batalla (Input Driven)

El juego se basa en el posicionamiento táctico mediante Drag & Drop:

    Reordenamiento: Puedes arrastrar las 3 unidades activas entre los slots de ataque.

    Estrategia Defensiva: Debes colocar a la unidad con mejor DEF en el slot donde el enemigo concentre sus ataques.

    HP Global: La vida es compartida por todo el equipo. Si llega a 0, la partida termina.

Inteligencia del Enemigo

El enemigo ataca de forma aleatoria en 4 posibles momentos (Slots 0, 1, 2 y 3):

    Slot 0: Antes de que actúe tu primera unidad.

    Slots 1-3: Después de que actúen tus unidades 1, 2 y 3 respectivamente.

    Super Ataque (SA): El enemigo lanzará un SA devastador por turno. Para mantener la intriga y el suspense, la ubicación del SA es oculta hasta que comienza el turno, obligando al jugador a predecir y arriesgar.

📈 Progresión Infinita

Inspirado en el modo "Supervivencia" o "Zombies":

    Dificultad Escalar: Al derrotar a un enemigo, el siguiente aparece con estadísticas aumentadas mediante un multiplicador.

    High Score: El juego registra tu récord de oleadas superadas para fomentar la competitividad.

🔊 Apartado Audiovisual y Feedback

    Banda Sonora: Ambientado con la OST de LR PHY Janemba.

    Feedback de Batalla: El juego incluye una Feed de Batalla detallada que describe cada acción.

    Efectos de Sonido: Audio diferenciado para ataques normales, Super Ataques, esquives y daño recibido para mejorar la inmersión.

🛠️ Especificaciones Técnicas

    Lenguaje: Swift.

    Entorno: Xcode 12.4.

    Arquitectura: Basada en estados para manejar la lógica de turnos y rotaciones.

    Debug Tool: Incluye un botón de Skip funcional para saltar oleadas durante las pruebas de desarrollo.

🚀 Próximas Implementaciones (Roadmap)

    Efectos de Super Ataque: Implementar bufos de estadísticas (ej. "Sube la DEF al atacar") que duren un número determinado de turnos.

    Pasivas de Unidad: Habilidades únicas para cada personaje que se activen al entrar en rotación.

📺 Demostración

Puedes ver el funcionamiento del juego en el siguiente enlace:
Ver Video de Demo en YouTube
