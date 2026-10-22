import csv
import tempfile
import unittest
from pathlib import Path
from confirm_dribble_score_v032 import update

class PersistentScoreTests(unittest.TestCase):
    def test_session_specific_idempotent_and_audited(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "dribble_bot_summary_v032.csv"
            with f.open("w", newline="", encoding="utf-8") as h:
                w = csv.DictWriter(h, fieldnames=["session", "outcome", "evidence", "record_score", "flags_remaining"])
                w.writeheader()
                w.writerow(dict(session="a_10", outcome="unverified", evidence="no_verified_goal_flag", record_score="", flags_remaining="0"))
                w.writerow(dict(session="b_20", outcome="unverified", evidence="no_verified_goal_flag", record_score="", flags_remaining="0"))
            changed, result = update(f, "a_10", goal=True, score=403)
            self.assertTrue(changed)
            self.assertEqual(result["record_score"], "403")
            changed, _ = update(f, "a_10", goal=True, score=403)
            self.assertFalse(changed)
            with f.open(newline="", encoding="utf-8") as h:
                rows = list(csv.DictReader(h))
            self.assertEqual(rows[1]["outcome"], "unverified")
            with (Path(d) / "dribble_bot_score_audit_v032.csv").open(newline="", encoding="utf-8") as h:
                self.assertEqual(len(list(csv.DictReader(h))), 1)
            with self.assertRaises(ValueError):
                update(f, "nonexistent", goal=True, score=1)
            with self.assertRaises(ValueError):
                update(f, "b_20", score=404)

if __name__ == "__main__":
    unittest.main()
