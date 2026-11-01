from pathlib import Path
import unittest
root=Path(__file__).resolve().parents[1]
ordered=(root/"lua/challenge/pass_ordered_v0820.lua").read_text()
bot=(root/"lua/pass_bot.lua").read_text()
auto=(root/"lua/challenge/pass_auto_v071.lua").read_text()
class TestV0847(unittest.TestCase):
 def test_six_seven_up_progress(self):
  for t in ('VERSION="0.8.47"','holder==6 and target==7','pair_67_up_streak','pair_67_recent_up_progress','(state.pair_67_extension_count or 0)<2'):
   self.assertIn(t,ordered)
  for t in ('approach_67_up_feedback','movement.pair_67_extension_count','movement.pair_67_last_distance'):
   self.assertIn(t,bot)
 def test_existing_routes_retained(self):
  self.assertIn('return {Up=true},"pre_up_step"',auto)
  self.assertIn('if t.origin==6 and t.target==3 then buttons={Up=true} end',auto)
  self.assertIn('return {Down=true},"pre_down_step"',auto)
  self.assertIn('local desired_burst=',bot)
  self.assertIn('approach_89_predicted_target',bot)
if __name__=="__main__":unittest.main()
