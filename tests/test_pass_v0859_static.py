from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
F=(R/"lua/challenge/pass_finish_v07.lua").read_text(encoding="utf-8")
B=(R/"lua/pass_bot.lua").read_text(encoding="utf-8")
O=(R/"lua/challenge/pass_ordered_v0820.lua").read_text(encoding="utf-8")
class TestV0859(unittest.TestCase):
 def test_distance_and_no_far_shot(self):
  for x in ('VERSION="0.8.59"','MAX_GOALKEEPER_X=135','MAX_APPROACH_FRAMES=120','shot_blocked_too_far','await_ball_at_holder_feet','finish_goal_approach'):
   self.assertIn(x,F)
  self.assertIn('move[dx>0 and "Right" or "Left"]=true',F)
  self.assertIn('px*px+py*py<=18*18',F)
 def test_trajectory(self):
  self.assertIn('pass_shot_trajectory_v0859.csv',B)
  self.assertIn('trajectory_write(emu.framecount(),0,sample_for_auto,"shot_x")',B)
  self.assertIn('elapsed<=60 or elapsed%10==0',B)
  self.assertIn('reason~="finish_goal_approach"',B)
 def test_route_and_evidence(self):
  self.assertIn('primary_9_to_7',O)
  self.assertIn('fallback_6_to_7',O)
  self.assertIn('GoalEvidence.step(goal_monitor,g)',B)
if __name__=='__main__':unittest.main()
