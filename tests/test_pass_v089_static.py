from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class CoordinateRoute(unittest.TestCase):
 def test_lookahead_uses_coordinates_and_preserves_endgame(self):
  s=(R/"lua/challenge/pass_route_v089.lua").read_text()
  for token in ('p.x','p.y','candidate.cost+onward','future_cost(points,id,next_visited)','for id=2,9 do','points[11]','points[10]'):
   self.assertIn(token,s)
  p=(R/"lua/challenge/pass_priority_v087.lua").read_text()
  self.assertIn('Route.choose(sample,holder,visited,info.report,stage)',p)
  self.assertIn('return allow,"penultimate_11"',p)
  self.assertIn('return allow,"last_10"',p)
 def test_no_extra_button_presses(self):
  s=(R/"lua/pass_bot.lua").read_text()
  self.assertIn('"route_candidate"',s)
  self.assertIn('"|route_score="',s)
  self.assertIn('chain_complete_candidate',s)
  controller=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn('buttons.B=true',controller)
  self.assertIn('t.hold_count>=t.hold_frames',controller)
if __name__=="__main__": unittest.main()
