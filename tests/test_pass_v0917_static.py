from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class PairV0917(unittest.TestCase):
 def test_pair_tracing(self):
  for k in ['pair917_holder_summary','pair_trace.moving','pair_trace.still','pair_trace.last_b']:
   self.assertIn(k,S)
 def test_safe_direct(self):
  for k in ['pair917_direct_10_11','direct.distance<=175','math.abs(direct.dy)<=95',
            'not lane_blocker(sample_for_auto,10,11)','exclusive_receiver=11']:
   self.assertIn(k,S)
 def test_fallback(self):
  self.assertIn('reason="initial_motion_stall"',S)
  self.assertIn('elapsed>=9 and geom.distance>250',S)
 def test_priorities_and_clock(self):
  for k in ['spatial.holder==6 and not spatial.visited[2]',
            'spatial.holder==5 and not spatial.visited[8]',
            'chain_completion_clock_evidence']:
   self.assertIn(k,S)
if __name__=="__main__":unittest.main()
