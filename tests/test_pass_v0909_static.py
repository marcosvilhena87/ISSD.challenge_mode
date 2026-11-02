from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class RouteCommitV0909(unittest.TestCase):
 def test_lookahead(self):
  self.assertIn("local function pass_first_target(sample,from,visited)",S)
  self.assertIn("next_cost*0.65",S)
  self.assertIn("best_cost+25<reference",S)
 def test_commit(self):
  self.assertIn('long_710.queue_commit_holder==spatial.holder',S)
  self.assertIn('long_710.queue_commit_target=queue_target',S)
  self.assertIn('autopass.phase~="idle"',S)
 def test_reference_preserved(self):
  self.assertIn('first_unvisited(spatial.visited,spatial.holder)',S)
  self.assertIn('finish_x_verified_output',S)
  self.assertIn('pass_clock_started',S)
if __name__=="__main__":unittest.main()
