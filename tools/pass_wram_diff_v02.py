"""Compare controlled 128-KiB WRAM snapshots; candidates are hypotheses, not proof."""
import argparse
import json
from pathlib import Path

SIZE = 0x20000

def read(path):
    data = Path(path).read_bytes()
    if len(data) != SIZE:
        raise ValueError(f"{path}: expected 131072 bytes, got {len(data)}")
    return data

def compare(before, after):
    a, b = read(before), read(after)
    changes = [i for i in range(SIZE) if a[i] != b[i]]
    runs = []
    for address in changes:
        if runs and address == runs[-1][-1] + 1:
            runs[-1].append(address)
        else:
            runs.append([address])
    # Isolated, narrow transitions are good starting points for testing counters/ownership.
    ranked = sorted(runs, key=lambda run: (len(run), run[0]))
    return {
        "before": str(before), "after": str(after),
        "bytes_changed": len(changes),
        "candidate_regions": [
            {"offset_hex": f"0x{run[0]:05X}", "length": len(run),
             "before_hex": a[run[0]:run[-1]+1].hex(),
             "after_hex": b[run[0]:run[-1]+1].hex()}
            for run in ranked[:200]
        ],
        "warning": "Changes may reflect animation, timers, ball, unrelated entities or stale data. Validate with repeated control experiments."
    }

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before")
    parser.add_argument("after")
    parser.add_argument("--output", default="pass_wram_candidates_v02.json")
    args = parser.parse_args()
    report = compare(args.before, args.after)
    Path(args.output).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"{report['bytes_changed']} bytes changed; report: {args.output}")

if __name__ == "__main__":
    main()
