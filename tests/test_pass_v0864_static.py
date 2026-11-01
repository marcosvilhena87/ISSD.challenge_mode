from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
M=(R/"lua/challenge/pass_reach_v0863.lua").read_text(encoding="utf-8")
class TestV0864(unittest.TestCase):
 def test_four_indicators(self):
  for x in ["carrier_walk","receiver_walk","closest_ball_receiver_gap","combined_walk","ball_path","initial_gap"]:
   self.assertIn(x,B)
  self.assertIn('pass_reach_v0864.csv',B)
 def test_receiver_tracking(self):
  for x in ['f.receiver_walk=f.receiver_walk+', 'f.closest_gap=math.min', 'f.combined_walk=f.walk+f.receiver_walk','direct_candidate','adjusted_candidate','other_or_no_receiver']:
   self.assertIn(x,M)
 def test_preserves_control(self):
  self.assertIn('CONTINUOUS_HOLD_710', (R/"lua/challenge/pass_ordered_v0820.lua").read_text())
  self.assertIn('GoalEvidence.step(goal_monitor,g)',B)
if __name__=="__main__":unittest.main()
