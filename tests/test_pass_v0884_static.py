from pathlib import Path
import unittest
B=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class TestLong710(unittest.TestCase):
 def test_direction_and_b(self):
  self.assertIn('buttons={[long_710.direction]=true,B=true}',B)
  self.assertIn('long_710_directional_b',B)
  self.assertIn('simultaneous=true',B)
 def test_geometry(self):
  self.assertIn('distance>=180 and distance<=410',B)
  self.assertIn('math.abs(dy)<=100',B)
  self.assertIn('gap<=18',B)
 def test_finite_and_resumes(self):
  self.assertIn('long_710_observation_timeout',B)
  self.assertIn('long_710_receiver_observed',B)
  self.assertIn('frame-(long_710.shot_frame or frame)>=120',B)
  self.assertIn('pass_chain.next_frame=frame+1',B)
  self.assertIn('long_710.phase="done"',B)
 def test_preserve_repeat(self):
  self.assertIn('pass_chain.repeat_710_started and not pass_chain.repeat_710_used',B)
if __name__=="__main__":unittest.main()
