from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassV0837(unittest.TestCase):
 def test_right_always_first_until_measured_block(self):
  s=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
  for t in ('VERSION="0.8.37"','if holder==5 and target==8 and (not state or not state.right_suspended) then','right_block_reason="measured_regression"','right_block_reason="measured_still"'):
   self.assertIn(t,s)
 def test_locked_burst_and_explicit_stop(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for t in ('buttons=movement.burst_buttons','approach_right_blocked','no_up_left_fallback=true','and buttons.Right) and 2','Ordered.step(sample_for_auto,holder,target,movement)','pre_down_step','approach_diagonal_started'):
   self.assertIn(t,s)
if __name__=="__main__":unittest.main()
