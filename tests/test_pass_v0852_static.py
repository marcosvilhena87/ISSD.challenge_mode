from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
B=(R/"lua/pass_bot.lua").read_text()
F=(R/"lua/challenge/pass_feet_v0815.lua").read_text()
class TestV0852(unittest.TestCase):
 def test_67_after_62(self):
  self.assertIn('VERSION="0.8.52"',O)
  self.assertIn('ROUTE={6,2,3,4,5,8,9,7,10,11}',O)
  self.assertIn('function M.can_relay_six_seven(holder,visited)',O)
  self.assertIn('return holder==6 and not (visited and visited[7])',O)
  self.assertIn('route_67_continuity',B)
  self.assertIn('pass_chain.approach_state={}',B)
 def test_neutral_window(self):
  for k in ('pair_67_settle_left=2','approach_67_neutral_wait','approach_67_delayed_motion','Ordered.capture(sample_for_auto,holder,target)','movement.pair_67_settle_left=nil'):
   self.assertIn(k,B)
 def test_invariants(self):
  self.assertIn('MIN_PASS_DISTANCE=24',F)
  self.assertIn('approach_710_steering_feedback',B)
  self.assertIn('approach_89_predicted_target',B)
if __name__=="__main__":unittest.main()
