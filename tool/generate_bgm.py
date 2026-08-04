"""assets/audio/ 안의 배경음악·효과음을 만드는 스크립트.

저작권 있는 음원(게임 BGM 등)을 가져다 쓰지 않고 전부 직접 합성한다.
- bgm_1.mp3 ~ bgm_4.mp3 : 잔잔한 마림바/비브라폰 + 포근한 패드.
  마을 같은 분위기로 서로 다른 조성·진행을 써서 이어 들어도 지루하지 않다.
- tap.mp3 : 버튼을 눌렀을 때 나는 아주 짧고 부드러운 '톡' 소리.

사용법:
    python3 tool/generate_bgm.py
"""

import math
import os
import subprocess
import wave

import numpy as np

SR = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")

# 음 이름 → 주파수(A4=440 기준).
NOTES = {
    "C3": 130.81, "D3": 146.83, "E3": 164.81, "F3": 174.61, "G3": 196.00,
    "A3": 220.00, "B3": 246.94,
    "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00,
    "A4": 440.00, "B4": 493.88,
    "C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46, "G5": 783.99,
    "A5": 880.00,
}

BAR = 4.0          # 한 마디 길이(초)
TAIL = 3.0         # 마지막 음의 여운. 앞으로 접어 이음매를 없앤다.


def bell(freq, duration, amp, decay=2.2, detune=0.0):
    """마림바/비브라폰 느낌의 한 음."""
    n = int(SR * duration)
    t = np.arange(n) / SR
    f = freq * (1.0 + detune)
    wave_data = (
        np.sin(2 * math.pi * f * t)
        + 0.34 * np.sin(2 * math.pi * f * 2 * t)
        + 0.10 * np.sin(2 * math.pi * f * 3.01 * t)
        + 0.05 * np.sin(2 * math.pi * f * 4.02 * t)
    )
    attack = np.clip(t / 0.006, 0, 1)
    return wave_data * attack * np.exp(-t * decay) * amp


def pad(freqs, duration, amp):
    """코드를 여리게 깔아 주는 패드. 양 끝이 0이라 이어 붙여도 안 튄다."""
    n = int(SR * duration)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for i, f in enumerate(freqs):
        detune = 1.0 + (i - 1) * 0.0006
        out += np.sin(2 * math.pi * f * detune * t) / len(freqs)
    envelope = np.sin(np.pi * np.clip(t / duration, 0, 1)) ** 1.5
    return out * envelope * amp


def build_track(chords, melody, swing=0.0):
    """코드 진행과 멜로디로 한 곡을 만든다. 끝은 처음으로 이어진다."""
    loop_seconds = len(chords) * BAR
    total = int(SR * (loop_seconds + TAIL))
    buf = np.zeros(total)

    for i, chord in enumerate(chords):
        seg = pad([NOTES[n] for n in chord], BAR + 0.6, amp=0.15)
        s = int(SR * i * BAR)
        end = min(total, s + len(seg))
        buf[s:end] += seg[: end - s]

    for start, note, amp in melody:
        # 살짝 어긋난 타이밍(스윙)으로 기계 느낌을 뺀다.
        offset = swing if int(start * 2) % 2 else 0.0
        seg = bell(NOTES[note], 2.8, amp * 0.26)
        s = int(SR * (start + offset))
        end = min(total, s + len(seg))
        if s < total:
            buf[s:end] += seg[: end - s]

    loop_len = int(SR * loop_seconds)
    tail = buf[loop_len:]
    loop = buf[:loop_len].copy()
    loop[: len(tail)] += tail

    loop = np.convolve(loop, np.ones(24) / 24, mode="same")
    peak = np.max(np.abs(loop))
    if peak > 0:
        loop = loop / peak * 0.5
    return loop


# ── 곡 4개. 조성과 진행을 달리해 이어 들어도 물리지 않게. ──────────────
TRACKS = {
    # 1) 포근한 아침 (C - Am - F - G)
    "bgm_1": dict(
        chords=[("C3", "E3", "G3"), ("A3", "C4", "E4"),
                ("F3", "A3", "C4"), ("G3", "B3", "D4")],
        melody=[(0.0, "C5", .9), (0.75, "E5", .7), (1.5, "G4", .6), (2.5, "D5", .55),
                (4.0, "A4", .9), (4.75, "C5", .7), (5.5, "E5", .6), (6.5, "G4", .55),
                (8.0, "F4", .9), (8.75, "A4", .7), (9.5, "C5", .6), (10.5, "E5", .55),
                (12.0, "G4", .9), (12.75, "D5", .7), (13.5, "E5", .6), (14.5, "C5", .5)],
        swing=0.02,
    ),
    # 2) 산책 (F - C - G - Am)
    "bgm_2": dict(
        chords=[("F3", "A3", "C4"), ("C3", "E3", "G3"),
                ("G3", "B3", "D4"), ("A3", "C4", "E4")],
        melody=[(0.0, "A4", .85), (1.0, "C5", .65), (2.0, "F5", .6), (3.0, "C5", .5),
                (4.0, "G4", .85), (1.0 + 4, "E5", .65), (6.0, "C5", .6), (7.0, "G4", .5),
                (8.0, "B4", .85), (9.0, "D5", .65), (10.0, "G5", .6), (11.0, "D5", .5),
                (12.0, "A4", .85), (13.0, "E5", .65), (14.0, "C5", .6), (15.0, "A4", .5)],
        swing=0.03,
    ),
    # 3) 오후의 낮잠 (Dm - G - C - Am)
    "bgm_3": dict(
        chords=[("D3", "F3", "A3"), ("G3", "B3", "D4"),
                ("C3", "E3", "G3"), ("A3", "C4", "E4")],
        melody=[(0.0, "D5", .8), (1.25, "F5", .6), (2.5, "A4", .55),
                (4.0, "B4", .8), (5.25, "D5", .6), (6.5, "G4", .55),
                (8.0, "E5", .8), (9.25, "C5", .6), (10.5, "G4", .55),
                (12.0, "C5", .8), (13.25, "A4", .6), (14.5, "E5", .5)],
        swing=0.025,
    ),
    # 4) 별 보는 밤 (Am - F - C - G)
    "bgm_4": dict(
        chords=[("A3", "C4", "E4"), ("F3", "A3", "C4"),
                ("C3", "E3", "G3"), ("G3", "B3", "D4")],
        melody=[(0.0, "A4", .8), (1.5, "E5", .6), (3.0, "C5", .5),
                (4.0, "F4", .8), (5.5, "C5", .6), (7.0, "A4", .5),
                (8.0, "G4", .8), (9.5, "E5", .6), (11.0, "C5", .5),
                (12.0, "D5", .8), (13.5, "B4", .6), (15.0, "G4", .5)],
        swing=0.02,
    ),
}


def tap_sound():
    """버튼 누를 때 나는 짧고 부드러운 '톡'. 귀에 거슬리지 않게 아주 짧다."""
    dur = 0.09
    n = int(SR * dur)
    t = np.arange(n) / SR
    # 높은 음에서 살짝 떨어지는 짧은 톤 + 아주 여린 배음.
    freq = 1250 * np.exp(-t * 9)
    phase = 2 * math.pi * np.cumsum(freq) / SR
    wave_data = np.sin(phase) + 0.25 * np.sin(2 * phase)
    envelope = np.exp(-t * 42) * np.clip(t / 0.002, 0, 1)
    out = wave_data * envelope
    peak = np.max(np.abs(out))
    if peak > 0:
        out = out / peak * 0.45
    return out


def write_mp3(name, samples, bitrate="96k"):
    os.makedirs(OUT_DIR, exist_ok=True)
    wav_path = os.path.join(OUT_DIR, f"{name}.wav")
    mp3_path = os.path.join(OUT_DIR, f"{name}.mp3")
    pcm = (samples * 32767).astype("<i2")
    with wave.open(wav_path, "w") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(pcm.tobytes())
    subprocess.run(
        ["ffmpeg", "-y", "-i", wav_path, "-codec:a", "libmp3lame",
         "-b:a", bitrate, "-ar", str(SR), "-ac", "1", mp3_path],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    os.remove(wav_path)
    size = os.path.getsize(mp3_path) / 1024
    print(f"wrote {os.path.basename(mp3_path)} ({size:.0f} KB)")


def main():
    for name, spec in TRACKS.items():
        write_mp3(name, build_track(**spec))
    # 효과음은 아주 짧으니 음질을 조금 더 준다.
    write_mp3("tap", tap_sound(), bitrate="128k")

    # 예전 단일 파일은 더 이상 쓰지 않는다.
    old = os.path.join(OUT_DIR, "bgm.mp3")
    if os.path.exists(old):
        os.remove(old)
        print("removed old bgm.mp3")


if __name__ == "__main__":
    main()
