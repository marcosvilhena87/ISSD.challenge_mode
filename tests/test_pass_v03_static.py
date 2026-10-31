from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
class PassV03Tests(unittest.TestCase):
    def test_pure_monitor_has_stability_gate(self):
        code=(ROOT/"lua/challenge/pass_possession_monitor_v03.lua").read_text(encoding="utf-8")
        self.assertIn('self.count<self.minimum',code)
        self.assertIn('stable_value_change',code)
        self.assertIn('unverified_possession_candidate',code)
    def test_runner_monitor_does_not_automate_passes(self):
        code=(ROOT/"lua/pass_bot.lua").read_text(encoding="utf-8")
        self.assertIn('0x00A6',code)
        self.assertIn('pass_possession_v03.csv',code)
        self.assertIn('Possession.new({minimum=3})',code)
        self.assertIn('joypad.set({},1)',code)
        self.assertNotIn('memory.write_',code)
if __name__ == "__main__":
    unittest.main()
