from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class FinishV0813(unittest.TestCase):
 def test_finish_strict_gates(self):
  s=(R/"lua/challenge/pass_finish_v07.lua").read_text()
  for needle in ('await_ten_spatial_candidates','await_bonus_countdown_correspondence',
                 'await_stable_holder','finish_window_expired','shots=t.shots+1',
                 'shot={X=true}','goalkeeper_y_proxy','ambiguous_goal_side'):
   self.assertIn(needle,s)
 def test_opt_in_and_input_logging(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for needle in ('cmd=="FINISH:ON"','finish.enabled=auto_finish_queued',
                 'Finish.step(finish','if shot.X then buttons=shot',
                 'if buttons.X then log_input','auto_write(emu.framecount(),"finish_"'):
   self.assertIn(needle,s)
if __name__=="__main__": unittest.main()
