from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
F=(R/"lua/challenge/pass_finish_v07.lua").read_text()
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
B=(R/"lua/pass_bot.lua").read_text()
class TestV0860(unittest.TestCase):
 def test_goal_guard(self):
  for token in ('VERSION="0.8.60"','function M.geometry(sample)','goalkeeper_coordinate_mismatch','invalid_coordinate_domain','math.abs(dx)>1024','math.abs(dy)>512'):
   self.assertIn(token,F)
  self.assertIn('if not geometry then t.enabled=false;return {},geometry_reason end',F)
 def test_six_seven(self):
  self.assertIn('pair_67_cardinal_recovery',O)
  self.assertIn('pair_67_cardinal_attempts or 0)<8',O)
  self.assertIn('approach_67_cardinal_retry',B)
  self.assertIn('movement.pair_67_cardinal_flip=1',B)
 def test_existing_behavior(self):
  self.assertIn('primary_9_to_7',O)
  self.assertIn('fallback_6_to_7',O)
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
  self.assertIn('GoalEvidence.step(goal_monitor,g)',B)
  self.assertIn('pass_shot_trajectory_v0859.csv',B)
if __name__=="__main__":unittest.main()
