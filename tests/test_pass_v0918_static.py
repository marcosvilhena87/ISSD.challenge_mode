from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf8")
class PairAudit(unittest.TestCase):
 def test_mismatch_probe(self):
  self.assertIn('pair_trace.last_target~=current',S)
  self.assertIn('"target_mismatch"',S)
  self.assertIn('pair_trace.last_target=receiver',S)
  self.assertIn('observation_only=true',S)
 def test_priorities_and_score(self):
  self.assertIn('spatial.holder==6 and not spatial.visited[2]',S)
  self.assertIn('spatial.holder==5 and not spatial.visited[8]',S)
  self.assertIn('chain_completion_clock_evidence',S)
  self.assertIn('pass_score_wram_correlated',S)
if __name__=="__main__":unittest.main()
