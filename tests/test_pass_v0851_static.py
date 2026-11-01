from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
O=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
B=(ROOT/"lua/pass_bot.lua").read_text(encoding="utf-8")
F=(ROOT/"lua/challenge/pass_feet_v0815.lua").read_text(encoding="utf-8")
class V0851(unittest.TestCase):
 def test_geometric_priority(self):
  for token in ('VERSION="0.8.51"','holder==7 and target==10 and state and dx>20','local key="Right"','pair_710_coordinate_right','pair_710_limited_vertical_correction','right_stalls>=2'):
   self.assertIn(token,O)
 def test_feedback(self):
  for token in ('approach_710_steering_feedback','pair_710_right_stalls','pair_710_vertical_count','approach_710_relative_feedback'):
   self.assertIn(token,B)
 def test_regressions(self):
  self.assertIn('ROUTE={6,2,3,4,5,8,9,7,10,11}',O)
  self.assertIn('MIN_PASS_DISTANCE=24',F)
  self.assertIn('approach_67_relative_feedback',B)
  self.assertIn('approach_89_predicted_target',B)
if __name__=="__main__":unittest.main()
