from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class V0832(unittest.TestCase):
 def test_route_and_recovery(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for x in ('VERSION="0.8.32"','ROUTE={6,3,2,4,5,8,9,7,10,11}','state.recovery_exploratory=true','state.recovery_exploratory and 4 or 16','state.recovery_probe_failed'):
   self.assertIn(x,s)
 def test_integration(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for x in ('approach_probe_failed','approach_probe_result','approach_direction_still','approach_recovery_started','autopass.direction="Down"','GoalEvidence.step(goal_monitor,goal_sample)'):
   self.assertIn(x,s)
if __name__=="__main__":unittest.main()
