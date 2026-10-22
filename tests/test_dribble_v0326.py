import csv
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
class FlagTimingSourceTests(unittest.TestCase):
 def test_schema_and_counter_detection(self):
  s=(ROOT/"dribble_bot_v0326.lua").read_text(encoding="utf-8")
  self.assertIn('dribble_flag_timing_v0326.csv',s)
  self.assertIn('dribble_start_state_v0326.csv',s)
  self.assertIn('drop==1',s)
  self.assertIn('s.frame-attempt.last_flag_frame',s)
  self.assertIn('write(root.."/dribble_start_state_v0326.csv"',s)
  self.assertIn('},13)',s)
  self.assertIn('},14)',s)
 def test_keeps_goal_and_waypoints(self):
  s=(ROOT/"dribble_bot_v0326.lua").read_text(encoding="utf-8")
  self.assertIn('require("challenge.dribble_goal_v0325")',s)
  self.assertIn('confirm_dribble_score_v032.py',s)
if __name__=="__main__": unittest.main()
