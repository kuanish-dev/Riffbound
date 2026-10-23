from pathlib import Path

import numpy as np
from pedalboard import (Chorus, Compressor, Distortion, Gain, HighpassFilter, HighShelfFilter, Limiter, LowpassFilter,
    LowShelfFilter, PeakFilter, Pedalboard, Reverb)

from band_samples import RATE, Kit, Pitched, mix_into, mix_into_mono, scan, shaped, stereo
from band_score import LEAD_IN, PRE_ROLL, SLOTS, bar_count, chord_at, events, low_note, note_midi, plan, ring_until

ROOT = Path(__file__).resolve().parent.parent
TRACKS = ROOT / "assets" / "tracks"
TRACK_RMS = 0.12
VELOCITY = {"lower": 0.62, "upper": 0.95}
DRUMS = {"kick": ["KdrumR", "KdrumL"], "snare": ["Snare"], "hat": ["HihatClosed"], "open": ["HihatOpen"],
    "crash": ["CrashL", "CrashR"], "ride": ["RideR"], "china": ["China"], "tom1": ["Tom1"], "tom2": ["Tom2"],
    "tom3": ["Tom3"], "tom4": ["Tom4"]}
DRUM_GAIN = {"hat": 0.55, "open": 0.6, "ride": 0.6, "crash": 0.75, "china": 0.6}
REGISTER = {"bass": 28, "guitar": 40, "cello": 36, "viola": 57, "clean": 52}
PALM = {"length": 0.85, "cutoff": 1400.0}
TAKE_DELAY = [0.0, 0.012]
STRUM = 0.004
MIX = {"drums": 0.1, "bass": 0.1, "guitars": 0.08, "strings": 0.025, "clean": 0.05}


class Band:
    def __init__(self, src: Path):
        kit = next(src.glob("muldjord/*/DrumGizmo/MuldjordKit/Samples"))
        self.kit = Kit(kit)
        self.guitar = Pitched(scan(src / "emily/Emilyguitar/notes", r"([a-g]b?)(\d)_(p|mp|mf|f)_rr\d\.wav", 0))
        self.bass = Pitched(scan(src / "swagbass/Swagbass/notes", r"([a-g]b?)(\d)_(p|f|fff)_rr\d\.wav", -1))
        strings = src / "vsco/Strings"
        self.cello = Pitched(scan(strings / "Cello Section/susvib", r"susvib_([A-G]b?)(\d)_(v\d)_\d\.wav", 1))
        self.viola = Pitched(scan(strings / "Viola Section/susvib", r"ViolaEns_susvib_([A-G]b?)(\d)_(v\d)_\d\.wav", 1))

    def render(self, song: dict) -> np.ndarray:
        slot = 60.0 / song["bpm"] / 2 * RATE
        total = (LEAD_IN + bar_count(song) + 1) * SLOTS
        length = int(round(total * slot))
        stems = {"drums": self.drums(song, slot, length), "bass": self.bass_part(song, slot, length, total),
            "guitars": self.guitars(song, slot, length, total), "strings": self.strings(song, slot, length, total),
            "clean": self.counter(song, slot, length)}
        mix = sum(loudness(stems[k], MIX[k]) for k in stems)
        master = Pedalboard([LowShelfFilter(cutoff_frequency_hz=90, gain_db=2.5), PeakFilter(cutoff_frequency_hz=400, gain_db=-3, q=0.8),
            HighShelfFilter(cutoff_frequency_hz=5000, gain_db=2.0),
            Compressor(threshold_db=-14, ratio=2.5, attack_ms=10, release_ms=120), Limiter(-1.0)])
        mix = master(mix.T.astype(np.float32), RATE).T
        mix = mix * (TRACK_RMS / (np.sqrt(np.mean(mix ** 2)) + 1e-9))
        mix = np.clip(mix, -0.98, 0.98)
        fade = int(slot * 4)
        mix[-fade:] *= np.linspace(1.0, 0.0, fade)[:, None]
        return np.concatenate([np.zeros((int(PRE_ROLL * RATE), 2), np.float32), mix[:length - int(PRE_ROLL * RATE)]])

    def drums(self, song: dict, slot: float, length: int) -> np.ndarray:
        out = np.zeros((length, 2), np.float32)
        for b, parts, _spec in plan(song):
            for part, cells in parts.items():
                if part not in DRUMS:
                    continue
                for s, cell in enumerate(cells):
                    if cell == ".":
                        continue
                    pieces = DRUMS[part]
                    piece = pieces[(b * SLOTS + s) % len(pieces)]
                    velocity = VELOCITY["upper" if cell.isupper() else "lower"]
                    mix_into(out, int(round((b * SLOTS + s) * slot)), self.kit.hit(piece, velocity), DRUM_GAIN.get(part, 1.0))
        board = Pedalboard([Compressor(threshold_db=-16, ratio=3, attack_ms=8, release_ms=90),
            LowShelfFilter(cutoff_frequency_hz=70, gain_db=3), PeakFilter(cutoff_frequency_hz=420, gain_db=-4, q=1.0),
            PeakFilter(cutoff_frequency_hz=4000, gain_db=3, q=0.8), Reverb(room_size=0.25, wet_level=0.08, dry_level=0.95)])
        return board(np.ascontiguousarray(out.T), RATE).T

    def bass_part(self, song: dict, slot: float, length: int, total: int) -> np.ndarray:
        out = np.zeros(length, np.float32)
        evs = events(song, "bass")
        for i, ev in enumerate(evs):
            root, _tones = ev["chord"]
            midi = low_note(root, REGISTER["bass"]) + {"x": 0, "o": 12, "f": 7}[ev["cell"].lower()]
            x = self.bass.note(midi, "fff" if ev["cell"].isupper() else "f")[:, 0]
            ring = int((ring_until(evs, i, total) - ev["at"]) * slot) - int(0.01 * RATE)
            mix_into_mono(out, int(round(ev["at"] * slot)), shaped(x[:, None], ring)[:, 0])
        board = Pedalboard([HighpassFilter(35), Compressor(threshold_db=-20, ratio=4, attack_ms=5, release_ms=80),
            Distortion(drive_db=4), LowpassFilter(3500), LowShelfFilter(cutoff_frequency_hz=100, gain_db=3), Gain(-4)])
        return stereo(board(out[None, :], RATE)[0])

    def guitars(self, song: dict, slot: float, length: int, total: int) -> np.ndarray:
        evs = events(song, "guitar")
        sides = [self._guitar_take(evs, slot, length, total, take) for take in range(2)]
        return np.stack([sides[0] * 0.95 + sides[1] * 0.12, sides[1] * 0.95 + sides[0] * 0.12], axis=1)

    def _guitar_take(self, evs: list, slot: float, length: int, total: int, take: int) -> np.ndarray:
        di = np.zeros(length, np.float32)
        for i, ev in enumerate(evs):
            if ev["cell"] != "-":
                self._power_chord(di, ev, ring_until(evs, i, total), slot, TAKE_DELAY[take])
        return guitar_amp(take)(di[None, :], RATE)[0]

    def _power_chord(self, di: np.ndarray, ev: dict, until: int, slot: float, delay: float) -> None:
        low = low_note(ev["chord"][0], REGISTER["guitar"])
        palm = ev["cell"].islower()
        ring = int(slot * PALM["length"]) if palm else int((until - ev["at"]) * slot)
        at = int(round(ev["at"] * slot + delay * RATE))
        for k, midi in enumerate([low, low + 7, low + 12]):
            x = shaped(self.guitar.note(midi, "mf" if palm else "f"), ring, 0.03 if palm else 0.06)[:, 0]
            mix_into_mono(di, at + int(k * STRUM * RATE), _lowpass(x, PALM["cutoff"]) if palm else x)

    def strings(self, song: dict, slot: float, length: int, total: int) -> np.ndarray:
        out = np.zeros((length, 2), np.float32)
        evs = events(song, "strings")
        for i, ev in enumerate(evs):
            root, tones = ev["chord"]
            ring = int((ring_until(evs, i, total) - ev["at"]) * slot) + int(0.15 * RATE)
            at = int(round(ev["at"] * slot))
            cello_root = low_note(root, REGISTER["cello"])
            upper = sorted(low_note(t, REGISTER["viola"]) for t in tones[1:]) or [low_note(root, REGISTER["viola"])]
            for lib, midi in [(self.cello, cello_root), (self.cello, cello_root + 7)] + [(self.viola, m) for m in upper]:
                x = lib.note(midi, "v3" if lib is self.cello else "v2")
                x = shaped(x, ring, 0.25)
                attack = min(len(x), int(0.04 * RATE))
                x[:attack] *= np.linspace(0.0, 1.0, attack)[:, None]
                mix_into(out, at, x, 0.5)
        board = Pedalboard([HighpassFilter(110), PeakFilter(cutoff_frequency_hz=400, gain_db=-4, q=0.8), LowpassFilter(7000),
            Reverb(room_size=0.7, wet_level=0.3, dry_level=0.8)])
        return board(np.ascontiguousarray(out.T), RATE).T

    def counter(self, song: dict, slot: float, length: int) -> np.ndarray:
        out = np.zeros(length, np.float32)
        for b, bar in enumerate(song.get("counter", [])):
            for s, cell in enumerate(bar.split()):
                if cell in "-=":
                    continue
                at = (LEAD_IN + b) * SLOTS + s
                x = self.guitar.note(note_midi(cell), "mp")[:, 0]
                mix_into_mono(out, int(round(at * slot)), shaped(x[:, None], int(slot * 3), 0.2)[:, 0])
        board = Pedalboard([HighpassFilter(120), Compressor(threshold_db=-20, ratio=3), Chorus(rate_hz=0.8, depth=0.2, mix=0.4),
            Reverb(room_size=0.6, wet_level=0.3, dry_level=0.8), Gain(-2)])
        wet = board(np.stack([out, out]), RATE).T
        return wet * np.array([0.8, 1.0], np.float32)


def loudness(x: np.ndarray, target: float) -> np.ndarray:
    frames = x.reshape(-1)[: len(x.reshape(-1)) // 4410 * 4410].reshape(-1, 4410)
    rms = np.sqrt(np.mean(frames ** 2, axis=1))
    active = rms[rms > 0.1 * rms.max()] if rms.max() > 0 else rms
    return x * (target / (np.sqrt(np.mean(active ** 2)) + 1e-9)) if rms.max() > 0 else x


def guitar_amp(take: int) -> Pedalboard:
    return Pedalboard([HighpassFilter(100), Gain(6), Distortion(drive_db=26 + 3 * take), HighpassFilter(90),
        LowpassFilter(6500), PeakFilter(cutoff_frequency_hz=450, gain_db=-5, q=0.9),
        PeakFilter(cutoff_frequency_hz=2800, gain_db=4, q=1.0), Compressor(threshold_db=-18, ratio=3), Gain(-10)])


def _lowpass(x: np.ndarray, hz: float) -> np.ndarray:
    return Pedalboard([LowpassFilter(hz)])(x[None, :].astype(np.float32), RATE)[0]


def render_all(songs: list, src: str) -> None:
    import build_assets
    band = Band(Path(src).expanduser())
    TRACKS.mkdir(parents=True, exist_ok=True)
    for song in songs:
        build_assets.write_ogg(TRACKS / f"{song['id']}.ogg", band.render(song), 0.4)
        print(song["id"])
