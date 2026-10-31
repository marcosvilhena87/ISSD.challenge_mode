from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
class PassFinishV07(unittest.TestCase):
 def test_gate_and_one_shot(self):
  s=(R/"lua/challenge/pass_finish_v07.lua").read_text()
  self.assertIn("await_ten_spatial_candidates",s)
  self.assertIn("await_bonus_countdown_correspondence",s)
  self.assertIn("frame-completion_frame>240",s)
  self.assertIn("return {X=true}",s)
  self.assertIn('state.phase="done"',s)
 def test_runner_opt_in(self):
  s=(R/"lua/pass_bot.lua").read_text()
  for k in ("FINISH:ON","FINISH:OFF","pass_finish_v07.csv","bonus.first_decrement_frame"):
   self.assertIn(k,s)
  self.assertNotIn("memory.write_",s)
if __name__=="__main__":unittest.main()
