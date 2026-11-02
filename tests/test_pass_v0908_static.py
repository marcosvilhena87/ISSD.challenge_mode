from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf8")
class PassFirstV0908(unittest.TestCase):
 def test_selector(self):
  self.assertIn("local function pass_first_target(sample,from,visited)",S)
  self.assertIn("g.distance<=185",S)
  self.assertIn("not lane_blocker(sample,from,id)",S)
  self.assertIn("not visited[id]",S)
 def test_fallback(self):
  self.assertIn("local queue_target=pass_first or first_unvisited",S)
  self.assertIn('"time_score_pass_first"',S)
 def test_metrics(self):
  self.assertIn('"time_score_new_visitor"',S)
  self.assertIn("frames_since_last=",S)
 def test_success_path_unchanged(self):
  self.assertIn("finish_x_verified_output",S)
  self.assertIn("finish_version=",S)
  self.assertIn("pass_clock_started",S)
if __name__=="__main__":unittest.main()
