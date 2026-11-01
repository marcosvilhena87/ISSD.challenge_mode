from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
E=(R/"lua/challenge/pass_early_v0865.lua").read_text()
B=(R/"lua/pass_bot.lua").read_text()
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
class TestEarlyPassV0865(unittest.TestCase):
 def test_guard(self):
  for token in ['MIN_APPROACH=24','MAX_DISTANCE=420','MAX_LATERAL=160','holder~=7','target~=10','ball_not_at_feet']:
   self.assertIn(token,E)
 def test_integration(self):
  self.assertIn('Early.evaluate(sample_for_auto,holder,10',B)
  self.assertIn('pass_chain.early_710_used=true',B)
  self.assertIn('early_710_trial',B)
  self.assertIn('movement.burst_remaining',B)
  self.assertIn('GoalEvidence.step(goal_monitor,g)',B)
 def test_priorities(self):
  self.assertIn('VERSION="0.8.65"',O)
  self.assertIn('primary_9_to_7',O)
  self.assertIn('CONTINUOUS_HOLD_710=24',O)
if __name__=="__main__":unittest.main()
