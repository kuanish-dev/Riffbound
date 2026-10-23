extends Node
## Службы, общие для показа и разработки. Заполняет Main при запуске.

var conductor: Conductor
var fretboard: Fretboard
var tuning: Tuning
var looper: Looper
var voices: GuitarVoices
var performance: SongJudge
var style: StyleMeter
## menu — выбор песни, song — играем песню, results — итог песни, jam — свободная игра, shop — магазин гитар.
var state := "menu"
## Выбранная в меню песня (индекс в Songs.all()).
var menu_index := 0
## Выбранная в магазине гитара (индекс в Shop.SKINS).
var shop_index := 0
## Подложка джема: id стиля Backing.STYLES или трека Tracks.
var jam_backing := "rock"
## Метроном поверх музыки (N) — в песне и в джеме.
var metronome := false
## Какие умения нужны в этой песне (бенд, сдвиг позиции) — лишние кнопки и подсказки прячутся. В джеме — все.
var needs := {"bend": true, "positions": true}
## Прокрутка списков на сенсоре: режим → верхняя видимая строка (листается пальцем).
var scroll := {"menu": 0.0, "shop": 0.0}
## Открыта ли в джеме панель «Ещё» (тон, гамма, метроном, тап-темп, MIDI…).
var more := false
## Что сейчас звучит в джеме: {id, name, kind (style/track), bpm, …} — для показа.
var music := {}
## Итог последней песни: score, stars, accuracy, record.
var last_result := {}
## Сенсорное управление (TouchPad) вместо подсказок клавиш.
var touch := false
