from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class V0831(unittest.TestCase):
 def test_recovery_is_bounded_and_learned(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for x in ('VERSION="0.8.31"','function M.recover','state.recovery_left=16','state.recovery_used','no_improving_learned_vector','function M.interposition','holder==6 and target==2 and key=="Right"'):
   self.assertIn(x,s)
 def test_runtime_guards(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for x in ('Ordered.recover(movement,measurement,holder,target)','approach_recovery_started','interposition_right_suppressed','interposition_6_3_2','movement.recovery_left=movement.recovery_left-1','autopass.direction="Up"','autopass.direction="Down"','GoalEvidence.step(goal_monitor,goal_sample)'):
   self.assertIn(x,s)
if __name__=="__main__":unittest.main()
