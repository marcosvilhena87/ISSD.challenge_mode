from pathlib import Path
import unittest
S=(Path(__file__).resolve().parents[1]/"lua/pass_bot.lua").read_text(encoding="utf8")
class ClockStart(unittest.TestCase):
 def test_queued_until_decrement(self):
  self.assertIn('clock_start_pending=pending_auto and selected_pass_button=="B"',S)
  self.assertIn('previous_clock_read.time>ts.time and ts.time>0',S)
  self.assertIn('"pass_clock_started"',S)
 def test_expiry_independent(self):
  self.assertIn('armed and clock_started and not clock_expired_logged',S)
  self.assertIn('"pass_time_budget_expired"',S)
 def test_watchdog_diagnostics(self):
  self.assertIn('"watchdog_active_blocked"',S)
  self.assertIn('"watchdog_active_move"',S)
  self.assertIn('"watchdog_motion_result"',S)
 def test_chain_components(self):
  self.assertIn('"possession_spatial_resync"',S)
  self.assertIn('"pass_direction_output"',S)
  self.assertIn('"finish_x_output"',S)
if __name__=="__main__":unittest.main()
