from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class PassV0835(unittest.TestCase):
 def test_diagonal_policy(self):
  s=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for token in ('VERSION="0.8.35"','holder==8 and target==9','return {Up=true,Right=true},"approach_step"','function M.guard_diagonal','state.diagonal_disabled=true','Up_Right={1,-1}'):
   self.assertIn(token,s)
 def test_run_integration_and_existing_safeguards(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  for token in ('approach_diagonal_started','approach_diagonal_feedback','movement.burst_direction="Up_Right"','Ordered.guard_diagonal(movement,measurement)','buttons={Up=true,Right=true}','pre_down_step','GoalEvidence.step(goal_monitor,goal_sample)'):
   self.assertIn(token,s)
if __name__=="__main__":unittest.main()
