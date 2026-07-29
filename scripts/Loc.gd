extends Node
## UI text localization (English/Spanish) - GameSettings.language picks which
## one t()/tier_name()/round_name() return. Every menu scene calls these in
## its _ready() (and whenever the language changes) to set Button/Label
## .text/.accessibility_name/.accessibility_description, rather than using
## Godot's TranslationServer/.po pipeline - simpler and consistent with how
## the rest of this project builds UI directly in code.
##
## Real Grand Slam names (Court.tier 7's four tournaments) are deliberately
## NOT translated - "Wimbledon", "Roland Garros" etc. are proper nouns used
## essentially unchanged in Spanish tennis media too, and they're also save-
## file dictionary keys (see CareerData.slam_titles), so translating the
## *display* would risk confusing them with the *identifier*. The fictional
## tiers 1-6 and the round names have no such constraint and are fully
## translated below.

const STRINGS := {
	"main_title_access": {"en": "Echo Padel, main menu", "es": "Echo Padel, menú principal"},
	"difficulty_label": {"en": "Difficulty", "es": "Dificultad"},
	"difficulty_selector_access": {"en": "Difficulty selector", "es": "Selector de dificultad"},
	"difficulty_selector_desc": {"en": "Choose how strong the bot opponent plays: Easy, Medium, Hard, Pro, Elite, or Legendary.",
			"es": "Elige el nivel del rival: Fácil, Medio, Difícil, Profesional, Élite o Legendario."},
	"difficulty_easy": {"en": "Easy", "es": "Fácil"},
	"difficulty_medium": {"en": "Medium", "es": "Medio"},
	"difficulty_hard": {"en": "Hard", "es": "Difícil"},
	"difficulty_pro": {"en": "Pro", "es": "Profesional"},
	"difficulty_elite": {"en": "Elite", "es": "Élite"},
	"difficulty_legendary": {"en": "Legendary", "es": "Legendario"},
	"play_button": {"en": "Play", "es": "Jugar"},
	"play_desc": {"en": "Start a padel match against the bot at the selected difficulty.",
			"es": "Comienza un partido de pádel contra el rival en la dificultad elegida."},
	"training_button": {"en": "Training", "es": "Entrenamiento"},
	"training_desc": {"en": "Practice reaching the ball and timing your return, with no opponent and no scoring.",
			"es": "Practica llegar a la pelota y calcular el momento de golpear, sin rival ni puntuación."},
	"career_button": {"en": "Career", "es": "Carrera"},
	"career_desc": {"en": "Climb from School League all the way to the Grand Slams, and keep winning as many as you can.",
			"es": "Sube desde la Liga Escolar hasta los Grand Slams, y gana todos los que puedas."},
	"settings_button": {"en": "Settings", "es": "Configuración"},
	"settings_desc": {"en": "Adjust the game's audio volume.", "es": "Ajusta el volumen del juego."},
	"exit_button": {"en": "Exit", "es": "Salir"},
	"exit_desc": {"en": "Quit Echo Padel.", "es": "Salir de Echo Padel."},

	"settings_title": {"en": "Settings", "es": "Configuración"},
	"volume_label": {"en": "Master Volume", "es": "Volumen general"},
	"volume_slider_access": {"en": "Master volume slider", "es": "Control deslizante de volumen"},
	"volume_slider_desc": {"en": "Adjust the overall game volume from 0 to 100 percent.",
			"es": "Ajusta el volumen general del juego de 0 a 100 por ciento."},
	"language_label": {"en": "Language", "es": "Idioma"},
	"language_selector_access": {"en": "Language selector", "es": "Selector de idioma"},
	"language_selector_desc": {"en": "Choose English or Spanish for menus and spoken announcements.",
			"es": "Elige inglés o español para los menús y los anuncios de voz."},
	"lang_english": {"en": "English", "es": "Inglés"},
	"lang_spanish": {"en": "Spanish", "es": "Español"},
	"vibration_label": {"en": "Controller Vibration", "es": "Vibración del mando"},
	"vibration_desc": {"en": "Turn controller rumble on hits, bounces, and point outcomes on or off.",
			"es": "Activa o desactiva la vibración del mando en golpes, botes y resultados de punto."},
	"back_button": {"en": "Back", "es": "Atrás"},
	"back_desc": {"en": "Return to the main menu.", "es": "Volver al menú principal."},

	"career_menu_title": {"en": "New Career", "es": "Nueva carrera"},
	"career_menu_instructions": {"en": "Enter your player name", "es": "Introduce el nombre de tu jugador"},
	"name_input_placeholder": {"en": "Player name", "es": "Nombre del jugador"},
	"name_input_desc": {"en": "Type the name your career will be saved under.",
			"es": "Escribe el nombre con el que se guardará tu carrera."},
	"start_career_button": {"en": "Start Career", "es": "Iniciar carrera"},
	"start_career_desc": {"en": "Begin your career at School League with this name.",
			"es": "Comienza tu carrera en la Liga Escolar con este nombre."},

	"career_hub_title": {"en": "Career", "es": "Carrera"},
	"career_hub_status": {"en": "%s - Current tier: %s", "es": "%s - Nivel actual: %s"},
	"career_hub_unlimited": {"en": "Unlimited tries at School League.",
			"es": "Intentos ilimitados en la Liga Escolar."},
	"career_hub_losses": {"en": "Losses at this tier: %d of %d before you drop a tier.",
			"es": "Derrotas en este nivel: %d de %d antes de bajar de nivel."},
	"enter_tier_button": {"en": "Enter %s", "es": "Entrar en %s"},
	"enter_tier_desc": {"en": "Play through the %s bracket.", "es": "Juega el cuadro de %s."},
	"slam_desc_template": {"en": "Won %d %s so far. Play through this Grand Slam's bracket.",
			"es": "Ganado %d %s hasta ahora. Juega el cuadro de este Grand Slam."},
	"time_singular": {"en": "time", "es": "vez"},
	"time_plural": {"en": "times", "es": "veces"},
	"resume_button": {"en": "Resume %s (%s)", "es": "Reanudar %s (%s)"},
	"resume_desc": {"en": "Continue the tournament you left in progress.",
			"es": "Continúa el torneo que dejaste en progreso."},
	"back_to_menu_button": {"en": "Back to Main Menu", "es": "Volver al menú principal"},
	"reset_career_button": {"en": "Reset Career", "es": "Reiniciar carrera"},
	"reset_career_desc": {"en": "Permanently erase your career progress and start over. Press twice to confirm.",
			"es": "Borra permanentemente el progreso de tu carrera y empieza de nuevo. Pulsa dos veces para confirmar."},
	"reset_confirm_button": {"en": "Press again to confirm reset", "es": "Pulsa de nuevo para confirmar"},

	"upgrades_button": {"en": "Upgrades (%d points available)", "es": "Mejoras (%d puntos disponibles)"},
	"upgrades_desc": {"en": "Spend points earned from love-game wins on your character's strength, IQ, speed, and racket.",
			"es": "Gasta los puntos ganados por juegos a cero en la fuerza, inteligencia, velocidad y raqueta de tu personaje."},
	"upgrades_title": {"en": "Upgrades", "es": "Mejoras"},
	"upgrades_points_label": {"en": "Points available: %d", "es": "Puntos disponibles: %d"},
	"upgrade_stat_strength": {"en": "Strength", "es": "Fuerza"},
	"upgrade_stat_iq": {"en": "IQ", "es": "Inteligencia"},
	"upgrade_stat_speed": {"en": "Speed", "es": "Velocidad"},
	"upgrade_stat_racket": {"en": "Racket", "es": "Raqueta"},
	"upgrade_stat_strength_desc": {"en": "Hit your normal shots harder - tougher for the bot to return.",
			"es": "Golpea tus tiros normales con más fuerza, más difíciles de devolver para el rival."},
	"upgrade_stat_iq_desc": {"en": "Place shaped shots further from the center - harder for the bot to reach in time.",
			"es": "Coloca los tiros con efecto más lejos del centro, más difíciles de alcanzar a tiempo para el rival."},
	"upgrade_stat_speed_desc": {"en": "Move between tiles faster.", "es": "Muévete entre casillas más rápido."},
	"upgrade_stat_racket_desc": {"en": "A bigger sweet spot - more forgiving timing window when you're returning the ball.",
			"es": "Un punto dulce más grande: más margen de tiempo al devolver la pelota."},
	"upgrade_row_button": {"en": "%s: Level %d of %d - Spend 1 point", "es": "%s: Nivel %d de %d - Gastar 1 punto"},
	"upgrade_row_maxed": {"en": "%s: Level %d of %d (maxed)", "es": "%s: Nivel %d de %d (al máximo)"},
	"upgrade_row_no_points": {"en": "%s: Level %d of %d (no points available)", "es": "%s: Nivel %d de %d (sin puntos disponibles)"},
	"upgrade_point_earned_announcement": {"en": "Love game! You earned an upgrade point.",
			"es": "¡Juego a cero! Has ganado un punto de mejora."},

	"check_updates_button": {"en": "Check for Updates", "es": "Buscar actualizaciones"},
	"check_updates_desc": {"en": "Check online for a newer version of Echo Padel.",
			"es": "Busca en línea una versión más reciente de Echo Padel."},
	"update_available_message": {"en": "A new update (version %s) is available. Download and install it now? The game will restart.",
			"es": "Hay una nueva actualización (versión %s) disponible. ¿Descargarla e instalarla ahora? El juego se reiniciará."},
	"update_now_button": {"en": "Update Now", "es": "Actualizar ahora"},
	"not_now_button": {"en": "Not Now", "es": "Ahora no"},
	"ok_button": {"en": "OK", "es": "Aceptar"},
	"update_downloading_message": {"en": "Downloading update... %d percent.", "es": "Descargando actualización... %d por ciento."},
	"update_up_to_date_message": {"en": "You already have the latest version.", "es": "Ya tienes la última versión."},
	"update_check_failed_message": {"en": "Couldn't check for updates. Check your internet connection and try again later.",
			"es": "No se pudo buscar actualizaciones. Comprueba tu conexión a internet e inténtalo más tarde."},
	"update_download_failed_message": {"en": "The update download failed. Please try again later.",
			"es": "No se pudo descargar la actualización. Inténtalo de nuevo más tarde."},

	"help_button": {"en": "Help", "es": "Ayuda"},
	"help_desc": {"en": "A detailed guide to playing Echo Padel.", "es": "Una guía detallada para jugar a Echo Padel."},
	"help_title": {"en": "How to Play Echo Padel", "es": "Cómo jugar a Echo Padel"},

	"help_goal_heading": {"en": "The Goal & Scoring", "es": "El objetivo y la puntuación"},
	"help_goal_body": {"en": "Echo Padel is a padel match played entirely by ear, on a court split by a net. Score points, win games and sets, and win the match - standard tennis-style scoring: Love, 15, 30, 40, deuce and advantage, first to 6 games (win by 2) per set, best of three sets, with a tiebreak at 6 games all.",
			"es": "Echo Padel es un partido de pádel que se juega enteramente de oído, en una pista dividida por una red. Suma puntos, gana juegos y sets, y gana el partido - puntuación estilo tenis: cero, 15, 30, 40, deuce y ventaja, el primero en llegar a 6 juegos (con diferencia de 2) gana el set, al mejor de tres sets, con muerte súbita si el marcador llega a 6 juegos iguales."},

	"help_movement_heading": {"en": "Moving Around the Court", "es": "Moverte por la pista"},
	"help_movement_body": {"en": "Use the arrow keys or WASD (or a controller's left stick) to step around your side of the court, one tile at a time. Your side is a 3 by 2 grid: left, middle, or right, and near the net or near your back wall. You start every point on the front-middle tile. Press C (or click in the right stick) any time to hear your current tile announced - works in every mode, online included.",
			"es": "Usa las flechas o WASD (o el stick izquierdo de un mando) para moverte por tu lado de la pista, una casilla a la vez. Tu lado es una cuadrícula de 3 por 2: izquierda, centro o derecha, y cerca de la red o cerca de tu pared del fondo. Empiezas cada punto en la casilla central de delante. Pulsa C (o pulsa el stick derecho) en cualquier momento para escuchar tu casilla actual - funciona en todos los modos, incluido el modo en línea."},

	"help_hitting_heading": {"en": "Hitting the Ball", "es": "Golpear la pelota"},
	"help_hitting_body": {"en": "Hold Space (or Xbox A / PS5 Cross) to charge a shot - the longer you hold it, the harder you hit. Release to swing. You'll hear the ball's first bounce as a locating cue, then a second bounce shortly after - swing while standing on the correct tile during that second bounce's window to return it. Miss the window, or swing from the wrong tile, and you fault the point.",
			"es": "Mantén pulsado Espacio (o A en Xbox / Cruz en PS5) para cargar un golpe - cuanto más tiempo lo mantengas, más fuerte golpeas. Suelta para golpear. Oirás el primer bote de la pelota como referencia para localizarla, y poco después un segundo bote - golpea mientras estás en la casilla correcta durante la ventana de ese segundo bote para devolverla. Si te pierdes la ventana, o golpeas desde la casilla equivocada, pierdes el punto."},

	"help_smash_heading": {"en": "The Smash", "es": "El remate"},
	"help_smash_body": {"en": "If a shot is mishit - too weak, whether from too little charge or a poor bot swing - it 'dollies' up into a slow, high, easy ball. Only then can you press Enter (or Xbox B / PS5 Circle) for a smash: a separate, dedicated, always-maximum-power blast that's hard - but not impossible - for the other side to return. You can't smash a normal ball, only a dollied one.",
			"es": "Si un golpe sale mal - por poca carga o un mal golpe del rival - la pelota queda 'globeada': lenta, alta y fácil. Solo entonces puedes pulsar Enter (o B en Xbox / Círculo en PS5) para rematar: un golpe aparte, siempre a máxima potencia, difícil - pero no imposible - de devolver para el otro lado. No puedes rematar una pelota normal, solo una globeada."},

	"help_drop_shot_heading": {"en": "The Drop Shot", "es": "El golpe cortado"},
	"help_drop_shot_body": {"en": "Hold Right Shift (or a controller's right trigger) to charge a drop shot - a separate button from the normal swing. Release to hit: no matter which direction you're holding, it always lands short in the front row, right near the net. Barely tap it and you'll likely fault into the net; a slightly longer tap instead dollies up into a weak, easy ball, same as an under-charged normal shot; hold it longer still for a genuine, firm drop shot with its own distinct sound - safer, but easier for the other side to reach in time.",
			"es": "Mantén pulsada la tecla Shift derecha (o el gatillo derecho de un mando) para cargar un golpe cortado - un botón aparte del golpe normal. Suelta para golpear: sin importar qué dirección mantengas pulsada, siempre cae corto, cerca de la red. Si apenas la tocas, es probable que falles a la red; una pulsación un poco más larga en cambio deja una pelota floja y fácil, igual que un golpe normal mal cargado; mantenla pulsada más tiempo para un golpe cortado firme de verdad, con su propio sonido - más seguro, pero más fácil de alcanzar para el otro lado."},

	"help_shaping_heading": {"en": "Shot Shaping & the Wall Bank Shot", "es": "Dar forma al golpe y el golpe de pared"},
	"help_shaping_body": {"en": "Whichever direction you're holding when you release your shot (or press smash) shapes it: Left or Right curves it that way, Back plays it off your own back wall first - carrying forward over the net, the real padel bank shot - and Forward drops it short near the net. Hold nothing for a flat, straight shot. On a controller, shot shaping uses the right stick instead, independent of the left stick's movement.",
			"es": "La dirección que mantengas pulsada al soltar tu golpe (o al rematar) le da forma: izquierda o derecha lo curva hacia ese lado, atrás lo juega primero contra tu propia pared del fondo - llevándolo hacia adelante por encima de la red, el golpe de pared real del pádel - y adelante lo deja corto cerca de la red. No mantengas nada pulsado para un golpe plano y directo. Con un mando, dar forma al golpe usa el stick derecho en su lugar, independiente del movimiento del stick izquierdo."},

	"help_sounds_heading": {"en": "Sounds to Listen For", "es": "Sonidos que debes escuchar"},
	"help_sounds_body": {"en": "The soundscape is kept deliberately simple. You'll hear: your own racket hitting the ball; two bounces on your own side (the second one louder - that's your deadline to react); your opponent hitting the ball, and their bounce - both slightly muffled and quieter, so you can always tell whose side a sound is on; a chime and prompt before every serve; cheering when you win a point, booing when your opponent does; and distinct sounds for a smash, a mishit, a drop shot, a shot into the net, and a sharp glass-like crack when a ball banks off the back wall.",
			"es": "El sonido se mantiene deliberadamente sencillo. Oirás: tu propia raqueta golpeando la pelota; dos botes en tu propio lado (el segundo más fuerte, esa es tu límite para reaccionar); a tu rival golpeando la pelota, y su bote - ambos un poco más apagados y silenciosos, para que siempre sepas de qué lado viene un sonido; un timbre y un aviso antes de cada saque; ánimos cuando ganas un punto, abucheos cuando lo gana tu rival; y sonidos distintos para un remate, un golpe fallido, un golpe cortado, un golpe a la red y un chasquido de cristal cuando la pelota rebota en la pared del fondo."},

	"help_serving_heading": {"en": "Serving & the Ready Prompt", "es": "Sacar y el aviso de listo"},
	"help_serving_body": {"en": "Before every serve, you'll hear a chime and be asked if you're ready - press Enter (or Xbox B / PS5 Circle) when you are. This stops the next ball from arriving while you're still listening to the score.",
			"es": "Antes de cada saque, oirás un timbre y se te preguntará si estás listo - pulsa Enter (o B en Xbox / Círculo en PS5) cuando lo estés. Esto evita que la siguiente pelota llegue mientras todavía estás escuchando el marcador."},

	"help_training_heading": {"en": "Training Mode", "es": "Modo Entrenamiento"},
	"help_training_body": {"en": "Training mode serves you a steady stream of balls to random tiles on your own side, with no opponent and no scoring - just practice reaching the right tile and timing your return. It tracks your current and best streak.",
			"es": "El modo Entrenamiento te envía un flujo constante de pelotas a casillas aleatorias de tu lado, sin rival ni puntuación - solo practica llegar a la casilla correcta y calcular el momento de devolver. Lleva la cuenta de tu racha actual y tu mejor racha."},

	"help_career_heading": {"en": "Career Mode & Upgrades", "es": "Modo Carrera y mejoras"},
	"help_career_body": {"en": "Start a career, name your player, and climb from School League all the way to the Grand Slams and beyond, to the Hall of Champions. Each tournament is a multi-round bracket - lose a round and you're out of that tournament, though you keep your tier. Three tournament losses at the same tier demotes you one tier down (School League has unlimited tries). Win a love game - a game where your opponent doesn't score a single point - and you earn an upgrade point, spendable from the Career Hub's Upgrades screen on your character's Strength (harder normal shots), IQ (shaped shots placed further from center), Speed (faster movement between tiles), and Racket (a more forgiving hit timing window).",
			"es": "Inicia una carrera, ponle nombre a tu jugador, y sube desde la Liga Escolar hasta los Grand Slams y más allá, hasta el Salón de Campeones. Cada torneo es un cuadro de varias rondas - pierde una ronda y quedas fuera de ese torneo, aunque conservas tu nivel. Tres derrotas en torneos del mismo nivel te bajan un nivel (la Liga Escolar tiene intentos ilimitados). Gana un juego a cero - un juego en el que tu rival no anota ni un punto - y ganas un punto de mejora, que puedes gastar desde la pantalla de Mejoras del Centro de Carrera en la Fuerza de tu personaje (golpes normales más fuertes), Inteligencia (golpes con efecto colocados más lejos del centro), Velocidad (te mueves más rápido entre casillas) y Raqueta (una ventana de tiempo más generosa al golpear)."},

	"help_online_extras_heading": {"en": "Online Coins & Emotes", "es": "Monedas y emotes en línea"},
	"help_online_extras_body": {"en": "Winning an online match earns you coins - 5 for Online Mode, 2 for the faster Quick Online Mode. Spend coins in the Emote Store (from the online menu) on celebration emotes - short music clips; press Tab (or a controller's left trigger) on an emote there to preview how it sounds before buying. During an online match, hold Left Shift (or a controller's left bumper) to open your emote menu. On keyboard, use Down to pick one you own and Enter to play it; on a controller, the left and right bumpers cycle between them instead, and A (or Cross on PS5) plays the highlighted one. Your opponent hears it too, and so do you.",
			"es": "Ganar un partido en línea te da monedas - 5 en Modo en línea, 2 en el Modo rápido en línea, más rápido. Gástalas en la Tienda de emotes (desde el menú en línea) en emotes de celebración - clips musicales cortos; pulsa Tab (o el gatillo izquierdo de un mando) sobre un emote ahí para escuchar cómo suena antes de comprarlo. Durante un partido en línea, mantén pulsada la tecla Shift izquierda (o el gatillo izquierdo de un mando) para abrir tu menú de emotes. Con teclado, usa Abajo para elegir uno que tengas y Enter para reproducirlo; con un mando, los gatillos izquierdo y derecho los recorren en su lugar, y A (o Cruz en PS5) reproduce el que esté resaltado. Tu rival también lo escuchará, y tú también."},

	"help_settings_heading": {"en": "Settings", "es": "Configuración"},
	"help_settings_body": {"en": "Adjust the master volume and switch between English and Spanish menus and voice from the Settings screen, reachable from the main menu.",
			"es": "Ajusta el volumen general y cambia entre menús y voz en inglés o español desde la pantalla de Configuración, accesible desde el menú principal."},

	"version_label_access": {"en": "Version %s", "es": "Versión %s"},
	"play_online_button": {"en": "Play Online (LAN)", "es": "Jugar en línea (red local)"},
	"play_online_desc": {"en": "Play against someone else on the same WiFi or local network - no internet or account needed.",
			"es": "Juega contra otra persona en la misma red WiFi o local. No necesitas internet ni cuenta."},
	"lan_title": {"en": "Play Online (LAN)", "es": "Jugar en línea (red local)"},
	"lan_cancel_desc": {"en": "Cancel and return to the main menu.", "es": "Cancela y vuelve al menú principal."},
	"lan_connected_message": {"en": "Connected to %s. Starting the match.", "es": "Conectado con %s. Comenzando el partido."},
	"lan_failed_message": {"en": "Couldn't connect. Check you're both on the same network and try again.",
			"es": "No se pudo conectar. Comprueba que ambos estén en la misma red e inténtalo de nuevo."},
	"lan_failed_host_message": {"en": "Nobody joined your room in time. Make sure they chose Join Room and typed your room code correctly, then try again.",
			"es": "Nadie se unió a tu sala a tiempo. Asegúrate de que eligieran Unirse a sala y escribieran bien tu código, y vuelve a intentarlo."},
	"lan_failed_join_message": {"en": "Couldn't reach that room. Double-check the room code and that you're both on the same WiFi, then try again.",
			"es": "No se pudo llegar a esa sala. Revisa el código y que ambos estén en la misma WiFi, y vuelve a intentarlo."},
	"lan_invalid_code_message": {"en": "That room code doesn't look right. It should just be the short number the host was given - check with them and try again.",
			"es": "Ese código de sala no parece correcto. Debería ser el número corto que le dieron al anfitrión - confírmalo con él e inténtalo de nuevo."},
	"lan_name_prompt": {"en": "Enter your name. Your opponent will hear it announced during the match.",
			"es": "Escribe tu nombre. Tu rival lo escuchará durante el partido."},
	"lan_name_input_desc": {"en": "Type the name your opponent will hear during the match.",
			"es": "Escribe el nombre que tu rival escuchará durante el partido."},
	"lan_create_button": {"en": "Create Room", "es": "Crear sala"},
	"lan_create_desc": {"en": "Host a room. You'll be given a room code to share with the other player.",
			"es": "Crea una sala. Recibirás un código para compartir con el otro jugador."},
	"lan_join_button": {"en": "Join Room", "es": "Unirse a sala"},
	"lan_join_desc": {"en": "Enter a room code the other player shared with you.",
			"es": "Escribe el código de sala que te compartió el otro jugador."},
	"lan_hosting_message": {"en": "Your room code is %s. Tell the other player to choose Join Room and type that in. Waiting for them to connect.",
			"es": "El código de tu sala es %s. Dile al otro jugador que elija Unirse a sala y lo escriba. Esperando a que se conecte."},
	"lan_hosting_quick_message": {"en": "Your room code is %s. Tell the other player to choose Quick Online Mode, then Join Room, and type that in. Waiting for them to connect.",
			"es": "El código de tu sala es %s. Dile al otro jugador que elija Modo rápido en línea, luego Unirse a sala, y lo escriba. Esperando a que se conecte."},
	"lan_no_address_message": {"en": "Couldn't find a network address on this device. Make sure you're connected to WiFi and try again.",
			"es": "No se encontró una dirección de red en este dispositivo. Comprueba tu conexión WiFi e inténtalo de nuevo."},
	"lan_join_code_prompt": {"en": "Enter the room code the other player gave you.", "es": "Escribe el código de sala que te dio el otro jugador."},
	"lan_room_code_placeholder": {"en": "Room code", "es": "Código de sala"},
	"lan_join_code_input_desc": {"en": "Type the room code the host shared with you, then press Connect.",
			"es": "Escribe el código que te compartió el anfitrión y pulsa Conectar."},
	"lan_connect_button": {"en": "Connect", "es": "Conectar"},
	"lan_connect_desc": {"en": "Connect using the room code you entered.", "es": "Conéctate usando el código que escribiste."},
	"lan_connecting_message": {"en": "Connecting to room %s...", "es": "Conectando a la sala %s..."},
	"lan_still_hosting_message": {"en": "Still waiting for the other player to join your room...", "es": "Todavía esperando a que el otro jugador se una a tu sala..."},
	"lan_still_joining_message": {"en": "Still trying to connect to that room...", "es": "Todavía intentando conectar a esa sala..."},
	"lan_copy_code_button": {"en": "Copy Room Code", "es": "Copiar código de sala"},
	"lan_copy_code_desc": {"en": "Copy the room code to your clipboard so you can paste it into a text or chat message.",
			"es": "Copia el código de sala al portapapeles para pegarlo en un mensaje de texto o chat."},
	"lan_copy_code_confirm": {"en": "Room code %s copied to your clipboard.", "es": "Código de sala %s copiado al portapapeles."},

	"online_mode_select_title": {"en": "Choose Online Mode", "es": "Elige el modo en línea"},
	"online_coin_balance": {"en": "Coins: %d", "es": "Monedas: %d"},
	"online_coin_balance_desc": {"en": "Check your current coin balance, earned from online match wins.",
			"es": "Consulta tu saldo actual de monedas, ganadas en partidos en línea."},
	"online_mode_button": {"en": "Online Mode", "es": "Modo en línea"},
	"online_mode_desc": {"en": "Standard scoring: games and sets, best of three.",
			"es": "Puntuación estándar: juegos y sets, al mejor de tres."},
	"quick_online_mode_button": {"en": "Quick Online Mode", "es": "Modo rápido en línea"},
	"quick_online_mode_desc": {"en": "Fast scoring: first to seven points, win by two, no games or sets.",
			"es": "Puntuación rápida: el primero en llegar a siete puntos, con dos de ventaja, sin juegos ni sets."},

	"store_button": {"en": "Emote Store", "es": "Tienda de emotes"},
	"store_desc": {"en": "Spend coins earned from online wins on celebration emotes.",
			"es": "Gasta las monedas ganadas en línea en emotes de celebración."},
	"store_title": {"en": "Emote Store", "es": "Tienda de emotes"},
	"store_coin_balance": {"en": "You have %d coins.", "es": "Tienes %d monedas."},
	"store_owned_label": {"en": "Owned", "es": "Ya lo tienes"},
	"store_buy_button": {"en": "Buy for %d coins", "es": "Comprar por %d monedas"},
	"store_buy_desc": {"en": "Spend %d coins to unlock this emote. Press Tab, or a controller's left trigger, to preview how it sounds first.",
			"es": "Gasta %d monedas para desbloquear este emote. Pulsa Tab, o el gatillo izquierdo de un mando, para escuchar cómo suena antes."},
	"store_owned_desc": {"en": "Press Tab, or a controller's left trigger, to preview how this emote sounds.",
			"es": "Pulsa Tab, o el gatillo izquierdo de un mando, para escuchar cómo suena este emote."},
	"store_bought_message": {"en": "Bought! You can now play this emote during online matches.",
			"es": "¡Comprado! Ya puedes reproducir este emote en partidos en línea."},
	"store_cant_afford_message": {"en": "Not enough coins yet.", "es": "Todavía no tienes suficientes monedas."},
	"store_earn_hint": {"en": "Win a match in Online Mode for 5 coins, or Quick Online Mode for 2.",
			"es": "Gana un partido en Modo en línea para conseguir 5 monedas, o en Modo rápido en línea para conseguir 2."},

	"emote_afro_pop": {"en": "Afro Pop", "es": "Afro pop"},
	"emote_hip_hop": {"en": "Hip-Hop", "es": "Hip-hop"},
	"emote_eastern_folk_dance": {"en": "Eastern European Folk Dance", "es": "Danza folclórica de Europa del Este"},
	"emote_silly_voice": {"en": "Silly Voice", "es": "Voz graciosa"},
	"emote_uk_drill": {"en": "UK Drill", "es": "UK Drill"},
	"emote_villain_laugh": {"en": "Villain Laugh", "es": "Risa malvada"},
	"emote_chiptune_victory": {"en": "Chiptune Victory", "es": "Victoria chiptune"},
	"emote_airhorn_hype": {"en": "Airhorn Hype", "es": "Bocina de estadio"},
	"emote_latin_party": {"en": "Latin Party", "es": "Fiesta latina"},
	"emote_sad_trombone": {"en": "Sad Trombone", "es": "Trombón triste"},
	"emote_mic_drop": {"en": "Mic Drop", "es": "Suelta el micrófono"},
	"emote_why_so_serious": {"en": "Why So Serious?", "es": "¿Por qué tan serio?"},
	"emote_ping_pong_taunt": {"en": "Ping Pong Taunt", "es": "Burla del ping pong"},
	"emote_game_over_trailer": {"en": "Game Over Trailer", "es": "Tráiler de fin de partida"},
	"emote_too_easy_tease": {"en": "Too Easy", "es": "Demasiado fácil"},
	"emote_champions_taunt": {"en": "Champions Taunt", "es": "Burla de campeones"},

	"emote_menu_title": {"en": "Emotes", "es": "Emotes"},
	"emote_menu_empty": {"en": "You don't own any emotes yet - visit the Emote Store from the main menu.",
			"es": "Todavía no tienes emotes - visita la Tienda de emotes desde el menú principal."},
	"emote_menu_play_desc": {"en": "Play this emote now - your opponent will hear it too.",
			"es": "Reproduce este emote ahora - tu rival también lo escuchará."},
	"emote_celebrates_suffix": {"en": "celebrates!", "es": "¡celebra!"},
}

const TIER_NAMES_ES := [
	"Liga Escolar", "Campeonato Regional", "Campeonato Nacional",
	"Circuito Satélite", "Circuito Challenger", "Circuito Mundial",
]

const ROUND_NAMES_ES := {
	"Round of 32": "Dieciseisavos de Final",
	"Round of 16": "Octavos de Final",
	"Quarterfinal": "Cuartos de Final",
	"Semifinal": "Semifinal",
	"Final": "Final",
}

func t(key: String) -> String:
	var entry: Dictionary = STRINGS.get(key, {})
	if entry.is_empty():
		push_warning("Loc: unknown key '%s'" % key)
		return key
	return entry.get(GameSettings.language, entry.get("en", key))

## tier: 1-6 (School League .. World Tour) and 8 (Hall of Champions) are
## fictional names and get translated below. Tier 7 (Grand Slams) isn't -
## see the class doc comment for why those names stay as-is.
func tier_name(tier: int) -> String:
	var en_name: String = CareerTiers.tier_name(tier)
	if GameSettings.language == "es":
		if tier >= 1 and tier <= TIER_NAMES_ES.size():
			return TIER_NAMES_ES[tier - 1]
		if tier >= CareerTiers.HALL_TIER:
			return "Salón de Campeones"
	return en_name

func round_name(english_round_name: String) -> String:
	if GameSettings.language == "es":
		return ROUND_NAMES_ES.get(english_round_name, english_round_name)
	return english_round_name
