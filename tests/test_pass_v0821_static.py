from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class DirectionCalibration(unittest.TestCase):
 def test_cardinal_and_diagonal_modes(self):
  s=(ROOT/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('t.calibration_mode=="A"',s)
  self.assertIn('buttons[toward(origin,dest)]=true',s)
  self.assertIn('elseif direction=="AUTO" then',s)
  self.assertIn('#t.early_flight<18',s)
 def test_commands_logs_and_one_approach_input(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  for x in ('cmd=="CALIB:A"','cmd=="CALIB:B"','"early_flight"','next_auto.calibration_mode=calibration_mode'):
   self.assertIn(x,s)
  self.assertNotIn('log_input(emu.framecount(),"approach",reason,holder,target,buttons)',s)
if __name__=="__main__":unittest.main()
