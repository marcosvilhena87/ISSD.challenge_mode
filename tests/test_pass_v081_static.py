from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class Pass081(unittest.TestCase):
 def test_simultaneous_pad_and_b(self):
  s=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('buttons.B=true',s)
  self.assertIn('no_direction_for_pass',s)
  self.assertIn('buttons.Left or buttons.Right or buttons.Up or buttons.Down',s)
  self.assertIn('math.abs(dx)>=math.abs(dy)',s)
  self.assertIn('t.tries=1',s)
 def test_inputs_logged(self):
  s=(R/"lua/pass_bot.lua").read_text()
  self.assertIn('pass_inputs_v081.csv',s)
  self.assertIn('log_input(emu.framecount()',s)
  self.assertIn('reason=="no_valid_target"',s)
  self.assertNotIn('memory.write_',s)
if __name__=="__main__": unittest.main()
