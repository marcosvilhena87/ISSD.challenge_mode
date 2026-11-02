from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
class Dash710(unittest.TestCase):
 def test_dash_scope(self):
  self.assertIn('holder==7 and target==10 and not buttons.B',B)
  self.assertIn('buttons.Y=true',B)
  self.assertIn('approach_710_dash_start',B)
 def test_release_and_direction(self):
  self.assertIn('buttons.Y and (buttons.B or buttons.X',B)
  self.assertIn('buttons.Y=nil',B)
  self.assertIn('{"Right","Left","Up","Down"}',B)
 def test_existing_limits(self):
  self.assertIn('VERSION="0.8.73"',O)
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
  self.assertIn('Early.TARGET_DISTANCE==160',B)
if __name__=="__main__":unittest.main()
