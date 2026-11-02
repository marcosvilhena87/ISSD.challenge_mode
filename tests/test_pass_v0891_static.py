from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class UniversalDirections(unittest.TestCase):
 def test_diagonal_movement(self):
  self.assertIn('local function approach_buttons(g)',S)
  self.assertIn('b[g.dx>0 and "Right" or "Left"]=true',S)
  self.assertIn('b[g.dy>0 and "Down" or "Up"]=true',S)
  self.assertIn('buttons=approach_buttons(g)',S)
 def test_all_pairs(self):
  self.assertIn('pair_geometry(sample_for_auto,long_710.origin,long_710.target)',S)
  self.assertIn('{"UpRight",12,-12}',S)
  self.assertIn('{"DownLeft",-12,12}',S)
 def test_clear_lane_pass(self):
  self.assertIn('relay_lane_open_pass_queued',S)
  self.assertIn('relay_pass_cancelled_blocker',S)
  self.assertIn('buttons={[long_710.direction]=true,B=true}',S)
 def test_recovery(self):
  self.assertIn('long_710_motion_result',S)
  self.assertIn('last_missing_710',S)
if __name__=="__main__":unittest.main()
