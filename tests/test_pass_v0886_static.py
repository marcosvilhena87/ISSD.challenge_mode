from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class PriorityRecovery(unittest.TestCase):
 def test_exclusive_last(self):
  self.assertIn('local priority_missing=last_missing_710',S)
  self.assertIn('and not priority_lock',S)
  self.assertIn('last_missing_710(spatial.visited,spatial.holder)',S)
 def test_lateral_release(self):
  self.assertIn('long_710.phase="sidestep"',S)
  self.assertIn('long_710.walk_ticks<4',S)
  self.assertIn('frame-long_710.walk_start<6',S)
  self.assertIn('last_missing_sidestep_finished',S)
 def test_return(self):
  self.assertIn('long_710.last_holder==10 and spatial.holder==7',S)
  self.assertIn('long_710.return_due=true',S)
  self.assertIn('long_710.returns<1',S)
  self.assertIn('return_7_to_10',S)
  self.assertIn('buttons={[long_710.direction]=true,B=true}',S)
 def test_no_fake_success(self):
  self.assertIn('confidence=spatial_only',S)
  self.assertIn('long_710_observation_timeout',S)
if __name__=="__main__":unittest.main()
