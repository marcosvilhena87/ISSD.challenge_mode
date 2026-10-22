"""Decode experimental DRIBBLE timer trace to BCD seconds and raw fractional counters.
Run: python decode_dribble_timers_v1.py [input.csv] [decoded.csv] [summary.csv]
No third-party dependencies; no emulator required.
"""
import csv
import sys
from pathlib import Path


def bcd(value):
    if value is None:
        return None
    value = int(value)
    hi, lo = value >> 4, value & 15
    return hi * 10 + lo if 0 <= hi <= 9 and 0 <= lo <= 9 else None


def decode(row):
    def num(name):
        raw = row.get(name, "")
        return int(raw) if raw not in ("", None) else None

    def word(start):
        low, high = num(f"b_014F{start:X}"), num(f"b_014F{start + 1:X}")
        return low + (high << 8) if low is not None and high is not None else None

    return {
        "time_seconds_bcd": bcd(num("b_014F0")),
        "bonus_seconds_bcd": bcd(num("b_014F4")),
        "time_fraction_u16": word(2),
        "bonus_fraction_u16": word(6),
        "time_fraction_hi": num("b_014F3"),
        "bonus_fraction_hi": num("b_014F7"),
    }


def value(x):
    return "" if x is None else str(x)


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    source = Path(argv[0]) if len(argv) > 0 else Path("dribble_timer_validation_v1.csv")
    dest = Path(argv[1]) if len(argv) > 1 else Path("dribble_timer_decoded_v1.csv")
    report = Path(argv[2]) if len(argv) > 2 else Path("dribble_timer_decoder_summary_v1.csv")
    if not source.is_file():
        raise SystemExit(f"Input CSV not found: {source}")
    with source.open(newline="", encoding="utf-8-sig") as handle:
        rows = [r for r in csv.DictReader(handle)
                if r.get("phase") in ("time_candidate", "bonus_candidate")]
    columns = ["session", "frame", "phase", "remaining", "time_seconds_bcd",
               "bonus_seconds_bcd", "time_fraction_u16", "bonus_fraction_u16",
               "time_fraction_hi", "bonus_fraction_hi", "status"]
    with dest.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        for row in rows:
            d = decode(row)
            writer.writerow({**{k: row.get(k, "") for k in columns[:4]},
                             **{k: value(v) for k, v in d.items()},
                             "status": "candidate_only"})
    fields = ["phase", "samples", "bcd_valid", "seconds_first", "seconds_last",
              "seconds_transitions", "fraction_transitions",
              "stable_seconds_frames", "transitions", "status"]
    with report.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for phase, sec, frac in [
            ("time_candidate", "time_seconds_bcd", "time_fraction_u16"),
            ("bonus_candidate", "bonus_seconds_bcd", "bonus_fraction_u16"),
        ]:
            group = [(r, decode(r)) for r in rows if r["phase"] == phase]
            changes, fchanges, same, transitions = 0, 0, 0, []
            for (prior_r, prior), (cur_r, cur) in zip(group, group[1:]):
                if prior[sec] != cur[sec]:
                    changes += 1
                    if len(transitions) < 20:
                        transitions.append(f"{cur_r['frame']}:{value(prior[sec])}>{value(cur[sec])}")
                else:
                    same += 1
                if prior[frac] != cur[frac]:
                    fchanges += 1
            stats = {
                "phase": phase, "samples": len(group),
                "bcd_valid": sum(d[sec] is not None for _, d in group),
                "seconds_first": value(group[0][1][sec]) if group else "",
                "seconds_last": value(group[-1][1][sec]) if group else "",
                "seconds_transitions": changes, "fraction_transitions": fchanges,
                "stable_seconds_frames": same, "transitions": ";".join(transitions),
                "status": "hypothesis_only",
            }
            writer.writerow(stats)
            print(f"[ISSD.decoder_v1] {phase} samples={len(group)} BCD={stats['bcd_valid']} "
                  f"seconds={stats['seconds_first']} -> {stats['seconds_last']} "
                  f"fraction_changes={fchanges}")
    print(f"[ISSD.decoder_v1] wrote {dest} and {report}")


if __name__ == "__main__":
    main()
