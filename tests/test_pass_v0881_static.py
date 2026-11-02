from pathlib import Path
import unittest
B=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class StaticRange710(unittest.TestCase):
 def test_trigger_and_freeze(self):
  self.assertIn('static_710.phase=="await_7" and spatial.holder==7',B)
  self.assertIn('gap<=18',B)
  self.assertIn('pass_chain.active=false',B)
  self.assertIn('autopass.enabled=false',B)
 def test_once_and_release(self):
  self.assertIn('static_710.phase="observe";buttons={}',B)
  self.assertIn('static_710.phase="finished"',B)
  self.assertIn('static_710_range_pass_pulse',B)
  self.assertIn('static_710_range_started',B)
 def test_observation(self):
  self.assertIn('frame-static_710.started>=127',B)
  self.assertIn('static_710_range_observation_finished',B)
if __name__=="__main__":unittest.main()
