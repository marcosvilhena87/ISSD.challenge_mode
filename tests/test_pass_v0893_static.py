from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class FastSupport(unittest.TestCase):
 def test_fast_pass(self):
  self.assertIn('relay_fast_directional_b',S)
  self.assertIn('long_710.fast_pass and elapsed<2',S)
  self.assertIn('buttons={[long_710.direction]=true,B=true}',S)
 def test_blocker_as_receiver(self):
  self.assertIn('local function support_receiver(sample,from,to,blocker)',S)
  self.assertIn('long_710.target=blocker',S)
  self.assertIn('relay_support_blocker_selected',S)
  self.assertIn('already_visited=',S)
  self.assertIn('count<2',S)
 def test_origin_possession_retained(self):
  self.assertIn('carrier_gap(sample_for_auto,long_710.origin)',S)
if __name__=="__main__": unittest.main()
