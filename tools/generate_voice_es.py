"""Generates spoken Spanish voice-line audio for Echo Padel.

Unlike tools/generate_voice.ps1 (English, via the Windows SAPI voices
already installed on this machine), there's no Spanish SAPI/OneCore voice
installed here to render offline with - so this uses edge-tts instead: a
Python client for Microsoft Edge's "Read Aloud" neural text-to-speech
service (the same engine behind the browser's own accessibility feature).
It needs internet access to run; the output files it produces are then
committed as static assets like everything else, so the game itself never
needs network access at runtime.

Saved directly as mp3 (Godot imports mp3 natively, same as wav - no
conversion needed) to res://audio/voice/es/, mirroring the key set in
tools/generate_voice.ps1's $lines exactly - Voice.gd's PHRASES/LINES for
"es" must stay in sync with these keys.

Run once (or whenever lines change): python tools/generate_voice_es.py
Requires: pip install edge-tts
"""
import asyncio
import os

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "audio", "voice", "es")
VOICE = "es-ES-AlvaroNeural"

LINES = {
	"match_start": "Partido nuevo. Al mejor de tres sets. Tu saque.",
	"quick_match_start": "Partido nuevo. A siete puntos, con dos de ventaja.",
	"wall_match_start": "Partido nuevo. Al mejor de tres sets. Las paredes laterales están en juego - los golpes que saldrían fuera rebotan y siguen en juego. Tu saque.",
	"your_serve": "Tu saque.",
	"bot_serve": "Saca el rival.",
	"out": "Fuera.",
	"into_net": "A la red.",
	"missed": "No devuelta.",
	"point_you": "Punto para ti.",
	"point_bot": "Punto para el rival.",
	"game_you": "Juego para ti.",
	"game_bot": "Juego para el rival.",
	"set_you": "Set para ti.",
	"set_bot": "Set para el rival.",
	"match_point_you": "Punto de partido para ti.",
	"match_point_bot": "Punto de partido para el rival.",
	"set_point_you": "Punto de set para ti.",
	"set_point_bot": "Punto de set para el rival.",
	"you_win_match": "¡Ganas el partido!",
	"bot_wins_match": "El rival gana el partido.",
	"deuce": "Iguales.",
	"advantage_you": "Ventaja para ti.",
	"advantage_bot": "Ventaja para el rival.",
	"love": "Cero.",
	"fifteen": "Quince.",
	"thirty": "Treinta.",
	"forty": "Cuarenta.",
	"all": "Iguales.",
	"score_prefix": "Marcador.",
	"you_prefix": "Tú:",
	"bot_prefix": "Rival:",
	"sets_singular": "set,",
	"sets_plural": "sets,",
	"games_singular": "juego.",
	"games_plural": "juegos.",
	"paused": "Pausado.",
	"resumed": "Reanudado.",
	"training_intro": "Modo entrenamiento. Las pelotas llegan a casillas al azar de tu lado. "
			"Llega a la casilla y pulsa Espacio para devolver. Escape vuelve al menú.",
	"best_streak_prefix": "Mejor racha:",
	"career_round_won": "¡Ronda ganada! Avanzas.",
	"career_round_lost": "Perdiste esta ronda. Torneo terminado.",
	"career_champion": "¡Campeón! ¡Ganaste el torneo!",
	"career_promoted": "¡Subes al siguiente nivel!",
	"career_demoted": "Tres derrotas en este nivel: has bajado de nivel.",
	"career_reset_confirm": "Esto borrará tu carrera de forma permanente. "
			"Pulsa Reiniciar carrera de nuevo antes de cinco segundos para confirmar.",
	"point_prefix": "Punto para",
	"game_prefix": "Juego para",
	"set_prefix": "Set para",
	"match_point_prefix": "Punto de partido para",
	"set_point_prefix": "Punto de set para",
	"advantage_prefix": "Ventaja para",
	"serves_suffix": "saca.",
	"wins_match_suffix": "gana el partido.",
	"ready_prompt": "Pulsa Enter cuando estés listo para sacar.",
	"coord_prefix": "Tu posición:",
	"coord_left": "izquierda,",
	"coord_middle": "centro,",
	"coord_right": "derecha,",
	"coord_front": "adelante.",
	"coord_back": "atrás.",
}

# Career-mode opponent surnames (see OpponentNames.gd's LAST_NAMES - this
# list must stay in sync with that one) - a small, fixed set, so every
# possible opponent name still has full offline clip fallback.
LAST_NAMES = [
	"Carter", "Bennett", "Hayes", "Mercer", "Ellison", "Whitfield", "Sorensen",
	"Delgado", "Kowalski", "Novak", "Fontaine", "Marsh", "Osei", "Larsson",
	"Vance", "Renwick", "Castillo", "Abernathy", "Nakamura", "Petrov",
]
for _name in LAST_NAMES:
	LINES[f"name_{_name.lower()}"] = _name

NUM_WORDS = [
	"cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "diez",
	"once", "doce", "trece", "catorce", "quince", "dieciséis", "diecisiete", "dieciocho",
	"diecinueve", "veinte",
]
for _i, _word in enumerate(NUM_WORDS):
	LINES[f"num_{_i}"] = _word


async def generate() -> None:
	os.makedirs(OUT_DIR, exist_ok=True)
	import edge_tts
	for key, text in LINES.items():
		path = os.path.join(OUT_DIR, f"{key}.mp3")
		communicate = edge_tts.Communicate(text, VOICE)
		await communicate.save(path)
		print(f"wrote {path}")
	print("Done.")


if __name__ == "__main__":
	asyncio.run(generate())
