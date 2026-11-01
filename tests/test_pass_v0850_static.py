from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
O=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
B=(ROOT/"lua/pass_bot.lua").read_text(encoding="utf-8")
F=(ROOT/"lua/challenge/pass_feet_v0815.lua").read_text(encoding="utf-8")
class TestV0850(unittest.TestCase):
 def test_pair_specific_direction(self):
  for t in ('VERSION="0.8.50"','holder==7 and target==10','pair_710_right_streak','pair_710_relative_right_progress','return {Right=true},"approach_step",metrics'):
   self.assertIn(t,O)
 def test_relative_measurement_and_bounded_extension(self):
  for t in ('approach_710_relative_feedback','holder_toward','receiver_away','relative_closing','pair_710_extension_count'):
   self.assertIn(t,B)
  self.assertIn('(state.pair_710_extension_count or 0)<2',O)
  self.assertIn('pair_710_recent_right_progress',O)
  self.assertIn('Ordered.MAX_APPROACH_ABSOLUTE',B)
 def test_inherited(self):
  self.assertIn('ROUTE={6,2,3,4,5,8,9,7,10,11}',O)
  self.assertIn('MIN_PASS_DISTANCE=24',F)
  self.assertIn('approach_67_relative_feedback',B)
  self.assertIn('approach_89_predicted_target',B)
if __name__=="__main__":unittest.main()
