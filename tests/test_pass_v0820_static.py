from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class OrderedApproach(unittest.TestCase):
 def test_route(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  self.assertIn("ROUTE={6,2,3,4,5,8,9,7,10,11}",s)
  self.assertIn('holder~=M.ROUTE[index]',s)
  self.assertIn('MAX_APPROACH=90',s)
  self.assertIn('ball_not_at_feet',s)
 def test_gate_and_progress(self):
  runner=(R/"lua/pass_bot.lua").read_text()
  for x in ('"approach_step"','"approach_neutral"','"approach_timeout"',
            '"route_advanced"','"route_deviation"','pass_chain.route_index'):
   self.assertIn(x,runner)
  self.assertIn('buttons,reason=Ordered.step',runner)
 def test_exact_target(self):
  p=(R/"lua/challenge/pass_priority_v087.lua").read_text()
  self.assertIn('Ordered.next(route_index,holder)',p)
  self.assertIn('"approach_required"',p)
  self.assertNotIn('Relay.choose',p)
if __name__=="__main__":unittest.main()
