from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
B=(ROOT/"lua/pass_bot.lua").read_text(encoding="utf-8")
O=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
class V0877(unittest.TestCase):
 def test_direction_only(self):
  self.assertIn('movement.experimental_dash_710_enabled==true',B)
  self.assertNotIn('phase="..((math.floor((pass_chain.approach_frames or 0)/8)',B)
  self.assertIn('DIRECTION_ONLY_V0877',B)
 def test_measured_telemetry(self):
  for event in ['approach_710_relative_closure','approach_710_receiver_slow_window','approach_710_actual_input']:
   self.assertIn(event,B)
  self.assertIn('actual_Y=',B)
  self.assertIn('holder_vx-receiver_vx',B)
 def test_guards_and_repeat(self):
  self.assertIn('repeat_710_started',B)
  self.assertIn('spatial.visited[10] and not spatial.visited[11]',B)
  self.assertIn('MAX_APPROACH_ABSOLUTE=210',O)
  self.assertIn('VERSION="0.8.77"',O)
if __name__=="__main__":unittest.main()
