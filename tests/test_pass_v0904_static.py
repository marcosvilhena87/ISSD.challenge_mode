from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf-8")
class TimeBudgetV0904(unittest.TestCase):
 def test_game_clock(self):
  self.assertIn('pass_clock=ts',S)
  self.assertIn('pass_time_budget_expired',S)
  self.assertIn('chain_visits<10',S)
 def test_active_watchdog(self):
  self.assertIn('long_710.phase="watchdog_move"',S)
  self.assertIn('"watchdog_active_move"',S)
  self.assertIn('"watchdog_motion_result"',S)
  self.assertIn('"watchdog_stall_detected"',S)
  self.assertIn('wd_threshold=(clock_valid and clock_left<=10) and 12 or 24',S)
 def test_safety(self):
  self.assertIn('possession<=18',S)
  self.assertIn('attempts<4',S)
  self.assertIn('buttons=approach_buttons(g)',S)
  self.assertIn('finish_x_output',S)
  self.assertIn('possession_spatial_resync',S)
if __name__=="__main__":unittest.main()
