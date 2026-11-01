from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
S=(R/"lua/challenge/pass_spatial_v04.lua").read_text(encoding="utf-8")
F=(R/"lua/challenge/pass_finish_v07.lua").read_text(encoding="utf-8")
class TestV0861(unittest.TestCase):
 def test_diagonal_priority(self):
  self.assertIn('VERSION="0.8.61"',O)
  self.assertIn('state.direction="Up_Right"',O)
  self.assertIn('(state.pair_67_diagonal_trials or 0)<6',O)
  self.assertIn('movement.pair_67_diagonal_regressions',B)
  self.assertIn('movement.pair_67_diagonal_stalls',B)
  self.assertIn('>=3',B)
 def test_goal_audit_and_guard(self):
  self.assertIn('M.goalkeeper={id=1,x=0x052A,y=0x052C}',S)
  self.assertIn('finish_goalkeeper_wram_audit',B)
  self.assertIn('goal_reference=unverified',B)
  self.assertIn('goalkeeper_coordinate_mismatch',F)
 def test_stable_route(self):
  self.assertIn('primary_9_to_7',O)
  self.assertIn('fallback_6_to_7',O)
  self.assertIn('GoalEvidence.step(goal_monitor,g)',B)
if __name__=="__main__":unittest.main()
