from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class PassV0912(unittest.TestCase):
 def test_priority(self):
  self.assertIn("spatial.holder==6 and not spatial.visited[2]",S)
  self.assertIn("priority_62.distance<=240",S)
  self.assertIn('queue_target=2',S)
  self.assertIn('"priority_6_to_2"',S)
 def test_relay(self):
  self.assertIn("local function preemptive_relay(",S)
  self.assertIn("not lane_blocker(sample,from,id)",S)
  self.assertIn("not lane_blocker(sample,id,target)",S)
  self.assertIn("preemptive_relay_candidate",S)
 def test_baseline(self):
  self.assertIn("best_cost+25<reference",S)
  self.assertIn("finish_x_verified_output",S)
  self.assertIn("pass_score_wram_correlated",S)
if __name__=="__main__": unittest.main()
