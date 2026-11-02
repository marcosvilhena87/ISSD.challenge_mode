from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf8")
class GateFastRecovery(unittest.TestCase):
 def test_same_holder_timeout(self):
  self.assertIn('reason=="possession_gate_timeout" and clock_started',S)
  self.assertIn('old_origin==actual and old_target',S)
  self.assertIn('"possession_gate_fast_recovery"',S)
 def test_safe_fast_pass(self):
  self.assertIn('g.distance<=185 and math.abs(g.dy)<=105',S)
  self.assertIn('ball_distance<=18 and valid_time and retries<2',S)
  self.assertIn('long_710.phase="face";long_710.fast_pass=true',S)
 def test_fallback_preserved(self):
  self.assertIn('"possession_gate_restarted"',S)
  self.assertIn('pass_chain.approach_state={}',S)
  self.assertIn('"pass_direction_output"',S)
  self.assertIn('"finish_x_output"',S)
if __name__=="__main__":unittest.main()
