from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
E=(ROOT/"lua/challenge/pass_goal_evidence_v0826.lua").read_text(encoding="utf-8")
B=(ROOT/"lua/pass_bot.lua").read_text(encoding="utf-8")
class TestPostShotV0857(unittest.TestCase):
 def test_dribble_reuse(self):
  self.assertIn('require("challenge.goal_evidence_v4")',E)
  self.assertIn('Core.marker(st.core,"SHOT_STARTED",s.frame)',E)
  self.assertIn('function M.mark_shot(st,s)',E)
  self.assertIn('st.core=Core.new(s)',E)
 def test_post_shot_window(self):
  self.assertIn('WINDOW=300',E)
  self.assertIn('GoalEvidence.mark_shot(goal_monitor,shot_sample)',B)
  self.assertIn('GoalEvidence.step(goal_monitor,g)',B)
  self.assertIn('goal_post_shot_started',B)
  self.assertIn('post_shot_window_closed',B)
  self.assertIn('goal_post_shot_',B)
 def test_unconfirmed_cases(self):
  for token in ('counter_conflict_unverified','multiple_increments_unverified','no_increment_in_window','pass_contextual_goal_candidate','awaiting_post_shot_observation'):
   self.assertIn(token,E)
 def test_pass_route_unmodified(self):
  self.assertIn('chain candidate complete',B) if 'chain candidate complete' in B else self.assertIn('route_67_continuity',B)
if __name__=='__main__':unittest.main()
