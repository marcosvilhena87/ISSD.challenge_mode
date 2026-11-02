from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class ProgressAwareV0916(unittest.TestCase):
 def test_priorities(self):
  self.assertIn("spatial.holder==6 and not spatial.visited[2]",S)
  self.assertIn("spatial.holder==5 and not spatial.visited[8]",S)
 def test_progress_fallback(self):
  self.assertIn('ctrl.worse_frames>=5',S)
  self.assertIn('reason="distance_increasing"',S)
  self.assertIn('reason="poor_progress"',S)
 def test_vertical_bias(self):
  self.assertIn('math.abs(geom.dy)<=math.abs(geom.dx)*0.8',S)
 def test_preserved(self):
  self.assertIn('chain_completion_clock_evidence',S)
  self.assertIn('finish_x_verified_output',S)
if __name__=="__main__":unittest.main()
