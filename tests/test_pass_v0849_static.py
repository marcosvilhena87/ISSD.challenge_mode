from pathlib import Path
import unittest
root=Path(__file__).resolve().parents[1]
ordered=(root/"lua/challenge/pass_ordered_v0820.lua").read_text()
bot=(root/"lua/pass_bot.lua").read_text()
feet=(root/"lua/challenge/pass_feet_v0815.lua").read_text()
class TestV0849(unittest.TestCase):
 def test_pair_67_relative_feedback_and_guard(self):
  for token in ('approach_67_relative_feedback','approach_67_direction_guard','holder_toward','receiver_away','relative_closing','dd>1.5 and dl>1.5','pair_67_double_regression'):
   self.assertIn(token,bot)
 def test_temporary_ban(self):
  for token in ('VERSION="0.8.49"','pair_67_avoid_direction','pair_67_avoid_left','choice.key~=state.pair_67_avoid_direction','state.pair_67_avoid_left==0'):
   self.assertIn(token,ordered)
 def test_old_features(self):
  self.assertIn('ROUTE={6,2,3,4,5,8,9,7,10,11}',ordered)
  self.assertIn('MIN_PASS_DISTANCE=24',feet)
  self.assertIn('approach_89_predicted_target',bot)
  self.assertIn('approach_67_up_feedback',bot)
if __name__=="__main__": unittest.main()
