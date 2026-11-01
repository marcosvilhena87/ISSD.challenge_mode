from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassGoalEvidence(unittest.TestCase):
 def test_renamed_module_present(self):
  self.assertTrue((R/"lua/challenge/goal_evidence_v4.lua").exists())
  self.assertFalse((R/"lua/challenge/dribble_goal_evidence_v4.lua").exists())
  for p in ("lua/dribble_bot.lua","lua/goal_evidence_v4.lua","tests/test_dribble_goal_evidence_v4.lua"):
   self.assertIn("challenge.goal_evidence_v4",(R/p).read_text())
 def test_pass_observation(self):
  s=(R/"lua/challenge/pass_goal_evidence_v0826.lua").read_text()
  for x in ("Core.step(st.core,s)","WINDOW=300","pass_contextual_goal_candidate","no_increment_in_window"):
   self.assertIn(x,s)
  self.assertNotIn("Core.classify",s)
 def test_runner(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for x in ('"shot_x_issued"','"post_shot_sample"','"observation_window_closed"','"passive_counter_unverified_goal"'):
   self.assertIn(x,s)
  self.assertIn('goal_monitor=GoalEvidence.new',s)
if __name__=="__main__":unittest.main()
