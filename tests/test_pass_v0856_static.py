from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
class V0856(unittest.TestCase):
 def test_bounded_checkpoints(self):
  for s in ('VERSION="0.8.56"','function M.goalward_checkpoint(state,frames,measurement)','pair_710_checkpoints or 0)>=2','baseline-measurement.distance<25','frames>=M.MAX_APPROACH_ABSOLUTE'):
   self.assertIn(s,O)
  self.assertIn('approach_710_goalward_checkpoint',B)
 def test_goalward_is_hypothesis(self):
  self.assertIn('approach_710_goalward_feedback',B)
  self.assertIn('receiver_goalward_candidate=',B)
  self.assertIn('movement.target=target',B)
  self.assertIn('approach_target_joypad_commit',B)
 def test_inherited(self):
  self.assertIn('primary_9_to_7',O)
  self.assertIn('fallback_6_to_7',O)
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
  self.assertIn('pair_67_up_right_approach',O)
if __name__=="__main__":unittest.main()
