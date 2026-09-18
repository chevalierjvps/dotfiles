#!/usr/bin/env python3
"""
Waybar Pomodoro Module with Automated Obsidian Vault Sync
Inspired by Andeskjerf/waybar-module-pomodoro

Features:
- Full Pomodoro lifecycle (Work 25m, Short Break 5m, Long Break 15m after 4 cycles).
- Outputs streaming Waybar-compatible JSON (text, tooltip, class).
- Unix domain socket IPC for toggle, reset, skip, set-task, etc.
- Auto-syncs completed sessions directly into Obsidian Vault:
  - Formats as Dataview-compatible inline metadata + Markdown tables.
  - Updates YAML frontmatter metrics (today_sessions, total_focus_minutes).
- Rofi interactive menu for task selection (pulls tasks from Central de Tarefas or custom input).
- Audio chimes and desktop notifications via notify-send.
"""

import sys
import os
import time
import json
import socket
import select
import subprocess
import re
from datetime import datetime, date
from pathlib import Path

# Paths
SOCKET_PATH = f"/tmp/waybar-pomodoro-{os.getuid()}.sock"
LEGACY_SOCKET = "/tmp/waybar-pomodoro.sock"
CACHE_DIR = Path.home() / ".cache" / "waybar-pomodoro"
CACHE_FILE = CACHE_DIR / "state.json"
VAULT_DIR = Path.home() / "Documents" / "Obsidian Vault"
POMODORO_LOG_FILE = VAULT_DIR / "🍅 Pomodoro & Focus Log.md"
TASKS_FILE = VAULT_DIR / "🎯 Central de Tarefas & Missão.md"

# Durations in seconds
DEFAULT_WORK = 25 * 60
DEFAULT_SHORT_BREAK = 5 * 60
DEFAULT_LONG_BREAK = 15 * 60
MAX_CYCLES = 4

# Sound files
CHIME_SOUND = "/usr/share/sounds/freedesktop/stereo/complete.oga"
BREAK_SOUND = "/usr/share/sounds/freedesktop/stereo/bell.oga"

class PomodoroEngine:
    def __init__(self):
        self.state = "WORK"  # WORK, SHORT_BREAK, LONG_BREAK
        self.is_running = False
        self.remaining_seconds = DEFAULT_WORK
        self.cycle = 1  # 1 to 4
        self.completed_today = 0
        self.task_name = "General Focus"
        self.session_start_time = None
        self.last_date = str(date.today())

        self.work_time = DEFAULT_WORK
        self.short_break_time = DEFAULT_SHORT_BREAK
        self.long_break_time = DEFAULT_LONG_BREAK

        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        self.load_state()

    def load_state(self):
        if CACHE_FILE.exists():
            try:
                with open(CACHE_FILE, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    # Check if day rolled over
                    if data.get("last_date") == str(date.today()):
                        self.completed_today = data.get("completed_today", 0)
                    else:
                        self.completed_today = 0
                        self.last_date = str(date.today())

                    self.state = data.get("state", "WORK")
                    self.remaining_seconds = data.get("remaining_seconds", self.work_time)
                    self.cycle = data.get("cycle", 1)
                    self.task_name = data.get("task_name", "General Focus")
                    self.is_running = False  # Always start paused on boot
            except Exception as e:
                pass

    def save_state(self):
        try:
            data = {
                "state": self.state,
                "remaining_seconds": self.remaining_seconds,
                "cycle": self.cycle,
                "completed_today": self.completed_today,
                "task_name": self.task_name,
                "last_date": str(date.today()),
                "is_running": self.is_running,
            }
            with open(CACHE_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
        except Exception:
            pass

    def tick(self):
        # Daily reset check
        today_str = str(date.today())
        if self.last_date != today_str:
            self.last_date = today_str
            self.completed_today = 0

        if not self.is_running:
            return

        if self.remaining_seconds > 0:
            self.remaining_seconds -= 1

        if self.remaining_seconds <= 0:
            self.on_timer_completed()

    def on_timer_completed(self):
        self.is_running = False

        if self.state == "WORK":
            self.completed_today += 1
            duration_min = self.work_time // 60
            start_dt = self.session_start_time or datetime.now()
            end_dt = datetime.now()

            # 1. Sync to Obsidian Vault
            self.sync_to_obsidian(start_dt, end_dt, duration_min, self.task_name, self.cycle, "completed")

            # 2. Sound & Notification
            play_sound(CHIME_SOUND)
            send_notification(
                "🍅 Pomodoro Completed!",
                f"{duration_min} min on '{self.task_name}' logged to Vault.\nTime for a break.",
                urgency="normal",
            )

            # 3. Next Cycle
            if self.cycle >= MAX_CYCLES:
                self.state = "LONG_BREAK"
                self.remaining_seconds = self.long_break_time
                self.cycle = 1
            else:
                self.state = "SHORT_BREAK"
                self.remaining_seconds = self.short_break_time
                self.cycle += 1

        elif self.state in ("SHORT_BREAK", "LONG_BREAK"):
            play_sound(BREAK_SOUND)
            send_notification(
                "☕ Break Ended!",
                f"Ready for another focus cycle on '{self.task_name}'?",
                urgency="normal",
            )
            self.state = "WORK"
            self.remaining_seconds = self.work_time

        self.save_state()

    def toggle(self):
        self.is_running = not self.is_running
        if self.is_running and self.session_start_time is None:
            self.session_start_time = datetime.now()
        self.save_state()

    def start(self):
        if not self.is_running:
            self.is_running = True
            if self.session_start_time is None:
                self.session_start_time = datetime.now()
            self.save_state()

    def stop(self):
        if self.is_running:
            self.is_running = False
            self.save_state()

    def reset(self):
        # If user spent more than 5 minutes before resetting, log as interrupted
        if self.state == "WORK" and self.session_start_time:
            spent = self.work_time - self.remaining_seconds
            if spent >= 5 * 60:
                self.sync_to_obsidian(
                    self.session_start_time,
                    datetime.now(),
                    spent // 60,
                    self.task_name,
                    self.cycle,
                    "interrupted",
                )

        self.is_running = False
        self.session_start_time = None
        if self.state == "WORK":
            self.remaining_seconds = self.work_time
        elif self.state == "SHORT_BREAK":
            self.remaining_seconds = self.short_break_time
        else:
            self.remaining_seconds = self.long_break_time
        self.save_state()

    def skip(self):
        self.is_running = False
        self.session_start_time = None
        if self.state == "WORK":
            self.state = "SHORT_BREAK"
            self.remaining_seconds = self.short_break_time
        else:
            self.state = "WORK"
            self.remaining_seconds = self.work_time
        self.save_state()

    def set_task(self, name: str):
        if name and name.strip():
            self.task_name = name.strip()
            self.save_state()
            send_notification("🎯 Focus Task Set", f"Current focus: {self.task_name}")

    def sync_to_obsidian(self, start_dt: datetime, end_dt: datetime, duration_min: int, task: str, cycle: int, status_str: str):
        if not POMODORO_LOG_FILE.exists():
            return

        try:
            content = POMODORO_LOG_FILE.read_text(encoding="utf-8")
            today_date = date.today().strftime("%Y-%m-%d")
            start_hm = start_dt.strftime("%H:%M")
            end_hm = end_dt.strftime("%H:%M")
            status_emoji = "✅ Completed" if status_str == "completed" else "⚠️ Interrupted"

            # Parse frontmatter metrics
            total_sessions = 0
            total_mins = 0
            today_sessions = 0
            today_mins = 0

            m_tot_sess = re.search(r"total_sessions:\s*(\d+)", content)
            if m_tot_sess:
                total_sessions = int(m_tot_sess.group(1))
            m_tot_mins = re.search(r"total_focus_minutes:\s*(\d+)", content)
            if m_tot_mins:
                total_mins = int(m_tot_mins.group(1))

            if status_str == "completed":
                total_sessions += 1
                total_mins += duration_min
                today_sessions = self.completed_today
                today_mins = self.completed_today * (self.work_time // 60)

            # Update frontmatter
            content = re.sub(r"total_sessions:\s*\d+", f"total_sessions: {total_sessions}", content)
            content = re.sub(r"total_focus_minutes:\s*\d+", f"total_focus_minutes: {total_mins}", content)
            content = re.sub(r"today_sessions:\s*\d+", f"today_sessions: {today_sessions}", content)
            content = re.sub(r"today_focus_minutes:\s*\d+", f"today_focus_minutes: {today_mins}", content)
            content = re.sub(r"last_sync:.*", f"last_sync: {datetime.now().isoformat()}", content)

            # Update quick stats card
            content = re.sub(
                r"\|\s*🔥\s*\*\*Today's Pomodoros\*\*\s*\|\s*`[^`]+`\s*\|",
                f"| 🔥 **Today's Pomodoros** | `{today_sessions} sessions` |",
                content,
            )
            content = re.sub(
                r"\|\s*⏱️\s*\*\*Focus Time Today\*\*\s*\|\s*`[^`]+`\s*\|",
                f"| ⏱️ **Focus Time Today** | `{today_mins} minutes` |",
                content,
            )
            content = re.sub(
                r"\|\s*🏆\s*\*\*All-Time Total\*\*\s*\|\s*`[^`]+`\s*\|",
                f"| 🏆 **All-Time Total** | `{total_sessions} sessions ({total_mins} min)` |",
                content,
            )
            content = re.sub(
                r"\|\s*🎯\s*\*\*Active Task\*\*\s*\|\s*\*[^*]+\*\s*\|",
                f"| 🎯 **Active Task** | *{task}* |",
                content,
            )

            # Dataview line
            mode_tag = "WORK" if self.state == "WORK" else "BREAK"
            dv_line = f"- [x] (pomodoro:: {mode_tag}) (duration:: {duration_min}m) (start:: {start_hm}) (end:: {end_hm}) (task:: \"{task}\") (cycle:: {cycle}/4) (status:: {status_str})\n"

            # Table row
            table_row = f"| {start_hm} | {end_hm} | 🍅 Focus | {duration_min} min | {task} | {cycle}/4 | {status_emoji} |\n"

            # Insert into today's section
            day_header = f"### 📅 {today_date}"
            if day_header in content:
                idx = content.find(day_header)
                table_split = content[idx:].find("| :---: |")
                if table_split != -1:
                    insert_pos = idx + table_split + len("| :---: |")
                    newline_pos = content[insert_pos:].find("\n")
                    if newline_pos != -1:
                        target = insert_pos + newline_pos + 1
                        content = content.replace("*(Today's completed sessions will appear here automatically).*\n", "")
                        content = content[:target] + table_row + dv_line + content[target:]
            else:
                # Add new day section under ## 📅 Session History
                new_day_section = f"\n{day_header}\n\n| Start | End | Type | Duration | Task / Topic | Cycle | Status |\n| :---: | :---: | :---: | :---: | :--- | :---: | :---: |\n{table_row}{dv_line}\n"
                insert_marker = "## 📅 Session History\n"
                if insert_marker in content:
                    idx = content.find(insert_marker) + len(insert_marker)
                    content = content[:idx] + new_day_section + content[idx:]
                else:
                    content += new_day_section

            POMODORO_LOG_FILE.write_text(content, encoding="utf-8")
        except Exception as e:
            pass

    def get_waybar_json(self) -> str:
        mins = self.remaining_seconds // 60
        secs = self.remaining_seconds % 60
        time_str = f"{mins:02d}:{secs:02d}"

        classes = []
        if self.state == "WORK":
            icon = "󰔐"
            classes.append("work")
            mode_desc = f"Focus (Cycle {self.cycle}/{MAX_CYCLES})"
        elif self.state == "SHORT_BREAK":
            icon = "󰒲"
            classes.append("break")
            mode_desc = "Short Break"
        else:
            icon = "󰃮"
            classes.append("break")
            mode_desc = "Long Break"

        if self.is_running:
            classes.append("running")
            state_desc = "▶️ Running"
        else:
            classes.append("paused")
            state_desc = "⏸️ Paused"

        text = f"{icon} {time_str}"

        tooltip = (
            f"🍅 Pomodoro — {mode_desc}\n"
            f"━━━━━━━━━━━━━━━━━━━━━━\n"
            f"State: {state_desc}\n"
            f"Time: {time_str}\n"
            f"Cycle: {self.cycle} of {MAX_CYCLES}\n"
            f"Today's Pomodoros: {self.completed_today} ({self.completed_today * 25} min)\n"
            f"Active Task: {self.task_name}\n\n"
            f"🖱️ Left Click: Start / Pause\n"
            f"🖱️ Right Click: Reset Session\n"
            f"🖱️ Middle Click: Task & Options Menu (Rofi)\n"
            f"🖱️ Scroll Up/Down: Skip / Reset"
        )

        return json.dumps({
            "text": text,
            "tooltip": tooltip,
            "class": classes,
            "alt": self.state.lower(),
        })

def play_sound(path):
    if Path(path).exists():
        subprocess.Popen(["paplay", path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def send_notification(title, body, urgency="normal"):
    subprocess.Popen([
        "notify-send",
        "-u", urgency,
        "-i", "alarm",
        title,
        body,
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def send_command(cmd: str):
    sock_target = SOCKET_PATH if os.path.exists(SOCKET_PATH) else (LEGACY_SOCKET if os.path.exists(LEGACY_SOCKET) else None)
    if not sock_target:
        # Start server in background if not running
        subprocess.Popen([sys.executable, __file__, "server"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(0.3)
        sock_target = SOCKET_PATH

    try:
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.connect(sock_target)
        client.sendall((cmd + "\n").encode("utf-8"))
        client.close()
    except Exception:
        pass

def extract_pending_tasks_from_vault() -> list:
    tasks = []
    if TASKS_FILE.exists():
        try:
            content = TASKS_FILE.read_text(encoding="utf-8")
            for line in content.splitlines():
                line = line.strip()
                if line.startswith("- [ ]"):
                    # Clean markdown
                    clean = line.replace("- [ ]", "").strip()
                    clean = re.sub(r"\[\[([^\]|]+)(?:\|[^\]]+)?\]\]", r"\1", clean)
                    clean = clean.replace("**", "").replace("*", "")
                    clean = re.sub(r"\$[^$]+\$", "", clean).strip()
                    if clean and len(clean) > 3:
                        tasks.append(clean)
        except Exception:
            pass
    return tasks

def open_rofi_menu():
    pending_tasks = extract_pending_tasks_from_vault()

    menu_options = [
        "▶️ Start / ⏸️ Pause (Toggle)",
        "🔄 Reset Current Cycle",
        "⏭️ Skip to Next Phase (Break/Focus)",
        "📝 Set Custom Focus Task...",
        "📖 Open Pomodoro Log in Obsidian",
        "────────────────────────────────────────",
    ]

    if pending_tasks:
        menu_options.append("🎯 SELECT TASK FROM VAULT:")
        for t in pending_tasks[:10]:
            menu_options.append(f"• {t}")

    rofi_input = "\n".join(menu_options)
    try:
        proc = subprocess.Popen(
            ["rofi", "-dmenu", "-p", "🍅 Pomodoro", "-i", "-lines", "12", "-width", "60"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            text=True,
        )
        stdout, _ = proc.communicate(input=rofi_input)
        selected = stdout.strip()

        if not selected:
            return

        if "Start / ⏸️ Pause" in selected:
            send_command("toggle")
        elif "Reset Current Cycle" in selected:
            send_command("reset")
        elif "Skip to Next Phase" in selected:
            send_command("skip")
        elif "Set Custom Focus Task" in selected:
            # Prompt for custom task
            proc_task = subprocess.Popen(
                ["rofi", "-dmenu", "-p", "🎯 Enter Focus Task:"],
                stdout=subprocess.PIPE,
                text=True,
            )
            custom_task, _ = proc_task.communicate()
            if custom_task.strip():
                send_command(f"set-task {custom_task.strip()}")
        elif "Open Pomodoro Log in Obsidian" in selected:
            subprocess.Popen(["xdg-open", "obsidian://open?vault=Obsidian%20Vault&file=🍅%20Pomodoro%20%26%20Focus%20Log"])
        elif selected.startswith("• "):
            task_picked = selected[2:].strip()
            send_command(f"set-task {task_picked}")
    except Exception as e:
        pass

def try_connect_subscriber() -> socket.socket | None:
    sock_target = SOCKET_PATH if os.path.exists(SOCKET_PATH) else (LEGACY_SOCKET if os.path.exists(LEGACY_SOCKET) else None)
    if not sock_target:
        return None
    try:
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.connect(sock_target)
        sock.sendall(b"SUBSCRIBE\n")
        return sock
    except (ConnectionRefusedError, FileNotFoundError, OSError):
        return None

def run_subscriber(sock: socket.socket):
    try:
        sock_file = sock.makefile("r", encoding="utf-8")
        for line in sock_file:
            line = line.strip()
            if line:
                print(line, flush=True)
    except Exception:
        pass
    finally:
        try:
            sock.close()
        except Exception:
            pass

def run_master_server():
    for p in (SOCKET_PATH, LEGACY_SOCKET):
        if os.path.exists(p) or os.path.islink(p):
            try:
                os.remove(p)
            except OSError:
                pass

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    try:
        os.symlink(SOCKET_PATH, LEGACY_SOCKET)
    except Exception:
        pass

    server.listen(10)
    server.setblocking(False)

    engine = PomodoroEngine()
    subscribers: list[socket.socket] = []

    def broadcast(json_str: str):
        print(json_str, flush=True)
        dead = []
        for sub in subscribers:
            try:
                sub.sendall((json_str + "\n").encode("utf-8"))
            except Exception:
                dead.append(sub)
        for d in dead:
            try:
                d.close()
            except Exception:
                pass
            if d in subscribers:
                subscribers.remove(d)

    # Initial output
    broadcast(engine.get_waybar_json())
    last_tick_time = time.time()

    while True:
        read_list = [server] + subscribers
        try:
            readable, _, _ = select.select(read_list, [], [], 0.2)
        except Exception:
            readable = []

        for sock in readable:
            if sock is server:
                try:
                    conn, _ = server.accept()
                    conn.setblocking(True)
                    data = conn.recv(1024).decode("utf-8").strip()
                    if not data:
                        conn.close()
                        continue

                    if data.startswith("SUBSCRIBE"):
                        conn.setblocking(False)
                        subscribers.append(conn)
                        try:
                            conn.sendall((engine.get_waybar_json() + "\n").encode("utf-8"))
                        except Exception:
                            pass
                    else:
                        parts = data.split(" ", 1)
                        action = parts[0].lower()
                        arg = parts[1] if len(parts) > 1 else ""

                        if action == "toggle":
                            engine.toggle()
                        elif action == "start":
                            engine.start()
                        elif action == "stop":
                            engine.stop()
                        elif action == "reset":
                            engine.reset()
                        elif action == "skip":
                            engine.skip()
                        elif action == "set-task":
                            engine.set_task(arg)
                        elif action in ("set-work", "work") and arg.isdigit():
                            engine.work_time = int(arg) * 60
                            engine.reset()
                        elif action in ("set-short", "shortbreak") and arg.isdigit():
                            engine.short_break_time = int(arg) * 60
                        elif action in ("set-long", "longbreak") and arg.isdigit():
                            engine.long_break_time = int(arg) * 60

                        try:
                            conn.sendall(b"OK\n")
                        except Exception:
                            pass
                        finally:
                            conn.close()

                        broadcast(engine.get_waybar_json())
                except Exception:
                    pass
            else:
                # Subscriber connection check
                try:
                    data = sock.recv(1024)
                    if not data:
                        if sock in subscribers:
                            subscribers.remove(sock)
                        sock.close()
                except Exception:
                    if sock in subscribers:
                        subscribers.remove(sock)
                    try:
                        sock.close()
                    except Exception:
                        pass

        # 1-second tick loop
        now = time.time()
        if now - last_tick_time >= 1.0:
            last_tick_time = now
            engine.tick()
            broadcast(engine.get_waybar_json())

def run_server():
    while True:
        sub_sock = try_connect_subscriber()
        if sub_sock:
            run_subscriber(sub_sock)
            time.sleep(0.3)
        else:
            try:
                run_master_server()
            except OSError:
                time.sleep(0.5)

def main():
    args = sys.argv[1:]
    if not args or args[0] == "server":
        run_server()
        return

    cmd = args[0].lower()

    if cmd in ("--help", "-h", "help"):
        print("Usage: waybar-module-pomodoro [options] [operation]")
        print("  Operations:")
        print("    toggle                     Toggle timer (start / pause)")
        print("    start                      Start timer")
        print("    stop                       Pause timer")
        print("    reset                      Reset current cycle to full duration")
        print("    skip                       Skip to next phase (Focus <-> Break)")
        print("    menu                       Open interactive Rofi menu (with Vault tasks)")
        print("    set-task <name>            Set active focus task")
        print("  Options:")
        print("    -w, --work <min>           Set work duration in minutes (default: 25)")
        print("    -s, --shortbreak <min>     Set short break in minutes (default: 5)")
        print("    -l, --longbreak <min>      Set long break in minutes (default: 15)")
        return

    i = 0
    while i < len(args):
        arg = args[i]
        if arg in ("-w", "--work") and i + 1 < len(args):
            send_command(f"set-work {args[i+1]}")
            i += 2
            continue
        elif arg in ("-s", "--shortbreak") and i + 1 < len(args):
            send_command(f"set-short {args[i+1]}")
            i += 2
            continue
        elif arg in ("-l", "--longbreak") and i + 1 < len(args):
            send_command(f"set-long {args[i+1]}")
            i += 2
            continue
        elif arg == "menu":
            open_rofi_menu()
            return
        elif arg in ("toggle", "start", "stop", "reset", "skip"):
            send_command(arg)
            return
        elif arg == "set-task":
            task_name = " ".join(args[i+1:]) if i + 1 < len(args) else "Foco Geral"
            send_command(f"set-task {task_name}")
            return
        else:
            send_command(arg)
            return
        i += 1

if __name__ == "__main__":
    main()

