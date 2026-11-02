from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class CoordinateRouting(unittest.TestCase):
 def test_coordinate_convention(self):
  self.assertIn('local dx,dy=xy.tx-xy.hx,xy.ty-xy.hy',S)
  self.assertIn('dx>=0 and "Right" or "Left"',S)
  self.assertIn('dy>=0 and "Down" or "Up"',S)
 def test_all_player_telemetry(self):
  self.assertIn('local function pair_geometry(sample,from,to)',S)
  self.assertIn('"relay_coordinates"',S)
  self.assertIn('"|tx="..g.xy.tx',S)
  self.assertIn('"|ty="..g.xy.ty',S)
 def test_corridor_choice(self):
  self.assertIn('local function lane_escape(sample,from,to)',S)
  self.assertIn('{"Up",0,-12}',S)
  self.assertIn('{"Down",0,12}',S)
  self.assertIn('{"Left",-12,0}',S)
  self.assertIn('{"Right",12,0}',S)
  self.assertIn('long_710.walk_dir=lane_escape(sample_for_auto,from,target)',S)
 def test_directional_pass(self):
  self.assertIn('buttons={[long_710.direction]=true,B=true}',S)
  self.assertIn('long_710.direction=g.direction',S)
if __name__=="__main__": unittest.main()
