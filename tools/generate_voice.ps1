# Generates spoken voice-line WAV assets for Echo Padel (English) using the
# built-in Windows speech synthesizer (System.Speech). No internet or extra
# install needed. Run once (or whenever lines change): powershell -File tools/generate_voice.ps1
# Spanish clips are generated separately by tools/generate_voice_es.py (no
# Spanish SAPI voice is installed on this machine, so those use neural TTS
# via edge-tts instead - see that script for details).

Add-Type -AssemblyName System.Speech

$outDir = Join-Path $PSScriptRoot "..\audio\voice\en"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.Rate = 1
$synth.Volume = 100

$lines = @{
    "match_start"         = "New match. Best of three sets. Your serve."
    "your_serve"          = "Your serve."
    "bot_serve"           = "Bot serves."
    "out"                 = "Out."
    "into_net"            = "Into the net."
    "missed"              = "Not returned."
    "point_you"           = "Point, you."
    "point_bot"           = "Point, bot."
    "game_you"            = "Game, you."
    "game_bot"            = "Game, bot."
    "set_you"             = "Set, you."
    "set_bot"             = "Set, bot."
    "match_point_you"     = "Match point, you."
    "match_point_bot"     = "Match point, bot."
    "set_point_you"       = "Set point, you."
    "set_point_bot"       = "Set point, bot."
    "you_win_match"       = "You win the match!"
    "bot_wins_match"      = "Bot wins the match."
    "deuce"               = "Deuce."
    "advantage_you"       = "Advantage, you."
    "advantage_bot"       = "Advantage, bot."
    "love"                = "Love."
    "fifteen"             = "Fifteen."
    "thirty"              = "Thirty."
    "forty"               = "Forty."
    "all"                 = "All."
    "score_prefix"        = "Score check."
    "you_prefix"          = "You:"
    "bot_prefix"          = "Bot:"
    "sets_singular"       = "set,"
    "sets_plural"         = "sets,"
    "games_singular"      = "game."
    "games_plural"        = "games."
    "paused"              = "Paused."
    "resumed"             = "Resumed."
    "training_intro"      = "Training mode. Balls serve to random tiles on your side. Reach the tile and press Space to return. Escape returns to the menu."
    "best_streak_prefix"  = "Best streak:"
    "career_round_won"    = "Round won! Advancing."
    "career_round_lost"   = "You lost this round. Tournament over."
    "career_champion"     = "Champion! You won the tournament!"
    "career_promoted"     = "You're promoted to the next tier!"
    "career_demoted"      = "Three losses at this tier - you've been dropped down a level."
    "career_reset_confirm" = "This will permanently erase your career. Press Reset Career again within five seconds to confirm."
    "point_prefix"        = "Point,"
    "game_prefix"         = "Game,"
    "set_prefix"          = "Set,"
    "match_point_prefix"  = "Match point,"
    "set_point_prefix"    = "Set point,"
    "advantage_prefix"    = "Advantage,"
    "serves_suffix"       = "serves."
    "wins_match_suffix"   = "wins the match."
    "ready_prompt"        = "Press Enter when ready to serve."
}

for ($i = 0; $i -le 20; $i++) {
    $lines["num_$i"] = "$i"
}

# Career-mode opponent surnames (see OpponentNames.gd's LAST_NAMES - this
# list must stay in sync with that one) - a small, fixed set, so every
# possible opponent name still has full offline clip fallback.
$lastNames = @(
    "Carter", "Bennett", "Hayes", "Mercer", "Ellison", "Whitfield", "Sorensen",
    "Delgado", "Kowalski", "Novak", "Fontaine", "Marsh", "Osei", "Larsson",
    "Vance", "Renwick", "Castillo", "Abernathy", "Nakamura", "Petrov"
)
foreach ($name in $lastNames) {
    $lines["name_$($name.ToLower())"] = $name
}

foreach ($key in $lines.Keys) {
    $path = Join-Path $outDir "$key.wav"
    $synth.SetOutputToWaveFile($path)
    $synth.Speak($lines[$key])
    $synth.SetOutputToDefaultAudioDevice()
    Write-Host "wrote $path"
}

$synth.Dispose()
Write-Host "Done."
