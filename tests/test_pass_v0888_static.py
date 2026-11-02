from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class RelayNineSeven(unittest.TestCase):
 def test_priority(self):
  self.assertIn('local relay_97=pass_chain.active and spatial.holder==9 and not spatial.visited[7]',S)
  self.assertIn('priority_missing~=nil or relay_97',S)
  self.assertIn('(spatial.holder==9 and not spatial.visited[7])',S)
 def test_route(self):
  self.assertIn('from==9 and not spatial.visited[7] and 7',S)
  self.assertIn('"relay_9_to_7"',S)
  self.assertIn('"relay_97_started"',S)
  self.assertIn('buttons={[long_710.direction]=true,B=true}',S)
 def test_continuation(self):
  self.assertIn('long_710_advance_finished',S)
  self.assertIn('long_710_motion_result',S)
  self.assertIn('long_pass_rearmed',S)
if __name__=="__main__":unittest.main()
