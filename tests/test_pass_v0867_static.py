from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
A=(R/"lua/challenge/pass_auto_v071.lua").read_text(encoding="utf-8")
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
class TestFacingV0867(unittest.TestCase):
 def test_target_specific_facing(self):
  self.assertIn('t.facing_direction=toward(origin,dest)',A)
  self.assertIn('return {[t.facing_direction]=true},"pre_down_step"',A)
  self.assertIn('t.phase="hold";return empty,"pre_down_release"',A)
  self.assertIn('if t.pre_down_frames>=2',A)
 def test_telemetry(self):
  self.assertIn('"facing_45_target_step"',B)
  self.assertIn('"facing_45_release"',B)
  self.assertIn('pass_reach_v0864.csv',B)
 def test_other_passes_preserved(self):
  self.assertIn('VERSION="0.8.67"',O)
  self.assertIn('primary_9_to_7',O)
  self.assertIn('CONTINUOUS_HOLD_710=24',O)
  self.assertIn('finish_stadium_goal_audit',B)
if __name__=="__main__":unittest.main()
