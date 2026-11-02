from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
S=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
F=(R/"lua/challenge/pass_finish_v07.lua").read_text(encoding="utf-8")
class FinishReloadV0907(unittest.TestCase):
 def test_reload(self):
  self.assertIn('package.loaded["challenge.pass_finish_v07"]=nil',S)
  self.assertIn('Finish.VERSION=="0.9.7"',S)
  self.assertIn('finish_version=',S)
 def test_bounded_approach(self):
  self.assertIn('VERSION="0.9.7"',F)
  self.assertIn('MAX_APPROACH_FRAMES=210',F)
  self.assertIn('if gap>M.MAX_GOALKEEPER_X then',F)
  self.assertIn('if not holder_found then',F)
 def test_shot_audit(self):
  self.assertIn('finish_x_verified_output',S)
  self.assertIn('goal_post_shot_started',S)
  self.assertIn('shot_x_issued',S)
 def test_preserve_chain(self):
  self.assertIn('possession_gate_fast_recovery',S)
  self.assertIn('pass_clock_started',S)
if __name__=="__main__": unittest.main()
