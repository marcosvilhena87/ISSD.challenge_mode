from pathlib import Path
import unittest
s=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf8")
class WatchdogDirections(unittest.TestCase):
 def test_watchdog(self):
  self.assertIn('queue_watchdog_release',s)
  self.assertIn('wd_frame-long_710.watchdog_last_action>=90',s)
  self.assertIn('wd_released=wd_frame<long_710.watchdog_release_until',s)
  self.assertIn('not priority_lock',s)
 def test_queue_order(self):
  self.assertIn('first_unvisited(spatial.visited,spatial.holder)',s)
  self.assertIn('local target=queue_target or missing',s)
 def test_pair_direction(self):
  self.assertIn('local routing_g=pair_geometry(sample_for_auto,from,target)',s)
  self.assertIn('local function approach_buttons(g)',s)
  self.assertIn('buttons={[long_710.direction]=true,B=true}',s)
 def test_diagnostics(self):
  self.assertIn('queue_route_diagnostic',s)
  self.assertIn('lateral_alignment',s)
if __name__=="__main__":unittest.main()
