from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
G=(R/"lua/challenge/pass_goal_evidence_v0826.lua").read_text(encoding="utf-8")
class TestPassV0858(unittest.TestCase):
 def test_separate_progress(self):
  self.assertIn('VERSION="0.8.58"',O)
  self.assertIn('(state.pair_710_recent_net_gain or 0)>=8',O)
  self.assertIn('measurement.distance<=state.best_distance+12',O)
  self.assertIn('approach_710_net_progress',B)
  self.assertIn('movement.pair_710_net_samples',B)
  self.assertIn('if #net>4 then table.remove(net,1) end',B)
 def test_context_preserved(self):
  self.assertIn('primary_9_to_7',O)
  self.assertIn('fallback_6_to_7',O)
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
  self.assertIn('GoalEvidence.mark_shot(goal_monitor,shot_sample)',B)
  self.assertIn('GoalEvidence.step(goal_monitor,g)',B)
  self.assertIn('require("challenge.goal_evidence_v4")',G)
if __name__=='__main__': unittest.main()
