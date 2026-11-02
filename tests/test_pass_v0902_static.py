from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class TimeoutRecovery(unittest.TestCase):
 def test_timeout_takeover(self):
  self.assertIn('long_710.phase="recover_approach"',S)
  self.assertIn('"approach_timeout_recovery_started"',S)
  self.assertIn('failures<3',S)
 def test_fresh_geometry(self):
  self.assertIn('pair_geometry(sample_for_auto,from,to)',S)
  self.assertIn('buttons=approach_buttons(g)',S)
  self.assertIn('gained>=12 or elapsed>=30 or moved>=50',S)
 def test_new_controller_and_progress(self):
  self.assertIn('local next_auto=Auto.new()',S)
  self.assertIn('pass_chain.approach_state={}',S)
  self.assertIn('"approach_timeout_recovery_result"',S)
  self.assertIn('"approach_timeout_recovery_fallback"',S)
 def test_direction_and_finish_preserved(self):
  self.assertIn('pass_direction_output',S)
  self.assertIn('finish_x_output',S)
if __name__=="__main__": unittest.main()
