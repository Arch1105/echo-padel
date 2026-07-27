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
	"help_movement_body": {"en": "Use the arrow keys or WASD (or a controller's left stick) to step around your side of the court, one tile at a time. Your side is a 2 by 2 grid: left or right, and near the net or near your back wall.",
			"es": "Usa las flechas o WASD (o el stick izquierdo de un mando) para moverte por tu lado de la pista, una casilla a la vez. Tu lado es una cuadrícula de 2 por 2: izquierda o derecha, y cerca de la red o cerca de tu pared del fondo."},

	"help_hitting_heading": {"en": "Hitting the Ball", "es": "Golpear la pelota"},
	"help_hitting_body": {"en": "Hold Space (or Xbox A / PS5 Cross) to charge a shot - the longer you hold it, the harder you hit. Release to swing. You'll hear the ball's first bounce as a locating cue, then a second bounce shortly after - swing while standing on the correct tile during that second bounce's window to return it. Miss the window, or swing from the wrong tile, and you fault the point.",
			"es": "Mantén pulsado Espacio (o A en Xbox / Cruz en PS5) para cargar un golpe - cuanto más tiempo lo mantengas, más fuerte golpeas. Suelta para golpear. Oirás el primer bote de la pelota como referencia para localizarla, y poco después un segundo bote - golpea mientras estás en la casilla correcta durante la ventana de ese segundo bote para devolverla. Si te pierdes la ventana, o golpeas desde la casilla equivocada, pierdes el punto."},

	"help_smash_heading": {"en": "The Smash", "es": "El remate"},
	"help_smash_body": {"en": "If a shot is mishit - too weak, whether from too little charge or a poor bot swing - it 'dollies' up into a slow, high, easy ball. Only then can you press Enter (or Xbox B / PS5 Circle) for a smash: a separate, dedicated, always-maximum-power blast that's hard - but not impossible - for the other side to return. You can't smash a normal ball, only a dollied one.",
			"es": "Si un golpe sale mal - por poca carga o un mal golpe del rival - la pelota queda 'globeada': lenta, alta y fácil. Solo entonces puedes pulsar Enter (o B en Xbox / Círculo en PS5) para rematar: un golpe aparte, siempre a máxima potencia, difícil - pero no imposible - de devolver para el otro lado. No puedes rematar una pelota normal, solo una globeada."},

	"help_shaping_heading": {"en": "Shot Shaping & the Wall Bank Shot", "es": "Dar forma al golpe y el golpe de pared"},
	"help_shaping_body": {"en": "Whichever direction you're holding when you release your shot (or press smash) shapes it: Left or Right curves it that way, Back plays it off your own back wall first - carrying forward over the net, the real padel bank shot - and Forward drops it short near the net. Hold nothing for a flat, straight shot. On a controller, shot shaping uses the right stick instead, independent of the left stick's movement.",
			"es": "La dirección que mantengas pulsada al soltar tu golpe (o al rematar) le da forma: izquierda o derecha lo curva hacia ese lado, atrás lo juega primero contra tu propia pared del fondo - llevándolo hacia adelante por encima de la red, el golpe de pared real del pádel - y adelante lo deja corto cerca de la red. No mantengas nada pulsado para un golpe plano y directo. Con un mando, dar forma al golpe usa el stick derecho en su lugar, independiente del movimiento del stick izquierdo."},

	"help_sounds_heading": {"en": "Sounds to Listen For", "es": "Sonidos que debes escuchar"},
	"help_sounds_body": {"en": "The soundscape is kept deliberately simple. You'll hear: your own racket hitting the ball; two bounces on your own side (the second one louder - that's your deadline to react); your opponent hitting the ball, and their bounce - both slightly muffled and quieter, so you can always tell whose side a sound is on; a chime and prompt before every serve; cheering when you win a point, booing when your opponent does; and distinct sounds for a smash, a mishit, a shot into the net, and a sharp glass-like crack when a ball banks off the back wall.",
			"es": "El sonido se mantiene deliberadamente sencillo. Oirás: tu propia raqueta golpeando la pelota; dos botes en tu propio lado (el segundo más fuerte, esa es tu límite para reaccionar); a tu rival golpeando la pelota, y su bote - ambos un poco más apagados y silenciosos, para que siempre sepas de qué lado viene un sonido; un timbre y un aviso antes de cada saque; ánimos cuando ganas un punto, abucheos cuando lo gana tu rival; y sonidos distintos para un remate, un golpe fallido, un golpe a la red y un chasquido de cristal cuando la pelota rebota en la pared del fondo."},

	"help_serving_heading": {"en": "Serving & the Ready Prompt", "es": "Sacar y el aviso de listo"},
	"help_serving_body": {"en": "Before every serve, you'll hear a chime and be asked if you're ready - press Enter (or Xbox B / PS5 Circle) when you are. This stops the next ball from arriving while you're still listening to the score.",
			"es": "Antes de cada saque, oirás un timbre y se te preguntará si estás listo - pulsa Enter (o B en Xbox / Círculo en PS5) cuando lo estés. Esto evita que la siguiente pelota llegue mientras todavía estás escuchando el marcador."},

	"help_training_heading": {"en": "Training Mode", "es": "Modo Entrenamiento"},
	"help_training_body": {"en": "Training mode serves you a steady stream of balls to random tiles on your own side, with no opponent and no scoring - just practice reaching the right tile and timing your return. It tracks your current and best streak.",
			"es": "El modo Entrenamiento te envía un flujo constante de pelotas a casillas aleatorias de tu lado, sin rival ni puntuación - solo practica llegar a la casilla correcta y calcular el momento de devolver. Lleva la cuenta de tu racha actual y tu mejor racha."},

	"help_career_heading": {"en": "Career Mode & Upgrades", "es": "Modo Carrera y mejoras"},
	"help_career_body": {"en": "Start a career, name your player, and climb from School League all the way to the Grand Slams and beyond, to the Hall of Champions. Each tournament is a multi-round bracket - lose a round and you're out of that tournament, though you keep your tier. Three tournament losses at the same tier demotes you one tier down (School League has unlimited tries). Win a love game - a game where your opponent doesn't score a single point - and you earn an upgrade point, spendable from the Career Hub's Upgrades screen on your character's Strength (harder normal shots), IQ (shaped shots placed further from center), Speed (faster movement between tiles), and Racket (a more forgiving hit timing window).",
			"es": "Inicia una carrera, ponle nombre a tu jugador, y sube desde la Liga Escolar hasta los Grand Slams y más allá, hasta el Salón de Campeones. Cada torneo es un cuadro de varias rondas - pierde una ronda y quedas fuera de ese torneo, aunque conservas tu nivel. Tres derrotas en torneos del mismo nivel te bajan un nivel (la Liga Escolar tiene intentos ilimitados). Gana un juego a cero - un juego en el que tu rival no anota ni un punto - y ganas un punto de mejora, que puedes gastar desde la pantalla de Mejoras del Centro de Carrera en la Fuerza de tu personaje (golpes normales más fuertes), Inteligencia (golpes con efecto colocados más lejos del centro), Velocidad (te mueves más rápido entre casillas) y Raqueta (una ventana de tiempo más generosa al golpear)."},

	"help_settings_heading": {"en": "Settings", "es": "Configuración"},
	"help_settings_body": {"en": "Adjust the master volume and switch between English and Spanish menus and voice from the Settings screen, reachable from the main menu.",
			"es": "Ajusta el volumen general y cambia entre menús y voz en inglés o español desde la pantalla de Configuración, accesible desde el menú principal."},
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
