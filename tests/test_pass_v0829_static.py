from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class V0829(unittest.TestCase):
 def test_feedback_partial_progress_and_delay(self):
  s=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for key in ('VERSION="0.8.29"','delta_distance>0.5 or delta_lateral>0.5',
              'delta_distance< -0.5 and delta_lateral< -0.5',
              'state.zero_bursts>=3','direction_pending_feedback',
              'direction_partial_progress'):
   self.assertIn(key,s)
 def test_up_b_pair_only(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  self.assertIn('if autopass.origin==6 and autopass.target==2 then',s)
  self.assertIn('autopass.direction="Up"',s)
  self.assertIn('pass_direction_override',s)
  self.assertIn('direction=Up|button=B|policy=pair_6_2_only',s)
  self.assertIn('GoalEvidence.step(goal_monitor,goal_sample)',s)
if __name__=="__main__":unittest.main()
