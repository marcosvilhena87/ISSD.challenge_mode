from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class ScoreRelayV0911(unittest.TestCase):
 def test_score_guards(self):
  self.assertIn("score_armed_baseline",S)
  self.assertIn("score_result_stable>=3",S)
  self.assertIn("pass_score_wram_correlated",S)
  self.assertIn("a~=nil and b~=nil and c~=nil and d==c",S)
 def test_relay_cost(self):
  self.assertIn("relay_saves>=35",S)
  self.assertIn("support_g.distance<=185",S)
  self.assertIn("remaining.distance<=185",S)
  self.assertIn("time_score_relay_rejected",S)
 def test_preserves_finish(self):
  self.assertIn("finish_x_verified_output",S)
  self.assertIn("best_cost+25<reference",S)
if __name__=="__main__": unittest.main()
