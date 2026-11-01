from pathlib import Path
import unittest
root=Path(__file__).resolve().parents[1]
bridge=(root/"lua/challenge/pass_bridge_v083.lua").read_text()
feet=(root/"lua/challenge/pass_feet_v0815.lua").read_text()
class SelftestMinGap(unittest.TestCase):
 def test_fixture_separation(self):
  self.assertIn('x=id*40,y=0',bridge)
  self.assertIn('ball={x=240,y=0}',bridge)
  self.assertIn('MIN_PASS_DISTANCE=24',feet)
  self.assertGreaterEqual(40,24)
 def test_still_requires_three_directional_pass_frames(self):
  self.assertIn('assert(pulses==3',bridge)
  self.assertIn('assert(keys.Up or keys.Down or keys.Left or keys.Right',bridge)
if __name__=="__main__": unittest.main()
