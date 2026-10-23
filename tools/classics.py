#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from classics_data import SONGS

NOTE_NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
ACCIDENTALS = {"": 0, "#": 1, "b": -1}
KEY_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
SCALES = {
    "minor_pentatonic": [0, 3, 5, 7, 10], "blues": [0, 3, 5, 6, 7, 10], "natural_minor": [0, 2, 3, 5, 7, 8, 10],
    "harmonic_minor": [0, 2, 3, 5, 7, 8, 11], "dorian": [0, 2, 3, 5, 7, 9, 10], "major_pentatonic": [0, 2, 4, 7, 9],
    "major": [0, 2, 4, 5, 7, 9, 11], "chromatic": list(range(12)),
}
STRINGS = ["low", "mid", "high"]
BASE_MIDI = 48
NOTES_PER_STRING = 3
FRETS = 4
MIDI_RANGE = (40, 88)
LEAD_IN = 2
LEGATO_STEP = 2
SLOTS = 8


def midi_of(name: str) -> int:
    pitch = NOTE_NAMES[name[0]] + ACCIDENTALS[name[1:-1]]
    return 12 * (int(name[-1]) + 1) + pitch


def degree_of(midi: int, key: int, steps: list) -> int:
    rel = midi - BASE_MIDI - key
    octave, pc = divmod(rel, 12)
    if pc not in steps:
        raise ValueError("нота %d не в гамме" % midi)
    return octave * len(steps) + steps.index(pc)


def midi_at(degree: int, key: int, steps: list) -> int:
    octave, i = divmod(degree, len(steps))
    return BASE_MIDI + key + 12 * octave + steps[i]


def fits(pos: int, key: int, steps: list) -> bool:
    top = NOTES_PER_STRING * (len(STRINGS) - 1) + FRETS - 1
    return all(MIDI_RANGE[0] <= midi_at(NOTES_PER_STRING * pos + d, key, steps) <= MIDI_RANGE[1] for d in range(top + 1))


def notes_of(song: dict) -> list:
    notes = []
    for b, bar in enumerate(song["melody"]):
        cells = bar.split()
        assert len(cells) == SLOTS, (song["id"], b + 1, bar)
        for s, cell in enumerate(cells):
            if cell == "=":
                assert notes, (song["id"], b + 1)
                notes[-1]["len"] += 1
            elif cell != "-":
                notes.append({"bar": b, "slot": s, "midi": midi_of(cell), "len": 1})
    return notes


def tab_of(song: dict) -> list:
    key = KEY_NAMES.index(song["key"])
    steps = SCALES[song["scale"]]
    notes = notes_of(song)
    by_bar = [[n for n in notes if n["bar"] == b] for b in range(len(song["melody"]))]
    positions = plan_positions(song, by_bar, key, steps)
    bars = []
    last = None
    for b, bar_notes in enumerate(by_bar):
        rows = {s: ["-"] * SLOTS for s in STRINGS}
        for n in bar_notes:
            last = place(song, n, positions[b], last, rows, degree_of(n["midi"], key, steps))
        bars.append(bar_of(rows, positions[b]))
    return bars


def plan_positions(song: dict, by_bar: list, key: int, steps: list) -> list:
    allowed = [positions_for(song, b, bar_notes, key, steps) for b, bar_notes in enumerate(by_bar)]
    best = {p: (0, [p]) for p in allowed[0]}
    for options in allowed[1:]:
        best = {p: min((cost + abs(p - q), path + [p]) for q, (cost, path) in best.items()) for p in options}
    return min(best.values())[1]


def positions_for(song: dict, b: int, bar_notes: list, key: int, steps: list) -> list:
    degrees = [degree_of(n["midi"], key, steps) for n in bar_notes]
    span = NOTES_PER_STRING * (len(STRINGS) - 1) + FRETS - 1
    options = [p for p in range(12) if fits(p, key, steps) and (not degrees or (NOTES_PER_STRING * p <= min(degrees)
        and NOTES_PER_STRING * p + span >= max(degrees)))]
    assert options, (song["id"], b + 1, "такт не влезает в позицию")
    return options


def place(song: dict, n: dict, pos: int, last: dict | None, rows: dict, degree: int) -> dict:
    string, fret = string_and_fret(degree - NOTES_PER_STRING * pos, last)
    cell = str(fret + 1)
    if song.get("legato") and is_legato(n, string, pos, last):
        cell = ("h" if n["midi"] > last["midi"] else "p") + cell
    write(rows[STRINGS[string]], n, cell)
    end = n["slot"] + n["len"]
    return {"string": string, "pos": pos, "midi": n["midi"], "end": (n["bar"] + end // SLOTS, end % SLOTS)}


def string_and_fret(rel: int, last: dict | None) -> tuple:
    choices = [(s, rel - NOTES_PER_STRING * s) for s in range(len(STRINGS)) if 0 <= rel - NOTES_PER_STRING * s < FRETS]
    same = [c for c in choices if last is not None and c[0] == last["string"]]
    return same[0] if same else min(choices, key=lambda c: c[1])


def is_legato(n: dict, string: int, pos: int, last: dict | None) -> bool:
    return last is not None and last["string"] == string and last["pos"] == pos and last["end"] == (n["bar"], n["slot"]) \
        and 0 < abs(n["midi"] - last["midi"]) <= LEGATO_STEP


def write(row: list, n: dict, cell: str) -> None:
    row[n["slot"]] = cell
    for k in range(1, n["len"]):
        if n["slot"] + k < SLOTS:
            row[n["slot"] + k] = "="


def bar_of(rows: dict, pos: int) -> dict:
    bar = {s: " ".join(r) for s, r in rows.items() if any(c != "-" for c in r)}
    if pos:
        bar["pos"] = pos
    return bar


def gd_song(song: dict) -> str:
    bars = []
    for bar in tab_of(song):
        parts = (['"pos": %d' % bar["pos"]] if "pos" in bar else []) + \
            ['"%s": "%s"' % (s, bar[s]) for s in STRINGS if s in bar]
        bars.append("\t\t\t{%s}," % ", ".join(parts))
    chords = ", ".join('"%s"' % c for c in song["chords"])
    return ('\t{"id": "%s", "name": "%s", "level": %d, "backing": "%s", "bpm": %.1f, "key": %d, "scale": "%s",\n'
        '\t\t"text": "%s",\n\t\t"chords": [%s],\n\t\t"bars": [\n%s\n\t\t]},') % (
        song["id"], song["name"], song["level"], song["id"], song["bpm"], KEY_NAMES.index(song["key"]),
        song["scale"], song["text"], chords, "\n".join(bars))


def main() -> None:
    if sys.argv[1:2] == ["tabs"]:
        for song in SONGS:
            print(gd_song(song))
    elif sys.argv[1:2] == ["render"]:
        import band
        band.render_all(SONGS, sys.argv[2])
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
