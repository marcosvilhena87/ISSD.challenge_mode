from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
class TestPassV085(unittest.TestCase):
 def test_wait_until_holder_stable(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  self.assertIn('local holder_pending=armed and autopass.enabled and not auto_finished',s)
  self.assertIn('and autopass.phase=="idle" and not spatial.holder',s)
  self.assertIn('and (spatial.holder or autopass.phase~="idle") then',s)
  self.assertIn('emu.framecount()-autopass.start_frame>=180',s)
  self.assertIn('holder_detection_timeout',s)
 def test_no_change_to_pass_inputs(self):
  s=(ROOT/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('buttons.B=true',s)
  self.assertIn('t.tries=1',s)
if __name__=="__main__":
 unittest.main()
