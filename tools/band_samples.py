from pathlib import Path
import re

import numpy as np
import soundfile as sf

RATE = 44100
NOTE_NAMES = {"c": 0, "db": 1, "d": 2, "eb": 3, "e": 4, "f": 5, "gb": 6, "g": 7, "ab": 8, "a": 9, "bb": 10, "b": 11}
MICS = {"KdrumL": (0.0, 0.9), "KdrumR": (0.0, 0.9), "Snare_top": (0.0, 1.0), "Snare_bottom": (0.0, 0.4),
    "Hihat": (-0.35, 0.6), "Tom1": (-0.45, 0.8), "Tom2": (-0.15, 0.8), "Tom3": (0.15, 0.8), "Tom4": (0.45, 0.8),
    "RideL": (-0.5, 0.4), "RideR": (0.5, 0.4), "OHL": (-0.85, 0.8), "OHR": (0.85, 0.8), "AmbL": (-1.0, 0.45),
    "AmbR": (1.0, 0.45)}


def load(path: Path) -> np.ndarray:
    data, rate = sf.read(path, always_2d=True, dtype="float32")
    assert rate == RATE, path
    return data


class Pitched:

    def __init__(self, files: dict):
        self.files = files
        self.cache = {}
        self.turn = 0

    def note(self, midi: int, layer: str) -> np.ndarray:
        base = min(self.files, key=lambda m: (abs(m - midi), m))
        layers = self.files[base]
        names = layers.get(layer) or layers[sorted(layers)[-1]]
        path = names[self.turn % len(names)]
        self.turn += 1
        if path not in self.cache:
            self.cache[path] = load(path)
        return repitch(self.cache[path], midi - base)


def repitch(x: np.ndarray, semitones: float) -> np.ndarray:
    if semitones == 0:
        return x
    ratio = 2.0 ** (semitones / 12.0)
    pos = np.arange(0, len(x) - 1, ratio)
    i = pos.astype(int)
    frac = (pos - i)[:, None]
    return (x[i] * (1 - frac) + x[i + 1] * frac).astype(np.float32)


def scan(folder: Path, pattern: str, octave_shift: int) -> dict:
    out = {}
    for path in sorted(folder.glob("*.wav")):
        m = re.fullmatch(pattern, path.name)
        if not m:
            continue
        midi = 12 * (int(m.group(2)) + 1 + octave_shift) + NOTE_NAMES[m.group(1).lower()]
        out.setdefault(midi, {}).setdefault(m.group(3), []).append(path)
    return out


class Kit:

    def __init__(self, folder: Path):
        self.folder = folder
        self.hits = {}
        self.cache = {}
        self.turn = {}

    def hit(self, piece: str, velocity: float) -> np.ndarray:
        if piece not in self.hits:
            self.hits[piece] = sorted({int(p.name.split("-")[0]) for p in (self.folder / piece).glob("*.flac")})
        hits = self.hits[piece]
        turn = self.turn.get(piece, 0)
        self.turn[piece] = turn + 1
        top = round(velocity * (len(hits) - 1))
        n = hits[max(0, top - turn % 3)]
        key = (piece, n)
        if key not in self.cache:
            self.cache[key] = self._mix(piece, n)
        return self.cache[key]

    def _mix(self, piece: str, n: int) -> np.ndarray:
        out = None
        for mic, (pan, gain) in MICS.items():
            x = load(self.folder / piece / f"{n}-{piece}-{mic}.flac")[:, 0]
            stereo = np.stack([x * gain * np.sqrt((1 - pan) / 2), x * gain * np.sqrt((1 + pan) / 2)], axis=1)
            out = stereo if out is None else _add(out, stereo)
        return out


def _add(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    if len(b) > len(a):
        a, b = b, a
    a = a.copy()
    a[:len(b)] += b
    return a


def mix_into(out: np.ndarray, at: int, x: np.ndarray, gain: float = 1.0) -> None:
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    end = min(len(out), at + len(x))
    if end > at:
        out[at:end] += x[:end - at] * gain


def mix_into_mono(out: np.ndarray, at: int, x: np.ndarray) -> None:
    end = min(len(out), at + len(x))
    if end > at:
        out[at:end] += x[:end - at]


def shaped(x: np.ndarray, length: int, release: float = 0.02) -> np.ndarray:
    y = x[:length].copy()
    n = min(len(y), int(release * RATE))
    if n:
        y[len(y) - n:] *= np.linspace(1.0, 0.0, n)[:, None]
    return y


def stereo(x: np.ndarray) -> np.ndarray:
    return np.stack([x, x], axis=1)
