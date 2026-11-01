from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class TriggerDiagnostic(unittest.TestCase):
 def test_delay_is_neutral_and_configurable(self):
  s=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('t.phase=="prewait"',s)
  self.assertIn('return empty,"trigger_pre_wait"',s)
  self.assertIn('t.prewait_until=frame+t.trigger_delay',s)
  self.assertIn('buttons.B=true',s)
 def test_command_and_per_frame_telemetry(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for token in ('cmd=="TRIGGER:A" or cmd=="TRIGGER:B"','trigger_mode=="B" and 12 or 0',
                'pass_trigger_v0811.csv','trigger_write(emu.framecount()',
                'ball and ball.x','hp and hp.x','buttons.B and 1 or 0'):
   self.assertIn(token,s)
  self.assertIn('limit=18',s)
if __name__=="__main__": unittest.main()
