"""Generate tiny original, dependency-free UI sounds for the prototype."""
import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def write_tone(name: str, notes: list[tuple[float, float]], volume: float = 0.22) -> None:
    samples: list[int] = []
    for frequency, duration in notes:
        count = int(RATE * duration)
        for index in range(count):
            t = index / RATE
            envelope = math.sin(math.pi * index / max(1, count - 1)) ** 1.5
            tone = math.sin(math.tau * frequency * t) + 0.22 * math.sin(math.tau * frequency * 2 * t)
            samples.append(int(max(-1, min(1, tone * volume * envelope)) * 32767))
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(b"".join(struct.pack("<h", sample) for sample in samples))


write_tone("pickup.wav", [(660, 0.055), (880, 0.075)])
write_tone("craft.wav", [(392, 0.07), (523.25, 0.07), (659.25, 0.11)])
write_tone("build_complete.wav", [(261.63, 0.09), (392, 0.09), (523.25, 0.18)], 0.26)
