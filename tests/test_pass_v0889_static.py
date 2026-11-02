from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class SidestepNineSeven(unittest.TestCase):
 def test_97_trigger_and_bounded(self):
  self.assertIn('blocker and from==9 and target==7',S)
  self.assertIn('long_710.sidestep_97_count<4',S)
  self.assertIn('frame-long_710.walk_start<6',S)
  self.assertIn('relay_97_sidestep_exhausted',S)
 def test_telemetry(self):
  self.assertIn('relay_97_sidestep_started',S)
  self.assertIn('relay_97_sidestep_finished',S)
  self.assertIn('relay_97_sidestep_aborted',S)
  self.assertIn('"|dx="..delta_x',S)
  self.assertIn('"|previous_cross="',S)
 def test_fallback_and_pass(self):
  self.assertIn('and not long_710.sidestep_97_exhausted',S)
  self.assertIn('buttons={[long_710.direction]=true,B=true}',S)
  self.assertIn('long_710_motion_result',S)
if __name__=="__main__": unittest.main()
