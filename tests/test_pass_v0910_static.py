from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf8")
class ScoreMonitorV0910(unittest.TestCase):
 def test_addresses(self):
  for a in ["0x01CF3","0x01CF8","0x01CFA","0x0DC06"]: self.assertIn(a,S)
 def test_passive_and_arithmetic(self):
  self.assertIn("local function score_log(",S)
  self.assertIn("c==a+b",S)
  self.assertIn("c==d",S)
  self.assertIn("pass_score_wram_v0910.csv",S)
 def test_slow_segment(self):
  self.assertIn("elapsed>=180",S)
  self.assertIn("time_score_slow_segment",S)
 def test_preserve_v0909(self):
  self.assertIn("best_cost+25<reference",S)
  self.assertIn("finish_x_verified_output",S)
if __name__=="__main__":unittest.main()
