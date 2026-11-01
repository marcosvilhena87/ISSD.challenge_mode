from pathlib import Path
import unittest
root=Path(__file__).resolve().parents[1]
ordered=(root/"lua/challenge/pass_ordered_v0820.lua").read_text()
bot=(root/"lua/pass_bot.lua").read_text()
feet=(root/"lua/challenge/pass_feet_v0815.lua").read_text()
class V0848(unittest.TestCase):
 def test_route(self):
  self.assertIn('ROUTE={6,2,3,4,5,8,9,7,10,11}',ordered)
  self.assertIn('not visited[id]',ordered)
  self.assertIn('holder~=autopass.target',bot)
  self.assertIn('chain_transfer_candidate',bot)
 def test_feedback(self):
  for x in ('VERSION="0.8.48"','recent_combined_progress','last_good_direction','good_direction_streak','good_direction_lock','combined_gain'):
   self.assertIn(x,ordered)
 def test_preserved(self):
  self.assertIn('MIN_PASS_DISTANCE=24',feet)
  self.assertIn('approach_89_predicted_target',bot)
  self.assertIn('approach_67_up_feedback',bot)
if __name__=="__main__":unittest.main()
