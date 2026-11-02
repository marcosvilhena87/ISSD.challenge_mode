from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class DirectionOutput(unittest.TestCase):
 def test_final_gate(self):
  self.assertIn('if armed and buttons.B and not buttons.X', S)
  self.assertIn('local receiver=special or autopass.target',S)
  self.assertIn('pair_geometry(sample_for_auto,sender,receiver)',S)
 def test_actual_correction(self):
  self.assertIn('buttons.Up=nil;buttons.Down=nil;buttons.Left=nil;buttons.Right=nil',S)
  self.assertIn('buttons[g.direction]=true',S)
  self.assertIn('pass_direction_output',S)
  self.assertIn('requested_direction=',S)
  self.assertIn('calculated_direction=',S)
 def test_fail_closed(self):
  self.assertIn('buttons.B=nil',S)
  self.assertIn('pass_direction_blocked',S)
 def test_finish_preserved(self):
  self.assertIn('finish_x_output',S)
  self.assertIn('not buttons.X',S)
if __name__=="__main__":unittest.main()
