from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class PassBonusV051(unittest.TestCase):
 def test_first_decrement_and_initialization_are_distinct(self):
  s=(ROOT/"lua/challenge/pass_bonus_validation_v051.lua").read_text()
  self.assertIn('first_bonus_decrement',s)
  self.assertIn('bonus_increase_or_initialization',s)
  self.assertIn('first_decrement_without_spatial_completion',s)
 def test_runner_and_legacy_detector(self):
  runner=(ROOT/"lua/pass_bot.lua").read_text()
  legacy=(ROOT/"lua/challenge/pass_timers_v05.lua").read_text()
  self.assertIn("pass_bonus_validation_v051.csv",runner)
  self.assertIn("event.visited_count==10",runner)
  self.assertIn("bonus_initialized_candidate",legacy)
  self.assertNotIn('bonus_zero_to_positive_candidate',legacy)
  self.assertNotIn('memory.write_',runner)
if __name__=="__main__": unittest.main()
