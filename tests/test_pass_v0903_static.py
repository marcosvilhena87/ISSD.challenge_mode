from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class SpatialPossessionResync(unittest.TestCase):
 def test_holder_mismatch_resets_gate(self):
  self.assertIn('spatial.holder~=autopass.origin',S)
  self.assertIn('"possession_spatial_resync"',S)
  self.assertIn('local fresh=Auto.new()',S)
 def test_timeout_retains_chain(self):
  self.assertIn('reason=="possession_gate_timeout" and pass_chain.active',S)
  self.assertIn('"possession_gate_restarted"',S)
  self.assertIn('pass_chain.active=true;auto_finished=false',S)
 def test_queue_and_direction_kept(self):
  self.assertIn('first_unvisited(spatial.visited,new_holder)',S)
  self.assertIn('"pass_direction_output"',S)
  self.assertIn('"finish_x_output"',S)
if __name__=="__main__":unittest.main()
