from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassV0840(unittest.TestCase):
 def test_progress_vs_still(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for token in ('VERSION="0.8.40"','right_lateral_progress','persistent_horizontal_still','state.right_still>=3','metrics.lateral < state.burst_start.lateral-0.5'):
   self.assertIn(token,s)
 def test_burst_limit_and_neutral_followup(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for token in ('local desired_burst=','and 8 or Ordered.BURST_FRAMES','local recovery_cap=','math.min(desired_burst,','movement.right_followup_left=3','approach_right_followup','buttons=movement.burst_buttons','GoalEvidence.step(goal_monitor,goal_sample)'):
   self.assertIn(token,s)
if __name__=="__main__":unittest.main()
