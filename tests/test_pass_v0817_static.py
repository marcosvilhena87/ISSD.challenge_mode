from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class BallAlignment(unittest.TestCase):
 def test_cross_product_and_near_ball(self):
  s=(R/"lua/challenge/pass_alignment_ball_v0817.lua").read_text()
  for term in ("MAX_BALL_OFFSET=18","MAX_LINE_ERROR=12","MAX_BEHIND=5",
               "math.abs(ox*vy-oy*vx)/length","ball_not_at_feet",
               "ball_behind_carrier","ball_off_pass_axis"):
   self.assertIn(term,s)
 def test_before_b_and_selection(self):
  a=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  r=(R/"lua/challenge/pass_relay_v0810.lua").read_text()
  self.assertIn("BallLine.check(sample,t.origin,t.target)",a)
  self.assertIn("BallLine.check(sample,holder,id)",r)
  self.assertIn('return empty,"retarget_requested_"..why',a)
if __name__=="__main__":unittest.main()
