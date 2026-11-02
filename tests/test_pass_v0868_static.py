from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
A=(R/"lua/challenge/pass_auto_v071.lua").read_text(encoding="utf-8")
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
E=(R/"lua/challenge/pass_early_v0865.lua").read_text(encoding="utf-8")
class TestEarly710ExecutionV0868(unittest.TestCase):
 def test_flag_is_transferred(self):
  self.assertIn("early_710_trial=true",B)
  self.assertIn("t.early_710_trial=(plan and plan.early_710_trial==true",A)
 def test_guard_and_b(self):
  self.assertIn('Early.evaluate(sample,7,10,Early.MIN_APPROACH,false)',A)
  self.assertIn('safe=true;why="early_710_guarded_geometry"',A)
  self.assertIn('if safe and not t.early_710_trial then',A)
  self.assertIn('buttons.B=true',A)
  self.assertIn('MAX_DISTANCE=420',E)
 def test_trace_and_preservation(self):
  self.assertIn('"early_710_execution"',B)
  self.assertIn('"facing_45_target_step"',B)
  self.assertIn('"finish_stadium_goal_audit"',B)
  self.assertIn('VERSION="0.8.68"',O)
if __name__=="__main__": unittest.main()
