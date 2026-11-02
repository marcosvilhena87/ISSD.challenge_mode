from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
class DashGuard(unittest.TestCase):
 def test_short_dash(self):
  self.assertIn('desired_burst=8',B)
  self.assertIn('buttons.Y=true',B)
  self.assertIn('VERSION="0.8.74"',O)
 def test_ball_proximity_and_recovery(self):
  for marker in ('ball_gap_710','approach_710_ball_gap','approach_710_dash_ball_pause','approach_710_dash_ball_recovered','approach_710_dash_ball_unrecovered'):
   self.assertIn(marker,B)
  self.assertIn('movement.dash_ball_pause=3',B)
  self.assertIn('gap<=18',B)
 def test_existing_guards(self):
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
  self.assertIn('Early.TARGET_DISTANCE==160',B)
  self.assertIn('buttons.Y and (buttons.B or buttons.X',B)
if __name__=="__main__": unittest.main()
