#!/usr/bin/env python3
import json
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import librosa
import numpy as np
import soundfile as sf
from scipy import signal

from track_analysis import bake_loop, bar_chords, beat_grid, key_of, read_midi

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
RATE = 44100

NOTE_OFFSETS = {"c": 0, "db": 1, "d": 2, "eb": 3, "e": 4, "f": 5, "gb": 6, "g": 7, "ab": 8, "a": 9, "bb": 10, "b": 11}
KEY_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

GUITAR_NOTES = ["e2", "gb2", "a2", "c3", "eb3", "gb3", "a3", "c4", "eb4", "gb4", "a4", "c5", "eb5", "gb5", "a5", "c6", "d6"]
BASS_NOTES = ["a1", "c2", "eb2", "gb2", "a2", "c3", "eb3", "gb3", "a3"]
BASS_OCTAVE = -12
DRUMS = {
    "kick_1.flac": ("kick_1", 0.6), "kick_2.flac": ("kick_2", 0.6),
    "snare_1.flac": ("snare_1", 0.5), "snare_2.flac": ("snare_2", 0.5),
    "hat_1.flac": ("hat_1", 0.2), "hat_2.flac": ("hat_2", 0.2),
    "hat_open.flac": ("hat_open", 0.8), "crash.flac": ("crash", 2.0),
}
TRACKS = {
    "rock_theme_3": {"src": "rock_theme_3_loop_.wav", "midi": "rock_theme_3.mid"},
    "rocky_loop": {"src": "loop.7z:loop/loop.ogg", "midi": "loop_1.mid", "key": "C minor"},
    "unchained_destiny": {"src": "unchained_destiny_loop.wav"},
    "jrpg_battle": {"src": "jrpg_battle_loop.mp3"},
    "background_loop": {"src": "background_music_loop.mp3"},
    "funked_up": {"src": "Funked_Up.mp3"},
}
SEAMLESS = 0.15
PRE_ROLL = 0.01
TRACK_RMS = 0.12
FX = ["light_01", "light_03", "flare_01", "spark_04", "star_05", "smoke_03", "circle_05"]
FONTS = ["Rubik.ttf", "Rubik-OFL.txt", "RussoOne-Regular.ttf", "RussoOne-OFL.txt"]


def midi_of(name: str) -> int:
    pitch, octave = name[:-1], int(name[-1])
    return 12 * (octave + 1) + NOTE_OFFSETS[pitch]


def load_mono(path: Path) -> np.ndarray:
    data, rate = sf.read(path, always_2d=True)
    mono = data.mean(axis=1)
    if rate != RATE:
        mono = librosa.resample(mono, orig_sr=rate, target_sr=RATE)
    return mono.astype(np.float64)


def trim(x: np.ndarray, seconds: float, fade: float) -> np.ndarray:
    start = int(np.argmax(np.abs(x) > 0.02 * np.max(np.abs(x))))
    start = max(0, start - int(0.003 * RATE))
    y = x[start:start + int(seconds * RATE)].copy()
    n = min(len(y), int(fade * RATE))
    y[len(y) - n:] *= np.linspace(1.0, 0.0, n)
    return y


def lead_tone(x: np.ndarray) -> np.ndarray:
    sos_pre = signal.butter(2, 110, "highpass", fs=RATE, output="sos")
    y = signal.sosfilt(sos_pre, x / (np.max(np.abs(x)) + 1e-9))
    drive, bias = 7.0, 0.12
    y = np.tanh(drive * (y + bias)) - np.tanh(drive * bias)
    sos_cab = np.vstack([
        signal.butter(2, 80, "highpass", fs=RATE, output="sos"),
        signal.butter(4, 4800, "lowpass", fs=RATE, output="sos"),
    ])
    y = signal.sosfilt(sos_cab, y)
    b, a = signal.iirpeak(1500, 1.2, fs=RATE)
    y = y + 0.35 * signal.lfilter(b, a, y)
    return level(y)


def level(y: np.ndarray, target_rms: float = 0.18) -> np.ndarray:
    head = y[: int(0.4 * RATE)]
    y = y * (target_rms / (np.sqrt(np.mean(head ** 2)) + 1e-9))
    peak = np.max(np.abs(y))
    return y * (0.95 / peak) if peak > 0.95 else y


def write_ogg(path: Path, y: np.ndarray, quality: float = 0.3) -> None:
    channels = 1 if y.ndim == 1 else y.shape[1]
    with sf.SoundFile(path, "w", RATE, channels, format="OGG", subtype="VORBIS", compression_level=quality) as f:
        for i in range(0, len(y), 8192):
            f.write(y[i:i + 8192].astype(np.float32))


def write_wav(path: Path, y: np.ndarray) -> None:
    sf.write(path, np.clip(y, -1.0, 1.0).astype(np.float32), RATE, subtype="PCM_16")


def build_guitar(dl: Path) -> None:
    out = ASSETS / "guitar"
    out.mkdir(parents=True, exist_ok=True)
    for name in GUITAR_NOTES:
        y = lead_tone(trim(load_mono(dl / "guitar" / f"{name}_f_rr1.wav"), 3.2, 0.3))
        write_ogg(out / f"{midi_of(name)}.ogg", y)
    for i in (1, 2, 3):
        y = lead_tone(trim(load_mono(dl / "guitar" / f"muted1_rr{i}.wav"), 0.25, 0.08))
        write_ogg(out / f"dead_{i}.ogg", y * 0.7)


def build_bass(dl: Path) -> None:
    out = ASSETS / "bass"
    out.mkdir(parents=True, exist_ok=True)
    for name in BASS_NOTES:
        y = trim(load_mono(dl / "bass" / f"{name}_f_rr1.wav"), 1.4, 0.25)
        write_wav(out / f"{midi_of(name) + BASS_OCTAVE}.wav", y / (np.max(np.abs(y)) + 1e-9) * 0.9)


def build_drums(dl: Path) -> None:
    out = ASSETS / "drums"
    out.mkdir(parents=True, exist_ok=True)
    for src, (name, seconds) in DRUMS.items():
        y = trim(load_mono(dl / "drums" / src), seconds, min(0.15, seconds / 3))
        write_wav(out / f"{name}.wav", y / (np.max(np.abs(y)) + 1e-9) * 0.9)


def build_tracks(dl: Path) -> dict:
    out = ASSETS / "tracks"
    out.mkdir(parents=True, exist_ok=True)
    report = {}
    with tempfile.TemporaryDirectory() as tmp:
        for track_id, spec in TRACKS.items():
            audio = _track_audio(dl, spec, Path(tmp))
            mono = librosa.resample(audio.mean(axis=1), orig_sr=RATE, target_sr=22050)
            midi_bpm, notes = read_midi(dl / "tracks" / spec["midi"]) if "midi" in spec else (None, None)
            bpm, downbeat = beat_grid(mono, 22050, midi_bpm)
            bar = 240.0 / bpm
            seconds = len(audio) / RATE
            bars = _whole_bars(seconds, bar)
            start = int(max(0.0, (downbeat % bar) - PRE_ROLL) * RATE)
            loop = _leveled(bake_loop(audio, start, int(round(bars * bar * RATE))))
            write_ogg(out / f"{track_id}.ogg", loop, 0.55)
            confidence, key, minor = _track_key(spec, mono, notes)
            loop_mono = librosa.resample(loop.mean(axis=1), orig_sr=RATE, target_sr=22050)
            report[track_id] = {"chords": "|".join(bar_chords(loop_mono, 22050, bpm, bars, key, minor)), "bpm": bpm,
                                "bars": bars, "offset": round(downbeat % bar - start / RATE, 3), "key": key, "minor": minor,
                                "key_name": KEY_NAMES[key] + (" minor" if minor else " major"),
                                "key_confidence": round(confidence, 3), "source_seconds": round(seconds, 3),
                                "dropped_seconds": round(seconds - bars * bar, 3)}
    return report


def _track_audio(dl: Path, spec: dict, tmp: Path) -> np.ndarray:
    path = dl / "tracks" / spec["src"]
    if ":" in spec["src"]:
        archive, member = spec["src"].split(":")
        subprocess.run(["tar", "-xf", str(dl / "tracks" / archive), "-C", str(tmp), member], check=True)
        path = tmp / member
    audio, rate = sf.read(path, always_2d=True)
    return librosa.resample(audio.T, orig_sr=rate, target_sr=RATE).T if rate != RATE else audio


def _whole_bars(seconds: float, bar: float) -> int:
    nearest = round(seconds / bar)
    return nearest if abs(seconds - nearest * bar) < SEAMLESS else int(seconds / bar)


def _leveled(loop: np.ndarray) -> np.ndarray:
    loop = loop * (TRACK_RMS / (np.sqrt(np.mean(loop ** 2)) + 1e-9))
    return loop / max(1.0, np.max(np.abs(loop)) / 0.98)


def _track_key(spec: dict, mono: np.ndarray, notes: np.ndarray | None) -> tuple:
    if "key" in spec:
        root, mode = spec["key"].split()
        return 1.0, KEY_NAMES.index(root), mode == "minor"
    profile = notes if notes is not None else librosa.feature.chroma_cqt(y=librosa.effects.harmonic(mono), sr=22050).mean(axis=1)
    return key_of(profile)


def build_fx(dl: Path) -> None:
    out = ASSETS / "fx"
    out.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(dl / "kenney" / "kenney_particle-pack.zip") as z, tempfile.TemporaryDirectory() as tmp:
        for name in FX:
            member = f"PNG (Transparent)/{name}.png"
            z.extract(member, tmp)
            subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(Path(tmp) / member), "-vf", "scale=256:256",
                            str(out / f"{name}.png")], check=True)


def build_fonts(dl: Path) -> None:
    out = ASSETS / "fonts"
    out.mkdir(parents=True, exist_ok=True)
    for name in FONTS:
        shutil.copy(dl / "fonts" / name, out / name)


def chords_only() -> None:
    import re
    table = (ROOT / "core" / "tracks.gd").read_text()
    for m in re.finditer(r'"id": "(\w+)".*?"bpm": ([\d.]+), "bars": (\d+).*?"key": (\d+), "scale": "(\w+)"', table, re.S):
        track_id, bpm, bars, key, scale = m.group(1), float(m.group(2)), int(m.group(3)), int(m.group(4)), m.group(5)
        mono, sr = librosa.load(ASSETS / "tracks" / f"{track_id}.ogg", sr=22050, mono=True)
        print(f'{track_id}: "chords": "{"|".join(bar_chords(mono, sr, bpm, bars, key, scale.startswith("minor")))}"')


def main() -> None:
    if sys.argv[1:] == ["--chords"]:
        chords_only()
        return
    dl = Path(sys.argv[1]).resolve()
    if sys.argv[2:] == ["tracks"]:
        print(json.dumps(build_tracks(dl), ensure_ascii=False, indent=1))
        return
    build_guitar(dl)
    build_bass(dl)
    build_drums(dl)
    build_fx(dl)
    build_fonts(dl)
    print(json.dumps(build_tracks(dl), ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
