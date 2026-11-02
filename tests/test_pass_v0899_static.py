from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class Alignment(unittest.TestCase):
 def test_approach(self):
  self.assertIn('long_710.phase="align"',S)
  self.assertIn('buttons=approach_buttons(g)',S)
  self.assertIn('math.abs(align_g.dy)>100',S)
 def test_bounded_and_measured(self):
  self.assertIn('elapsed>=18 or walked>=42',S)
  self.assertIn('local gain=long_710.align_initial_gap-g.distance',S)
  self.assertIn('queue_alignment_result',S)
 def test_fallback(self):
  self.assertIn('long_710.align_no_progress>=3',S)
  self.assertIn('queue_alignment_fallback',S)
  self.assertIn('long_710.watchdog_release_until=frame+48',S)
 def test_safe_passing(self):
  self.assertIn('carrier_gap(sample_for_auto,long_710.origin)',S)
  self.assertIn('buttons={[long_710.direction]=true,B=true}',S)
if __name__=="__main__":unittest.main()
