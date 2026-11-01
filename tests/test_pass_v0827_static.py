from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class SafeExtension(unittest.TestCase):
 def test_extension_is_bounded(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for text in ("MAX_APPROACH=90","MAX_APPROACH_ABSOLUTE=210","EXTEND_FRAMES=30","function M.can_extend","insufficient_net_progress","state.initial_distance-state.best_distance<12","measurement.distance>state.best_distance+12"):
   self.assertIn(text,s)
 def test_runner(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for text in ("Ordered.can_extend(movement,pass_chain.approach_frames,measurement)","approach_extended","approach_extension_neutral","approach_timeout","movement.approach_limit or Ordered.MAX_APPROACH","Ordered.MAX_APPROACH_ABSOLUTE"):
   self.assertIn(text,s)
 def test_goal_monitor_preserved(self):
  s=(R/"lua/pass_bot.lua").read_text()
  self.assertIn('GoalEvidence.step(goal_monitor,goal_sample)',s)
  self.assertIn('"shot_x_issued"',s)
if __name__=="__main__": unittest.main()
