from pathlib import Path
import unittest
B=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class ShortWalkRange(unittest.TestCase):
 def test_walk_bounded(self):
  self.assertIn('walk_frames=12,max_walk=24',B)
  self.assertIn('static_710.phase="walk"',B)
  self.assertIn('walked>=static_710.max_walk',B)
  self.assertIn('spatial.holder~=7',B)
 def test_pass_and_trajectory(self):
  for x in ("static_710_short_walk_finished","static_710_short_walk_aborted",
            "static_710_range_pass_pulse","static_710_ball_trajectory",
            "static_710_range_observation_finished"):
   self.assertIn(x,B)
  self.assertIn('static_710.ball_max=math.max',B)
  self.assertIn('static_710.closest_10=math.min',B)
  self.assertIn('frame-(static_710.shot_frame or frame)>=122',B)
if __name__=="__main__":unittest.main()
