from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class OrderedQueue(unittest.TestCase):
 def test_queue(self):
  self.assertIn('local function first_unvisited(visited,holder)',S)
  self.assertIn('for id=2,11 do',S)
  self.assertIn('local target=queue_target or missing',S)
 def test_support_quality(self):
  self.assertIn('remaining.distance+12<distance',S)
  self.assertIn('next_leg.distance+12<distance',S)
  self.assertIn('no_queue_progress',S)
 def test_observability(self):
  self.assertIn('queue_target_changed',S)
  self.assertIn('queue_holder_changed',S)
  self.assertIn('first_unvisited(spatial.visited,spatial.holder) or long_710.target',S)
 def test_existing(self):
  self.assertIn('carrier_gap(sample_for_auto,long_710.origin)',S)
  self.assertIn('universal_support_planned',S)
if __name__=="__main__": unittest.main()
