from pathlib import Path
import unittest
root=Path(__file__).resolve().parents[1]
feet=(root/"lua/challenge/pass_feet_v0815.lua").read_text()
ordered=(root/"lua/challenge/pass_ordered_v0820.lua").read_text()
bot=(root/"lua/pass_bot.lua").read_text()
auto=(root/"lua/challenge/pass_auto_v071.lua").read_text()
class V0844(unittest.TestCase):
 def test_global_minimum(self):
  self.assertIn('MIN_PASS_DISTANCE=24',feet)
  self.assertIn('distance>=M.MIN_PASS_DISTANCE',feet)
  self.assertIn('distance<M.MIN_PASS_DISTANCE and "too_close"',feet)
  self.assertIn('pass_min_gap_check',bot)
 def test_relative_observations(self):
  for t in ('VERSION="0.8.44"','holder_toward=holder_toward','receiver_away=receiver_away','relative_closing=holder_toward-receiver_away'):
   self.assertIn(t,ordered)
  for t in ('approach_89_relative_feedback','pair_89_carrier_stall','receiver_away=','|closing='):
   self.assertIn(t,bot)
 def test_prior_sequences_retained(self):
  self.assertIn('if t.origin==6 and t.target==3 then buttons={Up=true} end',auto)
  self.assertIn('return {Down=true},"pre_down_step"',auto)
  self.assertIn('local desired_burst=',bot)
if __name__=="__main__":unittest.main()
