from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
B=(ROOT/"lua/pass_bot.lua").read_text(encoding="utf-8")
O=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
class TestV0880(unittest.TestCase):
 def test_neutral_watchdog(self):
  self.assertIn('approach_710_neutral_watchdog',B)
  self.assertIn('st.pair_710_output_neutral>=5',B)
  self.assertIn('st.burst_remaining=0;st.burst_buttons=nil',B)
 def test_invalid_coordinates_fail_closed(self):
  self.assertIn('not (p.x==0 and p.y==0)',O)
  self.assertIn('return {},"invalid_coordinates"',O)
  self.assertIn('if not v then\n      buttons={}',B)
  self.assertIn('approach_710_invalid_coordinates',B)
 def test_limits_and_repeat(self):
  self.assertIn('VERSION="0.8.80"',O)
  self.assertIn('MAX_APPROACH_710_ABSOLUTE=480',O)
  self.assertIn('repeat_710_started',B)
if __name__=="__main__":unittest.main()
