"""Persistent, session-targeted operator confirmation for DRIBBLE v0.3.2.
Works even after BizHawk closes. Never treats gameplay exit as confirmed goal.
"""
import argparse
import csv
import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path

FIELDS = ("session", "outcome", "evidence", "record_score")

def update(summary, session, goal=False, score=None):
    summary = Path(summary)
    if not summary.is_file():
        raise ValueError(f"Summary not found: {summary}")
    with summary.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        cols = reader.fieldnames
        if not cols or any(k not in cols for k in FIELDS):
            raise ValueError("Unexpected summary CSV schema")
        rows = list(reader)
    matches = [r for r in rows if r["session"] == session]
    if len(matches) != 1:
        raise ValueError(f"Session {session!r}: expected exactly 1 row, found {len(matches)}")
    row = matches[0]
    old = {k: row[k] for k in FIELDS[1:]}
    if goal:
        row["outcome"] = "goal_confirmed_operator"
        row["evidence"] = "operator_visual_confirmation"
    if score is not None:
        if not goal and row["outcome"] != "goal_confirmed_operator":
            raise ValueError("Score requires --confirm-goal, or a previously confirmed goal")
        if score < 0:
            raise ValueError("Score must be nonnegative")
        row["record_score"] = str(score)
    new = {k: row[k] for k in FIELDS[1:]}
    if old == new:
        return False, new
    fd, temp = tempfile.mkstemp(prefix=".dribble_summary_", suffix=".tmp", dir=str(summary.parent))
    try:
        with os.fdopen(fd, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=cols)
            writer.writeheader()
            writer.writerows(rows)
            f.flush()
            os.fsync(f.fileno())
        os.replace(temp, summary)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)
    audit = summary.with_name("dribble_bot_score_audit_v032.csv")
    audit_exists = audit.is_file() and audit.stat().st_size > 0
    with audit.open("a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        if not audit_exists:
            writer.writerow(["timestamp_utc", "session", "old_outcome", "new_outcome", "old_score", "new_score", "evidence"])
        writer.writerow([datetime.now(timezone.utc).isoformat(), session, old["outcome"], new["outcome"],
                         old["record_score"], new["record_score"], new["evidence"]])
    return True, new

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--summary", default="dribble_bot_summary_v032.csv")
    p.add_argument("--session", required=True, help="Exact session from summary CSV")
    p.add_argument("--confirm-goal", action="store_true", help="Only after verifying the record screen for this attempt")
    p.add_argument("--score", type=int)
    args = p.parse_args()
    if not args.confirm_goal and args.score is None:
        p.error("Provide --confirm-goal and/or --score")
    try:
        changed, data = update(args.summary, args.session, args.confirm_goal, args.score)
    except ValueError as e:
        p.error(str(e))
    print(("Updated" if changed else "Already up-to-date") + f": session={args.session} outcome={data['outcome']} score={data['record_score']}")

if __name__ == "__main__":
    main()
