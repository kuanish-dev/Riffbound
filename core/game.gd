extends Node

var conductor: Conductor
var fretboard: Fretboard
var tuning: Tuning
var looper: Looper
var voices: GuitarVoices
var performance: SongJudge
var style: StyleMeter
var pad: TouchPad
var state := "menu"
var menu_index := 0
var shop_index := 0
var jam_backing := "rock"
var metronome := false
var needs := {"bend": true, "positions": true}
var scroll := {"menu": 0.0, "shop": 0.0}
var more := false
var music := {}
var chords: Array[String] = []
var last_result := {}
var touch := false
