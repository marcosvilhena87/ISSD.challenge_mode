from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
ORDERED=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
BOT=(ROOT/"lua/pass_bot.lua").read_text(encoding="utf-8")
AUTO=(ROOT/"lua/challenge/pass_auto_v071.lua").read_text(encoding="utf-8")

class TestV0843(unittest.TestCase):
    def test_pair_89_uses_measured_motion(self):
        for item in ('VERSION="0.8.43"','holder==8 and target==9','state.motion[name]','pair_8_9_measured_cardinal','pair_89_last_bad_direction','pair_8_9_no_blind_recovery'):
            self.assertIn(item,ORDERED)
        self.assertIn('dx>10 and dy< -10',ORDERED)
    def test_early_stop_and_logs(self):
        for item in ('approach_89_feedback','approach_89_regression_stop','movement.pair_89_regression or 0)>=2','movement.pair_89_total_growth or 0)>24'):
            self.assertIn(item,BOT)
    def test_other_pairs_unchanged(self):
        self.assertIn('return {Up=true},"pre_up_step"',AUTO)
        self.assertIn('if t.origin==6 and t.target==3 then buttons={Up=true} end',AUTO)
        self.assertIn('return {Down=true},"pre_down_step"',AUTO)
        self.assertIn('local desired_burst=',BOT)
        self.assertIn('movement.right_followup_left=3',BOT)

if __name__=="__main__":
    unittest.main()
