from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassV0833(unittest.TestCase):
 def test_routing_and_direction_guards(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  self.assertIn('VERSION="0.8.33"',s)
  self.assertIn('ROUTE={6,3,2,4,5,8,9,7,10,11}',s)
  self.assertIn('holder==5 and target==8',s)
  self.assertIn('(target==2 or target==3)',s)
 def test_probe_neutral_precedes_timeout(self):
  s=(R/"lua/pass_bot.lua").read_text()
  a=s.index('if movement.recovery_phase=="awaiting_sample"')
  b=s.index('if (pass_chain.approach_frames or 0)>=approach_limit and not pass_chain.approach_neutral')
  self.assertLess(a,b)
  for x in ('movement.recovery_phase="awaiting_sample"','movement.recovery_phase="evaluated"','approach_probe_failed','approach_probe_result','first_pass_right_suppressed','GoalEvidence.step(goal_monitor,goal_sample)'):
   self.assertIn(x,s)
if __name__=="__main__": unittest.main()
