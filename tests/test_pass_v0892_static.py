from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class OriginPossession(unittest.TestCase):
 def test_actual_origin(self):
  self.assertIn('local gap=carrier_gap(sample_for_auto,long_710.origin)',S)
  self.assertNotIn('if long_710.phase=="face" then\n      local gap=ball_gap_710(sample_for_auto)',S)
 def test_distinct_failures(self):
  for reason in ('holder_changed','invalid_coordinates','missing_ball_or_origin','ball_out_of_range'):
   self.assertIn('failure="'+reason+'"',S)
  self.assertIn('"|actual_holder="..tostring(spatial.holder)',S)
 def test_release_and_pass(self):
  self.assertIn('relay_lane_open_pass_queued',S)
  self.assertIn('buttons={[long_710.direction]=true,B=true}',S)
  self.assertIn('relay_pass_cancelled_blocker',S)
 def test_other_players(self):
  self.assertIn('long_710.origin,long_710.target',S)
  self.assertIn('relay_97_started',S)
if __name__=="__main__":unittest.main()
