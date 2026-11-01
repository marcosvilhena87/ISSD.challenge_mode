from pathlib import Path
import unittest
R=Path(__file__).resolve().parents[1]
ordered=(R/"lua/challenge/pass_ordered_v0820.lua").read_text()
priority=(R/"lua/challenge/pass_priority_v087.lua").read_text()
bot=(R/"lua/pass_bot.lua").read_text()
class TestRouteV0846(unittest.TestCase):
 def test_nine_to_eight_default_once(self):
  self.assertIn('VERSION="0.8.46"',ordered)
  self.assertIn('if holder==9 and not nine_to_eight_done then',ordered)
  self.assertIn('return 8,"nine_to_eight_default_return"',ordered)
  self.assertIn('nine_to_eight_done)',priority)
 def test_reset_and_completion(self):
  self.assertEqual(bot.count('nine_to_eight_done=false'),2)
  self.assertIn('autopass.origin==9 and holder==8 and autopass.target==8',bot)
  self.assertIn('pass_chain.nine_to_eight_done=true',bot)
  self.assertIn('route_9_to_8_completed',bot)
  self.assertIn('if repeated then pass_chain.consecutive_relays',bot)
  self.assertIn('for id in pairs(spatial.visited)',bot)
 def test_previous_approaches(self):
  self.assertIn('movement.right_followup_left=3',bot)
  self.assertIn('approach_89_relative_feedback',bot)
if __name__=="__main__": unittest.main()
