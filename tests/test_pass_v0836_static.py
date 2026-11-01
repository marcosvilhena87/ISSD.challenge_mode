from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassV0836(unittest.TestCase):
 def test_right_priority_is_conditional(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for term in ('VERSION="0.8.36"','holder==5 and target==8','not state.right_suspended','function M.guard_right','distance_change>2','actual_projection< -0.5','right_progress_streak','right_still','state.right_suspended=true'):
   self.assertIn(term,s)
 def test_runtime_and_prior_features(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for term in ('approach_right_feedback','Ordered.guard_right(movement,measurement','approach_diagonal_started','pre_down_step','GoalEvidence.step(goal_monitor,goal_sample)'):
   self.assertIn(term,s)
if __name__=="__main__":unittest.main()
