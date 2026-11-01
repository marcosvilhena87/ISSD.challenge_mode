from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class AdaptiveRoute(unittest.TestCase):
 def test_ordered_unvisited(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  self.assertIn("ROUTE={6,2,3,4,5,8,9,7,10,11}",s)
  self.assertIn('not visited[id]',s)
  self.assertIn('"all_visited"',s)
  self.assertNotIn('unexpected_holder',s)
 def test_continue_after_unexpected_receiver(self):
  s=(R/"lua/pass_bot.lua").read_text()
  self.assertIn('"route_recovered"',s)
  self.assertIn('recovery=continue',s)
  self.assertIn('pass_chain.approach_frames=0',s)
  p=(R/"lua/challenge/pass_priority_v087.lua").read_text()
  self.assertIn('Ordered.next(route_index,holder,visited)',p)
if __name__=="__main__":unittest.main()
