#!/usr/bin/env python3
"""Сборка звуков и текстур Riffbound из скачанных свободных материалов (источники — CREDITS.md).

Запуск (нужны numpy, scipy, soundfile, librosa; ffmpeg и tar (bsdtar, читает .7z) в PATH):
    python tools/build_assets.py <папка_загрузок>
В папке загрузок: tracks/ guitar/ bass/ drums/ kenney/ fonts/ — файлы как их отдают источники.

Пишет в assets/:
    guitar/<midi>.ogg, guitar/dead_<n>.ogg  — гитара через перегруз и кабинет (играется голосами гитары)
    bass/<midi>.wav, drums/<имя>.wav         — 16-бит PCM: из них игра сама собирает бэкинг
    tracks/<id>.ogg                          — CC0-треки для джема
    fx/*.png, fonts/*                        — текстуры свечения и шрифты
и печатает темп, число тактов, тональность и аккорды по тактам треков — их переносим в core/tracks.gd.
    python tools/build_assets.py --chords    — только аккорды уже собранных треков (assets/tracks)
"""
import json
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

import librosa
import numpy as np
import soundfile as sf
from scipy import signal

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
RATE = 44100

NOTE_OFFSETS = {"c": 0, "db": 1, "d": 2, "eb": 3, "e": 4, "f": 5, "gb": 6, "g": 7, "ab": 8, "a": 9, "bb": 10, "b": 11}
KEY_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

GUITAR_NOTES = ["e2", "gb2", "a2", "c3", "eb3", "gb3", "a3", "c4", "eb4", "gb4", "a4", "c5", "eb5", "gb5", "a5", "c6", "d6"]
BASS_NOTES = ["a1", "c2", "eb2", "gb2", "a2", "c3", "eb3", "gb3", "a3"]
# барабан: файл загрузки → (имя в игре, длина в секундах)
DRUMS = {
    "kick_1.flac": ("kick_1", 0.6), "kick_2.flac": ("kick_2", 0.6),
    "snare_1.flac": ("snare_1", 0.5), "snare_2.flac": ("snare_2", 0.5),
    "hat_1.flac": ("hat_1", 0.2), "hat_2.flac": ("hat_2", 0.2),
    "hat_open.flac": ("hat_open", 0.8), "crash.flac": ("crash", 2.0),
}
# трек: id → файл загрузки (или «архив:файл в нём»), MIDI автора, если есть (точный темп), и тональность,
# если анализ ошибается
TRACKS = {
    "rock_theme_3": {"src": "rock_theme_3_loop_.wav", "midi": "rock_theme_3.mid"},
    # ноты MIDI — ровно C Eb F G Bb (до-минорная пентатоника), профиль Крумхансла путает её с фа мажором
    "rocky_loop": {"src": "loop.7z:loop/loop.ogg", "midi": "loop_1.mid", "key": "C minor"},
    "unchained_destiny": {"src": "unchained_destiny_loop.wav"},
    "jrpg_battle": {"src": "jrpg_battle_loop.mp3"},
    "background_loop": {"src": "background_music_loop.mp3"},
    "funked_up": {"src": "Funked_Up.mp3"},
}
SEAMLESS = 0.15     # петля автора — целое число тактов, если лишнего меньше стольких секунд
PRE_ROLL = 0.01     # петля начинается чуть раньше сильной доли, чтобы не срезать атаку (это и есть offset в игре)
SEAM = 0.03         # сшивка конца петли с началом, с
TRACK_RMS = 0.12
FX = ["light_01", "light_03", "flare_01", "spark_04", "star_05", "smoke_03", "circle_05"]
FONTS = ["Rubik.ttf", "Rubik-OFL.txt", "RussoOne-Regular.ttf", "RussoOne-OFL.txt"]

# Профили тональностей Крумхансла — для оценки тона по хроме
MAJOR = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
MINOR = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])


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
    """С начала звука (чуть раньше атаки), заданной длины, с плавным концом."""
    start = int(np.argmax(np.abs(x) > 0.02 * np.max(np.abs(x))))
    start = max(0, start - int(0.003 * RATE))
    y = x[start:start + int(seconds * RATE)].copy()
    n = min(len(y), int(fade * RATE))
    y[len(y) - n:] *= np.linspace(1.0, 0.0, n)
    return y


def lead_tone(x: np.ndarray) -> np.ndarray:
    """Чистый сигнал с датчиков → перегруженная соло-гитара: срез низа, асимметричный перегруз, кабинет."""
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
    """Одинаковая громкость начала ноты, без перегрузки по пику."""
    head = y[: int(0.4 * RATE)]
    y = y * (target_rms / (np.sqrt(np.mean(head ** 2)) + 1e-9))
    peak = np.max(np.abs(y))
    return y * (0.95 / peak) if peak > 0.95 else y


def write_ogg(path: Path, y: np.ndarray, quality: float = 0.3) -> None:
    """Vorbis кусками: libsndfile падает, если отдать ему длинный звук одним блоком. quality: 0 — лучше, 1 — меньше."""
    channels = 1 if y.ndim == 1 else y.shape[1]
    with sf.SoundFile(path, "w", RATE, channels, format="OGG", subtype="VORBIS", compression_level=quality) as f:
        for i in range(0, len(y), 8192):
            f.write(y[i:i + 8192].astype(np.float32))


def write_wav(path: Path, y: np.ndarray) -> None:
    sf.write(path, np.clip(y, -1.0, 1.0).astype(np.float32), RATE, subtype="PCM_16")


def _vlq(data: bytes, i: int) -> tuple:
    value = 0
    while True:
        byte = data[i]
        i += 1
        value = (value << 7) | (byte & 0x7F)
        if byte < 0x80:
            return value, i


def read_midi(path: Path) -> tuple:
    """Первый темп и гистограмма высот (без 10-го канала — ударных) из стандартного MIDI-файла."""
    data = path.read_bytes()
    bpm, hist, i = 120.0, np.zeros(12), 14
    first_tempo = True
    while data[i:i + 4] == b"MTrk":
        stop = i + 8 + int.from_bytes(data[i + 4:i + 8], "big")
        j, status = i + 8, 0
        while j < stop:
            _, j = _vlq(data, j)
            if data[j] == 0xFF:
                kind = data[j + 1]
                length, k = _vlq(data, j + 2)
                if kind == 0x51 and first_tempo:
                    bpm, first_tempo = 60_000_000 / int.from_bytes(data[k:k + 3], "big"), False
                j = k + length
            elif data[j] in (0xF0, 0xF7):
                length, k = _vlq(data, j + 1)
                j = k + length
            else:
                if data[j] & 0x80:
                    status, j = data[j], j + 1
                if status & 0xF0 == 0x90 and data[j + 1] > 0 and status & 0x0F != 9:
                    hist[data[j] % 12] += 1
                j += 1 if status & 0xF0 in (0xC0, 0xD0) else 2
        i = stop
    return round(bpm, 3), hist


def key_of(profile: np.ndarray) -> tuple:
    """Тональность по профилю высот (Крумхансл): (тоника, минор?, уверенность)."""
    return max((float(np.corrcoef(np.roll(template, k), profile)[0, 1]), k, minor)
               for k in range(12) for minor, template in ((False, MAJOR), (True, MINOR)))


# Трезвучия тональности: ступень (полутоны от тоники) → лад аккорда. В миноре V бывает и мажорным (гармонический).
DIATONIC = {False: [(0, ""), (2, "m"), (4, "m"), (5, ""), (7, ""), (9, "m")],
            True: [(0, "m"), (3, ""), (5, "m"), (7, "m"), (7, ""), (8, ""), (10, "")]}
TRIADS = {"": [0, 4, 7], "m": [0, 3, 7]}


def bar_chords(mono: np.ndarray, sr: int, bpm: float, bars: int, key: int, minor: bool) -> list:
    """Аккорд каждого такта петли: средняя хрома гармонической части такта против трезвучий тональности
    (корень весомее терции и квинты)."""
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
    """Темп (если не задан — перебором ±5% около оценки librosa) и сильная доля: время первой «единицы»."""
    hop = 128
    fps = sr / hop
    env = librosa.onset.onset_strength(y=mono, sr=sr, hop_length=hop)
    env = env / env.max()
    if bpm is None:
        guess = float(np.atleast_1d(librosa.beat.beat_track(onset_envelope=env, sr=sr, hop_length=hop)[0])[0])
        candidates = np.arange(guess * 0.95, guess * 1.05, 0.01)
    else:
        candidates = np.array([bpm])
    best = (-1.0, 0.0, 0.0)
    for tempo in candidates:
        period = 60 / tempo * fps
        beats = np.arange(int(len(env) / period) - 1) * period
        phases = np.arange(0, period, 1.0)
        score = env[(phases[:, None] + beats[None, :]).astype(int)].mean(axis=1)
        if score.max() > best[0]:
            best = (float(score.max()), float(tempo), float(phases[score.argmax()] / fps))
    _, tempo, phase = best
    # «единица» такта — доля, на которой в среднем сильнее всего бьёт низ (бочка)
    mel = librosa.power_to_db(librosa.feature.melspectrogram(y=mono, sr=sr, hop_length=hop, n_mels=64, fmax=8000))
    low = librosa.onset.onset_strength(S=mel[:6], sr=sr, hop_length=hop)
    frames = ((phase + np.arange(int(len(mono) / sr * tempo / 60) - 1) * 60 / tempo) * fps).astype(int)
    frames = frames[frames < len(low)]
    downbeat = int(np.argmax([low[frames[k::4]].mean() for k in range(4)]))
    return round(tempo, 2), phase + downbeat * 60 / tempo


def bake_loop(audio: np.ndarray, start: int, length: int) -> np.ndarray:
    """Ровно length сэмплов с start (петля автора — по кругу), конец плавно переходит в то, что звучит перед началом."""
    total = len(audio)
    out = audio[(start + np.arange(length)) % total].copy()
    seam = int(SEAM * RATE)
    before = audio[(start - seam + np.arange(seam)) % total]
    ramp = np.linspace(0.0, 1.0, seam)[:, None]
    out[-seam:] = out[-seam:] * (1.0 - ramp) + before * ramp
    return out


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
        write_wav(out / f"{midi_of(name)}.wav", y / (np.max(np.abs(y)) + 1e-9) * 0.9)


def build_drums(dl: Path) -> None:
    out = ASSETS / "drums"
    out.mkdir(parents=True, exist_ok=True)
    for src, (name, seconds) in DRUMS.items():
        y = trim(load_mono(dl / "drums" / src), seconds, min(0.15, seconds / 3))
        write_wav(out / f"{name}.wav", y / (np.max(np.abs(y)) + 1e-9) * 0.9)


def build_tracks(dl: Path) -> dict:
    """Треки → петли ровно в целое число тактов, начиная с сильной доли (PRE_ROLL до неё): сетка игры
    не уезжает на повторах. Печатает темп, число тактов и тональность для core/tracks.gd."""
    out = ASSETS / "tracks"
    out.mkdir(parents=True, exist_ok=True)
    report = {}
    with tempfile.TemporaryDirectory() as tmp:
        for track_id, spec in TRACKS.items():
            path = dl / "tracks" / spec["src"]
            if ":" in spec["src"]:
                archive, member = spec["src"].split(":")
                subprocess.run(["tar", "-xf", str(dl / "tracks" / archive), "-C", tmp, member], check=True)
                path = Path(tmp) / member
            audio, rate = sf.read(path, always_2d=True)
            if rate != RATE:
                audio = librosa.resample(audio.T, orig_sr=rate, target_sr=RATE).T
            mono = librosa.resample(audio.mean(axis=1), orig_sr=RATE, target_sr=22050)
            midi_bpm, notes = read_midi(dl / "tracks" / spec["midi"]) if "midi" in spec else (None, None)
            bpm, downbeat = beat_grid(mono, 22050, midi_bpm)
            bar = 240.0 / bpm
            seconds = len(audio) / RATE
            bars = round(seconds / bar) if abs(seconds - round(seconds / bar) * bar) < SEAMLESS else int(seconds / bar)
            start = int(max(0.0, (downbeat % bar) - PRE_ROLL) * RATE)
            loop = bake_loop(audio, start, int(round(bars * bar * RATE)))
            loop *= TRACK_RMS / (np.sqrt(np.mean(loop ** 2)) + 1e-9)
            loop /= max(1.0, np.max(np.abs(loop)) / 0.98)
            write_ogg(out / f"{track_id}.ogg", loop, 0.55)
            harmonic = librosa.effects.harmonic(mono)
            profile = notes if notes is not None else librosa.feature.chroma_cqt(y=harmonic, sr=22050).mean(axis=1)
            confidence, key, minor = key_of(profile)
            if "key" in spec:
                root, mode = spec["key"].split()
                confidence, key, minor = 1.0, KEY_NAMES.index(root), mode == "minor"
            loop_mono = librosa.resample(loop.mean(axis=1), orig_sr=RATE, target_sr=22050)
            chords = bar_chords(loop_mono, 22050, bpm, bars, key if "key" not in spec else KEY_NAMES.index(spec["key"].split()[0]),
                                minor if "key" not in spec else spec["key"].endswith("minor"))
            report[track_id] = {"chords": " ".join(chords), "bpm": bpm, "bars": bars, "offset": round(downbeat % bar - start / RATE, 3),
                                "key": key, "minor": minor, "key_name": KEY_NAMES[key] + (" minor" if minor else " major"),
                                "key_confidence": round(confidence, 3), "source_seconds": round(seconds, 3),
                                "dropped_seconds": round(seconds - bars * bar, 3)}
    return report


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
    """Аккорды уже собранных петель: темп, такты и тональность — из таблицы core/tracks.gd."""
    import re
    table = (ROOT / "core" / "tracks.gd").read_text()
    for m in re.finditer(r'"id": "(\w+)".*?"bpm": ([\d.]+), "bars": (\d+).*?"key": (\d+), "scale": "(\w+)"', table, re.S):
        track_id, bpm, bars, key, scale = m.group(1), float(m.group(2)), int(m.group(3)), int(m.group(4)), m.group(5)
        mono, sr = librosa.load(ASSETS / "tracks" / f"{track_id}.ogg", sr=22050, mono=True)
        print(f'{track_id}: "chords": "{" ".join(bar_chords(mono, sr, bpm, bars, key, scale.startswith("minor")))}"')


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
