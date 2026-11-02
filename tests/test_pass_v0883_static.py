from pathlib import Path
import unittest
B=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class DirectionalPass(unittest.TestCase):
 def test_simultaneous_input(self):
  self.assertIn('buttons={[static_710.direction]=true,B=true}',B)
  self.assertNotIn('buttons={B=true}\n        if not static_710.shot_frame',B)
  self.assertIn('buttons_simultaneous=true',B)
  self.assertIn('static_710_actual_input',B)
 def test_movement(self):
  self.assertIn('requested_direction=',B)
  self.assertIn('"|dx="..tostring(coords.hx-static_710.initial.hx)',B)
  self.assertIn('"|dy="..tostring(coords.hy-static_710.initial.hy)',B)
  self.assertIn('walk_frames=12,max_walk=24',B)
 def test_single_observation(self):
  self.assertIn('static_710_ball_trajectory',B)
  self.assertIn('static_710_range_observation_finished',B)
if __name__=="__main__":unittest.main()
