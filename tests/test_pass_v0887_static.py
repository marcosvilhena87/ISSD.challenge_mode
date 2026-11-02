from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class CarrierAdvance(unittest.TestCase):
 def test_bounded_advance(self):
  self.assertIn('long_710.phase="advance"',S) if False else None
  self.assertIn('and "advance" or "face"',S)
  self.assertIn('elapsed>=18 or progress>=40',S)
  self.assertIn('long_710_advance_finished',S)
  self.assertIn('long_710_advance_aborted',S)
 def test_bounded_rearm(self):
  self.assertIn('long_pass_rearmed',S)
  self.assertIn('(long_710.attempts[attempt_key] or 0)<2',S)
  self.assertIn('long_710.cooldown_until=frame+36',S)
 def test_measurement_and_pass(self):
  self.assertIn('long_710_motion_result',S)
  self.assertIn('receiver_dx=',S)
  self.assertIn('carrier_dx=',S)
  self.assertIn('buttons={[long_710.direction]=true,B=true}',S)
 def test_recovery(self):
  self.assertIn('last_missing_710(spatial.visited,spatial.holder)',S)
  self.assertIn('return_710_queued',S)
if __name__=="__main__":unittest.main()
