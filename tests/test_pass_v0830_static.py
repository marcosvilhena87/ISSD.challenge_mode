from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class MotionCalibrationV0830(unittest.TestCase):
 def test_holder_receiver_separate(self):
  s=(ROOT/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for token in ['VERSION="0.8.30"','function M.capture','function M.observe_motion','holder_dx=hx','target_dx=tx','motion_opposite','motion_delayed_or_still','learned.count>=2']:
   self.assertIn(token,s)
 def test_direction_overrides_and_integration(self):
  s=(ROOT/"lua/pass_bot.lua").read_text()
  for token in ['autopass.origin==6 and autopass.target==2','autopass.direction="Up"','autopass.origin==4 and autopass.target==5','autopass.direction="Down"','approach_motion_calibration','movement.burst_positions=Ordered.capture','Ordered.observe_motion(movement,sample_for_auto,holder,target)','GoalEvidence.step(goal_monitor,goal_sample)']:
   self.assertIn(token,s)
if __name__=="__main__":unittest.main()
