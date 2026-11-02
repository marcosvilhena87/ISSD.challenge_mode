from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
F=(ROOT/"lua/challenge/pass_finish_v07.lua").read_text(encoding="utf-8")
B=(ROOT/"lua/pass_bot.lua").read_text(encoding="utf-8")
class FinishV0900(unittest.TestCase):
 def test_preserves_pass_chain(self):
  self.assertIn('queue_alignment_started',B)
  self.assertIn('first_unvisited(spatial.visited,spatial.holder)',B)
 def test_bounded_approach_and_stall(self):
  self.assertIn('MAX_APPROACH_FRAMES=210',F)
  self.assertIn('approach_stall_frames>=15',F)
  self.assertIn('approach_recoveries>=9',F)
  self.assertIn('shot_blocked_no_progress',F)
 def test_no_early_shot(self):
  self.assertIn('if gap>M.MAX_GOALKEEPER_X then',F)
  self.assertIn('if not holder_found then return {},"await_ball_at_holder_feet" end',F)
  self.assertIn('local shot={X=true}',F)
 def test_telemetry(self):
  self.assertIn('finish_approach_recovery',B)
  self.assertIn('finish_x_output',B)
  self.assertIn('"|current_gap="',B)
if __name__=="__main__": unittest.main()
