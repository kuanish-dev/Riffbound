from pathlib import Path

import librosa
import numpy as np

RATE = 44100
SEAM = 0.03
KEY_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
HOP = 128
MAJOR = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
MINOR = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])
DIATONIC = {False: [(0, ""), (2, "m"), (4, "m"), (5, ""), (7, ""), (9, "m")],
            True: [(0, "m"), (3, ""), (5, "m"), (7, "m"), (7, ""), (8, ""), (10, "")]}
TRIADS = {"": [0, 4, 7], "m": [0, 3, 7]}


def _vlq(data: bytes, i: int) -> tuple:
    value = 0
    while True:
        byte = data[i]
        i += 1
        value = (value << 7) | (byte & 0x7F)
        if byte < 0x80:
            return value, i


def read_midi(path: Path) -> tuple:
    data = path.read_bytes()
    state = {"bpm": None, "hist": np.zeros(12)}
    i = 14
    while data[i:i + 4] == b"MTrk":
        stop = i + 8 + int.from_bytes(data[i + 4:i + 8], "big")
        _read_track(data, i + 8, stop, state)
        i = stop
    return round(state["bpm"] or 120.0, 3), state["hist"]


def _read_track(data: bytes, j: int, stop: int, state: dict) -> None:
    status = 0
    while j < stop:
        _, j = _vlq(data, j)
        if data[j] == 0xFF:
            j = _meta_event(data, j, state)
        elif data[j] in (0xF0, 0xF7):
            length, k = _vlq(data, j + 1)
            j = k + length
        else:
            status, j = _channel_event(data, j, status, state)


def _meta_event(data: bytes, j: int, state: dict) -> int:
    length, k = _vlq(data, j + 2)
    if data[j + 1] == 0x51 and state["bpm"] is None:
        state["bpm"] = 60_000_000 / int.from_bytes(data[k:k + 3], "big")
    return k + length


def _channel_event(data: bytes, j: int, status: int, state: dict) -> tuple:
    if data[j] & 0x80:
        status, j = data[j], j + 1
    if status & 0xF0 == 0x90 and data[j + 1] > 0 and status & 0x0F != 9:
        state["hist"][data[j] % 12] += 1
    return status, j + (1 if status & 0xF0 in (0xC0, 0xD0) else 2)


def key_of(profile: np.ndarray) -> tuple:
    return max((float(np.corrcoef(np.roll(template, k), profile)[0, 1]), k, minor)
               for k in range(12) for minor, template in ((False, MAJOR), (True, MINOR)))


def bar_chords(mono: np.ndarray, sr: int, bpm: float, bars: int, key: int, minor: bool) -> list:
    harmonic = librosa.effects.harmonic(mono)
    hop = 512
    chroma = librosa.feature.chroma_cqt(y=harmonic, sr=sr, hop_length=hop)
    frames_per_bar = 240.0 / bpm * sr / hop
    names = []
    for bar in range(bars):
        a, b = int(bar * frames_per_bar), max(int((bar + 1) * frames_per_bar), int(bar * frames_per_bar) + 1)
        profile = chroma[:, a:b].mean(axis=1)
        best = None
        for degree, quality in DIATONIC[minor]:
            root = (key + degree) % 12
            score = sum(profile[(root + step) % 12] * w for step, w in zip(TRIADS[quality], (1.4, 1.0, 1.0)))
            if best is None or score > best[0]:
                best = (score, KEY_NAMES[root] + quality)
        names.append(best[1])
    return names


def beat_grid(mono: np.ndarray, sr: int, bpm: float | None) -> tuple:
    env = librosa.onset.onset_strength(y=mono, sr=sr, hop_length=HOP)
    env = env / env.max()
    tempo, phase = _best_tempo_phase(env, sr / HOP, _tempo_candidates(env, sr, bpm))
    return round(tempo, 2), phase + _downbeat(mono, sr, tempo, phase) * 60 / tempo


def _tempo_candidates(env: np.ndarray, sr: int, bpm: float | None) -> np.ndarray:
    if bpm is not None:
        return np.array([bpm])
    guess = float(np.atleast_1d(librosa.beat.beat_track(onset_envelope=env, sr=sr, hop_length=HOP)[0])[0])
    return np.arange(guess * 0.95, guess * 1.05, 0.01)


def _best_tempo_phase(env: np.ndarray, fps: float, candidates: np.ndarray) -> tuple:
    best = (-1.0, 0.0, 0.0)
    for tempo in candidates:
        period = 60 / tempo * fps
        beats = np.arange(int(len(env) / period) - 1) * period
        phases = np.arange(0, period, 1.0)
        score = env[(phases[:, None] + beats[None, :]).astype(int)].mean(axis=1)
        if score.max() > best[0]:
            best = (float(score.max()), float(tempo), float(phases[score.argmax()] / fps))
    return best[1], best[2]


def _downbeat(mono: np.ndarray, sr: int, tempo: float, phase: float) -> int:
    fps = sr / HOP
    mel = librosa.power_to_db(librosa.feature.melspectrogram(y=mono, sr=sr, hop_length=HOP, n_mels=64, fmax=8000))
    low = librosa.onset.onset_strength(S=mel[:6], sr=sr, hop_length=HOP)
    frames = ((phase + np.arange(int(len(mono) / sr * tempo / 60) - 1) * 60 / tempo) * fps).astype(int)
    frames = frames[frames < len(low)]
    return int(np.argmax([low[frames[k::4]].mean() for k in range(4)]))


def bake_loop(audio: np.ndarray, start: int, length: int) -> np.ndarray:
    total = len(audio)
    out = audio[(start + np.arange(length)) % total].copy()
    seam = int(SEAM * RATE)
    before = audio[(start - seam + np.arange(seam)) % total]
    ramp = np.linspace(0.0, 1.0, seam)[:, None]
    out[-seam:] = out[-seam:] * (1.0 - ramp) + before * ramp
    return out
