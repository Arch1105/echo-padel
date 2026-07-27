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
	"difficulty_selector_desc": {"en": "Choose how strong the bot opponent plays: Easy, Medium, Hard, or Pro.",
			"es": "Elige el nivel del rival: Fácil, Medio, Difícil o Profesional."},
	"difficulty_easy": {"en": "Easy", "es": "Fácil"},
	"difficulty_medium": {"en": "Medium", "es": "Medio"},
	"difficulty_hard": {"en": "Hard", "es": "Difícil"},
	"difficulty_pro": {"en": "Pro", "es": "Profesional"},
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

## tier: 1-6 (School League .. World Tour). Tier 7 (Grand Slams) isn't
## covered here - see the class doc comment for why those names stay as-is.
func tier_name(tier: int) -> String:
	var en_name: String = CareerTiers.tier_name(tier)
	if GameSettings.language == "es" and tier >= 1 and tier <= TIER_NAMES_ES.size():
		return TIER_NAMES_ES[tier - 1]
	return en_name

func round_name(english_round_name: String) -> String:
	if GameSettings.language == "es":
		return ROUND_NAMES_ES.get(english_round_name, english_round_name)
	return english_round_name
