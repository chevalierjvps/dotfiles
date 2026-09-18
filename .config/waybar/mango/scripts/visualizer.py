#!/usr/bin/env python3
"""
Waybar Audio Visualizer for Amberglow CRT Theme.
Monitors PipeWire/MPRIS audio and streams ASCII spectrum bars to Waybar.
Automatically hides and terminates cava when no audio is playing to preserve CPU.
"""

import atexit
import json
import os
import signal
import subprocess
import sys
import time

BAR_GLYPHS = (" ", " ", "▂", "▃", "▄", "▅", "▆", "▇")
NUM_BARS = 8
FRAMERATE = 20

CAVA_CONFIG = f"""
[general]
bars = {NUM_BARS}
framerate = {FRAMERATE}
autosens = 1
overshoot = 15

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bar_delimiter = 32
"""

cava_proc = None


def cleanup():
    global cava_proc
    if cava_proc is not None:
        try:
            cava_proc.terminate()
            cava_proc.wait(timeout=0.3)
        except Exception:
            try:
                cava_proc.kill()
            except Exception:
                pass
        cava_proc = None


atexit.register(cleanup)


def handle_signal(sig, frame):
    cleanup()
    sys.exit(0)


signal.signal(signal.SIGTERM, handle_signal)
signal.signal(signal.SIGINT, handle_signal)
signal.signal(signal.SIGHUP, handle_signal)


def is_audio_active() -> bool:
    """Check if playerctl is playing or if PipeWire has active audio streams."""
    try:
        res = subprocess.run(
            ["playerctl", "status"],
            capture_output=True,
            text=True,
            timeout=0.2,
        )
        if res.returncode == 0 and "Playing" in res.stdout:
            return True
    except Exception:
        pass

    try:
        res = subprocess.run(
            ["wpctl", "status"],
            capture_output=True,
            text=True,
            timeout=0.2,
        )
        if "[active]" in res.stdout:
            return True
    except Exception:
        pass

    return False


def get_metadata() -> str:
    """Get current playing track metadata for tooltip."""
    try:
        res = subprocess.run(
            ["playerctl", "metadata", "--format", "{{ artist }} — {{ title }}"],
            capture_output=True,
            text=True,
            timeout=0.2,
        )
        out = res.stdout.strip()
        if out and out != "—":
            return f"{out}\nLeft-click: CAVA Visualizer (Float)\nRight-click: Play/Pause"
    except Exception:
        pass
    return "Audio Visualizer (Amberglow CRT)\nLeft-click: CAVA Visualizer (Float)"


def start_cava():
    global cava_proc
    cleanup()
    cava_proc = subprocess.Popen(
        ["cava", "-p", "/dev/stdin"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        bufsize=1,
    )
    cava_proc.stdin.write(CAVA_CONFIG)
    cava_proc.stdin.close()
    return cava_proc


def emit(text: str, tooltip: str = "", css_class: str = ""):
    data = {
        "text": text,
        "tooltip": tooltip,
        "class": css_class,
    }
    sys.stdout.write(json.dumps(data) + "\n")
    sys.stdout.flush()


def main():
    global cava_proc
    consecutive_silence = 0
    tooltip = "Audio Visualizer"
    last_tooltip_time = 0.0

    # Start hidden
    emit("", "", "hidden")

    while True:
        if not is_audio_active():
            cleanup()
            emit("", "", "hidden")
            consecutive_silence = 0
            time.sleep(1.0)
            continue

        # Audio is active, ensure cava is running
        if cava_proc is None or cava_proc.poll() is not None:
            cava_proc = start_cava()
            consecutive_silence = 0

        # Read line from cava
        line = cava_proc.stdout.readline()
        if not line:
            # cava closed or failed
            cleanup()
            time.sleep(0.5)
            continue

        line_str = line.strip()
        if not line_str:
            continue

        # Parse bar values
        parts = line_str.split()
        values = []
        for p in parts:
            if p.isdigit():
                v = int(p)
                values.append(min(max(v, 0), len(BAR_GLYPHS) - 1))

        if len(values) != NUM_BARS:
            continue

        # Check silence
        if all(v == 0 for v in values):
            consecutive_silence += 1
            if consecutive_silence > (FRAMERATE * 2):  # 2 seconds of silence
                if not is_audio_active():
                    cleanup()
                    emit("", "", "hidden")
                    time.sleep(0.5)
                    continue
        else:
            consecutive_silence = 0

        # Update metadata every 2 seconds
        now = time.monotonic()
        if now - last_tooltip_time > 2.0:
            tooltip = get_metadata()
            last_tooltip_time = now

        glyphs = "".join(BAR_GLYPHS[v] for v in values)
        emit(glyphs, tooltip, "playing")


if __name__ == "__main__":
    main()
