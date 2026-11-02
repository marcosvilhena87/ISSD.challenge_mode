from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
EARLY=(ROOT/"lua/challenge/pass_early_v0865.lua").read_text(encoding="utf-8")
BOT=(ROOT/"lua/pass_bot.lua").read_text(encoding="utf-8")
ORDERED=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")

class TestV0870(unittest.TestCase):
    def test_close_range_gate(self):
        self.assertIn('VERSION="0.8.70"', EARLY)
        self.assertIn('TARGET_DISTANCE=160,MAX_DISTANCE=180,MAX_LATERAL=100', EARLY)
        self.assertIn('m.distance> M.MAX_DISTANCE', EARLY)
        self.assertIn('m.lateral>M.MAX_LATERAL', EARLY)
    def test_normal_plan_cannot_bypass_gate(self):
        self.assertIn('plan and plan.target==10', BOT)
        self.assertIn('close.distance>Early.MAX_DISTANCE', BOT)
        self.assertIn('close.lateral>Early.MAX_LATERAL', BOT)
        self.assertIn('selector_reason="approach_required"', BOT)
        self.assertIn('bridge_info.target=10', BOT)
    def test_telemetry_and_prior_safety(self):
        self.assertIn('"approach_710_close_gate"', BOT)
        self.assertIn('early_710_guard_out_of_band', BOT)
        self.assertIn('approach_58_controlled_retry', BOT)
        self.assertIn('MAX_APPROACH_ABSOLUTE=210', ORDERED)
        self.assertIn('VERSION="0.8.70"', ORDERED)

if __name__=="__main__":
    unittest.main()
