from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class LastMissing(unittest.TestCase):
 def test_missing_only_one(self):
  self.assertIn('for id=2,11 do if not visited[id]',S)
  self.assertIn('if count==1 and holder~=absent then return absent end',S)
 def test_blocker_geometry(self):
  self.assertIn('projection>0.10 and projection<0.90',S)
  self.assertIn('if cross<=24 then return p.id,cross end',S)
  self.assertIn('long_pass_lane_blocked',S)
 def test_directional_B_and_confirmation(self):
  self.assertIn('buttons={[long_710.direction]=true,B=true}',S)
  self.assertIn('spatial.holder==long_710.target',S)
  self.assertIn('long_710_observation_timeout',S)
 def test_normal_route_kept(self):
  self.assertIn('Ordered.next(nil,7,spatial.visited)==10',S)
  self.assertIn('distance>=35 and distance<=410',S)
if __name__=="__main__":unittest.main()
