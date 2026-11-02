from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
class TestV0875(unittest.TestCase):
 def test_stall_fallback(self):
  self.assertIn('movement.stall_710_frames',B)
  self.assertIn('movement.dash_710_disabled=true',B)
  self.assertIn('approach_710_dash_stall_fallback',B)
  self.assertIn('approach_710_direction_only',B)
 def test_dash_disabled(self):
  self.assertIn('not movement.dash_710_disabled and not buttons.B',B)
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
  self.assertIn('VERSION="0.8.75"',O)
if __name__=="__main__":unittest.main()
