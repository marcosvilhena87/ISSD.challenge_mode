from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
class TestV0862(unittest.TestCase):
 def test_continuous_hold(self):
  for token in ('VERSION="0.8.62"','CONTINUOUS_HOLD_710=24','CONTINUOUS_HOLD_67=12'):
   self.assertIn(token,O)
  self.assertIn('desired_burst=Ordered.CONTINUOUS_HOLD_710',B)
  self.assertIn('desired_burst=Ordered.CONTINUOUS_HOLD_67',B)
  self.assertIn('approach_continuous_hold_started',B)
  self.assertIn('approach_continuous_hold_ended',B)
 def test_revalidation_and_safety(self):
  self.assertIn('local new_buttons,check=Ordered.step(sample_for_auto,holder,target,movement)',B)
  self.assertIn('buttons=movement.burst_buttons',B)
  self.assertIn('movement.burst_remaining=movement.burst_remaining-1',B)
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
  self.assertIn('primary_9_to_7',O)
  self.assertIn('fallback_6_to_7',O)
  self.assertIn('GoalEvidence.step(goal_monitor,g)',B)
if __name__=="__main__":unittest.main()
