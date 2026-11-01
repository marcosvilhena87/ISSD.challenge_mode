from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class DualGeometry(unittest.TestCase):
 def test_minor_axis_for_diagonal(self):
  s=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text()
  self.assertIn('why=="diagonal_risk"',s)
  self.assertIn('metrics.lateral>Feet.MAX_LATERAL',s)
  self.assertIn('math.abs(dx)<=math.abs(dy) and "x" or "y"',s)
  self.assertIn('state.best_lateral',s)
  self.assertIn('state.previous_lateral=lateral',s)
 def test_preserve_fluidity_and_progress(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  self.assertIn('buttons=new_buttons;reason="approach_step"',s)
  self.assertIn('"|best_lateral="',s)
  self.assertIn('cause=approach_duration',s)
  self.assertIn('pass_chain.approach_frames%20==0',s)
  self.assertIn('movement.burst_remaining=movement.burst_remaining-1',s)
if __name__=="__main__":unittest.main()
