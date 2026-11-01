from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassV0839(unittest.TestCase):
 def test_coordinate_rules(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for t in ('VERSION="0.8.39"','dx>20','direction="Right"','dx>10 and dy< -10','direction="Up_Right"','if holder==5 and target==8 and dx>0'):
   self.assertIn(t,s)
 def test_prolonged_and_logged(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for t in ('buttons.Right) and 8','approach_coordinate_decision','buttons=movement.burst_buttons','approach_right_settle','approach_right_frame','pre_down_step','approach_diagonal_started'):
   self.assertIn(t,s)
if __name__=="__main__":unittest.main()
