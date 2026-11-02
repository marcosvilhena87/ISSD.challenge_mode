from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class FinalTarget(unittest.TestCase):
 def test_precedence(self):
  self.assertIn('local target=missing or (long_710.return_due and from==7 and 10)',S)
  self.assertIn('local target=last_missing_710(spatial.visited,spatial.holder) or long_710.target',S)
 def test_state(self):
  for event in ('final_target_changed','final_holder_changed','final_stale_target_cleared','final_retry_rearmed'):
   self.assertIn(event,S)
 def test_support_retained(self):
  self.assertIn('relay_support_blocker_selected',S)
  self.assertIn('long_710.target=blocker',S)
 def test_possession(self):
  self.assertIn('carrier_gap(sample_for_auto,long_710.origin)',S)
if __name__=="__main__":unittest.main()
