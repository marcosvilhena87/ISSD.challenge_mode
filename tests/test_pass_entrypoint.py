from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class PassEntrypointTests(unittest.TestCase):
    def test_mode_is_routed(self):
        main = (ROOT / "main.lua").read_text(encoding="utf-8")
        self.assertIn('value~="PASS"', main)
        self.assertIn('if mode=="PASS" then', main)
        self.assertIn('dofile(file("lua/pass_bot.lua"))', main)

    def test_runner_is_safe_observation_only(self):
        runner = (ROOT / "lua/pass_bot.lua").read_text(encoding="utf-8")
        self.assertIn('p.challenge=="PASS" and p.level==1', runner)
        self.assertIn('joypad.set({},1)', runner)
        self.assertNotIn('memory.write_', runner)
        self.assertIn('pass_lv1_observations_v01.csv', runner)

if __name__ == "__main__":
    unittest.main()
