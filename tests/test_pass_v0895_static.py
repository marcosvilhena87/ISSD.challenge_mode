from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf8")
class PlanningSupport(unittest.TestCase):
 def test_support_at_planning(self):
  self.assertIn('local support_g=support_receiver(sample_for_auto,from,target,blocker)',S)
  self.assertIn('long_710.phase="face"',S)
  self.assertIn('"final_support_planned"',S)
 def test_limit_and_route(self):
  self.assertIn('support_count<2',S)
  self.assertIn('long_710.original_target=missing or target',S)
  self.assertIn('long_710.support_target=blocker',S)
  self.assertIn('final_support_received',S)
 def test_final_target(self):
  self.assertIn('local target=missing or (long_710.return_due',S)
  self.assertIn('final_target_changed',S)
  self.assertIn('final_support_rejected',S)
 def test_passthrough(self):
  self.assertIn('carrier_gap(sample_for_auto,long_710.origin)',S)
  self.assertIn('relay_fast_directional_b',S)
if __name__=="__main__":unittest.main()
