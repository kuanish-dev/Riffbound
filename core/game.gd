extends Node
## Службы, общие для показа и разработки. Заполняет Main при запуске.

var conductor: Conductor
var fretboard: Fretboard
var tuning: Tuning
var looper: Looper
var voices: GuitarVoices
var performance: SongJudge
## menu — выбор песни, song — играем песню, results — итог песни, jam — свободная игра.
var state := "menu"
## Выбранная в меню песня (индекс в Songs.all()).
var menu_index := 0
## Подложка джема (Synth.BACKINGS).
var jam_backing := "rock"
## Итог последней песни: score, stars, accuracy, record.
var last_result := {}
## Сенсорное управление (TouchPad) вместо подсказок клавиш.
var touch := false
