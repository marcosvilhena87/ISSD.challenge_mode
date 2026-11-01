from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class V0828(unittest.TestCase):
 def test_dual_cost_and_feedback(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for x in ('VERSION="0.8.28"','math.max(0,distance-Feet.MAX_RANGE)','math.max(0,lateral-Feet.MAX_LATERAL)','function M.observe','direction_worsened','direction_improved','no_direction_improves','state.penalties[key]'):
   self.assertIn(x,s)
 def test_runner_records_measured_feedback(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for x in ('movement.burst_start=initial','movement.burst_direction=key','approach_direction_feedback','approach_no_improvement','Ordered.can_extend','GoalEvidence.step(goal_monitor,goal_sample)'):
   self.assertIn(x,s)
if __name__=="__main__": unittest.main()
