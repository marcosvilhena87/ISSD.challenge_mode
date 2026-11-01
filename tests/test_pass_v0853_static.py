from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
F=(R/"lua/challenge/pass_feet_v0815.lua").read_text(encoding="utf-8")
class V0853(unittest.TestCase):
 def test_up_right_geometry(self):
  for x in ('VERSION="0.8.53"','holder==6 and target==7 and state and dx>8 and dy< -8','pair_67_up_right_approach','return {Up=true,Right=true},"approach_step",metrics','pair_67_diagonal_disabled'):
   self.assertIn(x,O)
 def test_feedback(self):
  for x in ('approach_67_diagonal_feedback','movement.pair_67_diagonal_trials','movement.pair_67_diagonal_disabled=true','motion.holder_dx','motion.holder_dy'):
   self.assertIn(x,B)
 def test_existing(self):
  self.assertIn('ROUTE={6,2,3,4,5,8,9,7,10,11}',O)
  self.assertIn('route_67_continuity',B)
  self.assertIn('approach_67_neutral_wait',B)
  self.assertIn('MIN_PASS_DISTANCE=24',F)
if __name__=="__main__":unittest.main()
