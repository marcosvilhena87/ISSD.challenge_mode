from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf8")
class ExclusiveV0913(unittest.TestCase):
 def test_arbitration_location(self):
  self.assertLess(S.index('exclusive_6_to_2_started'),S.index('-- v0.9.1: final output gate'))
  self.assertIn('local receiver=exclusive_pass_62 and 2 or special or autopass.target',S)
 def test_limits(self):
  for item in ['elapsed>=54','carrier>18','geom.distance>320','geom.distance<=175','math.abs(geom.dy)<=95','not lane_blocker(sample_for_auto,6,2)']:
   self.assertIn(item,S)
 def test_single_pulse_and_fallback(self):
  self.assertIn('exclusive_62.state="done"',S)
  self.assertIn('"exclusive_6_to_2_B"',S)
  self.assertIn('"exclusive_6_to_2_fallback"',S)
 def test_finish_unchanged(self):
  self.assertIn('finish_x_verified_output',S)
if __name__=="__main__": unittest.main()
