from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class FacingV0814(unittest.TestCase):
 def test_orientation_before_B(self):
  s=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  for p in ('facing_frames=4','t.phase=="face"','return buttons,"facing_directional"',
            't.phase=="face_release"','return empty,"facing_release"',
            't.phase="face"','buttons.B=true'):
   self.assertIn(p,s)
  self.assertLess(s.index('if t.phase=="face"'),s.index('if t.phase=="hold"'))
 def test_logged_and_selftest(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for p in ('"facing_directional"','"facing_release"','autopass.phase=="face"'):
   self.assertIn(p,s)
  bridge=(R/"lua/challenge/pass_bridge_v083.lua").read_text()
  self.assertIn('pulses==3',bridge)
if __name__=="__main__":unittest.main()
