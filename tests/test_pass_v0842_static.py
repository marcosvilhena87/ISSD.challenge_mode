from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
AUTO = (ROOT / "lua/challenge/pass_auto_v071.lua").read_text(encoding="utf-8")
BOT = (ROOT / "lua/pass_bot.lua").read_text(encoding="utf-8")

class TestPassV0842(unittest.TestCase):
    def test_up_orientation_only_then_release(self):
        self.assertIn('return {Up=true},"pre_up_step"', AUTO)
        self.assertIn('t.pre_up_frames>=2', AUTO)
        self.assertIn('t.phase="hold";return empty,"pre_up_release"', AUTO)
    def test_up_plus_b_and_no_neutral_b(self):
        self.assertIn('if t.origin==6 and t.target==3 then buttons={Up=true} end', AUTO)
        self.assertIn('buttons.B=true', AUTO)
        self.assertNotIn('if t.origin==6 and t.target==3 then buttons={} end', AUTO)
        self.assertIn('if not (buttons.Left or buttons.Right or buttons.Up or buttons.Down) then', AUTO)
    def test_no_auto_rotation_but_retain_feet_safety(self):
        self.assertIn('alignment_reason=="ball_off_pass_axis"', AUTO)
        self.assertIn('distance(origin,ball)>18', AUTO)
        self.assertIn('Feet.check(sample,t.origin,t.target,t.feet_initial)', AUTO)
    def test_other_pairs_and_v0840_preserved(self):
        self.assertIn('return {Down=true},"pre_down_step"', AUTO)
        self.assertIn('t.origin==4 and t.target==5', AUTO)
        self.assertIn('autopass.direction="Down"', BOT)
        self.assertIn('movement.right_followup_left=3', BOT)
        self.assertIn('local desired_burst=', BOT)

if __name__ == "__main__":
    unittest.main()
