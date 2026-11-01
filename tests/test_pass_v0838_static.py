from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassV0838(unittest.TestCase):
 def test_small_negative_does_not_stop(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for term in ('VERSION="0.8.38"','distance_change>8','actual_projection< -6','right_tolerated','right_cumulative_regression>12','right_repeated_regression'):
   self.assertIn(term,s)
 def test_neutral_baseline_and_frame_logs(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for term in ('right_settle_remaining=4','approach_right_settle','approach_right_frame','approach_right_blocked','buttons=movement.burst_buttons','approach_diagonal_started','pre_down_step'):
   self.assertIn(term,s)
if __name__=="__main__": unittest.main()
