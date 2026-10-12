"""Generate our original, unrestricted test fixture; no third-party music."""
import math
import struct
import wave
from pathlib import Path

output = Path(__file__).resolve().parents[1] / 'OfflineMusicPlayerTests/Fixtures/TestTone.wav'
rate = 22050
with wave.open(str(output), 'wb') as audio:
    audio.setnchannels(1)
    audio.setsampwidth(2)
    audio.setframerate(rate)
    for i in range(rate * 12):
        # Low volume and a short fade at both ends.
        envelope = min(1, i / (rate * 0.1), (rate * 12 - i - 1) / (rate * 0.1))
        audio.writeframesraw(struct.pack('<h', int(1800 * envelope * math.sin(2 * math.pi * 440 * i / rate))))
print(output)
