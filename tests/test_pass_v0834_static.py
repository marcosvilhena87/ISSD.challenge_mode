from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassV0834(unittest.TestCase):
 def test_recent_distance_progress(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for term in ('VERSION="0.8.34"','state.recent_progress>=2','recent_progress_verified','(state.recent_extension_count or 0)<2','state.previous_distance-d>0.5'):
   self.assertIn(term,s)
 def test_two_step_pre_down_and_release(self):
  s=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  for term in ('t.phase=="pre_down"','t.pre_down_frames>=2','return {Down=true},"pre_down_step"','t.phase=="pre_down_release"','return empty,"pre_down_release"','t.origin==4 and t.target==5'):
   self.assertIn(term,s)
  self.assertIn('buttons.B=true',s)
 def test_integration(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for term in ('approach_recent_progress','movement.recent_extension_count','pre_down_step','pre_down_release','autopass.direction="Down"','GoalEvidence.step(goal_monitor,goal_sample)'):
   self.assertIn(term,s)
if __name__=="__main__": unittest.main()
