"""Repair missing headers in v035 CSVs without discarding observations.

Run with: python repair_dribble_csv_v035.py
Stop the Lua runner before executing this script.
"""
import csv
import pathlib
import re
import shutil

ROOT = pathlib.Path(__file__).resolve().parent.parent
CSV_DIR = ROOT / "csv"
RUNNER = (ROOT / "lua" / "dribble_bot.lua").read_text(encoding="utf-8")
PATTERN = re.compile(r'setup\(csv_dir\.\."/([^"]+)"\s*,\s*"([^"]+)"\)')
# Include standalone local variables trace / summary.
HEADERS = {name: header for name, header in PATTERN.findall(RUNNER)}
HEADERS["dribble_bot_trace_v035.csv"] = (
    "session,frame,armed,phase,event,reason,gs,ptr,remaining,poss,player_x,player_y,"
    "ball_x,ball_y,buttons,time_bcd,bonus_bcd,time_frac_u16,bonus_frac_u16,recovery_diagnostics"
)
HEADERS["dribble_bot_summary_v035.csv"] = (
    "session,started_frame,flags_frame,shot_frame,exit_frame,flags_elapsed_frames,"
    "goal_elapsed_frames,total_elapsed_frames,flags_remaining,time_start_bcd,"
    "time_at_fifth_bcd,bonus_at_fifth_bcd,time_at_exit_bcd,bonus_at_exit_bcd,"
    "shot_attempts,exit_reason,outcome,evidence,record_score"
)
def main():
    for name, header in sorted(HEADERS.items()):
        path = CSV_DIR / name
        if not path.exists():
            continue  # New runner will create it with the correct header.
        raw = path.read_bytes()
        if not raw:
            print(f"EMPTY (will replace): {name}")
            path.write_bytes((header + "\n").encode("utf-8"))
            continue
        first = raw.splitlines()[0].decode("utf-8-sig", errors="replace").strip("\r\n")
        if first == header:
            if raw.startswith(b"\xef\xbb\xbf"):
                backup = path.with_name(path.name + ".bak")
                shutil.copy2(path, backup)
                path.write_bytes(raw[3:])
                print(f"BOM FIXED: {name} (backup: {backup.name})")
            else:
                print(f"OK: {name}")
            continue
        first_count = len(next(csv.reader([first])))
        expected_count = len(next(csv.reader([header])))
        if first_count != expected_count:
            print(f"MANUAL REVIEW: {name} first row has {first_count} columns; expected {expected_count}. Not modified.")
            continue
        backup = path.with_name(path.name + ".bak")
        shutil.copy2(path, backup)
        path.write_bytes((header + "\n").encode("utf-8") + raw)
        print(f"HEADER RESTORED: {name} (backup: {backup.name})")
if __name__ == "__main__":
    main()
