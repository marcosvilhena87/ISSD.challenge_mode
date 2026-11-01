from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class FeetPassV0815(unittest.TestCase):
 def test_limits_and_target_motion(self):
  s=(ROOT/"lua/challenge/pass_feet_v0815.lua").read_text()
  for term in ('MAX_RANGE=190','MAX_LATERAL=72','MAX_DRIFT=32',
               '"too_far"','"diagonal_risk"','"target_moved"','"feet_candidate"'):
   self.assertIn(term,s)
 def test_filters_before_ranking_and_B(self):
  relay=(ROOT/"lua/challenge/pass_relay_v0810.lua").read_text()
  auto=(ROOT/"lua/challenge/pass_auto_v071.lua").read_text()
  runner=(ROOT/"lua/pass_bot.lua").read_text()
  self.assertIn('Feet.check(sample,holder,id)',relay)
  self.assertIn('Feet.check(sample,id,goal)',relay)
  self.assertIn('Feet.check(sample,t.origin,t.target,t.feet_initial)',auto)
  self.assertIn('t.hold_count==0',auto)
  self.assertIn('feet_pass_rejected_',auto)
  self.assertIn('feet_pass_rejected',runner)
  self.assertIn('feet_route_blocked',runner)
if __name__=="__main__": unittest.main()
