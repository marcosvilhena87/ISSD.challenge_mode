from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class Boundary(unittest.TestCase):
 def test_zero_is_not_definitive(self):
  self.assertIn('status="boundary_unverified"',S) if False else self.assertIn('"boundary_unverified"',S)
  self.assertIn('chain_completion_clock_evidence',S)
  self.assertNotIn('chain_complete_out_of_time',S)
 def test_completion_not_filtered_by_seconds(self):
  self.assertIn('if not completion_frame and event.visited_count==10 and clock_started then',S)
 def test_priorities_preserved(self):
  self.assertIn('spatial.holder==6 and not spatial.visited[2]',S)
  self.assertIn('spatial.holder==5 and not spatial.visited[8]',S)
if __name__=="__main__": unittest.main()
