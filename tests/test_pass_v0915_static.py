from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class AdaptiveV0915(unittest.TestCase):
 def test_vertical_first_only_six(self):
  self.assertIn("if from==6 and math.abs(geom.dy)>95 then",S)
  self.assertIn("geom.distance>220 and math.abs(geom.dx)>75",S)
 def test_fallback_limits(self):
  self.assertIn("elapsed>=(from==6 and 66 or 78)",S)
  self.assertIn('reason="vertical_stall"',S)
  self.assertIn('ctrl.last_vertical_progress',S)
 def test_five_to_eight_preserved(self):
  self.assertIn("spatial.holder==5 and not spatial.visited[8]",S)
  self.assertIn("exclusive_receiver=to",S)
 def test_boundary_and_score(self):
  self.assertIn("chain_completion_clock_evidence",S)
  self.assertIn("pass_score_wram_correlated",S)
if __name__=="__main__":unittest.main()
