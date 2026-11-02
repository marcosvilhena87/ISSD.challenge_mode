from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
class TestV0869(unittest.TestCase):
 def test_right_regression_is_bounded(self):
  self.assertIn('VERSION="0.8.69"',O)
  self.assertIn('right_58_regressions',O)
  self.assertIn('right_transient_regression',O)
  self.assertIn('right_persistent_regression',O)
  self.assertIn('state.right_58_regressions>=3',O)
 def test_retry_and_diagnostics(self):
  self.assertIn('approach_58_controlled_retry',B)
  self.assertIn('used<2 and remaining>12',B)
  self.assertIn('Ordered.MAX_APPROACH_ABSOLUTE-(pass_chain.approach_frames or 0)',B)
  self.assertIn('pass_45_ball_relative_at_b',B)
 def test_prior_features(self):
  self.assertIn('early_710_execution',B)
  self.assertIn('facing_45_target_step',B)
  self.assertIn('finish_stadium_goal_audit',B)
  self.assertIn('primary_9_to_7',O)
if __name__=="__main__": unittest.main()
