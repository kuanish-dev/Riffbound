import re

LEAD_IN = 2
PRE_ROLL = 0.01
SLOTS = 8
CHORD_ROOTS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
QUALITIES = {"": [0, 4, 7], "m": [0, 3, 7], "5": [0, 7], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10], "dim": [0, 3, 6]}
STYLES = {
    "lesson": {"order": ["a", "a", "a", "fill"], "phrase_crash": True,
        "count": {"hat": "x.x.x.x."},
        "intro": {"kick": "X...X...", "snare": "..X...X.", "hat": "x.x.x.x.", "bass": "X...X...", "guitar": "X.......",
            "strings": "X......."},
        "a": {"kick": "X...X...", "snare": "..X...X.", "hat": "x.x.x.x.", "bass": "X...X...", "guitar": "X...X...",
            "strings": "X...X..."},
        "fill": {"kick": "X...X...", "snare": "..X.X.XX", "hat": "x.x.....", "bass": "X...X...", "guitar": "X...X...",
            "strings": "X...X..."},
        "end": {"kick": "X.......", "crash": "X.......", "bass": "X.......", "guitar": "X.......", "strings": "X......."}},
    "ballad": {"order": ["a", "a", "a", "fill"], "phrase_crash": True,
        "count": {"hat": "x.x.x.x."},
        "intro": {"kick": "X.......", "crash": "X.......", "tom1": "....x.x.", "tom3": ".....x.X", "bass": "X.......",
            "guitar": "X.......", "strings": "X......."},
        "a": {"kick": "X.....x.", "snare": "....X...", "hat": "x.x.x.x.", "bass": "X...x...", "guitar": "X...X...",
            "strings": "X...X..."},
        "fill": {"kick": "X.....x.", "snare": "....X.xx", "hat": "x.x.x...", "tom2": "......x.", "bass": "X...x...",
            "guitar": "X...X...", "strings": "X...X..."},
        "end": {"kick": "X.......", "crash": "X.......", "bass": "X.......", "guitar": "X.......", "strings": "X......."}},
    "ballad_drive": {"order": ["a", "a", "a", "fill"], "phrase_crash": True,
        "count": {"hat": "x.x.x.x."},
        "intro": {"kick": "X..X....", "snare": "....X.xX", "crash": "X.......", "bass": "X..x....", "guitar": "X..x....",
            "strings": "X......."},
        "a": {"kick": "X..X..x.", "snare": "....X...", "hat": "xxxxxxxx", "bass": "X..x..x.", "guitar": "X..x..x.",
            "strings": "X...X..."},
        "fill": {"kick": "X..X....", "snare": "....X.xX", "tom1": ".....x..", "tom3": "......x.", "bass": "X..x....",
            "guitar": "X..x....", "strings": "X...X..."},
        "end": {"kick": "X.......", "crash": "X.......", "bass": "X.......", "guitar": "X.......", "strings": "X......."}},
    "rock": {"order": ["a", "a", "a", "fill"], "phrase_crash": True,
        "count": {"hat": "x.x.x.x."},
        "intro": {"kick": "X...X...", "snare": "..X.X.XX", "crash": "X.......", "bass": "X.......", "guitar": "X.......",
            "strings": "X......."},
        "a": {"kick": "X...X.x.", "snare": "..X...X.", "hat": "xxxxxxxx", "bass": "xxxxxxxx", "guitar": "Xxx.Xxx.",
            "strings": "X...X..."},
        "fill": {"kick": "X...X...", "snare": "..X...xX", "hat": "xxxx....", "tom2": ".....x..", "bass": "xxxxxxxx",
            "guitar": "Xxx.Xxx.", "strings": "X...X..."},
        "end": {"kick": "X.......", "crash": "X.......", "bass": "X.......", "guitar": "X.......", "strings": "X......."}},
    "stabs": {"order": ["a", "a", "b", "b"], "phrase_crash": False,
        "count": {"hat": "x.x.x.x."},
        "intro": {"snare": "..x.xXXX", "kick": "X......."},
        "a": {"kick": ".xxxX...", "snare": ".xxx....", "crash": "....X...", "bass": ".xxxX...", "guitar": ".xxxX...",
            "strings": "....X..."},
        "b": {"kick": "XxxxX.x.", "snare": ".xxx..X.", "crash": "....X...", "hat": "x.....x.", "bass": ".xxxX.x.",
            "guitar": ".xxxX.x.", "strings": "....X..."},
        "end": {"kick": "X.......", "crash": "X.......", "bass": "X.......", "guitar": "X.......", "strings": "X......."}},
    "metal": {"order": ["a", "a", "a", "fill"], "phrase_crash": True,
        "count": {"hat": "x.x.x.x."},
        "intro": {"kick": "xxxxxxxx", "snare": "....XxXX", "crash": "X.......", "bass": "xxxxxxxx", "guitar": "Xxxxxxxx"},
        "a": {"kick": "xxxxxxxx", "snare": "..X...X.", "ride": "x.x.x.x.", "bass": "xxxxxxxx", "guitar": "Xxxxxxxx",
            "strings": "X...X..."},
        "fill": {"kick": "xxxxxxxx", "snare": "..X.XxXX", "tom4": ".....x..", "bass": "xxxxxxxx", "guitar": "Xxxxxxxx",
            "strings": "X...X..."},
        "end": {"kick": "X.......", "crash": "X.......", "china": "X.......", "bass": "X.......", "guitar": "X.......",
            "strings": "X......."}},
}


def bar_count(song: dict) -> int:
    return len(song["tab"] if "tab" in song else song["melody"])


def chord(name: str) -> tuple:
    m = re.fullmatch(r"([A-G])([#b]?)(.*)", name)
    root = (CHORD_ROOTS[m.group(1)] + {"": 0, "#": 1, "b": -1}[m.group(2)]) % 12
    return root, [(root + s) % 12 for s in QUALITIES[m.group(3)]]


def chord_at(spec: str, slot: int) -> tuple:
    parts = spec.split()
    return chord(parts[min(slot * len(parts) // SLOTS, len(parts) - 1)])


def low_note(pc: int, lowest: int) -> int:
    return lowest + (pc - lowest) % 12


def note_midi(name: str) -> int:
    pitch = CHORD_ROOTS[name[0]] + {"": 0, "#": 1, "b": -1}[name[1:-1]]
    return 12 * (int(name[-1]) + 1) + pitch


def plan(song: dict) -> list:
    style = STYLES[song["style"]]
    chords = song["chords"]
    count = bar_count(song)
    bars = []
    for b in range(LEAD_IN + count + 1):
        k = b - LEAD_IN
        if b == 0:
            parts = style["count"]
        elif b == 1:
            parts = style["intro"]
        elif k == count - 1:
            parts = style["end"]
        elif k >= count:
            parts = {}
        else:
            parts = dict(style[style["order"][k % len(style["order"])]])
            if style["phrase_crash"] and k % 4 == 0 and "crash" not in parts:
                parts["crash"] = "X......."
        bars.append((b, parts, chords[min(max(k, 0), count - 1)]))
    return bars


def events(song: dict, part: str) -> list:
    out = []
    for b, parts, spec in plan(song):
        for s, cell in enumerate(parts.get(part, "")):
            if cell != ".":
                out.append({"at": b * SLOTS + s, "cell": cell, "chord": chord_at(spec, s)})
    return out


def ring_until(evs: list, i: int, total: int) -> int:
    return evs[i + 1]["at"] if i + 1 < len(evs) else total
