from pathlib import Path
import unittest

R=Path(__file__).resolve().parents[1]

class PassV082(unittest.TestCase):
 def test_selector_diagnostics(self):
  s=(R/"lua/challenge/pass_alignment_v08.lua").read_text()
  for token in ("report.eligible=report.eligible+1","report.excluded_visited",
                "report.candidates[#report.candidates+1]=c",
                'return best,best and "selected" or "no_unvisited_receiver",report'):
   self.assertIn(token,s)

 def test_target_and_terminal_handling(self):
  s=(R/"lua/pass_bot.lua").read_text()
  self.assertIn("pass_candidates_v082.csv",s)
  self.assertIn("candidate_write(emu.framecount()",s)
  self.assertIn('reason=="no_valid_target"',s)
  self.assertIn("autopass.enabled=false;auto_finished=true",s)
  self.assertIn("and not auto_finished and sample_for_auto",s)

 def test_one_attempt_and_simultaneity_preserved(self):
  s=(R/"lua/challenge/pass_auto_v071.lua").read_text()
  self.assertIn("buttons.B=true",s)
  self.assertIn('return {},"no_direction_for_pass"',s)
  self.assertIn("t.tries=1",s)

if __name__=="__main__":
 unittest.main()
