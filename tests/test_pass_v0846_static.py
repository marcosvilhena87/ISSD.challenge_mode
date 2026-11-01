from pathlib import Path
import unittest
root=Path(__file__).resolve().parents[1]
ordered=(root/"lua/challenge/pass_ordered_v0820.lua").read_text()
bot=(root/"lua/pass_bot.lua").read_text()
feet=(root/"lua/challenge/pass_feet_v0815.lua").read_text()
auto=(root/"lua/challenge/pass_auto_v071.lua").read_text()
class TestV0846(unittest.TestCase):
 def test_bounded_neutral_prediction(self):
  for x in ('VERSION="0.8.46"','function M.observe_receiver','function M.receiver_prediction','dt>12','velocity_outlier','local horizon=4','math.max(-24,math.min(24','frame-v.frame>12','if forecast then dx,dy=forecast.dx,forecast.dy end'):
   self.assertIn(x,ordered)
 def test_neutral_instrumentation(self):
  for x in ('movement.current_frame=emu.framecount()','approach_89_neutral_velocity','approach_89_predicted_target','Ordered.observe_receiver','Ordered.receiver_prediction'):
   self.assertIn(x,bot)
 def test_prior_behavior(self):
  self.assertIn('MIN_PASS_DISTANCE=24',feet)
  self.assertIn('movement.right_followup_left=3',bot)
  self.assertIn('if t.origin==6 and t.target==3 then buttons={Up=true} end',auto)
  self.assertIn('approach_89_relative_feedback',bot)
if __name__=="__main__":unittest.main()
