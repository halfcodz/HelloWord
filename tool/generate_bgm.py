"""assets/audio/bgm.mp3 를 만드는 스크립트.

외부 음원을 쓰지 않고 직접 합성한다(저작권 문제 없음).
잔잔한 벨 소리 아르페지오 + 아주 옅은 패드로 이루어진 16초짜리 루프이며,
꼬리가 앞으로 이어지도록 겹쳐서 반복 재생해도 이음매가 들리지 않는다.

사용법:
    python3 tool/generate_bgm.py          # WAV 생성 후 ffmpeg로 mp3 변환
"""

import math
import os
import subprocess
import wave

import numpy as np

SR = 44100          # 샘플레이트
LOOP_SECONDS = 16.0  # 한 바퀴 길이(코드 4개 × 4초)
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")

# 음 이름 → 주파수(A4=440 기준).
NOTES = {
    "C3": 130.81, "E3": 164.81, "F3": 174.61, "G3": 196.00, "A3": 220.00,
    "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00,
    "A4": 440.00, "C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99,
}

# 코드 진행: C - Am - F - G (따뜻하고 익숙한 진행)
CHORDS = [
    ("C3", "E3", "G3"),
    ("A3", "C4", "E4"),
    ("F3", "A3", "C4"),
    ("G3", "C4", "E4"),
]

# 마디마다 흐르는 멜로디(펜타토닉이라 어떤 순서로 겹쳐도 부딪히지 않는다).
MELODY = [
    # (시작 초, 음, 세기)
    (0.0, "C5", 0.9), (0.75, "E5", 0.7), (1.5, "G4", 0.6), (2.5, "D5", 0.55),
    (4.0, "A4", 0.9), (4.75, "C5", 0.7), (5.5, "E5", 0.6), (6.5, "G4", 0.55),
    (8.0, "F4", 0.9), (8.75, "A4", 0.7), (9.5, "C5", 0.6), (10.5, "E5", 0.55),
    (12.0, "G4", 0.9), (12.75, "D5", 0.7), (13.5, "E5", 0.6), (14.5, "C5", 0.5),
]

# 꼬리가 다음 바퀴 앞부분으로 넘어가도 되도록 뒤에 여유를 두고 만든 뒤 접는다.
TAIL_SECONDS = 3.0


def bell(freq, duration, amp):
    """벨/마림바 느낌의 한 음. 배음 몇 개 + 지수 감쇠."""
    n = int(SR * duration)
    t = np.arange(n) / SR
    # 배음 구성: 기음이 크고 위로 갈수록 빠르게 작아진다.
    wave_data = (
        np.sin(2 * math.pi * freq * t)
        + 0.38 * np.sin(2 * math.pi * freq * 2 * t)
        + 0.12 * np.sin(2 * math.pi * freq * 3.01 * t)
    )
    # 어택은 짧게(딱딱하지 않게 5ms), 릴리즈는 길게.
    attack = np.clip(t / 0.005, 0, 1)
    decay = np.exp(-t * 2.2)
    return wave_data * attack * decay * amp


def pad(freqs, start, duration, amp):
    """코드를 아주 여리게 깔아 주는 패드. 부드럽게 들어오고 나간다."""
    n = int(SR * duration)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for i, f in enumerate(freqs):
        # 살짝 디튠해 두께감을 준다.
        detune = 1.0 + (i - 1) * 0.0007
        out += np.sin(2 * math.pi * f * detune * t) * (1.0 / len(freqs))
    # 사인 모양 엔벨로프(양 끝이 0이라 이음매가 안 들린다).
    envelope = np.sin(np.pi * np.clip(t / duration, 0, 1)) ** 1.5
    return out * envelope * amp


def build():
    total = int(SR * (LOOP_SECONDS + TAIL_SECONDS))
    buf = np.zeros(total)

    # 1) 패드(코드) — 마디마다 4초씩, 살짝 겹치게.
    for i, chord in enumerate(CHORDS):
        start = i * 4.0
        freqs = [NOTES[n] for n in chord]
        seg = pad(freqs, start, 4.6, amp=0.16)
        s = int(SR * start)
        buf[s:s + len(seg)] += seg[:max(0, total - s)]

    # 2) 멜로디(벨).
    for start, note, amp in MELODY:
        seg = bell(NOTES[note], 2.6, amp * 0.28)
        s = int(SR * start)
        end = min(total, s + len(seg))
        buf[s:end] += seg[:end - s]

    # 3) 꼬리를 앞으로 접어 넣어 이음매 없는 루프로 만든다.
    loop_len = int(SR * LOOP_SECONDS)
    tail = buf[loop_len:]
    loop = buf[:loop_len].copy()
    loop[:len(tail)] += tail

    # 4) 아주 살짝 로우패스(부드럽게) + 노멀라이즈.
    kernel = np.ones(24) / 24
    loop = np.convolve(loop, kernel, mode="same")
    peak = np.max(np.abs(loop))
    if peak > 0:
        loop = loop / peak * 0.5  # -6 dBFS 정도. 배경음악이라 여유 있게.
    return loop


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    loop = build()
    pcm = (loop * 32767).astype("<i2")

    wav_path = os.path.join(OUT_DIR, "bgm.wav")
    with wave.open(wav_path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())
    print("wrote", wav_path)

    mp3_path = os.path.join(OUT_DIR, "bgm.mp3")
    subprocess.run(
        ["ffmpeg", "-y", "-i", wav_path, "-codec:a", "libmp3lame",
         "-b:a", "96k", "-ar", "44100", "-ac", "1", mp3_path],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    os.remove(wav_path)
    size = os.path.getsize(mp3_path) / 1024
    print(f"wrote {mp3_path} ({size:.0f} KB)")


if __name__ == "__main__":
    main()
